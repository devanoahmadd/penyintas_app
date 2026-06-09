import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/onboarding_keypad.dart';

Widget _pump({required bool isDark}) => MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: MaterialApp(
        home: Scaffold(
          body: OnboardingKeypad(isDark: isDark, onKey: (_) {}),
        ),
      ),
    );

void main() {
  group('applyOnboardingKey', () {
    // --- digit append ---
    test('0 + "5" = 5', () => expect(applyOnboardingKey(0, '5'), 5));
    test('12 + "3" = 123', () => expect(applyOnboardingKey(12, '3'), 123));
    test('append tidak melampaui 9 digit: 99_999_999 + "9" = 999_999_999', () =>
        expect(applyOnboardingKey(99999999, '9'), 999999999));

    // --- back ---
    test('back: 123 → 12', () => expect(applyOnboardingKey(123, 'back'), 12));
    test('back: 1 → 0', () => expect(applyOnboardingKey(1, 'back'), 0));
    test('back: 0 → 0 (no-op)', () => expect(applyOnboardingKey(0, 'back'), 0));

    // --- 000 multiply ---
    test('000: 1 → 1000', () => expect(applyOnboardingKey(1, '000'), 1000));
    test('000 pada 0 → 0 (no leading zero multiply)', () =>
        expect(applyOnboardingKey(0, '000'), 0));
    test('000: 1_000_000 * 1000 > max → stays at 1_000_000', () =>
        expect(applyOnboardingKey(1000000, '000'), 1000000));

    // --- max clamp ---
    test('append di max (999_999_999) + "5" → stays', () =>
        expect(applyOnboardingKey(999999999, '5'), 999999999));
    test('append tepat di batas: 99_999_999 + "9" = 999_999_999', () =>
        expect(applyOnboardingKey(99999999, '9'), 999999999));
  });

  group('OnboardingKeypad — surface token', () {
    testWidgets('light mode: button digit menggunakan surfaceLight', (tester) async {
      await tester.pumpWidget(_pump(isDark: false));

      final allContainers = tester.widgetList<Container>(find.byType(Container));
      final hasSurfaceLight = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.surfaceLight;
      });

      expect(hasSurfaceLight, isTrue,
          reason: 'Minimal satu button digit harus memakai AppColors.surfaceLight di light mode');
    });

    testWidgets('light mode: tidak ada button yang memakai cardLight', (tester) async {
      await tester.pumpWidget(_pump(isDark: false));

      final allContainers = tester.widgetList<Container>(find.byType(Container));
      final hasCardLight = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.cardLight;
      });

      expect(hasCardLight, isFalse,
          reason: 'Tidak boleh ada button yang memakai AppColors.cardLight (token card) di keypad');
    });

    testWidgets('dark mode: button digit menggunakan surfaceDark', (tester) async {
      await tester.pumpWidget(_pump(isDark: true));

      final allContainers = tester.widgetList<Container>(find.byType(Container));
      final hasSurfaceDark = allContainers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.surfaceDark;
      });

      expect(hasSurfaceDark, isTrue,
          reason: 'Minimal satu button digit harus memakai AppColors.surfaceDark di dark mode');
    });
  });
}
