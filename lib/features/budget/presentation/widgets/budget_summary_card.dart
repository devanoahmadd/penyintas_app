import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

/// Hero card for the budget overview — mirrors DaysToLiveCard's structure.
///
/// Displays remaining operational budget + overall status badge.
/// Returns [SizedBox.shrink] if no budget settings have been configured.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.overview});
  final BudgetOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    if (overview.totalSpendable <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final cardBg = isDark ? AppColors.primaryDeep : AppColors.primary;
    const textFull = Colors.white;
    final textSoft = Colors.white.withValues(alpha: 0.75);
    final trackColor = Colors.white.withValues(alpha: 0.18);
    final fillColor = Colors.white.withValues(alpha: 0.90);

    final usagePct = overview.operationalUsagePct;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isDark ? Border.all(color: AppColors.shoot, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + status badge ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ANGGARAN OPERASIONAL',
                style: AppTextStyles.caption.copyWith(color: textSoft),
              ),
              _StatusBadge(status: overview.overallStatus, l10n: l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Big number ─────────────────────────────────────────────────
          Text(
            formatRupiah(overview.operationalRemaining),
            style: AppTextStyles.numericLg.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: textFull,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sisa siklus ini',
            style: AppTextStyles.bodySmall.copyWith(color: textSoft),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Progress bar + usage label ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: usagePct,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(usagePct * 100).round()}% terpakai',
                style: AppTextStyles.caption.copyWith(
                  color: textSoft,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),

          // ── Pace projection — tampil bila paceStatus non-null (ada data & siklus belum habis) ─────
          if (overview.paceStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatRupiah(overview.dailyBurnRate.round())}/hari',
                  style: AppTextStyles.caption.copyWith(
                    color: textSoft,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  _paceLabel(overview),
                  style: AppTextStyles.caption.copyWith(
                    color: _paceColor(overview.paceStatus),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _paceLabel(BudgetOverviewEntity overview) {
    // projectedOperationalDays selalu non-null di sini — guard dailyBurnRate > 0
    // di call site memastikan ini (#F2-6).
    final projected = overview.projectedOperationalDays!;
    if (overview.paceStatus == BudgetStatus.safe) {
      return 'Cukup sampai akhir siklus';
    }
    final clamped = projected.clamp(0, overview.remainingDays);
    return 'Habis ~$clamped hari lagi';
  }

  Color _paceColor(BudgetStatus? status) => switch (status) {
        BudgetStatus.safe => Colors.white.withValues(alpha: 0.75),
        BudgetStatus.caution => AppColors.caution,
        BudgetStatus.danger => AppColors.warn,
        _ => Colors.white.withValues(alpha: 0.75),
      };
}

// ── Status badge ────────────────────────────────────────────────────────────
// Mirrors _StatusBadge from DaysToLiveCard — reuses the same l10n keys
// and BudgetStatus switch.

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
        AppColors.shoot,
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
          Icon(icon, size: 14, color: color),
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
