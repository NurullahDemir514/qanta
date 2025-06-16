import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

enum IncomeCategory {
  salary,
  bonus,
  freelance,
  business,
  investment,
  rental,
  gift,
  other,
}

extension IncomeCategoryExtension on IncomeCategory {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case IncomeCategory.salary:
        return l10n.salary;
      case IncomeCategory.bonus:
        return l10n.bonus;
      case IncomeCategory.freelance:
        return l10n.freelance;
      case IncomeCategory.business:
        return l10n.business;
      case IncomeCategory.investment:
        return l10n.investmentIncome;
      case IncomeCategory.rental:
        return l10n.rental;
      case IncomeCategory.gift:
        return l10n.gift;
      case IncomeCategory.other:
        return l10n.other;
    }
  }

  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case IncomeCategory.salary:
        return l10n.salaryDescription;
      case IncomeCategory.bonus:
        return l10n.bonusDescription;
      case IncomeCategory.freelance:
        return l10n.freelanceDescription;
      case IncomeCategory.business:
        return l10n.businessDescription;
      case IncomeCategory.investment:
        return l10n.investmentDescription;
      case IncomeCategory.rental:
        return l10n.rentalDescription;
      case IncomeCategory.gift:
        return l10n.giftDescription;
      case IncomeCategory.other:
        return l10n.otherDescription;
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeCategory.salary:
        return Icons.work_outlined;
      case IncomeCategory.bonus:
        return Icons.star_outlined;
      case IncomeCategory.freelance:
        return Icons.laptop_outlined;
      case IncomeCategory.business:
        return Icons.business_outlined;
      case IncomeCategory.investment:
        return Icons.trending_up_outlined;
      case IncomeCategory.rental:
        return Icons.home_outlined;
      case IncomeCategory.gift:
        return Icons.card_giftcard_outlined;
      case IncomeCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.salary:
        return const Color(0xFF8E8E93);
      case IncomeCategory.bonus:
        return const Color(0xFF8E8E93);
      case IncomeCategory.freelance:
        return const Color(0xFF8E8E93);
      case IncomeCategory.business:
        return const Color(0xFF8E8E93);
      case IncomeCategory.investment:
        return const Color(0xFF8E8E93);
      case IncomeCategory.rental:
        return const Color(0xFF8E8E93);
      case IncomeCategory.gift:
        return const Color(0xFF8E8E93);
      case IncomeCategory.other:
        return const Color(0xFF8E8E93);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case IncomeCategory.salary:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.bonus:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.freelance:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.business:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.investment:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.rental:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.gift:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case IncomeCategory.other:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
    }
  }
} 