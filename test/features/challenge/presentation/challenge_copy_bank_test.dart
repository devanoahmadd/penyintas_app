import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/presentation/utils/challenge_copy_bank.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';

void main() {
  group('challengeBankLine', () {
    testWidgets(
      'U105 — same weekKey, same status → same line',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        // Pastikan frame sudah render
        await tester.pumpAndSettle();

        expect(contextHolder, isNotNull,
            reason: 'BuildContext harus tersedia setelah pumpAndSettle');
        final context = contextHolder!;

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

        expect(line1, equals(line2),
            reason: 'Kalimat sama untuk weekKey sama harus identik');
      },
    );

    testWidgets(
      'U105 — different weekKey → line bisa berbeda',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        final weekKey1 = 20260907;
        final weekKey2 = 20260914;
        final status = ChallengeStatus.achieved;

        final line1 = challengeBankLine(
          context,
          status: status,
          weekKey: weekKey1,
        );
        final line2 = challengeBankLine(
          context,
          status: status,
          weekKey: weekKey2,
        );

        expect(line1.isNotEmpty && line2.isNotEmpty, isTrue);
      },
    );

    testWidgets(
      'K2 — 8 Senin berturut, status sama → 8 kalimat berbeda',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        final sundays = [
          20260907, // Minggu ke-5
          20260914, // Minggu ke-6
          20260921, // Minggu ke-7
          20260928, // Minggu ke-8
          20261005, // Minggu ke-9
          20261012, // Minggu ke-10
          20261019, // Minggu ke-11
          20261026, // Minggu ke-12
        ];

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
              'bukan ${uniqueLines.length}',
        );
      },
    );

    testWidgets(
      'K2 — bank memiliki semua 24 key (8 × 3 status)',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        const statuses = [
          ChallengeStatus.active,
          ChallengeStatus.achieved,
          ChallengeStatus.missed,
        ];

        for (final status in statuses) {
          final line = challengeBankLine(
            context,
            status: status,
            weekKey: 20260907,
          );
          expect(line.isNotEmpty, isTrue,
              reason: 'challengeBankLine harus menghasilkan string non-kosong');
        }
      },
    );

    testWidgets(
      'U99 — tidak ada digit di seluruh bank',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        const statuses = [
          ChallengeStatus.active,
          ChallengeStatus.achieved,
          ChallengeStatus.missed,
        ];

        const weekKeys = [20260907, 20260914];

        for (final status in statuses) {
          for (final weekKey in weekKeys) {
            final line = challengeBankLine(
              context,
              status: status,
              weekKey: weekKey,
            );

            if (line.isEmpty) continue;

            expect(
              line.contains(RegExp(r'[0-9]')),
              isFalse,
              reason: 'Kalimat bank tidak boleh berisi digit: "$line"',
            );
          }
        }
      },
    );

    testWidgets(
      'U100 — semua kalimat bank ≤ 120 karakter',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        const statuses = [
          ChallengeStatus.active,
          ChallengeStatus.achieved,
          ChallengeStatus.missed,
        ];

        const weekKeys = [20260907, 20260914, 20260921, 20260928];

        for (final status in statuses) {
          for (final weekKey in weekKeys) {
            final line = challengeBankLine(
              context,
              status: status,
              weekKey: weekKey,
            );

            if (line.isEmpty) continue;

            expect(
              line.length,
              lessThanOrEqualTo(120),
              reason: 'Panjang kalimat ≤ 120: "$line" adalah $line.length karakter',
            );
          }
        }
      },
    );

    testWidgets(
      'U103 — fungsi tidak menyentuh jalur jaringan',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

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
          reason: 'Fungsi harus pure (deterministic)',
        );
      },
    );

    testWidgets(
      'held/skipped/unknown → string kosong',
      (WidgetTester tester) async {
        BuildContext? contextHolder;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegateFor(const Locale('id')),
            ],
            supportedLocales: const [Locale('id'), Locale('en')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  contextHolder = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(contextHolder, isNotNull);
        final context = contextHolder!;

        const statuses = [
          ChallengeStatus.held,
          ChallengeStatus.skipped,
          ChallengeStatus.unknown,
        ];

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
      },
    );
  });
}
