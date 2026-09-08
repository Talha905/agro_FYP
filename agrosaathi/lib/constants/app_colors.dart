import 'package:flutter/material.dart';

/// Design-system colors, gradients, and shadows for AgroSaathi.
class AppColors {
  // Brand colors
  static const primary = Color(0xFF2E7D32); // Main actions, growth, agriculture
  static const primaryLight = Color(0xFFE8F5E9); // Light green container / badge
  static const primaryDark = Color(0xFF1B5E20);

  static const secondary = Color(0xFFD97706); // Warm amber / harvest
  static const secondaryLight = Color(0xFFFEF3C7);

  static const accent = Color(0xFF0284C7); // Water, irrigation, sky blue
  static const accentLight = Color(0xFFE0F2FE);

  static const success = Color(0xFF16A34A); // Confirmations, completed tasks
  static const successLight = Color(0xFFDCFCE7);

  static const warning = Color(0xFFEA580C); // Overdue alerts, rescheduling warnings
  static const warningLight = Color(0xFFFFEDD5);

  static const danger = Color(0xFFDC2626); // High risk, disease alerts
  static const dangerLight = Color(0xFFFEE2E2);

  static const riskLow = Color(0xFF16A34A);
  static const riskMedium = Color(0xFFD97706);
  static const riskHigh = Color(0xFFDC2626);

  // Surfaces & Neutrals
  static const background = Color(0xFFF8FAFC); // Clean slate-tinted off-white
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE2E8F0);
  static const glassBorder = Color(0x33FFFFFF);

  // Typography
  static const textPrimary = Color(0xFF0F172A); // High contrast slate
  static const textSecondary = Color(0xFF64748B); // Captions, helper text
  static const textDisabled = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF166534)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunnyGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient rainyGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x99FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
