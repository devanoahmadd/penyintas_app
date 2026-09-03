import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/widgets/common/dashed_border_painter.dart';

void main() {
  group('DashedBorderPainter', () {
    test('painter dapat dibuat dengan color dan radius', () {
      const painter = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 8.0,
      );

      expect(painter.color, const Color(0xFF000000));
      expect(painter.radius, 8.0);
    });

    test('shouldRepaint mengembalikan true saat color berubah', () {
      const painter1 = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 8.0,
      );
      const painter2 = DashedBorderPainter(
        color: Color(0xFFFFFFFF),
        radius: 8.0,
      );

      final shouldRepaint = painter1.shouldRepaint(painter2);
      expect(shouldRepaint, isTrue);
    });

    test('shouldRepaint mengembalikan true saat radius berubah', () {
      const painter1 = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 8.0,
      );
      const painter2 = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 12.0,
      );

      final shouldRepaint = painter1.shouldRepaint(painter2);
      expect(shouldRepaint, isTrue);
    });

    test('shouldRepaint mengembalikan false saat tidak ada perubahan', () {
      const painter1 = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 8.0,
      );
      const painter2 = DashedBorderPainter(
        color: Color(0xFF000000),
        radius: 8.0,
      );

      final shouldRepaint = painter1.shouldRepaint(painter2);
      expect(shouldRepaint, isFalse);
    });
  });
}
