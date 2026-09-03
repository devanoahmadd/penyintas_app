import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';

abstract class StreakLocalDatasource {
  Stream<Set<int>> watchMarkedDays();

  /// Penanda MENTAH, termasuk baris `viaClockCorrection` (D-11/D-17).
  /// HANYA untuk pertanyaan "sudah pernah ditekan?".
  Stream<Set<int>> watchAllMarkDays();

  Future<Set<int>> readMarkedDays();
  Stream<Set<int>> watchTransactionDays({required int epochDay});
  Future<Set<int>> readTransactionDays({required int epochDay});
  Future<StreakMetaValues> readMeta();
  Future<void> saveMeta(StreakMetaValues meta);

  /// TIDAK PERNAH menimpa baris yang sudah ada (D-4).
  Future<void> insertMark({
    required int dayKey,
    required DateTime markedAt,
    required String timezone,
    required bool viaClockCorrection,
  });

  /// Baris apa adanya — dipakai `markToday()`/`unmarkToday()` untuk memutuskan
  /// (D-4, D-5, D-8). `null` berarti hari itu memang belum pernah ditandai.
  Future<StreakDayMark?> findMark(int dayKey);
  Future<bool> hasMark(int dayKey);

  /// Baris yang belum pernah sampai ke Firestore DAN layak dikirim (D-6).
  /// Diurutkan `dayKey` MENAIK: yang paling tua paling dekat dengan TTL
  /// 7 hari `SyncQueue`, jadi ia yang harus lolos batas `kMaxPushPerSession`
  /// lebih dulu (D-18).
  Future<List<StreakDayMark>> readUnsyncedMarks();

  Future<void> deleteMark(int dayKey);
  Future<void> markSynced(int dayKey);

  /// Buang item `SyncQueue` tertunda untuk [collectionPath] yang sama persis.
  /// Mengembalikan jumlah item ber-operasi `create` yang dibuang.
  Future<int> purgePendingSyncFor(String collectionPath);

  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  });

  /// Hapus baris lokal yang SUDAH tersinkron namun TIDAK ADA lagi di hasil
  /// tarikan (D-14, dipakai `syncMarksFromRemote()` Task 8). Remote berwenang
  /// untuk baris yang PERNAH naik; baris `isSynced == false` (belum sempat
  /// naik) TIDAK PERNAH disentuh method ini.
  Future<void> deleteSyncedMarksAbsentFrom(
    Set<int> survivingDayKeys, {
    required int sinceDayKey,
  });

  /// Tarik-dari-remote: insert bila belum ada, JANGAN timpa baris lokal.
  /// Baris lokal bisa memegang `viaClockCorrection`; menimpanya akan mencuci
  /// tanda itu — persis kelas kesalahan yang aturan "tak pernah disinkronkan"
  /// dibuat untuk mencegah.
  Future<void> upsertMarksFromRemote(List<StreakMarkModel> models);
}

class StreakLocalDatasourceImpl implements StreakLocalDatasource {
  StreakLocalDatasourceImpl(this._db);

  final AppDatabase _db;

  /// Paralel hook B2 (lihat [readTransactionDays]): baris via-koreksi-jam
  /// dibuang DI SINI, bukan di kalkulator, supaya `computeStreak()` tetap
  /// murni & bisa diuji tanpa database.
  SimpleSelectStatement<$StreakDayMarksTable, StreakDayMark> _bersih() =>
      _db.select(_db.streakDayMarks)
        ..where((t) => t.viaClockCorrection.equals(false));

  @override
  Stream<Set<int>> watchMarkedDays() =>
      _bersih().watch().map((rows) => rows.map((r) => r.dayKey).toSet());

  /// MENTAH — tanpa filter `viaClockCorrection` (D-11/D-17). Ia menjawab
  /// "sudah pernah ditekan?", bukan "menghitung?". Dipakai HANYA oleh aturan
  /// CTA; replay dan `cellFor` tetap memakai [watchMarkedDays].
  @override
  Stream<Set<int>> watchAllMarkDays() => _db
      .select(_db.streakDayMarks)
      .watch()
      .map((rows) => rows.map((r) => r.dayKey).toSet());

  @override
  Future<Set<int>> readMarkedDays() async =>
      (await _bersih().get()).map((r) => r.dayKey).toSet();

  /// Proyeksi sempit lewat query builder Drift, pengelompokan di Dart.
  ///
  /// TIDAK memakai `GROUP BY` SQL: Drift menyimpan DateTime sebagai INTEGER
  /// unix-detik UTC, sehingga mengelompokkan per hari LOKAL menuntut
  /// `date(date,'unixepoch','localtime')` — sebuah `customStatement`, yang
  /// pola Drift proyek ini larang untuk query standar. Lagipula aturan hari
  /// aman butuh DUA kolom sekaligus (`date` dan `createdAt` dalam jendela
  /// D..D+2) — itu predikat dua-dimensi, bukan agregasi satu kolom.
  ///
  /// Filternya tetap di SQL agar index `idx_transactions_date` terpakai, dan
  /// yang ditarik HANYA dua kolom (`selectOnly` + `addColumns`) — bukan baris
  /// penuh. Ini bukan gaya: query ini berjalan ulang di setiap perubahan tabel
  /// transaksi, dan pada akun tiga tahun (~11 ribu baris) menarik seluruh
  /// kolom berarti memateri ulang seluruh tabel paling ramai di app, di HP
  /// kelas bawah, hanya untuk membaca dua tanggal.
  JoinedSelectStatement<$TransactionsTable, Transaction> _txSejak(
    int epochDay,
  ) =>
      _db.selectOnly(_db.transactions)
        ..addColumns([_db.transactions.date, _db.transactions.createdAt])
        ..where(
          _db.transactions.date.isBiggerOrEqualValue(
            localMidnightOf(epochDay),
          ),
        );

  Set<int> _keHariAman(List<TypedResult> rows) {
    final days = <int>{};
    for (final r in rows) {
      // hook B2: transaksi buatan sistem dilewati di sini saat B2 Transaksi
      // Berulang dibangun — streak mencerminkan kehadiran user, bukan cron.
      final d = localDayKey(r.read(_db.transactions.date)!);
      final c = localDayKey(r.read(_db.transactions.createdAt)!);
      // Batas bawah menutup celah menabung streak di muka; batas atas adalah
      // jendela penyusulan 2 hari (K5).
      if (c >= d && c <= addDays(d, 2)) days.add(d);
    }
    return days;
  }

  @override
  Stream<Set<int>> watchTransactionDays({required int epochDay}) =>
      _txSejak(epochDay).watch().map(_keHariAman);

  @override
  Future<Set<int>> readTransactionDays({required int epochDay}) async =>
      _keHariAman(await _txSejak(epochDay).get());

  @override
  Future<StreakMetaValues> readMeta() async {
    final row = await (_db.select(
      _db.streakMeta,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    // Baris hilang bukan galat: clearAllLocalData() menyapunya saat logout
    // dan HANYA membuat ulang baris preferences.
    if (row == null) return StreakMetaValues.empty;
    return StreakMetaValues(
      lastSeenDay: row.lastSeenDay,
      maxSeenDay: row.maxSeenDay,
      lastCelebratedRuas: row.lastCelebratedRuas,
      clockAnomalyCount: row.clockAnomalyCount,
      acknowledgedBreakDay: row.acknowledgedBreakDay,
    );
  }

  @override
  Future<void> saveMeta(StreakMetaValues meta) => _db
      .into(_db.streakMeta)
      .insertOnConflictUpdate(
        StreakMetaCompanion.insert(
          id: const Value(1),
          lastSeenDay: Value(meta.lastSeenDay),
          maxSeenDay: Value(meta.maxSeenDay),
          lastCelebratedRuas: Value(meta.lastCelebratedRuas),
          clockAnomalyCount: Value(meta.clockAnomalyCount),
          acknowledgedBreakDay: Value(meta.acknowledgedBreakDay),
        ),
      );

  /// `insertOrIgnore`, BUKAN `insertOnConflictUpdate` (D-4). Baris yang sudah
  /// ada tidak boleh tersentuh: kalau jam device mundur ke hari yang KEBETULAN
  /// sudah pernah ditandai jujur, menimpanya akan menurunkan penanda itu jadi
  /// `viaClockCorrection` dan memutus ruas user yang tidak curang apa pun —
  /// sekaligus membuat lokal berselisih dengan dokumen remote yang tetap
  /// bersih. Mustahil secara konstruksi lebih baik daripada dijaga sebuah `if`.
  ///
  /// `dayKey` WAJIB dibungkus `Value(...)` di sini. Drift memperlakukan
  /// `dayKey` sebagai alias `rowid` SQLite (satu-satunya `IntColumn` primary
  /// key tanpa default eksplisit), sehingga generator membuatnya OPSIONAL
  /// (`Value<int>` berdefault `Value.absent()`) di `Companion.insert` —
  /// BUKAN `int` wajib. Melupakan baris ini tetap mengompilasi dan diam-diam
  /// menghasilkan rowid auto-increment (1, 2, 3, …), bukan `yyyymmdd`. Lihat
  /// test "T31" dan test watchMarkedDays yang membuktikan round-trip
  /// `dayKey`.
  @override
  Future<void> insertMark({
    required int dayKey,
    required DateTime markedAt,
    required String timezone,
    required bool viaClockCorrection,
  }) => _db
      .into(_db.streakDayMarks)
      .insert(
        StreakDayMarksCompanion.insert(
          dayKey: Value(dayKey),
          markedAt: markedAt,
          timezone: timezone,
          viaClockCorrection: Value(viaClockCorrection),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  Future<StreakDayMark?> findMark(int dayKey) => (_db.select(
    _db.streakDayMarks,
  )..where((t) => t.dayKey.equals(dayKey))).getSingleOrNull();

  @override
  Future<bool> hasMark(int dayKey) async => await findMark(dayKey) != null;

  /// Baris via-koreksi-jam sengaja TIDAK PERNAH ikut — ia tak boleh naik ke
  /// Firestore dalam keadaan apa pun (spec §4.7).
  @override
  Future<List<StreakDayMark>> readUnsyncedMarks() =>
      (_db.select(_db.streakDayMarks)
            ..where(
              (t) =>
                  t.isSynced.equals(false) &
                  t.viaClockCorrection.equals(false),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.dayKey)]))
          .get();

  @override
  Future<void> deleteMark(int dayKey) => (_db.delete(
    _db.streakDayMarks,
  )..where((t) => t.dayKey.equals(dayKey))).go();

  @override
  Future<void> markSynced(int dayKey) =>
      (_db.update(_db.streakDayMarks)..where((t) => t.dayKey.equals(dayKey)))
          .write(const StreakDayMarksCompanion(isSynced: Value(true)));

  @override
  Future<int> purgePendingSyncFor(String collectionPath) async {
    final tertunda = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.collectionPath.equals(collectionPath))).get();
    if (tertunda.isEmpty) return 0;
    await (_db.delete(
      _db.syncQueue,
    )..where((t) => t.collectionPath.equals(collectionPath))).go();
    return tertunda.where((e) => e.operation == SyncOperation.create).length;
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) => _db
      .into(_db.syncQueue)
      .insert(
        SyncQueueCompanion(
          itemId: Value(itemId),
          collectionPath: Value(collectionPath),
          data: Value(jsonEncode(data)),
          operation: Value(operation),
          createdAt: Value(DateTime.now()),
        ),
      );

  /// D-14. Kandidatnya disaring dua kali: `isSynced` (hanya baris yang
  /// PERNAH naik) dan `viaClockCorrection` (baris itu tak pernah punya
  /// dokumen remote sama sekali — absennya dari tarikan tidak berarti apa
  /// pun, jadi tak boleh jadi alasan penghapusan).
  @override
  Future<void> deleteSyncedMarksAbsentFrom(
    Set<int> survivingDayKeys, {
    required int sinceDayKey,
  }) async {
    final kandidat = await (_db.select(_db.streakDayMarks)..where(
          (t) =>
              t.isSynced.equals(true) &
              t.viaClockCorrection.equals(false) &
              t.dayKey.isBiggerOrEqualValue(sinceDayKey),
        ))
        .get();
    final dibuang = kandidat
        .where((r) => !survivingDayKeys.contains(r.dayKey))
        .map((r) => r.dayKey)
        .toList();
    if (dibuang.isEmpty) return;
    await (_db.delete(
      _db.streakDayMarks,
    )..where((t) => t.dayKey.isIn(dibuang))).go();
  }

  /// `insertOrIgnore`, sama seperti [insertMark] (D-4 versi tarik). Baris
  /// lokal yang sudah ada — jujur maupun `viaClockCorrection` — tidak boleh
  /// tersentuh: dokumen remote tidak pernah membawa `viaClockCorrection`
  /// sama sekali, jadi menimpa akan mencuci tanda itu tanpa jejak.
  @override
  Future<void> upsertMarksFromRemote(List<StreakMarkModel> models) async {
    await _db.transaction(() async {
      for (final m in models) {
        await _db
            .into(_db.streakDayMarks)
            .insert(
              StreakDayMarksCompanion.insert(
                // WAJIB Value(...): dayKey adalah alias rowid (PK tanpa
                // default), generator membuatnya opsional di Companion.insert.
                dayKey: Value(m.dayKey),
                markedAt: m.markedAt,
                timezone: m.timezone,
                isSynced: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
