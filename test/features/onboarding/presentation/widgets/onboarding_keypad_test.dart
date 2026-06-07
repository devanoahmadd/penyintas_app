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
