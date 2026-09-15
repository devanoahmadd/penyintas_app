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
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
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

/// Jejak audit zona waktu device saat baris ditulis. MURNI audit: tak pernah
/// dibaca logika mana pun di app, dan satu-satunya tujuannya ikut ke dokumen
/// Firestore.
///
/// Bentuknya SENGAJA sama dengan `streak_day_marks.timezone`
/// (`streak_repository_impl.dart:243-251`): singkatan device ("WIB", "+07"),
/// bukan id IANA. Menggantinya dengan IANA adalah keputusan lintas-fitur milik
/// pemilik repo, bukan keputusan diam-diam di sini — `preferences.timezone`
/// merekam zona PROFIL user (kota pilihannya), bukan zona yang melahirkan
/// `weekKey`, dan menariknya dari `tz.local.name` mengikat penulisan ini pada
/// urutan inisialisasi paket timezone milik lapisan notifikasi.
///
/// Yang ditambahkan di sini cuma satu: jaring untuk nama zona KOSONG.
/// `firestore.rules` menuntut `timezone.size() > 0`, jadi string kosong membuat
/// dokumennya DITOLAK selamanya — dorongan gagal diam-diam dan barisnya
/// mengendap di antrian tanpa satu pun pesan ke user. Offset UTC selalu ada.
String zonaAudit(String namaZona, Duration offsetUtc) {
  if (namaZona.isNotEmpty) return namaZona;
  final menit = offsetUtc.inMinutes;
  final tanda = menit < 0 ? '-' : '+';
  final jam = (menit.abs() ~/ 60).toString().padLeft(2, '0');
  final sisa = (menit.abs() % 60).toString().padLeft(2, '0');
  return 'UTC$tanda$jam:$sisa';
}

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl({
    required ChallengeLocalDatasource local,
    required ChallengeRemoteDatasource remote,
    required NetworkInfo network,
    required FirebaseAuth auth,
    required AppClock clock,
    required GetLimitableCategoriesUseCase getLimitable,
  })  : _local = local, _remote = remote, _network = network,
        _auth = auth, _clock = clock, _getLimitable = getLimitable;

  final ChallengeLocalDatasource _local;
  final ChallengeRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;
  final AppClock _clock;

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
        await _local.upsert(m.toCompanion(
          keepResultSeenAt: lokal?.resultSeenAt,
          isSynced: true,
        ));
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

  @override
  Future<Either<Failure, void>> changeCategory({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) =>
      throw UnimplementedError('diisi di Task 12');

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
      final slugs = kategori.getOrElse(() => const []).map((c) => c.slug).toSet();

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

  @override
  Stream<Either<Failure, ChallengeInputs>> watchInputs() =>
      throw UnimplementedError('diisi di Task 13');

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
      WeeklyChallengesCompanion companion, int weekKey) async {
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
      int weekKey, WeeklyChallengesCompanion patch) async {
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
