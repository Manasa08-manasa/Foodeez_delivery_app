import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';

/// Standalone Rider Route Draw Splash Screen.
/// Features deep navy gradient background, grid lines, animated route drawing,
/// travelling rider marker dot, pin drop at destination with pulse rings,
/// gold gradient RIDER typography, tagline, and progress bar.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeIn;
  late final Animation<double> _pathProgress;
  late final Animation<double> _pinDrop;
  late final Animation<double> _pulseProgress;
  late final Animation<double> _textSlide;
  late final Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
    );

    _pathProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.58, curve: Curves.easeInOutCubic),
    );

    _pinDrop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.75, curve: Curves.elasticOut),
    );

    _pulseProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
    );

    _textSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.92, curve: Curves.easeOutCubic),
    );

    _barProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.90, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future<void>.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final graphicWidth = Responsive.isTablet(context) ? 320.0 : math.min(size.width * 0.8, 280.0);
    final graphicHeight = graphicWidth * 1.35;

    final titleSize = Responsive.fontSize(context, 48);
    final taglineSize = Responsive.fontSize(context, 11.5);

    return Scaffold(
      backgroundColor: AppColors.accentDeep,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Navy Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      AppColors.accentLight,
                      AppColors.accentDeep,
                      Color(0xFF07131D),
                    ],
                  ),
                ),
              ),

              // Grid Painter
              CustomPaint(
                size: Size.infinite,
                painter: _BackgroundGridPainter(),
              ),

              // Content Column
              FadeTransition(
                opacity: _fadeIn,
                child: SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Route Animation Graphic
                      SizedBox(
                        width: graphicWidth,
                        height: graphicHeight,
                        child: CustomPaint(
                          painter: _RouteDrawPainter(
                            progress: _pathProgress.value,
                            pinScale: _pinDrop.value,
                            pulseProgress: _pulseProgress.value,
                          ),
                          child: Stack(
                            children: [
                              // Destination Pin Overlay
                              if (_pathProgress.value > 0.4)
                                _PinOverlay(
                                  progress: _pathProgress.value,
                                  pinDrop: _pinDrop.value,
                                  graphicSize: Size(graphicWidth, graphicHeight),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Typography: RIDER & Tagline
                      Transform.translate(
                        offset: Offset(0, (1 - _textSlide.value) * 20),
                        child: Opacity(
                          opacity: _textSlide.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFF0D48A),
                                    Color(0xFFE8C767),
                                    Color(0xFFB8862F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'RIDER',
                                  style: AppText.display(
                                    size: titleSize,
                                    weight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RIDE  ·  DELIVER  ·  EARN',
                                style: AppText.body(
                                  size: taglineSize,
                                  weight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 3.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Gold Progress Bar
                      Container(
                        width: 120,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white.withOpacity(0.12),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _barProgress.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF0D48A),
                                    Color(0xFFB8862F),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.isTablet(context) ? 48 : 36),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Draws background grid lines matching standalone HTML
class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const spacing = 50.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the route path, glowing stroke, start point, travelling dot, and pulse rings
class _RouteDrawPainter extends CustomPainter {
  final double progress;
  final double pinScale;
  final double pulseProgress;

  _RouteDrawPainter({
    required this.progress,
    required this.pinScale,
    required this.pulseProgress,
  });

  Path _getRoutePath(Size size) {
    final w = size.width;
    final h = size.height;

    // Bezier curve matching standalone HTML: M60 428 C 116 400, 190 394, 150 338 C 124 300, 132 294, 139 280
    // Normalized to canvas bounds (w, h)
    return Path()
      ..moveTo(w * 0.22, h * 0.85)
      ..cubicTo(
        w * 0.45,
        h * 0.78,
        w * 0.72,
        h * 0.76,
        w * 0.55,
        h * 0.58,
      )
      ..cubicTo(
        w * 0.42,
        h * 0.44,
        w * 0.48,
        h * 0.42,
        w * 0.50,
        h * 0.35,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getRoutePath(size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;

    // 1. Base trace path (faint gold stroke)
    final baseTracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8C767).withOpacity(0.16);
    canvas.drawPath(path, baseTracePaint);

    // 2. Start circle
    final startTangent = metric.getTangentForOffset(0);
    if (startTangent != null) {
      canvas.drawCircle(
        startTangent.position,
        6.0,
        Paint()..color = const Color(0xFFF0D48A),
      );
    }

    // 3. Active animated route line
    if (progress > 0) {
      final activeLength = totalLength * progress;
      final activePath = metric.extractPath(0, activeLength);

      // Glow under path
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF0D48A).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(activePath, glowPaint);

      // Main gold gradient stroke
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            const Color(0xFFF0D48A),
            const Color(0xFFE8C767),
            const Color(0xFFB8862F),
          ],
        );
      canvas.drawPath(activePath, strokePaint);

      // 4. Travelling rider dot
      if (progress < 0.98) {
        final currentTangent = metric.getTangentForOffset(activeLength);
        if (currentTangent != null) {
          final pos = currentTangent.position;

          // Outer glow circle
          canvas.drawCircle(
            pos,
            12.0,
            Paint()
              ..color = const Color(0xFFF0D48A).withOpacity(0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );

          // Rider dot
          canvas.drawCircle(
            pos,
            6.5,
            Paint()..color = const Color(0xFFF0D48A),
          );
          canvas.drawCircle(
            pos,
            3.0,
            Paint()..color = Colors.white,
          );
        }
      }
    }

    // 5. Pulse rings anchored at destination pin base when pin drops
    if (pinScale > 0.2) {
      final endTangent = metric.getTangentForOffset(totalLength);
      if (endTangent != null) {
        final center = endTangent.position;

        for (int i = 0; i < 2; i++) {
          double pulse = (pulseProgress + (i * 0.4)) % 1.0;
          double radius = 10.0 + (pulse * 30.0);
          double opacity = (1.0 - pulse).clamp(0.0, 1.0);

          final pulsePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = const Color(0xFFF0D48A).withOpacity(opacity * 0.7);

          canvas.drawCircle(center, radius, pulsePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteDrawPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pinScale != pinScale ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

/// Pin Overlay widget positioned over destination point
class _PinOverlay extends StatelessWidget {
  final double progress;
  final double pinDrop;
  final Size graphicSize;

  const _PinOverlay({
    required this.progress,
    required this.pinDrop,
    required this.graphicSize,
  });

  @override
  Widget build(BuildContext context) {
    // End position of path: (w * 0.50, h * 0.35)
    final pinX = graphicSize.width * 0.50;
    final pinY = graphicSize.height * 0.35;

    final opacity = progress.clamp(0.0, 1.0);
    final scale = pinDrop.clamp(0.0, 1.2);
    final translateY = (1 - pinDrop.clamp(0.0, 1.0)) * -30.0;

    return Positioned(
      left: pinX - 32,
      top: pinY - 64 + translateY,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _MapPinPainter(),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF050E17),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/foodeez-mark.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Color(0xFFF0D48A),
                            ),
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
    );
  }
}

/// Teardrop Map Pin painter
class _MapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Map pin teardrop shape
    final path = Path()
      ..moveTo(w * 0.5, h * 0.98)
      ..cubicTo(w * 0.15, h * 0.65, 0, h * 0.45, 0, h * 0.35)
      ..cubicTo(0, h * 0.15, w * 0.22, 0, w * 0.5, 0)
      ..cubicTo(w * 0.78, 0, w, h * 0.15, w, h * 0.35)
      ..cubicTo(w, h * 0.45, w * 0.85, h * 0.65, w * 0.5, h * 0.98)
      ..close();

    // Fill pin with gold gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, h),
        [
          const Color(0xFFF0D48A),
          const Color(0xFFE8C767),
          const Color(0xFFB8862F),
        ],
      );
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
