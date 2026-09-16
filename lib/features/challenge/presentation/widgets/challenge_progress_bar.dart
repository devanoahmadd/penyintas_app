import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

/// Tiga keadaan ambang tantangan minggu ini, dari proporsi `spent`/`target`.
///
/// Dipakai BERSAMA oleh isi bar ([ChallengeProgressBar]) dan baris kata+ikon
/// di kartu (`ActiveChallengeCard`) — supaya keduanya tidak pernah berselisih
/// pendapat soal keadaan mana yang sedang aktif (spec §7).
enum ChallengeBarState { safe, caution, over }

/// ≤50% aman · 50–80% mendekati · >80% lewat. Dihitung dari rasio MENTAH
/// (boleh > 1.0 saat sudah lewat target) — hanya lebar bar yang di-clamp
/// untuk digambar, bukan rasio yang menentukan keadaan.
ChallengeBarState challengeBarStateFor(double pct) {
  if (pct <= 0.50) return ChallengeBarState.safe;
  if (pct <= 0.80) return ChallengeBarState.caution;
  return ChallengeBarState.over;
}

/// Warna isi bar per ambang (spec §7).
///
/// Ambang aman di tema GELAP wajib `primaryBright`, bukan `primary` —
/// `primary`/`surfaceDark` cuma 2,63:1 (gagal 3:1), `primaryBright` lolos di
/// 4,32:1. `caution` dan `over` sama di kedua tema (warna fungsional).
Color challengeBarFillColor(ChallengeBarState state, bool isDark) {
  return switch (state) {
    ChallengeBarState.safe =>
      isDark ? AppColors.primaryBright : AppColors.primary,
    ChallengeBarState.caution => AppColors.caution,
    ChallengeBarState.over => AppColors.warn,
  };
}

/// Bar progres tantangan mingguan (aktif / lewat target).
///
/// Track diberi outline 1px `muted*` — bukan sekadar warna `surface*` — sebab
/// kontras track vs kartu sendiri cuma ~1,1:1, nyaris tak kelihatan tanpa
/// garis tepi. `muted*` lolos ambang 3:1 untuk elemen non-teks (spec §7).
///
/// Menghormati `MediaQuery.disableAnimations`: saat aktif, lebar isi langsung
/// ke nilai akhir tanpa animasi antara.
class ChallengeProgressBar extends StatelessWidget {
  const ChallengeProgressBar({
    super.key,
    required this.spent,
    required this.target,
    required this.isDark,
  });

  final int spent;
  final int target;
  final bool isDark;

  double get _rawPct => target > 0 ? spent / target : 0.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rawPct = _rawPct;
    final clampedPct = rawPct.clamp(0.0, 1.0);
    final state = challengeBarStateFor(rawPct);
    final fillColor = challengeBarFillColor(state, isDark);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final persen = (clampedPct * 100).round();

    return Semantics(
      value: l10n.challengeBarSemantics(persen),
      child: Container(
        key: const Key('challenge-bar-track'),
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              widthFactor: clampedPct,
              child: Container(
                key: const Key('challenge-bar-fill'),
                decoration: BoxDecoration(color: fillColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
