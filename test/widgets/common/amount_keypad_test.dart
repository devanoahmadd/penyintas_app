import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/widgets/common/amount_keypad.dart';

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
      body: AmountKeypad(isDark: isDark, onKey: (_) {}),
    ),
  ),
);

// CATATAN: brief awalnya menyarankan `MediaQuery(data: MediaQueryData(...))`
// sebagai pembungkus untuk mengendalikan lebar layar. Terbukti TIDAK bekerja:
// `View` yang disisipkan `tester.pumpWidget` tetap membangun constraint
// layout nyata dari `tester.view.physicalSize`, bukan dari MediaQuery yang
// disisipkan lebih dalam di tree — override macam itu hanya mengubah nilai
// yang dibaca `MediaQuery.of(context)`, bukan constraint GridView yang
// sesungguhnya. Dibuktikan lewat pengukuran manual: hasilnya 108dp, bukan
// 48dp, untuk kasus padding bawaan. Dipakai di sini idiom yang sudah mapan
// di `onboarding_page_test.dart` (file sepupu yang disentuh task yang sama):
// `tester.view.physicalSize` + `devicePixelRatio` — satu-satunya cara yang
// benar-benar mengendalikan constraint nyata sekaligus nilai MediaQuery.
Widget _pumpPad({required double padding}) => MaterialApp(
  localizationsDelegates: [_SyncL10nDelegate(_l10n)],
  locale: const Locale('id'),
  home: Scaffold(
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: padding / 2),
      child: AmountKeypad(isDark: false, onKey: (_) {}),
    ),
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _l10n = await AppLocalizations.delegate.load(const Locale('id'));
    _l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('applyAmountKey', () {
    // --- digit append ---
    test('0 + "5" = 5', () => expect(applyAmountKey(0, '5'), 5));
    test('12 + "3" = 123', () => expect(applyAmountKey(12, '3'), 123));
    test(
      'append tidak melampaui 9 digit: 99_999_999 + "9" = 999_999_999',
      () => expect(applyAmountKey(99999999, '9'), 999999999),
    );

    // --- back ---
    test('back: 123 → 12', () => expect(applyAmountKey(123, 'back'), 12));
    test('back: 1 → 0', () => expect(applyAmountKey(1, 'back'), 0));
    test('back: 0 → 0 (no-op)', () => expect(applyAmountKey(0, 'back'), 0));

    // --- 000 multiply ---
    test('000: 1 → 1000', () => expect(applyAmountKey(1, '000'), 1000));
    test(
      '000 pada 0 → 0 (no leading zero multiply)',
      () => expect(applyAmountKey(0, '000'), 0),
    );
    test(
      '000: 1_000_000 * 1000 > max → stays at 1_000_000',
      () => expect(applyAmountKey(1000000, '000'), 1000000),
    );

    // --- max clamp ---
    test(
      'append di max (999_999_999) + "5" → stays',
      () => expect(applyAmountKey(999999999, '5'), 999999999),
    );
    test(
      'append tepat di batas: 99_999_999 + "9" = 999_999_999',
      () => expect(applyAmountKey(99999999, '9'), 999999999),
    );
  });

  group('AmountKeypad — surface token', () {
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

  group('AmountKeypad — a11y', () {
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

  group('AmountKeypad — kontrak lebar nyata', () {
    testWidgets('panel dengan padding 48: tombol tepat 48dp', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_pumpPad(padding: 48));
      final size = tester.getSize(find.widgetWithText(GestureDetector, '5'));
      expect(size.height, closeTo(48, 0.5));
    });

    testWidgets('panel dengan padding 32 (lebar kolom beda) → TETAP 48dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_pumpPad(padding: 32));
      final size = tester.getSize(find.widgetWithText(GestureDetector, '5'));
      expect(
        size.height,
        closeTo(48, 0.5),
        reason:
            'aspect diturunkan dari constraint nyata `LayoutBuilder` '
            'memberi — bukan dari parameter yang dititipkan pemanggil — jadi '
            'padding panel berapa pun tetap menghasilkan tombol 48dp',
      );
    });

    testWidgets('lanskap ber-notch: tombol TETAP >= 48dp di dalam SafeArea', (
      tester,
    ) async {
      // Lanskap + inset kiri-kanan seperti perangkat ber-notch.
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(left: 44, right: 44);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [_SyncL10nDelegate(_l10n)],
          locale: const Locale('id'),
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AmountKeypad(isDark: false, onKey: (_) {}),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.widgetWithText(GestureDetector, '7')).height,
        greaterThanOrEqualTo(48.0),
        reason:
            'SafeArea meng-inset kiri-kanan di lanskap; menghitung dari '
            'lebar layar penuh membuat tombolnya menyusut diam-diam',
      );
    });
  });
}
