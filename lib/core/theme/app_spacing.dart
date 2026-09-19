import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;

  static const double cardRadius = 16.0;
  static const double buttonRadius = 14.0;
  static const double inputRadius = 12.0;
  static const double badgeRadius = 999.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F382A).withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF0F382A).withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}
