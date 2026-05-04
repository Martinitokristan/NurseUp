import 'package:flutter/material.dart';

/// Typography scale for NurseUp.
///
/// Intentionally **does not set `color`** so every Text inherits from the
/// active `ThemeData.textTheme` (resolved via `DefaultTextStyle.of(context)`).
/// This guarantees correct contrast in both light and dark modes.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2);
  static const TextStyle h1 = TextStyle(fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w700);
  static const TextStyle h3 = TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle bodyMedium = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);
  static const TextStyle bodySmall = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle label = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle button = TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2);
  static const TextStyle caption = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400);
  static const TextStyle overline = TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1);
}

