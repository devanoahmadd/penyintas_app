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
  String get categoryIncome => _t('category_income');
  String get categoryOther => _t('category_other');

  String get errorNetwork => _t('error_network');
  String get errorAuth => _t('error_auth');
  String get loading => _t('loading');

  String get onboardingIncomeTitle => _t('onboarding_income_title');
  String get onboardingIncomeLabel => _t('onboarding_income_label');
  String get onboardingIncomeHint => _t('onboarding_income_hint');
  String get onboardingFixedTitle => _t('onboarding_fixed_title');
  String get onboardingFixedHint => _t('onboarding_fixed_hint');
  String get onboardingDateTitle => _t('onboarding_date_title');
  String get survivalModeTitle => _t('survival_mode_title');
  String get dashboardDtlLabel => _t('dashboard_dtl_label');
  String get dashboardDtlSubtitle => _t('dashboard_dtl_subtitle');
  String get dashboardSaldoLabel => _t('dashboard_saldo_label');
  String get dashboardSpendingLabel => _t('dashboard_spending_label');
  String get dashboardEmergencyLabel => _t('dashboard_emergency_label');
  String get dashboardRecentTx => _t('dashboard_recent_tx');
  String get dashboardSeeAll => _t('dashboard_see_all');
  String get dashboardFromBudget => _t('dashboard_from_budget');
  String get dashboardStatusSafe => _t('dashboard_status_safe');
  String get dashboardStatusCaution => _t('dashboard_status_caution');
  String get dashboardStatusDanger => _t('dashboard_status_danger');
  String get dashboardSafeUntil => _t('dashboard_safe_until');
  String get navHome => _t('nav_home');
  String get navTransactions => _t('nav_transactions');
  String get navBudget => _t('nav_budget');
  String get navReport => _t('nav_report');
  String get navProfile => _t('nav_profile');

  // Auth
  String get authLoginTitle => _t('auth_login_title');
  String get authLoginSubtitle => _t('auth_login_subtitle');
  String get authEmailLabel => _t('auth_email_label');
  String get authEmailHint => _t('auth_email_hint');
  String get authPasswordLabel => _t('auth_password_label');
  String get authPasswordHint => _t('auth_password_hint');
  String get authForgotPassword => _t('auth_forgot_password');
  String get authSignIn => _t('auth_sign_in');
  String get authNoAccount => _t('auth_no_account');
  String get authSignUpLink => _t('auth_sign_up_link');
  String get authRegisterTitle => _t('auth_register_title');
  String get authRegisterSubtitle => _t('auth_register_subtitle');
  String get authNameLabel => _t('auth_name_label');
  String get authNameHint => _t('auth_name_hint');
  String get authPasswordHintReg => _t('auth_password_hint_reg');
  String get authConfirmLabel => _t('auth_confirm_label');
  String get authConfirmHint => _t('auth_confirm_hint');
  String get authCreateAccount => _t('auth_create_account');
  String get authHasAccount => _t('auth_has_account');
  String get authSignInLink => _t('auth_sign_in_link');

  // Validation errors
  String get errorEmailEmpty => _t('error_email_empty');
  String get errorEmailInvalid => _t('error_email_invalid');
  String get errorPasswordEmpty => _t('error_password_empty');
  String get errorNameMin => _t('error_name_min');
  String get errorPasswordMin => _t('error_password_min');
  String get errorConfirmMismatch => _t('error_confirm_mismatch');

  // Add transaction sheet
  String get txRecordTitle => _t('tx_record_title');
  String get txIncomeLabel => _t('tx_income_label');
  String get txExpenseLabel => _t('tx_expense_label');
  String get txNominalLabel => _t('tx_nominal_label');
  String get txNominalTap => _t('tx_nominal_tap');
  String get txSectionCategory => _t('tx_section_category');
  String get txSectionNote => _t('tx_section_note');
  String get txSectionDate => _t('tx_section_date');
  String get txNoteHint => _t('tx_note_hint');
  String get txDoneBtn => _t('tx_done_btn');

  String get retry => _t('retry');

  // Onboarding — new keys (#125)
  String get onboardingEyebrowIncome => _t('onboarding_eyebrow_income');
  String get onboardingEyebrowFixed => _t('onboarding_eyebrow_fixed');
  String get onboardingErrorInvalidAmount => _t('onboarding_error_invalid_amount');
  String get onboardingErrorAmountTooLarge => _t('onboarding_error_amount_too_large');
  String get onboardingErrorSelectDate => _t('onboarding_error_select_date');
  String get onboardingErrorEmptyExpenses => _t('onboarding_error_empty_expenses');
  String get onboardingErrorExpensesExceedIncome => _t('onboarding_error_expenses_exceed_income');
  String get onboardingExpenseRent => _t('onboarding_expense_rent');
  String get onboardingExpenseRentHint => _t('onboarding_expense_rent_hint');
  String get onboardingExpenseUtilities => _t('onboarding_expense_utilities');
  String get onboardingExpenseUtilitiesHint => _t('onboarding_expense_utilities_hint');
  String get onboardingExpenseInternet => _t('onboarding_expense_internet');
  String get onboardingExpenseInternetHint => _t('onboarding_expense_internet_hint');
  String get onboardingExpensePhone => _t('onboarding_expense_phone');
  String get onboardingExpensePhoneHint => _t('onboarding_expense_phone_hint');
  String get onboardingExpenseOtherHint => _t('onboarding_expense_other_hint');
  String get onboardingErrorFixedExceedsIncome => _t('onboarding_error_fixed_exceeds_income');
  String get onboardingEmergencyTargetLabel => _t('onboarding_emergency_target_label');
  String onboardingEmergencyPerMonth(int pct) =>
      _t('onboarding_emergency_per_month').replaceAll('{pct}', '$pct');
  String get onboardingSliderMin => _t('onboarding_slider_min');
  String get onboardingSliderMax => _t('onboarding_slider_max');
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
