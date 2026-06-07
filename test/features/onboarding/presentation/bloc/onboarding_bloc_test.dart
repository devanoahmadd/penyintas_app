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
  const tEmergencyPct = 0.10;
  const tDailyBudget = 27000;

  // #208: single event, carries all fields
  const tExpenses = {
    'kos': 400000,
    'listrik': 100000,
    'internet': 50000,
    'pulsa': 50000,
    'lain': 0,
  };
  const tSubmitEvent = OnboardingSubmitted(
    income: tIncome,
    paymentDate: tPaymentDate,
    expenses: tExpenses,
    emergencyFundPct: tEmergencyPct,
  );

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

  // ── OnboardingStarted ─────────────────────────────────────────────────
  group('OnboardingStarted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emit [OnboardingInitial] saat started',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStarted()),
      expect: () => [const OnboardingInitial()],
    );
  });

  // ── OnboardingSubmitted — sukses ──────────────────────────────────────
  group('OnboardingSubmitted — sukses', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emit [Calculating, Success] saat save & calc berhasil',
      build: buildBloc,
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(tSubmitEvent),
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingSuccess(dailyBudget: tDailyBudget),
      ],
      verify: (_) {
        verify(() => mockAnalytics.logOnboardingCompleted()).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'panggil pushUserSettings setelah save sukses (#211)',
      build: buildBloc,
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(tSubmitEvent),
      verify: (_) {
        verify(() => mockPush(any())).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'dailyBudget di Success state = nilai dari use case',
      build: buildBloc,
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(tSubmitEvent),
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingSuccess(dailyBudget: tDailyBudget),
      ],
    );
  });

  // ── OnboardingSubmitted — gagal save ──────────────────────────────────
  group('OnboardingSubmitted — gagal save', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emit [Calculating, Error] saat save gagal',
      build: buildBloc,
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any())).thenAnswer(
          (_) async => const Left(CacheFailure('Gagal menyimpan.')),
        );
      },
      act: (bloc) => bloc.add(tSubmitEvent),
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingError(message: 'Gagal menyimpan.'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'retry dari Error state: submit ulang berhasil → Success (#207)',
      build: buildBloc,
      setUp: () {
        var callCount = 0;
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Left(CacheFailure('Gagal menyimpan.'));
          }
          return const Right(null);
        });
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(tSubmitEvent);
        await Future<void>.delayed(Duration.zero);
        // Retry: kirim ulang event yang sama dari Error state
        bloc.add(tSubmitEvent);
      },
      expect: () => [
        const OnboardingCalculating(),
        const OnboardingError(message: 'Gagal menyimpan.'),
        const OnboardingCalculating(),
        const OnboardingSuccess(dailyBudget: tDailyBudget),
      ],
    );
  });

  // ── OnboardingSubmitted — remainingDays fallback ──────────────────────
  group('remainingDays fallback', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'pakai daysInCycle() bukan 0 ketika hari ini = paymentDate',
      build: buildBloc,
      setUp: () {
        when(() => mockCalc(any()))
            .thenAnswer((_) async => Right(tCalcResult));
        when(() => mockSave(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAnalytics.logOnboardingCompleted())
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(OnboardingSubmitted(
        income: tIncome,
        paymentDate: DateTime.now().day, // remainingDaysInCycle() → 0
        expenses: tExpenses,
        emergencyFundPct: tEmergencyPct,
      )),
      // Cukup verifikasi calc dipanggil dengan remainingDays > 0
      verify: (_) {
        final captured = verify(() => mockCalc(captureAny())).captured;
        final params = captured.first as CalcParams;
        expect(params.remainingDays, greaterThan(0));
      },
    );
  });

  // ── fixedExpenses getter ──────────────────────────────────────────────
  group('OnboardingSubmitted.fixedExpenses', () {
    test('menjumlahkan semua expense values', () {
      const event = OnboardingSubmitted(
        income: tIncome,
        paymentDate: tPaymentDate,
        expenses: {'kos': 400000, 'listrik': 100000, 'internet': 50000, 'pulsa': 50000, 'lain': 0},
        emergencyFundPct: tEmergencyPct,
      );
      expect(event.fixedExpenses, 600000);
    });

    test('fixedExpenses = 0 bila semua baris 0 (default state)', () {
      const event = OnboardingSubmitted(
        income: tIncome,
        paymentDate: tPaymentDate,
        expenses: {'kos': 0, 'listrik': 0, 'internet': 0, 'pulsa': 0, 'lain': 0},
        emergencyFundPct: tEmergencyPct,
      );
      expect(event.fixedExpenses, 0);
    });
  });
}
