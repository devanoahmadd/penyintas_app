import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/domain/repositories/report_repository.dart';

class GetMonthlyReportUseCase implements UseCase<ReportEntity, DateTime> {
  const GetMonthlyReportUseCase(this._repo);
  final ReportRepository _repo;

  @override
  Future<Either<Failure, ReportEntity>> call(DateTime params) =>
      _repo.getMonthlyReport(params);
}
