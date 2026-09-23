import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:shimmer/shimmer.dart';

/// Enam keadaan "tak ada apa-apa untuk ditunjukkan" tantangan mingguan,
/// dirakit dari [ChallengePhase] (Task 5).
///
/// SENGAJA mem-`switch` [ChallengePhase] TANPA `default` — sama seperti
/// `resolveChallengePhase` (Task 5): phase baru yang lahir tanpa
/// tampilannya ditulis membuat berkas ini GAGAL KOMPILASI, bukan diam-diam
/// merender kosong.
///
/// [PhaseActive]/[PhaseOver] BUKAN tanggung jawab kartu ini — keduanya
/// dirender `ActiveChallengeCard` (Task 14). Keduanya tetap harus disebut
/// di `switch` ini (exhaustiveness compiler), tapi melempar `ArgumentError`
/// kalau benar-benar diterima — kesalahan pemanggilan gagal SEGERA, bukan
/// menampilkan kartu kosong yang membingungkan di atas tantangan yang
/// sebenarnya sedang berjalan.
///
/// **Lima dari enam keadaan SENGAJA tanpa tombol**
/// (`notEnoughData`, `outOfWindow`, `settledThisWeek`, `held`,
/// `budgetNotSet` — skeleton `undetermined`/`preparing` juga tanpa tombol,
/// jadi total tujuh dari delapan): tombol yang tidak mengerjakan apa pun
/// ("Muat ulang", "Pelajari lagi") adalah slop yang paling sering lolos
/// review karena terlihat seperti kepedulian. Satu-satunya keadaan dengan
/// tombol adalah `disabled`, karena itu satu-satunya keadaan dengan AKSI
/// nyata yang bisa dikerjakan user lewat kartu ini: menyalakan sakelar.
///
/// Tinggi minimum 120dp di SEMUA keadaan — supaya halaman tidak berubah
/// tinggi drastis saat phase berganti.
///
/// Memakai `cardLight`/`cardDark` (BUKAN `surface*`) — kartu ini permukaan
/// PERMANEN (satu-satunya elevasi di slot tantangan), beda dari
/// `ChallengeResultCard` yang banner sementara di atasnya. Judul memakai
/// `text*` (textLight/cardLight = 15,13:1, textDark/cardDark = 11,32:1),
/// deskripsi & ikon memakai `textSoft*` (textSoftLight/cardLight = 11,82:1,
/// textSoftDark/cardDark = 8,38:1) — keduanya lolos AA di kedua tema, dan
/// TIDAK PERNAH warna fungsional (`caution`/`warn`/`primaryBright`/
/// `success`) dipakai untuk teks atau ikon di atas kartu ini.
class ChallengeEmptyCard extends StatelessWidget {
  const ChallengeEmptyCard({super.key, required this.phase, this.onEnable});

  final ChallengePhase phase;

  /// Hanya dipakai [PhaseDisabled]. Diabaikan di keadaan lain — lima
  /// keadaan sisanya sengaja tanpa tombol.
  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return switch (phase) {
      PhaseDisabled() => _EmptyShell(
        icon: Icons.eco_outlined,
        title: l10n.challengeEmptyDisabledTitle,
        body: l10n.challengeEmptyDisabledBody,
        button: _EnableButton(l10n: l10n, onEnable: onEnable),
      ),
      PhaseActive() || PhaseOver() => throw ArgumentError(
        'ChallengeEmptyCard tidak menerima PhaseActive/PhaseOver — '
        'keduanya milik ActiveChallengeCard (Task 14).',
      ),
      PhaseHeld() => _EmptyShell(
        icon: Icons.pause_circle_outlined,
        title: l10n.challengeEmptyHeldTitle,
        body: l10n.challengeEmptyHeldBody,
      ),
      PhaseSettledThisWeek() => _EmptyShell(
        icon: Icons.flag_circle_outlined,
        title: l10n.challengeEmptySettledTitle,
        body: l10n.challengeEmptySettledBody,
      ),
      PhaseOutOfWindow(isFirstWeek: final isFirstWeek) => _EmptyShell(
        icon: Icons.schedule_outlined,
        title: isFirstWeek
            ? l10n.challengeEmptyOutOfWindowFirstTitle
            : l10n.challengeEmptyOutOfWindowTitle,
        body: isFirstWeek
            ? l10n.challengeEmptyOutOfWindowFirstBody
            : l10n.challengeEmptyOutOfWindowBody,
      ),
      PhaseNotEnoughData() => _EmptyShell(
        icon: Icons.bar_chart_outlined,
        title: l10n.challengeEmptyNotEnoughDataTitle,
        body: l10n.challengeEmptyNotEnoughDataBody,
      ),
      PhaseBudgetNotSet() => _EmptyShell(
        icon: Icons.tune_outlined,
        title: l10n.challengeEmptyBudgetNotSetTitle,
        body: l10n.challengeEmptyBudgetNotSetBody,
      ),
      PhaseUndetermined() || PhasePreparing() => const _SkeletonShell(),
    };
  }
}

// ── Kerangka bersama lima keadaan bertitel+body ─────────────────────────────

class _EmptyShell extends StatelessWidget {
  const _EmptyShell({
    required this.icon,
    required this.title,
    required this.body,
    this.button,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;

    return Container(
      key: const Key('challenge-empty-card'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: '$title $body',
            container: true,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      key: const Key('challenge-empty-icon'),
                      size: 20,
                      color: textSoftColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        key: const Key('challenge-empty-title'),
                        style: AppTextStyles.h3.copyWith(color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  key: const Key('challenge-empty-body'),
                  style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
              ],
            ),
          ),
          if (button != null) ...[
            const SizedBox(height: AppSpacing.lg),
            button!,
          ],
        ],
      ),
    );
  }
}

// ── Tombol "Nyalakan" — satu-satunya tombol di antara enam keadaan ─────────

class _EnableButton extends StatelessWidget {
  const _EnableButton({required this.l10n, required this.onEnable});

  final AppLocalizations l10n;
  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('challenge-empty-enable-button'),
        onPressed: onEnable,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Text(
          l10n.challengeEmptyEnableButton,
          style: AppTextStyles.label.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// ── Skeleton — undetermined/preparing, keadaan SEMENTARA (bukan terminal) ──

class _SkeletonShell extends StatelessWidget {
  const _SkeletonShell();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final baseColor = isDark ? const Color(0xFF1C3526) : AppColors.cardLight;
    final highlightColor = isDark ? const Color(0xFF2E5040) : AppColors.bgLight;

    return Semantics(
      label: l10n.loading,
      child: Container(
        key: const Key('challenge-empty-card-skeleton'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _shimmerBar(cardBg, width: 140, height: 16),
              const SizedBox(height: AppSpacing.md),
              _shimmerBar(cardBg, width: double.infinity, height: 12),
              const SizedBox(height: AppSpacing.sm),
              _shimmerBar(cardBg, width: 180, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBar(
    Color color, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
