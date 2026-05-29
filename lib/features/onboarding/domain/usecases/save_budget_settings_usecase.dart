import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class SaveBudgetSettingsUseCase extends UseCase<void, BudgetSettingsEntity> {
  SaveBudgetSettingsUseCase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(BudgetSettingsEntity params) {
    return _repository.saveBudgetSettings(params);
  }
}
