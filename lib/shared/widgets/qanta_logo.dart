import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Qanta logo widget that can be used throughout the app
/// Supports different sizes and automatically falls back to a gradient Q if logo is not found
class QantaLogo extends StatelessWidget {
  final double size;
  final bool isWhite;
  final String? customLogoPath;

  const QantaLogo({
    super.key,
    this.size = 40,
    this.isWhite = false,
    this.customLogoPath,
  });

  /// Small logo for app bars and compact spaces
  const QantaLogo.small({
    super.key,
    this.size = 32,
    this.isWhite = false,
    this.customLogoPath,
  });

  /// Medium logo for cards and medium spaces
  const QantaLogo.medium({
    super.key,
    this.size = 64,
    this.isWhite = false,
    this.customLogoPath,
  });

  /// Large logo for splash and welcome screens
  const QantaLogo.large({
    super.key,
    this.size = 120,
    this.isWhite = false,
    this.customLogoPath,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath = customLogoPath ?? 
        (isWhite ? AppConstants.imagePath + 'logo_white.png' : AppConstants.logoPath);
    
    return _buildLogo(logoPath);
  }

  Widget _buildLogo(String logoPath) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient container with Q letter
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF34D399),
                  ],
                ),
                borderRadius: BorderRadius.circular(size * 0.2),
              ),
              child: Center(
                child: Text(
                  'Q',
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 