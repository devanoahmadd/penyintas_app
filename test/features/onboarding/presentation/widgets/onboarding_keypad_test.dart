import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_keypad.dart';

/// Delegate sinkron — l10n di-preload sekali di setUpAll (`rootBundle` hang
/// bila dimuat async per-pump), lalu instance yang sama disuapkan lewat
/// [SynchronousFuture]. `SynchronousFuture` penting: `Localizations` mendeteksi
/// future yang sudah selesai dan memuatnya di frame yang SAMA, sehingga test
/// existing yang `pumpWidget` sekali (tanpa pump susulan) tetap jalan apa adanya.
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(_value);
  @override
  bool shouldReload(_) => false;
}

late AppLocalizations _l10n;
late AppLocalizations _l10nEn;

Widget _pump({required bool isDark, AppLocalizations? l10n}) => MediaQuery(
  data: const MediaQueryData(size: Size(390, 844)),
  child: MaterialApp(
    localizationsDelegates: [_SyncL10nDelegate(l10n ?? _l10n)],
    locale: Locale(l10n == null ? 'id' : 'en'),
    home: Scaffold(
      body: OnboardingKeypad(isDark: isDark, onKey: (_) {}),
    ),
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _l10n = await AppLocalizations.delegate.load(const Locale('id'));
    _l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('applyOnboardingKey', () {
    // --- digit append ---
    test('0 + "5" = 5', () => expect(applyOnboardingKey(0, '5'), 5));
    test('12 + "3" = 123', () => expect(applyOnboardingKey(12, '3'), 123));
    test(
      'append tidak melampaui 9 digit: 99_999_999 + "9" = 999_999_999',
      () => expect(applyOnboardingKey(99999999, '9'), 999999999),
    );

    // --- back ---
    test('back: 123 → 12', () => expect(applyOnboardingKey(123, 'back'), 12));
    test('back: 1 → 0', () => expect(applyOnboardingKey(1, 'back'), 0));
    test('back: 0 → 0 (no-op)', () => expect(applyOnboardingKey(0, 'back'), 0));

    // --- 000 multiply ---
    test('000: 1 → 1000', () => expect(applyOnboardingKey(1, '000'), 1000));
    test(
      '000 pada 0 → 0 (no leading zero multiply)',
      () => expect(applyOnboardingKey(0, '000'), 0),
    );
    test(
      '000: 1_000_000 * 1000 > max → stays at 1_000_000',
      () => expect(applyOnboardingKey(1000000, '000'), 1000000),
    );

    // --- max clamp ---
    test(
      'append di max (999_999_999) + "5" → stays',
      () => expect(applyOnboardingKey(999999999, '5'), 999999999),
    );
    test(
      'append tepat di batas: 99_999_999 + "9" = 999_999_999',
      () => expect(applyOnboardingKey(99999999, '9'), 999999999),
    );
  });

  group('OnboardingKeypad — surface token', () {
    testWidgets('light mode: button digit menggunakan surfaceLight', (
      tester,
    ) async {
      await tester.pumpWidget(_pump(isDark: false));

      final allContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final hasSurfaceLight = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.surfaceLight;
      });

      expect(
        hasSurfaceLight,
        isTrue,
        reason:
            'Minimal satu button digit harus memakai AppColors.surfaceLight di light mode',
      );
    });

    testWidgets('light mode: tidak ada button yang memakai cardLight', (
      tester,
    ) async {
      await tester.pumpWidget(_pump(isDark: false));

      final allContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final hasCardLight = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.cardLight;
      });

      expect(
        hasCardLight,
        isFalse,
        reason:
            'Tidak boleh ada button yang memakai AppColors.cardLight (token card) di keypad',
      );
    });

    testWidgets('dark mode: button digit menggunakan surfaceDark', (
      tester,
    ) async {
      await tester.pumpWidget(_pump(isDark: true));

      final allContainers = tester.widgetList<Container>(
        find.byType(Container),
      );
      final hasSurfaceDark = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.surfaceDark;
      });

      expect(
        hasSurfaceDark,
        isTrue,
        reason:
            'Minimal satu button digit harus memakai AppColors.surfaceDark di dark mode',
      );
    });
  });

  group('OnboardingKeypad — a11y', () {
    testWidgets('label semantics backspace ada (locale ID)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_pump(isDark: false));

      expect(find.bySemanticsLabel(_l10n.commonBackspace), findsOneWidget);

      handle.dispose();
    });

    // Test PENJAGA: locale EN-lah yang membedakan l10n dari hardcode. Di locale
    // ID nilainya kebetulan sama ('Hapus'), jadi test ID saja TIDAK akan merah
    // bila seseorang mengembalikannya jadi hardcode — sudah dibuktikan lewat
    // uji mutasi. Label ini DIBACAKAN screen reader: user EN yang mendengar
    // "Hapus" tak punya konteks visual untuk menebaknya.
    testWidgets('locale EN: label backspace "Delete", bukan hardcode "Hapus"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_pump(isDark: false, l10n: _l10nEn));

      expect(find.bySemanticsLabel(_l10nEn.commonBackspace), findsOneWidget);
      expect(find.bySemanticsLabel('Hapus'), findsNothing);

      handle.dispose();
    });
  });
}
