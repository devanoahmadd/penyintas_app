import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Tinggi minimum banner — separuh lebih pendek dari kartu 116 `BentoFeatTile`
/// sehingga porsi hijau di grid turun, tapi jauh di atas hit target 48dp.
/// MINIMUM, bukan tinggi tetap: saat font sistem membesar, banner tumbuh ke
/// bawah alih-alih memotong teks.
const double kBentoBannerMinHeight = 76;

/// Tile bento SELEBAR PENUH berbentuk banner horizontal: ikon kiri,
/// label + sub di tengah, badge kanan.
///
/// Lahir dari butir 4 (keputusan pemilik repo 2026-09-24): tile ketujuh grid
/// dua-kolom berdiri sendiri di barisnya, dan `BentoFeatTile` — dirancang
/// vertikal untuk setengah lebar — yang dipaksa melebar menyisakan ⅔ ruang
/// kanan kosong dengan ikon dan badge terpisah jauh. API-nya sengaja SAMA
/// dengan `BentoFeatTile`, jadi pemanggil cukup mengganti nama kelas.
class BentoBannerTile extends StatelessWidget {
  const BentoBannerTile({
    super.key,
    required this.bg,
    required this.icon,
    required this.label,
    required this.sub,
    required this.badge,
    required this.onTap,
  });

  final Color bg;
  final IconData icon;
  final String label;
  final String sub;

  /// String kosong → pill TIDAK dirender (sama seperti `BentoFeatTile`).
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: kBentoBannerMinHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md2,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: Colors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      // Selebar penuh, satu baris biasanya cukup. Dua baris
                      // memberi ruang saat font sistem membesar — membungkus
                      // lebih jujur daripada memotong angka sisa/lewat.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  key: const Key('bento-banner-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
