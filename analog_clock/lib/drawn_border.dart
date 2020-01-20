import 'dart:math';

import 'package:flutter/material.dart';

/// Border that is drawn with [CustomPainter]
class DrawnBorder extends StatelessWidget {
  /// All of the parameters are required and must not be null.
  const DrawnBorder({
    @required this.color,
    @required this.thickness,
    @required this.textSize,
    @required this.light,
  })  : assert(color != null),
        assert(thickness != null),
        assert(textSize != null),
        assert(light != null);

  // The color of the border
  final Color color;

  // The thickness of border
  final double thickness;

  //Size of the hour numbers
  final double textSize;

  // Whether light mode is enabled
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: BorderPainter(
            thick: thickness,
            color: color,
            light: light,
            textSize: textSize,
          ),
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws clock border.
class BorderPainter extends CustomPainter {
  BorderPainter({
    @required this.thick,
    @required this.color,
    @required this.light,
    @required this.textSize,
  })  : assert(color != null),
        assert(thick != null),
        assert(thick >= 1.0),
        assert(thick <= 20.0),
        assert(textSize >= 10),
        assert(textSize <= 50);

  double thick;
  double textSize;
  Color color;
  bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset(0, 0) & size).center;
    final length = size.shortestSide * 0.4 + 10;

    // Draw the inner and outer borders of the clock.
    drawClockBorders(canvas, center, length);

    // Draw the numbers that indicates the hours.
    drawNumberPie(canvas, size);

    // Translate to the center to prepare for drawing ticks.
    canvas.translate(center.dx, center.dy);
    drawTicks(canvas, length - thick / 2);
  }

  void drawClockBorders(Canvas canvas, Offset center, double length) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = thick;

    // Clock border
    canvas.drawCircle(center, length, paint);

    // Clock color inside the border
    paint
      ..color = light ? Colors.white : Colors.grey[600]
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, length - thick / 2, paint);
  }

  void drawNumberPie(Canvas canvas, Size size) {
    // Offset so that the number circle is aligned properly.
    final center = (Offset(-textSize / 3.5, -textSize / 1.8) & size).center;
    final cx = center.dx;
    final cy = center.dy;
    final length = size.shortestSide * 0.4 - 12;

    for (int i = 1; i <= 12; i++) {
      TextSpan textSpan = new TextSpan(
        style: new TextStyle(
          color: this.color,
          fontSize: textSize,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
        text: i.toString(),
      );
      TextPainter painter = new TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      painter.layout();

      double angle = pi / 6 * (i - 3);
      double x = cx + cos(angle) * length;
      double y = cy + sin(angle) * length;

      // Center the numbers having more than 1 digit in them.
      if (i > 9) {
        x -= textSize / 3.5;
      }

      painter.paint(canvas, new Offset(x, y));
    }
  }

  void drawTicks(Canvas canvas, double radius) {
    final paint = Paint()..color = color;

    // Rotate by 6 degrees
    // Angle is measured in radians so convert 6 to radius by multiplying with pi/180.
    double angle = 6 * pi / 180;
    for (int i = 0; i < 60; i++) {
      if (i % 5 == 0)
        paint.strokeWidth = thick / 6;
      else
        paint.strokeWidth = thick / 8;
      canvas.drawLine(
        new Offset(0, -radius),
        new Offset(0, -radius + (i % 5 == 0 ? thick / 1.5 : thick / 3)),
        paint,
      );
      canvas.rotate(angle);
    }
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thick != thick;
  }
}
