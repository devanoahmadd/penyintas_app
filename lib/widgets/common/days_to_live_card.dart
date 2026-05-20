import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

class DaysToLiveCard extends StatelessWidget {
  const DaysToLiveCard({
    super.key,
    required this.daysToLive,
    required this.remainingDays,
    required this.status,
  });

  final int daysToLive;
  final int remainingDays;
  final BudgetStatus status;

  String _safeUntilDate() {
    // #62: clamp agar tidak melampaui akhir siklus; tambah "(est.)" jika DTL > sisa hari
    final safeDays = daysToLive.clamp(0, remainingDays);
    final date = DateTime.now().add(Duration(days: safeDays));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final suffix = daysToLive > remainingDays ? ' (est.)' : '';
    return '${date.day} ${months[date.month - 1]}$suffix';
  }

  double get _dtlRatio =>
      remainingDays > 0
          ? (daysToLive / remainingDays).clamp(0.0, 1.0)
          : 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final cardBg = isDark ? AppColors.primaryDeep : AppColors.primary;
    const textFull = Colors.white;
    final textSoft = Colors.white.withValues(alpha: 0.75);
    final textMuted = Colors.white.withValues(alpha: 0.55);
    final trackColor = Colors.white.withValues(alpha: 0.25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isDark ? Border.all(color: AppColors.shoot, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — label + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.dashboardDtlLabel,
                style: AppTextStyles.caption.copyWith(color: textSoft),
              ),
              _StatusBadge(status: status, l10n: l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Number + "hari"
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$daysToLive',
                style: AppTextStyles.h1.copyWith(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: textFull,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'hari',
                  style: AppTextStyles.h3.copyWith(color: textSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Subtitle
          Text(
            '${l10n.dashboardSafeUntil} ${_safeUntilDate()}',
            style: AppTextStyles.bodySmall.copyWith(color: textSoft),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: _dtlRatio,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(textMuted),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final BudgetStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      BudgetStatus.safe => (
          Icons.eco_outlined,
          l10n.dashboardStatusSafe,
          Colors.white,
        ),
      BudgetStatus.caution => (
          Icons.bolt_outlined,
          l10n.dashboardStatusCaution,
          AppColors.caution,
        ),
      BudgetStatus.danger => (
          Icons.warning_amber_rounded,
          l10n.dashboardStatusDanger,
          AppColors.warn,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
