import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Kartu fitur unggulan di grid bento dashboard (mis. Survival Mode, Tagihan).
///
/// Diekstrak dari `dashboard_page.dart` (Task 7.1) agar dapat dipakai ulang
/// oleh `BillsBentoTile` tanpa menyeret seluruh halaman dashboard ke widget
/// test — lihat `bills_bento_tile.dart`.
class BentoFeatTile extends StatelessWidget {
  const BentoFeatTile({
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

  /// Badge pojok kanan-atas. String kosong → badge TIDAK dirender (dipakai
  /// `BillsBentoTile` saat tidak ada tagihan aktif, supaya tak ada angka
  /// palsu yang tampil).
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
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(AppSpacing.md2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 26, color: Colors.white),
                  if (badge.isNotEmpty)
                    Container(
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
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Tile hanya selebar setengah layar dan `sub` bisa dinamis
                    // (nama tagihan sampai 50 karakter) — potong agar tak
                    // meluber, sama seperti `BillItem` di halaman daftar.
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
