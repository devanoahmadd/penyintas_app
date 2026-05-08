import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this._locale, this._strings);

  final Locale _locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static LocalizationsDelegate<AppLocalizations> delegateFor(Locale locale) =>
      _AppLocalizationsDelegate(locale);

  Locale get locale => _locale;

  String _t(String key) => _strings[key] ?? key;

  String get appName => _t('app_name');
  String get slogan => _t('slogan');
  String get taglineOnboarding => _t('tagline_onboarding');
  String get taglineAbout => _t('tagline_about');
  String get emptyStateTransactions => _t('empty_state_transactions');
  String get survivalModeCopy => _t('survival_mode_copy');
  String get milestoneCopy => _t('milestone_copy');

  String get dashboardBudgetToday => _t('dashboard_budget_today');
  String get dashboardRemaining => _t('dashboard_remaining');
  String get dashboardDaysToLive => _t('dashboard_days_to_live');
  String daysLeft(int days) => _t('dashboard_days_left').replaceAll('{days}', '$days');

  String get addTransaction => _t('add_transaction');
  String get transactionLabel => _t('transaction_label');
  String get transactionAmount => _t('transaction_amount');
  String get transactionCategory => _t('transaction_category');

  String get btnSave => _t('btn_save');
  String get btnCancel => _t('btn_cancel');
  String get btnNext => _t('btn_next');
  String get btnBack => _t('btn_back');

  String get settingsLanguage => _t('settings_language');
  String get settingsTheme => _t('settings_theme');
  String get settingsThemeLight => _t('settings_theme_light');
  String get settingsThemeDark => _t('settings_theme_dark');
  String get settingsThemeSystem => _t('settings_theme_system');

  String get categoryFood => _t('category_food');
  String get categoryTransport => _t('category_transport');
  String get categoryCampus => _t('category_campus');
  String get categoryData => _t('category_data');
  String get categoryShopping => _t('category_shopping');
  String get categoryFixed => _t('category_fixed');
  String get categoryOther => _t('category_other');

  String get errorNetwork => _t('error_network');
  String get errorAuth => _t('error_auth');
  String get loading => _t('loading');

  String get onboardingIncomeTitle => _t('onboarding_income_title');
  String get onboardingIncomeHint => _t('onboarding_income_hint');
  String get onboardingFixedTitle => _t('onboarding_fixed_title');
  String get onboardingFixedHint => _t('onboarding_fixed_hint');
  String get onboardingDateTitle => _t('onboarding_date_title');
  String get survivalModeTitle => _t('survival_mode_title');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate([this._locale]);

  final Locale? _locale;

  static const _supported = ['id', 'en'];

  @override
  bool isSupported(Locale locale) => _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final raw = await rootBundle
        .loadString('assets/translations/${locale.languageCode}.json');
    final map = Map<String, String>.from(
      (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString())),
    );
    return AppLocalizations(locale, map);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => old._locale != _locale;
}
