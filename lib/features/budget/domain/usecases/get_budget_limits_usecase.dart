import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';

class GetBudgetLimitsUseCase extends UseCase<List<BudgetLimitEntity>, NoParams> {
  GetBudgetLimitsUseCase(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, List<BudgetLimitEntity>>> call(NoParams params) =>
      _repository.getBudgetLimits();
}
