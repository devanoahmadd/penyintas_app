import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.breakdown});

  final Map<String, int> breakdown;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breakdown != widget.breakdown) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    if (widget.breakdown.isEmpty) {
      return Center(
        child: Text(
          'Belum ada pengeluaran bulan ini.',
          style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
        ),
      );
    }

    final entries = widget.breakdown.entries.toList();
    final total = entries.fold(0, (s, e) => s + e.value);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
              ),
              sections: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final isTouched = idx == _touchedIndex;
                final (_, color) = CategoryMetadata.of(e.key);
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: color,
                  radius: isTouched ? 70 : 60,
                  showTitle: isTouched,
                  title: isTouched ? '${e.key}\n${formatRupiah(e.value)}' : '',
                  titleStyle: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: entries.map((e) {
            final pct = total > 0 ? (e.value / total * 100).round() : 0;
            final (_, color) = CategoryMetadata.of(e.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${e.key} $pct% (${formatRupiah(e.value)})',
                  style: AppTextStyles.caption.copyWith(color: textColor),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
