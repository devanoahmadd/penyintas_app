import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

class MarkTodayNoSpendUseCase implements UseCase<void, NoParams> {
  const MarkTodayNoSpendUseCase(this._repository);
  final StreakRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.markToday();
}
