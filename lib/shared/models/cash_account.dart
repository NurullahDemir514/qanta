class CashAccount {
  final String id;
  final String userId;
  final String name; // "Nakit Param", "Cüzdanım" vs.
  final double balance; // Mevcut nakit miktarı
  final String currency; // TRY, USD, EUR vs.
  final DateTime createdAt;
  final DateTime updatedAt;

  const CashAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON'dan model oluştur
  factory CashAccount.fromJson(Map<String, dynamic> json) {
    return CashAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Veritabanına insert için (id ve timestamp'ler olmadan)
  Map<String, dynamic> toInsert() {
    return {
      'user_id': userId,
      'name': name,
      'balance': balance,
      'currency': currency,
    };
  }

  // Bakiye güncelleme için yeni instance oluştur
  CashAccount copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CashAccount(id: $id, name: $name, balance: $balance $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CashAccount && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 