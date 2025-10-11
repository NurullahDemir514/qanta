/// Account types supported by the system
enum AccountType {
  credit('credit'),
  debit('debit'),
  cash('cash');

  const AccountType(this.value);
  final String value;

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AccountType.cash,
    );
  }
}

/// Unified account model for all account types (credit cards, debit cards, cash accounts)
class AccountModel {
  final String id;
  final String userId;
  final AccountType type;
  final String name;
  final String? bankName;
  final double balance;
  final double? creditLimit;
  final int? statementDay;
  final int? dueDay;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.bankName,
    this.balance = 0.0,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this is a credit card account
  bool get isCreditCard => type == AccountType.credit;

  /// Whether this is a debit card account
  bool get isDebitCard => type == AccountType.debit;

  /// Whether this is a cash account
  bool get isCashAccount => type == AccountType.cash;

  /// Available amount for spending
  double get availableAmount {
    switch (type) {
      case AccountType.credit:
        // For credit cards, available = credit limit - current balance (debt)
        // Note: balance is positive for debt, negative for overpayment
        final limit = creditLimit ?? 0.0;
        final rawAvailable = limit - balance;
        return rawAvailable.clamp(0.0, limit);
      case AccountType.debit:
      case AccountType.cash:
        // For debit/cash, available = current balance
        return balance;
    }
  }

  /// Used credit amount (for credit cards only)
  double get usedCredit => isCreditCard ? balance.clamp(0.0, double.infinity) : 0.0;

  /// Credit utilization percentage (for credit cards only)
  double get creditUtilization {
    if (!isCreditCard || creditLimit == null || creditLimit == 0) return 0.0;
    return (usedCredit / creditLimit!) * 100;
  }

  /// Display name - always return just the name field
  String get displayName {
    return name;
  }

  /// Account type display name
  String get typeDisplayName {
    switch (type) {
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.debit:
        return 'Debit Card';
      case AccountType.cash:
        return 'Cash Account';
    }
  }

  /// Create from JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: AccountType.fromString(json['type'] as String),
      name: json['name'] as String,
      bankName: json['bank_name'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      statementDay: json['statement_day'] as int?,
      dueDay: json['due_day'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Parse DateTime from various formats (String, Timestamp, DateTime)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is DateTime) return value;
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'name': name,
      'bank_name': bankName,
      'balance': balance,
      'credit_limit': creditLimit,
      'statement_day': statementDay,
      'due_day': dueDay,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AccountModel copyWith({
    String? id,
    String? userId,
    AccountType? type,
    String? name,
    String? bankName,
    double? balance,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AccountModel(id: $id, type: ${type.value}, name: $name, balance: $balance)';
  }
} 