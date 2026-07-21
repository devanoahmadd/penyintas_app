part of 'settings_bloc.dart';

final class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String locale;

  const SettingsState({required this.themeMode, required this.locale});

  const SettingsState.initial() : themeMode = ThemeMode.system, locale = 'id';

  SettingsState copyWith({ThemeMode? themeMode, String? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [themeMode, locale];
}
