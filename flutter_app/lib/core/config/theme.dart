import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Neutral/Premium)
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFE5E5E5);
  static const Color outlineDim = Color(0xFFCCCCCC);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF242424);
  static const Color darkOutline = Color(0xFF333333);
  static const Color darkOutlineDim = Color(0xFF444444);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFCCCCCC);
  static const Color darkTextTertiary = Color(0xFF888888);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Accent
  static const Color primary = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF666666);
  static const Color accent = Color(0xFF3B82F6);

  // Glassmorphism
  static const Color glassLight = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x80000000);

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF333333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;
}

class AppElevation {
  static const shadowSoft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const shadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const shadowLarge = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 8),
    ),
  ];

  static const shadowXL = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 20,
      offset: Offset(0, 12),
    ),
  ];

  static const shadowDarkSoft = [
    BoxShadow(
      color: Color(0x1AFFFFFF),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const shadowDarkMedium = [
    BoxShadow(
      color: Color(0x29FFFFFF),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
