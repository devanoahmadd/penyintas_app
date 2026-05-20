import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/data/datasources/report_local_datasource.dart';
import 'package:penyintas_app/features/report/data/datasources/report_remote_datasource.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl({
    required ReportLocalDatasource local,
    required ReportRemoteDatasource remote,
    required AppDatabase db,
  })  : _local = local,
        _remote = remote,
        _db = db;

  final ReportLocalDatasource _local;
  final ReportRemoteDatasource _remote;
  final AppDatabase _db;

  @override
  Future<Either<Failure, ReportEntity>> getMonthlyReport(
    DateTime month,
  ) async {
    try {
      return Right(await _local.getMonthlyReport(month));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (List<String>, String?)>> getAiInsights(
    ReportEntity report,
  ) async {
    try {
      final settings = await (_db.select(_db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (settings == null) {
        return Left(CacheFailure('Pengaturan tidak ditemukan.'));
      }

      final monthKey = '${report.month.year}-${report.month.month}';
      final result = await _remote.getAiInsights(
        reportData: {
          'month': monthKey,
          'totalSpent': report.totalSpent,
          'totalIncome': report.totalIncome,
          'categoryBreakdown':
              report.categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
        },
        settingsData: {
          'monthlyIncome': settings.monthlyIncome,
          'fixedExpenses': settings.fixedExpenses,
          'emergencyFundPct': settings.emergencyFundPct,
        },
      );
      return Right(result);
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return Left(ServerFailure(e.toString()));
    }
  }
}
