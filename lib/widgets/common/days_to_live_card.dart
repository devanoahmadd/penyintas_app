import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

class DaysToLiveCard extends StatelessWidget {
  const DaysToLiveCard({super.key, required this.daysToLive});

  final int daysToLive;

  Color _dtlColor(bool isDark) {
    if (daysToLive > 14) return isDark ? AppColors.textDark : Colors.white;
    if (daysToLive >= 7) return AppColors.caution;
    return AppColors.warn;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isDark
            ? Border.all(color: AppColors.shoot, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAYS TO LIVE',
            style: AppTextStyles.caption.copyWith(
              color: isDark
                  ? AppColors.shoot
                  : Colors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$daysToLive',
            style: AppTextStyles.h1.copyWith(
              fontFamily: 'JetBrainsMono',
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: _dtlColor(isDark),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Prediksi berdasarkan pola belanjamu',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSoftDark
                  : Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
