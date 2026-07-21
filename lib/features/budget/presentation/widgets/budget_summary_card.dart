import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

/// Hero card untuk budget overview.
///
/// Dua state:
/// - [totalSpendable] > 0 → card hijau dengan sisa + pace.
/// - [totalSpendable] <= 0 → card warn dengan breakdown deficit + CTA settings.
///
/// [onSettingsTap] dipanggil oleh CTA pada state over-budget agar caller bisa
/// reload bloc setelah settings disimpan. Jika null, navigasi ke settings
/// tetap berjalan tapi tanpa reload.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.overview,
    this.onSettingsTap,
  });

  final BudgetOverviewEntity overview;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    if (overview.totalSpendable <= 0) {
      return _OverBudgetCard(overview: overview, onSettingsTap: onSettingsTap);
    }
    return _NormalCard(overview: overview);
  }
}

// ── Normal state ──────────────────────────────────────────────────────────────

class _NormalCard extends StatelessWidget {
  const _NormalCard({required this.overview});
  final BudgetOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
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
          // ── Header: label + status ──────────────────────────────────────
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

          // ── Nominal sisa ────────────────────────────────────────────────
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
            'sisa dari ${formatRupiah(overview.totalSpendable)}',
            style: AppTextStyles.bodySmall.copyWith(color: textSoft),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Progress bar ────────────────────────────────────────────────
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

          // ── Pace — tampil bila paceStatus non-null ──────────────────────
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
    // projectedOperationalDays selalu non-null di sini — guard paceStatus != null
    // di call site memastikan ini.
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

// ── Over-budget setup state ───────────────────────────────────────────────────
//
// Aktif saat totalSpendable <= 0, artinya pengeluaran tetap + dana darurat
// sudah menghabiskan seluruh pendapatan. User perlu melihat breakdown
// deficit dan diarahkan ke settings untuk memperbaiki.

class _OverBudgetCard extends StatelessWidget {
  const _OverBudgetCard({required this.overview, this.onSettingsTap});

  final BudgetOverviewEntity overview;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    const textFull = Colors.white;
    final textSoft = Colors.white.withValues(alpha: 0.80);
    final divider = Colors.white.withValues(alpha: 0.20);

    // Selisih sebenarnya sebelum clamp — bisa negatif.
    final rawSpendable =
        overview.monthlyIncome -
        overview.totalFixedExpenses -
        overview.emergencyFundMonthly;
    final deficitAbs = rawSpendable.abs();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.warn,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: label + badge ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ANGGARAN OPERASIONAL',
                style: AppTextStyles.caption.copyWith(color: textSoft),
              ),
              _WarnBadge(label: 'PERLU DIATUR'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Pesan singkat ───────────────────────────────────────────────
          Text(
            'Pengeluaran tetapmu melebihi pendapatan siklus ini.',
            style: AppTextStyles.bodySmall.copyWith(
              color: textFull,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Divider ─────────────────────────────────────────────────────
          Divider(color: divider, height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Breakdown ───────────────────────────────────────────────────
          _BreakdownRow(
            label: 'Pemasukan',
            value: overview.monthlyIncome,
            isNegative: false,
            textColor: textFull,
            mutedColor: textSoft,
          ),
          if (overview.totalFixedExpenses > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _BreakdownRow(
              label: 'Pengeluaran tetap',
              value: overview.totalFixedExpenses,
              isNegative: true,
              textColor: textFull,
              mutedColor: textSoft,
            ),
          ],
          if (overview.emergencyFundMonthly > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _BreakdownRow(
              label: 'Dana darurat',
              value: overview.emergencyFundMonthly,
              isNegative: true,
              textColor: textFull,
              mutedColor: textSoft,
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Divider(color: divider, height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Selisih (total deficit) ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selisih',
                style: AppTextStyles.label.copyWith(
                  color: textFull,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                rawSpendable < 0
                    ? '− ${formatRupiah(deficitAbs)}'
                    : formatRupiah(deficitAbs),
                style: AppTextStyles.numericSm.copyWith(
                  color: textFull,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── CTA ─────────────────────────────────────────────────────────
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap:
                  onSettingsTap ?? () => context.push('/budget/edit-settings'),
              borderRadius: BorderRadius.circular(AppRadius.md),
              splashColor: Colors.white.withValues(alpha: 0.10),
              highlightColor: Colors.white.withValues(alpha: 0.06),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sesuaikan Pengaturan Anggaran',
                      style: AppTextStyles.label.copyWith(color: textFull),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown row ─────────────────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.isNegative,
    required this.textColor,
    required this.mutedColor,
  });

  final String label;
  final int value;
  final bool isNegative;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: mutedColor)),
        Text(
          isNegative ? '− ${formatRupiah(value)}' : formatRupiah(value),
          style: AppTextStyles.numericSm.copyWith(color: textColor),
        ),
      ],
    );
  }
}

// ── Warn badge ────────────────────────────────────────────────────────────────

class _WarnBadge extends StatelessWidget {
  const _WarnBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
// Mirrors _StatusBadge from DaysToLiveCard — reuses l10n keys dan BudgetStatus switch.

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
