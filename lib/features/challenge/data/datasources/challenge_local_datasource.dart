import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart'
    show weekKeyOf;
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/entities/weekly_spend.dart';

/// S-C — SATU-SATUNYA pemeta baris Drift → entity domain di seluruh fitur.
/// Kalau suatu saat lahir pemeta kedua, itu tanda `ChallengeWeek` kurang
/// lengkap: tambah field di entity-nya, jangan tambah pemetanya.
ChallengeWeek toChallengeWeek(WeeklyChallenge r) => ChallengeWeek(
      weekKey: r.weekKey,
      category: r.category,
      targetAmount: r.targetAmount,
      baselineAmount: r.baselineAmount,
      status: r.status,
      finalSpent: r.finalSpent,
      resolvedAt: r.resolvedAt,
      resultSeenAt: r.resultSeenAt,
    );

abstract class ChallengeLocalDatasource {
  Stream<WeeklyChallenge?> watchWeek(int weekKey);
  Stream<List<WeeklyChallenge>> watchHistory(int limit);

  /// Pemicu hitung ulang `spentInWeek`/`excludedInWeek` — SINYAL saja, tanpa
  /// membawa data. Angkanya tetap datang dari agregat SQL, jadi tabel paling
  /// ramai di app tidak pernah dimaterialisasi ulang ke memori hanya untuk
  /// tahu bahwa ia berubah.
  Stream<void> watchTransactionTicks();
  Future<WeeklyChallenge?> findWeek(int weekKey);
  Future<List<WeeklyChallenge>> activeWeeksBefore(int weekKey);
  Future<List<WeeklySpend>> getWeeklySpends(int fromWeekKey);
  Future<int> spentInWeek({required int weekKey, required String category});
  Future<int> excludedInWeek({required int weekKey, required String category});
  Future<int> totalExpenseInWeek({required int weekKey, required String category});
  Future<void> upsert(WeeklyChallengesCompanion row);
  Future<int> updateWeek(int weekKey, WeeklyChallengesCompanion patch);
  Future<void> markSynced(int weekKey);
  Future<void> markResultSeen({required int weekKey, required DateTime at});
  Future<int> markOlderResultsSeen({required int keepWeekKey, required DateTime at});
  Future<List<WeeklyChallenge>> pendingRows();
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required String data,
    required SyncOperation operation,
  });
  Future<int> purgePendingSyncFor(String docPath);
}

class ChallengeLocalDatasourceImpl implements ChallengeLocalDatasource {
  ChallengeLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  // ─── Proyeksi belanja ──────────────────────────────────────────────────────

  /// Proyeksi SEMPIT: hanya empat kolom yang ditarik, filternya di SQL supaya
  /// index `idx_transactions_date` terpakai. Query ini berjalan ulang tiap ada
  /// perubahan tabel transaksi — menarik baris penuh berarti memateri ulang
  /// tabel paling ramai di app, di HP kelas bawah.
  ///
  /// `sourceBillId.isNull()` ada di klausa SQL, bukan penyaringan di Dart
  /// (D19): ia mengurangi baris yang ditarik, dan satu tempat membuat mustahil
  /// ada jalur proyeksi kedua yang lupa memfilter.
  @override
  Future<List<WeeklySpend>> getWeeklySpends(int fromWeekKey) async {
    final t = _db.transactions;
    final q = _db.selectOnly(t)
      ..addColumns([t.date, t.amount, t.category])
      ..where(
        t.date.isBiggerOrEqualValue(localMidnightOf(fromWeekKey)) &
            t.type.equals('expense') &
            t.isFixed.equals(false) &
            t.sourceBillId.isNull(),
      );

    // Pengelompokan di Dart, bukan SQL: GROUP BY minggu lokal butuh
    // customStatement yang dilarang CLAUDE.md (Drift menyimpan DateTime
    // sebagai detik UTC).
    final total = <({int weekKey, String category}), int>{};
    for (final r in await q.get()) {
      final tanggal = r.read(t.date)!;
      final kunci = (
        weekKey: weekKeyOf(tanggal),
        category: r.read(t.category)!,
      );
      total[kunci] = (total[kunci] ?? 0) + r.read(t.amount)!;
    }
    return [
      for (final e in total.entries)
        WeeklySpend(
          weekKey: e.key.weekKey,
          category: e.key.category,
          amount: e.value,
        ),
    ];
  }

  /// S-D — tiga pembacaan yang WAJIB saling melengkapi:
  ///   dihitung   = !isFixed && sourceBillId IS NULL
  ///   dikecualikan = isFixed || sourceBillId IS NOT NULL   ← komplemen persis
  ///   total      = tanpa syarat tambahan
  /// Invariannya diuji: `dihitung + dikecualikan == total`.
  @override
  Future<int> spentInWeek({required int weekKey, required String category}) =>
      _jumlahMinggu(weekKey: weekKey, category: category, mode: _Mode.dihitung);

  /// Melayani baris penjelas §7.4. Ia melaporkan **seluruh** yang dibuang
  /// proyeksi, bukan tagihan saja: transaksi "Tandai Lunas" untuk tagihan
  /// ber-`isFixedNeed` bulanan lahir dengan `isFixed == true` DAN
  /// `sourceBillId != null` (`bills_bloc.dart:238`), dan kos/listrik adalah
  /// bentuk tagihan yang paling sering user punya.
  @override
  Future<int> excludedInWeek({required int weekKey, required String category}) =>
      _jumlahMinggu(weekKey: weekKey, category: category, mode: _Mode.dikecualikan);

  /// Ada demi invarian rekonsiliasi. Tidak dipakai UI.
  @override
  Future<int> totalExpenseInWeek({
    required int weekKey,
    required String category,
  }) =>
      _jumlahMinggu(weekKey: weekKey, category: category, mode: _Mode.total);

  Future<int> _jumlahMinggu({
    required int weekKey,
    required String category,
    required _Mode mode,
  }) async {
    final t = _db.transactions;
    final jumlah = t.amount.sum();

    // Satu tempat, tiga mode — supaya komplemennya tak bisa berselisih dengan
    // yang dikomplemeni. Dua fungsi terpisah dengan predikat yang ditulis
    // tangan masing-masing adalah bentuk Rev 1, dan di situlah selisihnya lahir.
    final dasar = t.date.isBiggerOrEqualValue(localMidnightOf(weekKey)) &
        t.date.isSmallerThanValue(localMidnightOf(addDays(weekKey, 7))) &
        t.category.equals(category) &
        t.type.equals('expense');

    final operasional = t.isFixed.equals(false) & t.sourceBillId.isNull();

    final q = _db.selectOnly(t)
      ..addColumns([jumlah])
      ..where(switch (mode) {
        _Mode.dihitung => dasar & operasional,
        _Mode.dikecualikan => dasar & operasional.not(),
        _Mode.total => dasar,
      });
    final row = await q.getSingleOrNull();
    return row?.read(jumlah) ?? 0;
  }

  // ─── Baris tantangan ───────────────────────────────────────────────────────

  @override
  Stream<WeeklyChallenge?> watchWeek(int weekKey) =>
      (_db.select(_db.weeklyChallenges)..where((t) => t.weekKey.equals(weekKey)))
          .watchSingleOrNull();

  @override
  Stream<List<WeeklyChallenge>> watchHistory(int limit) =>
      (_db.select(_db.weeklyChallenges)
            ..orderBy([(t) => OrderingTerm.desc(t.weekKey)])
            ..limit(limit))
          .watch();

  /// Preseden bentuknya `transaction_local_datasource.dart:116-118`.
  @override
  Stream<void> watchTransactionTicks() =>
      _db.tableUpdates(TableUpdateQuery.onTable(_db.transactions)).map<void>(
            (_) {},
          );

  @override
  Future<WeeklyChallenge?> findWeek(int weekKey) =>
      (_db.select(_db.weeklyChallenges)..where((t) => t.weekKey.equals(weekKey)))
          .getSingleOrNull();

  /// Bentuk JAMAK dengan sungguh-sungguh: dua baris lampau `active` sekaligus
  /// bisa terjadi lewat jam device yang dimundurkan atau merge lintas-device.
  @override
  Future<List<WeeklyChallenge>> activeWeeksBefore(int weekKey) =>
      (_db.select(_db.weeklyChallenges)
            ..where((t) =>
                t.weekKey.isSmallerThanValue(weekKey) &
                t.status.equalsValue(ChallengeStatus.active))
            ..orderBy([(t) => OrderingTerm.asc(t.weekKey)]))
          .get();

  @override
  Future<void> upsert(WeeklyChallengesCompanion row) =>
      _db.into(_db.weeklyChallenges).insertOnConflictUpdate(row);

  // ─── Penanda lokal — TIDAK menggeser updatedAt maupun isSynced (D23) ───────

  @override
  Future<void> markSynced(int weekKey) =>
      (_db.update(_db.weeklyChallenges)..where((t) => t.weekKey.equals(weekKey)))
          .write(const WeeklyChallengesCompanion(isSynced: Value(true)));

  @override
  Future<void> markResultSeen({required int weekKey, required DateTime at}) =>
      (_db.update(_db.weeklyChallenges)..where((t) => t.weekKey.equals(weekKey)))
          .write(WeeklyChallengesCompanion(resultSeenAt: Value(at)));

  /// D22 — menandai SEMUA hasil belum-dilihat KECUALI [keepWeekKey].
  /// Mengembalikan jumlah baris tersentuh, supaya test bisa membedakan
  /// "tidak ada yang perlu ditandai" dari "gagal menandai".
  @override
  Future<int> markOlderResultsSeen({
    required int keepWeekKey,
    required DateTime at,
  }) =>
      (_db.update(_db.weeklyChallenges)
            ..where((t) =>
                t.weekKey.equals(keepWeekKey).not() &
                t.resultSeenAt.isNull() &
                (t.status.equalsValue(ChallengeStatus.achieved) |
                    t.status.equalsValue(ChallengeStatus.missed))))
          .write(WeeklyChallengesCompanion(resultSeenAt: Value(at)));

  /// M8 — MENGUBAH baris yang sudah ada, bukan upsert. Mengembalikan jumlah
  /// baris tersentuh supaya pemanggil bisa membedakan "berhasil" dari "barisnya
  /// tak ada".
  ///
  /// Kenapa bukan `insertOnConflictUpdate` seperti [upsert]: `resolveWeek` dan
  /// `changeCategory` mengirim companion PARSIAL (tanpa `timezone`/`createdAt`).
  /// Kalau barisnya kebetulan tak ada, upsert akan mencoba INSERT dan melanggar
  /// NOT NULL — gagal di runtime, di jalur yang jarang dilewati test.
  @override
  Future<int> updateWeek(int weekKey, WeeklyChallengesCompanion patch) =>
      (_db.update(_db.weeklyChallenges)
            ..where((t) => t.weekKey.equals(weekKey)))
          .write(patch);

  @override
  Future<List<WeeklyChallenge>> pendingRows() =>
      (_db.select(_db.weeklyChallenges)
            ..where((t) => t.isSynced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.weekKey)]))
          .get();

  // ─── Antrian sinkron ───────────────────────────────────────────────────────

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required String data,
    required SyncOperation operation,
  }) =>
      _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              itemId: itemId,
              collectionPath: collectionPath,
              data: data,
              operation: operation,
              createdAt: DateTime.now().toUtc(),
            ),
          );

  /// Kebenaran lokal saat ini SELALU menang atas apa pun yang masih menunggu
  /// terkirim. Satu weekKey bisa ditulis tiga kali dalam dua hari (buat Senin →
  /// ganti pos → lewati Selasa); tanpa purge, antrian menyimpan tiga payload
  /// untuk satu dokumen dan kebenaran bersandar pada urutan antrian.
  ///
  /// S-A — [docPath] adalah DOC PATH PENUH (`users/{uid}/challenges/{weekKey}`),
  /// bukan path koleksi. Selain karena dispatcher menolak segmen ganjil, ini
  /// yang membuat purge berbutir per-minggu: menutup dua minggu lampau
  /// sekaligus dalam keadaan offline tak lagi membuang antrian saudaranya.
  @override
  Future<int> purgePendingSyncFor(String docPath) =>
      (_db.delete(_db.syncQueue)
            ..where((t) => t.collectionPath.equals(docPath)))
          .go();
}

enum _Mode { dihitung, dikecualikan, total }
