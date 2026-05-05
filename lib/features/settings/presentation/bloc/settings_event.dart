part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class ChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;
  const ChangeTheme(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

final class ChangeLanguage extends SettingsEvent {
  final String locale;
  const ChangeLanguage(this.locale);

  @override
  List<Object> get props => [locale];
}
