import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';

/// Delegate sinkron — `rootBundle` hang di test ke-2+ bila l10n dimuat async
/// per-pump. Preload sekali di setUpAll, lalu suapkan instance yang sama.
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _value;
  @override
  bool shouldReload(_) => false;
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  Future<void> pumpKeypad(
    WidgetTester tester, {
    required void Function(String) onDigit,
    VoidCallback? onBackspace,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        home: Scaffold(
          body: PinKeypad(
            onDigit: onDigit,
            onBackspace: onBackspace ?? () {},
            enabled: enabled,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('menekan angka memanggil onDigit', (tester) async {
    String? tapped;
    await pumpKeypad(tester, onDigit: (d) => tapped = d);
    await tester.tap(find.text('5'));
    expect(tapped, '5');
  });

  testWidgets('disabled → onDigit tak dipanggil', (tester) async {
    String? tapped;
    await pumpKeypad(tester, onDigit: (d) => tapped = d, enabled: false);
    await tester.tap(find.text('5'));
    expect(tapped, isNull);
  });

  testWidgets(
    'tombol backspace punya label semantics dari l10n (ikon tanpa teks — tanpa '
    'ini screen reader tak tahu tombol mana yang menghapus digit salah)',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKeypad(tester, onDigit: (_) {});

      expect(find.bySemanticsLabel(l10n.applockBackspace), findsOneWidget);

      handle.dispose();
    },
  );
}
