import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/constants/streak_constants.dart';
import 'package:penyintas_app/core/database/app_database.dart'
    show SyncOperation;
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_mark_remote_datasource.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';
import 'package:penyintas_app/features/streak/domain/streak_calculator.dart';

/// ⚠️ KABEL KRITIS (D-17): `watchMarkedDays()` (BERSIH) → parameter
/// `markedDays`; `watchAllMarkDays()` (MENTAH) → parameter `markedDaysAll`.
/// Menukarnya membuat penanda hasil koreksi jam ikut menghitung ruas — persis
/// manipulasi yang seluruh fitur ini dirancang untuk menolak. `markedDaysAll`
/// adalah pass-through murni; `computeStreak()` DILARANG membacanya, jadi
/// pertukaran ini tidak akan pernah tertangkap di level kalkulator.
class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({
    required StreakLocalDatasource local,
    required StreakMarkRemoteDatasource remote,
    required NetworkInfo network,
    required FirebaseAuth auth,
    required AppClock clock,
    int epochDay = kStreakEpochDay,
  }) : _local = local,
       _remote = remote,
       _network = network,
       _auth = auth,
       _clock = clock,
       _epochDay = epochDay;

  final StreakLocalDatasource _local;
  final StreakMarkRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;
  final AppClock _clock;
  final int _epochDay;

  /// Pemicu hitung-ulang dari luar (timer tengah malam, app resume).
  final _pemicu = StreamController<void>.broadcast();

  @override
  void requestRecompute() {
    if (!_pemicu.isClosed) _pemicu.add(null);
  }

  /// HIGIENE TEST SAJA — BUKAN kontrak untuk dipanggil dari BLoC manapun.
  ///
  /// Ketiga langganan stream (`markSub`/`allMarkSub`/`txSub`) dan
  /// `debounceTimer` di `watchSnapshot()` membersihkan diri sendiri lewat
  /// `onCancel` milik `StreamController` yang dibuat baru tiap
  /// `watchSnapshot()` dipanggil — mereka TIDAK bergantung pada method ini.
  /// Yang benar-benar dimiliki `dispose()` hanyalah `_pemicu`, satu broadcast
  /// controller LEVEL-REPOSITORY, dipakai bersama oleh halaman `/consistency`,
  /// tile bento, kartu sore, DAN `DailyReminderScheduler` sekaligus (repo ini
  /// `registerLazySingleton`, satu instance untuk semuanya).
  ///
  /// Menutupnya dari SATU consumer (mis. `StreakBloc.close()` di Task 11)
  /// membuat `requestRecompute()` senyap gagal (no-op lewat guard
  /// `!_pemicu.isClosed`) untuk SEMUA consumer lain sisa umur proses — tanpa
  /// error yang terlihat. `dispose()` di sini murni menghindari warning
  /// "StreamController not closed" di test; produksi tidak pernah
  /// memanggilnya (repository lazy singleton tidak pernah direkonstruksi).
  @override
  void dispose() => _pemicu.close();

  /// Debounce 150 ms: satu batch penyimpanan bisa menyentuh dua tabel yang
  /// keduanya diawasi, dan tanpa debounce kalkulator berjalan dua kali untuk
  /// satu aksi user.
  static const _debounce = Duration(milliseconds: 150);

  @override
  Stream<StreakSnapshot> watchSnapshot() {
    late StreamController<StreakSnapshot> controller;
    StreamSubscription<Set<int>>? markSub;
    StreamSubscription<Set<int>>? allMarkSub;
    StreamSubscription<Set<int>>? txSub;
    StreamSubscription<void>? pemicuSub;
    Timer? debounceTimer;

    var marked = <int>{};
    var markedAll = <int>{}; // D-11/D-17 — mentah, HANYA untuk aturan CTA
    var txDays = <int>{};

    Future<void> hitungSekali() async {
      if (controller.isClosed) return;
      try {
        // KEPUTUSAN D-2: meta DIBACA satu tembak, TIDAK diawasi. Loop
        // tulis→emit→hitung→tulis jadi mustahil secara konstruksi, bukan
        // hanya dijaga sebuah `if` di BLoC.
        final meta = await _local.readMeta();
        if (controller.isClosed) return;
        controller.add(
          computeStreak(
            markedDays: marked,
            markedDaysAll: markedAll,
            transactionDays: txDays,
            epochDay: _epochDay,
            lastSeenDay: meta.lastSeenDay,
            today: localDayKey(_clock.now()),
          ),
        );
      } catch (e, stack) {
        _logError(e, stack, 'watchSnapshot');
        if (controller.isClosed) return;
        // Error event merambat ke stream snapshot — BLoC menangkapnya lewat
        // onError dan menampilkan jalur galat §8.2. Angka 0 yang sebenarnya
        // berarti "gagal baca" adalah kebohongan yang dilarang K10.
        controller.addError(e, stack);
      }
    }

    void jadwalkan() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounce, hitungSekali);
    }

    controller = StreamController<StreakSnapshot>(
      onListen: () {
        markSub = _local.watchMarkedDays().listen(
          (v) {
            marked = v;
            jadwalkan();
          },
          onError: (Object e, StackTrace s) {
            if (!controller.isClosed) controller.addError(e, s);
          },
        );
        // D-11/D-17: himpunan MENTAH untuk aturan CTA. Ia sengaja stream
        // ketiga dan bukan turunan dari `marked` — baris bertanda tidak
        // pernah muncul di sana.
        allMarkSub = _local.watchAllMarkDays().listen(
          (v) {
            markedAll = v;
            jadwalkan();
          },
          onError: (Object e, StackTrace s) {
            if (!controller.isClosed) controller.addError(e, s);
          },
        );
        txSub = _local
            .watchTransactionDays(epochDay: _epochDay)
            .listen(
              (v) {
                txDays = v;
                jadwalkan();
              },
              onError: (Object e, StackTrace s) {
                if (!controller.isClosed) controller.addError(e, s);
              },
            );
        pemicuSub = _pemicu.stream.listen((_) => jadwalkan());
      },
      onCancel: () async {
        debounceTimer?.cancel();
        await markSub?.cancel();
        await allMarkSub?.cancel();
        await txSub?.cancel();
        await pemicuSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<bool> isTodaySafe() async {
    try {
      final today = localDayKey(_clock.now());
      final marked = await _local.readMarkedDays();
      if (marked.contains(today)) return true;
      final tx = await _local.readTransactionDays(epochDay: _epochDay);
      return tx.contains(today);
    } catch (e, stack) {
      _logError(e, stack, 'isTodaySafe');
      return false; // gagal ke arah "pengingat muncul"
    }
  }

  @override
  Future<StreakMetaValues> readMeta() => _local.readMeta();

  @override
  Future<void> saveMeta(StreakMetaValues meta) => _local.saveMeta(meta);

  @override
  Future<Either<Failure, void>> markToday() async {
    try {
      final now = _clock.now();
      final today = localDayKey(now);

      // D-4 — IDEMPOTEN, dan ini yang PERTAMA diperiksa. Baris yang sudah ada
      // tidak pernah disentuh: isinya maupun status sinkronnya. Menaruhnya di
      // atas penjaga jam disengaja — kalau harinya memang sudah ditandai,
      // tidak ada yang akan tercipta, jadi menolaknya dengan pesan galat cuma
      // membingungkan user atas aksi yang sebenarnya tak berefek apa-apa.
      // Ini sekaligus jaring kedua guard tap-ganda §8.1.
      if (await _local.hasMark(today)) return const Right(null);

      final meta = await _local.readMeta();

      // Mode netral penjaga jam (selisih 1–2 hari): penandaan DITOLAK.
      // Pembekuannya maksimal 2 hari dan sembuh sendiri; di luar rentang itu
      // cabang "koreksi jam" sudah melepaskan penjaganya.
      //
      // Ambangnya diukur dalam HARI lewat `addDays()`, BUKAN pengurangan
      // `yyyymmdd` mentah — jebakan yang sama persis yang sudah diperbaiki di
      // `streak_calculator.dart` (`_selisihHari`): `20261001 - 20260930` = 71,
      // padahal jaraknya satu hari. Perbandingan `<`/`>=` antar `dayKey` aman
      // karena urutan `yyyymmdd` sudah sejalan dengan urutan kalender; yang
      // tidak boleh cuma ARITMETIKAnya.
      if (today < meta.lastSeenDay && today >= addDays(meta.lastSeenDay, -2)) {
        return Left(
          ValidationFailure(
            'Jam perangkat sedang tidak cocok. Coba lagi nanti.',
          ),
        );
      }

      // Waktu nyata tidak pernah berjalan mundur. Hari device yang jatuh jauh
      // DI BAWAH hari tertinggi yang pernah tercatat hanya bisa berarti jam
      // dimanipulasi atau RTC benar-benar reset — keduanya diperlakukan sama.
      //
      // PEMBANDINGNYA `maxSeenDay`, BUKAN `lastSeenDay`: `lastSeenDay` sudah
      // diturunkan StreakBloc saat snapshot dihitung, jauh sebelum user
      // menekan tombol, sehingga selisihnya selalu nol di titik ini.
      //
      // `maxSeenDay > 0` menjaga meta kosong (akun baru / sesudah logout):
      // `addDays(0, -2)` akan menghitung mundur dari tanggal tak bermakna.
      final viaClockCorrection =
          meta.maxSeenDay > 0 && today < addDays(meta.maxSeenDay, -2);

      // `timeZoneName` memberi SINGKATAN device ("WIB", "+07"), bukan id IANA
      // seperti contoh "Asia/Jakarta" di spec §6.1. Dibiarkan begitu dengan
      // sadar: kolom ini murni jejak audit, tak pernah dibaca logika mana pun,
      // dan menariknya dari `tz.local.name` akan mengikat penandaan pada
      // urutan inisialisasi paket timezone milik lapisan notifikasi.
      await _local.insertMark(
        dayKey: today,
        markedAt: now.toUtc(),
        timezone: now.timeZoneName,
        viaClockCorrection: viaClockCorrection,
      );
      requestRecompute();

      // Baris bertanda TIDAK PERNAH disinkronkan. Kalau ia diunggah, reinstall
      // menariknya kembali TANPA tanda dan membatalkan seluruh pengecualian
      // ini — penjaga yang hidup hanya di lapisan lokal sementara datanya
      // hidup lebih lama dari lapisan itu. Barisnya tetap ada, tidak dihapus,
      // tanpa peringatan apa pun ke user.
      if (viaClockCorrection) return const Right(null);

      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null); // data tetap aman di lokal

      final path = 'users/$uid/streak_marks/$today';
      // Aturan anti-race (berlaku dua arah): buang dulu item tertunda untuk
      // path yang sama persis. Kebenaran lokal saat ini selalu menang atas
      // apa pun yang masih menunggu terkirim.
      await _local.purgePendingSyncFor(path);

      final model = StreakMarkModel(
        dayKey: today,
        markedAt: now.toUtc(),
        timezone: now.timeZoneName,
      );
      final data = model.toFirestore(updatedAtMs: now.millisecondsSinceEpoch);

      if (await _network.isConnected) {
        try {
          await _remote.saveMark(model);
          await _local.markSynced(today);
          return const Right(null);
        } catch (e, s) {
          _logError(e, s, 'markToday.push');
        }
      }
      await _local.addToSyncQueue(
        itemId: '$today',
        collectionPath: path,
        data: data,
        operation: SyncOperation.create,
      );
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'markToday');
      return Left(CacheFailure('Gagal menyimpan penanda hari ini.'));
    }
  }

  @override
  Future<Either<Failure, void>> unmarkToday() async {
    try {
      final today = localDayKey(_clock.now());

      // SATU pembacaan menutup dua lubang sekaligus:
      //
      //  D-8 — kalau tengah malam lewat selagi SnackBar undo masih hidup
      //  (5 detik, dan §7.5 menundanya lebih lama lagi lewat perayaan),
      //  `today` di sini sudah hari yang BERBEDA dari hari yang tadi
      //  ditandai. Tanpa penjaga ini ia akan menghapus — dan mengantre
      //  delete untuk — hari yang tidak pernah diurungkan siapa pun.
      //
      //  D-5 — baris bertanda tak pernah punya dokumen remote. Kalau hari itu
      //  KEBETULAN punya dokumen sah dari device lain, mengantre delete akan
      //  menghapus penanda jujur milik device itu.
      final row = await _local.findMark(today);
      if (row == null) return const Right(null);

      // Undo adalah PENGHAPUSAN BARIS, bukan penandaan-terbalik.
      await _local.deleteMark(today);
      requestRecompute();

      if (row.viaClockCorrection) return const Right(null);

      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final path = 'users/$uid/streak_marks/$today';
      final createDibuang = await _local.purgePendingSyncFor(path);
      // TEMUAN C1 — `createDibuang > 0` SENDIRIAN tidak cukup. Ada DUA jalur
      // unggah yang tidak saling tahu: `markToday()` offline mengantre
      // `create` ke `SyncQueue`, TAPI `pushPendingMarks()` (bootstrap login
      // berikutnya) mendorong baris itu lewat `_remote.saveMark()`
      // LANGSUNG lalu `markSynced()` — ia tidak pernah menyentuh
      // `SyncQueue`. Kalau itu yang terjadi, dokumen remote SUDAH ADA
      // (`row.isSynced == true`) sekalipun `create` basi masih kebetulan
      // nangkring di antrean (mis. belum sempat diproses `SyncService`).
      // Purge di atas membuangnya, tapi itu tak berarti "dokumen remote
      // belum pernah ada" — jadi wajib periksa `row.isSynced` juga sebelum
      // memutuskan delete tidak perlu diantre.
      if (createDibuang > 0 && !row.isSynced) {
        // Purge baru saja membuang satu-satunya `create` yang belum pernah
        // terkirim — dokumen remote memang belum pernah ada.
        return const Right(null);
      }

      // Sisanya: barisnya bersih dan dokumen remote memang pernah (atau
      // mungkin pernah) tersinkron. Mengantre delete aman & idempoten —
      // menghapus dokumen yang tak ada adalah no-op di Firestore, dan rules
      // mengizinkannya.
      await _local.addToSyncQueue(
        itemId: '$today',
        collectionPath: path,
        data: const <String, dynamic>{},
        operation: SyncOperation.delete,
      );
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'unmarkToday');
      return Left(CacheFailure('Gagal membatalkan penanda hari ini.'));
    }
  }

  /// KEPUTUSAN `sinceDayKey` (wajib diputuskan sadar — lihat brief Task 8):
  ///
  /// Method ini TIDAK meniru gerbang `hasAnyGoals()` milik
  /// `GoalRepositoryImpl.syncGoalsFromRemote()` (bootstrap sekali-lalu-tak-
  /// pernah-lagi) — lihat catatan di bawah `Future.wait` untuk alasannya
  /// (himpunan hari bisa bertambah dari device lain, bukan daftar tetap).
  /// Karena itu ia PASTI dipanggil berkala (tiap sesi login), sehingga
  /// `sinceDayKey` WAJIB dibatasi — default `0` pada `getMarks()` (tarik
  /// SELURUH riwayat dokumen user) tidak boleh pernah benar-benar terpakai
  /// di jalur produksi ini.
  ///
  /// Nilai yang dipakai: `_epochDay` (`kStreakEpochDay`), BUKAN
  /// `meta.maxSeenDay`. `kStreakEpochDay` adalah batas bawah MUTLAK — hari
  /// sebelum epoch tidak pernah ikut dihitung `computeStreak()` (K11), jadi
  /// menarik dokumen sebelum epoch hanya memateri baris yang kalkulator toh
  /// buang. `maxSeenDay` TIDAK dipakai karena ia bisa lebih besar dari
  /// dayKey dokumen yang justru hilang dari lokal (mis. reinstall di hari
  /// ke-40 dari ruas 60 hari) — membatasi ke situ akan membuat T15
  /// (pemulihan riwayat) hanya menarik ekor ruas, bukan seluruhnya.
  /// `_epochDay` tetap konstan sepanjang umur app (beku sejak merge, lihat
  /// `streak_constants.dart`), jadi jendela tarikan ini tidak pernah melebar
  /// dari sesi ke sesi — `deleteSyncedMarksAbsentFrom` di bawah pun dibatasi
  /// jendela yang sama, sehingga diff select-lalu-hapusnya tidak pernah lebih
  /// lebar dari seluruh riwayat sejak epoch (bukan seluruh riwayat dokumen).
  @override
  Future<Either<Failure, int>> syncMarksFromRemote() async {
    try {
      if (!await _network.isConnected) return const Right(0);
      if (_auth.currentUser == null) return const Right(0);

      // TARIK SAJA (D-9). Dorongan pindah ke `pushPendingMarks()` yang
      // dipanggil DI LUAR `Future.wait` — method ini dibungkus
      // `.timeout(_stepTimeout)` 3 detik oleh pemanggilnya, dan N panggilan
      // jaringan berurutan tidak akan pernah muat di dalamnya. Menaruh
      // dorongan lebih dulu di sini membuat timeout di tengah dorongan
      // membuat tarikannya TIDAK PERNAH dijalankan sama sekali.
      //
      // Tarik-dulu aman: `insertOrIgnore` secara konstruksi tidak bisa
      // menutupi baris lokal yang belum sempat naik.
      //
      // Catatan galat sebagian (bawaan Task 7, bukan ditambal di sini):
      // `getMarks()` gagal TOTAL — bukan sebagian — bila satu dokumen
      // remote punya field bertipe salah (mis. `dayKey` bukan angka dari
      // edit manual console / Admin SDK / bug klien lama). Diterima apa
      // adanya: seluruh method ini jatuh ke `catch` di bawah dan
      // mengembalikan `CacheFailure`, TANPA menyentuh baris lokal apa pun —
      // gagal aman, bukan gagal diam-diam. Isolasi per-dokumen di luar
      // lingkup Task 8.
      final models = await _remote.getMarks(sinceDayKey: _epochDay);
      await _local.upsertMarksFromRemote(models);

      // D-13: remote berwenang untuk baris yang PERNAH naik. Undo yang
      // dilakukan di device lain menghapus dokumennya; tanpa baris ini,
      // `pushPendingMarks()` akan membangkitkannya kembali dan membatalkan
      // keputusan user tanpa jejak. Baris `isSynced == false` adalah milik
      // lokal yang belum sempat naik — TIDAK PERNAH disentuh aturan ini.
      // Kontrak method ini didefinisikan di Task 6 (D-14) — lihat di sana
      // sebelum menulis ulang isinya di sini.
      await _local.deleteSyncedMarksAbsentFrom(
        models.map((m) => m.dayKey).toSet(),
        sinceDayKey: _epochDay,
      );

      requestRecompute();
      return Right(models.length);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, s) {
      _logError(e, s, 'syncMarksFromRemote');
      return Left(CacheFailure('Gagal memulihkan catatan konsistensi.'));
    }
  }

  /// Batas dorongan per sesi login. Backlog yang lebih besar terkuras di
  /// login berikutnya; ia tidak boleh menyandera bootstrap bermenit-menit.
  static const kMaxPushPerSession = 100;

  @override
  Future<int> pushPendingMarks() async {
    try {
      if (!await _network.isConnected) return 0;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 0;

      // `SyncQueue` membuang itemnya sendiri sesudah 7 hari
      // (`sync_service.dart:61-77`) dan TIDAK ADA yang pernah mengantre
      // ulang. Tanpa jalur ini, penanda yang dibuat saat offline lebih dari
      // sepekan hilang PERMANEN begitu user logout — janji T15 hanya berlaku
      // di test.
      final belumNaik = await _local.readUnsyncedMarks();
      var naik = 0;
      for (final row in belumNaik.take(kMaxPushPerSession)) {
        try {
          // D-15 — baca ulang SEBELUM mengirim. Method ini tidak lewat
          // `SyncQueue`, jadi tidak ikut memakai purge-sebelum-enqueue yang
          // Task 9 bangun untuk `markToday()`/`unmarkToday()` (S1/T25).
          // Baris bisa lenyap (diurungkan) atau berubah `viaClockCorrection`
          // sejak `readUnsyncedMarks()` di atas dipanggil.
          final sebelum = await _local.findMark(row.dayKey);
          if (sebelum == null || sebelum.viaClockCorrection) continue;

          await _remote.saveMark(
            StreakMarkModel(
              dayKey: row.dayKey,
              markedAt: row.markedAt,
              timezone: row.timezone,
            ),
          );

          // Baca ULANG lagi sesudah unggah berhasil: undo bisa menang tepat
          // di jendela network round-trip di atas. Tanpa ini, penanda yang
          // baru saja diurungkan user terunggah ulang tanpa jejak apa pun
          // yang memerintahkan penghapusannya — undo dibatalkan diam-diam.
          final sesudah = await _local.findMark(row.dayKey);
          if (sesudah == null) {
            await _remote.deleteMark(row.dayKey);
            continue;
          }
          await _local.markSynced(row.dayKey);

          // TEMUAN C1 (menyeluruh) — jalur ini naik LANGSUNG lewat
          // `_remote.saveMark()`, bukan lewat `SyncQueue`, jadi purge-
          // sebelum-enqueue yang dipakai `markToday()`/`unmarkToday()` tidak
          // pernah menyentuhnya. Kalau baris ini SEBELUMNYA dibuat offline,
          // item `create` untuk path yang sama masih bisa nangkring di
          // antrean sekarang jadi basi (dokumen remote sudah ada lewat
          // baris di atas). Purge di sini menutup jalur kedua: tanpanya,
          // undo berikutnya yang menemukan antrean sudah kosong (mis.
          // `SyncService` sempat memprosesnya duluan) tidak salah kira —
          // tapi kalau BELUM diproses, `create` basi itu tetap tak berguna
          // menunggu di antrean sampai TTL 7 hari.
          await _local.purgePendingSyncFor(
            'users/$uid/streak_marks/${row.dayKey}',
          );
          naik++;
        } catch (e, s) {
          // Satu baris gagal tidak boleh menggagalkan sisanya. Ia tetap
          // `isSynced = false` dan dicoba lagi sesi berikutnya — itulah
          // gunanya kolom itu sekarang punya pembaca.
          _logError(e, s, 'pushPendingMarks');
        }
      }
      return naik;
    } catch (e, s) {
      _logError(e, s, 'pushPendingMarks');
      return 0; // non-fatal: bootstrap tidak boleh gagal karena ini
    }
  }

  static void _logError(Object e, StackTrace stack, String konteks) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: konteks);
    } catch (_) {}
  }
}
