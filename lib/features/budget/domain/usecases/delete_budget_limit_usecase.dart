import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';

class DeleteBudgetLimitUseCase extends UseCase<void, DeleteLimitParams> {
  DeleteBudgetLimitUseCase(this._repository);
  final BudgetRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteLimitParams params) =>
      _repository.deleteBudgetLimit(params.id, params.categoryName);
}

class DeleteLimitParams extends Equatable {
  const DeleteLimitParams({required this.id, required this.categoryName});
  final int id;
  final String categoryName;

  @override
  List<Object> get props => [id, categoryName];
}
