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
  String daysLeft(int days) =>
      _t('dashboard_days_left').replaceAll('{days}', '$days');

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

  // ── Settings (D-sprint 1, #103/#112) ──
  String get settingsPageTitle => _t('settings_page_title');
  String get settingsSectionNotification => _t('settings_section_notification');
  String get settingsSectionExport => _t('settings_section_export');
  String get settingsSectionAbout => _t('settings_section_about');
  String get settingsReminderTitle => _t('settings_reminder_title');
  String get settingsReminderSubtitle => _t('settings_reminder_subtitle');
  String get settingsReminderTime => _t('settings_reminder_time');
  String get settingsPushTitle => _t('settings_push_title');
  String get settingsPushSubtitle => _t('settings_push_subtitle');
  String get settingsExportCsvTitle => _t('settings_export_csv_title');
  String get settingsExportCsvSubtitle => _t('settings_export_csv_subtitle');
  String get settingsFeedbackLabel => _t('settings_feedback_label');
  String get settingsExportFailed => _t('settings_export_failed');
  String settingsErrorReminder(String message) =>
      _t('settings_error_reminder').replaceAll('{message}', message);
  String settingsErrorPush(String message) =>
      _t('settings_error_push').replaceAll('{message}', message);
  String settingsExportSubject(String month) =>
      _t('settings_export_subject').replaceAll('{month}', month);

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
  String get dashboardBudgetLabel => _t('dashboard_budget_label');
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

  // Saya page
  String get sayaSectionQuick => _t('saya_section_quick');
  String get sayaQuickGoals => _t('saya_quick_goals');
  String get sayaQuickReport => _t('saya_quick_report');
  String get sayaQuickSurvival => _t('saya_quick_survival');
  String get sayaSectionSettings => _t('saya_section_settings');
  String get sayaThemeLabel => _t('saya_theme_label');
  String get sayaLanguageLabel => _t('saya_language_label');
  String get sayaNotifLabel => _t('saya_notif_label');
  String get sayaSectionAccount => _t('saya_section_account');
  String get sayaVersionLabel => _t('saya_version_label');
  String get sayaLogout => _t('saya_logout');
  String get sayaLogoutConfirm => _t('saya_logout_confirm');
  String get sayaLogoutConfirmYes => _t('saya_logout_confirm_yes');
  String get sayaSectionDanger => _t('saya_section_danger');
  String get sayaDeleteAccount => _t('saya_delete_account');
  String get sayaEditProfile => _t('saya_edit_profile');
  String get sayaPerantauBadge => _t('saya_perantau_badge');
  String get deleteAccountTitle => _t('delete_account_title');
  String get deleteAccountBody => _t('delete_account_body');
  String get deleteAccountAck => _t('delete_account_ack');
  String get deleteAccountPasswordLabel => _t('delete_account_password_label');
  String get deleteAccountConfirm => _t('delete_account_confirm');
  String get deleteAccountWrongPassword => _t('delete_account_wrong_password');
  String get deleteAccountDone => _t('delete_account_done');

  // Budget coming soon
  String get budgetComingSoonEyebrow => _t('budget_coming_soon_eyebrow');
  String get budgetComingSoonTitle => _t('budget_coming_soon_title');
  String get budgetComingSoonBody => _t('budget_coming_soon_body');

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
  String get authResetEmailSent => _t('auth_reset_email_sent');
  String get authResetPasswordTitle => _t('auth_reset_password_title');
  String get authResetPasswordBody => _t('auth_reset_password_body');
  String get authResetPasswordCta => _t('auth_reset_password_cta');
  String get authEmailInvalidShort => _t('auth_email_invalid_short');
  String get authBack => _t('auth_back');
  String get authPasswordMin8 => _t('auth_password_min8');
  String get authOr => _t('auth_or');
  String get authGoogleCta => _t('auth_google_cta');
  String get authVerifyBannerTitle => _t('auth_verify_banner_title');
  String get authVerifyBannerBody => _t('auth_verify_banner_body');
  String get authVerifyResendCta => _t('auth_verify_resend_cta');
  String authVerifyResendWait(int seconds) =>
      _t('auth_verify_resend_wait').replaceAll('{seconds}', '$seconds');
  String get authVerifyResent => _t('auth_verify_resent');

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

  // ── Layar transaksi (D-sprint 1, #157–#160) ──
  String get txFilterAll => _t('tx_filter_all');
  String get txDateToday => _t('tx_date_today');
  String get txDateYesterday => _t('tx_date_yesterday');
  String get txEmptyTitle => _t('tx_empty_title');
  String get txEmptySub => _t('tx_empty_sub');
  String get txEmptyFilteredTitle => _t('tx_empty_filtered_title');
  String get txEmptyFilteredSub => _t('tx_empty_filtered_sub');
  String get txAddButton => _t('tx_add_button');
  String txDayCount(int count) =>
      _t('tx_day_count').replaceAll('{count}', '$count');
  String get txMonthStart => _t('tx_month_start');
  String get txSearchHint => _t('tx_search_hint');
  String get txFilterPeriod => _t('tx_filter_period');
  String get txFilterWeek => _t('tx_filter_week');
  String get txFilterMonth => _t('tx_filter_month');
  String get txFilter3Months => _t('tx_filter_3months');
  String get txFilterCustom => _t('tx_filter_custom');
  String get txFilterFrom => _t('tx_filter_from');
  String get txFilterTo => _t('tx_filter_to');
  String get txFilterAmount => _t('tx_filter_amount');
  String get txFilterReset => _t('tx_filter_reset');
  String get txFilterApply => _t('tx_filter_apply');
  String get txDetailTitle => _t('tx_detail_title');
  String get txDetailTime => _t('tx_detail_time');
  String get txDetailType => _t('tx_detail_type');
  String get txDetailTypeVariable => _t('tx_detail_type_variable');
  String get txDetailNote => _t('tx_detail_note');
  String get txDetailEdit => _t('tx_detail_edit');
  String get txDetailDuplicate => _t('tx_detail_duplicate');
  String get txDetailDelete => _t('tx_detail_delete');
  String get txDetailDeleteConfirmTitle => _t('tx_detail_delete_confirm_title');
  String get txDetailDeleteConfirmBody => _t('tx_detail_delete_confirm_body');
  String get txDetailDeleteFailed => _t('tx_detail_delete_failed');

  String get retry => _t('retry');

  // Onboarding — new keys (#125)
  String get onboardingEyebrowIncome => _t('onboarding_eyebrow_income');
  String get onboardingEyebrowFixed => _t('onboarding_eyebrow_fixed');
  String get onboardingErrorInvalidAmount =>
      _t('onboarding_error_invalid_amount');
  String get onboardingErrorAmountTooLarge =>
      _t('onboarding_error_amount_too_large');
  String get onboardingErrorSelectDate => _t('onboarding_error_select_date');
  String get onboardingErrorEmptyExpenses =>
      _t('onboarding_error_empty_expenses');
  String get onboardingErrorExpensesExceedIncome =>
      _t('onboarding_error_expenses_exceed_income');
  String get onboardingExpenseRent => _t('onboarding_expense_rent');
  String get onboardingExpenseRentHint => _t('onboarding_expense_rent_hint');
  String get onboardingExpenseUtilities => _t('onboarding_expense_utilities');
  String get onboardingExpenseUtilitiesHint =>
      _t('onboarding_expense_utilities_hint');
  String get onboardingExpenseInternet => _t('onboarding_expense_internet');
  String get onboardingExpenseInternetHint =>
      _t('onboarding_expense_internet_hint');
  String get onboardingExpensePhone => _t('onboarding_expense_phone');
  String get onboardingExpensePhoneHint => _t('onboarding_expense_phone_hint');
  String get onboardingExpenseOtherHint => _t('onboarding_expense_other_hint');
  String get onboardingErrorFixedExceedsIncome =>
      _t('onboarding_error_fixed_exceeds_income');
  String get onboardingEmergencyTargetLabel =>
      _t('onboarding_emergency_target_label');
  String onboardingEmergencyPerMonth(int pct) =>
      _t('onboarding_emergency_per_month').replaceAll('{pct}', '$pct');
  String get onboardingSliderMin => _t('onboarding_slider_min');
  String get onboardingSliderMax => _t('onboarding_slider_max');

  // Onboarding — audit fixes (2026-06-02)
  String get onboardingEmergencyTitle => _t('onboarding_emergency_title');
  String get onboardingIncomeSubtitle => _t('onboarding_income_subtitle');
  String get onboardingFixedExpenseWarning =>
      _t('onboarding_fixed_expense_warning');
  String get onboardingEyebrowEmergency => _t('onboarding_eyebrow_emergency');
  String get onboardingEmergencySubtitle => _t('onboarding_emergency_subtitle');
  String get onboardingEmergencyQuestion => _t('onboarding_emergency_question');
  String get onboardingEmergencySkip => _t('onboarding_emergency_skip');
  String get onboardingDailyBudgetLabel => _t('onboarding_daily_budget_label');
  String get onboardingDailyBudgetSuffix =>
      _t('onboarding_daily_budget_suffix');
  String onboardingDailyBudgetDaysLeft(int days) =>
      _t('onboarding_daily_budget_days_left').replaceAll('{days}', '$days');
  String onboardingDailyBudgetMonthlyLeft(String amount) =>
      _t('onboarding_daily_budget_monthly_left').replaceAll('{amount}', amount);

  // Survival Tips page & banner
  String get survivalTipsPageTitle => _t('survival_tips_page_title');
  String get survivalTipsEyebrow => _t('survival_tips_eyebrow');
  String get survivalBudgetLabel => _t('survival_budget_label');
  String survivalBudgetDaysSuggested(int days, String amount) => _t(
    'survival_budget_days_suggested',
  ).replaceAll('{days}', '$days').replaceAll('{amount}', amount);
  String survivalTipsSavingChip(String amount) =>
      _t('survival_tips_saving_chip').replaceAll('{amount}', amount);
  String survivalBannerBalance(String amount, int days) => _t(
    'survival_banner_balance',
  ).replaceAll('{amount}', amount).replaceAll('{days}', '$days');
  String get survivalTipsLink => _t('survival_tips_link');
  String get survivalTipsEmpty => _t('survival_tips_empty');

  // Goals
  String get goalsTitle => _t('goals_title');
  String get goalsEmpty => _t('goals_empty');
  String get goalsAdd => _t('goals_add');
  String goalProgressLabel(String saved, String target) => _t(
    'goal_progress_label',
  ).replaceAll('{saved}', saved).replaceAll('{target}', target);
  String goalTargetDate(String date) =>
      _t('goal_target_date').replaceAll('{date}', date);
  String get goalCompleted => _t('goal_completed');
  String get goalOverdue => _t('goal_overdue');
  String get goalAddTitle => _t('goal_add_title');
  String get goalTitleLabel => _t('goal_title_label');
  String get goalTitleHint => _t('goal_title_hint');
  String get goalAmountLabel => _t('goal_amount_label');
  String get goalDateLabel => _t('goal_date_label');
  String get goalLinkLabel => _t('goal_link_label');
  String get goalLinkNone => _t('goal_link_none');
  String get goalDeleteConfirm => _t('goal_delete_confirm');
  String goalMilestonePct(int pct) =>
      _t('goal_milestone_pct').replaceAll('{pct}', '$pct');
  String get goalDetailMarkDone => _t('goal_detail_mark_done');
  String get goalDetailDeleteTooltip => _t('goal_detail_delete_tooltip');
  String get goalDetailStatusLabel => _t('goal_detail_status_label');
  String get goalDetailStatusActive => _t('goal_detail_status_active');
  String get goalDetailDeleteTitle => _t('goal_detail_delete_title');
  String get goalDetailDeleteBtn => _t('goal_detail_delete_btn');
  String get goalDetailTip => _t('goal_detail_tip');
  String get goalDatePickerHint => _t('goal_date_picker_hint');

  // Dashboard C1 — ring delta
  String get dashboardDeltaOnTrack => _t('dashboard_delta_on_track');
  String get dashboardDeltaNearing => _t('dashboard_delta_nearing');
  String get dashboardDeltaExceeded => _t('dashboard_delta_exceeded');
  String dashboardPctOfBudget(int pct) =>
      _t('dashboard_pct_of_budget').replaceAll('{pct}', '$pct');
  String dashboardPctOfTotal(int pct) =>
      _t('dashboard_pct_of_total').replaceAll('{pct}', '$pct');

  // Dashboard C1 — section headers
  String get dashboardQuickAccess => _t('dashboard_quick_access');
  String get dashboardQuickAccessAction => _t('dashboard_quick_access_action');
  String get dashboardSeeAllAction => _t('dashboard_see_all_action');

  // Dashboard C1 — greetings
  String get dashboardGreetingMorning => _t('dashboard_greeting_morning');
  String get dashboardGreetingNoon => _t('dashboard_greeting_noon');
  String get dashboardGreetingAfternoon => _t('dashboard_greeting_afternoon');
  String get dashboardGreetingEvening => _t('dashboard_greeting_evening');

  // Dashboard C1 — saldo card
  String get dashboardBalanceHidden => _t('dashboard_balance_hidden');
  String get dashboardBalanceDetail => _t('dashboard_balance_detail');
  String get dashboardBalanceAsOf => _t('dashboard_balance_as_of');

  // Dashboard C1 — bento tiles
  String get dashboardBentoSurvivalLabel =>
      _t('dashboard_bento_survival_label');
  String get dashboardBentoSurvivalBadge =>
      _t('dashboard_bento_survival_badge');
  String get dashboardBentoSurvivalSub => _t('dashboard_bento_survival_sub');
  String get dashboardBentoBillsLabel => _t('dashboard_bento_bills_label');
  String get dashboardBentoBillsSub => _t('dashboard_bento_bills_sub');
  String get dashboardBentoBillsBadge => _t('dashboard_bento_bills_badge');
  String get dashboardBentoGoalsSub => _t('dashboard_bento_goals_sub');
  String get dashboardBentoScanLabel => _t('dashboard_bento_scan_label');
  String get dashboardBentoScanSub => _t('dashboard_bento_scan_sub');
  String get dashboardBentoSplitLabel => _t('dashboard_bento_split_label');
  String get dashboardBentoSplitSub => _t('dashboard_bento_split_sub');
  String get dashboardBentoChallengeLabel =>
      _t('dashboard_bento_challenge_label');
  String get dashboardBentoChallengeSub => _t('dashboard_bento_challenge_sub');

  // Common
  String get commonComingSoon => _t('common_coming_soon');
  // 'Batal' TIDAK dibuatkan key baru — pakai getter existing `btnCancel`.
  String get commonDelete => _t('common_delete');

  // Dashboard C1 — tip card
  String get dashboardTipEyebrow => _t('dashboard_tip_eyebrow');
  String get dashboardTipText => _t('dashboard_tip_text');

  // Dashboard C1 — transaction empty
  String get dashboardTxEmpty => _t('dashboard_tx_empty');

  // Categories (extended)
  String get categoryHealth => _t('category_health');
  String get categoryInternet => _t('category_internet');

  // Onboarding — audit remediasi (#200/#201/#202)
  String get onboardingExitDialogTitle => _t('onboarding_exit_dialog_title');
  String get onboardingExitDialogBody => _t('onboarding_exit_dialog_body');
  String get onboardingExitDialogContinue =>
      _t('onboarding_exit_dialog_continue');
  String get onboardingExitDialogConfirm =>
      _t('onboarding_exit_dialog_confirm');
  String get onboardingResumeDialogTitle =>
      _t('onboarding_resume_dialog_title');
  String onboardingResumeDialogBody(int days) =>
      _t('onboarding_resume_dialog_body').replaceAll('{days}', '$days');
  String get onboardingResumeContinue => _t('onboarding_resume_continue');
  String get onboardingResumeRestart => _t('onboarding_resume_restart');
  String get onboardingResumeBanner => _t('onboarding_resume_banner');
  String get onboardingResetDialogTitle => _t('onboarding_reset_dialog_title');
  String get onboardingResetDialogCancel =>
      _t('onboarding_reset_dialog_cancel');
  String get onboardingResetDialogConfirm =>
      _t('onboarding_reset_dialog_confirm');
  String get onboardingDatePickerTitle => _t('onboarding_date_picker_title');
  String get onboardingDatePickerSubtitle =>
      _t('onboarding_date_picker_subtitle');
  String get onboardingDatePickerNote => _t('onboarding_date_picker_note');
  String get onboardingDatePickerNone => _t('onboarding_date_picker_none');
  String onboardingDatePickerUse(int date) =>
      _t('onboarding_date_picker_use').replaceAll('{date}', '$date');
  String onboardingDatePickerUseApprox(int date) =>
      _t('onboarding_date_picker_use_approx').replaceAll('{date}', '$date');
  String get onboardingWarnFixedFull => _t('onboarding_warn_fixed_full');

  // Onboarding redesign — C+ stagger
  String get onboardingEyebrowStep1 => _t('onboarding_eyebrow_step1');
  String get onboardingEyebrowStep2 => _t('onboarding_eyebrow_step2');
  String get onboardingEyebrowStep3 => _t('onboarding_eyebrow_step3');
  String get onboardingTitleIncome => _t('onboarding_title_income');
  String get onboardingTitleFixed => _t('onboarding_title_fixed');
  String get onboardingTitleDarurat => _t('onboarding_title_darurat');
  String get onboardingDoneEyebrow => _t('onboarding_done_eyebrow');
  String get onboardingDoneTitle => _t('onboarding_done_title');
  String get onboardingDoneSub => _t('onboarding_done_sub');
  String get onboardingPaydayLabel => _t('onboarding_payday_label');
  String get onboardingSkipLater => _t('onboarding_skip_later');
  String get onboardingChipOtherDate => _t('onboarding_chip_other_date');
  String get onboardingCtaStart => _t('onboarding_cta_start');
  String get onboardingCtaEnter => _t('onboarding_cta_enter');
  String get onboardingSheetDone => _t('onboarding_sheet_done');
  String get onboardingTotalLabel => _t('onboarding_total_label');
  String onboardingTotalPct(int pct) =>
      _t('onboarding_total_pct').replaceAll('{pct}', '$pct');
  String onboardingSheetTotalLabel(int pct) =>
      _t('onboarding_sheet_total_label').replaceAll('{pct}', '$pct');
  String get onboardingDailySubNoEmergency =>
      _t('onboarding_daily_sub_no_emergency');
  String onboardingDailySubSaving(String amount) =>
      _t('onboarding_daily_sub_saving').replaceAll('{amount}', amount);
  String get onboardingPctLabelLow => _t('onboarding_pct_label_low');
  String get onboardingPctNoteLow => _t('onboarding_pct_note_low');
  String get onboardingPctLabelMid => _t('onboarding_pct_label_mid');
  String get onboardingPctNoteMid => _t('onboarding_pct_note_mid');
  String get onboardingPctLabelHigh => _t('onboarding_pct_label_high');
  String get onboardingPctNoteHigh => _t('onboarding_pct_note_high');
  String get onboardingPctLabelMax => _t('onboarding_pct_label_max');
  String get onboardingPctNoteMax => _t('onboarding_pct_note_max');
  String get onboardingPctNoteSkip => _t('onboarding_pct_note_skip');
  String get onboardingStatDaily => _t('onboarding_stat_daily');
  String get onboardingStatEmergency => _t('onboarding_stat_emergency');
  String get onboardingStatIncome => _t('onboarding_stat_income');
  String get onboardingStatFixed => _t('onboarding_stat_fixed');

  // Profile Leg — B4 mini-wizard
  String get profileStepATitle => _t('profile_step_a_title');
  String get profileStepBTitle => _t('profile_step_b_title');
  String get profileLangLabel => _t('profile_lang_label');
  String get profileNameLabel => _t('profile_name_label');
  String get profileNameHint => _t('profile_name_hint');
  String get profileStatusLabel => _t('profile_status_label');
  String get profileStatusMahasiswa => _t('profile_status_mahasiswa');
  String get profileStatusPekerja => _t('profile_status_pekerja');
  String get profileCountryLabel => _t('profile_country_label');
  String get profileCityLabel => _t('profile_city_label');
  String get profileTimezoneLabel => _t('profile_timezone_label');
  String get profileTimezoneChange => _t('profile_timezone_change');
  String get profilePerantauLabel => _t('profile_perantau_label');
  String get profileHomeCountryLabel => _t('profile_home_country_label');
  String get profileHomeCityLabel => _t('profile_home_city_label');
  String get profileExitDialogTitle => _t('profile_exit_dialog_title');
  String get profileExitDialogBody => _t('profile_exit_dialog_body');
  String get profileExitDialogConfirm => _t('profile_exit_dialog_confirm');
  String get profileExitDialogContinue => _t('profile_exit_dialog_continue');
  String get profileErrorRetry => _t('profile_error_retry');
  String get profileErrorSignout => _t('profile_error_signout');

  // Profile Edit — C3
  String get profileEditTitle => _t('profile_edit_title');
  String get profileLoadError => _t('profile_load_error');
  String get profileSaved => _t('profile_saved');
  String get profileSelectCityFirst => _t('profile_select_city_first');
  String get profileDiscardTitle => _t('profile_discard_title');
  String get profileDiscardKeep => _t('profile_discard_keep');
  String get profileDiscardLeave => _t('profile_discard_leave');

  // Manage categories
  String get manageCategoriesTitle => _t('manage_categories_title');
  String get manageCategoriesSectionBuiltIn =>
      _t('manage_categories_section_built_in');
  String get manageCategoriesSectionCustom =>
      _t('manage_categories_section_custom');
  String get manageCategoriesEmpty => _t('manage_categories_empty');
  String get manageCategoriesEmptyHint => _t('manage_categories_empty_hint');
  String get manageCategoriesDeleteTitle =>
      _t('manage_categories_delete_title');
  String manageCategoriesDeleteBody(String name) =>
      _t('manage_categories_delete_body').replaceAll('{name}', name);
  String get manageCategoriesDeleteConfirm =>
      _t('manage_categories_delete_confirm');
  String get addCategoryTitle => _t('add_category_title');
  String get editCategoryTitle => _t('edit_category_title');
  String get addCategoryNameLabel => _t('add_category_name_label');
  String get addCategoryNameHint => _t('add_category_name_hint');
  String get addCategoryIconLabel => _t('add_category_icon_label');
  String get addCategoryLimitableLabel => _t('add_category_limitable_label');
  String get addCategoryLimitableSub => _t('add_category_limitable_sub');
  String get categorySuccessCreated => _t('category_success_created');
  String get categorySuccessUpdated => _t('category_success_updated');
  String get categorySuccessDeleted => _t('category_success_deleted');
  String get categoryErrorDuplicate => _t('category_error_duplicate');

  // Rekonsiliasi timezone — F5 (D3)
  String tzReconMessage(String city) =>
      _t('tz_recon_message').replaceAll('{city}', city);
  String get tzReconConfirm => _t('tz_recon_confirm');
  String get tzReconDismiss => _t('tz_recon_dismiss');
  String tzReconStored(String label) =>
      _t('tz_recon_stored').replaceAll('{label}', label);

  // ── App Lock (C2) ──
  String get settingsSectionSecurity => _t('settings_section_security');
  String get applockToggleTitle => _t('applock_toggle_title');
  String get applockToggleSubtitle => _t('applock_toggle_subtitle');
  String get applockBiometricTitle => _t('applock_biometric_title');
  String get applockBiometricSubtitle => _t('applock_biometric_subtitle');
  String get applockChangePin => _t('applock_change_pin');
  String get applockSetTitle => _t('applock_set_title');
  String get applockSetSubtitle => _t('applock_set_subtitle');
  String get applockConfirmTitle => _t('applock_confirm_title');
  String get applockConfirmSubtitle => _t('applock_confirm_subtitle');
  String get applockMismatch => _t('applock_mismatch');
  String get applockEnterTitle => _t('applock_enter_title');
  String get applockWrong => _t('applock_wrong');
  String applockLockedWait(int seconds) =>
      _t('applock_locked_wait').replaceAll('{seconds}', '$seconds');
  String get applockForgot => _t('applock_forgot');
  String get applockForgotDialogTitle => _t('applock_forgot_dialog_title');
  String get applockForgotDialogBody => _t('applock_forgot_dialog_body');
  String get applockForgotConfirm => _t('applock_forgot_confirm');
  String get applockBiometricReason => _t('applock_biometric_reason');
  String get applockVerifyToDisable => _t('applock_verify_to_disable');
  String get applockChangeCurrent => _t('applock_change_current');
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
    final raw = await rootBundle.loadString(
      'assets/translations/${locale.languageCode}.json',
    );
    final map = Map<String, String>.from(
      (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
    return AppLocalizations(locale, map);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => old._locale != _locale;
}
