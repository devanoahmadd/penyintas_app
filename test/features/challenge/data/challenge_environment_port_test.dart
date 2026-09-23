import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/data/ports/challenge_environment_port_impl.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_constants.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_mode_usecase.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockGetSurvivalModeUseCase extends Mock
    implements GetSurvivalModeUseCase {}

// ── Helpers ───────────────────────────────────────────────────────────────

DashboardEntity _dashboard({int totalMonthlyBudget = 3000000}) =>
    DashboardEntity(
      dailyBudget: 50000,
      spentToday: 0,
      remainingToday: 50000,
      totalMonthlyBudget: totalMonthlyBudget,
      totalSpentThisMonth: 300000,
      totalRemaining: totalMonthlyBudget - 300000,
      daysToLive: 14,
      remainingDays: 10,
      avgDailySpend: 30000,
      status: BudgetStatus.safe,
      lastUpdated: DateTime(2026, 5, 21),
      todayTransactions: const [],
      emergencyFundMonthly: 50000,
    );

SurvivalModeEntity _survival({required bool isActive}) => SurvivalModeEntity(
  isActive: isActive,
  remainingAmount: 80000,
  remainingDays: 10,
  suggestedDailyBudget: 8000,
  tips: const [],
);

void main() {
  late MockDashboardRepository dashboardRepo;
  late MockGetSurvivalModeUseCase getSurvival;
  late ChallengeEnvironmentPortImpl port;

  setUpAll(() {
    // Wajib: getSurvival menerima DashboardEntity non-nullable, jadi any()
    // dari mocktail melempar StateError sebelum test sempat berjalan tanpa
    // baris ini — dan gagalnya tidak menyebut sebabnya.
    registerFallbackValue(_dashboard());
  });

  setUp(() {
    dashboardRepo = MockDashboardRepository();
    getSurvival = MockGetSurvivalModeUseCase();
    port = ChallengeEnvironmentPortImpl(
      dashboardRepo: dashboardRepo,
      getSurvivalMode: getSurvival,
    );
  });

  test(
    'anggaran ada, aman → Right(budgetConfigured: true, survivalActive: false)',
    () async {
      when(() => dashboardRepo.watchDashboard()).thenAnswer(
        (_) => Stream.value(Right(_dashboard(totalMonthlyBudget: 3000000))),
      );
      when(
        () => getSurvival(any()),
      ).thenAnswer((_) async => Right(_survival(isActive: false)));

      final hasil = await port.read();

      expect(hasil.isRight(), isTrue);
      hasil.fold((_) => fail('harus Right'), (env) {
        expect(env.budgetConfigured, isTrue);
        expect(env.survivalActive, isFalse);
      });
    },
  );

  test('U59 · anggaran nol → budgetConfigured false, BUKAN Left', () async {
    when(
      () => dashboardRepo.watchDashboard(),
    ).thenAnswer((_) => Stream.value(Right(_dashboard(totalMonthlyBudget: 0))));
    when(() => getSurvival(any())).thenAnswer(
      (_) async =>
          Right(_survival(isActive: true)), // danger, seperti kode nyata
    );

    final hasil = await port.read();

    expect(hasil.isRight(), isTrue);
    hasil.fold((_) => fail('harus Right'), (env) {
      expect(env.budgetConfigured, isFalse);
      // Penting: survivalActive apa adanya. Gerbang anggaran yang jatuh lebih
      // dulu, bukan boolean ini yang dipalsukan.
      expect(env.survivalActive, isTrue);
    });
  });

  test('survival menyala → Right(survivalActive: true)', () async {
    when(() => dashboardRepo.watchDashboard()).thenAnswer(
      (_) => Stream.value(Right(_dashboard(totalMonthlyBudget: 3000000))),
    );
    when(
      () => getSurvival(any()),
    ).thenAnswer((_) async => Right(_survival(isActive: true)));

    final hasil = await port.read();

    expect(hasil.isRight(), isTrue);
    hasil.fold((_) => fail('harus Right'), (env) {
      expect(env.survivalActive, isTrue);
    });
  });

  test('dashboard Left → Left', () async {
    when(() => dashboardRepo.watchDashboard()).thenAnswer(
      (_) => Stream.value(Left(CacheFailure('gagal baca dashboard'))),
    );

    final hasil = await port.read();

    expect(hasil.isLeft(), isTrue);
  });

  test(
    'U57 · stream diam → Left setelah kEnvReadTimeout',
    () async {
      // StreamController yang sengaja tidak pernah add()/close() — meniru
      // koneksi yang diam total, bukan stream kosong (yang langsung selesai
      // tanpa menyentuh .timeout() sama sekali).
      final diam = StreamController<Either<Failure, DashboardEntity>>();
      addTearDown(diam.close);
      when(() => dashboardRepo.watchDashboard()).thenAnswer((_) => diam.stream);

      final hasil = await port.read();

      expect(hasil.isLeft(), isTrue);
    },
    timeout: Timeout(kEnvReadTimeout + const Duration(seconds: 5)),
  );
}
