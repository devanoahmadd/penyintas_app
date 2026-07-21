import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Tombol utama Penyintas — [AppColors.primary], radius [AppRadius.lg].
///
/// Gunakan [isLoading] saat menunggu proses async (teks diganti spinner inline).
/// Gunakan [isEnabled] = false untuk disable state — jangan pakai onPressed: null
/// langsung agar logic di pemanggil tetap bersih.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width = double.infinity,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  /// Lebar tombol. Default [double.infinity] (full width).
  final double width;

  /// Ikon opsional di kiri teks.
  final Widget? icon;

  bool get _active => isEnabled && !isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _active,
      label: label,
      child: SizedBox(
        width: width,
        height: 48, // hit target minimum Android 48dp
        child: Material(
          color: _active ? AppColors.primary : AppColors.primary.withAlpha(100),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: _active ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: AppColors.primaryDeep.withAlpha(80),
            highlightColor: AppColors.primaryDeep.withAlpha(40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : _ButtonContent(
                          key: const ValueKey('content'),
                          label: label,
                          icon: icon,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({super.key, required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white)),
      ],
    );
  }
}
