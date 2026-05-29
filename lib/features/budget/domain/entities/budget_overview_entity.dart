import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class BudgetOverviewEntity extends Equatable {
  const BudgetOverviewEntity({
    required this.monthlyIncome,
    required this.totalFixedExpenses,
    required this.emergencyFundMonthly,
    required this.totalSpendable,
    required this.categoryItems,
    required this.totalLimitSet,
    required this.totalSpentInLimited,
    required this.overallStatus,
  });

  final int monthlyIncome;
  final int totalFixedExpenses;
  final int emergencyFundMonthly;
  final int totalSpendable;
  final List<CategoryBudgetItem> categoryItems;
  final int totalLimitSet;
  final int totalSpentInLimited;
  final BudgetStatus overallStatus;

  @override
  List<Object> get props => [
        monthlyIncome, totalFixedExpenses, emergencyFundMonthly,
        totalSpendable, categoryItems, totalLimitSet,
        totalSpentInLimited, overallStatus,
      ];
}

class CategoryBudgetItem extends Equatable {
  const CategoryBudgetItem({
    required this.category,
    required this.spentAmount,
    this.limitAmount,
    this.cycleType,
    this.usagePct,
    this.status,
  });

  final TransactionCategory category;
  final int? limitAmount;
  final String? cycleType;
  final int spentAmount;
  final double? usagePct;
  final BudgetStatus? status;

  bool get hasLimit => limitAmount != null;

  @override
  List<Object?> get props =>
      [category, limitAmount, cycleType, spentAmount, usagePct, status];
}
