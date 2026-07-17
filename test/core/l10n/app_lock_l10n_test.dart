import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const keys = [
    'settings_section_security',
    'applock_toggle_title',
    'applock_toggle_subtitle',
    'applock_biometric_title',
    'applock_biometric_subtitle',
    'applock_change_pin',
    'applock_set_title',
    'applock_set_subtitle',
    'applock_confirm_title',
    'applock_confirm_subtitle',
    'applock_mismatch',
    'applock_enter_title',
    'applock_wrong',
    'applock_locked_wait',
    'applock_forgot',
    'applock_forgot_dialog_title',
    'applock_forgot_dialog_body',
    'applock_forgot_confirm',
    'applock_biometric_reason',
    'applock_verify_to_disable',
    'applock_change_current',
  ];

  for (final lang in ['id', 'en']) {
    test('$lang.json memuat semua key App Lock', () async {
      final raw = await rootBundle.loadString('assets/translations/$lang.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final k in keys) {
        expect(
          map.containsKey(k),
          isTrue,
          reason: '$lang.json kekurangan "$k"',
        );
      }
    });
  }
}
