import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';

/// Banner SEKALI-TAMPIL untuk hasil minggu tantangan yang belum dilihat user
/// (spec §7.6/§7.7).
///
/// BUKAN phase (lihat `ChallengePhase`, Task 5) — ia lapisan terpisah yang
/// dirender DI ATAS phase apa pun, termasuk `disabled` dan `held`. Karena
/// itu widget ini TIDAK PERNAH boleh masuk ke dalam `switch` milik
/// `ChallengeEmptyCard`: kalau keduanya digabung, irisan "sakelar mati +
/// hasil belum dilihat" butuh aturan tambahan yang justru ingin dihindari
/// desain ini (U82).
///
/// Memakai `surfaceLight`/`surfaceDark` — BUKAN `card*` — karena ia banner
/// SEMENTARA, bukan permukaan permanen. `ChallengeEmptyCard`/
/// `ActiveChallengeCard` tetap satu-satunya elevasi `card*` di slot
/// tantangan. SELURUH teks & ikon di sini memakai `textSoft*` (bukan
/// `text*`) — konsisten dengan sifat "banner ringan, bisa ditutup", dan
/// kontrasnya sudah dihitung: `textSoftLight`/`surfaceLight` = 10,38:1,
/// `textSoftDark`/`surfaceDark` = 9,01:1 (lolos AA di kedua tema).
///
/// `rangeLabel` (Task 16, `challenge_week_range.dart`) dan `line`
/// (Task 18, `challengeBankLine`) BELUM PUNYA penyuplai saat kartu ini
/// ditulis — keduanya diterima APA ADANYA sebagai parameter, bukan
/// dihitung di sini.
///
/// Menutup diri sendiri (merender kosong) kalau `week.status` bukan
/// `achieved`/`missed` — pertahanan berlapis: `pendingResult` yang dikirim
/// `ChallengeBloc` (Task 13, `_hasilBelumDilihatTerbaru`) sudah menyaring
/// status ini, tapi widget tidak boleh MENGASUMSIKAN pemanggilnya selalu
/// benar (U80).
class ChallengeResultCard extends StatelessWidget {
  const ChallengeResultCard({
    super.key,
    required this.week,
    required this.rangeLabel,
    required this.line,
    required this.onDismiss,
  });

  final ChallengeWeek week;
  final String rangeLabel;
  final String line;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // U80 — pertahanan berlapis. Minggu `held`/`skipped` (dan `active`,
    // `unknown`) tidak pernah punya cerita hasil yang masuk akal di sini.
    if (week.status != ChallengeStatus.achieved &&
        week.status != ChallengeStatus.missed) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;

    final eyebrow =
        '${l10n.challengeResultEyebrow.toUpperCase()} · '
        '${rangeLabel.toUpperCase()}';

    return Container(
      key: const Key('challenge-result-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_circle_outlined,
            key: const Key('challenge-result-icon'),
            size: 20,
            color: textSoftColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: '$eyebrow. $line',
              container: true,
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow,
                    key: const Key('challenge-result-eyebrow'),
                    style: AppTextStyles.caption.copyWith(
                      color: textSoftColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line,
                    key: const Key('challenge-result-line'),
                    style: AppTextStyles.body.copyWith(color: textSoftColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: l10n.challengeResultDismiss,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('challenge-result-dismiss-button'),
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    key: const Key('challenge-result-dismiss-icon'),
                    size: 20,
                    color: textSoftColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
