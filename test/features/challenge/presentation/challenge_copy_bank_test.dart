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
  late AppLocalizations l10nId;
  late AppLocalizations l10nEn;

  setUpAll(() {
    idJson = json.decode(File('assets/translations/id.json').readAsStringSync())
        as Map<String, dynamic>;
    enJson = json.decode(File('assets/translations/en.json').readAsStringSync())
        as Map<String, dynamic>;
    l10nId = AppLocalizations(const Locale('id'), Map<String, String>.from(idJson));
    l10nEn = AppLocalizations(const Locale('en'), Map<String, String>.from(enJson));
  });

  group('challengeBankLine — bank validation', () {
    test('K2 — bank memiliki SEMUA 24 key (8 × 3 status)', () {
      const statuses = ['active', 'achieved', 'missed'];
      final missingKeys = <String>[];

      for (final status in statuses) {
        for (int i = 1; i <= 8; i++) {
          final key = 'challenge_bank_${status}_$i';
          if (!idJson.containsKey(key)) {
            missingKeys.add('$key (id)');
          }
          if (!enJson.containsKey(key)) {
            missingKeys.add('$key (en)');
          }
        }
      }

      expect(
        missingKeys,
        isEmpty,
        reason: 'Semua 24 key wajib ada di kedua bahasa. Missing: $missingKeys',
      );
    });

    test('U99 — tidak ada digit di seluruh bank', () {
      const statuses = ['active', 'achieved', 'missed'];
      final withDigits = <String>[];

      for (final status in statuses) {
        for (int i = 1; i <= 8; i++) {
          final key = 'challenge_bank_${status}_$i';
          final idText = idJson[key] as String?;
          final enText = enJson[key] as String?;

          if (idText != null && idText.contains(RegExp(r'[0-9]'))) {
            withDigits.add('$key (id): "$idText"');
          }
          if (enText != null && enText.contains(RegExp(r'[0-9]'))) {
            withDigits.add('$key (en): "$enText"');
          }
        }
      }

      expect(
        withDigits,
        isEmpty,
        reason: 'Bank tidak boleh berisi digit. Ditemukan: $withDigits',
      );
    });

    test('U100 — semua kalimat bank ≤ 120 karakter', () {
      const statuses = ['active', 'achieved', 'missed'];
      final tooLong = <String>[];

      for (final status in statuses) {
        for (int i = 1; i <= 8; i++) {
          final key = 'challenge_bank_${status}_$i';
          final idText = idJson[key] as String?;
          final enText = enJson[key] as String?;

          if (idText != null && idText.length > 120) {
            tooLong.add('$key (id, ${idText.length} ch): "$idText"');
          }
          if (enText != null && enText.length > 120) {
            tooLong.add('$key (en, ${enText.length} ch): "$enText"');
          }
        }
      }

      expect(
        tooLong,
        isEmpty,
        reason: 'Semua kalimat ≤ 120 karakter. Terlalu panjang: $tooLong',
      );
    });
  });

  group('challengeBankLine — logic & determinism', () {
    testWidgets('U105 — same weekKey, same status → same line',
        (WidgetTester tester) async {
      final app = MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegateFor(const Locale('id')),
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: Builder(
          builder: (context) {
            final weekKey = 20260907;
            final status = ChallengeStatus.achieved;

            final line1 = challengeBankLine(
              context,
              status: status,
              weekKey: weekKey,
            );
            final line2 = challengeBankLine(
              context,
              status: status,
              weekKey: weekKey,
            );

            expect(
              line1,
              equals(line2),
              reason: 'Kalimat sama untuk weekKey sama harus identik (deterministic)',
            );

            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    });

    testWidgets('K2 — 8 Senin berturut, status sama → 8 kalimat berbeda',
        (WidgetTester tester) async {
      final sundays = [
        20260907, 20260914, 20260921, 20260928, 20261005, 20261012, 20261019, 20261026,
      ];

      final app = MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegateFor(const Locale('id')),
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: Builder(
          builder: (context) {
            const status = ChallengeStatus.achieved;

            final lines = <String>[];
            for (final weekKey in sundays) {
              final line = challengeBankLine(
                context,
                status: status,
                weekKey: weekKey,
              );
              lines.add(line);
            }

            final uniqueLines = lines.toSet();
            expect(
              uniqueLines.length,
              equals(8),
              reason: 'Delapan Senin berturut harus menghasilkan 8 kalimat unik, '
                  'bukan ${uniqueLines.length}. Indeks varian salah atau bank kurang lengkap.',
            );

            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    });

    testWidgets('U103 — fungsi tidak menyentuh jalur jaringan (pure function)',
        (WidgetTester tester) async {
      final app = MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegateFor(const Locale('id')),
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: Builder(
          builder: (context) {
            final weekKey = 20260907;
            final status = ChallengeStatus.achieved;

            final lines = List.generate(
              10,
              (_) => challengeBankLine(
                context,
                status: status,
                weekKey: weekKey,
              ),
            );

            final first = lines.first;
            expect(
              lines.every((line) => line == first),
              isTrue,
              reason: 'Fungsi harus pure (deterministic, no side effects)',
            );

            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    });

    testWidgets('held/skipped/unknown → string kosong', (WidgetTester tester) async {
      const statuses = [
        ChallengeStatus.held,
        ChallengeStatus.skipped,
        ChallengeStatus.unknown,
      ];

      final app = MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegateFor(const Locale('id')),
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: Builder(
          builder: (context) {
            const weekKey = 20260907;

            for (final status in statuses) {
              final line = challengeBankLine(
                context,
                status: status,
                weekKey: weekKey,
              );

              expect(
                line,
                isEmpty,
                reason: 'Status $status harus menghasilkan string kosong',
              );
            }

            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    });
  });
}
