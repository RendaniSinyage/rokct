import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterSurfacePainter extends CustomPainter {
  final double tiltFactor;
  final Color baseColor;
  final double level;
  final int percentage;

  WaterSurfacePainter({
    required this.tiltFactor,
    required this.baseColor,
    required this.level,
    required this.percentage,
  });

  Color get waterColor {
    if (percentage <= 25) {
      return Colors.red;      // Critical level - Red
    } else if (percentage <= 35) {
      return Colors.orange;   // Warning level - Orange
    } else if (percentage <= 50) {
      return Colors.yellow;   // Caution level - Yellow
    }
    return baseColor;  // Normal level - Original color (Green/Blue)
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waterColor  // Use the calculated color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final waveHeight = 5.0;
      final y = size.height * (1 - level) -
          waveHeight * math.sin((x / size.width) * 4 * math.pi + tiltFactor * math.pi) +
          (tiltFactor * (x - size.width / 2) / 10);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second layer with transparency
    final secondLayerPaint = Paint()
      ..color = waterColor.withOpacity(0.3)  // Use the same calculated color
      ..style = PaintingStyle.fill;

    final secondPath = Path();
    secondPath.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final waveHeight = 3.0;
      final y = size.height * (1 - level) -
          waveHeight * math.sin((x / size.width) * 4 * math.pi + math.pi / 2 + tiltFactor * math.pi) +
          (tiltFactor * (x - size.width / 2) / 12);
      secondPath.lineTo(x, y);
    }

    secondPath.lineTo(size.width, size.height);
    secondPath.close();

    canvas.drawPath(secondPath, secondLayerPaint);
  }

  @override
  bool shouldRepaint(covariant WaterSurfacePainter oldDelegate) =>
      tiltFactor != oldDelegate.tiltFactor ||
          baseColor != oldDelegate.baseColor ||
          level != oldDelegate.level ||
          percentage != oldDelegate.percentage;
}
