import 'package:flutter/material.dart';

import '../../core/responsive.dart';

/// Branded FooDeeZ Delivery partner logo used on login, splash, etc.
class FoodeezLogo extends StatelessWidget {
  final double? width;

  const FoodeezLogo({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final size = width ?? (Responsive.isTablet(context) ? 220.0 : 180.0);

    return Image.asset(
      'assets/images/delivery-partner-logo.png',
      width: size,
      fit: BoxFit.contain,
    );
  }
}
