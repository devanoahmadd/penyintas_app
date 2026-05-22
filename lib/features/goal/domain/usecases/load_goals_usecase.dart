import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class LoadGoalsUseCase implements UseCase<List<GoalEntity>, NoParams> {
  const LoadGoalsUseCase(this._repository);
  final GoalRepository _repository;

  @override
  Future<Either<Failure, List<GoalEntity>>> call(NoParams params) =>
      _repository.loadGoals();
}
