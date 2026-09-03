import 'package:flutter/material.dart';

/// Garis tepi putus-putus mengelilingi sebuah rounded-rect.
///
/// Diekstrak dari `dashboard_page.dart` (dulu privat, mustahil diimpor) karena
/// petak "jeda terpakai" di kalender Konsistensi memakai bentuk yang sama —
/// ditulis sekali, dipakai dua tempat.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rRect);

    const dashLen = 5.0;
    const gapLen = 4.0;
    final dashPath = Path();
    for (final pm in path.computeMetrics()) {
      double dist = 0;
      while (dist < pm.length) {
        dashPath.addPath(pm.extractPath(dist, dist + dashLen), Offset.zero);
        dist += dashLen + gapLen;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
