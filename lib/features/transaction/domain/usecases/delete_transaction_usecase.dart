import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase implements UseCase<void, String> {
  const DeleteTransactionUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) =>
      _repository.deleteTransaction(params);
}
