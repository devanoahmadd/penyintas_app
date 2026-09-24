import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/audit_timezone.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

/// T17 aturan 2 — peringkat presedensi merge.
/// Status terselesaikan SELALU menang atas `active`: minggu yang sudah tuntas
/// tidak boleh dibangkitkan kembali oleh baris `active` basi dari device lain.
int mergeRank(ChallengeStatus s) => s == ChallengeStatus.active ? 1 : 2;

/// true bila baris remote harus menimpa baris lokal.
bool remoteMenang({
  required ChallengeStatus lokalStatus,
  required DateTime lokalUpdatedAt,
  required ChallengeStatus remoteStatus,
  required DateTime remoteUpdatedAt,
}) {
  final rl = mergeRank(lokalStatus);
  final rr = mergeRank(remoteStatus);
  if (rr != rl) return rr > rl;
  return remoteUpdatedAt.isAfter(lokalUpdatedAt);
}

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl({
    required ChallengeLocalDatasource local,
    required ChallengeRemoteDatasource remote,
    required NetworkInfo network,
    required FirebaseAuth auth,
    required AppClock clock,
    required GetLimitableCategoriesUseCase getLimitable,
    required ChallengeSettingsDatasource settings,
  }) : _local = local,
       _remote = remote,
       _network = network,
       _auth = auth,
       _clock = clock,
       _getLimitable = getLimitable,
       _settings = settings;

  final ChallengeLocalDatasource _local;
  final ChallengeRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;
  final AppClock _clock;

  /// Dipakai HANYA oleh `watchInputs`: sakelar fitur adalah salah satu dari
  /// EMPAT stream yang digabung di sana. Ia ikut karena menyalakannya di
  /// Pengaturan tidak mengubah satu pun tabel yang diawasi tiga stream
  /// lainnya — tanpa dia, layar baru menyusul ketika ada perubahan tabel lain
  /// yang kebetulan memicu emit.
  final ChallengeSettingsDatasource _settings;

  /// Dipakai HANYA oleh `getCandidates`: kandidat wajib disaring ke kategori
  /// yang benar-benar bisa diberi batas anggaran (T3). Sumbernya usecase
  /// domain fitur transaksi — arah data→domain, arah yang memang sah — dan
  /// bukan tabel kategori langsung, supaya definisi "limitable" tetap satu.
  final GetLimitableCategoriesUseCase _getLimitable;

  /// S-A — DOC PATH PENUH. `users/$uid/challenges` (3 segmen) ditolak
  /// `sync_dispatcher.dart:15-23` sebagai malformed dan dihapus seketika oleh
  /// `sync_service.dart:88`; setiap tulisan offline akan hilang tanpa jejak
  /// selain satu log Crashlytics. Bentuk ini juga yang dipakai streak
  /// (`streak_repository_impl.dart:266`).
  String _docPath(String uid, int weekKey) => 'users/$uid/challenges/$weekKey';

  /// TARIKAN — blok tersendiri. JANGAN menggabungkannya dengan dorongan:
  /// di Fase 1, push yang ditaruh di dalam blok pull ber-timeout membuat pull
  /// tak pernah jalan, dan riwayat user tak pernah pulih meski semua test hijau.
  @override
  Future<Either<Failure, void>> syncChallengesFromRemote() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final sejak = _weekKeyMundur(kChallengeHistoryWeeks);
      final remoteRows = await _remote.fetchChallenges(uid, sejak);

      for (final m in remoteRows) {
        final lokal = await _local.findWeek(m.weekKey);
        if (lokal != null &&
            !remoteMenang(
              lokalStatus: lokal.status,
              lokalUpdatedAt: lokal.updatedAt,
              remoteStatus: m.status,
              remoteUpdatedAt: m.updatedAt,
            )) {
          continue;
        }
        // resultSeenAt lokal DIPERTAHANKAN — tanpa ini, tiap sinkron
        // memunculkan ulang kartu hasil yang sudah user tutup.
        await _local.upsert(
          m.toCompanion(keepResultSeenAt: lokal?.resultSeenAt, isSynced: true),
        );
      }
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'syncChallengesFromRemote');
      return Left(ServerFailure('Gagal menarik riwayat tantangan.'));
    }
  }

  /// DORONGAN — blok tersendiri dengan anggaran waktu sendiri.
  @override
  Future<Either<Failure, void>> pushPendingChallenges() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);
      if (!await _network.isConnected) return const Right(null);

      for (final row in await _local.pendingRows()) {
        try {
          await _remote.upsertChallenge(uid, ChallengeModel.fromRow(row));
          await _local.markSynced(row.weekKey);
        } catch (e, s) {
          _log(e, s, 'pushPendingChallenges.${row.weekKey}');
        }
      }
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'pushPendingChallenges');
      return Left(ServerFailure('Gagal mengirim tantangan tertunda.'));
    }
  }

  @override
  Future<Either<Failure, void>> createChallenge({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) async {
    try {
      final now = _clock.now();
      // Companion LENGKAP (timezone + createdAt ikut), jadi upsert aman —
      // inilah baris yang memang boleh lahir. Bandingkan `resolveWeek` yang
      // parsial dan karena itu lewat `_ubahDanKirim`.
      await _buatDanKirim(
        WeeklyChallengesCompanion(
          weekKey: Value(weekKey),
          category: Value(category),
          targetAmount: Value(targetAmount),
          baselineAmount: Value(baselineAmount),
          status: const Value(ChallengeStatus.active),
          timezone: Value(zonaAudit(now.timeZoneName, now.timeZoneOffset)),
          createdAt: Value(now.toUtc()),
          updatedAt: Value(now.toUtc()),
          isSynced: const Value(false),
        ),
        weekKey,
      );
      return const Right(null);
    } catch (e, s) {
      // Konvensi repo (`streak_repository_impl.dart:98,178,198,303,391`):
      // SETIAP method tulis ber-`Either` dibungkus. Tanpa ini, kegagalan Drift
      // tak terduga meledak keluar alih-alih jadi `Left` yang bisa ditangani.
      _log(e, s, 'createChallenge');
      return Left(CacheFailure('Gagal membuat tantangan.'));
    }
  }

  /// T11 — kategori/target/basis sengaja NULL: minggu ini tak pernah punya
  /// tantangan, dan riwayat merender "—". Statusnya FINAL: tidak pernah
  /// di-upgrade jadi `active` di hari berikutnya.
  @override
  Future<Either<Failure, void>> holdWeek(int weekKey) async {
    try {
      final now = _clock.now();
      await _buatDanKirim(
        WeeklyChallengesCompanion(
          weekKey: Value(weekKey),
          category: const Value(null),
          targetAmount: const Value(null),
          baselineAmount: const Value(null),
          status: const Value(ChallengeStatus.held),
          timezone: Value(zonaAudit(now.timeZoneName, now.timeZoneOffset)),
          createdAt: Value(now.toUtc()),
          updatedAt: Value(now.toUtc()),
          resolvedAt: Value(now.toUtc()),
          isSynced: const Value(false),
        ),
        weekKey,
      );
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'holdWeek');
      return Left(CacheFailure('Gagal menahan minggu ini.'));
    }
  }

  /// Field ber-payload berubah → updatedAt DIGESER (D23).
  ///
  /// M8 — `_ubahDanKirim`, bukan upsert: companion ini PARSIAL (tanpa
  /// `timezone`/`createdAt`), jadi kalau barisnya tak ada, upsert akan mencoba
  /// INSERT dan melanggar NOT NULL. Update yang mengenai nol baris dilaporkan
  /// sebagai `Left` — kegagalan yang jujur, bukan insert diam.
  @override
  Future<Either<Failure, void>> resolveWeek({
    required int weekKey,
    required ChallengeStatus status,
    required int finalSpent,
  }) async {
    try {
      final now = _clock.now();
      final berhasil = await _ubahDanKirim(
        weekKey,
        WeeklyChallengesCompanion(
          status: Value(status),
          finalSpent: Value(finalSpent),
          resolvedAt: Value(now.toUtc()),
          updatedAt: Value(now.toUtc()),
        ),
      );
      if (!berhasil) {
        return Left(CacheFailure('Minggu tantangan itu tidak ditemukan.'));
      }
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'resolveWeek');
      return Left(CacheFailure('Gagal menutup minggu tantangan.'));
    }
  }

  /// T14 — target DAN basis dihitung ulang dari kategori baru. Kalau target
  /// lama terbawa, user bisa memilih pos termurah sambil menyandang target pos
  /// termahal, dan kedua angka tampak wajar sendiri-sendiri di UI.
  @override
  Future<Either<Failure, void>> changeCategory({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) async {
    try {
      final now = _clock.now();
      // M8 — parsial (tanpa timezone/createdAt/status), jadi `_ubahDanKirim`.
      final berhasil = await _ubahDanKirim(
        weekKey,
        WeeklyChallengesCompanion(
          category: Value(category),
          targetAmount: Value(targetAmount),
          baselineAmount: Value(baselineAmount),
          updatedAt: Value(now.toUtc()),
        ),
      );
      if (!berhasil) {
        return Left(CacheFailure('Minggu tantangan itu tidak ditemukan.'));
      }
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'changeCategory');
      return Left(CacheFailure('Gagal mengganti pos tantangan.'));
    }
  }

  /// Kolom lokal saja: TIDAK menggeser updatedAt, TIDAK menyetel isSynced=false
  /// — menandai baris "belum tersinkron" akan mendorong ulang dokumen yang
  /// isinya identik, tiap kali user menutup kartu.
  @override
  Future<Either<Failure, void>> markResultSeen(int weekKey) async {
    try {
      await _local.markResultSeen(weekKey: weekKey, at: _clock.now().toUtc());
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'markResultSeen');
      return Left(CacheFailure('Gagal menandai hasil.'));
    }
  }

  @override
  Future<Either<Failure, void>> markOlderResultsSeen({
    required int keepWeekKey,
  }) async {
    try {
      await _local.markOlderResultsSeen(
        keepWeekKey: keepWeekKey,
        at: _clock.now().toUtc(),
      );
      return const Right(null);
    } catch (e, s) {
      _log(e, s, 'markOlderResultsSeen');
      return Left(CacheFailure('Gagal merapikan hasil lama.'));
    }
  }

  /// Kandidat minggu [weekKey], dirakit dari pola belanja user sendiri:
  /// proyeksi belanja empat minggu basis → `computeBaselines` → saring ke
  /// kategori yang bisa dibatasi → `selectCandidates` (yang memakai riwayat
  /// untuk rem rotasi T5).
  ///
  /// M5 — jendela riwayatnya [kChallengeHistoryWeeks] (12), BUKAN
  /// `kRotationWins + 2` (5). `consecutiveWins` memperlakukan `held`/`skipped`
  /// sebagai TRANSPARAN, jadi dengan jendela 5, tiga minggu `held` berturut
  /// sudah cukup mendorong kemenangan ketiga keluar jendela — dan rem rotasi
  /// mati diam-diam. Gejalanya tak tertangkap test kalkulator, yang menyuapi
  /// `history` langsung; ia hanya terlihat lewat jalur ini.
  @override
  Future<Either<Failure, List<ChallengeCandidate>>> getCandidates(
    int weekKey,
  ) async {
    try {
      final spends = await _local.getWeeklySpends(
        addDays(weekKey, -7 * kBaselineWeeks),
      );
      final basis = computeBaselines(spends: spends, currentWeekKey: weekKey);

      // S-B/M11 — kategori yang TAK TERBACA bukan "tidak ada kategori yang
      // layak". Memadatkannya jadi himpunan kosong membuat daftar kandidat
      // kosong, dan `EnsureOutcome` melaporkan 0; user lalu dituduh kurang
      // data padahal yang gagal adalah database. `Left` di sini yang menjaga
      // `candidateCount` tetap null sampai ke layar.
      final kategori = await _getLimitable(const NoParams());
      if (kategori.isLeft()) {
        return Left(CacheFailure('Kategori belum bisa dibaca.'));
      }
      final slugs = kategori
          .getOrElse(() => const [])
          .map((c) => c.slug)
          .toSet();

      // `watchHistory` sudah terurut weekKey MENURUN — bentuk yang dituntut
      // `consecutiveWins`. `.first` mengambil satu potret, bukan langganan:
      // menulis dari stream yang mengawasi tabelnya sendiri menghidupkan lagi
      // loop tulis→emit→hitung→tulis (D-2 Fase 1).
      final riwayat = await _local.watchHistory(kChallengeHistoryWeeks).first;

      return Right(
        selectCandidates(
          baselines: basis.baselines,
          weeksWithData: basis.weeksWithData,
          limitableSlugs: slugs,
          history: [
            for (final r in riwayat)
              ResolvedWeek(
                weekKey: r.weekKey,
                category: r.category,
                status: r.status,
              ),
          ],
        ),
      );
    } catch (e, s) {
      _log(e, s, 'getCandidates');
      return Left(CacheFailure('Gagal menyusun kandidat tantangan.'));
    }
  }

  /// Koalesensi emisi berdekatan. Satu tulisan baris menyentuh DUA stream yang
  /// sama-sama diawasi (`watchWeek` dan `watchHistory`); tanpa jeda ini,
  /// dua agregat SQL dijalankan dua kali untuk satu aksi user. Sengaja jauh
  /// lebih pendek dari debounce streak (150 ms) — di sini yang dikoalesenkan
  /// cuma emisi yang lahir dari SATU tulisan, bukan satu batch lintas-tabel.
  static const _koalesensi = Duration(milliseconds: 16);

  /// EMPAT stream, satu potret (S-B). TIDAK MENULIS APA PUN — menulis dari
  /// stream yang mengawasi tabelnya sendiri menghidupkan loop
  /// tulis→emit→hitung→tulis (D-2 Fase 1).
  ///
  /// `pendingResult` sengaja tidak dihitung di sini: stream hanya boleh
  /// MEMILIH, tak boleh MERAPIKAN. Perapian jamaknya milik langkah 1c
  /// `EnsureAndResolveChallenge` (D22), satu-satunya jalur tulis fitur ini.
  @override
  Stream<Either<Failure, ChallengeInputs>> watchInputs() {
    late StreamController<Either<Failure, ChallengeInputs>> controller;
    StreamSubscription<WeeklyChallenge?>? bariSub;
    StreamSubscription<List<WeeklyChallenge>>? riwayatSub;
    StreamSubscription<void>? txSub;
    StreamSubscription<bool>? sakelarSub;
    Timer? koalesensiTimer;

    // weekKey yang DIAWASI `watchWeek`, dipatok saat langganan dimulai. Kalau
    // minggu berganti selagi app terbuka, ia jadi basi — karena itu perakit di
    // bawah jatuh ke `riwayat` (yang tetap hidup dan memuat baris terbaru)
    // begitu jam menunjuk minggu lain.
    final kunciDiawasi = weekKeyOf(_clock.now());

    WeeklyChallenge? barisDiawasi;
    var riwayat = const <WeeklyChallenge>[];
    var aktif = false;

    // Drift meng-emit nilai awal saat di-listen; `tableUpdates` TIDAK. Jadi
    // emisi pertama ditahan sampai ketiga stream berdata sudah bicara —
    // tanpa penjaga ini, layar sempat memakai `enabled: false` bawaan dan
    // berkedip dari "fitur mati" ke keadaan sebenarnya.
    var adaBaris = false;
    var adaRiwayat = false;
    var adaSakelar = false;

    // Serialisasi: `hitungSekali` async, dan dua putaran yang tumpang tindih
    // bisa mendarat terbalik. Putaran yang sudah tidak terbaru berhenti diam.
    var generasi = 0;

    // Minor-5 — `controller.isClosed` TIDAK PERNAH true di sini: `onCancel`
    // (di bawah) membatalkan langganan sumbernya tapi tidak pernah memanggil
    // `controller.close()`. Flag lokal ini adalah penjaga yang SUNGGUHAN.
    var dibatalkan = false;

    Future<void> hitungSekali() async {
      if (dibatalkan) return;
      if (!adaBaris || !adaRiwayat || !adaSakelar) return;
      final milikSaya = ++generasi;
      try {
        final now = _clock.now();
        final mingguIni = weekKeyOf(now);
        final baris = mingguIni == kunciDiawasi
            ? barisDiawasi
            : riwayat.where((r) => r.weekKey == mingguIni).firstOrNull;

        final kategori = baris?.category;
        final terpakai = kategori == null
            ? 0
            : await _local.spentInWeek(weekKey: mingguIni, category: kategori);
        final dikecualikan = kategori == null
            ? 0
            : await _local.excludedInWeek(
                weekKey: mingguIni,
                category: kategori,
              );

        if (dibatalkan || milikSaya != generasi) return;
        controller.add(
          Right(
            ChallengeInputs(
              // S-C — SATU-SATUNYA tempat baris Drift jadi entity domain di
              // jalur baca. `toChallengeWeek` milik Task 6.
              weekThisWeek: baris == null ? null : toChallengeWeek(baris),
              spentThisWeek: terpakai,
              excludedThisWeek: dikecualikan,
              history: [for (final r in riwayat) toChallengeWeek(r)],
              enabled: aktif,
            ),
          ),
        );
      } catch (e, s) {
        _log(e, s, 'watchInputs');
        if (dibatalkan) return;
        // Angka 0 yang sebenarnya berarti "gagal baca" adalah kebohongan.
        controller.add(Left(CacheFailure('Tantangan belum bisa dibaca.')));
      }
    }

    void jadwalkan() {
      koalesensiTimer?.cancel();
      koalesensiTimer = Timer(_koalesensi, hitungSekali);
    }

    void gagal(Object e, StackTrace s) {
      _log(e, s, 'watchInputs.sumber');
      if (!dibatalkan) {
        controller.add(Left(CacheFailure('Tantangan belum bisa dibaca.')));
      }
    }

    controller = StreamController<Either<Failure, ChallengeInputs>>(
      onListen: () {
        // 1. Baris minggu ini — isi kartu utama.
        bariSub = _local.watchWeek(kunciDiawasi).listen((v) {
          barisDiawasi = v;
          adaBaris = true;
          jadwalkan();
        }, onError: gagal);
        // 2. Riwayat — daftar riwayat, `historyEmpty`, dan kartu hasil.
        riwayatSub = _local.watchHistory(kChallengeHistoryWeeks).listen((v) {
          riwayat = v;
          adaRiwayat = true;
          jadwalkan();
        }, onError: gagal);
        // 3. Tabel transaksi — pemicu hitung ulang progres. Hanya SINYAL:
        //    angkanya tetap datang dari agregat SQL di `hitungSekali`.
        txSub = _local.watchTransactionTicks().listen(
          (_) => jadwalkan(),
          onError: gagal,
        );
        // 4. Sakelar fitur — lihat dartdoc `_settings`.
        sakelarSub = _settings.watchEnabled().listen((v) {
          aktif = v;
          adaSakelar = true;
          jadwalkan();
        }, onError: gagal);
      },
      onCancel: () async {
        dibatalkan = true;
        koalesensiTimer?.cancel();
        await bariSub?.cancel();
        await riwayatSub?.cancel();
        await txSub?.cancel();
        await sakelarSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// M8 — DUA jalur tulis, dibedakan oleh NIAT, bukan oleh flag.
  ///
  /// `_buatDanKirim` untuk baris yang memang boleh lahir (`createChallenge`,
  /// `holdWeek`): companion-nya lengkap, jadi upsert aman.
  ///
  /// `_ubahDanKirim` untuk perubahan atas baris yang HARUS sudah ada
  /// (`resolveWeek`, `changeCategory`): companion-nya parsial — tanpa
  /// `timezone`/`createdAt` — sehingga upsert yang jatuh ke cabang INSERT akan
  /// melanggar NOT NULL di runtime, di jalur yang jarang dilewati test. Update
  /// yang mengenai nol baris adalah kegagalan yang jujur, bukan insert diam.
  ///
  /// Keduanya memakai ekor kirim yang SAMA.
  Future<bool> _buatDanKirim(
    WeeklyChallengesCompanion companion,
    int weekKey,
  ) async {
    await _local.upsert(companion);
    await _kirim(weekKey);
    return true;
  }

  /// Temuan review Task 7 — SATU TEMPAT, sengaja di ekor ini dan bukan di
  /// badan `resolveWeek`/`changeCategory`: keduanya bakal ditulis ulang
  /// (Task 10/12), tapi ekor ini bertahan dan mewarisi perbaikannya gratis.
  ///
  /// Baris yang diubah lewat jalur ini sebelumnya sudah `isSynced=true`.
  /// Tanpa menjatuhkannya di sini, `pendingRows()` (isSynced=false) tak akan
  /// pernah menjemput baris ini kalau antrian sync-nya sendiri hilang —
  /// jaring pengaman `pushPendingChallenges()` yang Task 13 kaitkan ke
  /// `bootstrap_coordinator` jadi tak pernah menyala untuknya.
  Future<bool> _ubahDanKirim(
    int weekKey,
    WeeklyChallengesCompanion patch,
  ) async {
    final tersentuh = await _local.updateWeek(
      weekKey,
      patch.copyWith(isSynced: const Value(false)),
    );
    if (tersentuh == 0) return false; // baris tak ada — pemanggil melapor Left
    await _kirim(weekKey);
    return true;
  }

  /// Ekor kirim bersama. Purge SEBELUM enqueue: satu weekKey bisa ditulis tiga
  /// kali dalam dua hari (buat Senin → ganti pos → lewati Selasa), dan tanpa
  /// purge antrian menyimpan tiga payload untuk satu dokumen sehingga kebenaran
  /// bersandar pada urutan antrian.
  ///
  /// Purge-nya berbutir DOKUMEN (S-A), jadi menutup dua minggu lampau sekaligus
  /// dalam keadaan offline tidak lagi membuang antrian saudaranya.
  Future<void> _kirim(int weekKey) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return; // data tetap aman di lokal

    final path = _docPath(uid, weekKey);
    await _local.purgePendingSyncFor(path);

    final row = await _local.findWeek(weekKey);
    if (row == null) return;
    final model = ChallengeModel.fromRow(row);

    if (await _network.isConnected) {
      try {
        await _remote.upsertChallenge(uid, model);
        await _local.markSynced(weekKey);
        return;
      } catch (e, s) {
        _log(e, s, 'kirim.push');
      }
    }
    await _local.addToSyncQueue(
      itemId: '$weekKey',
      collectionPath: path, // uid NYATA + doc path penuh — #252 dan S-A
      data: jsonEncode(model.toFirestore()),
      operation: SyncOperation.create,
    );
  }

  int _weekKeyMundur(int minggu) {
    final now = _clock.now();
    final senin = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday))
        .subtract(Duration(days: 7 * minggu));
    return localDayKey(senin);
  }

  void _log(Object e, StackTrace s, String reason) =>
      FirebaseCrashlytics.instance.recordError(e, s, reason: reason);
}
