import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.primaryDeep : AppColors.shoot,
      onPrimaryContainer: isDark ? AppColors.shoot : AppColors.primaryDeep,
      secondary: AppColors.primaryBright,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSecondaryContainer: isDark ? AppColors.textDark : AppColors.textLight,
      error: AppColors.warn,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textDark : AppColors.textLight,
      surfaceContainerHighest: isDark ? AppColors.borderDark : AppColors.borderLight,
      onSurfaceVariant: isDark ? AppColors.mutedDark : AppColors.mutedLight,
      outline: isDark ? AppColors.borderDark : AppColors.borderLight,
      outlineVariant: isDark ? AppColors.borderDark : AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        thickness: 0.5,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineLarge: AppTextStyles.h1.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineMedium: AppTextStyles.h2.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineSmall: AppTextStyles.h3.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyLarge: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyMedium: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight,
        ),
        labelLarge: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodySmall: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.warn),
        ),
        labelStyle: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.textLight,
        contentTextStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
