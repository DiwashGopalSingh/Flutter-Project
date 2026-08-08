import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Modern Crimson
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryLight = Color(0xFFFF6659);
  static const Color primaryDark = Color(0xFF9A0007);

  // Accent
  static const Color accent = Color(0xFFFF5252);
  static const Color accentGlow = Color(0x33FF5252);

  // Background - Deep Space Black
  static const Color background = Color(0xFF0A0A0F);
  static const Color backgroundCard = Color(0xFF14141E);
  static const Color surface = Color(0xFF1A1A27);
  static const Color surfaceElevated = Color(0xFF222233);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF546E7A);
  static const Color textMuted = Color(0xFF37474F);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successBg = Color(0x1A4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFCA28);
  static const Color warningBg = Color(0x1AFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF9A9A);
  static const Color errorBg = Color(0x1AE53935);
  static const Color info = Color(0xFF29B6F6);
  static const Color infoBg = Color(0x1A29B6F6);

  // Blood Group Specific Colors (Vibrant variants)
  static const Map<String, Color> bloodGroupColors = {
    'A+': Color(0xFFFF5252),
    'A-': Color(0xFFD32F2F),
    'B+': Color(0xFFE91E63),
    'B-': Color(0xFFC2185B),
    'AB+': Color(0xFFAB47BC),
    'AB-': Color(0xFF7B1FA2),
    'O+': Color(0xFFFF7043),
    'O-': Color(0xFFD84315),
  };

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6659), Color(0xFF9A0007)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E2C), Color(0xFF14141E)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF1744), Color(0xFFB71C1C)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FC3F7), Color(0xFF0277BD)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0F), Color(0xFF150505), Color(0xFF0A0A0F)],
  );

  // Border & Divider
  static const Color border = Color(0xFF2D2D45);
  static const Color divider = Color(0xFF1E1E30);

  // Glass effect
  static const Color glassOverlay = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
