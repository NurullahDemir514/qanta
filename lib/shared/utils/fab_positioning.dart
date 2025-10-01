import 'package:flutter/material.dart';

/// FAB konumlandırma için responsive utility sınıfı
class FabPositioning {
  /// Navbar'ın hemen üstünde konumlandırma için bottom değeri
  static double getBottomPosition(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Ekran boyutuna göre responsive değerler
    if (screenHeight < 700) {
      // Küçük ekranlar (iPhone SE, küçük Android)
      return 70.0;
    } else if (screenHeight < 800) {
      // Orta ekranlar (iPhone 12 mini, standart Android)
      return 80.0;
    } else if (screenHeight < 900) {
      // Büyük ekranlar (iPhone 12 Pro, büyük Android)
      return 90.0;
    } else {
      // Çok büyük ekranlar (iPhone 12 Pro Max, tablet)
      return 100.0;
    }
  }
  
  /// Sağ kenardan responsive mesafe
  static double getRightPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 375) {
      // Küçük ekranlar
      return 16.0;
    } else if (screenWidth < 414) {
      // Orta ekranlar
      return 20.0;
    } else {
      // Büyük ekranlar ve tabletler
      return 24.0;
    }
  }
  
  /// FAB boyutu için responsive değer
  static double getFabSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 375) {
      return 52.0;
    } else if (screenWidth < 414) {
      return 56.0;
    } else {
      return 60.0;
    }
  }
  
  /// Icon boyutu için responsive değer
  static double getIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 375) {
      return 24.0;
    } else if (screenWidth < 414) {
      return 28.0;
    } else {
      return 32.0;
    }
  }
  
  /// Speed dial seçenekleri arasındaki mesafe
  static double getSpeedDialSpacing(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < 700) {
      return 8.0;
    } else if (screenHeight < 800) {
      return 12.0;
    } else {
      return 16.0;
    }
  }
}
