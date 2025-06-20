/// Category types supported by the system
enum CategoryType {
  income('income'),
  expense('expense');

  const CategoryType(this.value);
  final String value;

  static CategoryType fromString(String value) {
    return CategoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CategoryType.expense,
    );
  }
}

/// Category model for income and expense categorization
class CategoryModel {
  final String id;
  final String? userId; // null for system categories
  final CategoryType type;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    this.userId,
    required this.type,
    required this.name,
    this.icon = 'label',
    this.color = '#6B7280',
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this is a system category (available to all users)
  bool get isSystemCategory => userId == null;

  /// Whether this is a user-created category
  bool get isUserCategory => userId != null;

  /// Whether this is an income category
  bool get isIncomeCategory => type == CategoryType.income;

  /// Whether this is an expense category
  bool get isExpenseCategory => type == CategoryType.expense;

  /// Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      type: CategoryType.fromString(json['type'] as String),
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'label',
      color: json['color'] as String? ?? '#6B7280',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? userId,
    CategoryType? type,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CategoryModel(id: $id, type: ${type.value}, name: $name)';
  }
} 