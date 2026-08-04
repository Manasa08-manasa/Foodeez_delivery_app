import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';

/// Final Rider splash — matches brand mockup:
/// navy grid, gold route draw, pin drop with Rider logo, RIDER + tagline.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _durationMs = 3200;
  static const _logoAsset = 'assets/images/Rider_logo.png';
  static const _bg = Color(0xFF0A0E14);

  late final AnimationController _c;
  late final Animation<double> _pathDraw;
  late final Animation<double> _pinDrop;
  late final Animation<double> _textIn;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );

    _pathDraw = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.48, curve: Curves.easeInOutCubic),
    );
    _pinDrop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.42, 0.70, curve: Curves.elasticOut),
    );
    _textIn = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.58, 0.86, curve: Curves.easeOutCubic),
    );

    _c.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage(_logoAsset), context);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final titleSize = Responsive.fontSize(context, 48);
    final taglineSize = Responsive.fontSize(context, 11);

    final gW = math.min(
      screen.width * 0.82,
      Responsive.isTablet(context) ? 340.0 : 300.0,
    );
    final gH = gW * 1.22;

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.3,
                    colors: [
                      Color(0xFF111722),
                      _bg,
                      Color(0xFF05070C),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              const CustomPaint(
                painter: _GridPainter(),
                size: Size.infinite,
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    SizedBox(
                      width: gW,
                      height: gH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(gW, gH),
                            painter: _RoutePainter(
                              progress: _pathDraw.value,
                              pinLanded: _pinDrop.value > 0.3,
                            ),
                          ),
                          _PinWidget(
                            progress: _pathDraw.value,
                            drop: _pinDrop.value,
                            size: Size(gW, gH),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    Transform.translate(
                      offset: Offset(0, (1 - _textIn.value) * 18),
                      child: Opacity(
                        opacity: _textIn.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (b) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFF6E4A8),
                                  Color(0xFFE2C46A),
                                  Color(0xFFC49A2C),
                                  Color(0xFF9A6E1A),
                                ],
                                stops: [0.0, 0.35, 0.7, 1.0],
                              ).createShader(b),
                              child: Text(
                                'RIDER',
                                style: AppText.display(
                                  size: titleSize,
                                  weight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'RIDE  ·  DELIVER  ·  EARN',
                              style: AppText.body(
                                size: taglineSize,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                                letterSpacing: 3.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.isTablet(context) ? 64 : 52),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Route geometry (normalized to graphic bounds)
// Start: lower-left · End tip: upper-center under pin
const _sx = 0.16;
const _sy = 0.90;
const _ex = 0.50;
const _ey = 0.22;

Path _buildRoute(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * _sx, h * _sy)
    ..cubicTo(
      w * 0.38,
      h * 0.82,
      w * 0.82,
      h * 0.74,
      w * 0.68,
      h * 0.52,
    )
    ..cubicTo(
      w * 0.56,
      h * 0.34,
      w * 0.42,
      h * 0.28,
      w * _ex,
      h * _ey,
    );
}

/// Faint 3×4 map grid.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2C3648).withValues(alpha: 0.38)
      ..strokeWidth = 0.7;

    final col = size.width / 3;
    final row = size.height / 4;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(col * i, 0), Offset(col * i, size.height), p);
    }
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(0, row * i), Offset(size.width, row * i), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws the gold route + start dot + soft ground ring under pin.
class _RoutePainter extends CustomPainter {
  final double progress;
  final bool pinLanded;

  _RoutePainter({required this.progress, required this.pinLanded});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildRoute(size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final len = m.length;

    // Ghost route
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE8C767).withValues(alpha: 0.10),
    );

    // Start terminal
    final start = m.getTangentForOffset(0);
    if (start != null) {
      canvas.drawCircle(
        start.position,
        5.5,
        Paint()..color = const Color(0xFFE8C767),
      );
    }

    if (progress > 0) {
      final drawn = m.extractPath(0, len * progress.clamp(0.0, 1.0));

      // Soft under-glow
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFE8C767).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Main gold stroke
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            Offset(size.width * _sx, size.height * _sy),
            Offset(size.width * _ex, size.height * _ey),
            const [
              Color(0xFFF3D98A),
              Color(0xFFE2C46A),
              Color(0xFFC9A227),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );

      // Travelling tip while drawing (disappears when complete)
      if (progress < 0.985) {
        final tip = m.getTangentForOffset(len * progress);
        if (tip != null) {
          canvas.drawCircle(
            tip.position,
            4.5,
            Paint()..color = const Color(0xFFF3D98A),
          );
        }
      }
    }

    // Soft ground ring under pin tip (matches brand screenshot)
    if (pinLanded) {
      final end = m.getTangentForOffset(len);
      if (end != null) {
        final c = end.position.translate(0, 3);
        // Soft fill
        canvas.drawCircle(
          c,
          14,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Thin ring (matching reference under pin tip)
        canvas.drawCircle(
          c,
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: 0.10),
        );
        canvas.drawCircle(
          c,
          16,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: 0.05),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.progress != progress || old.pinLanded != pinLanded;
}

/// Map pin matching the brand mock: gold teardrop frame + circular logo face.
class _PinWidget extends StatelessWidget {
  final double progress;
  final double drop;
  final Size size;

  const _PinWidget({
    required this.progress,
    required this.drop,
    required this.size,
  });

  // ViewBox 100 × 130 — classic tall location pin
  static const pinW = 92.0;
  static const pinH = 120.0;

  // Circular face geometry (in pin local coords) — matches _mapPinPath head
  static double get faceCx => pinW * 0.50;
  static double get faceCy => pinH * (48 / 130); // center of rounded head
  static double get holeR => pinW * 0.30; // large black circle, thick gold rim

  @override
  Widget build(BuildContext context) {
    final appear = ((progress - 0.40) / 0.22).clamp(0.0, 1.0);
    if (appear <= 0) return const SizedBox.shrink();

    final scale = drop.clamp(0.0, 1.12);
    final lift = (1 - drop.clamp(0.0, 1.0)) * -40.0;

    final logoD = holeR * 2;
    final logoLeft = faceCx - holeR;
    final logoTop = faceCy - holeR;

    final x = size.width * _ex;
    final y = size.height * _ey;

    return Positioned(
      left: x - pinW / 2,
      top: y - pinH + lift,
      child: Opacity(
        opacity: (appear * scale.clamp(0.0, 1.0)).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: pinW,
            height: pinH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gold teardrop pin shell
                CustomPaint(
                  size: const Size(pinW, pinH),
                  painter: _PinPainter(
                    faceCx: faceCx,
                    faceCy: faceCy,
                    holeRadius: holeR,
                  ),
                ),
                // Logo in the circular face
                Positioned(
                  left: logoLeft,
                  top: logoTop,
                  width: logoD,
                  height: logoD,
                  child: ClipOval(
                    child: ColoredBox(
                      color: const Color(0xFF05080E),
                      child: Image.asset(
                        'assets/images/Rider_logo.png',
                        width: logoD,
                        height: logoD,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.58),
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            'F',
                            style: AppText.display(
                              size: logoD * 0.48,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Classic location-pin path — rounded head, long pointed tip.
/// ViewBox logical units: 0..100 × 0..130
Path _mapPinPath(Size size) {
  final sx = size.width / 100.0;
  final sy = size.height / 130.0;

  // Clean teardrop matching the brand screenshot:
  // near-circle head (0..100, ~0..96) tapering to a sharp tip at (50, 128)
  return Path()
    ..moveTo(50 * sx, 2 * sy)
    // Top-left quarter → left side of head
    ..cubicTo(27 * sx, 2 * sy, 8 * sx, 18 * sy, 8 * sx, 48 * sy)
    // Left shoulder tapering down into the point
    ..cubicTo(8 * sx, 72 * sy, 32 * sx, 100 * sy, 50 * sx, 128 * sy)
    // Right shoulder up from the point
    ..cubicTo(68 * sx, 100 * sy, 92 * sx, 72 * sy, 92 * sx, 48 * sy)
    // Right head → top
    ..cubicTo(92 * sx, 18 * sy, 73 * sx, 2 * sy, 50 * sx, 2 * sy)
    ..close();
}

/// Gold pin body with circular logo cutout + soft tip shadow.
class _PinPainter extends CustomPainter {
  final double faceCx;
  final double faceCy;
  final double holeRadius;

  const _PinPainter({
    required this.faceCx,
    required this.faceCy,
    required this.holeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pin = _mapPinPath(size);
    final center = Offset(faceCx, faceCy);

    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius));

    final shell = Path.combine(PathOperation.difference, pin, hole);

    // Drop shadow under pin body
    canvas.drawPath(
      pin.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Gold gradient shell (thick frame like the reference)
    canvas.drawPath(
      shell,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.2, 0),
          Offset(size.width * 0.8, size.height),
          const [
            Color(0xFFF5E0A0),
            Color(0xFFE2C46A),
            Color(0xFFC9A227),
            Color(0xFFA67C1A),
          ],
          const [0.0, 0.35, 0.7, 1.0],
        ),
    );

    // Soft highlight on upper gold rim
    canvas.drawCircle(
      center.translate(0, -holeRadius * 0.15),
      holeRadius + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Ensure hole reads as solid dark (behind logo widget)
    canvas.drawCircle(
      center,
      holeRadius,
      Paint()..color = const Color(0xFF05080E),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.faceCx != faceCx ||
      old.faceCy != faceCy ||
      old.holeRadius != holeRadius;
}
