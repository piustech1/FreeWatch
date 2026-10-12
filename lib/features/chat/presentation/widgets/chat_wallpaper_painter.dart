import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter rendering subtle, low-opacity doodle motifs
/// (chat bubbles, film reels, stars, music, headphones, hearts, clocks)
/// across a dark emerald-tinted canvas to evoke a rich, immersive messaging atmosphere.
class ChatWallpaperPainter extends CustomPainter {
  const ChatWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    const cellWidth = 90.0;
    const cellHeight = 90.0;

    final cols = (size.width / cellWidth).ceil() + 1;
    final rows = (size.height / cellHeight).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * cellWidth + (r % 2 == 1 ? cellWidth / 2 : 0) + 20;
        final cy = r * cellHeight + 25;

        final patternIndex = (r * 3 + c * 5) % 8;
        _drawDoodle(canvas, cx, cy, patternIndex, paint, fillPaint);
      }
    }
  }

  void _drawDoodle(
    Canvas canvas,
    double x,
    double y,
    int index,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    canvas.save();
    canvas.translate(x, y);

    switch (index) {
      case 0:
        // Chat bubble with tail
        final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-11, -8, 22, 16),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, strokePaint);
        final tail = Path()
          ..moveTo(-5, 8)
          ..lineTo(-8, 12)
          ..lineTo(-2, 8);
        canvas.drawPath(tail, strokePaint);
        break;

      case 1:
        // Movie clapper / film reel
        final filmRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -7, 20, 14),
          const Radius.circular(3),
        );
        canvas.drawRRect(filmRect, strokePaint);
        canvas.drawLine(const Offset(-4, -7), const Offset(-4, 7), strokePaint);
        canvas.drawLine(const Offset(4, -7), const Offset(4, 7), strokePaint);
        break;

      case 2:
        // Play button triangle in circle
        canvas.drawCircle(Offset.zero, 9, strokePaint);
        final triangle = Path()
          ..moveTo(-3, -4.5)
          ..lineTo(4.5, 0)
          ..lineTo(-3, 4.5)
          ..close();
        canvas.drawPath(triangle, fillPaint);
        canvas.drawPath(triangle, strokePaint);
        break;

      case 3:
        // Star
        final star = Path();
        for (int i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + (i * 4 * math.pi / 5);
          final px = 7.5 * math.cos(angle);
          final py = 7.5 * math.sin(angle);
          if (i == 0) {
            star.moveTo(px, py);
          } else {
            star.lineTo(px, py);
          }
        }
        star.close();
        canvas.drawPath(star, strokePaint);
        break;

      case 4:
        // Headphones
        canvas.drawArc(
          const Rect.fromLTWH(-7, -8, 14, 14),
          math.pi,
          math.pi,
          false,
          strokePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-9, -2, 4, 7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, -2, 4, 7),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        break;

      case 5:
        // Clock
        canvas.drawCircle(Offset.zero, 8, strokePaint);
        canvas.drawLine(Offset.zero, const Offset(0, -4.5), strokePaint);
        canvas.drawLine(Offset.zero, const Offset(3.5, 0), strokePaint);
        break;

      case 6:
        // Heart
        final heart = Path()
          ..moveTo(0, 3)
          ..cubicTo(-5, -3, -7, -7, 0, -6.5)
          ..cubicTo(7, -7, 5, -3, 0, 3);
        canvas.drawPath(heart, strokePaint);
        break;

      case 7:
        // Musical note
        canvas.drawCircle(const Offset(-3, 4), 3, fillPaint);
        canvas.drawCircle(const Offset(-3, 4), 3, strokePaint);
        canvas.drawLine(const Offset(0, 4), const Offset(0, -6), strokePaint);
        canvas.drawLine(const Offset(0, -6), const Offset(5, -4), strokePaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
