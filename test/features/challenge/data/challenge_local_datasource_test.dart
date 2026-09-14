import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/sync/sync_dispatcher.dart' show toFirestoreOp;
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/transaction/data/datasources/category_local_datasource.dart';

// Senin 2026-09-07 .. Minggu 2026-09-13
const _mingguIni = 20260907;
final _epoch = DateTime(2026, 9, 7);

void main() {
  late AppDatabase db;
  late ChallengeLocalDatasource ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = ChallengeLocalDatasourceImpl(db);
  });

  tearDown(() async => db.close());

  Future<void> tambahTx({
    required int hari,
    required int nominal,
    String kategori = 'food',
    String tipe = 'expense',
    bool isFixed = false,
    int? sourceBillId,
  }) => db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          txId: 'tx-$hari-$nominal-${sourceBillId ?? 0}',
          amount: nominal,
          category: kategori,
          type: tipe,
          date: DateTime(2026, 9, hari, 12),
          createdAt: DateTime(2026, 9, hari, 12),
          updatedAt: DateTime(2026, 9, hari, 12),
          isFixed: Value(isFixed),
          sourceBillId: Value(sourceBillId),
        ),
      );

  WeeklyChallengesCompanion baris({
    int weekKey = _mingguIni,
    ChallengeStatus status = ChallengeStatus.active,
    String? kategori = 'food',
    DateTime? resultSeenAt,
  }) => WeeklyChallengesCompanion.insert(
        weekKey: Value(weekKey),
        category: Value(kategori),
        targetAmount: const Value(115000),
        baselineAmount: const Value(140000),
        status: status,
        timezone: 'WIB',
        createdAt: _epoch,
        updatedAt: _epoch,
        resultSeenAt: Value(resultSeenAt),
      );

  group('proyeksi belanja · D19', () {
    test('U108 · basis TIDAK menghitung transaksi ber-sourceBillId', () async {
      await tambahTx(hari: 8, nominal: 40000);                    // belanja harian
      await tambahTx(hari: 9, nominal: 186000, sourceBillId: 7);  // tagihan
      final spends = await ds.getWeeklySpends(_mingguIni);
      final food = spends.where((s) => s.category == 'food');
      expect(food.single.amount, 40000);
    });

    test('U4 · transaksi isFixed diabaikan', () async {
      await tambahTx(hari: 8, nominal: 40000);
      await tambahTx(hari: 9, nominal: 900000, isFixed: true);
      final spends = await ds.getWeeklySpends(_mingguIni);
      expect(spends.single.amount, 40000);
    });

    test('U5 · transaksi income diabaikan', () async {
      await tambahTx(hari: 8, nominal: 40000);
      await tambahTx(hari: 9, nominal: 900000, tipe: 'income');
      final spends = await ds.getWeeklySpends(_mingguIni);
      expect(spends.single.amount, 40000);
    });

    test('belanja dikelompokkan per minggu lokal', () async {
      await tambahTx(hari: 8, nominal: 30000);   // minggu 20260907
      await tambahTx(hari: 15, nominal: 50000);  // minggu 20260914
      final spends = await ds.getWeeklySpends(_mingguIni);
      final perMinggu = {for (final s in spends) s.weekKey: s.amount};
      expect(perMinggu[20260907], 30000);
      expect(perMinggu[20260914], 50000);
    });
  });

  group('progres minggu berjalan', () {
    test('U109 · spentInWeek TIDAK menghitung transaksi tagihan', () async {
      await tambahTx(hari: 8, nominal: 34000);
      await tambahTx(hari: 9, nominal: 186000, sourceBillId: 7);
      final terpakai = await ds.spentInWeek(weekKey: _mingguIni, category: 'food');
      expect(terpakai, 34000);
    });

    test('spentInWeek TIDAK menghitung transaksi income', () async {
      // U5 hanya menutup getWeeklySpends — jalur spentInWeek/excludedInWeek
      // punya klausa `type.equals('expense')` sendiri di `dasar` dan butuh
      // penjaganya sendiri, atau menghapusnya lolos tanpa test merah.
      await tambahTx(hari: 8, nominal: 34000);
      await tambahTx(hari: 9, nominal: 900000, tipe: 'income');
      final terpakai = await ds.spentInWeek(weekKey: _mingguIni, category: 'food');
      expect(terpakai, 34000);
    });

    test('spentInWeek berhenti di batas minggu', () async {
      await tambahTx(hari: 13, nominal: 10000); // Minggu, masih minggu ini
      await tambahTx(hari: 14, nominal: 99000); // Senin berikutnya
      final terpakai = await ds.spentInWeek(weekKey: _mingguIni, category: 'food');
      expect(terpakai, 10000);
    });

    test('U111 · excludedInWeek MENGHITUNG transaksi tagihan', () async {
      await tambahTx(hari: 8, nominal: 34000);
      await tambahTx(hari: 9, nominal: 186000, sourceBillId: 7);
      final dikecualikan =
          await ds.excludedInWeek(weekKey: _mingguIni, category: 'food');
      expect(dikecualikan, 186000);
    });

    test('U111 · excludedInWeek nol saat tak ada yang dikecualikan', () async {
      await tambahTx(hari: 8, nominal: 34000);
      expect(await ds.excludedInWeek(weekKey: _mingguIni, category: 'food'), 0);
    });

    test('S-D · tagihan ber-isFixed IKUT dihitung excludedInWeek', () async {
      // INI kasus yang Rev 1 lewatkan, dan ia yang PALING SERING terjadi:
      // bills_bloc.dart:238 menulis transaksi "Tandai Lunas" dengan
      // `isFixed: includeAsFixed && representedByFixedExpenses(bill)`, jadi kos
      // dan listrik bulanan mendarat sebagai isFixed=true DAN sourceBillId!=null.
      // Filter Rev 1 (`isFixed == false && sourceBillId != null`) membuangnya
      // dari progres DAN dari baris penjelas sekaligus.
      await tambahTx(hari: 8, nominal: 34000);
      await tambahTx(hari: 9, nominal: 1200000, sourceBillId: 3, isFixed: true);

      expect(await ds.spentInWeek(weekKey: _mingguIni, category: 'food'), 34000);
      expect(await ds.excludedInWeek(weekKey: _mingguIni, category: 'food'),
          1200000);
    });

    test('S-D · kebutuhan tetap non-tagihan juga masuk excludedInWeek', () async {
      await tambahTx(hari: 8, nominal: 34000);
      await tambahTx(hari: 10, nominal: 500000, isFixed: true); // tanpa sourceBillId
      expect(await ds.excludedInWeek(weekKey: _mingguIni, category: 'food'),
          500000);
    });

    test('S-D · INVARIAN rekonsiliasi: spent + excluded == total', () async {
      // Penjaga sesungguhnya. Ia merah untuk SETIAP pengecualian masa depan
      // yang ditambahkan ke proyeksi tapi lupa dicerminkan di excludedInWeek —
      // termasuk yang belum terpikirkan hari ini. Test berbasis daftar kasus
      // tidak bisa melakukan itu.
      await tambahTx(hari: 8, nominal: 34000);                                 // dihitung
      await tambahTx(hari: 9, nominal: 186000, sourceBillId: 7);               // tagihan
      await tambahTx(hari: 10, nominal: 1200000, sourceBillId: 3, isFixed: true); // tagihan tetap
      await tambahTx(hari: 11, nominal: 500000, isFixed: true);                // tetap non-tagihan

      final spent = await ds.spentInWeek(weekKey: _mingguIni, category: 'food');
      final excluded =
          await ds.excludedInWeek(weekKey: _mingguIni, category: 'food');
      final total =
          await ds.totalExpenseInWeek(weekKey: _mingguIni, category: 'food');

      // Nilai eksplisit DULU — invarian jumlah sendirian tautologis selama
      // `dikecualikan` didefinisikan sebagai negasi persis dari `dihitung`
      // (spent + (total - spent) == total selalu benar, apa pun predikatnya).
      // Tanpa asersi nilai ini, menghapus `isFixed.equals(false)` dari
      // predikat `operasional` (mis-hitung 500000 sebagai "dihitung" alih-alih
      // "dikecualikan") tetap lolos invarian jumlah walau angkanya salah.
      expect(spent, 34000);
      expect(excluded, 1886000);
      expect(spent + excluded, total);
      expect(total, 1920000);
    });
  });

  group('baris tantangan', () {
    test('U35 · baris held boleh tanpa kategori/target/basis', () async {
      await ds.upsert(WeeklyChallengesCompanion.insert(
        weekKey: const Value(_mingguIni),
        status: ChallengeStatus.held,
        timezone: 'WIB',
        createdAt: _epoch,
        updatedAt: _epoch,
      ));
      final row = await ds.findWeek(_mingguIni);
      expect(row!.status, ChallengeStatus.held);
      expect(row.category, isNull);
      expect(row.targetAmount, isNull);
    });

    test('U61 · activeWeeksBefore mengembalikan SEMUA baris active lampau', () async {
      await ds.upsert(baris(weekKey: 20260824));
      await ds.upsert(baris(weekKey: 20260831));
      await ds.upsert(baris(weekKey: _mingguIni));
      final lampau = await ds.activeWeeksBefore(_mingguIni);
      expect(lampau.map((r) => r.weekKey), [20260824, 20260831]);
    });

    test('U44 · watchHistory dibatasi limit dan terurut menurun', () async {
      for (var i = 0; i < 15; i++) {
        await ds.upsert(baris(
          weekKey: 20260101 + i,
          status: ChallengeStatus.achieved,
        ));
      }
      final riwayat = await ds.watchHistory(12).first;
      expect(riwayat.length, 12);
      expect(riwayat.first.weekKey, greaterThan(riwayat.last.weekKey));
    });
  });

  group('penandaan lokal · D22 & D23', () {
    test('U114 · markOlderResultsSeen menandai semua KECUALI keepWeekKey', () async {
      for (final w in [20260824, 20260831, 20260907]) {
        await ds.upsert(baris(weekKey: w, status: ChallengeStatus.achieved));
      }
      final n = await ds.markOlderResultsSeen(
        keepWeekKey: 20260907,
        at: DateTime(2026, 9, 14),
      );
      expect(n, 2);
      expect((await ds.findWeek(20260907))!.resultSeenAt, isNull);
      expect((await ds.findWeek(20260831))!.resultSeenAt, isNotNull);
      expect((await ds.findWeek(20260824))!.resultSeenAt, isNotNull);
    });

    test('U114 · markOlderResultsSeen tidak menyentuh baris yang sudah dilihat', () async {
      await ds.upsert(baris(
        weekKey: 20260831,
        status: ChallengeStatus.achieved,
        resultSeenAt: DateTime(2026, 9, 1),
      ));
      await ds.upsert(baris(weekKey: 20260907, status: ChallengeStatus.achieved));
      final n = await ds.markOlderResultsSeen(
        keepWeekKey: 20260907, at: DateTime(2026, 9, 14));
      expect(n, 0);
    });

    test('U117 · markResultSeen TIDAK menggeser updatedAt maupun isSynced', () async {
      await ds.upsert(baris(status: ChallengeStatus.achieved));
      await ds.markSynced(_mingguIni);
      final sebelum = await ds.findWeek(_mingguIni);

      await ds.markResultSeen(weekKey: _mingguIni, at: DateTime(2026, 9, 14));
      final sesudah = await ds.findWeek(_mingguIni);

      expect(sesudah!.updatedAt, sebelum!.updatedAt);
      expect(sesudah.isSynced, isTrue);
      expect(sesudah.resultSeenAt, isNotNull);
    });

    test('U117 · markOlderResultsSeen juga tidak menggeser updatedAt', () async {
      await ds.upsert(baris(weekKey: 20260831, status: ChallengeStatus.achieved));
      await ds.upsert(baris(weekKey: 20260907, status: ChallengeStatus.achieved));
      final sebelum = await ds.findWeek(20260831);

      await ds.markOlderResultsSeen(keepWeekKey: 20260907, at: DateTime(2026, 9, 14));
      final sesudah = await ds.findWeek(20260831);

      expect(sesudah!.updatedAt, sebelum!.updatedAt);
      expect(sesudah.resultSeenAt, isNotNull);
    });

    test('U117 · markSynced tidak menggeser updatedAt', () async {
      await ds.upsert(baris());
      final sebelum = await ds.findWeek(_mingguIni);
      await ds.markSynced(_mingguIni);
      expect((await ds.findWeek(_mingguIni))!.updatedAt, sebelum!.updatedAt);
    });
  });

  group('kontrak yang menjaga fitur lain', () {
    test('U33 · progres TIDAK pernah disimpan — sunting transaksi lama tak menggeser target', () async {
      await ds.upsert(baris());
      await tambahTx(hari: 8, nominal: 40000);
      final sebelum = await ds.findWeek(_mingguIni);

      await (db.update(db.transactions)
            ..where((t) => t.txId.equals('tx-8-40000-0')))
          .write(const TransactionsCompanion(amount: Value(999000)));

      final sesudah = await ds.findWeek(_mingguIni);
      expect(sesudah!.targetAmount, sebelum!.targetAmount);
      expect(sesudah.baselineAmount, sebelum.baselineAmount);
      // Progres justru IKUT berubah, karena ia dihitung ulang — itu memang mau kita.
      expect(await ds.spentInWeek(weekKey: _mingguIni, category: 'food'), 999000);
    });

    test('U43 · clearAllLocalData menyapu weekly_challenges', () async {
      await ds.upsert(baris());
      await db.clearAllLocalData();
      expect(await ds.findWeek(_mingguIni), isNull);
    });

    test('U45 · deleteCategory TIDAK menghapus baris weekly_challenges', () async {
      // Cascade deleteCategory menyapu budget_limits + categories saja
      // (category_local_datasource.dart:81-93). Riwayat tantangan harus tetap
      // hidup — kalau ikut terhapus, riwayat berlubang tanpa penjelasan.
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            slug: 'kopi-senja',
            isBuiltIn: const Value(false),
            isLimitable: const Value(true),
          ));
      await ds.upsert(baris(kategori: 'kopi-senja'));

      await CategoryLocalDatasourceImpl(db).deleteCategory('kopi-senja');

      final row = await ds.findWeek(_mingguIni);
      expect(row, isNotNull);
      expect(row!.category, 'kopi-senja'); // slug mentah, riwayat pakai label cadangan
    });
  });

  group('antrian sinkron · S-A doc path penuh', () {
    // Path yang dipakai SELALU doc path penuh `users/{uid}/challenges/{weekKey}`.
    // Rev 1 memakai path koleksi (3 segmen); sync_dispatcher.dart:15-23 menolak
    // segmen ganjil dengan ArgumentError, dan sync_service.dart:88 menghapus
    // item ber-ArgumentError seketika — setiap tulisan offline hilang.
    const pathA = 'users/uid-1/challenges/20260907';
    const pathB = 'users/uid-1/challenges/20260831';

    test('U48 · purge membuang item tertunda untuk DOKUMEN yang sama', () async {
      for (var i = 0; i < 3; i++) {
        await ds.addToSyncQueue(
          itemId: '$_mingguIni', collectionPath: pathA,
          data: '{"n":$i}', operation: SyncOperation.create,
        );
      }
      expect(await ds.purgePendingSyncFor(pathA), 3);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test('U48 · purge tidak menyentuh dokumen lain', () async {
      await ds.addToSyncQueue(
        itemId: '1', collectionPath: pathA, data: '{}',
        operation: SyncOperation.create);
      await ds.addToSyncQueue(
        itemId: '1', collectionPath: 'users/uid-1/streak_marks/20260907',
        data: '{}', operation: SyncOperation.create);
      await ds.purgePendingSyncFor(pathA);
      final sisa = await db.select(db.syncQueue).get();
      expect(sisa.single.collectionPath, 'users/uid-1/streak_marks/20260907');
    });

    test('S-A · purge minggu ini TIDAK memakan antrian minggu lain', () async {
      // Rev 1 mem-purge seluruh path koleksi, jadi menutup dua minggu lampau
      // sekaligus dalam keadaan offline membuang item minggu pertama saat
      // minggu kedua diproses. Langkah 1 Task 10 sengaja JAMAK — jadi kasus ini
      // bukan hipotetis.
      await ds.addToSyncQueue(
        itemId: '20260831', collectionPath: pathB, data: '{}',
        operation: SyncOperation.create);
      await ds.addToSyncQueue(
        itemId: '20260907', collectionPath: pathA, data: '{}',
        operation: SyncOperation.create);

      await ds.purgePendingSyncFor(pathA);

      final sisa = await db.select(db.syncQueue).get();
      expect(sisa.single.collectionPath, pathB);
    });

    test('S-A · item yang diantre LOLOS penjaga dispatcher yang asli', () async {
      // Jangan meng-assert bentuk string. Panggil penjaganya. Test yang meniru
      // aturan akan ikut salah kalau aturannya salah dipahami; test yang
      // memanggil penjaganya tidak bisa.
      await ds.addToSyncQueue(
        itemId: '$_mingguIni', collectionPath: pathA,
        data: '{"weekKey":20260907}', operation: SyncOperation.create);

      final item = await db.select(db.syncQueue).getSingle();
      expect(() => toFirestoreOp(item), returnsNormally);
      expect(toFirestoreOp(item).path, pathA);
    });
  });

  group('pemeta baris → entity · S-C', () {
    test('toChallengeWeek membawa field yang menentukan tampilan', () async {
      await ds.upsert(baris(status: ChallengeStatus.achieved));
      final week = toChallengeWeek((await ds.findWeek(_mingguIni))!);
      expect(week.weekKey, _mingguIni);
      expect(week.category, 'food');
      expect(week.targetAmount, 115000);
      expect(week.status, ChallengeStatus.achieved);
    });
  });
}
