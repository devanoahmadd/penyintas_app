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

      // Ubah nilai ke 100
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

      // Asersi frame antara — animasi sudah dimulai tapi belum selesai
      // Tunggu 150ms (dari total 420ms), nilai harus di antara 0 dan 100
      await tester.pump(const Duration(milliseconds: 150));

      final textWidget = tester.widget<Text>(find.byType(Text));
      final displayedValue = int.parse(textWidget.data ?? '0');

      // Asersi bahwa animasi sedang berjalan: nilai harus strictly di antara 0 dan 100
      expect(
        displayedValue,
        greaterThan(0),
        reason: 'Nilai harus > 0 (sudah bergerak dari awal 0)',
      );
      expect(
        displayedValue,
        lessThan(100),
        reason: 'Nilai harus < 100 (animasi belum selesai)',
      );

      // Tunggu animasi selesai (420ms total)
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('menggunakan format callback untuk menampilkan teks', (
      tester,
    ) async {
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
