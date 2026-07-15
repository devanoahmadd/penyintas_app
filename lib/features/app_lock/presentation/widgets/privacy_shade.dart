import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

/// Cover opak saat app di background / state unknown — menutup thumbnail
/// switcher agar saldo/transaksi tak bocor.
///
/// Warna latar harus solid (bukan semi-transparan) agar tak ada jejak
/// konten finansial yang tembus.
class PrivacyShade extends StatelessWidget {
  const PrivacyShade({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final logoColor = isDark ? AppColors.shoot : AppColors.primary;
    return Material(
      color: bg,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/logo-m7.svg',
          width: AppSpacing.huge,
          height: AppSpacing.huge,
          colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
