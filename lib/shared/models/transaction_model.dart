import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
  transfer,
}

extension TransactionTypeExtension on TransactionType {
  // Database için İngilizce değerler
  String get name {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  // UI için Türkçe görüntüleme adları
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Gelir';
      case TransactionType.expense:
        return 'Gider';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String getName(dynamic l10n) {
    // For now, return the display name. Can be enhanced with proper localization later
    return displayName;
  }

  String getDescription(dynamic l10n) {
    switch (this) {
      case TransactionType.income:
        return 'Maaş, bonus, satış geliri';
      case TransactionType.expense:
        return 'Alışveriş, fatura, harcama';
      case TransactionType.transfer:
        return 'Hesaplar arası transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.add_circle_outline;
      case TransactionType.expense:
        return Icons.remove_circle_outline;
      case TransactionType.transfer:
        return Icons.compare_arrows_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF00FFB3);
      case TransactionType.expense:
        return const Color(0xFFFF6B6B);
      case TransactionType.transfer:
        return const Color(0xFF4ECDC4);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF00FFB3).withValues(alpha: 0.1);
      case TransactionType.expense:
        return const Color(0xFFFF6B6B).withValues(alpha: 0.1);
      case TransactionType.transfer:
        return const Color(0xFF4ECDC4).withValues(alpha: 0.1);
    }
  }
}

enum CardType {
  credit,
  debit,
  cash,
}

enum TransactionCategory {
  // Income categories
  salary,
  freelance,
  business,
  gift,
  other,
  
  // Expense categories
  food,
  transport,
  shopping,
  entertainment,
  bills,
  healthcare,
  education,
  travel,
  housing,
  insurance;

  String get displayName {
    switch (this) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.business:
        return 'Business';
      case TransactionCategory.gift:
        return 'Gift';
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.transport:
        return 'Transportation';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.bills:
        return 'Bills & Utilities';
      case TransactionCategory.healthcare:
        return 'Healthcare';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.housing:
        return 'Housing';
      case TransactionCategory.insurance:
        return 'Insurance';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  bool get isIncomeCategory {
    return [
      TransactionCategory.salary,
      TransactionCategory.freelance,
      TransactionCategory.business,
      TransactionCategory.gift,
    ].contains(this);
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? category;
  
  // Kaynak kart bilgileri (sadece biri dolu olacak)
  final String? creditCardId;
  final String? debitCardId;
  final String? cashAccountId;
  
  // Transfer için hedef kart bilgileri
  final String? targetCreditCardId;
  final String? targetDebitCardId;
  final String? targetCashAccountId;
  
  // Taksit bilgileri (kredi kartı için)
  final int installmentCount;
  final int currentInstallment;
  
  // Ek bilgiler
  final String? merchantName;
  final String? location;
  final String? notes;
  
  // Zaman bilgileri
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
    this.creditCardId,
    this.debitCardId,
    this.cashAccountId,
    this.targetCreditCardId,
    this.targetDebitCardId,
    this.targetCashAccountId,
    this.installmentCount = 1,
    this.currentInstallment = 1,
    this.merchantName,
    this.location,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Kaynak kart türünü belirle
  CardType? get sourceCardType {
    if (creditCardId != null) return CardType.credit;
    if (debitCardId != null) return CardType.debit;
    if (cashAccountId != null) return CardType.cash;
    return null;
  }

  // Hedef kart türünü belirle (transfer için)
  CardType? get targetCardType {
    if (targetCreditCardId != null) return CardType.credit;
    if (targetDebitCardId != null) return CardType.debit;
    if (targetCashAccountId != null) return CardType.cash;
    return null;
  }

  // Kaynak kart ID'sini al
  String? get sourceCardId {
    return creditCardId ?? debitCardId ?? cashAccountId;
  }

  // Hedef kart ID'sini al
  String? get targetCardId {
    return targetCreditCardId ?? targetDebitCardId ?? targetCashAccountId;
  }

  // Taksit bilgisi string'i
  String? get installmentInfo {
    if (installmentCount <= 1) return null;
    if (installmentCount == 1) return 'Peşin';
    return '$currentInstallment/$installmentCount Taksit';
  }

  // Transfer işlemi mi?
  bool get isTransfer => type == TransactionType.transfer;

  // Taksitli işlem mi?
  bool get isInstallment => installmentCount > 1;

  // JSON'dan model oluştur
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['type'] as String).toLowerCase(),
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String?,
      creditCardId: json['credit_card_id'] as String?,
      debitCardId: json['debit_card_id'] as String?,
      cashAccountId: json['cash_account_id'] as String?,
      targetCreditCardId: json['target_credit_card_id'] as String?,
      targetDebitCardId: json['target_debit_card_id'] as String?,
      targetCashAccountId: json['target_cash_account_id'] as String?,
      installmentCount: json['installment_count'] as int? ?? 1,
      currentInstallment: json['current_installment'] as int? ?? 1,
      merchantName: json['merchant_name'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  // Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name.toLowerCase(),
      'amount': amount,
      'description': description,
      'category': category,
      'credit_card_id': creditCardId,
      'debit_card_id': debitCardId,
      'cash_account_id': cashAccountId,
      'target_credit_card_id': targetCreditCardId,
      'target_debit_card_id': targetDebitCardId,
      'target_cash_account_id': targetCashAccountId,
      'installment_count': installmentCount,
      'current_installment': currentInstallment,
      'merchant_name': merchantName,
      'location': location,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Veritabanına insert için JSON (id ve timestamp'ler hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'type': type.name.toLowerCase(),
      'amount': amount,
      'description': description,
      'category': category,
      'credit_card_id': creditCardId,
      'debit_card_id': debitCardId,
      'cash_account_id': cashAccountId,
      'target_credit_card_id': targetCreditCardId,
      'target_debit_card_id': targetDebitCardId,
      'target_cash_account_id': targetCashAccountId,
      'installment_count': installmentCount,
      'current_installment': currentInstallment,
      'merchant_name': merchantName,
      'location': location,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }

  // Kopyalama metodu
  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    String? category,
    String? creditCardId,
    String? debitCardId,
    String? cashAccountId,
    String? targetCreditCardId,
    String? targetDebitCardId,
    String? targetCashAccountId,
    int? installmentCount,
    int? currentInstallment,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      creditCardId: creditCardId ?? this.creditCardId,
      debitCardId: debitCardId ?? this.debitCardId,
      cashAccountId: cashAccountId ?? this.cashAccountId,
      targetCreditCardId: targetCreditCardId ?? this.targetCreditCardId,
      targetDebitCardId: targetDebitCardId ?? this.targetDebitCardId,
      targetCashAccountId: targetCashAccountId ?? this.targetCashAccountId,
      installmentCount: installmentCount ?? this.installmentCount,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      merchantName: merchantName ?? this.merchantName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 