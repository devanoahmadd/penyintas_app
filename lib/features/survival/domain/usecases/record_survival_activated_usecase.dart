import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/survival/domain/repositories/survival_repository.dart';

class RecordSurvivalActivatedUseCase {
  const RecordSurvivalActivatedUseCase(this._repo);
  final SurvivalRepository _repo;

  Future<Either<Failure, void>> call() => _repo.recordSurvivalActivated();
}
