import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class WatchTodayTransactionsUseCase
    implements StreamUseCase<List<TransactionEntity>, NoParams> {
  const WatchTodayTransactionsUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Stream<Either<Failure, List<TransactionEntity>>> call(NoParams params) =>
      _repository.watchTodayTransactions();
}
