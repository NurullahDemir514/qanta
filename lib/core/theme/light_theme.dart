import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class LightTheme {
  // Para birimi sembolleri için font fallback listesi
  static const List<String> _fontFallbacks = [
    'Roboto',
    'SF Pro Text',
    'SF Pro Display', 
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.lightCard,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightText,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightText),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
      ),
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.inter(
          color: AppColors.lightText, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.lightText, 
          fontSize: 16,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
        bodySmall: GoogleFonts.inter(
          color: AppColors.neutral, 
          fontSize: 12,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamilyFallback: _fontFallbacks),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
} 