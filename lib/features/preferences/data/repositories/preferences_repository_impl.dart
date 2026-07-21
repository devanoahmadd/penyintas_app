import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl({
    required PreferencesLocalDatasource local,
    required PreferencesRemoteDatasource remote,
    Duration syncTimeout = const Duration(seconds: 3),
  }) : _local = local,
       _remote = remote,
       _syncTimeout = syncTimeout;

  final PreferencesLocalDatasource _local;
  final PreferencesRemoteDatasource _remote;
  final Duration _syncTimeout;

  // Menyerap kegagalan Crashlytics saat unit test (tak ada Firebase app di
  // environment test). Pola konsisten dengan auth_remote_datasource.dart.
  static void _logError(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  @override
  Future<PreferencesEntity> read() async {
    final local = await _local.read();
    return local ?? PreferencesEntity.defaults;
  }

  @override
  Future<Either<Failure, Unit>> save(PreferencesEntity prefs) async {
    try {
      await _local.write(prefs); // canonical dulu
    } catch (e, s) {
      _logError(e, s);
      return const Left(CacheFailure('Gagal menyimpan preferensi.'));
    }
    try {
      await _remote.mirror(prefs); // best-effort
      // T-1: mirror sukses → tandai clean. Gagal → biarkan dirty (retry di launch
      // jalur A) agar perubahan offline tetap tersinkron, tanpa re-mirror tiap launch.
      await _local.markMirrored(DateTime.now().millisecondsSinceEpoch);
    } catch (e, s) {
      _logError(
        e,
        s,
      ); // non-fatal — local sudah tersimpan (tetap dirty → retry)
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> syncOnLaunch({
    required bool budgetOnboardingCompleted,
  }) async {
    try {
      final local = await _local.read() ?? PreferencesEntity.defaults;

      // (A) Local SUDAH otoritatif (§5: read-back HANYA saat local belum selesai).
      //     T-1 anti-clobber: JANGAN re-mirror tiap launch — itu menimpa cloud yg
      //     mungkin lebih baru dari device lain (last-launch-wins). Mirror HANYA bila
      //     local "dirty" (save yg mirror-nya belum sukses). Bersih → cloud tak disentuh.
      //     Mirror tetap di BACKGROUND (unawaited) → splash TAK menunggu (F-D3).
      //     Ratchet terjaga: remote tak pernah menurunkan profileCompleted true→false.
      if (local.profileCompleted) {
        if (await _local.hasPendingMirror()) {
          unawaited(_mirrorBestEffort(local));
        }
        return const Right(unit);
      }

      // Bootstrap: local belum selesai → coba pulihkan dari remote (reinstall/swap).
      // KRUSIAL (F-D1): fetch punya 3 keadaan — present / absen-terkonfirmasi / GAGAL.
      // A5 sudah membedakan (return null = doc absen; throw = error). JANGAN runtuhkan
      // keduanya jadi null — itu yang membuat timeout menimpa profil cloud asli.
      PreferencesEntity? remote;
      var fetchFailed = false;
      try {
        remote = await _remote.fetch().timeout(_syncTimeout);
      } catch (e, s) {
        _logError(e, s);
        fetchFailed =
            true; // timeout/offline/belum-auth → status cloud TAK DIKETAHUI
      }

      // (B) Remote selesai & VALID → ratchet UP: seed local. Tak perlu mirror (local
      //     kini == remote). F-D4: validasi data di sisi konsumsi (defense-in-depth atas
      //     clamp M1) — jangan seed "completed" yang field-nya rusak/kosong.
      if (remote != null &&
          remote.profileCompleted &&
          _isProfileValid(remote)) {
        await _local.write(remote);
        // T-1: local kini == remote (salinan setia) → tandai clean, jangan mirror balik.
        await _local.markMirrored(DateTime.now().millisecondsSinceEpoch);
        return const Right(unit);
      }

      // (C) Remote ADA tapi (belum selesai / selesai-tapi-invalid) → JANGAN seed,
      //     JANGAN mirror (F-D2/F-D4). Cloud punya data ≥ local; full-doc set akan
      //     MENIMPA progres parsial device lain. Local tetap default → needsProfile.
      if (remote != null) {
        return const Right(unit);
      }

      // (D) Fetch GAGAL → status cloud tak diketahui → JANGAN menulis apa pun ke
      //     cloud (F-D1: anti-clobber). Local tetap → needsProfile (fail-safe); pulih
      //     sendiri saat launch online berikutnya tanpa kehilangan data cloud.
      if (fetchFailed) {
        return const Right(unit);
      }

      // (E) Cloud TERBUKTI kosong (fetch sukses, doc absen).
      if (budgetOnboardingCompleted) {
        // Smart-default akun lama (§9): user selesai budget onboarding sebelum fitur
        // profil ada & cloud terbukti belum punya preferences/current → JANGAN paksa
        // ulang profil. Aman menulis+mirror: tak ada yang ditimpa. Mirror unawaited.
        final defaulted = local.copyWith(profileCompleted: true);
        await _local.write(defaulted);
        unawaited(_mirrorBestEffort(defaulted));
        return const Right(unit);
      }

      // (F) User baru, cloud kosong, budget belum → biarkan needsProfile. TANPA mirror
      //     (local=defaults kosong; tak ada yang berguna dikirim, hindari clobber).
      return const Right(unit);
    } catch (e, s) {
      _logError(e, s);
      return const Right(unit); // non-fatal — guard fail-safe needsProfile
    }
  }

  /// F-D4 (diperbaiki — audit Temuan 2): gerbang trust-boundary di sisi KONSUMSI.
  /// CATATAN PENTING: `fromFirestore` (A3) sudah meng-clamp `timezone`/`baseCurrency`
  /// kosong ke default, jadi cek "non-kosong" lama SELALU true lewat jalur `fetch()`
  /// → tak menjaga apa pun. Yang benar-benar berbahaya: doc `{...defaults,
  /// profileCompleted:true}` (klien lama/buggy) — semua default, tanpa kota, zona
  /// default — lolos rules tapi BUKAN profil asli. Gerbang ini menolaknya: leg profil
  /// asli (B4) SELALU memilih kota (`currentCity` terisi) ATAU menggeser zona via
  /// escape-hatch (`timezone` ≠ default). (Jalur smart-default akun lama (E) sengaja
  /// menulis defaults+completed TANPA gerbang ini — itu keputusan produk berbeda, §9.)
  bool _isProfileValid(PreferencesEntity p) {
    if (!p.timezone.contains('/')) return false; // bukan IANA wajar
    final hasCity = (p.currentCity?.trim().isNotEmpty ?? false);
    final movedTz = p.timezone != PreferencesEntity.defaults.timezone;
    return hasCity || movedTz; // penanda leg profil asli pernah dijalankan
  }

  /// Mirror dgn timeout + swallow. SELALU dipanggil via `unawaited(...)` di jalur
  /// launch — JANGAN pernah menggantung splash (A2/F-D3) atau menggagalkan launch.
  Future<void> _mirrorBestEffort(PreferencesEntity prefs) async {
    try {
      await _remote.mirror(prefs).timeout(_syncTimeout);
      // T-1: mirror sukses → tandai clean agar launch berikutnya tak mirror ulang.
      await _local.markMirrored(DateTime.now().millisecondsSinceEpoch);
    } catch (e, s) {
      _logError(e, s);
    }
  }
}
