// lib/features/dashboard/presentation/widgets/financial_slider_widget.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

// ── Data model ───────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.label,
    required this.valueText,
    this.unitText,
    required this.subtitle,
    required this.progress,
    required this.backgroundColor,
    required this.status,
    this.onTap,
  });

  final String label;
  final String valueText;   // pre-formatted (formatRupiah / "$n")
  final String? unitText;   // "hari" for DTL, null for others
  final String subtitle;
  final double progress;    // 0.0–1.0
  final Color backgroundColor;
  final BudgetStatus status;
  final VoidCallback? onTap;

  // dot color matches the slide background
  Color get dotColor => backgroundColor;
}

// ── Module-level helpers ──────────────────────────────────────────────────────

Color _statusColor(BudgetStatus status) => switch (status) {
      BudgetStatus.safe => AppColors.primary,
      BudgetStatus.caution => AppColors.caution,
      BudgetStatus.danger => AppColors.warn,
    };

BudgetStatus _pctToStatus(double pct) {
  if (pct <= 0.50) return BudgetStatus.safe;
  if (pct <= 0.80) return BudgetStatus.caution;
  return BudgetStatus.danger;
}

String _safeUntilDate(int daysToLive, int remainingDays) {
  // mirror of DaysToLiveCard._safeUntilDate — clamp so we never exceed cycle end
  final safeDays = daysToLive.clamp(0, remainingDays);
  final date = DateTime.now().add(Duration(days: safeDays));
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final suffix = daysToLive > remainingDays ? ' (est.)' : '';
  return '${date.day} ${months[date.month - 1]}$suffix';
}

String _deltaLabel(AppLocalizations l10n, BudgetStatus status) => switch (status) {
      BudgetStatus.safe => l10n.dashboardDeltaOnTrack,
      BudgetStatus.caution => l10n.dashboardDeltaNearing,
      BudgetStatus.danger => l10n.dashboardDeltaExceeded,
    };

// ── Stub widget (replaced in Task 3) ─────────────────────────────────────────

class FinancialSliderWidget extends StatelessWidget {
  const FinancialSliderWidget({super.key, required this.entity});
  final DashboardEntity entity;

  @override
  Widget build(BuildContext context) => const SizedBox(height: 190);
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _SlideBadge extends StatelessWidget {
  const _SlideBadge({required this.status, required this.l10n});
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
        Colors.white,
      ),
      BudgetStatus.danger => (
        Icons.warning_amber_rounded,
        l10n.dashboardStatusDanger,
        Colors.white,
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

// ── Card ──────────────────────────────────────────────────────────────────────

class _FinancialSlideCard extends StatelessWidget {
  const _FinancialSlideCard({
    required this.data,
    required this.isActive,
    required this.index, // 0=DTL, 1=Spending, 2=Emergency — drives blob/logo position
  });

  final _SlideData data;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        height: 152,
        decoration: BoxDecoration(
          color: data.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: data.backgroundColor.withValues(alpha: 0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: data.backgroundColor.withValues(alpha: 0.18),
                    blurRadius: 44,
                    offset: const Offset(0, 20),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              _buildBlob(),
              _buildLogoWm(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg2,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: label + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          data.label,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        ),
                        _SlideBadge(status: data.status, l10n: l10n),
                      ],
                    ),
                    const Spacer(),
                    // Number + optional unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            data.valueText,
                            style: data.unitText != null
                                ? AppTextStyles.numericLg.copyWith(
                                    fontSize: 52,
                                    height: 1.0,
                                    color: Colors.white,
                                  )
                                : AppTextStyles.numericMd.copyWith(
                                    height: 1.0,
                                    color: Colors.white,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.unitText != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              data.unitText!,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Subtitle
                    Text(
                      data.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: data.progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.82),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlob() {
    // Each card places its blob in a different corner for visual differentiation
    final (top, right, bottom, left, size) = switch (index) {
      0 => (-55.0, -35.0, null, null, 160.0),  // DTL: top-right
      1 => (null, -32.0, -50.0, null, 148.0),  // Spending: bottom-right
      _ => (-52.0, null, null, -32.0, 150.0),  // Emergency: top-left
    };
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.11),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWm() {
    // Each card has a unique logo crop position, size, and opacity
    final (top, right, bottom, left, size, opacity) = switch (index) {
      0 => (-10.0, -18.0, null, null, 130.0, 0.08),  // DTL: top-right crop, 8%
      1 => (null, null, -20.0, -16.0, 132.0, 0.09),  // Spending: bottom-left crop, 9%
      _ => (null, -30.0, -28.0, null, 175.0, 0.07),  // Emergency: bottom-right XL, 7%
    };
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Opacity(
        opacity: opacity,
        child: SvgPicture.asset(
          'assets/images/logo-m7.svg',
          width: size,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
