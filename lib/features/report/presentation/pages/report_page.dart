import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_state.dart';
import 'package:penyintas_app/features/report/presentation/widgets/category_pie_chart.dart';
import 'package:penyintas_app/features/report/presentation/widgets/insight_card.dart';
import 'package:penyintas_app/features/report/presentation/widgets/month_selector.dart';
import 'package:penyintas_app/features/report/presentation/widgets/weekly_bar_chart.dart';

/// Label perbandingan bulan (#99) — top-level agar bisa diuji tanpa widget.
/// String hardcoded Indonesia — konsisten halaman; sapu l10n = D-sprint 2.
String comparedLabelText(ReportEntity report) {
  final pct = report.comparedToPreviousMonth;
  if (pct == null) {
    if (report.hasPreviousMonthData) return 'Bulan lalu tanpa pengeluaran';
    final monthIsEmpty = report.totalSpent == 0 && report.totalIncome == 0;
    return monthIsEmpty ? 'Belum ada catatan bulan ini' : 'Bulan pertama';
  }
  if (pct == 0.0) return 'Sama dengan bulan lalu';
  final formatted = '${(pct * 100).toStringAsFixed(1)}% dari bulan lalu';
  return pct > 0 ? '+$formatted' : formatted;
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _shareKey = GlobalKey();

  Future<void> _shareReport(BuildContext context, ReportLoaded state) async {
    try {
      final obj = _shareKey.currentContext?.findRenderObject();
      if (obj is! RenderRepaintBoundary) return;
      final image = await obj.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final month = DateFormat('yyyy-MM').format(state.report.month);
      final file = File('${dir.path}/penyintas_laporan_$month.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            subject: 'Laporan Keuangan Penyintas $month',
          ),
        );
      } finally {
        await file.delete().catchError((_) => file);
      }
    } catch (_) {
      // share errors are non-fatal
    }
  }

  Widget _buildBody(ReportState state) {
    if (state is ReportLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ReportError) {
      return _ErrorView(message: state.message);
    }
    if (state is ReportLoaded) {
      return _ReportContent(state: state, shareKey: _shareKey);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final iconColor = isDark ? AppColors.textDark : AppColors.textLight;

    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        final selectedMonth = state is ReportLoaded
            ? state.selectedMonth
            : DateTime.now();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text('Laporan', style: AppTextStyles.h2),
            actions: [
              if (state is ReportLoaded)
                IconButton(
                  icon: Icon(Icons.share_outlined, color: iconColor),
                  tooltip: 'Bagikan laporan',
                  onPressed: () => _shareReport(context, state),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: MonthSelector(
                selectedMonth: selectedMonth,
                onPrevious: () =>
                    context.read<ReportBloc>().add(const PreviousMonth()),
                onNext: () => context.read<ReportBloc>().add(const NextMonth()),
              ),
            ),
          ),
          body: _buildBody(state),
        );
      },
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.state, required this.shareKey});

  final ReportLoaded state;
  final GlobalKey shareKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final report = state.report;

    final netIsPositive = report.netBalance >= 0;
    final netColor = netIsPositive ? AppColors.success : AppColors.warn;
    final comparedText = comparedLabelText(report);

    final monthLabel = DateFormat(
      'MMMM yyyy',
      'id',
    ).format(report.month).toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary card — wrapped in RepaintBoundary for share screenshot
        RepaintBoundary(
          key: shareKey,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAPORAN $monthLabel',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                          : '${report.netBalance < 0 ? '− ' : '+ '}${formatRupiah(report.netBalance.abs())}',
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Penyintas',
                      style: AppTextStyles.caption.copyWith(color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Pengeluaran per Kategori', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        CategoryPieChart(breakdown: report.categoryBreakdown),
        const SizedBox(height: AppSpacing.xl),

        Text('Pengeluaran per Minggu', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        WeeklyBarChart(weeklyData: report.weeklyBreakdown),
        const SizedBox(height: AppSpacing.xl),

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
        Text(value, style: AppTextStyles.numericSm.copyWith(color: valueColor)),
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
