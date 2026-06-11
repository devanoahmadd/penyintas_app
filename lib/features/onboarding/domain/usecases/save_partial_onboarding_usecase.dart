import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class SavePartialParams extends Equatable {
  const SavePartialParams({
    required this.step,
    required this.income,
    required this.expenses,
    required this.pct,
    required this.payday,
  });
  final int step;
  final int income;
  final Map<String, int> expenses;
  final int pct;
  final int payday;

  @override
  List<Object> get props => [step, income, expenses, pct, payday];
}

class SavePartialOnboardingUseCase extends UseCase<void, SavePartialParams> {
  SavePartialOnboardingUseCase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(SavePartialParams params) =>
      _repository.savePartial(
        step: params.step,
        income: params.income,
        expenses: params.expenses,
        pct: params.pct,
        payday: params.payday,
      );
}
