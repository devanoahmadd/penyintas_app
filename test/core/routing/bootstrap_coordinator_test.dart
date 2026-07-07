// test/core/routing/bootstrap_coordinator_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/bootstrap_coordinator.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

class _MockSyncUserSettings extends Mock implements SyncUserSettingsUseCase {}
class _MockBudgetRepo extends Mock implements BudgetRepository {}
class _MockGoalRepo extends Mock implements GoalRepository {}
class _MockOnbDs extends Mock implements OnboardingLocalDataSource {}
class _MockPrefsRepo extends Mock implements PreferencesRepository {}

void main() {
  late _MockSyncUserSettings syncUserSettings;
  late _MockBudgetRepo budgetRepo;
  late _MockGoalRepo goalRepo;
  late _MockOnbDs onbDs;
  late _MockPrefsRepo prefsRepo;
  late int onCompleteCalls;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(PreferencesEntity.defaults);
  });
  setUp(() {
    syncUserSettings = _MockSyncUserSettings();
    budgetRepo = _MockBudgetRepo();
    goalRepo = _MockGoalRepo();
    onbDs = _MockOnbDs();
    prefsRepo = _MockPrefsRepo();
    onCompleteCalls = 0;
    when(() => syncUserSettings(any())).thenAnswer((_) async => const Right(unit));
    when(() => budgetRepo.syncBudgetFromRemote())
        .thenAnswer((_) async => const Right(null));
    when(() => goalRepo.syncGoalsFromRemote())
        .thenAnswer((_) async => const Right(0));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    when(() => prefsRepo.syncOnLaunch(budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted')))
        .thenAnswer((_) async => const Right(unit));
  });

  BootstrapCoordinator build() => BootstrapCoordinator(
        syncUserSettings: syncUserSettings,
        budgetRepository: budgetRepo,
        goalRepository: goalRepo,
        onboardingDs: onbDs,
        prefsRepo: prefsRepo,
        onComplete: () => onCompleteCalls++,
      );

  test('ensure() menjalankan keempat langkah sync + onComplete (reset cache guard) SEKALI', () async {
    final c = build();
    await c.ensure();
    verify(() => syncUserSettings(any())).called(1);
    verify(() => budgetRepo.syncBudgetFromRemote()).called(1);
    verify(() => goalRepo.syncGoalsFromRemote()).called(1);
    verify(() => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'))).called(1);
    expect(onCompleteCalls, 1);
    expect(c.isDone, true);
  });

  test('memo: panggilan paralel & berurutan → kerja jalan SEKALI', () async {
    final c = build();
    await Future.wait([c.ensure(), c.ensure()]);
    await c.ensure();
    verify(() => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'))).called(1);
    expect(onCompleteCalls, 1); // onComplete tak berulang tiap ensure()
  });

  test('non-fatal: identity/budget gagal → syncOnLaunch tetap jalan, ensure() selesai', () async {
    when(() => syncUserSettings(any())).thenThrow(Exception('offline'));
    when(() => budgetRepo.syncBudgetFromRemote()).thenThrow(Exception('offline'));
    final c = build();
    await c.ensure(); // tak melempar
    verify(() => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'))).called(1);
    expect(c.isDone, true);
  });

  test('reset(): user berikutnya bootstrap dari awal', () async {
    final c = build();
    await c.ensure();
    c.reset();
    expect(c.isDone, false);
    await c.ensure();
    verify(() => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'))).called(2);
    expect(onCompleteCalls, 2);
  });

  test('non-fatal: goal restore gagal → langkah lain tetap jalan, ensure() selesai',
      () async {
    when(() => goalRepo.syncGoalsFromRemote()).thenThrow(Exception('offline'));
    final c = build();
    await c.ensure(); // tak melempar
    verify(() => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'))).called(1);
    expect(c.isDone, true);
  });
}
