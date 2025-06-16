import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';

class DebitCardModel {
  final String id;
  final String userId;
  final String bankCode; // 'garanti', 'akbank', 'isbank' vs.
  final String cardName;
  final String lastFourDigits;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebitCardModel({
    required this.id,
    required this.userId,
    required this.bankCode,
    required this.cardName,
    required this.lastFourDigits,
    required this.balance,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Banka adını al
  String get bankName => AppConstants.getBankName(bankCode);

  // Banka renklerini al
  List<Color> get gradientColors => AppConstants.getBankGradientColors(bankCode);
  Color get accentColor => AppConstants.getBankAccentColor(bankCode);

  // Kart görüntü adı
  String get displayName => '$bankName $cardName';

  // Kart numarası (maskelenmiş)
  String get maskedCardNumber => '**** **** **** $lastFourDigits';

  // Rastgele 4 haneli sayı üret
  static String generateRandomLastFourDigits() {
    final random = Random();
    final digits = List.generate(4, (index) => random.nextInt(10));
    return digits.join();
  }

  // copyWith metodu
  DebitCardModel copyWith({
    String? id,
    String? userId,
    String? bankCode,
    String? cardName,
    String? lastFourDigits,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebitCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankCode: bankCode ?? this.bankCode,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON'dan model oluştur
  factory DebitCardModel.fromJson(Map<String, dynamic> json) {
    return DebitCardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankCode: json['bank_code'] as String,
      cardName: json['card_name'] as String,
      lastFourDigits: json['card_number_last_four'] as String,
      balance: (json['current_balance'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_code': bankCode,
      'card_name': cardName,
      'card_number_last_four': lastFourDigits,
      'current_balance': balance,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Veritabanına insert için JSON (id ve timestamp'ler hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'bank_code': bankCode,
      'card_name': cardName,
      'card_number_last_four': lastFourDigits,
      'current_balance': balance,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebitCardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DebitCardModel(id: $id, bankName: $bankName, cardName: $cardName, balance: $balance)';
  }
} 