import 'package:flutter/material.dart';

class IncomeCategoryModel {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String iconName;
  final String colorHex;
  final int sortOrder;

  const IncomeCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
  });

  factory IncomeCategoryModel.fromJson(Map<String, dynamic> json) {
    return IncomeCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? 'attach_money_rounded',
      colorHex: json['color_hex']?.toString() ?? '#8E8E93',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'sort_order': sortOrder,
    };
  }

  // Icon widget'ı al
  IconData get icon {
    switch (iconName) {
      case 'work_rounded':
      case 'work_outlined':
        return Icons.work_outlined;
      case 'star_rounded':
      case 'star_outlined':
        return Icons.star_outlined;
      case 'laptop_rounded':
      case 'laptop_outlined':
        return Icons.laptop_outlined;
      case 'business_rounded':
      case 'business_outlined':
        return Icons.business_outlined;
      case 'trending_up_rounded':
      case 'trending_up_outlined':
        return Icons.trending_up_outlined;
      case 'home_rounded':
      case 'home_outlined':
        return Icons.home_outlined;
      case 'card_giftcard_rounded':
      case 'card_giftcard_outlined':
        return Icons.card_giftcard_outlined;
      case 'more_horiz_rounded':
      case 'more_horiz_outlined':
        return Icons.more_horiz_outlined;
      case 'attach_money_rounded':
      case 'attach_money_outlined':
        return Icons.attach_money_outlined;
      default:
        return Icons.attach_money_outlined;
    }
  }

  // Renk al
  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF8E8E93); // Varsayılan renk
    }
  }

  // Arka plan rengi
  Color get backgroundColor {
    return color.withValues(alpha: 0.1);
  }

  IncomeCategoryModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? iconName,
    String? colorHex,
    int? sortOrder,
  }) {
    return IncomeCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncomeCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'IncomeCategoryModel(id: $id, name: $name, displayName: $displayName)';
  }
} 