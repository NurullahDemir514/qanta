import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

enum RecurringFrequency {
  weekly,
  monthly,
  quarterly,
  yearly,
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case RecurringFrequency.weekly:
        return l10n.weekly;
      case RecurringFrequency.monthly:
        return l10n.monthly;
      case RecurringFrequency.quarterly:
        return l10n.quarterly;
      case RecurringFrequency.yearly:
        return l10n.yearly;
    }
  }

  /// getDisplayName - getName ile aynı, ama daha açıklayıcı isim
  String getDisplayName(AppLocalizations l10n) {
    return getName(l10n);
  }

  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case RecurringFrequency.weekly:
        return l10n.weeklyDescription;
      case RecurringFrequency.monthly:
        return l10n.monthlyDescription;
      case RecurringFrequency.quarterly:
        return l10n.quarterlyDescription;
      case RecurringFrequency.yearly:
        return l10n.yearlyDescription;
    }
  }

  String get name {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'Haftalık';
      case RecurringFrequency.monthly:
        return 'Aylık';
      case RecurringFrequency.quarterly:
        return '3 Aylık';
      case RecurringFrequency.yearly:
        return 'Yıllık';
    }
  }

  String get description {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'Her hafta tekrarlanır';
      case RecurringFrequency.monthly:
        return 'Her ay tekrarlanır';
      case RecurringFrequency.quarterly:
        return 'Her 3 ayda bir tekrarlanır';
      case RecurringFrequency.yearly:
        return 'Her yıl tekrarlanır';
    }
  }

  IconData get icon {
    switch (this) {
      case RecurringFrequency.weekly:
        return Icons.calendar_view_week_outlined;
      case RecurringFrequency.monthly:
        return Icons.calendar_view_month_outlined;
      case RecurringFrequency.quarterly:
        return Icons.calendar_today_outlined;
      case RecurringFrequency.yearly:
        return Icons.event_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RecurringFrequency.weekly:
        return const Color(0xFF8E8E93);
      case RecurringFrequency.monthly:
        return const Color(0xFF8E8E93);
      case RecurringFrequency.quarterly:
        return const Color(0xFF8E8E93);
      case RecurringFrequency.yearly:
        return const Color(0xFF8E8E93);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RecurringFrequency.weekly:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringFrequency.monthly:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringFrequency.quarterly:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringFrequency.yearly:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
    }
  }

  int get daysBetween {
    switch (this) {
      case RecurringFrequency.weekly:
        return 7;
      case RecurringFrequency.monthly:
        return 30;
      case RecurringFrequency.quarterly:
        return 90;
      case RecurringFrequency.yearly:
        return 365;
    }
  }
}

enum RecurringCategory {
  subscription,
  utilities,
  insurance,
  rent,
  loan,
  other,
}

extension RecurringCategoryExtension on RecurringCategory {
  String getName(AppLocalizations l10n) {
    switch (this) {
      case RecurringCategory.subscription:
        return l10n.subscription;
      case RecurringCategory.utilities:
        return l10n.utilities;
      case RecurringCategory.insurance:
        return l10n.insurance;
      case RecurringCategory.rent:
        return l10n.rent;
      case RecurringCategory.loan:
        return l10n.loan;
      case RecurringCategory.other:
        return l10n.other;
    }
  }

  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case RecurringCategory.subscription:
        return l10n.subscriptionDescription;
      case RecurringCategory.utilities:
        return l10n.utilitiesDescription;
      case RecurringCategory.insurance:
        return l10n.insuranceDescription;
      case RecurringCategory.rent:
        return l10n.rentDescription;
      case RecurringCategory.loan:
        return l10n.loanDescription;
      case RecurringCategory.other:
        return l10n.otherDescription;
    }
  }

  String get name {
    switch (this) {
      case RecurringCategory.subscription:
        return 'Abonelik';
      case RecurringCategory.utilities:
        return 'Faturalar';
      case RecurringCategory.insurance:
        return 'Sigorta';
      case RecurringCategory.rent:
        return 'Kira';
      case RecurringCategory.loan:
        return 'Kredi/Taksit';
      case RecurringCategory.other:
        return 'Diğer';
    }
  }

  String get description {
    switch (this) {
      case RecurringCategory.subscription:
        return 'Netflix, Spotify, YouTube';
      case RecurringCategory.utilities:
        return 'Elektrik, su, doğalgaz';
      case RecurringCategory.insurance:
        return 'Sağlık, kasko, dask';
      case RecurringCategory.rent:
        return 'Ev kirası, ofis kirası';
      case RecurringCategory.loan:
        return 'Kredi kartı, taksit';
      case RecurringCategory.other:
        return 'Diğer sabit ödemeler';
    }
  }

  IconData get icon {
    switch (this) {
      case RecurringCategory.subscription:
        return Icons.subscriptions_outlined;
      case RecurringCategory.utilities:
        return Icons.receipt_long_outlined;
      case RecurringCategory.insurance:
        return Icons.security_outlined;
      case RecurringCategory.rent:
        return Icons.home_outlined;
      case RecurringCategory.loan:
        return Icons.credit_card_outlined;
      case RecurringCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RecurringCategory.subscription:
        return const Color(0xFF8E8E93);
      case RecurringCategory.utilities:
        return const Color(0xFF8E8E93);
      case RecurringCategory.insurance:
        return const Color(0xFF8E8E93);
      case RecurringCategory.rent:
        return const Color(0xFF8E8E93);
      case RecurringCategory.loan:
        return const Color(0xFF8E8E93);
      case RecurringCategory.other:
        return const Color(0xFF8E8E93);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RecurringCategory.subscription:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringCategory.utilities:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringCategory.insurance:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringCategory.rent:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringCategory.loan:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
      case RecurringCategory.other:
        return const Color(0xFF8E8E93).withValues(alpha: 0.1);
    }
  }
} 