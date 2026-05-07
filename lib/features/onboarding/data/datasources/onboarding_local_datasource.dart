import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:penyintas_app/core/local/sync_queue_isar_model.dart';
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
  OnboardingLocalDataSourceImpl(this._isar);
  final Isar _isar;

  @override
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings) async {
    final existing = await _isar.appSettingsIsarModels.get(1);
    final model = AppSettingsIsarModel()
      ..id = 1
      ..locale = existing?.locale ?? 'id'
      ..themeMode = existing?.themeMode ?? 'system'
      ..onboardingCompleted = true
      ..monthlyIncome = settings.monthlyIncome
      ..paymentDate = settings.paymentDate
      ..fixedExpenses = settings.fixedExpenses
      ..emergencyFundPct = settings.emergencyFundPct;
    await _isar.writeTxn(() => _isar.appSettingsIsarModels.put(model));
  }

  @override
  Future<BudgetSettingsEntity?> getBudgetSettings() async {
    final saved = await _isar.appSettingsIsarModels.get(1);
    if (saved == null || saved.monthlyIncome == 0) return null;
    return BudgetSettingsEntity(
      monthlyIncome: saved.monthlyIncome,
      paymentDate: saved.paymentDate,
      fixedExpenses: saved.fixedExpenses,
      emergencyFundPct: saved.emergencyFundPct,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueIsarModel()
      ..itemId = itemId
      ..collectionPath = collectionPath
      ..data = jsonEncode(data)
      ..operation = SyncOperation.create
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() => _isar.syncQueueIsarModels.put(item));
  }
}
