import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> updateTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required DateTime from,
    required DateTime to,
    String? categoryFilter,
  });
  Stream<Either<Failure, List<TransactionEntity>>> watchTodayTransactions();
}
