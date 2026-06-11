import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

abstract class BudgetRepository {
  Future<Either<Failure, BudgetSettingsEntity>> getBudgetSettings();
  Future<Either<Failure, void>> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<Either<Failure, List<BudgetLimitEntity>>> getBudgetLimits();
  Future<Either<Failure, int>> saveBudgetLimit(BudgetLimitEntity limit);
  Future<Either<Failure, void>> deleteBudgetLimit(int id, String categoryName);

  /// #247: restore budget dari cloud bila lokal kosong; cache ke lokal.
  /// Dipakai splash saat reinstall. Lokal-hit → no-op network.
  Future<Either<Failure, BudgetSettingsEntity?>> syncBudgetFromRemote();
}
