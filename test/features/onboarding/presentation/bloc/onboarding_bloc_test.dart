import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/analytics_service.dart';
import 'package:penyintas_app/features/auth/domain/usecases/push_user_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/daily_budget_result.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_settings_usecase.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';

// Mocks
class MockSaveBudgetSettingsUseCase extends Mock
    implements SaveBudgetSettingsUseCase {}

class MockCalculateDailyBudgetUseCase extends Mock
    implements CalculateDailyBudgetUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockPushUserSettingsUseCase extends Mock
    implements PushUserSettingsUseCase {}

// Fallbacks
class FakeBudgetSettingsEntity extends Fake implements BudgetSettingsEntity {}
class FakeCalcParams extends Fake implements CalcParams {}

void main() {
  late MockSaveBudgetSettingsUseCase mockSave;
  late MockCalculateDailyBudgetUseCase mockCalc;
  late MockAnalyticsService mockAnalytics;
  late MockPushUserSettingsUseCase mockPush;

  const tIncome = 1500000;
  const tPaymentDate = 25;
  const tFixedExpenses = 600000;
  const tEmergencyPct = 0.10;
  const tDailyBudget = 27000;

  final tCalcResult = const DailyBudgetResult(
    dailyBudget: tDailyBudget,
    totalAvailable: 900000,
    emergencyFund: 90000,
    remainingDays: 30,
  );

  setUpAll(() {
    registerFallbackValue(FakeBudgetSettingsEntity());
    registerFallbackValue(FakeCalcParams());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockSave = MockSaveBudgetSettingsUseCase();
    mockCalc = MockCalculateDailyBudgetUseCase();
    mockAnalytics = MockAnalyticsService();
    mockPush = MockPushUserSettingsUseCase();
    when(() => mockPush(any())).thenAnswer((_) async => const Right(unit));
  });

  OnboardingBloc buildBloc() => OnboardingBloc(
        saveBudgetSettings: mockSave,
        calculateDailyBudget: mockCalc,
        analyticsService: mockAnalytics,
        pushUserSettings: mockPush,
      );

  group('OnboardingStarted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'should emit [OnboardingStep1] when started',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStarted()),
      expect: () => [const OnboardingStep1()],
    );
  });

  group('Step1Submitted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'should emit [OnboardingStep2] with income and paymentDate',
      build: buildBloc,
      seed: () => const OnboardingStep1(),
      act: (bloc) => bloc.add(const Step1Submitted(
        income: tIncome,
        paymentDate: tPaymentDate,
      )),
      expect: () => [
        const OnboardingStep2(income: tIncome, paymentDate: tPaymentDate),
      ],
    );
  });

  group('Step2Submitted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'should emit [OnboardingStep3] with accumulated data',
      build: buildBloc,
      seed: () =>
          const OnboardingStep2(income: tIncome, paymentDate: tPaymentDate),
      act: (bloc) =>
          bloc.add(const Step2Submitted(otherFixedExpense: tFixedExpenses)),
      expect: () => [
        isA<OnboardingStep3>()
            .having((s) => s.income, 'income', tIncome)
            .having((s) => s.paymentDate, 'paymentDate', tPaymentDate)
            .having((s) => s.fixedExpenses, 'fixedExpenses', tFixedExpenses),
      ],
    );
  });

  group('OnboardingBackPressed', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'should go back from Step2 to Step1',
      build: buildBloc,
      seed: () =>
          const OnboardingStep2(income: tIncome, paymentDate: tPaymentDate),
      act: (bloc) => bloc.add(const OnboardingBackPressed()),
      expect: () => [const OnboardingStep1()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'should go back from Step3 to Step2 preserving income and paymentDate',
      build: buildBloc,
      seed: () => const OnboardingStep3(
        income: tIncome,
        paymentDate: tPaymentDate,
        otherFixedExpense: tFixedExpenses,
        remainingDays: 30,
      ),
      act: (bloc) => bloc.add(const OnboardingBackPressed()),
      expect: () => [
        const OnboardingStep2(income: tIncome, paymentDate: tPaymentDate),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'should do nothing when pressing back on Step1',
      build: buildBloc,
      seed: () => const OnboardingStep1(),
      act: (bloc) => bloc.add(const OnboardingBackPressed()),
      expect: () => [],
    );
  });

  group('Step3Submitted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'should emit [OnboardingCalculating, OnboardingSuccess] when save succeeds',
      build: buildBloc,
      seed: () => const OnboardingStep3(
        income: tIncome,
        paymentDate: tPaymentDate,
        otherFixedExpense: tFixedExpenses,
        remainingDays: 30,
      ),
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) =>
          bloc.add(const Step3Submitted(emergencyFundPct: tEmergencyPct)),
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingSuccess(dailyBudget: tDailyBudget),
      ],
      verify: (_) {
        verify(() => mockAnalytics.logOnboardingCompleted()).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'should emit [OnboardingCalculating, OnboardingError] when save fails',
      build: buildBloc,
      seed: () => const OnboardingStep3(
        income: tIncome,
        paymentDate: tPaymentDate,
        otherFixedExpense: tFixedExpenses,
        remainingDays: 30,
      ),
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Gagal menyimpan.')),
        );
      },
      act: (bloc) =>
          bloc.add(const Step3Submitted(emergencyFundPct: tEmergencyPct)),
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingError(message: 'Gagal menyimpan.'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'push user settings ke Firestore setelah save sukses',
      build: buildBloc,
      seed: () => const OnboardingStep3(
        income: tIncome,
        paymentDate: tPaymentDate,
        otherFixedExpense: tFixedExpenses,
        remainingDays: 30,
      ),
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) =>
          bloc.add(const Step3Submitted(emergencyFundPct: tEmergencyPct)),
      verify: (_) {
        verify(() => mockPush(any())).called(1);
      },
    );
  });

  group('Step3Submitted guard — state bukan OnboardingStep3', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'tidak mengubah state ketika current state adalah OnboardingError',
      build: buildBloc,
      seed: () => const OnboardingError(message: 'Gagal menyimpan.'),
      act: (bloc) =>
          bloc.add(const Step3Submitted(emergencyFundPct: 0.10)),
      expect: () => [], // guard harus return early, tidak ada state change
    );
  });

  group('OnboardingRetryRequested', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emit OnboardingStep1 ketika _lastStep3 kosong',
      build: buildBloc,
      seed: () => const OnboardingError(message: 'Gagal.'),
      act: (bloc) => bloc.add(const OnboardingRetryRequested()),
      expect: () => [const OnboardingStep1()],
    );
  });
}
