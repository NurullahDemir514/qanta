import 'package:flutter/material.dart';

enum CardType {
  credit,
  debit,
  cash,
}

enum TransactionType {
  purchase,
  withdrawal,
  online,
  transfer,
  cashAddition,
}

class PaymentCardModel {
  final String id;
  final CardType cardType;
  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final String? accountType; // Vadesiz, Maaş Hesabı vs. (sadece banka kartı için)
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;
  final double? balance; // Banka kartı için
  final double? creditLimit; // Kredi kartı için
  final double? usedCredit; // Kredi kartı için

  const PaymentCardModel({
    required this.id,
    required this.cardType,
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    this.accountType,
    required this.primaryColor,
    required this.secondaryColor,
    this.isActive = true,
    this.balance,
    this.creditLimit,
    this.usedCredit,
  });

  // Kullanılabilir limit (kredi kartı için)
  double? get availableCredit {
    if (cardType != CardType.credit || creditLimit == null || usedCredit == null) {
      return null;
    }
    return creditLimit! - usedCredit!;
  }

  // Kart görüntü adı
  String get displayName {
    switch (cardType) {
      case CardType.credit:
        return '$bankName $cardName';
      case CardType.debit:
        return '$bankName ${accountType ?? 'Debit Card'}';
      case CardType.cash:
        return 'Nakit';
    }
  }

  // Kart alt bilgisi
  String get subtitle {
    switch (cardType) {
      case CardType.credit:
        return '**** $lastFourDigits';
      case CardType.debit:
        return '**** $lastFourDigits';
      case CardType.cash:
        return 'Cebinizdeki nakit';
    }
  }

  PaymentCardModel copyWith({
    String? id,
    CardType? cardType,
    String? bankName,
    String? cardName,
    String? lastFourDigits,
    String? accountType,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isActive,
    double? balance,
    double? creditLimit,
    double? usedCredit,
  }) {
    return PaymentCardModel(
      id: id ?? this.id,
      cardType: cardType ?? this.cardType,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      accountType: accountType ?? this.accountType,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      usedCredit: usedCredit ?? this.usedCredit,
    );
  }
}

class CardTransactionModel {
  final String id;
  final PaymentCardModel card;
  final TransactionType transactionType;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final int? installmentCount; // Toplam taksit sayısı (kredi kartı için)
  final int? currentInstallment; // Kaçıncı taksit (kredi kartı için)
  final String? merchantName; // İşyeri adı
  final String? location; // İşlem yeri
  final bool isIncome;

  const CardTransactionModel({
    required this.id,
    required this.card,
    required this.transactionType,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    this.installmentCount,
    this.currentInstallment,
    this.merchantName,
    this.location,
    this.isIncome = false,
  });

  // Taksit bilgisi string'i
  String? get installmentInfo {
    if (installmentCount == null || currentInstallment == null) {
      return null;
    }
    if (installmentCount == 1) {
      return 'Peşin';
    }
    return '$currentInstallment/$installmentCount Taksit';
  }

  // İşlem türü açıklaması
  String get transactionTypeDescription {
    switch (transactionType) {
      case TransactionType.purchase:
        return card.cardType == CardType.credit ? 'Kredi Kartı Alışverişi' : 'Banka Kartı Alışverişi';
      case TransactionType.withdrawal:
        return 'ATM Nakit Çekim';
      case TransactionType.online:
        return 'Online İşlem';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.cashAddition:
        return 'Nakit Ekleme';
    }
  }

  // Detaylı açıklama
  String get detailedDescription {
    final parts = <String>[];
    
    // Temel açıklama
    parts.add(description);
    
    // Taksit bilgisi
    if (installmentInfo != null) {
      parts.add(installmentInfo!);
    }
    
    // Lokasyon
    if (location != null) {
      parts.add(location!);
    }
    
    return parts.join(' • ');
  }

  // İşlem ikonu
  IconData get transactionIcon {
    switch (transactionType) {
      case TransactionType.purchase:
        return Icons.shopping_cart_outlined;
      case TransactionType.withdrawal:
        return Icons.atm_outlined;
      case TransactionType.online:
        return Icons.language_outlined;
      case TransactionType.transfer:
        return Icons.swap_horiz_outlined;
      case TransactionType.cashAddition:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // İşlem rengi
  Color get transactionColor {
    if (isIncome || amount > 0) {
      return const Color(0xFF34C759); // Yeşil - Gelir
    } else {
      return const Color(0xFFFF3B30); // Kırmızı - Gider
    }
  }

  CardTransactionModel copyWith({
    String? id,
    PaymentCardModel? card,
    TransactionType? transactionType,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    int? installmentCount,
    int? currentInstallment,
    String? merchantName,
    String? location,
    bool? isIncome,
  }) {
    return CardTransactionModel(
      id: id ?? this.id,
      card: card ?? this.card,
      transactionType: transactionType ?? this.transactionType,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      installmentCount: installmentCount ?? this.installmentCount,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      merchantName: merchantName ?? this.merchantName,
      location: location ?? this.location,
      isIncome: isIncome ?? this.isIncome,
    );
  }
} 