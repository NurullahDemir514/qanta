import 'package:flutter/material.dart';
import '../../../shared/models/transaction_model.dart';

enum TransferType {
  cardToCard,
  cardToCash,
  cashToCard,
  cashToCash,
}

extension TransferTypeExtension on TransferType {
  String get displayName {
    switch (this) {
      case TransferType.cardToCard:
        return 'Kart → Kart';
      case TransferType.cardToCash:
        return 'Kart → Nakit';
      case TransferType.cashToCard:
        return 'Nakit → Kart';
      case TransferType.cashToCash:
        return 'Nakit → Nakit';
    }
  }

  IconData get icon {
    switch (this) {
      case TransferType.cardToCard:
        return Icons.credit_card_outlined;
      case TransferType.cardToCash:
        return Icons.account_balance_wallet_outlined;
      case TransferType.cashToCard:
        return Icons.payment_outlined;
      case TransferType.cashToCash:
        return Icons.compare_arrows_rounded;
    }
  }

  Color get color {
    return const Color(0xFF4ECDC4);
  }
}

class TransferModel {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String? notes;
  
  // Kaynak bilgileri
  final String? sourceCreditCardId;
  final String? sourceDebitCardId;
  final String? sourceCashAccountId;
  
  // Hedef bilgileri
  final String? targetCreditCardId;
  final String? targetDebitCardId;
  final String? targetCashAccountId;
  
  // Transfer ücreti (opsiyonel)
  final double? transferFee;
  
  // Zaman bilgileri
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransferModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    this.notes,
    this.sourceCreditCardId,
    this.sourceDebitCardId,
    this.sourceCashAccountId,
    this.targetCreditCardId,
    this.targetDebitCardId,
    this.targetCashAccountId,
    this.transferFee,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Transfer tipini belirle
  TransferType get transferType {
    final hasSourceCard = sourceCreditCardId != null || sourceDebitCardId != null;
    final hasSourceCash = sourceCashAccountId != null;
    final hasTargetCard = targetCreditCardId != null || targetDebitCardId != null;
    final hasTargetCash = targetCashAccountId != null;

    if (hasSourceCard && hasTargetCard) {
      return TransferType.cardToCard;
    } else if (hasSourceCard && hasTargetCash) {
      return TransferType.cardToCash;
    } else if (hasSourceCash && hasTargetCard) {
      return TransferType.cashToCard;
    } else {
      return TransferType.cashToCash;
    }
  }

  // Kaynak kart ID'sini al
  String? get sourceCardId {
    return sourceCreditCardId ?? sourceDebitCardId ?? sourceCashAccountId;
  }

  // Hedef kart ID'sini al
  String? get targetCardId {
    return targetCreditCardId ?? targetDebitCardId ?? targetCashAccountId;
  }

  // Kaynak kart tipini al
  CardType? get sourceCardType {
    if (sourceCreditCardId != null) return CardType.credit;
    if (sourceDebitCardId != null) return CardType.debit;
    if (sourceCashAccountId != null) return CardType.cash;
    return null;
  }

  // Hedef kart tipini al
  CardType? get targetCardType {
    if (targetCreditCardId != null) return CardType.credit;
    if (targetDebitCardId != null) return CardType.debit;
    if (targetCashAccountId != null) return CardType.cash;
    return null;
  }

  // TransactionModel'den TransferModel oluştur
  factory TransferModel.fromTransactionModel(TransactionModel transaction) {
    if (transaction.type != TransactionType.transfer) {
      throw ArgumentError('Transaction must be of type transfer');
    }

    return TransferModel(
      id: transaction.id,
      userId: transaction.userId,
      amount: transaction.amount,
      description: transaction.description,
      notes: transaction.notes,
      sourceCreditCardId: transaction.creditCardId,
      sourceDebitCardId: transaction.debitCardId,
      sourceCashAccountId: transaction.cashAccountId,
      targetCreditCardId: transaction.targetCreditCardId,
      targetDebitCardId: transaction.targetDebitCardId,
      targetCashAccountId: transaction.targetCashAccountId,
      transactionDate: transaction.transactionDate,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
  }

  // TransactionModel'e dönüştür
  TransactionModel toTransactionModel() {
    return TransactionModel(
      id: id,
      userId: userId,
      type: TransactionType.transfer,
      amount: amount,
      description: description,
      category: 'transfer',
      creditCardId: sourceCreditCardId,
      debitCardId: sourceDebitCardId,
      cashAccountId: sourceCashAccountId,
      targetCreditCardId: targetCreditCardId,
      targetDebitCardId: targetDebitCardId,
      targetCashAccountId: targetCashAccountId,
      notes: notes,
      transactionDate: transactionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  TransferModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? description,
    String? notes,
    String? sourceCreditCardId,
    String? sourceDebitCardId,
    String? sourceCashAccountId,
    String? targetCreditCardId,
    String? targetDebitCardId,
    String? targetCashAccountId,
    double? transferFee,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      sourceCreditCardId: sourceCreditCardId ?? this.sourceCreditCardId,
      sourceDebitCardId: sourceDebitCardId ?? this.sourceDebitCardId,
      sourceCashAccountId: sourceCashAccountId ?? this.sourceCashAccountId,
      targetCreditCardId: targetCreditCardId ?? this.targetCreditCardId,
      targetDebitCardId: targetDebitCardId ?? this.targetDebitCardId,
      targetCashAccountId: targetCashAccountId ?? this.targetCashAccountId,
      transferFee: transferFee ?? this.transferFee,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': 'transfer',
      'amount': amount,
      'description': description,
      'category': 'transfer',
      'credit_card_id': sourceCreditCardId,
      'debit_card_id': sourceDebitCardId,
      'cash_account_id': sourceCashAccountId,
      'target_credit_card_id': targetCreditCardId,
      'target_debit_card_id': targetDebitCardId,
      'target_cash_account_id': targetCashAccountId,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      notes: json['notes'],
      sourceCreditCardId: json['credit_card_id'],
      sourceDebitCardId: json['debit_card_id'],
      sourceCashAccountId: json['cash_account_id'],
      targetCreditCardId: json['target_credit_card_id'],
      targetDebitCardId: json['target_debit_card_id'],
      targetCashAccountId: json['target_cash_account_id'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransferModel(id: $id, amount: $amount, transferType: $transferType, description: $description)';
  }
} 