import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, ReportEntity>> getMonthlyReport(DateTime month);
  Future<Either<Failure, (List<String>, String?)>> getAiInsights(
      ReportEntity report);
}
