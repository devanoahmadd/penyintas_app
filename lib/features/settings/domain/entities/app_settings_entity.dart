import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsEntity extends Equatable {
  final ThemeMode themeMode;
  final String locale;

  const AppSettingsEntity({required this.themeMode, required this.locale});

  AppSettingsEntity copyWith({ThemeMode? themeMode, String? locale}) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  static ThemeMode themeModeFromString(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String themeModeToString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    _ => 'system',
  };

  @override
  List<Object> get props => [themeMode, locale];
}
