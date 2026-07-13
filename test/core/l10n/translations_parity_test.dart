import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard: id.json & en.json harus punya set key identik, dan semua key
/// D-sprint 1 harus terdaftar di keduanya. `_t()` fallback ke nama key
/// saat key hilang — test ini mencegah fallback itu lolos diam-diam.
void main() {
  late Map<String, dynamic> id;
  late Map<String, dynamic> en;

  setUpAll(() {
    id =
        json.decode(File('assets/translations/id.json').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('id.json dan en.json punya set key identik', () {
    expect(
      id.keys.toSet().difference(en.keys.toSet()),
      isEmpty,
      reason: 'key ini hanya ada di id.json',
    );
    expect(
      en.keys.toSet().difference(id.keys.toSet()),
      isEmpty,
      reason: 'key ini hanya ada di en.json',
    );
  });

  test('semua key baru D-sprint 1 tersedia di kedua file', () {
    const newKeys = [
      // Settings (#103/#112)
      'settings_page_title', 'settings_section_notification',
      'settings_section_export', 'settings_section_about',
      'settings_reminder_title', 'settings_reminder_subtitle',
      'settings_reminder_time', 'settings_push_title', 'settings_push_subtitle',
      'settings_export_csv_title', 'settings_export_csv_subtitle',
      'settings_feedback_label', 'settings_error_reminder',
      'settings_error_push', 'settings_export_failed',
      'settings_export_subject',
      // Layar transaksi (#157–#160)
      'tx_filter_all', 'tx_date_today', 'tx_date_yesterday',
      'tx_empty_title', 'tx_empty_sub', 'tx_empty_filtered_title',
      'tx_empty_filtered_sub', 'tx_add_button', 'tx_day_count',
      'tx_month_start', 'tx_search_hint',
      // Filter sheet
      'tx_filter_period', 'tx_filter_week', 'tx_filter_month',
      'tx_filter_3months', 'tx_filter_custom', 'tx_filter_from',
      'tx_filter_to', 'tx_filter_amount', 'tx_filter_reset',
      'tx_filter_apply',
      // Detail sheet
      'tx_detail_title', 'tx_detail_time', 'tx_detail_type',
      'tx_detail_type_variable', 'tx_detail_note', 'tx_detail_edit',
      'tx_detail_duplicate', 'tx_detail_delete',
      'tx_detail_delete_confirm_title', 'tx_detail_delete_confirm_body',
      'tx_detail_delete_failed', 'common_delete',
    ];
    for (final k in newKeys) {
      expect(id.containsKey(k), isTrue, reason: 'id.json tidak punya "$k"');
      expect(en.containsKey(k), isTrue, reason: 'en.json tidak punya "$k"');
    }
  });

  test('semua key baru A5+B4 tersedia di kedua file', () {
    const newKeys = [
      'auth_google_cta',
      'auth_verify_banner_title',
      'auth_verify_banner_body',
      'auth_verify_resend_cta',
      'auth_verify_resend_wait',
      'auth_verify_resent',
    ];
    for (final key in newKeys) {
      expect(id.containsKey(key), isTrue, reason: '$key hilang di id.json');
      expect(en.containsKey(key), isTrue, reason: '$key hilang di en.json');
    }
  });
}
