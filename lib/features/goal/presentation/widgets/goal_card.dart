import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_config.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.onTap});

  final GoalEntity goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final savedFmt = formatCurrencyCompact(
      goal.savedAmount,
      CurrencyConfig.idr,
    );
    final targetFmt = formatCurrencyCompact(
      goal.targetAmount,
      CurrencyConfig.idr,
    );
    final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(goal.targetDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: AppTextStyles.h3.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(goal: goal, isDark: isDark),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Target date
            Text(
              context.l10n.goalTargetDate(dateStr),
              style: AppTextStyles.caption.copyWith(
                color: mutedColor,
                letterSpacing: 0,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress bar
            _GoalProgressBar(percent: goal.progressPercent),
            const SizedBox(height: AppSpacing.sm),
            // Progress label: Rp X dari Rp Y
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.goalProgressLabel(savedFmt, targetFmt),
                  style: AppTextStyles.caption.copyWith(
                    color: mutedColor,
                    letterSpacing: 0,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: _progressColor(goal.progressPercent),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double pct) {
    if (pct >= 1.0) return AppColors.success;
    if (pct >= 0.5) return AppColors.primaryBright;
    return AppColors.caution;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.goal, required this.isDark});
  final GoalEntity goal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (goal.isCompleted) {
      return _Chip(label: context.l10n.goalCompleted, color: AppColors.success);
    }
    if (goal.isOverdue) {
      return _Chip(label: context.l10n.goalOverdue, color: AppColors.warn);
    }
    return const SizedBox.shrink();
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({required this.percent});
  final double percent;

  Color _barColor(double p) {
    if (p >= 1.0) return AppColors.success;
    if (p >= 0.5) return AppColors.primaryBright;
    return AppColors.caution;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: percent),
      builder: (_, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation(_barColor(value)),
          minHeight: 8,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
