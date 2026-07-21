import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/get_dashboard_usecase.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class MockGetDashboardUseCase extends Mock implements GetDashboardUseCase {}

class FakeNoParams extends Fake implements NoParams {}

void main() {
  late MockGetDashboardUseCase mockGetDashboard;

  DashboardEntity makeEntity({int daysToLive = 18, DateTime? lastUpdated}) =>
      DashboardEntity(
        dailyBudget: 50000,
        spentToday: 20000,
        remainingToday: 30000,
        totalMonthlyBudget: 1500000,
        totalSpentThisMonth: 600000,
        totalRemaining: 900000,
        daysToLive: daysToLive,
        remainingDays: 20,
        avgDailySpend: 50000,
        status: BudgetStatus.safe,
        lastUpdated: lastUpdated ?? DateTime(2026, 5, 8),
        todayTransactions: const [],
        emergencyFundMonthly: 200000,
      );

  setUpAll(() {
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockGetDashboard = MockGetDashboardUseCase();
  });

  DashboardBloc buildBloc() => DashboardBloc(getDashboard: mockGetDashboard);

  group('LoadDashboard', () {
    blocTest<DashboardBloc, DashboardState>(
      'emits Loading then Loaded on success',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGetDashboard(any()),
        ).thenAnswer((_) => Stream.value(Right(makeEntity())));
      },
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>()
            .having((s) => s.entity.daysToLive, 'daysToLive', 18)
            .having((s) => s.entity.status, 'status', BudgetStatus.safe),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits Loading then Error on failure',
      build: buildBloc,
      setUp: () {
        when(
          () => mockGetDashboard(any()),
        ).thenAnswer((_) => Stream.value(const Left(CacheFailure())));
      },
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [isA<DashboardLoading>(), isA<DashboardError>()],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits multiple Loaded states on stream updates with different data',
      build: buildBloc,
      setUp: () {
        when(() => mockGetDashboard(any())).thenAnswer(
          (_) => Stream.fromIterable([
            Right(makeEntity(daysToLive: 18)),
            Right(makeEntity(daysToLive: 10)),
          ]),
        );
      },
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.entity.daysToLive,
          'first daysToLive',
          18,
        ),
        isA<DashboardLoaded>().having(
          (s) => s.entity.daysToLive,
          'second daysToLive',
          10,
        ),
      ],
    );
  });

  group('DashboardRefreshed', () {
    blocTest<DashboardBloc, DashboardState>(
      'emits Loaded without Loading on refresh',
      build: buildBloc,
      seed: () => DashboardLoaded(makeEntity(daysToLive: 18)),
      setUp: () {
        when(
          () => mockGetDashboard(any()),
        ).thenAnswer((_) => Stream.value(Right(makeEntity(daysToLive: 15))));
      },
      act: (bloc) => bloc.add(const DashboardRefreshed()),
      expect: () => [
        isA<DashboardLoaded>().having(
          (s) => s.entity.daysToLive,
          'refreshed daysToLive',
          15,
        ),
      ],
    );
  });
}
