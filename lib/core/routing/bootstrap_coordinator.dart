import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

/// Gerbang bootstrap SATU-TEMBAK per sesi login (Temuan 1, Opsi 1).
/// Menjalankan restorasi identity + budget + preferences (`syncOnLaunch`) SEKALI,
/// dipakai bersama oleh splash (cold-start) DAN `_redirect` (fresh-login/deep-link)
/// agar gerbang tak bergantung pada layar mana yang jadi entry-point. Memo `Future`
/// → panggilan berikutnya menunggu Future yang sama (instan setelah selesai).
class BootstrapCoordinator {
  BootstrapCoordinator({
    required SyncUserSettingsUseCase syncUserSettings,
    required BudgetRepository budgetRepository,
    required GoalRepository goalRepository,
    required OnboardingLocalDataSource onboardingDs,
    required PreferencesRepository prefsRepo,
    required BillRepository billRepository,
    required BillReminderScheduler billReminderScheduler,
    required BillReminderSettingsDatasource billReminderSettings,
    required StreakRepository streakRepository,
    required ChallengeRepository challengeRepository,
    required void Function()
    onComplete, // produksi: () => resetOnboardingCache()
    Duration stepTimeout = const Duration(seconds: 3),
  }) : _syncUserSettings = syncUserSettings,
       _budget = budgetRepository,
       _goals = goalRepository,
       _onboardingDs = onboardingDs,
       _prefs = prefsRepo,
       _bills = billRepository,
       _billScheduler = billReminderScheduler,
       _billReminderSettings = billReminderSettings,
       _streak = streakRepository,
       _challenge = challengeRepository,
       _onComplete = onComplete,
       _stepTimeout = stepTimeout;

  final SyncUserSettingsUseCase _syncUserSettings;
  final BudgetRepository _budget;
  final GoalRepository _goals;
  final OnboardingLocalDataSource _onboardingDs;
  final PreferencesRepository _prefs;
  final BillRepository _bills;
  final BillReminderScheduler _billScheduler;
  final BillReminderSettingsDatasource _billReminderSettings;
  final StreakRepository _streak;
  final ChallengeRepository _challenge;
  final void Function() _onComplete;
  final Duration _stepTimeout;

  Future<void>? _inflight;
  bool _done = false;
  bool get isDone => _done;

  /// Idempoten: jalan SEKALI per sesi; panggilan berikutnya menunggu Future yang sama.
  Future<void> ensure() => _inflight ??= _run();

  Future<void> _run() async {
    // Identity + budget + goal + bills paralel (restorasi data akun) — non-fatal.
    try {
      await Future.wait([
        _syncUserSettings(const NoParams()),
        _budget.syncBudgetFromRemote().timeout(_stepTimeout),
        _goals.syncGoalsFromRemote().timeout(_stepTimeout),
        _bills.syncBillsFromRemote().timeout(_stepTimeout),
        _streak.syncMarksFromRemote().timeout(_stepTimeout),
        _challenge.syncChallengesFromRemote().timeout(_stepTimeout),
      ]);
    } catch (e, s) {
      _recordNonFatal(e, s);
    }
    // Bootstrap preferences — butuh onboardingCompleted (smart-default akun lama, §9).
    try {
      final budgetDone = await _onboardingDs.isOnboardingCompleted();
      await _prefs.syncOnLaunch(budgetOnboardingCompleted: budgetDone);
    } catch (e, s) {
      _recordNonFatal(e, s);
    }
    // Reschedule pengingat tagihan (Task 6.2) — pasca pull-all-on-first-sync
    // di atas, device baru/reinstall/login akun lama langsung dapat pengingat
    // tanpa perlu buka halaman Tagihan dulu. Non-fatal: kegagalan notif TIDAK
    // boleh menggagalkan bootstrap.
    try {
      final activeResult = await _bills.watchActiveBills().first.timeout(
        _stepTimeout,
      );
      final activeBills = activeResult.fold((_) => null, (bills) => bills);
      if (activeBills != null) {
        final settings = await _billReminderSettings.read();
        await _billScheduler
            .rescheduleAll(
              activeBills,
              globalDaysBefore: settings.daysBefore,
              globalHour: settings.hour,
            )
            .timeout(_stepTimeout);
      }
    } catch (e, s) {
      _recordNonFatal(e, s);
    }
    // Dorong penanda yang belum sempat naik (D-9). SENGAJA di luar
    // `Future.wait`: N panggilan jaringan berurutan tidak muat di jendela
    // 3 detik, dan menaruhnya di dalam membuat timeout membatalkan
    // pemulihan yang justru paling penting. Non-fatal.
    try {
      await _streak.pushPendingMarks().timeout(const Duration(seconds: 15));
    } catch (e, s) {
      _recordNonFatal(e, s);
    }
    // Dorongan tantangan — blok TERPISAH dengan anggaran waktunya sendiri,
    // sama alasannya dengan dorongan penanda di atas (D-9). Menaruhnya di
    // dalam `Future.wait` tarikan ber-timeout 3 detik membuat tarikan tak
    // pernah jalan — dan di Fase 1 itu lolos SELURUH test. Non-fatal.
    try {
      await _challenge.pushPendingChallenges().timeout(
        const Duration(seconds: 15),
      );
    } catch (e, s) {
      _recordNonFatal(e, s);
    }
    _done = true;
    _onComplete(); // reset cache guard SEKALI → pembaca berikutnya lihat state ter-bootstrap
  }

  /// Dipanggil saat logout agar user berikutnya bootstrap dari awal.
  void reset() {
    _inflight = null;
    _done = false;
  }

  static void _recordNonFatal(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    } catch (_) {}
  }
}
