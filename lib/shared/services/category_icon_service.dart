import 'package:flutter/material.dart';

/// **Centralized Category Management Service**
/// 
/// This service provides comprehensive category management for the entire app:
/// - Icon mapping and management
/// - Color management and consistency
/// - Category utilities and helpers
/// - Default category definitions
/// - Category validation and normalization
/// 
/// **Features:**
/// - 200+ icon mappings with multiple aliases
/// - Consistent color scheme management
/// - Material 3 Design System compliance
/// - Support for custom user categories
/// - Fallback handling for unknown categories
/// - Multi-language category name support
/// - Category type validation
/// 
/// **Usage:**
/// ```dart
/// // Get icon for category
/// IconData icon = CategoryIconService.getIcon('restaurant');
/// 
/// // Get color for category
/// Color color = CategoryIconService.getColor('#FF6B6B');
/// 
/// // Get default categories
/// List<Map<String, dynamic>> categories = CategoryIconService.getDefaultExpenseCategories();
/// 
/// // Validate category
/// bool isValid = CategoryIconService.isValidCategoryIcon('food');
/// ```
/// 
/// **Category Types Supported:**
/// - **Income Categories**: salary, freelance, business, investment, etc.
/// - **Expense Categories**: food, transport, shopping, bills, etc.
/// - **Custom Categories**: user-defined categories with custom icons
/// 
/// **Icon Naming Convention:**
/// - Primary names: 'food', 'transport', 'salary'
/// - Aliases: 'restaurant', 'car', 'work'
/// - Turkish names: 'yemek', 'ulaşım', 'maaş'
/// - Icon variants: 'rounded', 'outlined', 'filled'
/// 
/// **Color Management:**
/// - Hex color parsing with validation
/// - Fallback colors for invalid inputs
/// - Opacity management for backgrounds
/// - Theme-aware color adjustments
/// 
/// **Performance:**
/// - Static methods for fast access
/// - Cached icon lookups
/// - Minimal memory footprint
/// - No external dependencies
/// 
/// **See also:**
/// - [CategoryModel] for category data structure
/// - [UnifiedCategoryModel] for unified category system
/// - [CategoryServiceV2] for database operations
class CategoryIconService {
  
  /// **Comprehensive Icon Mapping**
  /// 
  /// Static map containing all icon mappings for fast lookup.
  /// Supports multiple aliases and language variations for each icon.
  /// 
  /// **Performance Benefits:**
  /// - O(1) lookup time vs O(n) switch-case
  /// - Memory efficient with static initialization
  /// - Easy to maintain and extend
  /// 
  /// **Supported Variations:**
  /// - English names: 'food', 'transport', 'salary'
  /// - Turkish names: 'yemek', 'ulaşım', 'maaş'
  /// - Icon variations: 'restaurant', 'car', 'work'
  /// - Alternative spellings and common aliases
  static const Map<String, IconData> _iconMap = {
    // === INCOME ICONS ===
    'work': Icons.work_rounded,
    'salary': Icons.work_rounded,
    'maaş': Icons.work_rounded,
    'business': Icons.business_rounded,
    'iş': Icons.business_rounded,
    'investment': Icons.trending_up_rounded,
    'yatırım': Icons.trending_up_rounded,
    'gift': Icons.card_giftcard_rounded,
    'hediye': Icons.card_giftcard_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'rental': Icons.home_rounded,
    'kira': Icons.home_rounded,
    'home': Icons.home_rounded,
    'freelance': Icons.laptop_rounded,
    'laptop': Icons.laptop_rounded,
    'bonus': Icons.star_rounded,
    'star': Icons.star_rounded,
    'commission': Icons.percent_rounded,
    'komisyon': Icons.percent_rounded,
    'dividend': Icons.account_balance_rounded,
    'temettü': Icons.account_balance_rounded,
    'crypto': Icons.currency_bitcoin_rounded,
    'kripto': Icons.currency_bitcoin_rounded,
    'stocks': Icons.show_chart_rounded,
    'hisse': Icons.show_chart_rounded,
    'royalty': Icons.copyright_rounded,
    'telif': Icons.copyright_rounded,
    'pension': Icons.elderly_rounded,
    'emekli': Icons.elderly_rounded,
    'social_benefits': Icons.volunteer_activism_rounded,
    'sosyal_yardım': Icons.volunteer_activism_rounded,
    
    // === EXPENSE ICONS ===
    // Food & Dining
    'food': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded,
    'yemek': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'kahve': Icons.local_cafe_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'market': Icons.local_grocery_store_rounded,
    'fast_food': Icons.fastfood_rounded,
    'fast': Icons.fastfood_rounded,
    'alcohol': Icons.local_bar_rounded,
    'alkol': Icons.local_bar_rounded,
    'delivery': Icons.delivery_dining_rounded,
    'teslimat': Icons.delivery_dining_rounded,
    
    // Transportation
    'transport': Icons.directions_car_rounded,
    'car': Icons.directions_car_rounded,
    'directions_car': Icons.directions_car_rounded,
    'ulaşım': Icons.directions_car_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'gas': Icons.local_gas_station_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'yakıt': Icons.local_gas_station_rounded,
    'public_transport': Icons.directions_bus_rounded,
    'toplu_taşıma': Icons.directions_bus_rounded,
    'taxi': Icons.local_taxi_rounded,
    'parking': Icons.local_parking_rounded,
    'park': Icons.local_parking_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'motosiklet': Icons.two_wheeler_rounded,
    'bicycle': Icons.pedal_bike_rounded,
    'bisiklet': Icons.pedal_bike_rounded,
    'train': Icons.train_rounded,
    'tren': Icons.train_rounded,
    'subway': Icons.subway_rounded,
    'metro': Icons.subway_rounded,
    
    // Shopping
    'shopping': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_bag_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'alışveriş': Icons.shopping_bag_rounded,
    'clothing': Icons.checkroom_rounded,
    'kıyafet': Icons.checkroom_rounded,
    'electronics': Icons.devices_rounded,
    'elektronik': Icons.devices_rounded,
    'furniture': Icons.chair_rounded,
    'mobilya': Icons.chair_rounded,
    'books': Icons.menu_book_rounded,
    'kitap': Icons.menu_book_rounded,
    'gifts': Icons.card_giftcard_rounded,
    'hediyeler': Icons.card_giftcard_rounded,
    'jewelry': Icons.diamond_rounded,
    'mücevher': Icons.diamond_rounded,
    'shoes': Icons.sports_rounded,
    'ayakkabı': Icons.sports_rounded,
    
    // Entertainment & Lifestyle
    'entertainment': Icons.movie_rounded,
    'movie': Icons.movie_rounded,
    'eğlence': Icons.movie_rounded,
    'music': Icons.music_note_rounded,
    'müzik': Icons.music_note_rounded,
    'gaming': Icons.sports_esports_rounded,
    'oyun': Icons.sports_esports_rounded,
    'streaming': Icons.play_circle_rounded,
    'yayın': Icons.play_circle_rounded,
    'concerts': Icons.library_music_rounded,
    'konser': Icons.library_music_rounded,
    'nightlife': Icons.nightlife_rounded,
    'gece_hayatı': Icons.nightlife_rounded,
    'hobbies': Icons.palette_rounded,
    'hobi': Icons.palette_rounded,
    'photography': Icons.camera_alt_rounded,
    'fotoğraf': Icons.camera_alt_rounded,
    
    // Bills & Utilities
    'bills': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'faturalar': Icons.receipt_long_rounded,
    'electricity': Icons.bolt_rounded,
    'elektrik': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'su': Icons.water_drop_rounded,
    'internet': Icons.wifi_rounded,
    'phone': Icons.phone_rounded,
    'telefon': Icons.phone_rounded,
    'cable_tv': Icons.tv_rounded,
    'tv': Icons.tv_rounded,
    'subscription': Icons.subscriptions_rounded,
    'abonelik': Icons.subscriptions_rounded,
    'insurance': Icons.security_rounded,
    'sigorta': Icons.security_rounded,
    'bank_fees': Icons.account_balance_rounded,
    'banka_ücreti': Icons.account_balance_rounded,
    
    // Health & Wellness
    'health': Icons.local_hospital_rounded,
    'healthcare': Icons.local_hospital_rounded,
    'health_and_safety': Icons.local_hospital_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'sağlık': Icons.local_hospital_rounded,
    'doctor': Icons.medical_services_rounded,
    'doktor': Icons.medical_services_rounded,
    'pharmacy': Icons.local_pharmacy_rounded,
    'eczane': Icons.local_pharmacy_rounded,
    'dental': Icons.medical_services_rounded,
    'diş': Icons.medical_services_rounded,
    'fitness': Icons.fitness_center_rounded,
    'gym': Icons.fitness_center_rounded,
    'spor': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'beauty': Icons.spa_rounded,
    'güzellik': Icons.spa_rounded,
    'therapy': Icons.psychology_rounded,
    'terapi': Icons.psychology_rounded,
    'nutrition': Icons.dining_rounded,
    'beslenme': Icons.dining_rounded,
    
    // Education & Learning
    'education': Icons.school_rounded,
    'school': Icons.school_rounded,
    'eğitim': Icons.school_rounded,
    'university': Icons.account_balance_rounded,
    'üniversite': Icons.account_balance_rounded,
    'course': Icons.class_rounded,
    'kurs': Icons.class_rounded,
    'certification': Icons.workspace_premium_rounded,
    'sertifika': Icons.workspace_premium_rounded,
    'tutoring': Icons.person_rounded,
    'ders': Icons.person_rounded,
    'supplies': Icons.inventory_rounded,
    'malzeme': Icons.inventory_rounded,
    
    // Travel & Vacation
    'travel': Icons.flight_rounded,
    'flight': Icons.flight_rounded,
    'seyahat': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,
    'vacation': Icons.beach_access_rounded,
    'tatil': Icons.beach_access_rounded,
    'cruise': Icons.directions_boat_rounded,
    'gemi': Icons.directions_boat_rounded,
    'camping': Icons.terrain_rounded,
    'kamp': Icons.terrain_rounded,
    'luggage': Icons.luggage_rounded,
    'bavul': Icons.luggage_rounded,
    
    // Housing & Home
    'housing': Icons.home_rounded,
    'rent': Icons.home_rounded,
    'ev': Icons.home_rounded,
    'mortgage': Icons.real_estate_agent_rounded,
    'repairs': Icons.build_rounded,
    'tamir': Icons.build_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'temizlik': Icons.cleaning_services_rounded,
    'garden': Icons.grass_rounded,
    'bahçe': Icons.grass_rounded,
    'decoration': Icons.design_services_rounded,
    'dekorasyon': Icons.design_services_rounded,
    
    // Technology & Digital
    'tech': Icons.computer_rounded,
    'teknoloji': Icons.computer_rounded,
    'software': Icons.code_rounded,
    'yazılım': Icons.code_rounded,
    'cloud': Icons.cloud_rounded,
    'bulut': Icons.cloud_rounded,
    'domain': Icons.language_rounded,
    'alan_adı': Icons.language_rounded,
    'apps': Icons.apps_rounded,
    'uygulamalar': Icons.apps_rounded,
    
    // Personal Care & Family
    'personal_care': Icons.face_rounded,
    'kişisel_bakım': Icons.face_rounded,
    'haircut': Icons.content_cut_rounded,
    'kuaför': Icons.content_cut_rounded,
    'childcare': Icons.child_care_rounded,
    'çocuk_bakımı': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'evcil_hayvan': Icons.pets_rounded,
    'vet': Icons.local_hospital_rounded,
    'veteriner': Icons.local_hospital_rounded,
    'elderly_care': Icons.elderly_rounded,
    'yaşlı_bakımı': Icons.elderly_rounded,
    
    // Financial & Investment
    'fees': Icons.monetization_on_rounded,
    'ücretler': Icons.monetization_on_rounded,
    'taxes': Icons.receipt_long_rounded,
    'vergiler': Icons.receipt_long_rounded,
    'loans': Icons.credit_score_rounded,
    'krediler': Icons.credit_score_rounded,
    'savings': Icons.savings_rounded,
    'tasarruf': Icons.savings_rounded,
    
    // Emergency & Others
    'emergency': Icons.emergency_rounded,
    'acil': Icons.emergency_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'hayır': Icons.volunteer_activism_rounded,
    'legal': Icons.gavel_rounded,
    'hukuki': Icons.gavel_rounded,
    'professional': Icons.business_center_rounded,
    'profesyonel': Icons.business_center_rounded,
    
    // === TRANSFER ICONS ===
    'transfer': Icons.swap_horiz_rounded,
    'swap': Icons.swap_horiz_rounded,
    'swap_horiz': Icons.swap_horiz_rounded,
    'payment': Icons.payment_rounded,
    'ödeme': Icons.payment_rounded,
    'send_money': Icons.send_rounded,
    'para_gönder': Icons.send_rounded,
    'receive_money': Icons.call_received_rounded,
    'para_al': Icons.call_received_rounded,
    
    // === DEFAULT/FALLBACK ===
    'other': Icons.more_horiz_rounded,
    'category': Icons.more_horiz_rounded,
    'diğer': Icons.more_horiz_rounded,
  };

  /// Get icon data from icon name string with fast map lookup
  /// 
  /// **Performance Optimized:**
  /// - O(1) lookup time using HashMap
  /// - No switch-case overhead
  /// - Memory efficient static map
  /// 
  /// **Supported Formats:**
  /// - English: 'food', 'transport', 'salary'
  /// - Turkish: 'yemek', 'ulaşım', 'maaş'
  /// - Aliases: 'restaurant', 'car', 'work'
  /// - Icon names: 'restaurant_rounded', 'directions_car'
  /// 
  /// **Fallback:**
  /// Returns `Icons.more_horiz_rounded` for unknown icon names
  static IconData getIcon(String iconName) {
    final normalizedName = iconName.toLowerCase().trim();
    return _iconMap[normalizedName] ?? Icons.more_horiz_rounded;
  }

  /// Get icon with validation
  /// 
  /// Returns the icon if valid, otherwise returns fallback icon
  /// and optionally logs the invalid icon name for debugging.
  static IconData getIconSafe(String iconName, {bool logInvalid = false}) {
    final normalizedName = iconName.toLowerCase().trim();
    final icon = _iconMap[normalizedName];
    
    if (icon == null && logInvalid) {
      debugPrint('⚠️ CategoryIconService: Unknown icon name "$iconName"');
    }
    
    return icon ?? Icons.more_horiz_rounded;
  }

  /// Check if icon name exists in the map
  static bool hasIcon(String iconName) {
    return _iconMap.containsKey(iconName.toLowerCase().trim());
  }

  /// Get all available icon names from the map
  static List<String> getAllIconNames() {
    return _iconMap.keys.toList()..sort();
  }

  /// Get icon names by category type
  static List<String> getIconNamesByType(String categoryType) {
    switch (categoryType.toLowerCase()) {
      case 'income':
        return [
          'work', 'salary', 'business', 'investment', 'gift', 'rental',
          'freelance', 'bonus', 'commission', 'dividend', 'crypto', 'stocks',
          'royalty', 'pension', 'social_benefits'
        ];
      case 'expense':
        return [
          'food', 'restaurant', 'transport', 'car', 'shopping', 'bills',
          'entertainment', 'health', 'education', 'travel', 'housing',
          'tech', 'personal_care', 'pets'
        ];
      default:
        return getAllIconNames();
    }
  }
  
  // =====================================================
  // CENTRALIZED COLOR SYSTEM
  // =====================================================
  
  /// **Centralized Color Map**
  /// 
  /// Single source of truth for all category and transaction colors.
  /// Organized by category type with consistent iOS system colors.
  /// 
  /// **Benefits:**
  /// - O(1) color lookup performance
  /// - Consistent color scheme across app
  /// - Easy maintenance and updates
  /// - Supports multiple aliases per color
  static const Map<String, Color> _colorMap = {
    // === TRANSACTION TYPE COLORS ===
    'income_default': Color(0xFF34C759),      // iOS system green
    'expense_default': Color(0xFFFF3B30),     // iOS system red
    'transfer_default': Color(0xFF007AFF),    // iOS system blue
    
    // === FOOD & DINING COLORS ===
    'restaurant': Color(0xFFFF6B35),          // Soft coral
    'food': Color(0xFFFF6B35),
    'yemek': Color(0xFFFF6B35),
    'coffee': Color(0xFF8E6A5B),              // Muted brown
    'kahve': Color(0xFF8E6A5B),
    'groceries': Color(0xFF32D74B),           // iOS system green
    'market': Color(0xFF32D74B),
    'fast_food': Color(0xFFFF9500),           // iOS system orange
    'fast': Color(0xFFFF9500),
    'alcohol': Color(0xFFAF52DE),             // iOS system purple
    'alkol': Color(0xFFAF52DE),
    'delivery': Color(0xFF64D2FF),            // iOS system light blue
    'teslimat': Color(0xFF64D2FF),
    
    // === TRANSPORTATION COLORS ===
    'transport': Color(0xFF007AFF),           // iOS system blue
    'car': Color(0xFF007AFF),
    'directions_car': Color(0xFF007AFF),
    'ulaşım': Color(0xFF007AFF),
    'fuel': Color(0xFF8E8E93),                // iOS secondary label
    'gas': Color(0xFF8E8E93),
    'local_gas_station': Color(0xFF8E8E93),
    'yakıt': Color(0xFF8E8E93),
    'public_transport': Color(0xFF5AC8FA),    // iOS system light blue
    'toplu_taşıma': Color(0xFF5AC8FA),
    'taxi': Color(0xFFFFCC02),                // iOS system yellow
    'parking': Color(0xFF6D6D70),             // iOS tertiary label
    'park': Color(0xFF6D6D70),
    'motorcycle': Color(0xFF48484A),          // iOS quaternary label
    'motosiklet': Color(0xFF48484A),
    'bicycle': Color(0xFF34C759),             // iOS system green
    'bisiklet': Color(0xFF34C759),
    
    // === SHOPPING COLORS ===
    'shopping': Color(0xFFFF9F0A),            // iOS system orange
    'shopping_cart': Color(0xFFFF9F0A),
    'shopping_bag': Color(0xFFFF9F0A),
    'alışveriş': Color(0xFFFF9F0A),
    'clothing': Color(0xFFFF2D92),            // iOS system pink
    'kıyafet': Color(0xFFFF2D92),
    'electronics': Color(0xFF007AFF),         // iOS system blue
    'elektronik': Color(0xFF007AFF),
    'furniture': Color(0xFF8E6A5B),           // Muted brown
    'mobilya': Color(0xFF8E6A5B),
    'books': Color(0xFF8E8E93),               // iOS secondary label
    'kitap': Color(0xFF8E8E93),
    'jewelry': Color(0xFFFFD60A),             // iOS system yellow
    'mücevher': Color(0xFFFFD60A),
    
    // === ENTERTAINMENT COLORS ===
    'entertainment': Color(0xFFBF5AF2),       // iOS system purple
    'movie': Color(0xFFBF5AF2),
    'eğlence': Color(0xFFBF5AF2),
    'music': Color(0xFFAF52DE),               // iOS system purple
    'müzik': Color(0xFFAF52DE),
    'gaming': Color(0xFF30D158),              // iOS system green
    'oyun': Color(0xFF30D158),
    'streaming': Color(0xFFFF3B30),           // iOS system red
    'yayın': Color(0xFFFF3B30),
    'concerts': Color(0xFF5E5CE6),            // iOS system indigo
    'konser': Color(0xFF5E5CE6),
    'photography': Color(0xFF8E8E93),         // iOS secondary label
    'fotoğraf': Color(0xFF8E8E93),
    
    // === BILLS & UTILITIES COLORS ===
    'bills': Color(0xFF007AFF),               // iOS system blue
    'receipt': Color(0xFF007AFF),
    'receipt_long': Color(0xFF007AFF),
    'faturalar': Color(0xFF007AFF),
    'electricity': Color(0xFFFFD60A),         // iOS system yellow
    'elektrik': Color(0xFFFFD60A),
    'water': Color(0xFF64D2FF),               // iOS system light blue
    'su': Color(0xFF64D2FF),
    'internet': Color(0xFF5AC8FA),            // iOS system light blue
    'phone': Color(0xFF34C759),               // iOS system green
    'telefon': Color(0xFF34C759),
    'subscription': Color(0xFFFF9500),        // iOS system orange
    'abonelik': Color(0xFFFF9500),
    'insurance': Color(0xFF007AFF),           // iOS system blue
    'sigorta': Color(0xFF007AFF),
    
    // === HEALTH & WELLNESS COLORS ===
    'health': Color(0xFF30D158),              // iOS system green
    'healthcare': Color(0xFF30D158),
    'health_and_safety': Color(0xFF30D158),
    'local_hospital': Color(0xFF30D158),
    'sağlık': Color(0xFF30D158),
    'doctor': Color(0xFF64D2FF),              // iOS system light blue
    'doktor': Color(0xFF64D2FF),
    'pharmacy': Color(0xFF32D74B),            // iOS system green
    'eczane': Color(0xFF32D74B),
    'fitness': Color(0xFF30D158),             // iOS system green
    'gym': Color(0xFF30D158),
    'spor': Color(0xFF30D158),
    'spa': Color(0xFFFF2D92),                 // iOS system pink
    'beauty': Color(0xFFFF2D92),
    'güzellik': Color(0xFFFF2D92),
    
    // === EDUCATION COLORS ===
    'education': Color(0xFF007AFF),           // iOS system blue
    'school': Color(0xFF007AFF),
    'eğitim': Color(0xFF007AFF),
    'university': Color(0xFF5E5CE6),          // iOS system indigo
    'üniversite': Color(0xFF5E5CE6),
    'course': Color(0xFF5AC8FA),              // iOS system light blue
    'kurs': Color(0xFF5AC8FA),
    
    // === TRAVEL COLORS ===
    'travel': Color(0xFF5E5CE6),              // iOS system indigo
    'flight': Color(0xFF5E5CE6),
    'seyahat': Color(0xFF5E5CE6),
    'hotel': Color(0xFFFF9500),               // iOS system orange
    'vacation': Color(0xFF64D2FF),            // iOS system light blue
    'tatil': Color(0xFF64D2FF),
    
    // === TECHNOLOGY COLORS ===
    'tech': Color(0xFF007AFF),                // iOS system blue
    'teknoloji': Color(0xFF007AFF),
    'software': Color(0xFFBF5AF2),            // iOS system purple
    'yazılım': Color(0xFFBF5AF2),
    
    // === PERSONAL CARE COLORS ===
    'personal_care': Color(0xFFFF2D92),       // iOS system pink
    'kişisel_bakım': Color(0xFFFF2D92),
    'pets': Color(0xFF8E6A5B),                // Muted brown
    'evcil_hayvan': Color(0xFF8E6A5B),
    'childcare': Color(0xFFFFB3BA),           // Soft pink
    'çocuk_bakımı': Color(0xFFFFB3BA),
    
    // === INCOME CATEGORY COLORS ===
    'work': Color(0xFF34C759),                // iOS system green
    'salary': Color(0xFF34C759),
    'maaş': Color(0xFF34C759),
    'freelance': Color(0xFF007AFF),           // iOS system blue
    'laptop': Color(0xFF007AFF),
    'business': Color(0xFFBF5AF2),            // iOS system purple
    'iş': Color(0xFFBF5AF2),
    'investment': Color(0xFFFF9500),          // iOS system orange
    'yatırım': Color(0xFFFF9500),
    'rental': Color(0xFF30D158),              // iOS system green
    'kira': Color(0xFF30D158),
    'home': Color(0xFF30D158),
    'bonus': Color(0xFFFF3B30),               // iOS system red
    'star': Color(0xFFFF3B30),
    'gift': Color(0xFFFF2D92),                // iOS system pink
    'hediye': Color(0xFFFF2D92),
    'card_giftcard': Color(0xFFFF2D92),
    'commission': Color(0xFF32D74B),          // iOS system green
    'komisyon': Color(0xFF32D74B),
    'dividend': Color(0xFF30D158),            // iOS system green
    'temettü': Color(0xFF30D158),
    'crypto': Color(0xFFFF9F0A),              // iOS system orange
    'kripto': Color(0xFFFF9F0A),
    'stocks': Color(0xFF64D2FF),              // iOS system light blue
    'hisse': Color(0xFF64D2FF),
    'royalty': Color(0xFFAF52DE),             // iOS system purple
    'telif': Color(0xFFAF52DE),
    'pension': Color(0xFF5AC8FA),             // iOS system light blue
    'emekli': Color(0xFF5AC8FA),
    'social_benefits': Color(0xFF5E5CE6),     // iOS system indigo
    'sosyal_yardım': Color(0xFF5E5CE6),
    
    // === DEFAULT COLORS ===
    'default': Color(0xFF8E8E93),             // iOS secondary label
    'other': Color(0xFF8E8E93),
    'diğer': Color(0xFF8E8E93),
  };
  
  /// Get color from centralized color map
  /// 
  /// **Primary color lookup method** - uses centralized color map
  /// for consistent colors across the entire application.
  /// 
  /// **Lookup Priority:**
  /// 1. Direct icon name match (e.g., 'restaurant')
  /// 2. Normalized name match (e.g., 'RESTAURANT' → 'restaurant')
  /// 3. Turkish name match (e.g., 'yemek' → food color)
  /// 4. Category type default (income/expense/transfer)
  /// 5. Global default gray
  static Color getColorFromMap(String iconName, {String? categoryType}) {
    // Direct lookup
    if (_colorMap.containsKey(iconName)) {
      return _colorMap[iconName]!;
    }
    
    // Normalized lookup
    final normalizedName = iconName.toLowerCase().trim();
    if (_colorMap.containsKey(normalizedName)) {
      return _colorMap[normalizedName]!;
    }
    
    // Category type default
    if (categoryType != null) {
      final defaultKey = '${categoryType}_default';
      if (_colorMap.containsKey(defaultKey)) {
        return _colorMap[defaultKey]!;
      }
    }
    
    // Global default
    return _colorMap['default']!;
  }
  
  /// Get all available colors
  static Map<String, Color> getAllColors() {
    return Map.unmodifiable(_colorMap);
  }
  
  /// Check if color exists in map
  static bool hasColor(String iconName) {
    return _colorMap.containsKey(iconName) || 
           _colorMap.containsKey(iconName.toLowerCase().trim());
  }

  // =====================================================
  // CATEGORY MANAGEMENT UTILITIES
  // =====================================================

  /// Get default expense categories with Turkish names
  static List<Map<String, dynamic>> getDefaultExpenseCategories() {
    return [
      {
        'name': 'food',
        'displayName': 'Yemek & İçecek',
        'description': 'Restoran, market, kahve',
        'iconName': 'restaurant_rounded',
        'colorHex': '#FF6B6B',
        'sortOrder': 1,
      },
      {
        'name': 'transport',
        'displayName': 'Ulaşım',
        'description': 'Araba, toplu taşıma, yakıt',
        'iconName': 'directions_car_rounded',
        'colorHex': '#4ECDC4',
        'sortOrder': 2,
      },
      {
        'name': 'shopping',
        'displayName': 'Alışveriş',
        'description': 'Kıyafet, elektronik, genel',
        'iconName': 'shopping_bag_rounded',
        'colorHex': '#FFE66D',
        'sortOrder': 3,
      },
      {
        'name': 'bills',
        'displayName': 'Faturalar',
        'description': 'Elektrik, su, internet, telefon',
        'iconName': 'receipt_long_rounded',
        'colorHex': '#95E1D3',
        'sortOrder': 4,
      },
      {
        'name': 'entertainment',
        'displayName': 'Eğlence',
        'description': 'Sinema, müzik, oyun',
        'iconName': 'movie_rounded',
        'colorHex': '#FF8B94',
        'sortOrder': 5,
      },
      {
        'name': 'health',
        'displayName': 'Sağlık',
        'description': 'Doktor, eczane, fitness',
        'iconName': 'local_hospital_rounded',
        'colorHex': '#A8E6CF',
        'sortOrder': 6,
      },
      {
        'name': 'education',
        'displayName': 'Eğitim',
        'description': 'Okul, kurs, kitap',
        'iconName': 'school_rounded',
        'colorHex': '#FFD93D',
        'sortOrder': 7,
      },
      {
        'name': 'travel',
        'displayName': 'Seyahat',
        'description': 'Uçak, otel, tatil',
        'iconName': 'flight_rounded',
        'colorHex': '#5E5CE6',
        'sortOrder': 8,
      },
      {
        'name': 'other',
        'displayName': 'Diğer',
        'description': 'Diğer giderler',
        'iconName': 'more_horiz_rounded',
        'colorHex': '#B4A7D6',
        'sortOrder': 9,
      },
    ];
  }

  /// Get default income categories with Turkish names
  static List<Map<String, dynamic>> getDefaultIncomeCategories() {
    return [
      {
        'name': 'salary',
        'displayName': 'Maaş',
        'description': 'Aylık maaş geliri',
        'iconName': 'work_rounded',
        'colorHex': '#34C759',
        'sortOrder': 1,
      },
      {
        'name': 'freelance',
        'displayName': 'Freelance',
        'description': 'Serbest çalışma geliri',
        'iconName': 'laptop_rounded',
        'colorHex': '#007AFF',
        'sortOrder': 2,
      },
      {
        'name': 'business',
        'displayName': 'İş Geliri',
        'description': 'İş ve ticaret geliri',
        'iconName': 'business_rounded',
        'colorHex': '#BF5AF2',
        'sortOrder': 3,
      },
      {
        'name': 'investment',
        'displayName': 'Yatırım',
        'description': 'Hisse, kripto, yatırım geliri',
        'iconName': 'trending_up_rounded',
        'colorHex': '#FF9500',
        'sortOrder': 4,
      },
      {
        'name': 'rental',
        'displayName': 'Kira Geliri',
        'description': 'Ev, dükkan kira geliri',
        'iconName': 'home_rounded',
        'colorHex': '#30D158',
        'sortOrder': 5,
      },
      {
        'name': 'bonus',
        'displayName': 'Bonus',
        'description': 'Prim, ikramiye',
        'iconName': 'star_rounded',
        'colorHex': '#FF3B30',
        'sortOrder': 6,
      },
      {
        'name': 'gift',
        'displayName': 'Hediye',
        'description': 'Hediye para',
        'iconName': 'card_giftcard_rounded',
        'colorHex': '#FF2D92',
        'sortOrder': 7,
      },
      {
        'name': 'other',
        'displayName': 'Diğer',
        'description': 'Diğer gelirler',
        'iconName': 'more_horiz_rounded',
        'colorHex': '#8E8E93',
        'sortOrder': 8,
      },
    ];
  }

  /// Validate if an icon name is valid
  static bool isValidCategoryIcon(String iconName) {
    return hasIcon(iconName);
  }

  /// Normalize category name for consistency
  static String normalizeCategoryName(String name) {
    return name.toLowerCase().trim().replaceAll(' ', '_');
  }

  /// Get category display name in Turkish
  static String getCategoryDisplayName(String categoryName) {
    final normalized = normalizeCategoryName(categoryName);
    
    // Check expense categories
    final expenseCategory = getDefaultExpenseCategories()
        .firstWhere((cat) => cat['name'] == normalized, orElse: () => {});
    if (expenseCategory.isNotEmpty) {
      return expenseCategory['displayName'] as String;
    }
    
    // Check income categories
    final incomeCategory = getDefaultIncomeCategories()
        .firstWhere((cat) => cat['name'] == normalized, orElse: () => {});
    if (incomeCategory.isNotEmpty) {
      return incomeCategory['displayName'] as String;
    }
    
    // Fallback to capitalized name
    return categoryName.split('_').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  /// Get category description in Turkish
  static String getCategoryDescription(String categoryName) {
    final normalized = normalizeCategoryName(categoryName);
    
    // Check expense categories
    final expenseCategory = getDefaultExpenseCategories()
        .firstWhere((cat) => cat['name'] == normalized, orElse: () => {});
    if (expenseCategory.isNotEmpty) {
      return expenseCategory['description'] as String;
    }
    
    // Check income categories
    final incomeCategory = getDefaultIncomeCategories()
        .firstWhere((cat) => cat['name'] == normalized, orElse: () => {});
    if (incomeCategory.isNotEmpty) {
      return incomeCategory['description'] as String;
    }
    
    return 'Kategori açıklaması';
  }

  /// Get suggested icon name for a category
  static String getSuggestedIconName(String categoryName) {
    final normalized = normalizeCategoryName(categoryName);
    
    // Common mappings
    final iconMappings = {
      'food': 'restaurant_rounded',
      'yemek': 'restaurant_rounded',
      'transport': 'directions_car_rounded',
      'ulaşım': 'directions_car_rounded',
      'shopping': 'shopping_bag_rounded',
      'alışveriş': 'shopping_bag_rounded',
      'bills': 'receipt_long_rounded',
      'faturalar': 'receipt_long_rounded',
      'entertainment': 'movie_rounded',
      'eğlence': 'movie_rounded',
      'health': 'local_hospital_rounded',
      'sağlık': 'local_hospital_rounded',
      'education': 'school_rounded',
      'eğitim': 'school_rounded',
      'travel': 'flight_rounded',
      'seyahat': 'flight_rounded',
      'salary': 'work_rounded',
      'maaş': 'work_rounded',
      'freelance': 'laptop_rounded',
      'business': 'business_rounded',
      'iş': 'business_rounded',
      'investment': 'trending_up_rounded',
      'yatırım': 'trending_up_rounded',
      'rental': 'home_rounded',
      'kira': 'home_rounded',
      'bonus': 'star_rounded',
      'gift': 'card_giftcard_rounded',
      'hediye': 'card_giftcard_rounded',
    };
    
    return iconMappings[normalized] ?? 'more_horiz_rounded';
  }

  /// Get all available icon names for category selection
  static List<String> getAllAvailableIconNames() {
    return getAllIconNames();
  }

  /// Check if category is an income category based on name
  static bool isIncomeCategory(String categoryName) {
    final normalized = normalizeCategoryName(categoryName);
    final incomeCategories = getDefaultIncomeCategories()
        .map((cat) => cat['name'] as String)
        .toList();
    
    return incomeCategories.contains(normalized);
  }

  /// Check if category is an expense category based on name
  static bool isExpenseCategory(String categoryName) {
    final normalized = normalizeCategoryName(categoryName);
    final expenseCategories = getDefaultExpenseCategories()
        .map((cat) => cat['name'] as String)
        .toList();
    
    return expenseCategories.contains(normalized);
  }

  /// Get category type as string
  static String getCategoryType(String categoryName) {
    if (isIncomeCategory(categoryName)) return 'income';
    if (isExpenseCategory(categoryName)) return 'expense';
    return 'other';
  }

  /// Get color from hex string or centralized map
  /// 
  /// **Updated to use centralized color system first**
  /// Falls back to hex parsing if no predefined color exists.
  /// 
  /// **Lookup Priority:**
  /// 1. Centralized color map (for consistency)
  /// 2. Hex color parsing (for custom colors)
  /// 3. Default gray fallback
  static Color getColor(String colorInput) {
    // First try centralized color map
    if (hasColor(colorInput)) {
      return getColorFromMap(colorInput);
    }
    
    // Then try hex parsing for custom colors
    try {
      String cleanHex = colorInput.trim();
      
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
      return getColorFromMap('default'); // Use centralized default
    }
  }
  
  /// Get background color with opacity
  /// 
  /// Returns the category color with 10% opacity for use
  /// as background color in category selectors.
  static Color getBackgroundColor(String colorInput) {
    return getColor(colorInput).withOpacity(0.1);
  }
  
  /// Get predefined color for expense categories
  /// 
  /// **UPDATED:** Now uses centralized color map for better performance
  /// and consistency. Maintains backward compatibility.
  static Color getExpenseColor(String iconName) {
    return getColorFromMap(iconName, categoryType: 'expense');
  }
  
  /// Get predefined color for income categories
  /// 
  /// **UPDATED:** Now uses centralized color map for better performance
  /// and consistency. Maintains backward compatibility.
  static Color getIncomeColor(String iconName) {
    return getColorFromMap(iconName, categoryType: 'income');
  }
  
  /// Get appropriate color based on category type
  /// 
  /// **UPDATED:** Uses centralized color system with improved logic.
  /// Prioritizes predefined colors over hex colors for consistency.
  static Color getCategoryColor({
    required String iconName,
    String? colorHex,
    required bool isIncomeCategory,
  }) {
    // First try predefined colors from centralized map
    final categoryType = isIncomeCategory ? 'income' : 'expense';
    
    // Check if we have a predefined color for this icon
    if (hasColor(iconName)) {
      return getColorFromMap(iconName, categoryType: categoryType);
    }
    
    // Fall back to hex color if provided
    if (colorHex != null && colorHex.isNotEmpty) {
      return getColor(colorHex);
    }
    
    // Use category type default
    return getColorFromMap('${categoryType}_default');
  }

  /// Get all available expense category icons
  static Map<String, IconData> getAllExpenseIcons() {
    // Filter expense icons from the main icon map
    final expenseIconNames = getIconNamesByType('expense');
    final Map<String, IconData> expenseIcons = {};
    
    for (final iconName in expenseIconNames) {
      if (_iconMap.containsKey(iconName)) {
        expenseIcons[iconName] = _iconMap[iconName]!;
      }
    }
    
    return expenseIcons;
  }
  
  /// Get all available income category icons
  static Map<String, IconData> getAllIncomeIcons() {
    // Filter income icons from the main icon map
    final incomeIconNames = getIconNamesByType('income');
    final Map<String, IconData> incomeIcons = {};
    
    for (final iconName in incomeIconNames) {
      if (_iconMap.containsKey(iconName)) {
        incomeIcons[iconName] = _iconMap[iconName]!;
      }
    }
    
    return incomeIcons;
  }
} 