import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class CreateGoalParams extends Equatable {
  const CreateGoalParams({
    required this.title,
    required this.targetAmount,
    required this.targetDate,
  });

  final String title;
  final int targetAmount;
  final DateTime targetDate;

  @override
  List<Object> get props => [title, targetAmount, targetDate];
}

class CreateGoalUseCase implements UseCase<void, CreateGoalParams> {
  const CreateGoalUseCase(this._repository);
  final GoalRepository _repository;

  @override
  Future<Either<Failure, void>> call(CreateGoalParams params) =>
      _repository.createGoal(
        title: params.title,
        targetAmount: params.targetAmount,
        targetDate: params.targetDate,
      );
}
