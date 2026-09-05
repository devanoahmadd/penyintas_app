import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Kartu pengakuan saat sebuah ruas terhenti (spec §8.5).
///
/// Ini BUKAN galat dan BUKAN peringatan — karena itu latarnya token
/// `cardLight`/`cardDark`, **bukan** `AppColors.warn`, dan bentuknya kartu
/// tenang di atas kalender, bukan SnackBar.
///
/// Copy-nya menyebut panjang ruas yang BENAR-BENAR dicapai. Tidak ada angka
/// nol yang dipamerkan dan tidak ada kata yang menuduh: 40 hari itu terjadi
/// dan tidak dibatalkan oleh apa pun.
///
/// Kartu ini **tidak pernah** menjadi notifikasi push. §7.4 melarang
/// mengabarkan kehilangan streak ke luar app, dan larangan itu berlaku juga
/// untuk kabar yang hangat — tidak ada penjadwalan notifikasi di file ini.
class StreakBreakCard extends StatelessWidget {
  const StreakBreakCard({
    super.key,
    required this.runLength,
    required this.onAcknowledge,
  });

  /// Panjang ruas yang terhenti — yang DICAPAI, bukan sisa.
  final int runLength;

  /// Dipanggil saat "Oke" ditekan; pemanggil men-dispatch
  /// `StreakBreakAcknowledged` sehingga kartunya tampil sekali per kejadian.
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    // `primary` (#0F7A3E) nyaris tenggelam di atas `cardDark` (#1C3526);
    // `shoot` adalah pasangan aksen-on-dark-nya.
    final accentColor = isDark ? AppColors.shoot : AppColors.primary;

    return Container(
      key: const Key('consistency-break-surface'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.consistencyBreakTitle(runLength),
            style: AppTextStyles.body.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.consistencyBreakBody,
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('consistency-break-ok'),
              onPressed: onAcknowledge,
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                // Ambang sentuh Android 48dp.
                minimumSize: const Size(88, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                l10n.consistencyBreakOk,
                style: AppTextStyles.label.copyWith(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
