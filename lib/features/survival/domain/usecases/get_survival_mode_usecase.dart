import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/repositories/survival_repository.dart';

class GetSurvivalModeUseCase {
  const GetSurvivalModeUseCase(this._repo);
  final SurvivalRepository _repo;

  Future<Either<Failure, SurvivalModeEntity>> call(DashboardEntity entity) =>
      _repo.getSurvivalMode(entity);
}
