import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_local_datasource.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl({required GoalLocalDatasource local})
      : _local = local;

  final GoalLocalDatasource _local;

  @override
  Future<Either<Failure, List<GoalEntity>>> loadGoals() async {
    try {
      final goals = await _local.loadGoals();
      return Right(goals);
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'loadGoals');
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
      await _local.createGoal(
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'createGoal');
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
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'linkTransaction');
      return Left(CacheFailure('Gagal mengaitkan transaksi ke tujuan.'));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkTransaction(String txId) async {
    try {
      await _local.unlinkTransaction(txId);
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'unlinkTransaction');
      return Left(CacheFailure('Gagal melepas kaitan transaksi.'));
    }
  }

  @override
  Future<Either<Failure, void>> completeGoal(int goalId) async {
    try {
      await _local.completeGoal(goalId);
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'completeGoal');
      return Left(CacheFailure('Gagal menandai tujuan selesai.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(int goalId) async {
    try {
      await _local.deleteGoal(goalId);
      return const Right(null);
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'deleteGoal');
      return Left(CacheFailure('Gagal menghapus tujuan tabungan.'));
    }
  }
}
