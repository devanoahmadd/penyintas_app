import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class AddTransactionUseCase implements UseCase<void, TransactionEntity> {
  const AddTransactionUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) =>
      _repository.addTransaction(params);
}
