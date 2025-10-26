import 'package:flutter/material.dart';

class AppColors {
  // 🌗 Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF7F8FA);
  static const Color lightText = Color(0xFF000000);
  
  // Aliases for consistency
  static const Color backgroundLight = lightBackground;
  static const Color cardLight = lightCard;
  static const Color textLight = Color(0xFFA0A0A0); // Secondary text

  // 🌙 Dark Theme
  static const Color darkBackground = Color(0xFF0B0B0B);
  static const Color darkCard = Color(0xFF181818);
  static const Color darkText = Color(0xFFFFFFFF);
  
  // Aliases for consistency
  static const Color backgroundDark = darkBackground;
  static const Color cardDark = darkCard;
  static const Color textDark = Color(0xFF000000); // Primary text (light mode)

  // 🎨 Common (Original Colors)
  static const Color primary = Color(0xFF6D6D70); // Sophisticated Grey
  static const Color secondary = Color(0xFF8E8E93); // Grey
  static const Color error = Color(0xFFFF4C4C);
  static const Color warning = Color(0xFFFFC300);
  static const Color info = Color(0xFF00C2FF);
  static const Color success = Color(0xFF2E7D32); // Rich Green
  static const Color neutral = Color(0xFFA0A0A0);
  
  // Additional colors for Premium UI
  static const Color mintGreen = Color(0xFF34D399); // Mint Green for badges
  static const Color ioSBlue = Color(0xFF007AFF); // iOS Blue for buttons
  
  // Special colors
  static const Color white05 = Color(0x0DFFFFFF); // 5% white opacity
} 