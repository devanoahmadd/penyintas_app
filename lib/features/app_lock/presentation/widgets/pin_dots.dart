import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

/// Indikator progres pengisian PIN — deretan titik bulat, terisi
/// (warna primary) sebanyak [filled] dari total [length] digit.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = AppColors.primary;
    final inactive = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: AppSpacing.md2,
          height: AppSpacing.md2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? active : Colors.transparent,
            border: Border.all(color: i < filled ? active : inactive, width: 2),
          ),
        );
      }),
    );
  }
}
