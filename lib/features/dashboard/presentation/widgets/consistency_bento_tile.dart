import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_feat_tile.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';

/// Tile bento "Konsistensi" di dashboard (Task 16).
///
/// Tap → navigasi ke halaman konsistensi (`/consistency`) lewat
/// `context.push` (bukan `go`) supaya tombol back kembali ke dashboard.
///
/// Angka streak SELALU data nyata dari `StreakBloc` — tidak pernah "0 hari"
/// palsu. Tile adalah tempat angka salah paling mudah dipercaya user, karena
/// ia dilihat sekilas tanpa konteks:
/// - `restoring`/`initial`/`loading` → skeleton (belum tahu apa-apa, jangan
///   tebak angka).
/// - `failure` → sub-teks netral yang sama dengan ajakan mulai (gagal baca
///   BUKAN alasan menuduh user "0 hari").
/// - `ready` & `hasStarted == false` → ajakan "Mulai hari ini", BUKAN
///   "0 hari" (pengguna belum pernah mulai, bukan gagal mempertahankan 0
///   hari).
/// - `ready` & `hasStarted == true` → "{streak} hari berturut".
///
/// Tiga cabang non-angka di atas SENGAJA independen satu sama lain (bukan
/// digabung jadi satu kondisi "else" bersama) — masing-masing punya sabotase
/// & test sendiri, mengikuti pola `_ReadyBody._hideCta` di
/// `consistency_page.dart`.
class ConsistencyBentoTile extends StatelessWidget {
  const ConsistencyBentoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<StreakBloc, StreakState>(
      builder: (context, state) {
        final isRestoring =
            state.status == StreakStatus.restoring ||
            state.status == StreakStatus.initial ||
            state.status == StreakStatus.loading;
        if (isRestoring) {
          return const _ConsistencyBentoSkeleton();
        }

        final String badge;
        if (state.status == StreakStatus.failure) {
          badge = l10n.dashboardBentoConsistencyStart;
        } else {
          final snapshot = state.snapshot;
          if (snapshot != null && snapshot.hasStarted) {
            badge = l10n.dashboardBentoConsistencyDays(snapshot.currentStreak);
          } else {
            badge = l10n.dashboardBentoConsistencyStart;
          }
        }

        return BentoFeatTile(
          bg: AppColors.primary,
          icon: Icons.calendar_month_outlined,
          label: l10n.dashboardBentoConsistencyLabel,
          sub: l10n.dashboardBentoConsistencySub,
          badge: badge,
          onTap: () => context.push('/consistency'),
        );
      },
    );
  }
}

/// Skeleton ukuran tile bento — dipakai selama status `restoring`/
/// `initial`/`loading`, sebelum ada satu pun snapshot untuk dirender.
class _ConsistencyBentoSkeleton extends StatelessWidget {
  const _ConsistencyBentoSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final skeletonColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    return Container(
      key: const Key('consistency-bento-skeleton'),
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(AppSpacing.md2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          bar(26, 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(80, 16),
              const SizedBox(height: AppSpacing.xs),
              bar(56, 12),
            ],
          ),
        ],
      ),
    );
  }
}
