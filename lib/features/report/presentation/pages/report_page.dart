import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_state.dart';
import 'package:penyintas_app/features/report/presentation/widgets/category_pie_chart.dart';
import 'package:penyintas_app/features/report/presentation/widgets/insight_card.dart';
import 'package:penyintas_app/features/report/presentation/widgets/month_selector.dart';
import 'package:penyintas_app/features/report/presentation/widgets/weekly_bar_chart.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Laporan', style: AppTextStyles.h2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              final month = state is ReportLoaded
                  ? state.selectedMonth
                  : DateTime.now();
              return MonthSelector(
                selectedMonth: month,
                onPrevious: () =>
                    context.read<ReportBloc>().add(const PreviousMonth()),
                onNext: () =>
                    context.read<ReportBloc>().add(const NextMonth()),
              );
            },
          ),
        ),
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return _ErrorView(message: state.message);
          }
          if (state is ReportLoaded) {
            return _ReportContent(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.state});

  final ReportLoaded state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final report = state.report;

    final netIsPositive = report.netBalance >= 0;
    final netColor = netIsPositive ? AppColors.success : AppColors.warn;
    final comparedPct = report.comparedToPreviousMonth;
    final comparedText = comparedPct == 0.0
        ? 'Bulan pertama'
        : comparedPct > 0
            ? '+${(comparedPct * 100).toStringAsFixed(1)}% dari bulan lalu'
            : '${(comparedPct * 100).toStringAsFixed(1)}% dari bulan lalu';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryItem(
                    label: 'PENGELUARAN',
                    value: formatRupiah(report.totalSpent),
                    valueColor: AppColors.warn,
                    textColor: textColor,
                  ),
                  _SummaryItem(
                    label: 'PEMASUKAN',
                    value: formatRupiah(report.totalIncome),
                    valueColor: AppColors.success,
                    textColor: textColor,
                  ),
                  _SummaryItem(
                    label: 'SALDO BERSIH',
                    value: report.netBalance == 0
                        ? formatRupiah(0)
                        : '${report.netBalance < 0 ? '− ' : '+ '}${formatRupiah(report.netBalance.abs())}',
                    valueColor: netColor,
                    textColor: textColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                comparedText,
                style: AppTextStyles.caption.copyWith(color: textSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pie chart
        Text('Pengeluaran per Kategori', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        CategoryPieChart(breakdown: report.categoryBreakdown),
        const SizedBox(height: AppSpacing.xl),

        // Bar chart
        Text('Pengeluaran per Minggu', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        WeeklyBarChart(weeklyData: report.weeklyBreakdown),
        const SizedBox(height: AppSpacing.xl),

        // Daily average
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rata-rata per hari',
                style: AppTextStyles.bodySmall.copyWith(color: textSoft),
              ),
              Text(
                formatRupiah(report.dailyAverageSpend.round()),
                style: AppTextStyles.label.copyWith(color: textColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // AI insight
        InsightCard(
          isLoading: state.isLoadingInsight,
          insights: report.aiInsights,
          savingTip: report.savingTip,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.mutedDark
                : AppColors.mutedLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.numericSm.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.warn, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
