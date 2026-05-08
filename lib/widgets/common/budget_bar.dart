import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.spent,
    required this.total,
  });

  final int spent;
  final int total;

  Color _barColor(double pct) {
    if (pct <= 0.50) return AppColors.primary;
    if (pct <= 0.80) return AppColors.caution;
    return AppColors.warn;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ANGGARAN BULAN INI',
              style: AppTextStyles.caption,
            ),
            Text(
              '${formatRupiah(spent)} / ${formatRupiah(total)}',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: pct),
          builder: (context, value, child) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation(_barColor(value)),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}
