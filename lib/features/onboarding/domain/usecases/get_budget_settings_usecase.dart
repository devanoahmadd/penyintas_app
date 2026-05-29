import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetBudgetSettingsUseCase extends UseCase<BudgetSettingsEntity?, NoParams> {
  GetBudgetSettingsUseCase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, BudgetSettingsEntity?>> call(NoParams params) {
    return _repository.getBudgetSettings();
  }
}
