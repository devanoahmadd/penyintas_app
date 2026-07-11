import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.mutedColor});
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: mutedColor.withAlpha(80)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.authOr,
            style: AppTextStyles.caption.copyWith(color: mutedColor),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: mutedColor.withAlpha(80)),
        ),
      ],
    );
  }
}
