import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';

void main() {
  testWidgets('menekan angka memanggil onDigit', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinKeypad(onDigit: (d) => tapped = d, onBackspace: () {}),
        ),
      ),
    );
    await tester.tap(find.text('5'));
    expect(tapped, '5');
  });

  testWidgets('disabled → onDigit tak dipanggil', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinKeypad(
            onDigit: (d) => tapped = d,
            onBackspace: () {},
            enabled: false,
          ),
        ),
      ),
    );
    await tester.tap(find.text('5'));
    expect(tapped, isNull);
  });
}
