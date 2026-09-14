import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

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
  })  : _local = local, _remote = remote, _network = network,
        _auth = auth, _clock = clock;

  final ChallengeLocalDatasource _local;
  final ChallengeRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;
  final AppClock _clock;

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

  /// Implementasi MINIMAL — hanya plumbing tulis+kirim yang diuji Task 7
  /// (U47). Validasi bisnis penuh (mis. menolak weekKey yang bukan Senin
  /// berjalan, memverifikasi kandidat) menyusul di Task 11.
  @override
  Future<Either<Failure, void>> createChallenge({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) async {
    final now = _clock.now();
    await _buatDanKirim(
      WeeklyChallengesCompanion.insert(
        weekKey: Value(weekKey),
        category: Value(category),
        targetAmount: Value(targetAmount),
        baselineAmount: Value(baselineAmount),
        status: ChallengeStatus.active,
        timezone: now.timeZoneName,
        createdAt: now,
        updatedAt: now,
      ),
      weekKey,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> holdWeek(int weekKey) =>
      throw UnimplementedError('diisi di Task 11');

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

  @override
  Future<Either<Failure, List<ChallengeCandidate>>> getCandidates(int weekKey) =>
      throw UnimplementedError('diisi di Task 11');

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
