import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  const GetTransactionsUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
    GetTransactionsParams params,
  ) =>
      _repository.getTransactions(
        from: params.from,
        to: params.to,
        categoryFilter: params.categoryFilter,
      );
}

class GetTransactionsParams extends Equatable {
  const GetTransactionsParams({
    required this.from,
    required this.to,
    this.categoryFilter,
  });

  final DateTime from;
  final DateTime to;
  final TransactionCategory? categoryFilter;

  @override
  List<Object?> get props => [from, to, categoryFilter];
}
