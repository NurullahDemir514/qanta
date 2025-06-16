import 'package:flutter/material.dart';

/// Centralized service for category icons and colors
/// 
/// This service provides consistent icon and color mapping for all
/// category selectors throughout the app, ensuring visual consistency
/// and making it easy to update icons globally.
/// 
/// **Features:**
/// - Comprehensive icon mapping for all categories
/// - Consistent color scheme for expense/income categories  
/// - Support for custom user categories
/// - Fallback icons for unknown categories
/// - Material 3 Design System compliance
/// - Expanded lifestyle and modern categories
/// 
/// **Usage:**
/// ```dart
/// IconData icon = CategoryIconService.getIcon('restaurant');
/// Color color = CategoryIconService.getColor('#FF6B6B');
/// Color bgColor = CategoryIconService.getBackgroundColor('#FF6B6B');
/// ```
class CategoryIconService {
  
  /// Get icon data from icon name string
  /// 
  /// Supports multiple variations of icon names for flexibility:
  /// - 'restaurant', 'food', 'yemek' -> restaurant icon
  /// - 'car', 'transport', 'ulaşım' -> car icon
  /// - etc.
  static IconData getIcon(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      // === INCOME ICONS ===
      case 'work':
      case 'salary':
      case 'maaş':
        return Icons.work_rounded;
      case 'business':
      case 'iş':
        return Icons.business_rounded;
      case 'investment':
      case 'yatırım':
        return Icons.trending_up_rounded;
      case 'gift':
      case 'hediye':
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'rental':
      case 'kira':
      case 'home':
        return Icons.home_rounded;
      case 'freelance':
      case 'laptop':
        return Icons.laptop_rounded;
      case 'bonus':
      case 'star':
        return Icons.star_rounded;
      case 'commission':
      case 'komisyon':
        return Icons.percent_rounded;
      case 'dividend':
      case 'temettü':
        return Icons.account_balance_rounded;
      case 'crypto':
      case 'kripto':
        return Icons.currency_bitcoin_rounded;
      case 'stocks':
      case 'hisse':
        return Icons.show_chart_rounded;
      case 'royalty':
      case 'telif':
        return Icons.copyright_rounded;
      case 'pension':
      case 'emekli':
        return Icons.elderly_rounded;
      case 'social_benefits':
      case 'sosyal_yardım':
        return Icons.volunteer_activism_rounded;
      
      // === EXPENSE ICONS ===
      // Food & Dining
      case 'food':
      case 'restaurant':
      case 'yemek':
        return Icons.restaurant_rounded;
      case 'coffee':
      case 'kahve':
        return Icons.local_cafe_rounded;
      case 'groceries':
      case 'market':
        return Icons.local_grocery_store_rounded;
      case 'fast_food':
      case 'fast':
        return Icons.fastfood_rounded;
      case 'alcohol':
      case 'alkol':
        return Icons.local_bar_rounded;
      case 'delivery':
      case 'teslimat':
        return Icons.delivery_dining_rounded;
      
      // Transportation
      case 'transport':
      case 'car':
      case 'directions_car':
      case 'ulaşım':
        return Icons.directions_car_rounded;
      case 'fuel':
      case 'gas':
      case 'local_gas_station':
      case 'yakıt':
        return Icons.local_gas_station_rounded;
      case 'public_transport':
      case 'toplu_taşıma':
        return Icons.directions_bus_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'parking':
      case 'park':
        return Icons.local_parking_rounded;
      case 'motorcycle':
      case 'motosiklet':
        return Icons.two_wheeler_rounded;
      case 'bicycle':
      case 'bisiklet':
        return Icons.pedal_bike_rounded;
      case 'train':
      case 'tren':
        return Icons.train_rounded;
      case 'subway':
      case 'metro':
        return Icons.subway_rounded;
      
      // Shopping
      case 'shopping':
      case 'shopping_cart':
      case 'shopping_bag':
      case 'alışveriş':
        return Icons.shopping_bag_rounded;
      case 'clothing':
      case 'kıyafet':
        return Icons.checkroom_rounded;
      case 'electronics':
      case 'elektronik':
        return Icons.devices_rounded;
      case 'furniture':
      case 'mobilya':
        return Icons.chair_rounded;
      case 'books':
      case 'kitap':
        return Icons.menu_book_rounded;
      case 'gifts':
      case 'hediyeler':
        return Icons.card_giftcard_rounded;
      case 'jewelry':
      case 'mücevher':
        return Icons.diamond_rounded;
      case 'shoes':
      case 'ayakkabı':
        return Icons.sports_rounded;
      
      // Entertainment & Lifestyle
      case 'entertainment':
      case 'movie':
      case 'eğlence':
        return Icons.movie_rounded;
      case 'music':
      case 'müzik':
        return Icons.music_note_rounded;
      case 'gaming':
      case 'oyun':
        return Icons.sports_esports_rounded;
      case 'streaming':
      case 'yayın':
        return Icons.play_circle_rounded;
      case 'concerts':
      case 'konser':
        return Icons.library_music_rounded;
      case 'nightlife':
      case 'gece_hayatı':
        return Icons.nightlife_rounded;
      case 'hobbies':
      case 'hobi':
        return Icons.palette_rounded;
      case 'photography':
      case 'fotoğraf':
        return Icons.camera_alt_rounded;
      
      // Bills & Utilities
      case 'bills':
      case 'receipt':
      case 'receipt_long':
      case 'faturalar':
        return Icons.receipt_long_rounded;
      case 'electricity':
      case 'elektrik':
        return Icons.bolt_rounded;
      case 'water':
      case 'su':
        return Icons.water_drop_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'phone':
      case 'telefon':
        return Icons.phone_rounded;
      case 'cable_tv':
      case 'tv':
        return Icons.tv_rounded;
      case 'subscription':
      case 'abonelik':
        return Icons.subscriptions_rounded;
      case 'insurance':
      case 'sigorta':
        return Icons.security_rounded;
      case 'bank_fees':
      case 'banka_ücreti':
        return Icons.account_balance_rounded;
      
      // Health & Wellness
      case 'health':
      case 'healthcare':
      case 'health_and_safety':
      case 'local_hospital':
      case 'sağlık':
        return Icons.local_hospital_rounded;
      case 'doctor':
      case 'doktor':
        return Icons.medical_services_rounded;
      case 'pharmacy':
      case 'eczane':
        return Icons.local_pharmacy_rounded;
      case 'dental':
      case 'diş':
        return Icons.medical_services_rounded;
      case 'fitness':
      case 'gym':
      case 'spor':
        return Icons.fitness_center_rounded;
      case 'spa':
      case 'beauty':
      case 'güzellik':
        return Icons.spa_rounded;
      case 'therapy':
      case 'terapi':
        return Icons.psychology_rounded;
      case 'nutrition':
      case 'beslenme':
        return Icons.dining_rounded;
      
      // Education & Learning
      case 'education':
      case 'school':
      case 'eğitim':
        return Icons.school_rounded;
      case 'university':
      case 'üniversite':
        return Icons.account_balance_rounded;
      case 'course':
      case 'kurs':
        return Icons.class_rounded;
      case 'certification':
      case 'sertifika':
        return Icons.workspace_premium_rounded;
      case 'tutoring':
      case 'ders':
        return Icons.person_rounded;
      case 'supplies':
      case 'malzeme':
        return Icons.inventory_rounded;
      
      // Travel & Vacation
      case 'travel':
      case 'flight':
      case 'seyahat':
        return Icons.flight_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'vacation':
      case 'tatil':
        return Icons.beach_access_rounded;
      case 'cruise':
      case 'gemi':
        return Icons.directions_boat_rounded;
      case 'camping':
      case 'kamp':
        return Icons.terrain_rounded;
      case 'luggage':
      case 'bavul':
        return Icons.luggage_rounded;
      
      // Housing & Home
      case 'housing':
      case 'rent':
      case 'ev':
        return Icons.home_rounded;
      case 'mortgage':
      case 'mortgage':
        return Icons.real_estate_agent_rounded;
      case 'repairs':
      case 'tamir':
        return Icons.build_rounded;
      case 'cleaning':
      case 'temizlik':
        return Icons.cleaning_services_rounded;
      case 'garden':
      case 'bahçe':
        return Icons.grass_rounded;
      case 'decoration':
      case 'dekorasyon':
        return Icons.design_services_rounded;
      
      // Technology & Digital
      case 'tech':
      case 'teknoloji':
        return Icons.computer_rounded;
      case 'software':
      case 'yazılım':
        return Icons.code_rounded;
      case 'cloud':
      case 'bulut':
        return Icons.cloud_rounded;
      case 'domain':
      case 'alan_adı':
        return Icons.language_rounded;
      case 'apps':
      case 'uygulamalar':
        return Icons.apps_rounded;
      
      // Personal Care & Family
      case 'personal_care':
      case 'kişisel_bakım':
        return Icons.face_rounded;
      case 'haircut':
      case 'kuaför':
        return Icons.content_cut_rounded;
      case 'childcare':
      case 'çocuk_bakımı':
        return Icons.child_care_rounded;
      case 'pets':
      case 'evcil_hayvan':
        return Icons.pets_rounded;
      case 'vet':
      case 'veteriner':
        return Icons.local_hospital_rounded;
      case 'elderly_care':
      case 'yaşlı_bakımı':
        return Icons.elderly_rounded;
      
      // Financial & Investment
      case 'fees':
      case 'ücretler':
        return Icons.monetization_on_rounded;
      case 'taxes':
      case 'vergiler':
        return Icons.receipt_long_rounded;
      case 'loans':
      case 'krediler':
        return Icons.credit_score_rounded;
      case 'savings':
      case 'tasarruf':
        return Icons.savings_rounded;
      
      // Emergency & Others
      case 'emergency':
      case 'acil':
        return Icons.emergency_rounded;
      case 'charity':
      case 'hayır':
        return Icons.volunteer_activism_rounded;
      case 'legal':
      case 'hukuki':
        return Icons.gavel_rounded;
      case 'professional':
      case 'profesyonel':
        return Icons.business_center_rounded;
      
      // === TRANSFER ICONS ===
      case 'transfer':
      case 'swap':
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'payment':
      case 'ödeme':
        return Icons.payment_rounded;
      case 'send_money':
      case 'para_gönder':
        return Icons.send_rounded;
      case 'receive_money':
      case 'para_al':
        return Icons.call_received_rounded;
      
      // === DEFAULT/FALLBACK ===
      case 'other':
      case 'category':
      case 'diğer':
      default:
        return Icons.more_horiz_rounded;
    }
  }
  
  /// Get color from hex string
  /// 
  /// Converts hex color strings to Flutter Color objects.
  /// Handles various formats (#FF6B6B, FF6B6B, etc.)
  /// Returns default gray if parsing fails.
  static Color getColor(String colorHex) {
    try {
      String cleanHex = colorHex.trim();
      
      // Remove # if present
      if (cleanHex.startsWith('#')) {
        cleanHex = cleanHex.substring(1);
      }
      
      // Add alpha if only 6 characters (RGB)
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFF6B7280); // Default gray
    }
  }
  
  /// Get background color with opacity
  /// 
  /// Returns the category color with 10% opacity for use
  /// as background color in category selectors.
  static Color getBackgroundColor(String colorHex) {
    return getColor(colorHex).withOpacity(0.1);
  }
  
  /// Get predefined color for expense categories
  /// 
  /// Returns consistent colors for common expense categories
  /// based on icon name rather than stored color value.
  static Color getExpenseColor(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      // Food & Dining - Muted warm tones
      case 'restaurant':
      case 'food':
      case 'yemek':
        return const Color(0xFFFF6B35); // Soft coral
      case 'coffee':
      case 'kahve':
        return const Color(0xFF8E6A5B); // Muted brown
      case 'groceries':
      case 'market':
        return const Color(0xFF32D74B); // iOS system green
      case 'fast_food':
      case 'fast':
        return const Color(0xFFFF9500); // iOS system orange
      case 'alcohol':
      case 'alkol':
        return const Color(0xFFAF52DE); // iOS system purple
      case 'delivery':
      case 'teslimat':
        return const Color(0xFF64D2FF); // iOS system light blue
      
      // Transportation - Cool muted blues and grays
      case 'transport':
      case 'car':
      case 'directions_car':
      case 'ulaşım':
        return const Color(0xFF007AFF); // iOS system blue
      case 'fuel':
      case 'gas':
      case 'local_gas_station':
      case 'yakıt':
        return const Color(0xFF8E8E93); // iOS secondary label
      case 'public_transport':
      case 'toplu_taşıma':
        return const Color(0xFF5AC8FA); // iOS system light blue
      case 'taxi':
        return const Color(0xFFFFCC02); // iOS system yellow
      case 'parking':
      case 'park':
        return const Color(0xFF6D6D70); // iOS tertiary label
      case 'motorcycle':
      case 'motosiklet':
        return const Color(0xFF48484A); // iOS quaternary label
      case 'bicycle':
      case 'bisiklet':
        return const Color(0xFF34C759); // iOS system green
      
      // Shopping - Soft pastels
      case 'shopping':
      case 'shopping_cart':
      case 'shopping_bag':
      case 'alışveriş':
        return const Color(0xFFFF9F0A); // iOS system orange
      case 'clothing':
      case 'kıyafet':
        return const Color(0xFFFF2D92); // iOS system pink
      case 'electronics':
      case 'elektronik':
        return const Color(0xFF007AFF); // iOS system blue
      case 'furniture':
      case 'mobilya':
        return const Color(0xFF8E6A5B); // Muted brown
      case 'books':
      case 'kitap':
        return const Color(0xFF8E8E93); // iOS secondary label
      case 'jewelry':
      case 'mücevher':
        return const Color(0xFFFFD60A); // iOS system yellow
      
      // Entertainment & Lifestyle - Vibrant but muted
      case 'entertainment':
      case 'movie':
      case 'eğlence':
        return const Color(0xFFBF5AF2); // iOS system purple
      case 'music':
      case 'müzik':
        return const Color(0xFFAF52DE); // iOS system purple
      case 'gaming':
      case 'oyun':
        return const Color(0xFF30D158); // iOS system green
      case 'streaming':
      case 'yayın':
        return const Color(0xFFFF3B30); // iOS system red
      case 'concerts':
      case 'konser':
        return const Color(0xFF5E5CE6); // iOS system indigo
      case 'photography':
      case 'fotoğraf':
        return const Color(0xFF8E8E93); // iOS secondary label
      
      // Bills & Utilities - Professional grays and blues
      case 'bills':
      case 'receipt':
      case 'receipt_long':
      case 'faturalar':
        return const Color(0xFF007AFF); // iOS system blue
      case 'electricity':
      case 'elektrik':
        return const Color(0xFFFFD60A); // iOS system yellow
      case 'water':
      case 'su':
        return const Color(0xFF64D2FF); // iOS system light blue
      case 'internet':
        return const Color(0xFF5AC8FA); // iOS system light blue
      case 'phone':
      case 'telefon':
        return const Color(0xFF34C759); // iOS system green
      case 'subscription':
      case 'abonelik':
        return const Color(0xFFFF9500); // iOS system orange
      case 'insurance':
      case 'sigorta':
        return const Color(0xFF007AFF); // iOS system blue
      
      // Health & Wellness - Soft greens and blues
      case 'health':
      case 'healthcare':
      case 'health_and_safety':
      case 'local_hospital':
      case 'sağlık':
        return const Color(0xFF30D158); // iOS system green
      case 'doctor':
      case 'doktor':
        return const Color(0xFF64D2FF); // iOS system light blue
      case 'pharmacy':
      case 'eczane':
        return const Color(0xFF32D74B); // iOS system green
      case 'fitness':
      case 'gym':
      case 'spor':
        return const Color(0xFF30D158); // iOS system green
      case 'spa':
      case 'beauty':
      case 'güzellik':
        return const Color(0xFFFF2D92); // iOS system pink
      
      // Education & Learning - Professional blues
      case 'education':
      case 'school':
      case 'eğitim':
        return const Color(0xFF007AFF); // iOS system blue
      case 'university':
      case 'üniversite':
        return const Color(0xFF5E5CE6); // iOS system indigo
      case 'course':
      case 'kurs':
        return const Color(0xFF5AC8FA); // iOS system light blue
      
      // Travel & Vacation - Adventure colors
      case 'travel':
      case 'flight':
      case 'seyahat':
        return const Color(0xFF5E5CE6); // iOS system indigo
      case 'hotel':
        return const Color(0xFFFF9500); // iOS system orange
      case 'vacation':
      case 'tatil':
        return const Color(0xFF64D2FF); // iOS system light blue
      
      // Technology & Digital - Tech blues and purples
      case 'tech':
      case 'teknoloji':
        return const Color(0xFF007AFF); // iOS system blue
      case 'software':
      case 'yazılım':
        return const Color(0xFFBF5AF2); // iOS system purple
      
      // Personal Care & Family - Warm pastels
      case 'personal_care':
      case 'kişisel_bakım':
        return const Color(0xFFFF2D92); // iOS system pink
      case 'pets':
      case 'evcil_hayvan':
        return const Color(0xFF8E6A5B); // Muted brown
      case 'childcare':
      case 'çocuk_bakımı':
        return const Color(0xFFFFB3BA); // Soft pink
      
      default:
        return const Color(0xFF8E8E93); // iOS secondary label
    }
  }
  
  /// Get predefined color for income categories
  /// 
  /// Returns consistent colors for common income categories
  /// based on icon name rather than stored color value.
  static Color getIncomeColor(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      case 'work':
      case 'salary':
      case 'maaş':
        return const Color(0xFF34C759); // iOS system green
      case 'freelance':
      case 'laptop':
        return const Color(0xFF007AFF); // iOS system blue
      case 'business':
      case 'iş':
        return const Color(0xFFBF5AF2); // iOS system purple
      case 'investment':
      case 'yatırım':
        return const Color(0xFFFF9500); // iOS system orange
      case 'rental':
      case 'kira':
      case 'home':
        return const Color(0xFF30D158); // iOS system green
      case 'bonus':
      case 'star':
        return const Color(0xFFFF3B30); // iOS system red
      case 'gift':
      case 'hediye':
      case 'card_giftcard':
        return const Color(0xFFFF2D92); // iOS system pink
      case 'commission':
      case 'komisyon':
        return const Color(0xFF32D74B); // iOS system green
      case 'dividend':
      case 'temettü':
        return const Color(0xFF30D158); // iOS system green
      case 'crypto':
      case 'kripto':
        return const Color(0xFFFF9F0A); // iOS system orange
      case 'stocks':
      case 'hisse':
        return const Color(0xFF64D2FF); // iOS system light blue
      case 'royalty':
      case 'telif':
        return const Color(0xFFAF52DE); // iOS system purple
      case 'pension':
      case 'emekli':
        return const Color(0xFF5AC8FA); // iOS system light blue
      case 'social_benefits':
      case 'sosyal_yardım':
        return const Color(0xFF5E5CE6); // iOS system indigo
      default:
        return const Color(0xFF8E8E93); // iOS secondary label
    }
  }
  
  /// Get appropriate color based on category type
  /// 
  /// Uses predefined color schemes for income/expense categories
  /// or falls back to hex color parsing.
  static Color getCategoryColor({
    required String iconName,
    required String colorHex,
    required bool isIncomeCategory,
  }) {
    if (isIncomeCategory) {
      return getIncomeColor(iconName);
    } else {
      return getExpenseColor(iconName);
    }
  }
  
  /// Get all available expense category icons
  static Map<String, IconData> getAllExpenseIcons() {
    return {
      // Food & Dining
      'restaurant': Icons.restaurant_rounded,
      'coffee': Icons.local_cafe_rounded,
      'groceries': Icons.local_grocery_store_rounded,
      'fast_food': Icons.fastfood_rounded,
      'alcohol': Icons.local_bar_rounded,
      'delivery': Icons.delivery_dining_rounded,
      
      // Transportation
      'car': Icons.directions_car_rounded,
      'fuel': Icons.local_gas_station_rounded,
      'public_transport': Icons.directions_bus_rounded,
      'taxi': Icons.local_taxi_rounded,
      'parking': Icons.local_parking_rounded,
      'bicycle': Icons.pedal_bike_rounded,
      
      // Shopping
      'shopping': Icons.shopping_bag_rounded,
      'clothing': Icons.checkroom_rounded,
      'electronics': Icons.devices_rounded,
      'furniture': Icons.chair_rounded,
      'books': Icons.menu_book_rounded,
      'jewelry': Icons.diamond_rounded,
      
      // Entertainment
      'entertainment': Icons.movie_rounded,
      'music': Icons.music_note_rounded,
      'gaming': Icons.sports_esports_rounded,
      'streaming': Icons.play_circle_rounded,
      'photography': Icons.camera_alt_rounded,
      
      // Bills & Utilities
      'bills': Icons.receipt_long_rounded,
      'electricity': Icons.bolt_rounded,
      'water': Icons.water_drop_rounded,
      'internet': Icons.wifi_rounded,
      'phone': Icons.phone_rounded,
      'subscription': Icons.subscriptions_rounded,
      'insurance': Icons.security_rounded,
      
      // Health & Wellness
      'health': Icons.local_hospital_rounded,
      'doctor': Icons.medical_services_rounded,
      'pharmacy': Icons.local_pharmacy_rounded,
      'fitness': Icons.fitness_center_rounded,
      'beauty': Icons.spa_rounded,
      
      // Education
      'education': Icons.school_rounded,
      'university': Icons.account_balance_rounded,
      'course': Icons.class_rounded,
      
      // Travel
      'travel': Icons.flight_rounded,
      'hotel': Icons.hotel_rounded,
      'vacation': Icons.beach_access_rounded,
      
      // Personal Care
      'personal_care': Icons.face_rounded,
      'pets': Icons.pets_rounded,
      'childcare': Icons.child_care_rounded,
      
      // Technology
      'tech': Icons.computer_rounded,
      'software': Icons.code_rounded,
      
      // Others
      'other': Icons.more_horiz_rounded,
    };
  }
  
  /// Get all available income category icons
  static Map<String, IconData> getAllIncomeIcons() {
    return {
      'work': Icons.work_rounded,
      'business': Icons.business_rounded,
      'investment': Icons.trending_up_rounded,
      'gift': Icons.card_giftcard_rounded,
      'rental': Icons.home_rounded,
      'freelance': Icons.laptop_rounded,
      'bonus': Icons.star_rounded,
      'commission': Icons.percent_rounded,
      'dividend': Icons.account_balance_rounded,
      'crypto': Icons.currency_bitcoin_rounded,
      'stocks': Icons.show_chart_rounded,
      'royalty': Icons.copyright_rounded,
      'pension': Icons.elderly_rounded,
      'social_benefits': Icons.volunteer_activism_rounded,
      'other': Icons.more_horiz_rounded,
    };
  }
} 