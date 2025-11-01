import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının tasarruf kategorisi modeli
class SavingsCategory {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String color; // Hex color
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  SavingsCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Firebase'e dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'emoji': emoji,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Firebase'den oluştur
  factory SavingsCategory.fromJson(Map<String, dynamic> json) {
    return SavingsCategory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💰',
      color: json['color'] as String? ?? 'FF5733',
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] is Timestamp
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Kopyalama metodu
  SavingsCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SavingsCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

