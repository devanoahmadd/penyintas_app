import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.weeklyData});

  final List<WeeklySpendEntity> weeklyData;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: weeklyData.map((w) {
            return BarChartGroupData(
              x: w.weekNumber,
              barRods: [
                BarChartRodData(
                  toY: w.totalSpent.toDouble(),
                  color: AppColors.primary,
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryDeep,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    formatRupiah(rod.toY.round()),
                    AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  'M${value.toInt()}',
                  style: AppTextStyles.caption.copyWith(color: mutedColor),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
