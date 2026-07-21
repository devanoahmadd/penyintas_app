import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/budget/data/models/budget_limit_model.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';

abstract class BudgetLocalDatasource {
  Future<BudgetSettingsEntity?> getBudgetSettings();
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings);
  Future<List<BudgetLimitEntity>> getBudgetLimits();
  Future<int> saveBudgetLimit(BudgetLimitEntity limit);
  Future<void> deleteBudgetLimit(int id);
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  });
}

class BudgetLocalDatasourceImpl implements BudgetLocalDatasource {
  BudgetLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<BudgetSettingsEntity?> getBudgetSettings() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null || row.monthlyIncome == 0 || !row.onboardingCompleted)
      return null;
    return BudgetSettingsEntity(
      monthlyIncome: row.monthlyIncome,
      paymentDate: row.paymentDate,
      emergencyFundPct: row.emergencyFundPct,
      createdAt: row.onboardingCreatedAt ?? DateTime.now(),
      rentExpense: row.rentExpense,
      utilitiesExpense: row.utilitiesExpense,
      internetExpense: row.internetExpense,
      phoneExpense: row.phoneExpense,
      otherFixedExpense: row.otherFixedExpense,
    );
  }

  @override
  Future<void> saveBudgetSettings(BudgetSettingsEntity settings) async {
    final existing = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1),
            // Vestigial pasca-cutover (C2): dipertahankan agar kolom NOT NULL tak ter-clobber;
            // TAK ada yang membacanya lagi — language canonical hidup di `preferences`.
            locale: Value(existing?.locale ?? 'id'),
            themeMode: Value(existing?.themeMode ?? 'system'),
            onboardingCompleted: const Value(true),
            monthlyIncome: Value(settings.monthlyIncome),
            paymentDate: Value(settings.paymentDate),
            fixedExpenses: Value(settings.fixedExpenses),
            rentExpense: Value(settings.rentExpense),
            utilitiesExpense: Value(settings.utilitiesExpense),
            internetExpense: Value(settings.internetExpense),
            phoneExpense: Value(settings.phoneExpense),
            otherFixedExpense: Value(settings.otherFixedExpense),
            emergencyFundPct: Value(settings.emergencyFundPct),
            onboardingCreatedAt: Value(
              existing?.onboardingCreatedAt ?? settings.createdAt,
            ),
          ),
        );
  }

  @override
  Future<List<BudgetLimitEntity>> getBudgetLimits() async {
    final rows = await _db.select(_db.budgetLimits).get();
    return rows.map(BudgetLimitModel.fromRow).toList();
  }

  @override
  Future<int> saveBudgetLimit(BudgetLimitEntity limit) async {
    final existing = await (_db.select(
      _db.budgetLimits,
    )..where((t) => t.category.equals(limit.category))).getSingleOrNull();
    if (existing != null) {
      final model = BudgetLimitModel.fromEntity(
        limit.copyWith(id: existing.id),
      );
      await (_db.update(
        _db.budgetLimits,
      )..where((t) => t.id.equals(existing.id))).write(model.toCompanion());
      return existing.id;
    } else {
      final model = BudgetLimitModel.fromEntity(limit);
      return _db.into(_db.budgetLimits).insert(model.toCompanion());
    }
  }

  @override
  Future<void> deleteBudgetLimit(int id) async {
    await (_db.delete(_db.budgetLimits)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> addToSyncQueue({
    required String itemId,
    required String collectionPath,
    required Map<String, dynamic> data,
    required SyncOperation operation,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion(
            itemId: Value(itemId),
            collectionPath: Value(collectionPath),
            data: Value(jsonEncode(data)),
            operation: Value(operation),
            createdAt: Value(DateTime.now()),
          ),
        );
  }
}
