import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';

const epoch = 20260901;

void main() {
  late AppDatabase db;
  late StreakLocalDatasource ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = StreakLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  Future<void> tambahTransaksi({
    required DateTime date,
    required DateTime createdAt,
    String id = 'tx',
  }) async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            txId: '$id-${date.millisecondsSinceEpoch}-'
                '${createdAt.millisecondsSinceEpoch}',
            amount: 15000,
            category: 'makan',
            type: 'expense',
            date: date,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  }

  group('watchTransactionDays — jendela createdAt (spec §4.2 aturan 1)', () {
    test('T5 — date=D, createdAt=D+2 → D aman', () async {
      await tambahTransaksi(
        date: DateTime(2026, 9, 2, 13),
        createdAt: DateTime(2026, 9, 4, 8),
      );
      expect(await ds.readTransactionDays(epochDay: epoch), {20260902});
    });

    test('T6 — date=D, createdAt=D+3 → D TIDAK aman', () async {
      await tambahTransaksi(
        date: DateTime(2026, 9, 2, 13),
        createdAt: DateTime(2026, 9, 5, 8),
      );
      expect(await ds.readTransactionDays(epochDay: epoch), isEmpty);
    });

    test('T7 — date=D+1, createdAt=D (bertanggal depan) → D+1 TIDAK aman', () async {
      await tambahTransaksi(
        date: DateTime(2026, 9, 3, 9),
        createdAt: DateTime(2026, 9, 2, 9),
      );
      expect(await ds.readTransactionDays(epochDay: epoch), isEmpty);
    });

    test('T8 — transaksi lama diedit tanggalnya jadi hari ini → hari ini TIDAK '
        'aman karena createdAt tetap tanggal lama', () async {
      await tambahTransaksi(
        date: DateTime(2026, 9, 20, 10), // diedit ke "hari ini"
        createdAt: DateTime(2026, 9, 1, 10), // dibuat 19 hari lalu
      );
      expect(await ds.readTransactionDays(epochDay: epoch), isEmpty);
    });

    test('transaksi sebelum epoch tidak ikut terbaca', () async {
      await tambahTransaksi(
        date: DateTime(2026, 8, 20, 10),
        createdAt: DateTime(2026, 8, 20, 10),
      );
      expect(await ds.readTransactionDays(epochDay: epoch), isEmpty);
    });

    test('stream memancarkan ulang saat transaksi baru masuk', () async {
      final emisi = <Set<int>>[];
      final sub = ds.watchTransactionDays(epochDay: epoch).listen(emisi.add);
      await Future<void>.delayed(Duration.zero);
      await tambahTransaksi(
        date: DateTime(2026, 9, 5, 10),
        createdAt: DateTime(2026, 9, 5, 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emisi.last, contains(20260905));
    });
  });

  group('watchMarkedDays — baris via-koreksi-jam dikecualikan', () {
    test('baris bertanda TIDAK ikut, baris bersih ikut', () async {
      await ds.insertMark(
        dayKey: 20260902,
        markedAt: DateTime.utc(2026, 9, 2, 3),
        timezone: 'WIB',
        viaClockCorrection: false,
      );
      await ds.insertMark(
        dayKey: 20260903,
        markedAt: DateTime.utc(2026, 9, 3, 3),
        timezone: 'WIB',
        viaClockCorrection: true,
      );
      expect(await ds.readMarkedDays(), {20260902});
      // Barisnya TETAP ADA di tabel — tidak dihapus, hanya tak dipakai replay.
      expect(await ds.hasMark(20260903), isTrue);
    });

    test('T31 — insertMark TIDAK PERNAH menimpa baris yang sudah ada', () async {
      await ds.insertMark(
        dayKey: 20260902,
        markedAt: DateTime.utc(2026, 9, 2, 3),
        timezone: 'WIB',
        viaClockCorrection: false,
      );
      await ds.markSynced(20260902);

      // Persis kasus RTC reset di spec §4.7: jam mundur ke hari yang KEBETULAN
      // sudah pernah ditandai jujur, lalu user menekan CTA lagi.
      await ds.insertMark(
        dayKey: 20260902,
        markedAt: DateTime.utc(2026, 8, 3, 3),
        timezone: 'WIB',
        viaClockCorrection: true,
      );

      final row = await ds.findMark(20260902);
      expect(row!.viaClockCorrection, isFalse,
          reason: 'penanda jujur tidak boleh diturunkan jadi bertanda — '
              'itu memutus ruas user yang tidak curang apa pun');
      expect(row.isSynced, isTrue,
          reason: 'status sinkronnya pun tak boleh ikut ter-reset');
      expect(await ds.readMarkedDays(), {20260902},
          reason: 'hari itu tetap ikut replay');
    });
  });

  group('readUnsyncedMarks — bahan dorongan D-6', () {
    test('hanya baris BERSIH yang belum tersinkron', () async {
      await ds.insertMark(
        dayKey: 20260902, markedAt: DateTime.utc(2026, 9, 2),
        timezone: 'WIB', viaClockCorrection: false,
      );
      await ds.insertMark(
        dayKey: 20260903, markedAt: DateTime.utc(2026, 9, 3),
        timezone: 'WIB', viaClockCorrection: false,
      );
      await ds.markSynced(20260903);
      await ds.insertMark(
        dayKey: 20260904, markedAt: DateTime.utc(2026, 9, 4),
        timezone: 'WIB', viaClockCorrection: true,
      );

      expect(
        (await ds.readUnsyncedMarks()).map((e) => e.dayKey).toList(),
        [20260902],
        reason: '20260903 sudah tersinkron; 20260904 bertanda dan tak pernah '
            'boleh naik ke Firestore (spec §4.7)',
      );
    });
  });

  group('T43 — deleteSyncedMarksAbsentFrom (D-14)', () {
    test('baris tersinkron yang absen dari tarikan dihapus lokal', () async {
      await ds.insertMark(
        dayKey: 20260902, markedAt: DateTime.utc(2026, 9, 2),
        timezone: 'WIB', viaClockCorrection: false,
      );
      await ds.markSynced(20260902);

      await ds.deleteSyncedMarksAbsentFrom(<int>{}, sinceDayKey: epoch);

      expect(await ds.hasMark(20260902), isFalse);
    });

    test('baris BELUM tersinkron tidak pernah ikut terhapus', () async {
      await ds.insertMark(
        dayKey: 20260903, markedAt: DateTime.utc(2026, 9, 3),
        timezone: 'WIB', viaClockCorrection: false,
      );
      // isSynced tetap false — persis baris lokal yang belum sempat naik.

      await ds.deleteSyncedMarksAbsentFrom(<int>{}, sinceDayKey: epoch);

      expect(await ds.hasMark(20260903), isTrue,
          reason: 'D-13: baris isSynced==false bukan milik aturan ini');
    });

    test('baris bertanda TIDAK PERNAH ikut terhapus meski tersinkron secara '
        'tak sengaja', () async {
      await ds.insertMark(
        dayKey: 20260904, markedAt: DateTime.utc(2026, 9, 4),
        timezone: 'WIB', viaClockCorrection: true,
      );
      await ds.markSynced(20260904); // seharusnya tak pernah terjadi, tapi
                                      // aturan ini tetap wajib tahan kasusnya.

      await ds.deleteSyncedMarksAbsentFrom(<int>{}, sinceDayKey: epoch);

      expect(await ds.hasMark(20260904), isTrue);
    });

    test('baris yang MASIH ADA di hasil tarikan tidak tersentuh', () async {
      await ds.insertMark(
        dayKey: 20260905, markedAt: DateTime.utc(2026, 9, 5),
        timezone: 'WIB', viaClockCorrection: false,
      );
      await ds.markSynced(20260905);

      await ds.deleteSyncedMarksAbsentFrom({20260905}, sinceDayKey: epoch);

      expect(await ds.hasMark(20260905), isTrue);
    });
  });

  group('readMeta — tahan baris singleton yang hilang', () {
    test('mengembalikan nilai default saat baris id=1 tak ada', () async {
      // Persis keadaan sesudah clearAllLocalData(): allTables tersapu dan
      // HANYA preferences yang dibuat ulang.
      await db.delete(db.streakMeta).go();
      expect(await ds.readMeta(), StreakMetaValues.empty);
    });

    test('saveMeta membuat baris bila belum ada, lalu menimpanya', () async {
      await db.delete(db.streakMeta).go();
      await ds.saveMeta(
        const StreakMetaValues(
          lastSeenDay: 20260902,
          maxSeenDay: 20260902,
          lastCelebratedRuas: 3,
          clockAnomalyCount: 1,
          acknowledgedBreakDay: 20260830,
        ),
      );
      final meta = await ds.readMeta();
      expect(meta.lastSeenDay, 20260902);
      expect(meta.lastCelebratedRuas, 3);

      await ds.saveMeta(meta.copyWith(lastCelebratedRuas: 7));
      expect((await ds.readMeta()).lastCelebratedRuas, 7);
      final rows = await db.select(db.streakMeta).get();
      expect(rows, hasLength(1), reason: 'tetap satu baris singleton');
    });
  });

  group('purgePendingSyncFor', () {
    Future<void> antre(String path, SyncOperation op) => ds.addToSyncQueue(
      itemId: '20260902',
      collectionPath: path,
      data: const {'dayKey': 20260902},
      operation: op,
    );

    test('membuang HANYA item dengan path sama persis, dan menghitung create',
        () async {
      const path = 'users/u1/streak_marks/20260902';
      await antre(path, SyncOperation.create);
      await antre(path, SyncOperation.delete);
      await antre('users/u1/streak_marks/20260903', SyncOperation.create);
      await antre('users/u1/goals/g1', SyncOperation.create);

      final dibuang = await ds.purgePendingSyncFor(path);
      expect(dibuang, 1, reason: 'satu create untuk path itu');

      final sisa = await db.select(db.syncQueue).get();
      expect(sisa.map((e) => e.collectionPath).toSet(), {
        'users/u1/streak_marks/20260903',
        'users/u1/goals/g1',
      });
    });
  });
}
