import 'package:flutter/material.dart';
import 'card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/cash_account.dart';

enum PaymentMethodType {
  cash,
  card,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case PaymentMethodType.cash:
        return l10n.cash;
      case PaymentMethodType.card:
        return l10n.card;
    }
  }

  String get name {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Nakit';
      case PaymentMethodType.card:
        return 'Kart';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.cash:
        return Icons.payments_rounded;
      case PaymentMethodType.card:
        return Icons.credit_card_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethodType.cash:
        return const Color(0xFF34C759);
      case PaymentMethodType.card:
        return const Color(0xFF007AFF);
    }
  }
}

class PaymentMethod {
  final PaymentMethodType type;
  final PaymentCard? card;
  final CashAccount? cashAccount;
  final int? installments; // null = peşin, 1 = peşin, 2+ = taksit

  const PaymentMethod({
    required this.type,
    this.card,
    this.cashAccount,
    this.installments,
  });

  bool get isCash => type == PaymentMethodType.cash;
  bool get isCard => type == PaymentMethodType.card;
  bool get isInstallment => installments != null && installments! > 1;

  String getDisplayName(AppLocalizations l10n) {
    if (isCash) {
      return cashAccount?.name ?? l10n.cash;
    }
    if (card != null) {
      final installmentText = isInstallment 
        ? ' (${l10n.installments(installments!)})'
        : ' (${l10n.cashPayment})';
      return '${card!.name}$installmentText';
    }
    return l10n.card;
  }

  String getIncomeDisplayName(AppLocalizations l10n) {
    if (isCash) {
      return cashAccount?.name ?? l10n.cash;
    }
    if (card != null) {
      return card!.name; // No installment info for income
    }
    return l10n.card;
  }

  String get displayName {
    if (isCash) {
      return cashAccount?.name ?? 'Nakit';
    }
    if (card != null) {
      final installmentText = isInstallment ? ' ($installments Taksit)' : ' (Peşin)';
      return '${card!.name}$installmentText';
    }
    return 'Kart';
  }

  PaymentMethod copyWith({
    PaymentMethodType? type,
    PaymentCard? card,
    CashAccount? cashAccount,
    int? installments,
  }) {
    return PaymentMethod(
      type: type ?? this.type,
      card: card ?? this.card,
      cashAccount: cashAccount ?? this.cashAccount,
      installments: installments ?? this.installments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'card': card?.toJson(),
      'cashAccount': cashAccount?.toJson(),
      'installments': installments,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: PaymentMethodType.values.firstWhere((e) => e.name == json['type']),
      card: json['card'] != null ? PaymentCard.fromJson(json['card']) : null,
      cashAccount: json['cashAccount'] != null ? CashAccount.fromJson(json['cashAccount']) : null,
      installments: json['installments'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod &&
        other.type == type &&
        other.card == card &&
        other.cashAccount == cashAccount &&
        other.installments == installments;
  }

  @override
  int get hashCode => Object.hash(type, card, cashAccount, installments);

  @override
  String toString() {
    return 'PaymentMethod(type: $type, card: $card, cashAccount: $cashAccount, installments: $installments)';
  }
} 