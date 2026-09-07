import 'package:flutter/material.dart';

/// Design-system colors & gradients for AgroSaathi.
class AppColors {
  // Brand colors
  static const primary = Color(0xFF2E7D32); // Main actions, growth, agriculture
  static const primaryLight = Color(0xFFE8F5E9); // Light green container / badge
  static const primaryDark = Color(0xFF1B5E20);

  static const secondary = Color(0xFFB8860B); // Earthy amber, harvest / soil accents
  static const secondaryLight = Color(0xFFFFF8E1);

  static const accent = Color(0xFF1976D2); // Water, irrigation, weather, links
  static const accentLight = Color(0xFFE3F2FD);

  static const success = Color(0xFF43A047); // Confirmations, completed tasks
  static const successLight = Color(0xFFE8F5E9);

  static const warning = Color(0xFFF57C00); // Overdue alerts, rescheduling warnings
  static const warningLight = Color(0xFFFFF3E0);

  static const danger = Color(0xFFD32F2F); // High risk, disease alerts
  static const dangerLight = Color(0xFFFFEBEE);

  static const riskLow = Color(0xFF2E7D32);
  static const riskMedium = Color(0xFFF57C00);
  static const riskHigh = Color(0xFFD32F2F);

  // Surfaces & Neutrals
  static const background = Color(0xFFF7F9F6); // Soft green-tinted off-white
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE2E8F0);

  // Typography
  static const textPrimary = Color(0xFF1E293B); // High contrast dark slate
  static const textSecondary = Color(0xFF64748B); // Captions, helper text
  static const textDisabled = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
