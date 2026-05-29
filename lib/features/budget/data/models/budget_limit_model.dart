import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class BudgetLimitModel extends BudgetLimitEntity {
  const BudgetLimitModel({
    required super.id,
    required super.category,
    required super.limitAmount,
    required super.cycleType,
    required super.isEnabled,
    required super.updatedAt,
  });

  factory BudgetLimitModel.fromRow(BudgetLimit row) => BudgetLimitModel(
        id: row.id,
        category: TransactionCategory.values.byName(row.category),
        limitAmount: row.limitAmount,
        cycleType: row.cycleType,
        isEnabled: row.isEnabled,
        updatedAt: row.updatedAt,
      );

  factory BudgetLimitModel.fromEntity(BudgetLimitEntity entity) =>
      BudgetLimitModel(
        id: entity.id,
        category: entity.category,
        limitAmount: entity.limitAmount,
        cycleType: entity.cycleType,
        isEnabled: entity.isEnabled,
        updatedAt: entity.updatedAt,
      );

  BudgetLimitsCompanion toCompanion() => BudgetLimitsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        category: Value(category.name),
        limitAmount: Value(limitAmount),
        cycleType: Value(cycleType),
        isEnabled: Value(isEnabled),
        updatedAt: Value(updatedAt),
      );

  Map<String, dynamic> toFirestore() => {
        'category': category.name,
        'limitAmount': limitAmount,
        'cycleType': cycleType,
        'isEnabled': isEnabled,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
