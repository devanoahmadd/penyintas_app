import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class ClearPartialOnboardingUseCase extends UseCase<void, NoParams> {
  ClearPartialOnboardingUseCase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.clearPartial();
}
