import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary: Deep Emerald
  static const Color primary = Color(0xFF0F382A);
  static const Color primaryDark = Color(0xFF002217);
  static const Color primaryLight = Color(0xFF154D39);
  static const Color primaryContainer = Color(0xFF0F382A);
  static const Color onPrimaryContainer = Color(0xFF79A28F);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary & Accent: Muted Champagne Gold & Rose Accent
  static const Color secondary = Color(0xFFC5A059);
  static const Color secondaryDark = Color(0xFF775A19);
  static const Color secondaryContainer = Color(0xFFFED488);
  static const Color onSecondaryContainer = Color(0xFF785A1A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color goldAccent = Color(0xFFD4AF37);

  // Brand Logo Tokens
  static const Color brandRose = Color(0xFFA8435C);
  static const Color brandRoseLight = Color(0xFFB8526F);
  static const Color brandPinkBg = Color(0xFFFCE4E8);

  // Canvas & Surfaces: Soft Cream & Warm Alabaster
  static const Color background = Color(0xFFFBF9F5);
  static const Color surface = Color(0xFFFBF9F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF5EFE6);
  static const Color surfaceContainerLow = Color(0xFFF0F5F0);
  static const Color surfaceContainer = Color(0xFFEBEFEA);
  static const Color surfaceContainerHigh = Color(0xFFE5E9E4);
  static const Color surfaceContainerHighest = Color(0xFFDFE4DF);

  // Text & Content: Charcoal Forest
  static const Color textPrimary = Color(0xFF1F2421);
  static const Color textSecondary = Color(0xFF565E59);
  static const Color textTertiary = Color(0xFF717974);
  static const Color textMuted = Color(0xFF8C948F);
  static const Color onSurface = Color(0xFF1F2421);
  static const Color onSurfaceVariant = Color(0xFF414844);

  // Borders & Outlines: Linen Gray-Beige
  static const Color border = Color(0xFFE8E2D8);
  static const Color borderLight = Color(0xFFF0EBE3);
  static const Color outline = Color(0xFF717974);
  static const Color outlineVariant = Color(0xFFC1C8C3);

  // Semantic Status Tokens
  // 1. Success / Available / Confirmed (Forest Sage)
  static const Color statusSuccess = Color(0xFF1F6F43);
  static const Color statusSuccessBg = Color(0xFFE9F5EE);

  // 2. Warning / Limited / Pending Verification (Warm Amber)
  static const Color statusWarning = Color(0xFF9E6E18);
  static const Color statusWarningBg = Color(0xFFFEF6E7);

  // 3. Error / Rejected / Unavailable / Cancelled (Muted Crimson)
  static const Color statusError = Color(0xFF9C2A2A);
  static const Color statusErrorBg = Color(0xFFFDF0F0);

  // 4. Info / Processing (Deep Emerald tint)
  static const Color statusInfo = Color(0xFF2E6171);
  static const Color statusInfoBg = Color(0xFFE8F1F5);

  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F382A), Color(0xFF154D39)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFED488), Color(0xFFC5A059)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
