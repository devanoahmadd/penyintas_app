import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/widgets/common/count_up_text.dart';

void main() {
  group('CountUpText', () {
    testWidgets('menampilkan nilai dengan format callback', (tester) async {
      const testValue = 42;
      const testStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountUpText(
              value: testValue,
              style: testStyle,
              format: (val) => 'Nilai: $val',
            ),
          ),
        ),
      );

      expect(find.text('Nilai: 42'), findsOneWidget);
    });

    testWidgets('menganimasi nilai dari lama ke baru', (tester) async {
      const testStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountUpText(
              value: 0,
              style: testStyle,
              format: (val) => val.toString(),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Ubah nilai
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountUpText(
              value: 100,
              style: testStyle,
              format: (val) => val.toString(),
            ),
          ),
        ),
      );

      // Tunggu animasi selesai (420ms)
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('menggunakan format callback untuk menampilkan teks', (tester) async {
      const testStyle = TextStyle(fontSize: 16);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountUpText(
              value: 5000,
              style: testStyle,
              format: (val) => 'Rp $val',
            ),
          ),
        ),
      );

      expect(find.text('Rp 5000'), findsOneWidget);
    });
  });
}
