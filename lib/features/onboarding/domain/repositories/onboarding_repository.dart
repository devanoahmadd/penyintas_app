import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';

/// #247: repository onboarding kini hanya memiliki *onboarding-state*
/// (partial draft). Persistensi budget dimiliki fitur Budget.
abstract class OnboardingRepository {
  Future<Either<Failure, PartialOnboardingState?>> loadPartial();
  Future<Either<Failure, void>> savePartial({
    required int step,
    required int income,
    required Map<String, int> expenses,
    required int pct,
    required int payday,
  });
  Future<Either<Failure, void>> clearPartial();
}
