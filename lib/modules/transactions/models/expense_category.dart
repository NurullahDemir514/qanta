import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  travel,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case ExpenseCategory.food:
        return l10n.food;
      case ExpenseCategory.transport:
        return l10n.transport;
      case ExpenseCategory.shopping:
        return l10n.shopping;
      case ExpenseCategory.bills:
        return l10n.bills;
      case ExpenseCategory.entertainment:
        return l10n.entertainment;
      case ExpenseCategory.health:
        return l10n.health;
      case ExpenseCategory.education:
        return l10n.education;
      case ExpenseCategory.travel:
        return l10n.travel;
      case ExpenseCategory.other:
        return l10n.other;
    }
  }

  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case ExpenseCategory.food:
        return l10n.foodDescription;
      case ExpenseCategory.transport:
        return l10n.transportDescription;
      case ExpenseCategory.shopping:
        return l10n.shoppingDescription;
      case ExpenseCategory.bills:
        return l10n.billsDescription;
      case ExpenseCategory.entertainment:
        return l10n.entertainmentDescription;
      case ExpenseCategory.health:
        return l10n.healthDescription;
      case ExpenseCategory.education:
        return l10n.educationDescription;
      case ExpenseCategory.travel:
        return l10n.travelDescription;
      case ExpenseCategory.other:
        return l10n.otherDescription;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.entertainment:
        return Icons.movie_outlined;
      case ExpenseCategory.health:
        return Icons.local_hospital_outlined;
      case ExpenseCategory.education:
        return Icons.school_outlined;
      case ExpenseCategory.travel:
        return Icons.flight_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.transport:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.shopping:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.bills:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.entertainment:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.health:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.education:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.travel:
        return const Color(0xFF8E8E93);
      case ExpenseCategory.other:
        return const Color(0xFF8E8E93);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.transport:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.shopping:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.bills:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.entertainment:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.health:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.education:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.travel:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case ExpenseCategory.other:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
    }
  }
} 