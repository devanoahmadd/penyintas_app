import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

class SurvivalModeBanner extends StatelessWidget {
  const SurvivalModeBanner({
    super.key,
    required this.totalRemaining,
    required this.remainingDays,
  });

  final int totalRemaining;
  final int remainingDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warn,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Mode Hemat Aktif',
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lentur dulu. Kita lewati minggu ini bersama.',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sisa ${formatRupiah(totalRemaining)} untuk $remainingDays hari. Kamu bisa.',
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withAlpha(220)),
          ),
        ],
      ),
    );
  }
}
