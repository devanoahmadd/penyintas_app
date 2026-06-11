import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';

class MockLocalDataSource extends Mock implements OnboardingLocalDataSource {}

void main() {
  late OnboardingRepositoryImpl repository;
  late MockLocalDataSource local;

  final tPartial = PartialOnboardingState(
    step: 1,
    income: 3000000,
    expenses: const {'kos': 1000000, 'listrik': 0, 'internet': 0, 'pulsa': 0, 'lain': 0},
    pct: 10,
    payday: 25,
    savedAt: DateTime(2026, 6, 1),
  );

  setUp(() {
    local = MockLocalDataSource();
    repository = OnboardingRepositoryImpl(localDataSource: local);
  });

  group('loadPartial', () {
    test('forwards ke datasource → Right(partial)', () async {
      when(() => local.loadPartialOnboarding()).thenAnswer((_) async => tPartial);
      final result = await repository.loadPartial();
      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), same(tPartial));
    });

    test('datasource throws CacheException → Left(CacheFailure)', () async {
      when(() => local.loadPartialOnboarding())
          .thenThrow(const CacheException('boom'));
      final result = await repository.loadPartial();
      expect(result.isLeft(), true);
    });
  });

  group('savePartial', () {
    test('forwards semua arg → Right(null)', () async {
      when(() => local.savePartialOnboarding(
            step: any(named: 'step'),
            income: any(named: 'income'),
            expenses: any(named: 'expenses'),
            pct: any(named: 'pct'),
            payday: any(named: 'payday'),
          )).thenAnswer((_) async {});

      final result = await repository.savePartial(
        step: 1, income: 3000000,
        expenses: const {'kos': 1000000},
        pct: 10, payday: 25,
      );

      expect(result, const Right<Failure, void>(null));
      verify(() => local.savePartialOnboarding(
            step: 1, income: 3000000,
            expenses: const {'kos': 1000000},
            pct: 10, payday: 25,
          )).called(1);
    });
  });

  group('clearPartial', () {
    test('forwards ke datasource → Right(null)', () async {
      when(() => local.clearPartialOnboarding()).thenAnswer((_) async {});
      final result = await repository.clearPartial();
      expect(result, const Right<Failure, void>(null));
      verify(() => local.clearPartialOnboarding()).called(1);
    });
  });
}
