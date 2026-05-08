import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardUseCase implements StreamUseCase<DashboardEntity, NoParams> {
  const GetDashboardUseCase(this._repository);
  final DashboardRepository _repository;

  @override
  Stream<Either<Failure, DashboardEntity>> call(NoParams params) =>
      _repository.watchDashboard();
}
