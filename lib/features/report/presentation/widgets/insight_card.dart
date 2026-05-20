import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.isLoading,
    required this.insights,
    this.savingTip,
  });

  final bool isLoading;
  final List<String>? insights;
  final String? savingTip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSIGHT AI',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading) ..._skeleton(isDark),
          if (!isLoading && insights != null)
            ...insights!.map((insight) => _bulletRow(insight, textColor)),
          if (!isLoading && insights == null)
            Text(
              'Analisis belum tersedia.',
              style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
            ),
          if (!isLoading && savingTip != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      savingTip!,
                      style:
                          AppTextStyles.bodySmall.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _skeleton(bool isDark) {
    final skeletonColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return List.generate(
      3,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }

  Widget _bulletRow(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
