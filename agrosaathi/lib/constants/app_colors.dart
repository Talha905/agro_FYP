import 'package:flutter/material.dart';

/// Shared design-system colors (see Firestore Schema & Design System doc).
/// Person A owns this file — everyone else just imports AppColors.
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

  static const warning = Color(0xFFD32F2F); // Disease detection alerts, errors
  static const warningLight = Color(0xFFFFEBEE);

  static const riskLow = Color(0xFF2E7D32);
  static const riskMedium = Color(0xFFF57C00);
  static const riskHigh = Color(0xFFD32F2F);

  // Surfaces & Neutrals
  static const background = Color(0xFFFAF9F4); // Warm off-white (softer on eyes outdoors)
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE8E5D8);

  // Typography
  static const textPrimary = Color(0xFF212121); // Near-black for high contrast
  static const textSecondary = Color(0xFF6B6B6B); // Captions, helper text
  static const textDisabled = Color(0xFF9E9E9E);
}
