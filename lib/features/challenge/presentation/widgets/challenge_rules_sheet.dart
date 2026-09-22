import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Sheet "Cara kerja tantangan", dipicu ikon `[?]` di AppBar `/challenge`
/// (spec §7.3). Pola meniru `StreakRulesSheet`: bacaan pasif singkat, satu
/// topik, jalan keluar eksplisit.
///
/// **Contoh angka WAJIB pasangan 140.000 → 115.000** (`challenge_rules_body`,
/// `assets/translations/*.json`) — BUKAN "141.000 → 120.000" yang beredar di
/// spec §2 T4 / §7.9: `floor(141000 × 0,85 / 5000) × 5000 = 115.000`, bukan
/// 120.000, jadi pasangan lama keliru secara aritmetika (dikoreksi Rev 5
/// desain, dan Task 2 sudah mengunci `computeTarget` ke nilai yang benar).
///
/// Aksi sekunder **"Lewati minggu ini"** (T15) hanya tampil Senin–Selasa
/// ([showSkip]) dan SELALU didahului dialog konfirmasi — user tidak pernah
/// melewati minggu hanya dengan satu ketukan.
class ChallengeRulesSheet {
  const ChallengeRulesSheet._();

  static Future<void> show(
    BuildContext context, {
    required bool showSkip,
    required VoidCallback onSkip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _Body(showSkip: showSkip, onSkip: onSkip),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  Future<void> _handleSkipTap(BuildContext context) async {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('challenge-skip-confirm-dialog'),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.challengeRulesSkipConfirmTitle,
          style: AppTextStyles.h3.copyWith(color: textColor),
        ),
        content: Text(
          l10n.challengeRulesSkipConfirmBody,
          style: AppTextStyles.body.copyWith(color: textSoftColor),
        ),
        actions: [
          TextButton(
            key: const Key('challenge-skip-confirm-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.btnCancel,
              style: AppTextStyles.label.copyWith(color: mutedColor),
            ),
          ),
          TextButton(
            key: const Key('challenge-skip-confirm-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.challengeRulesSkipConfirmConfirm,
              style: AppTextStyles.label.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      onSkip();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final softColor = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Semantics(
      label: l10n.challengeRulesA11y,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Jalan keluar EKSPLISIT (gerbang ui-ux-pro-max: `modal-escape`) —
            // sheet ini bacaan pasif, jangan hanya andalkan swipe-down/scrim.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).closeButtonLabel,
                    child: InkResponse(
                      onTap: () => Navigator.of(context).pop(),
                      radius: 24,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.close, size: 18, color: mutedColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        l10n.challengeRulesTitle,
                        style: AppTextStyles.h3.copyWith(color: textColor),
                      ),
                    ),
                    Text(
                      key: const Key('challenge-rules-body'),
                      l10n.challengeRulesBody,
                      style: AppTextStyles.body.copyWith(color: softColor),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      key: const Key('challenge-rules-excluded-note'),
                      l10n.challengeRulesExcludedNote,
                      style: AppTextStyles.bodySmall.copyWith(color: softColor),
                    ),
                    if (showSkip) ...[
                      const SizedBox(height: AppSpacing.md),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: AppSpacing.sm),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('challenge-skip-action'),
                          onTap: () => _handleSkipTap(context),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.challengeRulesSkipAction,
                              style: AppTextStyles.label.copyWith(
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
