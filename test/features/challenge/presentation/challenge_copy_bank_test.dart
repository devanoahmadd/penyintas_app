import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_copy_bank.dart';

void main() {
  late Map<String, dynamic> idJson;
  late Map<String, dynamic> enJson;

  setUpAll(() {
    idJson = json.decode(File('assets/translations/id.json').readAsStringSync())
        as Map<String, dynamic>;
    enJson = json.decode(File('assets/translations/en.json').readAsStringSync())
        as Map<String, dynamic>;
  });

  group('bank kalimat', () {
    test('K2 — 24 key ada (8×3 status, 2 bahasa)', () {
      const statuses = ['active', 'achieved', 'missed'];
      final missing = <String>[];
      for (final status in statuses) {
        for (int i = 1; i <= 8; i++) {
          final key = 'challenge_bank_${status}_$i';
          if (!idJson.containsKey(key)) missing.add('$key id');
          if (!enJson.containsKey(key)) missing.add('$key en');
        }
      }
      expect(missing, isEmpty);
    });

    test('U99 — nol digit', () {
      final withDigits = <String>[];
      idJson.forEach((k, v) {
        if (k.startsWith('challenge_bank_') && (v as String).contains(RegExp(r'[0-9]'))) {
          withDigits.add(k);
        }
      });
      enJson.forEach((k, v) {
        if (k.startsWith('challenge_bank_') && (v as String).contains(RegExp(r'[0-9]'))) {
          withDigits.add(k);
        }
      });
      expect(withDigits, isEmpty);
    });

    test('U100 — semua ≤ 120 char', () {
      final tooLong = <String>[];
      idJson.forEach((k, v) {
        if (k.startsWith('challenge_bank_') && (v as String).length > 120) {
          tooLong.add(k);
        }
      });
      enJson.forEach((k, v) {
        if (k.startsWith('challenge_bank_') && (v as String).length > 120) {
          tooLong.add(k);
        }
      });
      expect(tooLong, isEmpty);
    });

    testWidgets('U105 — same weekKey → same line', (WidgetTester tester) async {
      late String line1, line2;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [AppLocalizations.delegateFor(const Locale('id'))],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: Builder(builder: (context) {
          line1 = challengeBankLine(
            context,
            status: ChallengeStatus.achieved,
            weekKey: 20260907,
          );
          line2 = challengeBankLine(
            context,
            status: ChallengeStatus.achieved,
            weekKey: 20260907,
          );
          return const Scaffold(body: SizedBox.shrink());
        }),
      ));
      await tester.pumpAndSettle();

      expect(line1, equals(line2));
    });
  });
}
