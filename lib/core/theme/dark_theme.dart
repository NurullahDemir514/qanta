import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class DarkTheme {
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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.darkCard,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkText,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
      ),
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.inter(
          color: AppColors.darkText, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: _fontFallbacks),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.darkText, 
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
        color: AppColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
} 