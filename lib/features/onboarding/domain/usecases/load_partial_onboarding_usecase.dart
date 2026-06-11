import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class LoadPartialOnboardingUseCase
    extends UseCase<PartialOnboardingState?, NoParams> {
  LoadPartialOnboardingUseCase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, PartialOnboardingState?>> call(NoParams params) =>
      _repository.loadPartial();
}
