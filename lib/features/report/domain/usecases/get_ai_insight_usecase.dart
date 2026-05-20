import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/domain/repositories/report_repository.dart';

class GetAiInsightUseCase {
  const GetAiInsightUseCase(this._repo);
  final ReportRepository _repo;

  Future<Either<Failure, (List<String>, String?)>> call(ReportEntity params) =>
      _repo.getAiInsights(params);
}
