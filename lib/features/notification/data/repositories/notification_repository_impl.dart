import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationLocalDatasource local,
    required NotificationRemoteDatasource remote,
  })  : _local = local,
        _remote = remote;

  final NotificationLocalDatasource _local;
  final NotificationRemoteDatasource _remote;

  /// Catat error ke Crashlytics, aman saat Firebase belum siap (mis. di test).
  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await _local.requestPermission();
      return Right(granted);
    } catch (e, s) {
      _logError(e, s);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveFcmToken(String uid, String token) async {
    try {
      await _remote.saveFcmToken(uid, token);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      await _local.scheduleDailyReminder(hour: hour, minute: minute);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDailyReminder() async {
    try {
      await _local.cancelDailyReminder();
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerToken(String uid) async {
    try {
      final token = await _remote.getFcmToken();
      if (token == null) return const Right(null);
      await _remote.registerToken(uid, token);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterToken(String uid) async {
    try {
      final token = await _remote.getFcmToken();
      if (token != null) await _remote.unregisterToken(uid, token);
      await _remote.deleteToken();
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getPushEnabled(String uid) async {
    try {
      return Right(await _remote.getPushEnabled(uid));
    } catch (e, s) {
      _logError(e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setPushEnabled(String uid, bool enabled) async {
    try {
      await _remote.setPushEnabled(uid, enabled);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s);
      return Left(ServerFailure(e.toString()));
    }
  }
}
