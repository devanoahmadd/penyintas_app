import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Keypad numerik untuk PIN. Mencerminkan gaya onboarding_keypad
/// (token surfaceAlt, hit target 48dp, haptic).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        return Row(
          children: row.map((k) {
            if (k.isEmpty) {
              return const Expanded(child: SizedBox(height: AppSpacing.huge));
            }
            return Expanded(
              child: _Key(
                label: k,
                enabled: enabled,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (k == 'back') {
                    onBackspace();
                  } else {
                    onDigit(k);
                  }
                },
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final isBack = label == 'back';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: AppSpacing.xxxl,
            child: Center(
              child: isBack
                  // semanticLabel WAJIB: ikon tanpa teks, jadi screen reader
                  // tak punya keterangan apa pun tanpa ini. Lewat l10n (bukan
                  // hardcode) karena label ini DIBACAKAN — user EN akan
                  // mendengar kata Indonesia yang tak ia pahami.
                  ? Icon(
                      Icons.backspace_outlined,
                      color: textColor,
                      size: 22,
                      semanticLabel: context.l10n.commonBackspace,
                    )
                  : Text(
                      label,
                      style: AppTextStyles.numericMd.copyWith(color: textColor),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
