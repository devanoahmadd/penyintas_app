import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, void>> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<Either<Failure, BudgetSettingsEntity?>> getBudgetSettings();
}
