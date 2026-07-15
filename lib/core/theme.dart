import 'package:flutter/material.dart';

/// Foodeez Rider brand palette — hex values sourced verbatim from the design prototype.
class AppColors {
  AppColors._();

  static const accent = Color(0xFF6E2A4D);
  static const accentLight = Color(0xFF8A3A66);
  static const accentDeep = Color(0xFF4E1D37);

  static const gold = Color(0xFFC9A227);
  static const goldDeep = Color(0xFFB4692E);

  static const green = Color(0xFF1F8A3B);
  static const greenPaleBg = Color(0xFFE7F4EA);
  static const greenPaleBg2 = Color(0xFFEAF6EE);
  static const greenPaleBorder = Color(0xFFBFE6C9);
  static const greenPaleBorder2 = Color(0xFFCBE6D2);
  static const greenMutedText = Color(0xFF5C7A62);
  static const greenMutedText2 = Color(0xFF137A37);
  static const greenDotBright = Color(0xFF8BE0A0);

  static const red = Color(0xFFE23B3B);

  static const star = Color(0xFFF5A623);

  static const ink = Color(0xFF1E1A1D);
  static const bodyGrey = Color(0xFF8A8189);
  static const lightGreyText = Color(0xFFB4A9AE);
  static const midGrey = Color(0xFF5C555A);
  static const midGrey2 = Color(0xFF3C363A);

  static const surface = Color(0xFFFBF8F4);
  static const cardBorder = Color(0xFFF1ECE8);
  static const hairline = Color(0xFFF6F1ED);
  static const dividerBorder = Color(0xFFE4DCE0);
  static const dividerBorder2 = Color(0xFFEFEAE6);

  static const plumTint = Color(0xFFF6EEF3);
  static const plumTintBorder = Color(0xFFE8D3E0);

  static const goldTint = Color(0xFFFBF0DE);
  static const goldTintBorder2 = Color(0xFFEAD6A9);

  static const otpBorderIdle = Color(0xFFE4DCE0);

  static const heroGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentLight, accent]);
  static const onlineHeroGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDF7EF), Color(0xFFE3F1E7)]);
  static const incentiveGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBF0DE), Color(0xFFF8E7C6)]);
  static const sosGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBEEEE), Color(0xFFF7E0E0)]);
}

/// Text style helpers — 'Bricolage Grotesque' for display/headings,
/// 'Plus Jakarta Sans' for body/UI text.
class AppText {
  AppText._();

  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
  }

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
    FontStyle? style,
  }) {
    return TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height, fontStyle: style);
  }
}
