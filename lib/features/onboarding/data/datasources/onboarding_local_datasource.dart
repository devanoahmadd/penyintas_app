import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/budget_settings_entity.dart';

abstract class OnboardingLocalDataSource {
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<BudgetSettingsEntity?> getBudgetSettings();
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
  });
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
          fixedExpenses: Value(settings.fixedExpenses),
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
      fixedExpenses: saved.fixedExpenses,
      emergencyFundPct: saved.emergencyFundPct,
      createdAt: saved.onboardingCreatedAt ?? DateTime.now(),
    );
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
}
