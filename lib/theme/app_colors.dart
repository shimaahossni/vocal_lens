import 'package:flutter/material.dart';

class AppColors {
  // Primary brand palette (Cyber Indigo & Electric Rose)
  static const Color primary        = Color(0xFF6366F1); // Indigo
  static const Color primaryDark    = Color(0xFF4F46E5);
  static const Color secondary      = Color(0xFFEC4899); // Rose / Pink
  static const Color accent         = Color(0xFFEC4899);
  static const Color accentCyan     = Color(0xFF06B6D4); // Cyan
  static const Color accentAmber    = Color(0xFFF59E0B); // Amber

  // Premium Deep Dark theme
  static const Color darkBg         = Color(0xFF0B0F19); // Ultra deep navy
  static const Color darkSurface    = Color(0xFF131B2E); // Surface container
  static const Color darkCard       = Color(0xFF172036); // Card background
  static const Color darkCardHover  = Color(0xFF1F2B47);
  static const Color darkInput      = Color(0xFF0F1626); // Text field fill
  static const Color darkBorder     = Color(0xFF23304E); // Crisp subtle border

  // Premium Clean Light theme
  static const Color lightBg        = Color(0xFFF8FAFC);
  static const Color lightSurface   = Colors.white;
  static const Color lightCard      = Colors.white;
  static const Color lightInput     = Color(0xFFF1F5F9);
  static const Color lightBorder    = Color(0xFFE2E8F0);

  // Status & Utility
  static const Color stop           = Color(0xFFEF4444); // Red
  static const Color success        = Color(0xFF10B981); // Emerald Green
  static const Color warning        = Color(0xFFF59E0B);

  // Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceWaveGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF6366F1), Color(0xFFEC4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
