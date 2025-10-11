import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen compatibility utility class for handling different Android screen densities
class ScreenCompatibility {
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;
  
  /// Get responsive width based on screen width
  static double responsiveWidth(BuildContext context, double width) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _baseWidth;
    return width * scaleFactor;
  }
  
  /// Get responsive height based on screen height
  static double responsiveHeight(BuildContext context, double height) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenHeight / _baseHeight;
    return height * scaleFactor;
  }
  
  /// Get responsive font size based on screen density
  static double responsiveFontSize(BuildContext context, double fontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _baseWidth;
    
    // Clamp scale factor to prevent extreme scaling
    final clampedScaleFactor = scaleFactor.clamp(0.8, 1.4);
    return fontSize * clampedScaleFactor;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context, EdgeInsets padding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _baseWidth;
    
    // Clamp scale factor to prevent extreme scaling
    final clampedScaleFactor = scaleFactor.clamp(0.8, 1.4);
    
    return EdgeInsets.only(
      left: padding.left * clampedScaleFactor,
      top: padding.top * clampedScaleFactor,
      right: padding.right * clampedScaleFactor,
      bottom: padding.bottom * clampedScaleFactor,
    );
  }
  
  /// Check if device has small screen
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Check if device has large screen
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  /// Get screen density category
  static String getScreenDensityCategory(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    if (devicePixelRatio <= 1.0) return 'ldpi';
    if (devicePixelRatio <= 1.5) return 'mdpi';
    if (devicePixelRatio <= 2.0) return 'hdpi';
    if (devicePixelRatio <= 3.0) return 'xhdpi';
    if (devicePixelRatio <= 4.0) return 'xxhdpi';
    return 'xxxhdpi';
  }
  
  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Get screen size category
  static ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) return ScreenSizeCategory.small;
    if (width < 480) return ScreenSizeCategory.medium;
    if (width < 600) return ScreenSizeCategory.large;
    if (width < 840) return ScreenSizeCategory.xlarge;
    return ScreenSizeCategory.xxlarge;
  }
}

/// Screen size categories
enum ScreenSizeCategory {
  small,
  medium,
  large,
  xlarge,
  xxlarge,
}

/// Extension for easier responsive sizing
extension ResponsiveExtension on num {
  /// Responsive width
  double w(BuildContext context) {
    return ScreenCompatibility.responsiveWidth(context, toDouble());
  }
  
  /// Responsive height
  double h(BuildContext context) {
    return ScreenCompatibility.responsiveHeight(context, toDouble());
  }
  
  /// Responsive font size
  double sp(BuildContext context) {
    return ScreenCompatibility.responsiveFontSize(context, toDouble());
  }
}
