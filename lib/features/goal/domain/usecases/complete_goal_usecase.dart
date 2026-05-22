import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class CompleteGoalUseCase implements UseCase<void, int> {
  const CompleteGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  Future<Either<Failure, void>> call(int goalId) =>
      _repository.completeGoal(goalId);
}
