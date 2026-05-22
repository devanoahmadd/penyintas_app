import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class DeleteGoalUseCase implements UseCase<void, int> {
  const DeleteGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  Future<Either<Failure, void>> call(int goalId) =>
      _repository.deleteGoal(goalId);
}
