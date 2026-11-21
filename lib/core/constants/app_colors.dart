import 'package:flutter/material.dart';

/// Tema warna maritim / biru laut profesional untuk aplikasi nelayan SPBN Madura.
class AppColors {
  AppColors._();

  // Primary Colors (Ocean & Maritime Blues)
  static const Color primary = Color(0xFF0F4C81); // Deep Ocean Blue
  static const Color primaryDark = Color(0xFF0A3254); // Deep Navy Trench
  static const Color primaryLight = Color(0xFF2B78B8); // Coastal Sea Blue
  static const Color primaryContainer = Color(0xFFD6E8F7);

  // Secondary & Accent Colors
  static const Color secondary = Color(0xFF0284C7); // Nautical Cyan
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky Marine
  static const Color accentSolar = Color(0xFFEAB308); // Golden Solar (Diesel Fuel Tint)
  static const Color accentWarm = Color(0xFFF97316); // Amber Flare

  // Status & Validation Colors (Geofence & Mock GPS)
  static const Color success = Color(0xFF16A34A); // Valid Geofence (Green)
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B); // Near Geofence boundary (Amber)
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626); // Outside Geofence / Mock GPS (Red)
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);

  // Neutral & Background Colors
  static const Color background = Color(0xFFF8FAFC); // Very light slate blue tint
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Deep Slate Navy
  static const Color textSecondary = Color(0xFF475569); // Slate Gray
  static const Color textMuted = Color(0xFF94A3B8); // Muted Light Slate
  static const Color textWhite = Color(0xFFFFFFFF);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Radar & Geofence Map Colors
  static const Color geofenceFill = Color(0x330284C7); // Translucent Ocean Cyan
  static const Color geofenceStroke = Color(0xFF0284C7);
  static const Color geofenceValidFill = Color(0x3316A34A); // Translucent Green
  static const Color geofenceValidStroke = Color(0xFF16A34A);
  static const Color geofenceInvalidFill = Color(0x33DC2626); // Translucent Red
  static const Color geofenceInvalidStroke = Color(0xFFDC2626);

  // Modern Gradients for Cards & Buttons
  static const LinearGradient gradientOcean = LinearGradient(
    colors: [Color(0xFF0A2540), Color(0xFF0F4C81), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientOceanLight = LinearGradient(
    colors: [Color(0xFF0F4C81), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSolar = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F2B48).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F2B48).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}
