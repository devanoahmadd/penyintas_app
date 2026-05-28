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
