import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';

abstract class GoalRepository {
  Future<Either<Failure, List<GoalEntity>>> loadGoals();

  Future<Either<Failure, void>> createGoal({
    required String title,
    required int targetAmount,
    required DateTime targetDate,
  });

  /// Update goalId pada transaksi. goalId null = unlink.
  Future<Either<Failure, void>> linkTransaction({
    required String txId,
    required int goalId,
  });

  Future<Either<Failure, void>> unlinkTransaction(String txId);

  Future<Either<Failure, void>> completeGoal(int goalId);

  /// Unlink semua transaksi terkait sebelum menghapus goal.
  Future<Either<Failure, void>> deleteGoal(int goalId);
}
