import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class UnlinkTransactionUseCase {
  const UnlinkTransactionUseCase(this._repository);
  final GoalRepository _repository;

  Future<Either<Failure, void>> call(String txId) =>
      _repository.unlinkTransaction(txId);
}
