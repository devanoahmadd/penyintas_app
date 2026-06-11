import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({required this.localDataSource});

  final OnboardingLocalDataSource localDataSource;

  @override
  Future<Either<Failure, PartialOnboardingState?>> loadPartial() async {
    try {
      return Right(await localDataSource.loadPartialOnboarding());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePartial({
    required int step,
    required int income,
    required Map<String, int> expenses,
    required int pct,
    required int payday,
  }) async {
    try {
      await localDataSource.savePartialOnboarding(
        step: step,
        income: income,
        expenses: expenses,
        pct: pct,
        payday: payday,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearPartial() async {
    try {
      await localDataSource.clearPartialOnboarding();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
