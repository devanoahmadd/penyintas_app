import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1C3526) : AppColors.cardLight;
    final highlightColor = isDark ? const Color(0xFF2E5040) : AppColors.bgLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SafeArea(
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _SkeletonHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SkeletonDtlCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const _SkeletonSaldoCard(),
                  const SizedBox(height: AppSpacing.md2),
                  const _SkeletonRingRow(),
                  const SizedBox(height: AppSpacing.xxl),
                  const _SkeletonSectionHeader(),
                  const SizedBox(height: AppSpacing.md),
                  const _SkeletonBentoGrid(),
                  const SizedBox(height: AppSpacing.lg),
                  const _SkeletonTipCard(),
                  const SizedBox(height: AppSpacing.xl),
                  const _SkeletonSectionHeader(),
                  const SizedBox(height: AppSpacing.md),
                  const _SkeletonTxCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Primitive ─────────────────────────────────────────────────────────────
// Shimmer.fromColors melukis gradient di atas children via BlendMode.srcATop.
// Children hanya perlu opaque — warna aslinya tidak terlihat, digantikan gradient.

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
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────
// Mirrors _DashboardHeader: avatar circle + 2 text lines + bell circle

class _SkeletonHeader extends StatelessWidget {
  const _SkeletonHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg2,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          _ShimmerBox(width: 44, height: 44, radius: AppRadius.pill),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 72, height: 12),
                SizedBox(height: AppSpacing.xs),
                _ShimmerBox(width: 130, height: 18),
              ],
            ),
          ),
          _ShimmerBox(width: 44, height: 44, radius: AppRadius.pill),
        ],
      ),
    );
  }
}

// ── DTL Card ──────────────────────────────────────────────────────────────
// Mirrors DaysToLiveCard: satu blok penuh ~140dp

class _SkeletonDtlCard extends StatelessWidget {
  const _SkeletonDtlCard();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 148, radius: AppRadius.lg);
  }
}

// ── Saldo Card ────────────────────────────────────────────────────────────
// Mirrors _SaldoCard: label + balance + timestamp ≈ 100dp

class _SkeletonSaldoCard extends StatelessWidget {
  const _SkeletonSaldoCard();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 130, radius: AppRadius.lg);
  }
}

// ── Ring Row ──────────────────────────────────────────────────────────────
// Mirrors 2× _RingWidget side by side

class _SkeletonRingRow extends StatelessWidget {
  const _SkeletonRingRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _ShimmerBox(height: 120, radius: AppRadius.md)),
        SizedBox(width: AppSpacing.sm2),
        Expanded(child: _ShimmerBox(height: 120, radius: AppRadius.md)),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
// Mirrors _SectionHeader: judul kiri + action kanan

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShimmerBox(width: 140, height: 18),
        _ShimmerBox(width: 56, height: 14),
      ],
    );
  }
}

// ── Bento Grid ────────────────────────────────────────────────────────────
// Mirrors _BentoGrid: 1 featured row (116dp) + 2 quick rows (60dp each)

class _SkeletonBentoGrid extends StatelessWidget {
  const _SkeletonBentoGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 116, radius: AppRadius.md)),
            SizedBox(width: AppSpacing.sm2),
            Expanded(child: _ShimmerBox(height: 116, radius: AppRadius.md)),
          ],
        ),
        SizedBox(height: AppSpacing.sm2),
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 60, radius: AppRadius.md)),
            SizedBox(width: AppSpacing.sm2),
            Expanded(child: _ShimmerBox(height: 60, radius: AppRadius.md)),
          ],
        ),
        SizedBox(height: AppSpacing.sm2),
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 60, radius: AppRadius.md)),
            SizedBox(width: AppSpacing.sm2),
            Expanded(child: _ShimmerBox(height: 60, radius: AppRadius.md)),
          ],
        ),
      ],
    );
  }
}

// ── Tip Card ──────────────────────────────────────────────────────────────
// Mirrors _TipCard: icon + teks ~48dp

class _SkeletonTipCard extends StatelessWidget {
  const _SkeletonTipCard();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 48, radius: AppRadius.md);
  }
}

// ── TX Card ───────────────────────────────────────────────────────────────
// Mirrors _TxCard dengan 3 baris — 3 × ~68dp ≈ 208dp

class _SkeletonTxCard extends StatelessWidget {
  const _SkeletonTxCard();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 208, radius: AppRadius.md);
  }
}
