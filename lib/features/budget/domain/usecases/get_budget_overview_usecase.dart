import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_limit_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_settings_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

class GetBudgetOverviewUseCase {
  const GetBudgetOverviewUseCase();

  BudgetOverviewEntity call(OverviewParams params) {
    final s = params.settings;
    final emergencyFundMonthly = (s.monthlyIncome * s.emergencyFundPct).round();
    final totalFixedExpenses = s.fixedExpenses;
    final totalSpendable =
        (s.monthlyIncome - totalFixedExpenses - emergencyFundMonthly).clamp(0, s.monthlyIncome);

    final daysElapsed = params.daysElapsed;
    final remainingDays = params.remainingDays;

    // Gunakan daftar dari DB (via OverviewParams) — bukan lagi hardcode (#Fase3A)
    final categoryItems = params.limitableCategories.map((cat) {
      final limit = params.limits
          .where((l) => l.category == cat.slug && l.isEnabled)
          .firstOrNull;
      final spent = params.currentPeriodTransactions
          .where((t) => t.category.name == cat.slug && t.type == TransactionType.expense)
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

      int? projectedDaysLeft;
      BudgetStatus? catPaceStatus;
      if (daysElapsed > 0 && spent > 0 && remainingDays > 0) {
        final dailyBurn = spent / daysElapsed;
        final catRemaining =
            (limit.limitAmount - spent).clamp(0, limit.limitAmount);
        projectedDaysLeft = catRemaining > 0
            ? (catRemaining / dailyBurn).floor()
            : 0;
        catPaceStatus = projectedDaysLeft >= remainingDays
            ? BudgetStatus.safe
            : projectedDaysLeft >= (remainingDays * 0.5).ceil()
                ? BudgetStatus.caution
                : BudgetStatus.danger;
      }

      return CategoryBudgetItem(
        category: cat,
        limitAmount: limit.limitAmount,
        cycleType: limit.cycleType,
        spentAmount: spent,
        usagePct: clampedPct,
        status: status,
        projectedDaysLeft: projectedDaysLeft,
        paceStatus: catPaceStatus,
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
      remainingDays: remainingDays,
      daysElapsed: daysElapsed,
    );
  }
}

class OverviewParams extends Equatable {
  const OverviewParams({
    required this.settings,
    required this.limits,
    required this.currentPeriodTransactions,
    required this.remainingDays,
    required this.daysElapsed,
    required this.limitableCategories,
  });

  final BudgetSettingsEntity settings;
  final List<BudgetLimitEntity> limits;
  final List<TransactionEntity> currentPeriodTransactions;
  final int remainingDays;
  final int daysElapsed;

  /// Kategori yang bisa dibatasi — diisi dari DB via GetLimitableCategoriesUseCase.
  /// Menggantikan daftar hardcode di usecase sebelumnya (#Fase3A).
  final List<CategoryEntity> limitableCategories;

  @override
  List<Object> get props => [
        settings, limits, currentPeriodTransactions,
        remainingDays, daysElapsed, limitableCategories,
      ];
}
