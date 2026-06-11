import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';

abstract class OnboardingLocalDataSource {
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<BudgetSettingsEntity?> getBudgetSettings();
  Future<bool> isOnboardingCompleted();
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
  });
  Future<void> savePartialOnboarding({
    required int step,
    required int income,
    required Map<String, int> expenses,
    required int pct,
    required int payday,
  });
  Future<PartialOnboardingState?> loadPartialOnboarding();
  Future<void> clearPartialOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings) async {
    final existing = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
          id: const Value(1),
          locale: Value(existing?.locale ?? 'id'),
          themeMode: Value(existing?.themeMode ?? 'system'),
          onboardingCompleted: const Value(true),
          monthlyIncome: Value(settings.monthlyIncome),
          paymentDate: Value(settings.paymentDate),
          fixedExpenses: Value(settings.fixedExpenses), // computed sum — backward compat
          rentExpense: Value(settings.rentExpense),
          utilitiesExpense: Value(settings.utilitiesExpense),
          internetExpense: Value(settings.internetExpense),
          phoneExpense: Value(settings.phoneExpense),
          otherFixedExpense: Value(settings.otherFixedExpense),
          emergencyFundPct: Value(settings.emergencyFundPct),
          // Set once — jangan overwrite jika sudah ada
          onboardingCreatedAt:
              Value(existing?.onboardingCreatedAt ?? settings.createdAt),
        ));
  }

  @override
  Future<BudgetSettingsEntity?> getBudgetSettings() async {
    final saved = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (saved == null || saved.monthlyIncome == 0) return null;
    return BudgetSettingsEntity(
      monthlyIncome: saved.monthlyIncome,
      paymentDate: saved.paymentDate,
      emergencyFundPct: saved.emergencyFundPct,
      createdAt: saved.onboardingCreatedAt ?? DateTime.now(),
      rentExpense: saved.rentExpense,
      utilitiesExpense: saved.utilitiesExpense,
      internetExpense: saved.internetExpense,
      phoneExpense: saved.phoneExpense,
      otherFixedExpense: saved.otherFixedExpense,
    );
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final saved = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    return (saved?.onboardingCompleted ?? false) &&
        (saved?.monthlyIncome ?? 0) > 0;
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final existing = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    final operation = (existing?.onboardingCompleted ?? false)
        ? SyncOperation.update
        : SyncOperation.create;
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
          itemId: Value(itemId),
          collectionPath: Value(collectionPath),
          data: Value(jsonEncode(data)),
          operation: Value(operation),
          createdAt: Value(DateTime.now()),
        ));
  }

  @override
  Future<void> savePartialOnboarding({
    required int step,
    required int income,
    required Map<String, int> expenses,
    required int pct,
    required int payday,
  }) async {
    final existing = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
      id: const Value(1),
      locale: Value(existing?.locale ?? 'id'),
      themeMode: Value(existing?.themeMode ?? 'system'),
      onboardingCompleted: Value(existing?.onboardingCompleted ?? false),
      monthlyIncome: Value(income),
      paymentDate: Value(payday),
      fixedExpenses: Value(expenses.values.fold(0, (s, v) => s + v)),
      rentExpense: Value(expenses['kos'] ?? 0),
      utilitiesExpense: Value(expenses['listrik'] ?? 0),
      internetExpense: Value(expenses['internet'] ?? 0),
      phoneExpense: Value(expenses['pulsa'] ?? 0),
      otherFixedExpense: Value(expenses['lain'] ?? 0),
      emergencyFundPct: Value(pct / 100),
      partialOnboardingStep: Value(step),
      partialOnboardingAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  @override
  Future<PartialOnboardingState?> loadPartialOnboarding() async {
    final saved = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (saved == null ||
        saved.partialOnboardingStep == null ||
        saved.partialOnboardingAt == null ||
        saved.partialOnboardingStep! < 0 ||
        saved.partialOnboardingStep! > 2) {
      // #235/#233: partial state tak utuh / step invalid → fresh start, jangan crash.
      return null;
    }
    return PartialOnboardingState(
      step: saved.partialOnboardingStep!,
      income: saved.monthlyIncome,
      expenses: {
        'kos': saved.rentExpense,
        'listrik': saved.utilitiesExpense,
        'internet': saved.internetExpense,
        'pulsa': saved.phoneExpense,
        'lain': saved.otherFixedExpense,
      },
      pct: (saved.emergencyFundPct * 100).round(),
      payday: saved.paymentDate,
      savedAt: DateTime.fromMillisecondsSinceEpoch(saved.partialOnboardingAt!),
    );
  }

  @override
  Future<void> clearPartialOnboarding() async {
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(const AppSettingsCompanion(
      partialOnboardingStep: Value(null),
      partialOnboardingAt: Value(null),
    ));
  }
}
