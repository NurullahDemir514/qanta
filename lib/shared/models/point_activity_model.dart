/// Point activity types enum
/// Defines all activities that can earn points
enum PointActivity {
  /// Rewarded ad watched
  rewardedAd('rewardedAd', 50),
  
  /// Transaction added (expense or income)
  transaction('transaction', 15),
  
  /// Daily login (first login of the day)
  dailyLogin('dailyLogin', 25),
  
  /// Weekly streak (7 consecutive days)
  weeklyStreak('weeklyStreak', 1000),
  
  /// Monthly goal completed
  monthlyGoal('monthlyGoal', 50),
  
  /// Referral bonus (user invited someone)
  referral('referral', 500),
  
  /// Budget goal completed
  budgetGoal('budgetGoal', 15),
  
  /// Savings goal milestone (25%, 50%, 75%, 100%)
  savingsMilestone('savingsMilestone', 12),
  
  /// Premium subscription bonus
  premiumBonus('premiumBonus', 50),
  
  /// Special event bonus
  specialEvent('specialEvent', 25),
  
  /// First card added (debit or credit)
  firstCard('firstCard', 250),
  
  /// First budget created
  firstBudget('firstBudget', 250),
  
  /// First stock purchase
  firstStockPurchase('firstStockPurchase', 250),
  
  /// First subscription created
  firstSubscription('firstSubscription', 250),
  
  /// Point redemption (spending points)
  redemption('redemption', 0); // Negative points when spending

  const PointActivity(this.value, this.defaultPoints);
  final String value;
  final int defaultPoints;

  static PointActivity fromString(String value) {
    return PointActivity.values.firstWhere(
      (activity) => activity.value == value,
      orElse: () => PointActivity.transaction,
    );
  }

  /// Get localized name for activity
  String getDisplayName(String locale) {
    switch (this) {
      case PointActivity.rewardedAd:
        return locale == 'tr' ? 'Reklam İzleme' : 'Rewarded Ad';
      case PointActivity.transaction:
        return locale == 'tr' ? 'İşlem Ekleme' : 'Add Transaction';
      case PointActivity.dailyLogin:
        return locale == 'tr' ? 'Günlük Giriş' : 'Daily Login';
      case PointActivity.weeklyStreak:
        return locale == 'tr' ? 'Haftalık Seri' : 'Weekly Streak';
      case PointActivity.monthlyGoal:
        return locale == 'tr' ? 'Aylık Hedef' : 'Monthly Goal';
      case PointActivity.referral:
        return locale == 'tr' ? 'Referans' : 'Referral';
      case PointActivity.budgetGoal:
        return locale == 'tr' ? 'Bütçe Hedefi' : 'Budget Goal';
      case PointActivity.savingsMilestone:
        return locale == 'tr' ? 'Birikim Milestone' : 'Savings Milestone';
      case PointActivity.premiumBonus:
        return locale == 'tr' ? 'Premium Bonus' : 'Premium Bonus';
      case PointActivity.specialEvent:
        return locale == 'tr' ? 'Özel Etkinlik' : 'Special Event';
      case PointActivity.firstCard:
        return locale == 'tr' ? 'İlk Kart' : 'First Card';
      case PointActivity.firstBudget:
        return locale == 'tr' ? 'İlk Bütçe' : 'First Budget';
      case PointActivity.firstStockPurchase:
        return locale == 'tr' ? 'İlk Hisse Alımı' : 'First Stock Purchase';
      case PointActivity.firstSubscription:
        return locale == 'tr' ? 'İlk Abonelik' : 'First Subscription';
      case PointActivity.redemption:
        return locale == 'tr' ? 'Puan Harcama' : 'Point Redemption';
    }
  }
}

