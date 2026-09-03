// test/core/routing/bootstrap_coordinator_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/bootstrap_coordinator.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

class _MockSyncUserSettings extends Mock implements SyncUserSettingsUseCase {}

class _MockBudgetRepo extends Mock implements BudgetRepository {}

class _MockGoalRepo extends Mock implements GoalRepository {}

class _MockOnbDs extends Mock implements OnboardingLocalDataSource {}

class _MockPrefsRepo extends Mock implements PreferencesRepository {}

class _MockBillRepo extends Mock implements BillRepository {}

class _MockBillReminderScheduler extends Mock
    implements BillReminderScheduler {}

class _MockBillReminderSettingsDs extends Mock
    implements BillReminderSettingsDatasource {}

class _MockStreakRepo extends Mock implements StreakRepository {}

void main() {
  late _MockSyncUserSettings syncUserSettings;
  late _MockBudgetRepo budgetRepo;
  late _MockGoalRepo goalRepo;
  late _MockOnbDs onbDs;
  late _MockPrefsRepo prefsRepo;
  late _MockBillRepo billRepo;
  late _MockBillReminderScheduler billScheduler;
  late _MockBillReminderSettingsDs billReminderSettingsDs;
  late _MockStreakRepo streakRepo;
  late int onCompleteCalls;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(PreferencesEntity.defaults);
    registerFallbackValue(<BillEntity>[]);
  });
  setUp(() {
    syncUserSettings = _MockSyncUserSettings();
    budgetRepo = _MockBudgetRepo();
    goalRepo = _MockGoalRepo();
    onbDs = _MockOnbDs();
    prefsRepo = _MockPrefsRepo();
    billRepo = _MockBillRepo();
    billScheduler = _MockBillReminderScheduler();
    billReminderSettingsDs = _MockBillReminderSettingsDs();
    streakRepo = _MockStreakRepo();
    onCompleteCalls = 0;
    when(
      () => syncUserSettings(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => budgetRepo.syncBudgetFromRemote(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => goalRepo.syncGoalsFromRemote(),
    ).thenAnswer((_) async => const Right(0));
    when(() => onbDs.isOnboardingCompleted()).thenAnswer((_) async => true);
    when(
      () => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => billRepo.syncBillsFromRemote(),
    ).thenAnswer((_) async => const Right(0));
    when(
      () => billRepo.watchActiveBills(),
    ).thenAnswer((_) => Stream.value(const Right(<BillEntity>[])));
    when(
      () => billReminderSettingsDs.read(),
    ).thenAnswer((_) async => (daysBefore: 1, hour: 9));
    when(
      () => billScheduler.rescheduleAll(
        any(),
        globalDaysBefore: any(named: 'globalDaysBefore'),
        globalHour: any(named: 'globalHour'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => streakRepo.syncMarksFromRemote(),
    ).thenAnswer((_) async => const Right(0));
    when(() => streakRepo.pushPendingMarks()).thenAnswer((_) async => 0);
  });

  BootstrapCoordinator build() => BootstrapCoordinator(
    syncUserSettings: syncUserSettings,
    budgetRepository: budgetRepo,
    goalRepository: goalRepo,
    onboardingDs: onbDs,
    prefsRepo: prefsRepo,
    billRepository: billRepo,
    billReminderScheduler: billScheduler,
    billReminderSettings: billReminderSettingsDs,
    streakRepository: streakRepo,
    onComplete: () => onCompleteCalls++,
  );

  test(
    'ensure() menjalankan keenam langkah sync + onComplete (reset cache guard) SEKALI',
    () async {
      final c = build();
      await c.ensure();
      verify(() => syncUserSettings(any())).called(1);
      verify(() => budgetRepo.syncBudgetFromRemote()).called(1);
      verify(() => goalRepo.syncGoalsFromRemote()).called(1);
      verify(() => billRepo.syncBillsFromRemote()).called(1);
      verify(() => streakRepo.syncMarksFromRemote()).called(1);
      verify(
        () => prefsRepo.syncOnLaunch(
          budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
        ),
      ).called(1);
      expect(onCompleteCalls, 1);
      expect(c.isDone, true);
    },
  );

  test(
    'ensure() mendorong penanda belum sinkron (pushPendingMarks) sesudah '
    'langkah lain selesai',
    () async {
      final c = build();
      await c.ensure();
      verify(() => streakRepo.pushPendingMarks()).called(1);
    },
  );

  test(
    'non-fatal: streak sync/push gagal → langkah lain tetap jalan, ensure() '
    'selesai',
    () async {
      when(
        () => streakRepo.syncMarksFromRemote(),
      ).thenThrow(Exception('offline'));
      when(
        () => streakRepo.pushPendingMarks(),
      ).thenThrow(Exception('offline'));
      final c = build();
      await c.ensure(); // tak melempar
      verify(
        () => prefsRepo.syncOnLaunch(
          budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
        ),
      ).called(1);
      expect(c.isDone, true);
    },
  );

  test('(a) memanggil scheduler.rescheduleAll pengingat tagihan setelah sync '
      'bills (device baru/reinstall langsung dapat pengingat)', () async {
    final c = build();
    await c.ensure();
    verify(() => billRepo.syncBillsFromRemote()).called(1);
    verify(
      () => billScheduler.rescheduleAll(
        any(),
        globalDaysBefore: 1,
        globalHour: 9,
      ),
    ).called(1);
  });

  test(
    'non-fatal: reschedule pengingat tagihan gagal → ensure() tetap selesai',
    () async {
      when(
        () => billScheduler.rescheduleAll(
          any(),
          globalDaysBefore: any(named: 'globalDaysBefore'),
          globalHour: any(named: 'globalHour'),
        ),
      ).thenThrow(Exception('notif error'));
      final c = build();
      await c.ensure(); // tak melempar
      expect(c.isDone, true);
      expect(onCompleteCalls, 1);
    },
  );

  test('memo: panggilan paralel & berurutan → kerja jalan SEKALI', () async {
    final c = build();
    await Future.wait([c.ensure(), c.ensure()]);
    await c.ensure();
    verify(
      () => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
      ),
    ).called(1);
    expect(onCompleteCalls, 1); // onComplete tak berulang tiap ensure()
  });

  test(
    'non-fatal: identity/budget gagal → syncOnLaunch tetap jalan, ensure() selesai',
    () async {
      when(() => syncUserSettings(any())).thenThrow(Exception('offline'));
      when(
        () => budgetRepo.syncBudgetFromRemote(),
      ).thenThrow(Exception('offline'));
      final c = build();
      await c.ensure(); // tak melempar
      verify(
        () => prefsRepo.syncOnLaunch(
          budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
        ),
      ).called(1);
      expect(c.isDone, true);
    },
  );

  test('reset(): user berikutnya bootstrap dari awal', () async {
    final c = build();
    await c.ensure();
    c.reset();
    expect(c.isDone, false);
    await c.ensure();
    verify(
      () => prefsRepo.syncOnLaunch(
        budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
      ),
    ).called(2);
    expect(onCompleteCalls, 2);
  });

  test(
    'non-fatal: goal restore gagal → langkah lain tetap jalan, ensure() selesai',
    () async {
      when(
        () => goalRepo.syncGoalsFromRemote(),
      ).thenThrow(Exception('offline'));
      final c = build();
      await c.ensure(); // tak melempar
      verify(
        () => prefsRepo.syncOnLaunch(
          budgetOnboardingCompleted: any(named: 'budgetOnboardingCompleted'),
        ),
      ).called(1);
      expect(c.isDone, true);
    },
  );
}
