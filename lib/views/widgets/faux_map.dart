import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Illustrated stand-in for the live map while en route, mirroring the
/// design's SVG placeholder (blocks, roads, a dashed marching route, a gold
/// destination pin, and a plum rider marker). A real app should replace this
/// with a Google Maps / Mapbox view driven by the rider's live location and
/// turn-by-turn directions to [destinationIcon]'s address.
class FauxMap extends StatefulWidget {
  final IconData destinationIcon;
  const FauxMap({super.key, this.destinationIcon = Icons.restaurant_outlined});

  @override
  State<FauxMap> createState() => _FauxMapState();
}

class _FauxMapState extends State<FauxMap> with SingleTickerProviderStateMixin {
  late final AnimationController _dash = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _dash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _dash,
        builder: (context, _) => CustomPaint(
          painter: _MapPainter(dashPhase: _dash.value, destinationIcon: widget.destinationIcon),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final double dashPhase;
  final IconData destinationIcon;
  _MapPainter({required this.dashPhase, required this.destinationIcon});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 392;
    final sy = size.height / 378;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawRect(const Rect.fromLTWH(0, 0, 392, 378), Paint()..color = const Color(0xFFE7DED3));

    final greenArea = Path()
      ..moveTo(0, 250)
      ..quadraticBezierTo(90, 220, 150, 258)
      ..relativeQuadraticBezierTo(60, -6, 242, -18)
      ..lineTo(392, 378)
      ..lineTo(0, 378)
      ..close();
    canvas.drawPath(greenArea, Paint()..color = const Color(0xFFD8E4CD));

    final blueArea = Path()
      ..moveTo(255, -10)
      ..quadraticBezierTo(300, 60, 268, 120)
      ..quadraticBezierTo(240, 175, 300, 210)
      ..lineTo(392, 210)
      ..lineTo(392, -10)
      ..close();
    canvas.drawPath(blueArea, Paint()..color = const Color(0xFFCFE0E8).withValues(alpha: 0.9));

    final blockPaint = Paint()..color = const Color(0xFFEFE8DE);
    for (final r in const [
      Rect.fromLTWH(24, 40, 70, 52),
      Rect.fromLTWH(110, 30, 58, 46),
      Rect.fromLTWH(40, 150, 64, 60),
      Rect.fromLTWH(150, 300, 72, 58),
      Rect.fromLTWH(300, 290, 70, 70),
      Rect.fromLTWH(326, 120, 52, 60),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)), blockPaint);
    }

    final roadPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void road(Offset a, Offset b, double w) {
      roadPaint.strokeWidth = w;
      canvas.drawLine(a, b, roadPaint);
    }
    road(const Offset(-10, 120), const Offset(402, 120), 15);
    road(const Offset(-10, 268), const Offset(402, 268), 13);
    road(const Offset(120, -10), const Offset(120, 392), 14);
    road(const Offset(262, -10), const Offset(262, 392), 11);
    road(const Offset(40, -10), const Offset(40, 392), 9);

    final route = Path()
      ..moveTo(70, 328)
      ..cubicTo(110, 300, 96, 232, 150, 210)
      ..cubicTo(190, 195, 250, 150, 300, 84);

    canvas.drawPath(route, Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round);

    final dashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_dashedPath(route, 1, 13, dashPhase * 14), dashPaint);

    // destination pin
    canvas.save();
    canvas.translate(300, 84 - 20);
    final pinPath = Path()
      ..moveTo(0, 26)
      ..cubicTo(-15, 26, -22, 14, -22, 5)
      ..arcToPoint(const Offset(22, 5), radius: const Radius.circular(22), clockwise: true)
      ..cubicTo(22, 14, 15, 26, 0, 26)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = AppColors.gold);
    canvas.drawPath(pinPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(destinationIcon.codePoint),
        style: TextStyle(fontSize: 17, fontFamily: destinationIcon.fontFamily, package: destinationIcon.fontPackage, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -11 - tp.height / 2));
    canvas.restore();

    // rider marker
    canvas.drawCircle(const Offset(70, 328), 17, Paint()..color = AppColors.accent.withValues(alpha: 0.18));
    canvas.drawCircle(const Offset(70, 328), 9, Paint()..color = AppColors.accent);
    canvas.drawCircle(const Offset(70, 328), 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);

    canvas.restore();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.22),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x470D2D41), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.22)),
    );
  }

  Path _dashedPath(Path source, double dashWidth, double dashGap, double phase) {
    final dashPath = Path();
    for (final metric in source.computeMetrics()) {
      var distance = -phase % (dashWidth + dashGap);
      while (distance < metric.length) {
        final start = math.max(distance, 0.0);
        final end = math.min(distance + dashWidth, metric.length);
        if (end > start) dashPath.addPath(metric.extractPath(start, end), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.dashPhase != dashPhase || oldDelegate.destinationIcon != destinationIcon;
}
