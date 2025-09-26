import 'package:flutter/material.dart';
import 'category_icon_service.dart';
import 'smart_category_service.dart';

/// Test helper to demonstrate the expanded categories
class CategoryTestHelper {
  
  /// Test all expense categories
  static void testExpenseCategories() {
    final testCategories = [
      // Food & Dining
      'kahve', 'market', 'fast food', 'delivery', 'restaurant',
      
      // Transportation  
      'yakıt', 'taksi', 'toplu taşıma', 'park', 'bisiklet',
      
      // Shopping
      'kıyafet', 'elektronik', 'kitap', 'mobilya', 'mücevher',
      
      // Entertainment
      'müzik', 'oyun', 'netflix', 'fotoğraf', 'sinema',
      
      // Bills & Utilities
      'elektrik', 'su', 'internet', 'telefon', 'abonelik',
      
      // Health & Wellness
      'doktor', 'eczane', 'spor', 'güzellik', 'sağlık',
      
      // Personal Care & Family
      'kişisel bakım', 'evcil hayvan', 'çocuk bakımı',
      
      // Technology
      'yazılım', 'teknoloji',
      
      // Education & Travel
      'üniversite', 'otel', 'eğitim',
    ];
    
    for (final category in testCategories) {
      final suggestion = SmartCategoryService.suggestCategoryStyle(
        name: category,
        isIncomeCategory: false,
      );
      
      final icon = CategoryIconService.getIcon(suggestion.iconName);
      final color = CategoryIconService.getColor(suggestion.colorHex);
      
    }
  }
  
  /// Test all income categories
  static void testIncomeCategories() {
    final testCategories = [
      'maaş', 'freelance', 'danışmanlık', 'satış komisyonu',
      'kira', 'hisse', 'kripto', 'temettü', 'telif',
      'emeklilik', 'sosyal yardım', 'bonus',
    ];
    
    for (final category in testCategories) {
      final suggestion = SmartCategoryService.suggestCategoryStyle(
        name: category,
        isIncomeCategory: true,
      );
      
      final icon = CategoryIconService.getIcon(suggestion.iconName);
      final color = CategoryIconService.getColor(suggestion.colorHex);
      
    }
  }
  
  /// Get all expense icons for display
  static Map<String, CategoryDisplay> getAllExpenseCategories() {
    final icons = CategoryIconService.getAllExpenseIcons();
    return icons.map((key, icon) => MapEntry(
      key,
      CategoryDisplay(
        name: _getCategoryDisplayName(key, false),
        icon: icon,
        color: CategoryIconService.getExpenseColor(key),
        iconName: key,
      ),
    ));
  }
  
  /// Get all income icons for display  
  static Map<String, CategoryDisplay> getAllIncomeCategories() {
    final icons = CategoryIconService.getAllIncomeIcons();
    return icons.map((key, icon) => MapEntry(
      key,
      CategoryDisplay(
        name: _getCategoryDisplayName(key, true),
        icon: icon,
        color: CategoryIconService.getIncomeColor(key),
        iconName: key,
      ),
    ));
  }
  
  /// Get display name for category
  static String _getCategoryDisplayName(String iconName, bool isIncome) {
    switch (iconName) {
      // Food & Dining
      case 'restaurant': return 'Restoran';
      case 'coffee': return 'Kahve';
      case 'groceries': return 'Market';
      case 'fast_food': return 'Fast Food';
      case 'alcohol': return 'Alkol';
      case 'delivery': return 'Yemek Siparişi';
      
      // Transportation
      case 'car': return 'Araba';
      case 'fuel': return 'Yakıt';
      case 'public_transport': return 'Toplu Taşıma';
      case 'taxi': return 'Taksi';
      case 'parking': return 'Park';
      case 'bicycle': return 'Bisiklet';
      
      // Shopping
      case 'shopping': return 'Alışveriş';
      case 'clothing': return 'Kıyafet';
      case 'electronics': return 'Elektronik';
      case 'furniture': return 'Mobilya';
      case 'books': return 'Kitap';
      case 'jewelry': return 'Mücevher';
      
      // Entertainment
      case 'entertainment': return 'Eğlence';
      case 'music': return 'Müzik';
      case 'gaming': return 'Oyun';
      case 'streaming': return 'Streaming';
      case 'photography': return 'Fotoğraf';
      
      // Bills & Utilities
      case 'bills': return 'Faturalar';
      case 'electricity': return 'Elektrik';
      case 'water': return 'Su';
      case 'internet': return 'İnternet';
      case 'phone': return 'Telefon';
      case 'subscription': return 'Abonelik';
      case 'insurance': return 'Sigorta';
      
      // Health & Wellness
      case 'health': return 'Sağlık';
      case 'doctor': return 'Doktor';
      case 'pharmacy': return 'Eczane';
      case 'fitness': return 'Spor';
      case 'beauty': return 'Güzellik';
      
      // Education & Travel
      case 'education': return 'Eğitim';
      case 'university': return 'Üniversite';
      case 'course': return 'Kurs';
      case 'travel': return 'Seyahat';
      case 'hotel': return 'Otel';
      case 'vacation': return 'Tatil';
      
      // Personal Care & Family
      case 'personal_care': return 'Kişisel Bakım';
      case 'pets': return 'Evcil Hayvan';
      case 'childcare': return 'Çocuk Bakımı';
      
      // Technology
      case 'tech': return 'Teknoloji';
      case 'software': return 'Yazılım';
      
      // Income categories
      case 'work': return 'Maaş';
      case 'business': return 'İş';
      case 'investment': return 'Yatırım';
      case 'gift': return 'Hediye';
      case 'rental': return 'Kira';
      case 'freelance': return 'Freelance';
      case 'bonus': return 'Bonus';
      case 'commission': return 'Komisyon';
      case 'dividend': return 'Temettü';
      case 'crypto': return 'Kripto';
      case 'stocks': return 'Hisse';
      case 'royalty': return 'Telif';
      case 'pension': return 'Emeklilik';
      case 'social_benefits': return 'Sosyal Yardım';
      
      case 'other': return 'Diğer';
      default: return iconName.replaceAll('_', ' ').toUpperCase();
    }
  }
  
  /// Test popular suggestions
  static void testPopularSuggestions() {
    final incomeSuggestions = SmartCategoryService.getPopularCategories(isIncomeCategory: true);
    for (final suggestion in incomeSuggestions) {
    }
    
    final expenseSuggestions = SmartCategoryService.getPopularCategories(isIncomeCategory: false);
    for (final suggestion in expenseSuggestions.take(10)) {  // Show first 10
    }
  }
  
  /// Run all tests
  static void runAllTests() {
    testExpenseCategories();
    debugPrint('');
    testIncomeCategories();
    debugPrint('');
    testPopularSuggestions();
  }
}

/// Category display helper class
class CategoryDisplay {
  final String name;
  final IconData icon;
  final Color color;
  final String iconName;
  
  const CategoryDisplay({
    required this.name,
    required this.icon,
    required this.color,
    required this.iconName,
  });
  
  @override
  String toString() => 'CategoryDisplay(name: $name, iconName: $iconName)';
} 