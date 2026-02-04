import 'package:flutter/material.dart';

/// App color palette based on design specifications
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFFF9F506); // Bright Yellow
  static const Color primaryDark = Color(0xFFC7C405); // Darker Yellow (shadows)
  static const Color primaryLight = Color(0xFFFFFB4D); // Lighter Yellow

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F8F5); // Off-white
  static const Color backgroundDark = Color(0xFF23220F); // Dark Brown
  static const Color neutralDark = Color(0xFF1C1C0D); // Dark charcoal

  // Surface colors
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF2D2D1A);

  // Animal colors (for placeholder tiles)
  static const Color beeColor = Color(0xFFFFD700); // Gold
  static const Color rabbitColor = Color(0xFFFF69B4); // Pink
  static const Color catColor = Color(0xFF87CEEB); // Sky Blue
  static const Color duckColor = Color(0xFF90EE90); // Light Green
  static const Color bearColor = Color(0xFFD2691E); // Chocolate

  // UI colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C0D);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textOnPrimary = Color(0xFF1C1C0D);
  static const Color textOnDark = Colors.white;

  // Blocker colors
  static const Color boxColor = Color(0xFF8B4513); // Brown
  static const Color iceColor = Color(0xFFADD8E6); // Light Blue

  // Power-up colors
  static const Color rainbowGradientStart = Color(0xFFFF0000);
  static const Color rainbowGradientEnd = Color(0xFF9400D3);

  // Gradient for buttons
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primary],
  );

  // Shadow color
  static const Color shadowColor = Color(0x40000000);
}
