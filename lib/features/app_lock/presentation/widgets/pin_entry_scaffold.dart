import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_dots.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';

/// Struktur layout bersama untuk ketiga halaman PIN (Set/Change/Verify):
/// Scaffold + AppBar + SafeArea + judul(+subjudul opsional) + [PinDots] +
/// kotak pesan status/error + [PinKeypad] + footer opsional.
///
/// Diekstrak dari Task 12 karena `build()` ketiganya identik strukturnya —
/// hanya berbeda pada state machine & judul/pesan yang ditampilkan, bukan
/// pada bentuk layoutnya. Lihat masing-masing halaman untuk state machine-nya.
class PinEntryScaffold extends StatelessWidget {
  const PinEntryScaffold({
    super.key,
    required this.title,
    required this.message,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.subtitle,
    this.keypadEnabled = true,
    this.footer,
  });

  /// Judul utama (mis. "Buat PIN", "Konfirmasi PIN", "Masukkan PIN saat ini").
  final String title;

  /// Subjudul opsional di bawah [title]. Null → tak dirender.
  final String? subtitle;

  /// Pesan status/error di bawah [PinDots] ('' = kosong, tak dirender apa pun
  /// selain ruang kosong agar layout tak "loncat" saat pesan muncul/hilang).
  final String message;

  /// Jumlah digit PIN yang sudah terisi (0..6) — diteruskan ke [PinDots].
  final int filled;

  /// Non-aktifkan [PinKeypad] (mis. saat lockout progresif berlangsung).
  final bool keypadEnabled;

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  /// Widget opsional di bawah keypad (mis. tombol aksi tambahan).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(color: textColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PinDots(length: 6, filled: filled),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSpacing.xl,
                child: Center(
                  // `liveRegion: true` — pesan error/status (mis. PIN salah,
                  // mismatch) WAJIB diumumkan screen reader saat muncul, tak
                  // cukup mengandalkan warna merah/oranye secara visual saja.
                  child: message.isEmpty
                      ? const SizedBox.shrink()
                      : Semantics(
                          liveRegion: true,
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.warn),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PinKeypad(
                enabled: keypadEnabled,
                onDigit: onDigit,
                onBackspace: onBackspace,
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.lg),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
