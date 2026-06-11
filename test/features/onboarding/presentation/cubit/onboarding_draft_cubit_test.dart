import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/clear_partial_onboarding_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/load_partial_onboarding_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/save_partial_onboarding_usecase.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/onboarding_draft_cubit.dart';

class MockLoad extends Mock implements LoadPartialOnboardingUseCase {}
class MockSave extends Mock implements SavePartialOnboardingUseCase {}
class MockClear extends Mock implements ClearPartialOnboardingUseCase {}
class FakeSaveParams extends Fake implements SavePartialParams {}

void main() {
  late MockLoad load;
  late MockSave save;
  late MockClear clear;

  final tPartial = PartialOnboardingState(
    step: 1, income: 3000000,
    expenses: const {'kos': 1000000, 'listrik': 0, 'internet': 0, 'pulsa': 0, 'lain': 0},
    pct: 10, payday: 25, savedAt: DateTime(2026, 6, 1),
  );

  setUpAll(() => registerFallbackValue(FakeSaveParams()));

  setUp(() {
    load = MockLoad();
    save = MockSave();
    clear = MockClear();
  });

  OnboardingDraftCubit build() =>
      OnboardingDraftCubit(loadDraft: load, saveDraft: save, clearDraft: clear);

  blocTest<OnboardingDraftCubit, OnboardingDraftState>(
    'loadDraft → OnboardingDraftLoaded(partial)',
    setUp: () => when(() => load(const NoParams()))
        .thenAnswer((_) async => Right(tPartial)),
    build: build,
    act: (c) => c.loadDraft(),
    expect: () => [OnboardingDraftLoaded(tPartial)],
  );

  blocTest<OnboardingDraftCubit, OnboardingDraftState>(
    'loadDraft tanpa draft → OnboardingDraftLoaded(null)',
    setUp: () => when(() => load(const NoParams()))
        .thenAnswer((_) async => const Right(null)),
    build: build,
    act: (c) => c.loadDraft(),
    expect: () => [const OnboardingDraftLoaded(null)],
  );

  blocTest<OnboardingDraftCubit, OnboardingDraftState>(
    'loadDraft gagal → OnboardingDraftLoaded(null) (tak crash)',
    setUp: () => when(() => load(const NoParams()))
        .thenAnswer((_) async => const Left(CacheFailure('x'))),
    build: build,
    act: (c) => c.loadDraft(),
    expect: () => [const OnboardingDraftLoaded(null)],
  );

  test('saveDraft memanggil usecase save', () async {
    when(() => save(any())).thenAnswer((_) async => const Right(null));
    await build().saveDraft(
      step: 1, income: 3000000,
      expenses: const {'kos': 1000000}, pct: 10, payday: 25,
    );
    verify(() => save(any())).called(1);
  });

  test('clearDraft memanggil usecase clear', () async {
    when(() => clear(const NoParams())).thenAnswer((_) async => const Right(null));
    await build().clearDraft();
    verify(() => clear(const NoParams())).called(1);
  });
}
