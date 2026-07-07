import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_local_datasource.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_remote_datasource.dart';
import 'package:penyintas_app/features/goal/data/models/goal_model.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

/// Local-first (pola TransactionRepositoryImpl): tulis lokal dulu — sukses
/// lokal = operasi sukses. Push remote saat online; gagal/offline → SyncQueue
/// (path doc PENUH `users/$uid/goals/$firestoreId`, uid di-resolve saat
/// enqueue — BUKAN placeholder `{uid}` ala budget yang tak di-resolve
/// SyncDispatcher). Belum login → data tetap lokal, tanpa queue.
class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl({
    required GoalLocalDatasource local,
    required GoalRemoteDatasource remote,
    required NetworkInfo networkInfo,
    required FirebaseAuth auth,
  }) : _local = local,
       _remote = remote,
       _network = networkInfo,
       _auth = auth;

  final GoalLocalDatasource _local;
  final GoalRemoteDatasource _remote;
  final NetworkInfo _network;
  final FirebaseAuth _auth;

  // Wrapper aman-test (pola TransactionRepositoryImpl._logError):
  // Crashlytics tanpa Firebase.initializeApp (unit test) tidak boleh crash.
  static void _logError(Object e, StackTrace s, String reason) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s, reason: reason);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, List<GoalEntity>>> loadGoals() async {
    try {
      final goals = await _local.loadGoals();
      return Right(goals);
    } catch (e, s) {
      _logError(e, s, 'loadGoals');
      return Left(CacheFailure('Gagal memuat daftar tujuan tabungan.'));
    }
  }

  @override
  Future<Either<Failure, void>> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  }) async {
    try {
      final model = await _local.createGoal(
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
      await _pushUpsert(model, operation: SyncOperation.create);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'createGoal');
      return Left(CacheFailure('Gagal menyimpan tujuan tabungan.'));
    }
  }

  @override
  Future<Either<Failure, void>> linkTransaction({
    required String txId,
    required int goalId,
  }) async {
    try {
      await _local.linkTransaction(txId: txId, goalId: goalId);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'linkTransaction');
      return Left(CacheFailure('Gagal mengaitkan transaksi ke tujuan.'));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkTransaction(String txId) async {
    try {
      await _local.unlinkTransaction(txId);
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'unlinkTransaction');
      return Left(CacheFailure('Gagal melepas kaitan transaksi.'));
    }
  }

  @override
  Future<Either<Failure, void>> completeGoal(int goalId) async {
    try {
      await _local.completeGoal(goalId);
      final model = await _local.findById(goalId);
      if (model != null && model.firestoreId.isNotEmpty) {
        await _pushUpsert(model, operation: SyncOperation.update);
      }
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'completeGoal');
      return Left(CacheFailure('Gagal menandai tujuan selesai.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(int goalId) async {
    try {
      // firestoreId WAJIB diambil SEBELUM row lokal dihapus.
      final firestoreId = await _local.firestoreIdOf(goalId);
      await _local.deleteGoal(goalId);

      final uid = _auth.currentUser?.uid;
      if (uid == null || firestoreId == null || firestoreId.isEmpty) {
        return const Right(null);
      }
      final path = 'users/$uid/goals/$firestoreId';
      if (await _network.isConnected) {
        try {
          await _remote.deleteGoal(firestoreId);
        } catch (e, s) {
          _logError(e, s, 'deleteGoal.push');
          await _local.addToSyncQueue(
            itemId: firestoreId,
            collectionPath: path,
            data: const <String, dynamic>{},
            operation: SyncOperation.delete,
          );
        }
      } else {
        await _local.addToSyncQueue(
          itemId: firestoreId,
          collectionPath: path,
          data: const <String, dynamic>{},
          operation: SyncOperation.delete,
        );
      }
      return const Right(null);
    } catch (e, s) {
      _logError(e, s, 'deleteGoal');
      return Left(CacheFailure('Gagal menghapus tujuan tabungan.'));
    }
  }

  @override
  Future<Either<Failure, int>> syncGoalsFromRemote() async {
    try {
      if (await _local.hasAnyGoals()) return const Right(0);
      if (!await _network.isConnected) return const Right(0);

      final models = await _remote.getGoals();
      if (models.isEmpty) return const Right(0);

      await _local.upsertFromRemote(models);
      return Right(models.length);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, s) {
      _logError(e, s, 'syncGoalsFromRemote');
      return Left(CacheFailure('Gagal memulihkan tujuan tabungan.'));
    }
  }

  /// Push create/update ke remote; offline atau remote gagal → SyncQueue.
  /// Belum login → no-op (data tetap lokal, pola TransactionRepositoryImpl).
  Future<void> _pushUpsert(
    GoalModel model, {
    required SyncOperation operation,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final path = 'users/$uid/goals/${model.firestoreId}';
    if (await _network.isConnected) {
      try {
        await _remote.saveGoal(model);
      } catch (e, s) {
        _logError(e, s, 'pushGoal');
        await _local.addToSyncQueue(
          itemId: model.firestoreId,
          collectionPath: path,
          data: model.toFirestore(),
          operation: operation,
        );
      }
    } else {
      await _local.addToSyncQueue(
        itemId: model.firestoreId,
        collectionPath: path,
        data: model.toFirestore(),
        operation: operation,
      );
    }
  }
}
