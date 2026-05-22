import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';

class LinkTransactionParams extends Equatable {
  const LinkTransactionParams({required this.txId, required this.goalId});

  final String txId;
  final int goalId;

  @override
  List<Object> get props => [txId, goalId];
}

class LinkTransactionUseCase implements UseCase<void, LinkTransactionParams> {
  const LinkTransactionUseCase(this._repository);
  final GoalRepository _repository;

  @override
  Future<Either<Failure, void>> call(LinkTransactionParams params) =>
      _repository.linkTransaction(txId: params.txId, goalId: params.goalId);
}
