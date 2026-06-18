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
  })  : _local = local,
        _remote = remote;

  final PreferencesLocalDatasource _local;
  final PreferencesRemoteDatasource _remote;

  // Resolusi: `_log` didefinisikan sebagai static method agar bisa dipanggil dari
  // static `_logError`. Pola ini konsisten dengan auth_remote_datasource.dart (baris 58)
  // yang memakai `FirebaseCrashlytics.instance.recordError(e, s)`.
  static void _log(Object e, StackTrace s) =>
      FirebaseCrashlytics.instance.recordError(e, s);

  // Pembungkus `try { _log(e, s); } catch (_) {}` — menyerap kegagalan Crashlytics
  // saat unit test (tak ada Firebase app di environment test).
  static void _logError(Object e, StackTrace s) {
    try {
      _log(e, s);
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
      _logError(e, s); // non-fatal — local sudah tersimpan (tetap dirty → retry)
    }
    return const Right(unit);
  }
}
