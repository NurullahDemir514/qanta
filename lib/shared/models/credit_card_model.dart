import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/constants/app_constants.dart';

class CreditCardModel {
  final String id;
  final String userId;
  final String bankCode;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final double availableLimit;
  final double totalDebt;
  final int statementDate; // 1-28
  final int dueDate; // 1-31
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditCardModel({
    required this.id,
    required this.userId,
    required this.bankCode,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.availableLimit,
    required this.totalDebt,
    required this.statementDate,
    required this.dueDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Banka adını al
  String get bankName => AppConstants.getBankName(bankCode);

  // Banka rengini al
  Color get bankColor => AppConstants.getBankAccentColor(bankCode);

  // Kullanım oranını hesapla (%)
  double get usagePercentage {
    if (creditLimit <= 0) return 0.0;
    return (totalDebt / creditLimit) * 100;
  }

  // Kullanılabilir limit hesapla
  double get calculatedAvailableLimit => creditLimit - totalDebt;

  // Kart numarası formatı
  String get formattedCardNumber => '**** **** **** $lastFourDigits';

  // Ekstre tarihini hesapla (bu ay veya gelecek ay)
  DateTime get nextStatementDate {
    final now = DateTime.now();
    var statementMonth = now.month;
    var statementYear = now.year;
    
    // Eğer bu ayın ekstre günü geçtiyse, gelecek aya geç
    if (now.day > statementDate) {
      statementMonth++;
      if (statementMonth > 12) {
        statementMonth = 1;
        statementYear++;
      }
    }
    
    return DateTime(statementYear, statementMonth, statementDate);
  }

  // Son ödeme tarihini hesapla
  DateTime get nextDueDate {
    final statementDate = nextStatementDate;
    var dueMonth = statementDate.month;
    var dueYear = statementDate.year;
    
    // Son ödeme tarihi ekstre tarihinden sonraki ayda
    dueMonth++;
    if (dueMonth > 12) {
      dueMonth = 1;
      dueYear++;
    }
    
    // Ayın son gününü kontrol et
    final lastDayOfMonth = DateTime(dueYear, dueMonth + 1, 0).day;
    final actualDueDate = dueDate > lastDayOfMonth ? lastDayOfMonth : dueDate;
    
    return DateTime(dueYear, dueMonth, actualDueDate);
  }

  // Kalan gün sayısı (son ödeme tarihine)
  int get daysUntilDue {
    final now = DateTime.now();
    final due = nextDueDate;
    return due.difference(now).inDays;
  }

  // JSON'dan model oluştur
  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankCode: json['bank_code'] as String,
      cardName: json['card_name'] as String? ?? 'Kredi Kartı',
      lastFourDigits: json['card_number_last_four'] as String,
      creditLimit: (json['credit_limit'] as num).toDouble(),
      availableLimit: (json['available_limit'] as num).toDouble(),
      totalDebt: (json['current_balance'] as num).toDouble(),
      statementDate: json['statement_day'] as int,
      dueDate: json['due_day'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_code': bankCode,
      'card_name': cardName,
      'card_number_last_four': lastFourDigits,
      'credit_limit': creditLimit,
      'available_limit': availableLimit,
      'current_balance': totalDebt,
      'statement_day': statementDate,
      'due_day': dueDate,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Veritabanı insert için JSON (id ve timestamp'ler hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'bank_code': bankCode,
      'card_name': cardName,
      'card_number_last_four': lastFourDigits,
      'credit_limit': creditLimit,
      'available_limit': availableLimit,
      'current_balance': totalDebt,
      'statement_day': statementDate,
      'due_day': dueDate,
      'is_active': isActive,
    };
  }

  // Kopyalama metodu
  CreditCardModel copyWith({
    String? id,
    String? userId,
    String? bankCode,
    String? cardName,
    String? lastFourDigits,
    double? creditLimit,
    double? availableLimit,
    double? totalDebt,
    int? statementDate,
    int? dueDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankCode: bankCode ?? this.bankCode,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      creditLimit: creditLimit ?? this.creditLimit,
      availableLimit: availableLimit ?? this.availableLimit,
      totalDebt: totalDebt ?? this.totalDebt,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CreditCardModel(id: $id, bankCode: $bankCode, cardName: $cardName, lastFourDigits: $lastFourDigits, creditLimit: $creditLimit, totalDebt: $totalDebt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 