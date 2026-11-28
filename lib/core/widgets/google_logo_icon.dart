import 'package:flutter/material.dart';

/// Ikon resmi Google "G" dengan 4 warna asli (Biru, Merah, Kuning, Hijau)
/// digambar menggunakan CustomPainter sesuai standar branding Google.
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue Arc & Bar
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(46.1, 24.55)
      ..cubicTo(46.1, 22.98, 45.95, 21.46, 45.72, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.7, 29.02)
      ..cubicTo(36.15, 31.89, 34.48, 34.32, 32.0, 35.96)
      ..lineTo(39.73, 41.96)
      ..cubicTo(44.24, 37.78, 46.8, 31.64, 46.1, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Arc (Bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24.0, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow Arc (Left Bottom)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(10.53, 28.58)
      ..cubicTo(10.05, 27.13, 9.77, 25.59, 9.77, 24.0)
      ..cubicTo(9.77, 22.41, 10.05, 20.87, 10.53, 19.42)
      ..lineTo(2.55, 13.23)
      ..cubicTo(0.92, 16.48, 0.0, 20.14, 0.0, 24.0)
      ..cubicTo(0.0, 27.86, 0.92, 31.52, 2.55, 34.77)
      ..lineTo(10.53, 28.58)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red Arc (Top)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(24.0, 9.51)
      ..cubicTo(27.54, 9.51, 30.71, 10.73, 33.21, 13.11)
      ..lineTo(40.06, 6.26)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.55, 13.23)
      ..lineTo(10.53, 19.42)
      ..cubicTo(12.43, 13.73, 17.74, 9.51, 24.0, 9.51)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

