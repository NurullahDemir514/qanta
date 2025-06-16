import 'package:flutter/material.dart';
import '../../../shared/models/account_model.dart';

enum CardType {
  credit,
  debit,
}

extension CardTypeExtension on CardType {
  String get name {
    switch (this) {
      case CardType.credit:
        return 'Kredi Kartı';
      case CardType.debit:
        return 'Banka Kartı';
    }
  }

  IconData get icon {
    switch (this) {
      case CardType.credit:
        return Icons.credit_card_rounded;
      case CardType.debit:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CardType.credit:
        return const Color(0xFFFF9500);
      case CardType.debit:
        return const Color(0xFF007AFF);
    }
  }
}

class PaymentCard {
  final String id;
  final String name;
  final String number;
  final String expiryDate;
  final String lastFourDigits;
  final CardType type;
  final String bankName;
  final Color color;
  final bool isActive;

  PaymentCard({
    required this.id,
    required this.name,
    required this.number,
    required this.expiryDate,
    required this.type,
    required this.bankName,
    required this.color,
    this.isActive = true,
  }) : lastFourDigits = number.length >= 4 ? number.substring(number.length - 4) : number;

  /// Create PaymentCard from AccountModel
  factory PaymentCard.fromAccount(AccountModel account) {
    // Determine card type from account type
    CardType cardType;
    Color cardColor;
    
    switch (account.type) {
      case AccountType.credit:
        cardType = CardType.credit;
        cardColor = const Color(0xFFFF3B30); // Red for credit cards
        break;
      case AccountType.debit:
        cardType = CardType.debit;
        cardColor = const Color(0xFF007AFF); // Blue for debit cards
        break;
      case AccountType.cash:
        // Cash accounts shouldn't be converted to PaymentCard
        throw ArgumentError('Cash accounts cannot be converted to PaymentCard');
    }

    return PaymentCard(
      id: account.id,
      name: account.name,
      number: '**** **** **** ****', // Placeholder since AccountModel doesn't store card number
      expiryDate: '', // Placeholder since AccountModel doesn't store expiry
      type: cardType,
      bankName: account.bankName ?? '',
      color: cardColor,
      isActive: account.isActive,
    );
  }

  PaymentCard copyWith({
    String? id,
    String? name,
    String? number,
    String? expiryDate,
    CardType? type,
    String? bankName,
    Color? color,
    bool? isActive,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      expiryDate: expiryDate ?? this.expiryDate,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'expiryDate': expiryDate,
      'type': type.name,
      'bankName': bankName,
      'color': color.value,
      'isActive': isActive,
    };
  }

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      expiryDate: json['expiryDate'] ?? '',
      type: CardType.values.firstWhere((e) => e.name == json['type']),
      bankName: json['bankName'],
      color: Color(json['color']),
      isActive: json['isActive'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentCard(id: $id, name: $name, type: $type, bankName: $bankName)';
  }
} 