import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';

/// Branded splash screen — navy grid background, gold route path, pin logo, RIDER title.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _pathProgress;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    _pathProgress = CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: Curves.easeInOutCubic));
    _textSlide = CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic));

    _controller.forward();
    // Keep the branded splash visible long enough on slower devices.
    Future<void>.delayed(const Duration(milliseconds: 3400), () {
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
    final graphicSize = Responsive.isTablet(context) ? 320.0 : 260.0;
    final titleSize = Responsive.fontSize(context, 52);
    final taglineSize = Responsive.fontSize(context, 11);

    return Scaffold(
      backgroundColor: AppColors.accent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _SplashGridPainter()),
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    SizedBox(
                      width: graphicSize,
                      height: graphicSize * 0.78,
                      child: CustomPaint(
                        painter: _SplashRoutePainter(progress: _pathProgress.value),
                        child: Align(
                          alignment: const Alignment(0.18, -0.62),
                          child: _PinLogo(size: graphicSize * 0.44),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Transform.translate(
                      offset: Offset(0, (1 - _textSlide.value) * 14),
                      child: Opacity(
                        opacity: _textSlide.value,
                        child: Column(
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => AppColors.goldTextGradient.createShader(bounds),
                              child: Text(
                                'RIDER',
                                style: AppText.display(size: titleSize, weight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'RIDE  ·  DELIVER  ·  EARN',
                              style: AppText.body(
                                size: taglineSize,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 2.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.isTablet(context) ? 60 : 44),
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

class _PinLogo extends StatelessWidget {
  final double size;

  const _PinLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _PinMarkerPainter())),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.terrain, size: size * 0.18, color: Colors.white.withValues(alpha: 0.9)),
              SizedBox(height: size * 0.03),
              Text(
                'FooI',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.9;

    const spacing = 46.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.38), radius: size.width * 0.55));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashRoutePainter extends CustomPainter {
  final double progress;

  _SplashRoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.86)
      ..cubicTo(
        size.width * 0.04,
        size.height * 0.60,
        size.width * 0.52,
        size.height * 0.70,
        size.width * 0.58,
        size.height * 0.24,
      );

    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gold.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(extractPath, glowPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.goldDeep, AppColors.gold, AppColors.goldLight],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(extractPath, strokePaint);

    if (progress > 0.02) {
      final start = metrics.getTangentForOffset(metrics.length * 0.0)?.position ?? Offset.zero;
      canvas.drawCircle(start, 8, Paint()..color = AppColors.gold);
      canvas.drawCircle(start, 4, Paint()..color = AppColors.goldLight);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRoutePainter oldDelegate) => oldDelegate.progress != progress;
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.gold, AppColors.goldDeep],
      ).createShader(Offset.zero & size);

    canvas.save();
    canvas.translate(size.width * 0.5, 0);
    canvas.rotate(math.pi);
    canvas.translate(-size.width * 0.5, -size.height);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pin = Path()
      ..moveTo(w * 0.5, h * 0.01)
      ..quadraticBezierTo(w * 0.88, h * 0.20, w * 0.75, h * 0.52)
      ..quadraticBezierTo(w * 0.62, h * 0.80, w * 0.5, h * 0.99)
      ..quadraticBezierTo(w * 0.38, h * 0.80, w * 0.25, h * 0.52)
      ..quadraticBezierTo(w * 0.12, h * 0.20, w * 0.5, h * 0.01)
      ..close();

    // Dark center.
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentDeep;
    canvas.drawPath(pin, fillPaint);

    // Gold border.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, w * 0.055)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.goldDeep, AppColors.gold, AppColors.goldLight],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(pin, borderPaint);

    // Subtle inner ring.
    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, w * 0.03)
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawPath(pin.shift(Offset(w * 0.0, h * 0.0)), innerRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
