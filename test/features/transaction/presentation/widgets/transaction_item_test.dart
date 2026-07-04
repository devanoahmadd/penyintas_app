import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:penyintas_app/features/transaction/presentation/widgets/transaction_item.dart';

class _FakeL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _FakeL10nDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
        AppLocalizations(locale, const {'category_other': 'Lainnya'}),
      );
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

final _mockTx = TransactionEntity(
  id: 'test-1',
  amount: 80000,
  category: 'other',
  type: TransactionType.expense,
  date: DateTime(2026, 5, 29, 0, 34),
  isFixed: false,
  isSynced: true,
  createdAt: DateTime(2026, 5, 29),
  updatedAt: DateTime(2026, 5, 29),
);

Widget _harness({Brightness brightness = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: const [_FakeL10nDelegate()],
      home: Material(child: TransactionItem(transaction: _mockTx)),
    );

// Finds the outer Container of TransactionItem by its unique padding.
Container _outerContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.padding ==
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

void main() {
  group('TransactionItem — flat style', () {
    testWidgets('light mode: background menggunakan bgLight', (tester) async {
      await tester.pumpWidget(_harness());
      final container = _outerContainer(tester);
      expect(container.decoration, isA<BoxDecoration>());
      final dec = container.decoration as BoxDecoration;
      expect(dec.color, AppColors.bgLight);
    });

    testWidgets('dark mode: background menggunakan bgDark', (tester) async {
      await tester.pumpWidget(_harness(brightness: Brightness.dark));
      final container = _outerContainer(tester);
      expect(container.decoration, isA<BoxDecoration>());
      final dec = container.decoration as BoxDecoration;
      expect(dec.color, AppColors.bgDark);
    });

    testWidgets('tidak ada borderRadius', (tester) async {
      await tester.pumpWidget(_harness());
      final container = _outerContainer(tester);
      expect(container.decoration, isA<BoxDecoration>());
      final dec = container.decoration as BoxDecoration;
      expect(dec.borderRadius, isNull);
    });

    testWidgets('hanya ada bottom border, top/left/right none', (tester) async {
      await tester.pumpWidget(_harness());
      final container = _outerContainer(tester);
      expect(container.decoration, isA<BoxDecoration>());
      final dec = container.decoration as BoxDecoration;
      expect(dec.border, isA<Border>());
      final border = dec.border as Border;
      expect(border.top.style, BorderStyle.none);
      expect(border.left.style, BorderStyle.none);
      expect(border.right.style, BorderStyle.none);
      expect(border.bottom.color, AppColors.borderLight);
      expect(border.bottom.width, 0.8);
    });

    testWidgets('label kategori built-in ter-l10n (slug other → Lainnya)',
        (tester) async {
      await tester.pumpWidget(_harness());
      expect(find.text('LAINNYA'), findsOneWidget); // baris kategori uppercase
      expect(find.text('OTHER'), findsNothing); // slug mentah tak tampil lagi
    });
  });
}
