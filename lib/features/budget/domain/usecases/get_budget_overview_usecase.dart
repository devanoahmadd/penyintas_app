import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class GetBudgetOverviewUseCase {
  const GetBudgetOverviewUseCase();

  static const _limitableCategories = [
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.shopping,
    TransactionCategory.health,
    TransactionCategory.internet,
    TransactionCategory.other,
  ];

  BudgetOverviewEntity call(OverviewParams params) {
    final s = params.settings;
    final emergencyFundMonthly = (s.monthlyIncome * s.emergencyFundPct).round();
    final totalFixedExpenses = s.fixedExpenses;
    final totalSpendable =
        (s.monthlyIncome - totalFixedExpenses - emergencyFundMonthly).clamp(0, s.monthlyIncome);

    final categoryItems = _limitableCategories.map((cat) {
      final limit = params.limits
          .where((l) => l.category == cat && l.isEnabled)
          .firstOrNull;
      final spent = params.currentPeriodTransactions
          .where((t) => t.category == cat && t.type == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);

      if (limit == null) {
        return CategoryBudgetItem(category: cat, spentAmount: spent);
      }

      final pct = limit.limitAmount > 0 ? spent / limit.limitAmount : 1.0;
      final clampedPct = pct.clamp(0.0, 1.0);
      final status = pct <= 0.5
          ? BudgetStatus.safe
          : pct <= 0.8
              ? BudgetStatus.caution
              : BudgetStatus.danger;

      return CategoryBudgetItem(
        category: cat,
        limitAmount: limit.limitAmount,
        cycleType: limit.cycleType,
        spentAmount: spent,
        usagePct: clampedPct,
        status: status,
      );
    }).toList();

    final withLimit = categoryItems.where((i) => i.hasLimit).toList();
    final totalLimitSet = withLimit.fold(0, (sum, i) => sum + (i.limitAmount ?? 0));
    final totalSpentInLimited = withLimit.fold(0, (sum, i) => sum + i.spentAmount);

    BudgetStatus overallStatus;
    if (withLimit.isEmpty) {
      overallStatus = BudgetStatus.safe;
    } else if (withLimit.any((i) => i.status == BudgetStatus.danger)) {
      overallStatus = BudgetStatus.danger;
    } else if (withLimit.any((i) => i.status == BudgetStatus.caution)) {
      overallStatus = BudgetStatus.caution;
    } else {
      overallStatus = BudgetStatus.safe;
    }

    return BudgetOverviewEntity(
      monthlyIncome: s.monthlyIncome,
      totalFixedExpenses: totalFixedExpenses,
      emergencyFundMonthly: emergencyFundMonthly,
      totalSpendable: totalSpendable,
      categoryItems: categoryItems,
      totalLimitSet: totalLimitSet,
      totalSpentInLimited: totalSpentInLimited,
      overallStatus: overallStatus,
    );
  }
}

class OverviewParams extends Equatable {
  const OverviewParams({
    required this.settings,
    required this.limits,
    required this.currentPeriodTransactions,
    required this.remainingDays,
  });

  final BudgetSettingsEntity settings;
  final List<BudgetLimitEntity> limits;
  final List<TransactionEntity> currentPeriodTransactions;
  final int remainingDays;

  @override
  List<Object> get props => [settings, limits, currentPeriodTransactions, remainingDays];
}
