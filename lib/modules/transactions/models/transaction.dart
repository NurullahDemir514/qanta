import 'package:flutter/material.dart';
import '../../../shared/models/transaction_model.dart';
import 'payment_method.dart';
import '../../../l10n/app_localizations.dart';

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  other,
}

enum IncomeCategory {
  salary,
  freelance,
  business,
  investment,
  rental,
  bonus,
  gift,
  other,
}

extension TransactionCategoryExtension on TransactionCategory {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case TransactionCategory.food:
        return l10n.foodAndDrink;
      case TransactionCategory.transport:
        return l10n.transport;
      case TransactionCategory.shopping:
        return l10n.shopping;
      case TransactionCategory.entertainment:
        return l10n.entertainment;
      case TransactionCategory.bills:
        return l10n.bills;
      case TransactionCategory.health:
        return l10n.health;
      case TransactionCategory.education:
        return l10n.education;
      case TransactionCategory.other:
        return l10n.other;
    }
  }

  String get name {
    switch (this) {
      case TransactionCategory.food:
        return 'Yemek & İçecek';
      case TransactionCategory.transport:
        return 'Ulaşım';
      case TransactionCategory.shopping:
        return 'Alışveriş';
      case TransactionCategory.entertainment:
        return 'Eğlence';
      case TransactionCategory.bills:
        return 'Faturalar';
      case TransactionCategory.health:
        return 'Sağlık';
      case TransactionCategory.education:
        return 'Eğitim';
      case TransactionCategory.other:
        return 'Diğer';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.food:
        return Icons.restaurant_outlined;
      case TransactionCategory.transport:
        return Icons.directions_car_outlined;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.entertainment:
        return Icons.movie_outlined;
      case TransactionCategory.bills:
        return Icons.receipt_long_outlined;
      case TransactionCategory.health:
        return Icons.local_hospital_outlined;
      case TransactionCategory.education:
        return Icons.school_outlined;
      case TransactionCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.food:
        return const Color(0xFFFF6B6B);
      case TransactionCategory.transport:
        return const Color(0xFF4ECDC4);
      case TransactionCategory.shopping:
        return const Color(0xFFFFE66D);
      case TransactionCategory.entertainment:
        return const Color(0xFFFF8B94);
      case TransactionCategory.bills:
        return const Color(0xFF95E1D3);
      case TransactionCategory.health:
        return const Color(0xFFA8E6CF);
      case TransactionCategory.education:
        return const Color(0xFFFFD93D);
      case TransactionCategory.other:
        return const Color(0xFFB4A7D6);
    }
  }
}

extension IncomeCategoryExtension on IncomeCategory {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case IncomeCategory.salary:
        return l10n.salary;
      case IncomeCategory.freelance:
        return l10n.freelance;
      case IncomeCategory.business:
        return l10n.business;
      case IncomeCategory.investment:
        return l10n.investment;
      case IncomeCategory.rental:
        return l10n.rental;
      case IncomeCategory.bonus:
        return l10n.bonus;
      case IncomeCategory.gift:
        return l10n.gift;
      case IncomeCategory.other:
        return l10n.otherIncome;
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeCategory.salary:
        return Icons.work_outlined;
      case IncomeCategory.freelance:
        return Icons.laptop_outlined;
      case IncomeCategory.business:
        return Icons.business_outlined;
      case IncomeCategory.investment:
        return Icons.trending_up_outlined;
      case IncomeCategory.rental:
        return Icons.home_outlined;
      case IncomeCategory.bonus:
        return Icons.card_giftcard_outlined;
      case IncomeCategory.gift:
        return Icons.redeem_outlined;
      case IncomeCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.salary:
        return const Color(0xFF34C759);
      case IncomeCategory.freelance:
        return const Color(0xFF007AFF);
      case IncomeCategory.business:
        return const Color(0xFF8B5CF6);
      case IncomeCategory.investment:
        return const Color(0xFFFF9500);
      case IncomeCategory.rental:
        return const Color(0xFF10B981);
      case IncomeCategory.bonus:
        return const Color(0xFFFF3B30);
      case IncomeCategory.gift:
        return const Color(0xFFFF2D92);
      case IncomeCategory.other:
        return const Color(0xFF6B7280);
    }
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final TransactionCategory category;
  final String description;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? accountId;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.paymentMethod,
    this.accountId,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    TransactionCategory? category,
    String? description,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? accountId,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'category': category.name,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.toJson(),
      'accountId': accountId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      amount: json['amount'].toDouble(),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      description: json['description'],
      date: DateTime.parse(json['date']),
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod']),
      accountId: json['accountId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, category: $category, description: $description, date: $date, paymentMethod: $paymentMethod)';
  }
} 