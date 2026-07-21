import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';

/// Donut chart showing income allocation: Operasional / Tetap / Dana Darurat.
///
/// Center of the donut shows total monthly income + "/bulan" label.
/// Returns [SizedBox.shrink] if total income is not configured.
class BudgetAllocationRing extends StatelessWidget {
  const BudgetAllocationRing({super.key, required this.overview});
  final BudgetOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final textMain = isDark ? AppColors.textDark : AppColors.textLight;

    final fixed = overview.totalFixedExpenses.toDouble();
    final emergency = overview.emergencyFundMonthly.toDouble();
    final spendable = overview.totalSpendable.toDouble();
    final total = fixed + emergency + spendable;
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ───────────────────────────────────────────────
        Text('ALOKASI PENDAPATAN', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.lg),

        // ── Donut + center overlay ──────────────────────────────────────
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: spendable,
                      color: AppColors.primary,
                      title: '',
                      radius: 30,
                    ),
                    PieChartSectionData(
                      value: fixed,
                      color: AppColors.warn,
                      title: '',
                      radius: 30,
                    ),
                    PieChartSectionData(
                      value: emergency,
                      color: AppColors.caution,
                      title: '',
                      radius: 30,
                    ),
                  ],
                ),
              ),
              // Center total overlay
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatRupiahCompact(overview.monthlyIncome),
                    style: AppTextStyles.numericMd.copyWith(
                      color: textMain,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '/bulan',
                    style: AppTextStyles.caption.copyWith(
                      color: muted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Legend ──────────────────────────────────────────────────────
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
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
  });

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
            formatRupiahCompact(amount),
            style: AppTextStyles.numericSm.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
