// test/features/profile/presentation/widgets/country_picker_test.dart
//
// Widget test untuk CountryPicker — TDD.
// Kontrak keys: country_search.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/country_picker.dart';

// Finder yang hanya cocok widget Text (bukan EditableText / TextField)
Finder findListItemText(String text) =>
    find.byWidgetPredicate((w) => w is Text && w.data == text);

Widget buildInScaffold(Widget child) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Scaffold(
          body: SizedBox(width: 400, height: 800, child: child),
        ),
      ),
    );

void main() {
  group('CountryPicker — search field', () {
    testWidgets('search field memiliki key country_search', (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('country_search')), findsOneWidget);
    });
  });

  group('CountryPicker — search filter', () {
    testWidgets('search memfilter — Singapura muncul, Indonesia hilang',
        (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const Key('country_search')), 'Singapura');
      await t.pumpAndSettle();

      expect(findListItemText('Singapura'), findsOneWidget);
      expect(findListItemText('Indonesia'), findsNothing);
    });

    testWidgets('search case-insensitive', (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const Key('country_search')), 'singapura');
      await t.pumpAndSettle();

      expect(findListItemText('Singapura'), findsOneWidget);
    });

    testWidgets('search dengan kode alpha-2 memfilter daftar', (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const Key('country_search')), 'SG');
      await t.pumpAndSettle();

      expect(findListItemText('Singapura'), findsOneWidget);
    });

    testWidgets('search tidak ada hasil → pesan empty state', (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      await t.enterText(
          find.byKey(const Key('country_search')), 'XYZXYZXYZ');
      await t.pumpAndSettle();

      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
    });
  });

  group('CountryPicker — TIDAK menampilkan flag emoji (N2)', () {
    testWidgets('tidak ada flag emoji setelah filter Indonesia', (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const Key('country_search')), 'Indonesia');
      await t.pumpAndSettle();

      final allText = t
          .widgetList(find.byType(Text))
          .cast<Text>()
          .map((w) => w.data ?? '')
          .join();

      final hasFlag =
          RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true).hasMatch(allText);
      expect(hasFlag, isFalse);
    });
  });

  group('CountryPicker — cakupan negara timezone dataset', () {
    // 19 negara wajib dari dataset timezone
    final kodeWajib = {
      'AE': 'Uni Emirat Arab',
      'AU': 'Australia',
      'CA': 'Kanada',
      'DE': 'Jerman',
      'EG': 'Mesir',
      'GB': 'Inggris',
      'HK': 'Hong Kong',
      'ID': 'Indonesia',
      'JP': 'Jepang',
      'KR': 'Korea Selatan',
      'MY': 'Malaysia',
      'NL': 'Belanda',
      'NZ': 'Selandia Baru',
      'QA': 'Qatar',
      'RU': 'Rusia',
      'SA': 'Arab Saudi',
      'SG': 'Singapura',
      'TW': 'Taiwan',
      'US': 'Amerika Serikat',
    };

    testWidgets('semua 19 negara timezone dataset tersedia via search',
        (t) async {
      await t.pumpWidget(buildInScaffold(const CountryPicker()));
      await t.pumpAndSettle();

      for (final entry in kodeWajib.entries) {
        // Filter by kode alpha-2 untuk presisi
        await t.enterText(find.byKey(const Key('country_search')), entry.key);
        await t.pumpAndSettle();
        expect(
          findListItemText(entry.value),
          findsOneWidget,
          reason: 'Negara "${entry.value}" (${entry.key}) harus ada',
        );
        // Reset
        await t.enterText(find.byKey(const Key('country_search')), '');
        await t.pumpAndSettle();
      }
    });
  });

  group('CountryPicker — hasil pop', () {
    testWidgets('tap negara via filter → Navigator.pop kode alpha-2',
        (t) async {
      dynamic popResult;

      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                popResult = await Navigator.of(ctx).push<dynamic>(
                  MaterialPageRoute(
                    builder: (_) => MediaQuery(
                      data: const MediaQueryData(size: Size(400, 800)),
                      child: const Scaffold(body: CountryPicker()),
                    ),
                  ),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      ));

      await t.tap(find.text('Buka'));
      await t.pumpAndSettle();

      // Filter ke Singapura agar hanya 1 item kota muncul
      await t.enterText(
          find.byKey(const Key('country_search')), 'Singapura');
      await t.pumpAndSettle();

      await t.tap(findListItemText('Singapura'));
      await t.pumpAndSettle();

      expect(popResult, equals('SG'));
    });
  });
}
