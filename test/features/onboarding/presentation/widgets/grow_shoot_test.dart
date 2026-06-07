import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/grow_shoot.dart';

Widget _pump({required bool isDark, double grow = 1.0}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: GrowShoot(grow: grow, size: 108, isDark: isDark),
        ),
      ),
    );

void main() {
  testWidgets('dark mode: background menggunakan cardDark', (tester) async {
    await tester.pumpWidget(_pump(isDark: true));
    await tester.pump(const Duration(milliseconds: 350));

    // The first ColoredBox inside GrowShoot is the background surface.
    // (The second one belongs to the soil strip Container.)
    final boxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(GrowShoot),
        matching: find.byType(ColoredBox),
      ),
    );
    final bgBox = boxes.first;
    expect(
      bgBox.color,
      AppColors.cardDark,
      reason:
          'GrowShoot dark mode harus pakai cardDark (#1C3526), bukan surfaceDark (#15301F)',
    );
  });

  testWidgets('light mode: background menggunakan cardLight', (tester) async {
    await tester.pumpWidget(_pump(isDark: false));
    await tester.pump(const Duration(milliseconds: 350));

    // The first ColoredBox inside GrowShoot is the background surface.
    final boxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(GrowShoot),
        matching: find.byType(ColoredBox),
      ),
    );
    final bgBox = boxes.first;
    expect(
      bgBox.color,
      AppColors.cardLight,
      reason: 'GrowShoot light mode harus pakai cardLight (#F4F0E7)',
    );
  });
}
