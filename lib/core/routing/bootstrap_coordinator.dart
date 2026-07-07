import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

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
    required void Function()
    onComplete, // produksi: () => resetOnboardingCache()
    Duration stepTimeout = const Duration(seconds: 3),
  }) : _syncUserSettings = syncUserSettings,
       _budget = budgetRepository,
       _goals = goalRepository,
       _onboardingDs = onboardingDs,
       _prefs = prefsRepo,
       _onComplete = onComplete,
       _stepTimeout = stepTimeout;

  final SyncUserSettingsUseCase _syncUserSettings;
  final BudgetRepository _budget;
  final GoalRepository _goals;
  final OnboardingLocalDataSource _onboardingDs;
  final PreferencesRepository _prefs;
  final void Function() _onComplete;
  final Duration _stepTimeout;

  Future<void>? _inflight;
  bool _done = false;
  bool get isDone => _done;

  /// Idempoten: jalan SEKALI per sesi; panggilan berikutnya menunggu Future yang sama.
  Future<void> ensure() => _inflight ??= _run();

  Future<void> _run() async {
    // Identity + budget + goal paralel (restorasi data akun) — non-fatal.
    try {
      await Future.wait([
        _syncUserSettings(const NoParams()),
        _budget.syncBudgetFromRemote().timeout(_stepTimeout),
        _goals.syncGoalsFromRemote().timeout(_stepTimeout),
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
