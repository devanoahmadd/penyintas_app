import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

/// Shimmer skeleton for [BudgetOverviewPage] while data loads.
///
/// Mirrors the real layout 1:1 — hero card, allocation ring, section header,
/// and three limit-card placeholders.
/// Pattern matches [DashboardSkeleton] (shimmer package + _ShimmerBox).
class BudgetOverviewSkeleton extends StatelessWidget {
  const BudgetOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF1C3526) : AppColors.cardLight;
    final highlightColor =
        isDark ? const Color(0xFF2E5040) : AppColors.bgLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          // Hero summary card ~150dp
          _SkeletonHero(),
          SizedBox(height: AppSpacing.xl),

          // Allocation ring ~300dp
          _SkeletonRing(),
          SizedBox(height: AppSpacing.xl),

          // Section header
          _SkeletonSectionHeader(),
          SizedBox(height: AppSpacing.md),

          // 3 limit card placeholders
          _SkeletonLimitCard(),
          SizedBox(height: AppSpacing.md),
          _SkeletonLimitCard(),
          SizedBox(height: AppSpacing.md),
          _SkeletonLimitCard(),
        ],
      ),
    );
  }
}

// ── Primitive ────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardLight, // shimmer gradient paints over this
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Hero summary card ────────────────────────────────────────────────────────
// Mirrors BudgetSummaryCard ~150dp

class _SkeletonHero extends StatelessWidget {
  const _SkeletonHero();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 150, radius: AppRadius.lg);
  }
}

// ── Allocation ring card ──────────────────────────────────────────────────────
// Mirrors BudgetAllocationRing: title + donut + legend ~300dp

class _SkeletonRing extends StatelessWidget {
  const _SkeletonRing();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 300, radius: AppRadius.lg);
  }
}

// ── Section header ────────────────────────────────────────────────────────────
// Mirrors "BATAS PER KATEGORI" caption line

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(width: 160, height: 16);
  }
}

// ── Limit card ────────────────────────────────────────────────────────────────
// Mirrors BudgetLimitCard: header + progress bar + footer ~92dp

class _SkeletonLimitCard extends StatelessWidget {
  const _SkeletonLimitCard();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 92, radius: AppRadius.md);
  }
}
