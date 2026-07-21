import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';

abstract class SurvivalRepository {
  Future<Either<Failure, SurvivalModeEntity>> getSurvivalMode(
    DashboardEntity dashboard,
  );

  Future<Either<Failure, List<SurvivalTip>>> getSurvivalTips({
    required int remainingAmount,
    required int remainingDays,
    required String language,
  });

  Future<Either<Failure, void>> recordSurvivalActivated();

  Future<Either<Failure, void>> clearSurvivalActivated();
}
