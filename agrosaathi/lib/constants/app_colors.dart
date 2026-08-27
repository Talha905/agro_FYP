import 'package:flutter/material.dart';

/// Shared design-system colors (see Firestore Schema & Design System doc).
/// Person A owns this file — everyone else just imports AppColors.
class AppColors {
  static const primary = Color(0xFF2E7D32); // main actions, growth
  static const secondary = Color(0xFFB8860B); // harvest/soil accents
  static const accent = Color(0xFF1976D2); // water / irrigation / weather
  static const success = Color(0xFF43A047); // confirmations
  static const warning = Color(0xFFD32F2F); // alerts (pests, errors)
  static const background = Color(0xFFFAF9F4);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF6B6B6B);
}
