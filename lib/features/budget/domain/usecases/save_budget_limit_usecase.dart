import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';

class SaveBudgetLimitUseCase extends UseCase<int, BudgetLimitEntity> {
  SaveBudgetLimitUseCase(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, int>> call(BudgetLimitEntity params) =>
      _repository.saveBudgetLimit(params);
}
