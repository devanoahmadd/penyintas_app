import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';

class BudgetAllocationRing extends StatelessWidget {
  const BudgetAllocationRing({super.key, required this.overview});
  final BudgetOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    final fixed = overview.totalFixedExpenses.toDouble();
    final emergency = overview.emergencyFundMonthly.toDouble();
    final spendable = overview.totalSpendable.toDouble();
    final total = fixed + emergency + spendable;
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 56,
                sections: [
                  PieChartSectionData(
                    value: fixed,
                    color: AppColors.warn,
                    title: '',
                    radius: 28,
                  ),
                  PieChartSectionData(
                    value: emergency,
                    color: AppColors.caution,
                    title: '',
                    radius: 28,
                  ),
                  PieChartSectionData(
                    value: spendable,
                    color: AppColors.primary,
                    title: '',
                    radius: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _LegendRow(
            color: AppColors.primary,
            label: 'Operasional',
            amount: overview.totalSpendable,
          ),
          _LegendRow(
            color: AppColors.warn,
            label: 'Tetap',
            amount: overview.totalFixedExpenses,
          ),
          _LegendRow(
            color: AppColors.caution,
            label: 'Dana Darurat',
            amount: overview.emergencyFundMonthly,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.amount});
  final Color color;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(
            formatRupiah(amount),
            style: AppTextStyles.numericSm.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
