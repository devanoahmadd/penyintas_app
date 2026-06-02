import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/auth/data/datasources/user_settings_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/models/user_settings_model.dart';
import 'package:penyintas_app/features/auth/domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  UserSettingsRepositoryImpl({
    required AppDatabase db,
    required UserSettingsRemoteDatasource remote,
    Duration syncTimeout = const Duration(seconds: 3),
  })  : _db = db,
        _remote = remote,
        _syncTimeout = syncTimeout;

  final AppDatabase _db;
  final UserSettingsRemoteDatasource _remote;
  final Duration _syncTimeout;

  static void _logError(Object e, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(e, stack);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, Unit>> wipeLocalData() async {
    try {
      await _db.clearAllLocalData();
      return const Right(unit);
    } catch (e, stack) {
      _logError(e, stack);
      return const Left(CacheFailure('Gagal membersihkan data lokal.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncFromRemote() async {
    try {
      final remoteModel =
          await _remote.fetchUserSettings().timeout(_syncTimeout);
      if (remoteModel != null) {
        await _writeIdentity(remoteModel);
      } else {
        final local = await _readIdentity();
        if (local.onboardingCompleted) {
          await _remote.saveUserSettings(local);
        }
      }
      return const Right(unit);
    } catch (e, stack) {
      _logError(e, stack);
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, Unit>> pushToRemote() async {
    try {
      final local = await _readIdentity();
      await _remote.saveUserSettings(local);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, stack) {
      _logError(e, stack);
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<UserSettingsModel> _readIdentity() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    return UserSettingsModel(
      onboardingCompleted: row?.onboardingCompleted ?? false,
    );
  }

  Future<void> _writeIdentity(UserSettingsModel s) async {
    // Companion minimal: hanya sentuh flag onboarding, jangan reset kolom
    // finansial (monthlyIncome/rentExpense/dst.) yang dihydrate jalur lain.
    await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
          id: const Value(1),
          onboardingCompleted: Value(s.onboardingCompleted),
        ));
  }
}
