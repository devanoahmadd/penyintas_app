import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// TextField standar Penyintas.
///
/// - Border 1dp normal, 2dp saat focus ([AppColors.primary])
/// - Error state: border + helper text [AppColors.warn]
/// - [helperText] default ' ' (spasi) agar tinggi field konsisten
///   saat ada/tidak ada pesan error — tidak ada layout shift
/// - [isPassword] = true aktifkan toggle show/hide secara internal
/// - [isValid] = true tampilkan checkmark hijau di kanan field
///   (kompatibel dengan [isPassword] — keduanya muncul bersamaan)
/// - Hindari floating label untuk form singkat; gunakan [label] di atas field
///   dan [hintText] di dalam field
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText = ' ',
    this.isPassword = false,
    this.isValid = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.onClear,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;

  /// Default ' ' (spasi) — jaga tinggi field konsisten saat error muncul/hilang.
  final String helperText;

  final bool isPassword;

  /// Tampilkan checkmark [AppColors.success] di kanan field.
  /// Jika [isPassword] juga true, eye icon dan checkmark muncul berdampingan.
  final bool isValid;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final Widget? prefixIcon;

  /// Tampilkan tombol × di kanan field saat ada isi.
  /// Tidak berlaku jika [isPassword] true.
  final VoidCallback? onClear;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  Widget? _buildSuffixIcon(Color hintColor) {
    final eyeIcon = IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: hintColor,
        size: 20,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
      tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
    );

    const checkIcon = Padding(
      padding: EdgeInsets.only(right: 12),
      child: Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: 20,
      ),
    );

    if (widget.isPassword && widget.isValid) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [eyeIcon, checkIcon],
      );
    } else if (widget.isPassword) {
      return eyeIcon;
    } else if (widget.onClear != null &&
        (widget.controller?.text.isNotEmpty ?? false)) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.close, color: hintColor, size: 18),
        onPressed: widget.onClear,
        tooltip: 'Hapus',
      );
    } else if (widget.isValid) {
      return checkIcon;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final hintColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.warn, width: 1.5),
    );
    final focusedErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.warn, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.label.copyWith(color: textColor),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          style: AppTextStyles.body.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.body.copyWith(color: hintColor),
            errorText: widget.errorText,
            helperText: widget.errorText == null ? widget.helperText : null,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.warn,
              height: 1.3,
            ),
            helperStyle: AppTextStyles.bodySmall.copyWith(height: 1.3),
            prefixIcon: widget.prefixIcon,
            suffixIconConstraints: const BoxConstraints(minHeight: 48),
            suffixIcon: _buildSuffixIcon(hintColor),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: focusedErrorBorder,
            disabledBorder: border,
          ),
        ),
      ],
    );
  }
}
