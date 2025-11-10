import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

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
    'cafe': Icons.local_cafe_rounded,
    'starbucks': Icons.local_cafe_rounded,
    'çay': Icons.local_cafe_rounded,
    'tea': Icons.local_cafe_rounded,
    'cigarette': Icons.smoking_rooms_rounded,
    'sigara': Icons.smoking_rooms_rounded,
    'tobacco': Icons.smoking_rooms_rounded,
    'tütün': Icons.smoking_rooms_rounded,
    
    // === PERSONAL CARE & BEAUTY ===
    'beauty': Icons.face_retouching_natural_rounded,
    'güzellik': Icons.face_retouching_natural_rounded,
    'cosmetics': Icons.face_retouching_natural_rounded,
    'kozmetik': Icons.face_retouching_natural_rounded,
    'hair': Icons.content_cut_rounded,
    'saç': Icons.content_cut_rounded,
    'barber': Icons.content_cut_rounded,
    'berber': Icons.content_cut_rounded,
    'salon': Icons.content_cut_rounded,
    'spa': Icons.spa_rounded,
    'massage': Icons.spa_rounded,
    'masaj': Icons.spa_rounded,
    'gym': Icons.fitness_center_rounded,
    'spor': Icons.fitness_center_rounded,
    'fitness': Icons.fitness_center_rounded,
    'workout': Icons.fitness_center_rounded,
    
    // === ENTERTAINMENT & LEISURE ===
    'cinema': Icons.movie_rounded,
    'sinema': Icons.movie_rounded,
    'movie': Icons.movie_rounded,
    'film': Icons.movie_rounded,
    'theater': Icons.theater_comedy_rounded,
    'tiyatro': Icons.theater_comedy_rounded,
    'concert': Icons.music_note_rounded,
    'konser': Icons.music_note_rounded,
    'music': Icons.music_note_rounded,
    'müzik': Icons.music_note_rounded,
    'gaming': Icons.sports_esports_rounded,
    'oyun': Icons.sports_esports_rounded,
    'game': Icons.sports_esports_rounded,
    'book': Icons.menu_book_rounded,
    'kitap': Icons.menu_book_rounded,
    'reading': Icons.menu_book_rounded,
    'okuma': Icons.menu_book_rounded,
    'magazine': Icons.menu_book_rounded,
    'dergi': Icons.menu_book_rounded,
    
    // === TECHNOLOGY & ELECTRONICS ===
    'phone': Icons.phone_android_rounded,
    'telefon': Icons.phone_android_rounded,
    'mobile': Icons.phone_android_rounded,
    'computer': Icons.computer_rounded,
    'bilgisayar': Icons.computer_rounded,
    'tablet': Icons.tablet_android_rounded,
    'internet': Icons.wifi_rounded,
    'software': Icons.apps_rounded,
    'yazılım': Icons.apps_rounded,
    'app': Icons.apps_rounded,
    'subscription': Icons.subscriptions_rounded,
    'abonelik': Icons.subscriptions_rounded,
    'streaming': Icons.stream_rounded,
    'netflix': Icons.stream_rounded,
    'spotify': Icons.music_note_rounded,
    'youtube': Icons.play_circle_rounded,
    
    // === HOME & GARDEN ===
    'furniture': Icons.chair_rounded,
    'mobilya': Icons.chair_rounded,
    'decoration': Icons.home_rounded,
    'dekorasyon': Icons.home_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'temizlik': Icons.cleaning_services_rounded,
    'garden': Icons.yard_rounded,
    'bahçe': Icons.yard_rounded,
    'plant': Icons.local_florist_rounded,
    'bitki': Icons.local_florist_rounded,
    'tool': Icons.build_rounded,
    'alet': Icons.build_rounded,
    'maintenance': Icons.build_rounded,
    'bakım': Icons.build_rounded,
    
    // === PETS & ANIMALS ===
    'pet': Icons.pets_rounded,
    'evcil': Icons.pets_rounded,
    'dog': Icons.pets_rounded,
    'köpek': Icons.pets_rounded,
    'cat': Icons.pets_rounded,
    'kedi': Icons.pets_rounded,
    'veterinary': Icons.local_hospital_rounded,
    'veteriner': Icons.local_hospital_rounded,
    'pet_food': Icons.pets_rounded,
    'mama': Icons.pets_rounded,
    
    // === MISCELLANEOUS ===
    'donation': Icons.volunteer_activism_rounded,
    'bağış': Icons.volunteer_activism_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'yardım': Icons.volunteer_activism_rounded,
    'insurance': Icons.security_rounded,
    'sigorta': Icons.security_rounded,
    'tax': Icons.receipt_long_rounded,
    'vergi': Icons.receipt_long_rounded,
    'fine': Icons.gavel_rounded,
    'ceza': Icons.gavel_rounded,
    'parking': Icons.local_parking_rounded,
    'otopark': Icons.local_parking_rounded,
    'toll': Icons.toll_rounded,
    'köprü': Icons.toll_rounded,
    'bridge': Icons.toll_rounded,
    'groceries': Icons.shopping_cart_rounded,
    'market': Icons.shopping_cart_rounded,
    'supermarket': Icons.shopping_cart_rounded,
    'süpermarket': Icons.shopping_cart_rounded,
    'grocery': Icons.shopping_cart_rounded,
    'bakkal': Icons.shopping_cart_rounded,
    'marketler': Icons.shopping_cart_rounded,
    'migros': Icons.shopping_cart_rounded,
    'carrefour': Icons.shopping_cart_rounded,
    'bim': Icons.shopping_cart_rounded,
    'a101': Icons.shopping_cart_rounded,
    'şok': Icons.shopping_cart_rounded,
    'fast_food': Icons.fastfood_rounded,
    'fast': Icons.fastfood_rounded,
    'mcdonalds': Icons.fastfood_rounded,
    'burger_king': Icons.fastfood_rounded,
    'kfc': Icons.fastfood_rounded,
    'alcohol': Icons.local_bar_rounded,
    'alkol': Icons.local_bar_rounded,
    'delivery': Icons.delivery_dining_rounded,
    'teslimat': Icons.delivery_dining_rounded,
    'yemeksepeti': Icons.delivery_dining_rounded,
    'getir': Icons.delivery_dining_rounded,
    'trendyol': Icons.delivery_dining_rounded,
    'pizza': Icons.local_pizza_rounded,
    'burger': Icons.lunch_dining_rounded,
    'hamburger': Icons.lunch_dining_rounded,
    'döner': Icons.lunch_dining_rounded,
    'kebab': Icons.lunch_dining_rounded,
    'sushi': Icons.set_meal_rounded,
    'chinese': Icons.ramen_dining_rounded,
    'çin': Icons.ramen_dining_rounded,
    
    // Transportation
    'transport': Icons.directions_car_rounded,
    'car': Icons.directions_car_rounded,
    'directions_car': Icons.directions_car_rounded,
    'ulaşım': Icons.directions_car_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'gas': Icons.local_gas_station_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'yakıt': Icons.local_gas_station_rounded,
    'benzin': Icons.local_gas_station_rounded,
    'diesel': Icons.local_gas_station_rounded,
    'dizel': Icons.local_gas_station_rounded,
    'petrol': Icons.local_gas_station_rounded,
    'shell': Icons.local_gas_station_rounded,
    'bp': Icons.local_gas_station_rounded,
    'opet': Icons.local_gas_station_rounded,
    'total': Icons.local_gas_station_rounded,
    'public_transport': Icons.directions_bus_rounded,
    'toplu_taşıma': Icons.directions_bus_rounded,
    'taxi': Icons.local_taxi_rounded,
    'taksi': Icons.local_taxi_rounded,
    'local_taxi': Icons.local_taxi_rounded,
    'uber': Icons.local_taxi_rounded,
    'bitaksi': Icons.local_taxi_rounded,
    'park': Icons.local_parking_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'motosiklet': Icons.two_wheeler_rounded,
    'bicycle': Icons.pedal_bike_rounded,
    'bisiklet': Icons.pedal_bike_rounded,
    'train': Icons.train_rounded,
    'tren': Icons.train_rounded,
    'subway': Icons.subway_rounded,
    'metro': Icons.subway_rounded,
    'bus': Icons.directions_bus_rounded,
    'otobüs': Icons.directions_bus_rounded,
    'dolmuş': Icons.directions_bus_rounded,
    'minibüs': Icons.directions_bus_rounded,
    'ferry': Icons.directions_boat_rounded,
    'vapur': Icons.directions_boat_rounded,
    'plane': Icons.flight_rounded,
    'uçak': Icons.flight_rounded,
    'flight_takeoff': Icons.flight_takeoff_rounded,
    'flight_land': Icons.flight_land_rounded,
    
    // Shopping
    'shopping': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_bag_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'alışveriş': Icons.shopping_bag_rounded,
    'clothing': Icons.checkroom_rounded,
    'kıyafet': Icons.checkroom_rounded,
    'electronics': Icons.devices_rounded,
    'elektronik': Icons.devices_rounded,
    'gifts': Icons.card_giftcard_rounded,
    'hediyeler': Icons.card_giftcard_rounded,
    'jewelry': Icons.diamond_rounded,
    'mücevher': Icons.diamond_rounded,
    'shoes': Icons.sports_rounded,
    'ayakkabı': Icons.sports_rounded,
    'nike': Icons.sports_rounded,
    'adidas': Icons.sports_rounded,
    'makeup': Icons.face_retouching_natural_rounded,
    'makyaj': Icons.face_retouching_natural_rounded,
    'perfume': Icons.local_florist_rounded,
    'parfüm': Icons.local_florist_rounded,
    
    // Entertainment & Lifestyle
    'entertainment': Icons.movie_rounded,
    'eğlence': Icons.movie_rounded,
    'yayın': Icons.play_circle_rounded,
    'concerts': Icons.library_music_rounded,
    'nightlife': Icons.nightlife_rounded,
    'gece_hayatı': Icons.nightlife_rounded,
    'hobbies': Icons.palette_rounded,
    'hobi': Icons.palette_rounded,
    'photography': Icons.camera_alt_rounded,
    'fotoğraf': Icons.camera_alt_rounded,
    'books': Icons.auto_stories_rounded,
    'kitaplar': Icons.auto_stories_rounded,
    'apple_music': Icons.music_note_rounded,
    
    // Bills & Utilities
    'bills': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'faturalar': Icons.receipt_long_rounded,
    'electricity': Icons.bolt_rounded,
    'elektrik': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'su': Icons.water_drop_rounded,
    'cable_tv': Icons.tv_rounded,
    'tv': Icons.tv_rounded,
    'digiturk': Icons.tv_rounded,
    'tivibu': Icons.tv_rounded,
    'turkcell': Icons.phone_rounded,
    'vodafone': Icons.phone_rounded,
    'türk_telekom': Icons.phone_rounded,
    'superonline': Icons.wifi_rounded,
    'ttnet': Icons.wifi_rounded,
    'bank_fees': Icons.account_balance_rounded,
    'banka_ücreti': Icons.account_balance_rounded,
    'atm': Icons.local_atm_rounded,
    'atm_fee': Icons.local_atm_rounded,
    'atm_ücreti': Icons.local_atm_rounded,
    'interest': Icons.trending_up_rounded,
    'faiz': Icons.trending_up_rounded,
    
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
    'therapy': Icons.psychology_rounded,
    'terapi': Icons.psychology_rounded,
    'nutrition': Icons.dining_rounded,
    'beslenme': Icons.dining_rounded,
    'supplement': Icons.medication_rounded,
    'takviye': Icons.medication_rounded,
    'vitamin': Icons.medication_rounded,
    'protein': Icons.fitness_center_rounded,
    
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
    
    // Technology & Digital
    'tech': Icons.computer_rounded,
    'teknoloji': Icons.computer_rounded,
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
    'elderly_care': Icons.elderly_rounded,
    'yaşlı_bakımı': Icons.elderly_rounded,
    
    // Financial & Investment
    'fees': Icons.monetization_on_rounded,
    'ücretler': Icons.monetization_on_rounded,
    'taxes': Icons.receipt_long_rounded,
    'vergiler': Icons.receipt_long_rounded,
    'loans': Icons.credit_score_rounded,
    'krediler': Icons.credit_score_rounded,
    'savings': Icons.account_balance_wallet_rounded,
    'tasarruf': Icons.account_balance_wallet_rounded,
    
    // Emergency & Others
    'emergency': Icons.emergency_rounded,
    'acil': Icons.emergency_rounded,
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
    'label': Icons.tag,
    'folder': Icons.tag,
    'other': Icons.tag,
    'category': Icons.tag,
    'diğer': Icons.tag,
    // === CUSTOM/NEW CATEGORIES ===
    'evcil_hayvan_maması': Icons.pets_rounded,
    'toy': Icons.toys_rounded,
    'oyuncak': Icons.toys_rounded,
    'hairdresser': Icons.content_cut_rounded,
    'psychologist': Icons.psychology_rounded,
    'natural_gas': Icons.fireplace_rounded,
    'cargo': Icons.local_shipping_rounded,
    'office': Icons.apartment_rounded,
    'cleaning_supplies': Icons.cleaning_services_rounded,
    'gift_item': Icons.card_giftcard_rounded,
    'fish': Icons.set_meal_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'home_renovation': Icons.handyman_rounded,
    'pet_vet': Icons.local_hospital_rounded,
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
  /// Returns `Icons.tag` for unknown icon names
  static IconData getIcon(String iconName) {
    final normalizedName = iconName.toLowerCase().trim();
    return _iconMap[normalizedName] ?? Icons.tag;
  }

  /// Get icon with validation
  /// 
  /// Returns the icon if valid, otherwise returns fallback icon
  /// and optionally logs the invalid icon name for debugging.
  static IconData getIconSafe(String iconName, {bool logInvalid = false}) {
    final normalizedName = iconName.toLowerCase().trim();
    final icon = _iconMap[normalizedName];
    
    if (icon == null && logInvalid) {
    }
    
    return icon ?? Icons.tag;
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
  /// Colors are chosen to be meaningful and intuitive:
  /// - Income categories: Green shades (money coming in)
  /// - Expense categories: Red/warm shades (money going out) 
  /// - Specific categories: Contextual colors (coffee=brown, fuel=gray, etc.)
  /// 
  /// **Benefits:**
  /// - O(1) color lookup performance
  /// - Intuitive color associations
  /// - Easy maintenance and updates
  /// - Supports multiple aliases per color
  // Color map removed - using single grey background and transaction type based icon colors
  static const Map<String, Color> _colorMap = {
    // === TRANSACTION TYPE COLORS ===
    'income_default': Color(0xFF22C55E),      // Green for income
    'expense_default': Color(0xFFEF4444),     // Red for expenses
    'transfer_default': Color(0xFF3B82F6),    // Blue for transfers
    
    // === INCOME CATEGORIES (GREEN SHADES) ===
    'work': Color(0xFF16A34A),                // Dark green
    'salary': Color(0xFF16A34A),
    'maaş': Color(0xFF16A34A),
    'business': Color(0xFF15803D),            // Darker green
    'iş': Color(0xFF15803D),
    'investment': Color(0xFF10B981),          // Emerald green
    'yatırım': Color(0xFF10B981),
    'gift': Color(0xFF22C55E),                // Medium green
    'hediye': Color(0xFF22C55E),
    'rental': Color(0xFF059669),              // Teal green
    'kira': Color(0xFF059669),
    'freelance': Color(0xFF4CAF50),           // Success green
    'bonus': Color(0xFF6EE7B7),               // Very light green
    'commission': Color(0xFF10B981),          // Emerald
    'komisyon': Color(0xFF10B981),
    
    // === FOOD & DINING COLORS (RED/WARM TONES) ===
    'restaurant': Color(0xFFDC2626),          // Red for dining out
    'food': Color(0xFFDC2626),
    'yemek': Color(0xFFDC2626),
    'coffee': Color(0xFF8B4513),              // Brown for coffee ☕
    'kahve': Color(0xFF8B4513),
    'cafe': Color(0xFF8B4513),
    'çay': Color(0xFF059669),                 // Green for tea 🍵
    'tea': Color(0xFF059669),
    'groceries': Color(0xFFEF4444),           // Red for grocery expenses
    'market': Color(0xFFEF4444),
    'supermarket': Color(0xFFEF4444),
    'süpermarket': Color(0xFFEF4444),
    'migros': Color(0xFFEF4444),
    'carrefour': Color(0xFFEF4444),
    'bim': Color(0xFFEF4444),
    'fast_food': Color(0xFFEA580C),           // Orange for fast food
    'fast': Color(0xFFEA580C),
    'mcdonalds': Color(0xFFEA580C),
    'burger_king': Color(0xFFEA580C),
    'pizza': Color(0xFFDC2626),               // Red for pizza
    'alcohol': Color(0xFF7C3AED),             // Purple for alcohol
    'alkol': Color(0xFF7C3AED),
    'delivery': Color(0xFFDC2626),            // Red for delivery expenses
    'teslimat': Color(0xFFDC2626),
    'yemeksepeti': Color(0xFFDC2626),
    'getir': Color(0xFFDC2626),
    'cigarette': Color(0xFFDC2626),           // Red for cigarette expenses (consistent with other expenses)
    'sigara': Color(0xFFDC2626),
    'tobacco': Color(0xFFDC2626),
    'tütün': Color(0xFFDC2626),
    
    // === PERSONAL CARE & BEAUTY COLORS (PINK/PURPLE TONES) ===
    'beauty': Color(0xFFEC4899),              // Pink for beauty expenses
    'güzellik': Color(0xFFEC4899),
    'cosmetics': Color(0xFFEC4899),
    'kozmetik': Color(0xFFEC4899),
    'hair': Color(0xFFEC4899),
    'saç': Color(0xFFEC4899),
    'barber': Color(0xFFEC4899),
    'berber': Color(0xFFEC4899),
    'salon': Color(0xFFEC4899),
    'spa': Color(0xFFEC4899),
    'massage': Color(0xFFEC4899),
    'masaj': Color(0xFFEC4899),
    'gym': Color(0xFF7C3AED),                 // Purple for fitness
    'spor': Color(0xFF7C3AED),
    'fitness': Color(0xFF7C3AED),
    'workout': Color(0xFF7C3AED),
    
    // === ENTERTAINMENT & LEISURE COLORS (ORANGE/YELLOW TONES) ===
    'cinema': Color(0xFFEA580C),              // Orange for entertainment
    'sinema': Color(0xFFEA580C),
    'movie': Color(0xFFEA580C),
    'film': Color(0xFFEA580C),
    'theater': Color(0xFFEA580C),
    'tiyatro': Color(0xFFEA580C),
    'concert': Color(0xFFEA580C),
    'konser': Color(0xFFEA580C),
    'music': Color(0xFFEA580C),
    'müzik': Color(0xFFEA580C),
    'gaming': Color(0xFFEA580C),
    'oyun': Color(0xFFEA580C),
    'game': Color(0xFFEA580C),
    'book': Color(0xFFD97706),                // Amber for books
    'kitap': Color(0xFFD97706),
    'reading': Color(0xFFD97706),
    'okuma': Color(0xFFD97706),
    'magazine': Color(0xFFD97706),
    'dergi': Color(0xFFD97706),
    
    // === TECHNOLOGY & ELECTRONICS COLORS (BLUE TONES) ===
    'phone': Color(0xFF3B82F6),               // Blue for technology
    'telefon': Color(0xFF3B82F6),
    'mobile': Color(0xFF3B82F6),
    'computer': Color(0xFF3B82F6),
    'bilgisayar': Color(0xFF3B82F6),
    'tablet': Color(0xFF3B82F6),
    'internet': Color(0xFF3B82F6),
    'software': Color(0xFF3B82F6),
    'yazılım': Color(0xFF3B82F6),
    'app': Color(0xFF3B82F6),
    'subscription': Color(0xFF3B82F6),
    'abonelik': Color(0xFF3B82F6),
    'streaming': Color(0xFF3B82F6),
    'netflix': Color(0xFF3B82F6),
    'spotify': Color(0xFF3B82F6),
    'youtube': Color(0xFF3B82F6),
    
    // === HOME & GARDEN COLORS (GREEN TONES) ===
    'furniture': Color(0xFF059669),           // Teal for home
    'mobilya': Color(0xFF059669),
    'decoration': Color(0xFF059669),
    'dekorasyon': Color(0xFF059669),
    'cleaning': Color(0xFF059669),
    'temizlik': Color(0xFF059669),
    'garden': Color(0xFF059669),
    'bahçe': Color(0xFF059669),
    'plant': Color(0xFF059669),
    'bitki': Color(0xFF059669),
    'tool': Color(0xFF059669),
    'alet': Color(0xFF059669),
    'maintenance': Color(0xFF059669),
    'bakım': Color(0xFF059669),
    
    // === PETS & ANIMALS COLORS (BROWN TONES) ===
    'pet': Color(0xFF8B4513),                 // Brown for pets
    'evcil': Color(0xFF8B4513),
    'dog': Color(0xFF8B4513),
    'köpek': Color(0xFF8B4513),
    'cat': Color(0xFF8B4513),
    'kedi': Color(0xFF8B4513),
    'veterinary': Color(0xFF8B4513),
    'veteriner': Color(0xFF8B4513),
    'pet_food': Color(0xFF8B4513),
    'mama': Color(0xFF8B4513),
    
    // === MISCELLANEOUS COLORS (VARIOUS) ===
    'donation': Color(0xFF10B981),            // Green for donations
    'bağış': Color(0xFF10B981),
    'charity': Color(0xFF10B981),
    'yardım': Color(0xFF10B981),
    'insurance': Color(0xFF6B7280),           // Gray for insurance
    'sigorta': Color(0xFF6B7280),
    'tax': Color(0xFF6B7280),                 // Gray for taxes
    'vergi': Color(0xFF6B7280),
    'fine': Color(0xFFDC2626),                // Red for fines
    'ceza': Color(0xFFDC2626),
    'parking': Color(0xFF6B7280),             // Gray for parking
    'otopark': Color(0xFF6B7280),
    'toll': Color(0xFF6B7280),                // Gray for tolls
    'köprü': Color(0xFF6B7280),
    'bridge': Color(0xFF6B7280),
    
    // === TRANSPORTATION COLORS (RED/WARM TONES FOR EXPENSES) ===
    'transport': Color(0xFFDC2626),           // Red for transport expenses
    'car': Color(0xFFDC2626),
    'directions_car': Color(0xFFDC2626),
    'ulaşım': Color(0xFFDC2626),
    'fuel': Color(0xFF6B7280),                // Gray for fuel ⛽
    'gas': Color(0xFF6B7280),
    'benzin': Color(0xFF6B7280),
    'diesel': Color(0xFF6B7280),
    'petrol': Color(0xFF6B7280),
    'yakıt': Color(0xFF6B7280),
    'shell': Color(0xFF6B7280),
    'bp': Color(0xFF6B7280),
    'opet': Color(0xFF6B7280),
    'public_transport': Color(0xFFEF4444),    // Red for public transport
    'toplu_taşıma': Color(0xFFEF4444),
    'bus': Color(0xFFEF4444),
    'otobüs': Color(0xFFEF4444),
    'metro': Color(0xFFEF4444),
    'taxi': Color(0xFFFBBF24),                // Yellow for taxi 🚕
    'taksi': Color(0xFFFBBF24),
    'uber': Color(0xFFFBBF24),
    'bitaksi': Color(0xFFFBBF24),
    'park': Color(0xFF6B7280),
    'motorcycle': Color(0xFF374151),          // Dark gray for motorcycle
    'motosiklet': Color(0xFF374151),
    'bicycle': Color(0xFF059669),             // Green for eco-friendly bike
    'bisiklet': Color(0xFF059669),
    
    // === SHOPPING COLORS (RED/WARM TONES FOR EXPENSES) ===
    'shopping': Color(0xFFDC2626),            // Red for shopping expenses
    'shopping_cart': Color(0xFFDC2626),
    'shopping_bag': Color(0xFFDC2626),
    'alışveriş': Color(0xFFDC2626),
    'clothing': Color(0xFFEC4899),            // Pink for clothing 👗
    'kıyafet': Color(0xFFEC4899),
    'nike': Color(0xFFEC4899),
    'adidas': Color(0xFFEC4899),
    'electronics': Color(0xFF6366F1),         // Blue for electronics 📱
    'elektronik': Color(0xFF6366F1),
    'books': Color(0xFF6B7280),               // Gray for books 📚
    'kitaplar': Color(0xFF6B7280),
    'jewelry': Color(0xFFFBBF24),             // Gold for jewelry 💍
    'mücevher': Color(0xFFFBBF24),
    'makeup': Color(0xFFEC4899),
    'makyaj': Color(0xFFEC4899),
    'perfume': Color(0xFF7C3AED),             // Purple for perfume
    'parfüm': Color(0xFF7C3AED),
    
    // === ENTERTAINMENT COLORS (RED/WARM TONES FOR EXPENSES) ===
    'entertainment': Color(0xFFDC2626),       // Red for entertainment expenses
    'eğlence': Color(0xFFDC2626),
    'apple_music': Color(0xFFA855F7),
    'yayın': Color(0xFFDC2626),
    'concerts': Color(0xFF6366F1),            // Blue for concerts 🎤
    'photography': Color(0xFF6B7280),         // Gray for photography 📷
    'fotoğraf': Color(0xFF6B7280),
    
    // === BILLS & UTILITIES COLORS (RED/WARM TONES FOR EXPENSES) ===
    'bills': Color(0xFFDC2626),               // Red for bills
    'receipt': Color(0xFFDC2626),
    'receipt_long': Color(0xFFDC2626),
    'faturalar': Color(0xFFDC2626),
    'electricity': Color(0xFFFBBF24),         // Yellow for electricity ⚡
    'elektrik': Color(0xFFFBBF24),
    'water': Color(0xFF0EA5E9),               // Blue for water 💧
    'su': Color(0xFF0EA5E9),
    'turkcell': Color(0xFF059669),
    'vodafone': Color(0xFFDC2626),            // Vodafone red
    'türk_telekom': Color(0xFF6366F1),        // TT blue
    'digiturk': Color(0xFF6366F1),            // Blue for TV
    'tivibu': Color(0xFF6366F1),
    
    // === HEALTH & WELLNESS COLORS (RED/WARM TONES FOR EXPENSES) ===
    'health': Color(0xFFDC2626),              // Red for health expenses
    'healthcare': Color(0xFFDC2626),
    'health_and_safety': Color(0xFFDC2626),
    'local_hospital': Color(0xFFDC2626),
    'sağlık': Color(0xFFDC2626),
    'doctor': Color(0xFFEF4444),              // Red for doctor visits
    'doktor': Color(0xFFEF4444),
    'pharmacy': Color(0xFF22C55E),            // Green for pharmacy 💊
    'eczane': Color(0xFF22C55E),
    'supplement': Color(0xFF22C55E),          // Green for supplements
    'takviye': Color(0xFF22C55E),
    'vitamin': Color(0xFF22C55E),
    'protein': Color(0xFF059669),
    
    // === EDUCATION COLORS ===
    'education': Color(0xFF2563EB),           // Modern blue
    'school': Color(0xFF2563EB),
    'eğitim': Color(0xFF2563EB),
    'university': Color(0xFF6366F1),          // Modern indigo
    'üniversite': Color(0xFF6366F1),
    'course': Color(0xFF0EA5E9),              // Modern sky blue
    'kurs': Color(0xFF0EA5E9),
    
    // === TRAVEL COLORS ===
    'travel': Color(0xFF7C3AED),              // Modern violet
    'flight': Color(0xFF7C3AED),
    'seyahat': Color(0xFF7C3AED),
    'hotel': Color(0xFFF59E0B),               // Modern amber
    'vacation': Color(0xFF06B6D4),            // Modern cyan
    'tatil': Color(0xFF06B6D4),
    
    // === TECHNOLOGY COLORS ===
    'tech': Color(0xFF3B82F6),                // Modern blue
    'teknoloji': Color(0xFF3B82F6),
    
    // === PERSONAL CARE COLORS ===
    'personal_care': Color(0xFFEC4899),       // Modern pink
    'kişisel_bakım': Color(0xFFEC4899),
    'pets': Color(0xFF92400E),                // Brown
    'evcil_hayvan': Color(0xFF92400E),
    'childcare': Color(0xFFFBBF24),           // Soft yellow
    'çocuk_bakımı': Color(0xFFFBBF24),
    
    
    // === DEFAULT COLORS ===
    'label': Color(0xFF6B7280),               // Cool gray for label
    'folder': Color(0xFF6B7280),              // Cool gray for folder
    'default': Color(0xFF6B7280),             // Cool gray
    'other': Color(0xFF6B7280),
    'diğer': Color(0xFF6B7280),
    // === CUSTOM/NEW CATEGORY COLORS ===
    'evcil_hayvan_maması': Color(0xFF8B5CF6),
    'toy': Color(0xFFF59E42),
    'oyuncak': Color(0xFFF59E42),
    'hairdresser': Color(0xFFEC4899),
    'psychologist': Color(0xFF6366F1),
    'natural_gas': Color(0xFF60A5FA),
    'cargo': Color(0xFF6B7280),
    'office': Color(0xFF6366F1),
    'cleaning_supplies': Color(0xFF10B981),
    'gift_item': Color(0xFF22C55E),
    'fish': Color(0xFF0EA5E9),
    'laundry': Color(0xFF60A5FA),
    'home_renovation': Color(0xFFF59E42),
    'pet_vet': Color(0xFF10B981),
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
    return getColor(colorInput).withValues(alpha: 0.1);
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

  /// Get localized category name with context
  static String getCategoryName(String categoryId, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return _getFallbackCategoryName(categoryId, 'en');
    }
    
    switch (categoryId) {
      case 'food':
        return l10n.food;
      case 'transport':
        return l10n.transport;
      case 'shopping':
        return l10n.shopping;
      case 'entertainment':
        return l10n.entertainment;
      case 'bills':
        return l10n.bills;
      case 'health':
        return l10n.health;
      case 'education':
        return l10n.education;
      case 'travel':
        return l10n.travel;
      case 'other':
        return l10n.other;
      case 'stocks':
        return l10n.stockTrading;
      default:
        return l10n.unknownCategory;
    }
  }

  /// Get localized category name with language code (fallback)
  static String getCategoryNameByLanguage(String categoryId, String language) {
    return _getFallbackCategoryName(categoryId, language);
  }

  /// Internal fallback method
  static String _getFallbackCategoryName(String categoryId, String language) {
    final categoryNames = {
      'food': language == 'tr' ? 'Yemek' : 'Food',
      'transport': language == 'tr' ? 'Ulaşım' : 'Transport',
      'shopping': language == 'tr' ? 'Alışveriş' : 'Shopping',
      'entertainment': language == 'tr' ? 'Eğlence' : 'Entertainment',
      'bills': language == 'tr' ? 'Faturalar' : 'Bills',
      'health': language == 'tr' ? 'Sağlık' : 'Health',
      'education': language == 'tr' ? 'Eğitim' : 'Education',
      'travel': language == 'tr' ? 'Seyahat' : 'Travel',
      'other': language == 'tr' ? 'Diğer' : 'Other',
      'stocks': language == 'tr' ? 'Hisse Alış/Satış' : 'Stock Trading',
    };
    return categoryNames[categoryId] ?? (language == 'tr' ? 'Bilinmeyen Kategori' : 'Unknown Category');
  }

  /// Get fallback category name (for backward compatibility)
  static String getFallbackCategoryName(String categoryId, String language) {
    return getCategoryNameByLanguage(categoryId, language);
  }
} 