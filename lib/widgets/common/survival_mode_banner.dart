import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';

class SurvivalModeBanner extends StatelessWidget {
  const SurvivalModeBanner({
    super.key,
    required this.totalRemaining,
    required this.remainingDays,
    this.onTap,
  });

  final int totalRemaining;
  final int remainingDays;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amountStr = formatCurrency(totalRemaining, CurrencyConfig.idr);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                const Icon(Icons.shield_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.survivalModeTitle,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.survivalModeCopy,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.survivalBannerBalance(amountStr, remainingDays),
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withAlpha(220)),
            ),
            if (onTap != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.survivalTipsLink,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withAlpha(220),
                  letterSpacing: 0,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withAlpha(220),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
