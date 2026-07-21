import 'package:flutter/material.dart';

/// Breakpoints and scaling helpers for phone + tablet layouts.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double largeTabletBreakpoint = 900;
  static const double maxContentWidth = 520;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isTablet(BuildContext context) => sizeOf(context).width >= tabletBreakpoint;

  static bool isLargeTablet(BuildContext context) => sizeOf(context).width >= largeTabletBreakpoint;

  static double scale(BuildContext context, double value) {
    final width = sizeOf(context).width;
    if (width >= largeTabletBreakpoint) return value * 1.15;
    if (width >= tabletBreakpoint) return value * 1.08;
    return value;
  }

  static double fontSize(BuildContext context, double size) => scale(context, size);

  static EdgeInsets screenPadding(BuildContext context, {double horizontal = 20, double vertical = 0}) {
    final scaled = scale(context, horizontal);
    if (isLargeTablet(context)) {
      return EdgeInsets.symmetric(horizontal: scaled * 2.2, vertical: vertical);
    }
    if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: scaled * 1.6, vertical: vertical);
    }
    return EdgeInsets.symmetric(horizontal: scaled, vertical: vertical);
  }

  static double contentWidth(BuildContext context) {
    final width = sizeOf(context).width;
    if (isTablet(context)) return width.clamp(0, maxContentWidth);
    return width;
  }
}

/// Centers content on tablets so the phone layout does not stretch edge-to-edge.
class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool constrainWidth;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.backgroundColor,
    this.constrainWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isTablet(context) || !constrainWidth) {
      return ColoredBox(color: backgroundColor ?? Colors.white, child: child);
    }

    return ColoredBox(
      color: backgroundColor ?? Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
