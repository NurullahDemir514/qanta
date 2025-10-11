import 'package:flutter/material.dart';

/// FAB konumlandırma için responsive utility sınıfı
class FabPositioning {
  /// Bottom navigation bar'ın dinamik yüksekliğini hesapla
  static double _getBottomNavBarHeight(BuildContext context) {
    // SafeArea bottom padding (home indicator, navigation bar)
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tab bar yüksekliği (MainTabBar widget'ı)
    const tabBarHeight = 48.0; // MainTabBar preferredSize
    
    // Tab bar padding (top + bottom)
    const tabBarPadding = 12.0; // 4 (top) + 8 (bottom)
    
    // Cihaz türüne göre minimum safe area bottom
    double minSafeAreaBottom;
    if (safeAreaBottom > 0) {
      // SafeArea değeri varsa kullan (home indicator var)
      minSafeAreaBottom = safeAreaBottom;
    } else {
      // SafeArea değeri yoksa (home indicator yok) - sadece tab bar için padding
      minSafeAreaBottom = 0.0; // Home indicator yok, sadece tab bar padding'i kullan
    }
    
    // Toplam bottom navigation bar yüksekliği
    return minSafeAreaBottom + tabBarHeight + tabBarPadding;
  }
  
  /// Navbar'ın hemen üstünde konumlandırma için bottom değeri
  static double getBottomPosition(BuildContext context) {
    final bottomNavBarHeight = _getBottomNavBarHeight(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Bottom navigation bar'ın üstünde 16px boşluk bırak
    final basePosition = bottomNavBarHeight + 16.0;
    
    // Ekran boyutuna göre ek padding
    if (screenHeight < 700) {
      // Küçük ekranlar - daha az padding
      return basePosition + 4.0;
    } else if (screenHeight < 800) {
      // Orta ekranlar - normal padding
      return basePosition + 8.0;
    } else if (screenHeight < 900) {
      // Büyük ekranlar - biraz daha fazla padding
      return basePosition + 12.0;
    } else {
      // Çok büyük ekranlar - maksimum padding
      return basePosition + 16.0;
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
  
  /// Debug için bottom navigation bar bilgilerini yazdır
  static void debugBottomNavInfo(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final bottomNavBarHeight = _getBottomNavBarHeight(context);
    final fabPosition = getBottomPosition(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Cihaz türü tespiti
    String deviceType = 'Unknown';
    String homeIndicatorStatus = safeAreaBottom > 0 ? 'Yes' : 'No';
    
    if (screenHeight > 800) {
      deviceType = 'Large (Pro Max/Tablet)';
    } else if (screenHeight > 700) {
      deviceType = 'Medium (Standard)';
    } else {
      deviceType = 'Small (SE/Mini)';
    }
    
    debugPrint('=== FAB Positioning Debug ===');
    debugPrint('Device Type: $deviceType');
    debugPrint('Screen Size: ${screenWidth.toInt()}x${screenHeight.toInt()}');
    debugPrint('Home Indicator: $homeIndicatorStatus');
    debugPrint('SafeArea Bottom: $safeAreaBottom');
    debugPrint('Bottom Nav Bar Height: $bottomNavBarHeight');
    debugPrint('FAB Bottom Position: $fabPosition');
    debugPrint('Available Space Above Nav: ${(screenHeight - fabPosition).toInt()}');
    debugPrint('FAB Distance from Bottom: ${(screenHeight - fabPosition).toInt()}');
    debugPrint('=============================');
  }
}
