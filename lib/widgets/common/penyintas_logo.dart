import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';

/// Logo M7 Penyintas.
///
/// Mode switching otomatis via [Theme.of(context).brightness]:
/// - light  → warna SVG asli (#0F7A3E)
/// - dark   → [AppColors.shoot] (#A8E6B6)
/// - reversed (di latar hijau) → putih
///
/// Kemiringan 6° sudah baked-in di SVG, jangan rotate ulang.
class PenyintasLogo extends StatelessWidget {
  const PenyintasLogo({super.key, this.size = 40, this.reversed = false})
    : assert(size >= 24, 'Ukuran minimum logo adalah 24dp');

  final double size;

  /// Gunakan [reversed] = true saat logo tampil di atas latar hijau/gelap pekat
  /// (misalnya SplashPage dengan background [AppColors.primary]).
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ColorFilter? colorFilter = reversed
        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
        : isDark
        ? const ColorFilter.mode(AppColors.shoot, BlendMode.srcIn)
        : null;

    return Semantics(
      label: 'Penyintas logo',
      child: SvgPicture.asset(
        'assets/images/logo-m7.svg',
        width: size,
        height: size,
        colorFilter: colorFilter,
      ),
    );
  }
}
