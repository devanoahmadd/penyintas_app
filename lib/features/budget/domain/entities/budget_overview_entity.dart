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

  /// Total yang sudah dibelanjakan di semua kategori operasional.
  int get totalOperationalSpent =>
      categoryItems.fold(0, (sum, i) => sum + i.spentAmount);

  /// Sisa anggaran operasional = totalSpendable - totalOperationalSpent (min 0).
  int get operationalRemaining =>
      (totalSpendable - totalOperationalSpent).clamp(0, totalSpendable);

  /// Persentase pemakaian operasional 0.0–1.0.
  double get operationalUsagePct => totalSpendable > 0
      ? (totalOperationalSpent / totalSpendable).clamp(0.0, 1.0)
      : 0.0;

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

  // ── Computed helpers ────────────────────────────────────────────────────

  @override
  List<Object?> get props =>
      [category, limitAmount, cycleType, spentAmount, usagePct, status];
}
