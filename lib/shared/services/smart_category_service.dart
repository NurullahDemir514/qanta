import 'package:flutter/material.dart';
import 'category_icon_service.dart';

/// Smart category creation service
/// 
/// Automatically assigns appropriate icons and colors to user-created categories
/// based on intelligent pattern matching of category names. This eliminates
/// the need for users to manually select icons and colors while ensuring
/// visual consistency.
/// 
/// **Features:**
/// - AI-like pattern matching for category names
/// - Multi-language support (Turkish/English)
/// - Intelligent fallbacks for unknown categories
/// - Consistent visual theming
/// - Professional UX without complexity
/// 
/// **Usage:**
/// ```dart
/// final suggestion = SmartCategoryService.suggestCategoryStyle(
///   name: 'Kahve',
///   isIncomeCategory: false,
/// );
/// 
/// final category = CategoryModel(
///   name: 'Kahve',
///   icon: suggestion.iconName,
///   color: suggestion.colorHex,
///   type: CategoryType.expense,
/// );
/// ```
class SmartCategoryService {
  
  /// Suggest appropriate icon and color for a category name
  static CategoryStyleSuggestion suggestCategoryStyle({
    required String name,
    required bool isIncomeCategory,
  }) {
    final cleanName = name.toLowerCase().trim();
    
    if (isIncomeCategory) {
      return _suggestIncomeStyle(cleanName);
    } else {
      return _suggestExpenseStyle(cleanName);
    }
  }
  
  /// Suggest style for income categories
  static CategoryStyleSuggestion _suggestIncomeStyle(String cleanName) {
    // Work and salary related
    if (_containsAny(cleanName, ['maaş', 'salary', 'iş', 'work', 'çalış', 'meslek', 'kariyer'])) {
      return CategoryStyleSuggestion(
        iconName: 'work',
        colorHex: '#34C759',
        confidence: 0.9,
      );
    }
    
    // Freelance and consulting
    if (_containsAny(cleanName, ['freelance', 'danışman', 'konsültan', 'serbest', 'proje', 'hizmet'])) {
      return CategoryStyleSuggestion(
        iconName: 'freelance',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Business and entrepreneurship
    if (_containsAny(cleanName, ['business', 'iş', 'şirket', 'girişim', 'ticaret', 'satış', 'müşteri'])) {
      return CategoryStyleSuggestion(
        iconName: 'business',
        colorHex: '#BF5AF2',
        confidence: 0.9,
      );
    }
    
    // Investment and returns
    if (_containsAny(cleanName, ['yatırım', 'investment', 'kar', 'getiri', 'faiz'])) {
      return CategoryStyleSuggestion(
        iconName: 'investment',
        colorHex: '#FF9500',
        confidence: 0.9,
      );
    }
    
    // Stocks and equity
    if (_containsAny(cleanName, ['hisse', 'stocks', 'borsa', 'equity', 'pay'])) {
      return CategoryStyleSuggestion(
        iconName: 'stocks',
        colorHex: '#64D2FF',
        confidence: 0.9,
      );
    }
    
    // Cryptocurrency
    if (_containsAny(cleanName, ['crypto', 'kripto', 'bitcoin', 'ethereum', 'blockchain'])) {
      return CategoryStyleSuggestion(
        iconName: 'crypto',
        colorHex: '#FF9F0A',
        confidence: 0.9,
      );
    }
    
    // Dividend income
    if (_containsAny(cleanName, ['temettü', 'dividend', 'dividends', 'pay out'])) {
      return CategoryStyleSuggestion(
        iconName: 'dividend',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Commission income
    if (_containsAny(cleanName, ['komisyon', 'commission', 'percentage', 'yüzde', 'satış komisyonu'])) {
      return CategoryStyleSuggestion(
        iconName: 'commission',
        colorHex: '#32D74B',
        confidence: 0.9,
      );
    }
    
    // Rental income
    if (_containsAny(cleanName, ['kira', 'rental', 'rent', 'ev', 'emlak', 'apart', 'daire'])) {
      return CategoryStyleSuggestion(
        iconName: 'rental',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Gifts and bonuses
    if (_containsAny(cleanName, ['hediye', 'gift', 'bonus', 'prim', 'ödül', 'ikramiye'])) {
      return CategoryStyleSuggestion(
        iconName: 'bonus',
        colorHex: '#FF3B30',
        confidence: 0.9,
      );
    }
    
    // Royalty income
    if (_containsAny(cleanName, ['telif', 'royalty', 'royalties', 'patent', 'copyright', 'license'])) {
      return CategoryStyleSuggestion(
        iconName: 'royalty',
        colorHex: '#AF52DE',
        confidence: 0.9,
      );
    }
    
    // Pension income
    if (_containsAny(cleanName, ['emekli', 'pension', 'retirement', 'emeklilik', 'sgk'])) {
      return CategoryStyleSuggestion(
        iconName: 'pension',
        colorHex: '#5AC8FA',
        confidence: 0.9,
      );
    }
    
    // Social benefits
    if (_containsAny(cleanName, ['sosyal', 'social', 'yardım', 'benefits', 'assistance', 'government'])) {
      return CategoryStyleSuggestion(
        iconName: 'social_benefits',
        colorHex: '#5E5CE6',
        confidence: 0.9,
      );
    }
    
    // Default income fallback
    return CategoryStyleSuggestion(
      iconName: 'work',
      colorHex: '#34C759',
      confidence: 0.3,
    );
  }
  
  /// Suggest style for expense categories
  static CategoryStyleSuggestion _suggestExpenseStyle(String cleanName) {
    // Food and dining
    if (_containsAny(cleanName, ['yemek', 'food', 'restoran', 'cafe', 'market', 'gıda', 'içecek', 'drink', 'restaurant'])) {
      return CategoryStyleSuggestion(
        iconName: 'restaurant',
        colorHex: '#FF6B35',
        confidence: 0.9,
      );
    }
    
    // Coffee specific
    if (_containsAny(cleanName, ['kahve', 'coffee', 'latte', 'cappuccino', 'espresso', 'starbucks'])) {
      return CategoryStyleSuggestion(
        iconName: 'coffee',
        colorHex: '#8E6A5B',
        confidence: 0.9,
      );
    }
    
    // Groceries
    if (_containsAny(cleanName, ['market', 'grocery', 'süpermarket', 'migros', 'carrefour', 'a101', 'bim', 'şok'])) {
      return CategoryStyleSuggestion(
        iconName: 'groceries',
        colorHex: '#32D74B',
        confidence: 0.9,
      );
    }
    
    // Fast food
    if (_containsAny(cleanName, ['fast', 'mcdonalds', 'burger', 'pizza', 'döner', 'kebap', 'hamburger'])) {
      return CategoryStyleSuggestion(
        iconName: 'fast_food',
        colorHex: '#FF9500',
        confidence: 0.9,
      );
    }
    
    // Alcohol & bars
    if (_containsAny(cleanName, ['alkol', 'alcohol', 'bar', 'bira', 'beer', 'wine', 'şarap', 'rakı', 'vodka'])) {
      return CategoryStyleSuggestion(
        iconName: 'alcohol',
        colorHex: '#AF52DE',
        confidence: 0.9,
      );
    }
    
    // Delivery
    if (_containsAny(cleanName, ['delivery', 'teslimat', 'yemeksepeti', 'getir', 'trendyol', 'sipariş'])) {
      return CategoryStyleSuggestion(
        iconName: 'delivery',
        colorHex: '#64D2FF',
        confidence: 0.9,
      );
    }
    
    // Transportation - general
    if (_containsAny(cleanName, ['ulaşım', 'transport', 'araba', 'car', 'otobüs', 'metro', 'taksi', 'uber'])) {
      return CategoryStyleSuggestion(
        iconName: 'transport',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Fuel specific
    if (_containsAny(cleanName, ['yakıt', 'benzin', 'fuel', 'gas', 'petrol', 'motorin', 'shell', 'bp', 'opet'])) {
      return CategoryStyleSuggestion(
        iconName: 'fuel',
        colorHex: '#8E8E93',
        confidence: 0.9,
      );
    }
    
    // Public transport
    if (_containsAny(cleanName, ['toplu', 'public', 'otobüs', 'bus', 'metro', 'subway', 'iett', 'İETT'])) {
      return CategoryStyleSuggestion(
        iconName: 'public_transport',
        colorHex: '#5AC8FA',
        confidence: 0.9,
      );
    }
    
    // Taxi & ride sharing
    if (_containsAny(cleanName, ['taksi', 'taxi', 'uber', 'bitaksi', 'martı'])) {
      return CategoryStyleSuggestion(
        iconName: 'taxi',
        colorHex: '#FFCC02',
        confidence: 0.9,
      );
    }
    
    // Parking
    if (_containsAny(cleanName, ['park', 'parking', 'otopark', 'vale'])) {
      return CategoryStyleSuggestion(
        iconName: 'parking',
        colorHex: '#6D6D70',
        confidence: 0.9,
      );
    }
    
    // Bicycle
    if (_containsAny(cleanName, ['bisiklet', 'bicycle', 'bike', 'martı', 'scooter'])) {
      return CategoryStyleSuggestion(
        iconName: 'bicycle',
        colorHex: '#34C759',
        confidence: 0.9,
      );
    }
    
    // Shopping and retail
    if (_containsAny(cleanName, ['alışveriş', 'shopping', 'mağaza', 'store', 'mall', 'online'])) {
      return CategoryStyleSuggestion(
        iconName: 'shopping',
        colorHex: '#FF9F0A',
        confidence: 0.9,
      );
    }
    
    // Clothing
    if (_containsAny(cleanName, ['kıyafet', 'clothes', 'clothing', 'giyim', 'moda', 'fashion', 'zara', 'h&m', 'mango'])) {
      return CategoryStyleSuggestion(
        iconName: 'clothing',
        colorHex: '#FF2D92',
        confidence: 0.9,
      );
    }
    
    // Electronics
    if (_containsAny(cleanName, ['elektronik', 'electronics', 'telefon', 'phone', 'laptop', 'computer', 'teknosa', 'vatan'])) {
      return CategoryStyleSuggestion(
        iconName: 'electronics',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Furniture
    if (_containsAny(cleanName, ['mobilya', 'furniture', 'sandalye', 'masa', 'yatak', 'ikea', 'bellona'])) {
      return CategoryStyleSuggestion(
        iconName: 'furniture',
        colorHex: '#8E6A5B',
        confidence: 0.9,
      );
    }
    
    // Books
    if (_containsAny(cleanName, ['kitap', 'book', 'books', 'okuma', 'reading', 'd&r', 'idefix', 'kitapyurdu'])) {
      return CategoryStyleSuggestion(
        iconName: 'books',
        colorHex: '#8E8E93',
        confidence: 0.9,
      );
    }
    
    // Jewelry
    if (_containsAny(cleanName, ['mücevher', 'jewelry', 'altın', 'gold', 'gümüş', 'silver', 'yüzük', 'kolye'])) {
      return CategoryStyleSuggestion(
        iconName: 'jewelry',
        colorHex: '#FFD60A',
        confidence: 0.9,
      );
    }
    
    // Entertainment and leisure
    if (_containsAny(cleanName, ['eğlence', 'entertainment', 'sinema', 'cinema', 'film', 'movie'])) {
      return CategoryStyleSuggestion(
        iconName: 'entertainment',
        colorHex: '#BF5AF2',
        confidence: 0.9,
      );
    }
    
    // Music
    if (_containsAny(cleanName, ['müzik', 'music', 'spotify', 'apple music', 'youtube music', 'konser', 'concert'])) {
      return CategoryStyleSuggestion(
        iconName: 'music',
        colorHex: '#AF52DE',
        confidence: 0.9,
      );
    }
    
    // Gaming
    if (_containsAny(cleanName, ['oyun', 'game', 'gaming', 'playstation', 'xbox', 'steam', 'twitch'])) {
      return CategoryStyleSuggestion(
        iconName: 'gaming',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Streaming services
    if (_containsAny(cleanName, ['streaming', 'netflix', 'amazon prime', 'disney', 'hulu', 'yayın', 'dizi', 'film'])) {
      return CategoryStyleSuggestion(
        iconName: 'streaming',
        colorHex: '#FF3B30',
        confidence: 0.9,
      );
    }
    
    // Photography
    if (_containsAny(cleanName, ['fotoğraf', 'photography', 'camera', 'photo', 'instagram', 'adobe'])) {
      return CategoryStyleSuggestion(
        iconName: 'photography',
        colorHex: '#8E8E93',
        confidence: 0.9,
      );
    }
    
    // Bills and utilities
    if (_containsAny(cleanName, ['fatura', 'bill', 'bills', 'utilities', 'ödeme'])) {
      return CategoryStyleSuggestion(
        iconName: 'bills',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Electricity
    if (_containsAny(cleanName, ['elektrik', 'electric', 'electricity', 'boğaziçi', 'ayedaş', 'bedaş'])) {
      return CategoryStyleSuggestion(
        iconName: 'electricity',
        colorHex: '#FFD60A',
        confidence: 0.9,
      );
    }
    
    // Water
    if (_containsAny(cleanName, ['su', 'water', 'iski', 'aski'])) {
      return CategoryStyleSuggestion(
        iconName: 'water',
        colorHex: '#64D2FF',
        confidence: 0.9,
      );
    }
    
    // Internet
    if (_containsAny(cleanName, ['internet', 'wifi', 'türk telekom', 'vodafone', 'turkcell'])) {
      return CategoryStyleSuggestion(
        iconName: 'internet',
        colorHex: '#5AC8FA',
        confidence: 0.9,
      );
    }
    
    // Phone
    if (_containsAny(cleanName, ['telefon', 'phone', 'mobile', 'gsm', 'hat'])) {
      return CategoryStyleSuggestion(
        iconName: 'phone',
        colorHex: '#34C759',
        confidence: 0.9,
      );
    }
    
    // Subscriptions
    if (_containsAny(cleanName, ['abonelik', 'subscription', 'monthly', 'aylık', 'premium'])) {
      return CategoryStyleSuggestion(
        iconName: 'subscription',
        colorHex: '#FF9500',
        confidence: 0.9,
      );
    }
    
    // Insurance
    if (_containsAny(cleanName, ['sigorta', 'insurance', 'axa', 'allianz', 'zurich'])) {
      return CategoryStyleSuggestion(
        iconName: 'insurance',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Health and medical
    if (_containsAny(cleanName, ['sağlık', 'health', 'doktor', 'doctor', 'hastane', 'hospital'])) {
      return CategoryStyleSuggestion(
        iconName: 'health',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Doctor
    if (_containsAny(cleanName, ['doktor', 'doctor', 'dr.', 'hekim', 'muayene'])) {
      return CategoryStyleSuggestion(
        iconName: 'doctor',
        colorHex: '#64D2FF',
        confidence: 0.9,
      );
    }
    
    // Pharmacy
    if (_containsAny(cleanName, ['eczane', 'pharmacy', 'ilaç', 'medicine', 'drug'])) {
      return CategoryStyleSuggestion(
        iconName: 'pharmacy',
        colorHex: '#32D74B',
        confidence: 0.9,
      );
    }
    
    // Fitness & gym
    if (_containsAny(cleanName, ['spor', 'sport', 'gym', 'fitness', 'antrenman', 'workout', 'koşu', 'running'])) {
      return CategoryStyleSuggestion(
        iconName: 'fitness',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Beauty & spa
    if (_containsAny(cleanName, ['güzellik', 'beauty', 'kuaför', 'hairdresser', 'spa', 'masaj', 'massage'])) {
      return CategoryStyleSuggestion(
        iconName: 'beauty',
        colorHex: '#FF2D92',
        confidence: 0.9,
      );
    }
    
    // Education and learning
    if (_containsAny(cleanName, ['eğitim', 'education', 'okul', 'school', 'course', 'kurs'])) {
      return CategoryStyleSuggestion(
        iconName: 'education',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // University
    if (_containsAny(cleanName, ['üniversite', 'university', 'college', 'yüksekokul'])) {
      return CategoryStyleSuggestion(
        iconName: 'university',
        colorHex: '#5E5CE6',
        confidence: 0.9,
      );
    }
    
    // Travel and vacation
    if (_containsAny(cleanName, ['seyahat', 'travel', 'tatil', 'vacation', 'uçak', 'flight'])) {
      return CategoryStyleSuggestion(
        iconName: 'travel',
        colorHex: '#5E5CE6',
        confidence: 0.9,
      );
    }
    
    // Hotel
    if (_containsAny(cleanName, ['otel', 'hotel', 'konaklama', 'accommodation', 'booking'])) {
      return CategoryStyleSuggestion(
        iconName: 'hotel',
        colorHex: '#FF9500',
        confidence: 0.9,
      );
    }
    
    // Technology & digital
    if (_containsAny(cleanName, ['teknoloji', 'tech', 'technology', 'digital', 'dijital'])) {
      return CategoryStyleSuggestion(
        iconName: 'tech',
        colorHex: '#007AFF',
        confidence: 0.9,
      );
    }
    
    // Software
    if (_containsAny(cleanName, ['yazılım', 'software', 'app', 'uygulama', 'adobe', 'microsoft', 'google'])) {
      return CategoryStyleSuggestion(
        iconName: 'software',
        colorHex: '#BF5AF2',
        confidence: 0.9,
      );
    }
    
    // Personal care
    if (_containsAny(cleanName, ['kişisel', 'personal', 'bakım', 'care', 'hygiene', 'hijyen'])) {
      return CategoryStyleSuggestion(
        iconName: 'personal_care',
        colorHex: '#FF2D92',
        confidence: 0.9,
      );
    }
    
    // Pets
    if (_containsAny(cleanName, ['evcil', 'pet', 'pets', 'köpek', 'kedi', 'dog', 'cat', 'animal', 'hayvan'])) {
      return CategoryStyleSuggestion(
        iconName: 'pets',
        colorHex: '#8E6A5B',
        confidence: 0.9,
      );
    }
    
    // Childcare
    if (_containsAny(cleanName, ['çocuk', 'child', 'children', 'baby', 'bebek', 'kreş', 'daycare'])) {
      return CategoryStyleSuggestion(
        iconName: 'childcare',
        colorHex: '#FFB3BA',
        confidence: 0.9,
      );
    }
    
    // Housing and home
    if (_containsAny(cleanName, ['ev', 'home', 'house', 'kira', 'rent', 'emlak', 'real estate'])) {
      return CategoryStyleSuggestion(
        iconName: 'home',
        colorHex: '#30D158',
        confidence: 0.9,
      );
    }
    
    // Default expense fallback
    return CategoryStyleSuggestion(
      iconName: 'other',
      colorHex: '#8E8E93',
      confidence: 0.3,
    );
  }
  
  /// Check if any of the keywords exist in the text
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }
  
  /// Get popular category suggestions for auto-complete
  static List<CategoryNameSuggestion> getPopularCategories({
    required bool isIncomeCategory,
    String? searchQuery,
  }) {
    List<CategoryNameSuggestion> suggestions;
    
    if (isIncomeCategory) {
      suggestions = [
        // Traditional income sources
        CategoryNameSuggestion(name: 'Yan Gelir', icon: 'work', color: '#34C759'),
        CategoryNameSuggestion(name: 'Danışmanlık', icon: 'freelance', color: '#007AFF'),
        CategoryNameSuggestion(name: 'Satış Komisyonu', icon: 'commission', color: '#32D74B'),
        CategoryNameSuggestion(name: 'Kiralama', icon: 'rental', color: '#30D158'),
        CategoryNameSuggestion(name: 'Hisse Karı', icon: 'stocks', color: '#64D2FF'),
        CategoryNameSuggestion(name: 'Temettü', icon: 'dividend', color: '#30D158'),
        CategoryNameSuggestion(name: 'Kripto Karı', icon: 'crypto', color: '#FF9F0A'),
        CategoryNameSuggestion(name: 'Telif Hakkı', icon: 'royalty', color: '#AF52DE'),
        CategoryNameSuggestion(name: 'Emeklilik', icon: 'pension', color: '#5AC8FA'),
        CategoryNameSuggestion(name: 'Sosyal Yardım', icon: 'social_benefits', color: '#5E5CE6'),
      ];
    } else {
      suggestions = [
        // Food & Dining
        CategoryNameSuggestion(name: 'Kahve & Çay', icon: 'coffee', color: '#8E6A5B'),
        CategoryNameSuggestion(name: 'Market', icon: 'groceries', color: '#32D74B'),
        CategoryNameSuggestion(name: 'Fast Food', icon: 'fast_food', color: '#FF9500'),
        CategoryNameSuggestion(name: 'Yemek Siparişi', icon: 'delivery', color: '#64D2FF'),
        
        // Transportation
        CategoryNameSuggestion(name: 'Yakıt', icon: 'fuel', color: '#8E8E93'),
        CategoryNameSuggestion(name: 'Taksi & Uber', icon: 'taxi', color: '#FFCC02'),
        CategoryNameSuggestion(name: 'Toplu Taşıma', icon: 'public_transport', color: '#5AC8FA'),
        CategoryNameSuggestion(name: 'Park Ücreti', icon: 'parking', color: '#6D6D70'),
        
        // Shopping
        CategoryNameSuggestion(name: 'Kıyafet', icon: 'clothing', color: '#FF2D92'),
        CategoryNameSuggestion(name: 'Elektronik', icon: 'electronics', color: '#007AFF'),
        CategoryNameSuggestion(name: 'Kitap', icon: 'books', color: '#8E8E93'),
        CategoryNameSuggestion(name: 'Mobilya', icon: 'furniture', color: '#8E6A5B'),
        
        // Entertainment
        CategoryNameSuggestion(name: 'Müzik (Spotify)', icon: 'music', color: '#AF52DE'),
        CategoryNameSuggestion(name: 'Oyun', icon: 'gaming', color: '#30D158'),
        CategoryNameSuggestion(name: 'Netflix', icon: 'streaming', color: '#FF3B30'),
        CategoryNameSuggestion(name: 'Fotoğrafçılık', icon: 'photography', color: '#8E8E93'),
        
        // Bills & Utilities
        CategoryNameSuggestion(name: 'Elektrik', icon: 'electricity', color: '#FFD60A'),
        CategoryNameSuggestion(name: 'Su Faturası', icon: 'water', color: '#64D2FF'),
        CategoryNameSuggestion(name: 'İnternet', icon: 'internet', color: '#5AC8FA'),
        CategoryNameSuggestion(name: 'Telefon', icon: 'phone', color: '#34C759'),
        CategoryNameSuggestion(name: 'Abonelik', icon: 'subscription', color: '#FF9500'),
        
        // Health & Wellness
        CategoryNameSuggestion(name: 'Doktor', icon: 'doctor', color: '#64D2FF'),
        CategoryNameSuggestion(name: 'Eczane', icon: 'pharmacy', color: '#32D74B'),
        CategoryNameSuggestion(name: 'Spor Salonu', icon: 'fitness', color: '#30D158'),
        CategoryNameSuggestion(name: 'Kuaför', icon: 'beauty', color: '#FF2D92'),
        
        // Personal Care & Family
        CategoryNameSuggestion(name: 'Kişisel Bakım', icon: 'personal_care', color: '#FF2D92'),
        CategoryNameSuggestion(name: 'Evcil Hayvan', icon: 'pets', color: '#8E6A5B'),
        CategoryNameSuggestion(name: 'Çocuk Bakımı', icon: 'childcare', color: '#FFB3BA'),
        
        // Technology
        CategoryNameSuggestion(name: 'Yazılım', icon: 'software', color: '#BF5AF2'),
        CategoryNameSuggestion(name: 'Teknoloji', icon: 'tech', color: '#007AFF'),
        
        // Travel
        CategoryNameSuggestion(name: 'Otel', icon: 'hotel', color: '#FF9500'),
        
        // Education
        CategoryNameSuggestion(name: 'Üniversite', icon: 'university', color: '#5E5CE6'),
      ];
    }
    
    // Filter based on search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      suggestions = suggestions
          .where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    
    return suggestions;
  }
}

/// Category style suggestion result
class CategoryStyleSuggestion {
  final String iconName;
  final String colorHex;
  final double confidence; // 0.0 to 1.0
  
  const CategoryStyleSuggestion({
    required this.iconName,
    required this.colorHex,
    required this.confidence,
  });
  
  /// Whether this suggestion is confident (high accuracy)
  bool get isConfident => confidence >= 0.8;
  
  /// Get icon data
  IconData get icon => CategoryIconService.getIcon(iconName);
  
  /// Get color
  Color get color => CategoryIconService.getColor(colorHex);
}

/// Category name suggestion for auto-complete
class CategoryNameSuggestion {
  final String name;
  final String icon;
  final String color;
  
  const CategoryNameSuggestion({
    required this.name,
    required this.icon,
    required this.color,
  });
  
  /// Get icon data
  IconData get iconData => CategoryIconService.getIcon(icon);
  
  /// Get color data
  Color get colorData => CategoryIconService.getColor(color);
} 