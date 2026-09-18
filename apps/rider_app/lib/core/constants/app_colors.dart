import 'package:flutter/material.dart';

class AppColors {
  // Brand & Accent
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF0F766E); // Teal accent

  // Sunlight-Readable Duty States
  static const Color dutyOnline = Color(0xFF059669); // Rich Emerald Green
  static const Color dutyOnlineLight = Color(0xFF10B981); // Bright Emerald
  static const Color dutyOnlineBackground = Color(0xFFECFDF5); // Light mint

  static const Color dutyOffline = Color(0xFF374151); // Slate Charcoal
  static const Color dutyOfflineLight = Color(0xFF4B5563);
  static const Color dutyOfflineBackground = Color(0xFFF3F4F6); // Soft grey

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF0F172A);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Text Colors (High Contrast for Outdoor Readability)
  static const Color textPrimary = Color(0xFF0F172A); // High-contrast Charcoal
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFF8FAFC);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
}
