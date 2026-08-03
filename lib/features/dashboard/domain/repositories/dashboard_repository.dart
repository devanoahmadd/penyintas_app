import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Stream<Either<Failure, DashboardEntity>> watchDashboard();

  /// B4/§5.2: dipanggil jalur penulis budget settings; membuang cache DAN
  /// memicu recompute pada semua stream dashboard yang hidup.
  void invalidateSettingsCache();
}
