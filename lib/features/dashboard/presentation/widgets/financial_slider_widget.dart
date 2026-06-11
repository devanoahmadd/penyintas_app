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
import 'package:penyintas_app/features/budget/domain/entities/budget_overview_entity.dart';
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

// ── Public widget ─────────────────────────────────────────────────────────────

class FinancialSliderWidget extends StatefulWidget {
  const FinancialSliderWidget({
    super.key,
    required this.entity,
    this.budgetOverview,
  });
  final DashboardEntity entity;
  final BudgetOverviewEntity? budgetOverview; // null = loading placeholder

  @override
  State<FinancialSliderWidget> createState() => _FinancialSliderWidgetState();
}

class _FinancialSliderWidgetState extends State<FinancialSliderWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % 4; // 4 slides: DTL, Spending, Budget, Emergency
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 440),
        curve: const Cubic(0.32, 0.72, 0, 1),
      );
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 6), _startAutoPlay);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  List<_SlideData> _buildSlides(DashboardEntity entity) {
    final l10n = context.l10n;

    // DTL
    final dtlProg = entity.remainingDays > 0
        ? (entity.daysToLive / entity.remainingDays).clamp(0.0, 1.0)
        : 0.0;

    // Spending
    final spendPct = entity.totalMonthlyBudget > 0
        ? (entity.totalSpentThisMonth / entity.totalMonthlyBudget)
            .clamp(0.0, 1.0)
        : 0.0;
    final spendStatus = _pctToStatus(spendPct);
    final spendPctInt = (spendPct * 100).round();

    // Emergency
    final emergTotal =
        entity.totalMonthlyBudget + entity.emergencyFundMonthly;
    final emergPct = emergTotal > 0
        ? (entity.emergencyFundMonthly / emergTotal).clamp(0.0, 1.0)
        : 0.0;
    final emergPctInt = (emergPct * 100).round();

    // Budget
    final budget = widget.budgetOverview;
    final budgetPct = (budget != null && budget.totalLimitSet > 0)
        ? (budget.totalSpentInLimited / budget.totalLimitSet).clamp(0.0, 1.0)
        : 0.0;
    final budgetStatus = _pctToStatus(budgetPct);
    final budgetRemaining = budget != null
        ? (budget.totalLimitSet - budget.totalSpentInLimited)
            .clamp(0, budget.totalLimitSet)
        : 0;

    return [
      _SlideData(
        label: l10n.dashboardDtlLabel,
        valueText: '${entity.daysToLive}',
        unitText: 'hari',
        subtitle:
            '${l10n.dashboardSafeUntil} ${_safeUntilDate(entity.daysToLive, entity.remainingDays)}',
        progress: dtlProg,
        backgroundColor: _statusColor(entity.status),
        status: entity.status,
        onTap: () => context.push('/dtl'),
      ),
      _SlideData(
        label: l10n.dashboardSpendingLabel,
        valueText: formatRupiah(entity.totalSpentThisMonth),
        subtitle:
            '${l10n.dashboardPctOfBudget(spendPctInt)} · ${_deltaLabel(l10n, spendStatus)}',
        progress: spendPct,
        backgroundColor: _statusColor(spendStatus),
        status: spendStatus,
        // /transactions is a bottom-nav tab → go() (replaces stack).
        // /dtl and /emergency are detail screens → push() (preserves back stack).
        onTap: () => context.go('/transactions'),
      ),
      _SlideData(
        label: 'ANGGARAN KATEGORI',
        valueText: (budget == null || budget.totalLimitSet == 0)
            ? '—'
            : formatRupiah(budgetRemaining),
        subtitle: budget == null
            ? 'Memuat...'
            : budget.totalLimitSet == 0
                ? 'Belum ada batas kategori'
                : '${(budgetPct * 100).round()}% terpakai siklus ini',
        progress: budgetPct,
        backgroundColor: (budget == null || budget.totalLimitSet == 0)
            ? AppColors.primaryDeep
            : _statusColor(budgetStatus),
        status: (budget == null || budget.totalLimitSet == 0)
            ? BudgetStatus.safe
            : budgetStatus,
        onTap: () => context.go('/budget'),
      ),
      _SlideData(
        label: l10n.dashboardEmergencyLabel,
        valueText: formatRupiah(entity.emergencyFundMonthly),
        subtitle: l10n.dashboardPctOfTotal(emergPctInt),
        progress: emergPct,
        backgroundColor: AppColors.primaryDeep,
        status: BudgetStatus.safe,
        onTap: () => context.push('/emergency'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slides = _buildSlides(widget.entity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 152,
          child: GestureDetector(
            onPanDown: (_) => _pauseAutoPlay(),
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              itemCount: slides.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) {
                final isActive = i == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedScale(
                      scale: isActive ? 1.0 : 0.955,
                      duration: const Duration(milliseconds: 300),
                      child: _FinancialSlideCard(
                        data: slides[i],
                        isActive: isActive,
                        index: i,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              width: isActive ? AppSpacing.lg2 : AppSpacing.sm,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: isActive
                    ? slides[i].dotColor
                    : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
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
    required this.index, // 0=DTL, 1=Spending, 2=Budget, 3=Emergency — drives blob/logo position
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
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      2 => (-52.0, null, null, -32.0, 150.0),  // Emergency: top-left
      _ => (null, null, -50.0, -35.0, 142.0),  // Budget: bottom-left
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
      2 => (null, -30.0, -28.0, null, 175.0, 0.07),  // Emergency: bottom-right XL, 7%
      _ => (-12.0, null, null, -20.0, 128.0, 0.08),  // Budget: top-left crop, 8%
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
