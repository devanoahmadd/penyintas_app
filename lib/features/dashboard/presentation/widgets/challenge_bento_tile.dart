import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_banner_tile.dart';

/// Tile bento "Tantangan / Mingguan" di dashboard (Task 17).
///
/// Tap → navigasi ke halaman tantangan (`/challenge`) lewat `context.push`
/// (bukan `go`), sama seperti `ConsistencyBentoTile` — dashboard tetap di
/// tumpukan navigasi supaya tombol back berfungsi.
///
/// **S1 — tile TIDAK menghitung keadaannya sendiri.** Ia hanya men-`switch`
/// pada `ChallengeSnapshot.phase` yang SUDAH dirakit `ChallengeBloc` lewat
/// `resolveChallengePhase` (satu-satunya sumber kebenaran, dipakai bersama
/// halaman `/challenge` — lihat dartdoc `ChallengeBloc._rakit`). Kalau tile
/// ini pernah punya cabang yang menghitung ulang dari bahan mentah, itu
/// pelanggaran S1 (dikunci test U97).
///
/// `snapshot == null`, `PhaseUndetermined`, dan `PhasePreparing` merender
/// skeleton — ketiganya keadaan SEMENTARA yang berumur milidetik-ke-detik;
/// memberinya kalimat sendiri berarti menakuti user dengan keadaan internal
/// yang tak bisa ia perbaiki (spec §5).
///
/// **D24 — `bg` SELALU `AppColors.primary`, di SEMUA phase termasuk
/// `PhaseOver`.** Tile bento adalah kartu berwarna penuh dengan teks putih;
/// `warn` (`#E07A3C`) di bawah teks putih cuma 2,99:1 — gagal AA bahkan di
/// ambang teks besar (3,0). Phase `over` dibedakan HANYA lewat kata
/// ("lewat", bukan "sisa"), tidak pernah lewat warna latar. Preseden
/// `dashboard_page.dart:682` yang memakai `bg: AppColors.warn` + teks putih
/// adalah utang lama Survival Mode — TIDAK ditiru di sini (dicatat justru
/// supaya tidak dijadikan pembenaran).
///
/// **Dua phase SENGAJA berkata sama:** `PhaseSettledThisWeek` dan
/// `PhaseOutOfWindow` sama-sama memakai `challenge_tile_window` ("Mulai
/// Senin depan") — dartdoc `challenge_phase.dart:61-62` menyatakan
/// keduanya "berkata sama ke user". Bukan celah, jangan disatukan jadi satu
/// `case` gabungan yang menyembunyikan alasannya.
class ChallengeBentoTile extends StatelessWidget {
  const ChallengeBentoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ChallengeBloc, ChallengeState>(
      builder: (context, state) {
        final phase = state.snapshot?.phase;
        if (phase == null) {
          return const _ChallengeBentoSkeleton();
        }

        final sub = switch (phase) {
          PhaseDisabled() => l10n.challengeTileOff,
          PhaseActive(week: final week, spent: final spent) =>
            l10n.challengeTileActive(
              CategoryMetadata.resolveLabelFromSlug(
                week.category ?? 'other',
                l10n,
              ),
              formatRupiah((week.targetAmount ?? 0) - spent),
            ),
          PhaseOver(week: final week, spent: final spent) =>
            l10n.challengeTileOver(
              CategoryMetadata.resolveLabelFromSlug(
                week.category ?? 'other',
                l10n,
              ),
              formatRupiah(spent - (week.targetAmount ?? 0)),
            ),
          PhaseHeld() => l10n.challengeTileHeld,
          PhaseSettledThisWeek() => l10n.challengeTileWindow,
          PhaseOutOfWindow() => l10n.challengeTileWindow,
          PhaseNotEnoughData() => l10n.challengeTileNoData,
          PhaseBudgetNotSet() => l10n.challengeTileBudget,
          // Keadaan SEMENTARA — lihat dartdoc kelas ini. `null` di sini
          // ditangkap tepat di bawah untuk jatuh ke skeleton, BUKAN
          // dirender sebagai kalimat kosong.
          PhaseUndetermined() => null,
          PhasePreparing() => null,
        };

        if (sub == null) {
          return const _ChallengeBentoSkeleton();
        }

        // Butir 4 — banner horizontal, bukan kartu vertikal: tile ini berdiri
        // sendiri selebar penuh di baris ketujuh grid.
        return BentoBannerTile(
          bg: AppColors.primary,
          icon: Icons.flag_outlined,
          label: l10n.dashboardBentoChallengeLabel,
          sub: sub,
          badge: l10n.dashboardBentoChallengeSub,
          onTap: () => context.push('/challenge'),
        );
      },
    );
  }
}

/// Skeleton ukuran tile bento (bentuk banner sejak butir 4) — dipakai selama belum ada snapshot, atau
/// selagi phase masih `undetermined`/`preparing`. Meniru PERSIS
/// `_ConsistencyBentoSkeleton` (Task 16) — dua tile sama-sama full-color di
/// keadaan siap, jadi skeleton keduanya juga harus konsisten.
class _ChallengeBentoSkeleton extends StatelessWidget {
  const _ChallengeBentoSkeleton();

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

    // Berbentuk BANNER seperti tile siapnya — tinggi sama, jadi dashboard
    // tak melompat saat snapshot tiba.
    return Container(
      key: const Key('challenge-bento-skeleton'),
      constraints: const BoxConstraints(minHeight: kBentoBannerMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          bar(26, 26),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
