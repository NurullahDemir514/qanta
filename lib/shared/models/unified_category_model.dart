import 'package:flutter/material.dart';
import '../services/category_icon_service.dart';

/// Unified category model for all transaction types
class UnifiedCategoryModel {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String iconName;
  final String colorHex;
  final int sortOrder;
  final CategoryType categoryType;
  final bool isUserCategory;

  const UnifiedCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
    required this.categoryType,
    this.isUserCategory = false,
  });

  /// Get icon from icon name using centralized service
  IconData get icon {
    return CategoryIconService.getIcon(iconName);
  }

  /// Get color from hex string using centralized service
  Color get color {
    return CategoryIconService.getColor(colorHex);
  }

  /// Get background color with opacity
  Color get backgroundColor {
    return color.withOpacity(0.1);
  }

  /// Create from JSON
  factory UnifiedCategoryModel.fromJson(Map<String, dynamic> json) {
    return UnifiedCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'more_horiz_rounded',
      colorHex: json['color_hex'] as String? ?? '#6B7280',
      sortOrder: json['sort_order'] as int? ?? 0,
      categoryType: CategoryType.fromString(json['category_type'] as String? ?? 'other'),
      isUserCategory: json['is_user_category'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'category_type': categoryType.name,
      'is_user_category': isUserCategory,
    };
  }

  /// Copy with new values
  UnifiedCategoryModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    CategoryType? categoryType,
    bool? isUserCategory,
  }) {
    return UnifiedCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      categoryType: categoryType ?? this.categoryType,
      isUserCategory: isUserCategory ?? this.isUserCategory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedCategoryModel(id: $id, name: $name, displayName: $displayName, categoryType: $categoryType)';
  }
}

/// Category types enum
enum CategoryType {
  income,
  expense,
  transfer,
  other;

  /// Get display name
  String get displayName {
    switch (this) {
      case CategoryType.income:
        return 'Gelir';
      case CategoryType.expense:
        return 'Gider';
      case CategoryType.transfer:
        return 'Transfer';
      case CategoryType.other:
        return 'Diğer';
    }
  }

  /// Get color
  Color get color {
    switch (this) {
      case CategoryType.income:
        return const Color(0xFF00FFB3);
      case CategoryType.expense:
        return const Color(0xFFFF6B6B);
      case CategoryType.transfer:
        return const Color(0xFF4ECDC4);
      case CategoryType.other:
        return const Color(0xFF6B7280);
    }
  }

  /// Create from string
  static CategoryType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'expense':
        return CategoryType.expense;
      case 'transfer':
        return CategoryType.transfer;
      default:
        return CategoryType.other;
    }
  }
}

/// Category statistics model
class CategoryStatsModel {
  final String category;
  final String categoryDisplayName;
  final double totalAmount;
  final int transactionCount;
  final double avgAmount;
  final double percentage;

  const CategoryStatsModel({
    required this.category,
    required this.categoryDisplayName,
    required this.totalAmount,
    required this.transactionCount,
    required this.avgAmount,
    required this.percentage,
  });

  factory CategoryStatsModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatsModel(
      category: json['category'] as String,
      categoryDisplayName: json['category_display_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      avgAmount: (json['avg_amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'category_display_name': categoryDisplayName,
      'total_amount': totalAmount,
      'transaction_count': transactionCount,
      'avg_amount': avgAmount,
      'percentage': percentage,
    };
  }
}

/// Category usage statistics model
class CategoryUsageStatsModel {
  final String transactionType;
  final String category;
  final String categoryDisplayName;
  final int transactionCount;
  final double totalAmount;
  final double avgAmount;
  final DateTime lastUsed;

  const CategoryUsageStatsModel({
    required this.transactionType,
    required this.category,
    required this.categoryDisplayName,
    required this.transactionCount,
    required this.totalAmount,
    required this.avgAmount,
    required this.lastUsed,
  });

  factory CategoryUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return CategoryUsageStatsModel(
      transactionType: json['transaction_type'] as String,
      category: json['category'] as String,
      categoryDisplayName: json['category_display_name'] as String,
      transactionCount: json['transaction_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      avgAmount: (json['avg_amount'] as num).toDouble(),
      lastUsed: DateTime.parse(json['last_used'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_type': transactionType,
      'category': category,
      'category_display_name': categoryDisplayName,
      'transaction_count': transactionCount,
      'total_amount': totalAmount,
      'avg_amount': avgAmount,
      'last_used': lastUsed.toUtc().toIso8601String(),
    };
  }
} 