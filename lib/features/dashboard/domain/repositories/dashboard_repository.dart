import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Stream<Either<Failure, DashboardEntity>> watchDashboard();
}
