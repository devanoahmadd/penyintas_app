import 'package:flutter/widgets.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
