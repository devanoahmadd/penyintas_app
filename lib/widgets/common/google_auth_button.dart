import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Tombol "Lanjutkan dengan Google" — satu label untuk login & register
/// (keputusan spec A5+B4 §6.1: backend-nya satu operasi sign-in-or-create).
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.authGoogleCta;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: AppColors.primary.withAlpha(20),
            highlightColor: AppColors.primary.withAlpha(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo resmi Google — tanpa recolor (guideline branding)
                  SvgPicture.asset(
                    'assets/images/google_g_logo.svg',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
