import 'package:flutter/material.dart';

/// لوحة ألوان ميزانيتي AI — النيون الفاخر
class AppColors {
  AppColors._();

  static const Color background     = Color(0xFF0A0E1A);
  static const Color card           = Color(0xFF141A29);
  static const Color cardElevated   = Color(0xFF1C2438);
  static const Color divider        = Color(0xFF232C42);
  
  // ألوان النيون الجديدة
  static const Color primaryBlue    = Color(0xFF00F0FF); // أزرق سماوي مشع
  static const Color primaryPink    = Color(0xFFFF007F); // زهري ماجنتا مشع
  
  static const Color textPrimary    = Color(0xFFF5F7FA);
  static const Color textSecondary  = Color(0xFF9AA6BF);
  static const Color textMuted      = Color(0xFF5C6880);
  static const Color success        = Color(0xFF2DD4BF);
  static const Color warning        = Color(0xFFFFB020);
  static const Color danger         = Color(0xFFFF4D6D);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient ringGradient = LinearGradient(
    colors: [primaryBlue, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color statusColor(double ratio) {
    if (ratio >= 1.0) return danger;
    if (ratio >= 0.85) return warning;
    if (ratio >= 0.65) return primaryPink;
    return success;
  }
}
