import 'package:flutter/material.dart';

/// Tutorial step position - Tooltip nerede görünsün
enum TutorialPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// Tutorial Step Model
/// Tutorial adım veri modeli
class TutorialStep {
  /// Unique step identifier
  final String id;
  
  /// Target widget key (hangi widget vurgulanacak)
  final GlobalKey targetKey;
  
  /// Title localization key
  final String titleKey;
  
  /// Description localization key
  final String descriptionKey;
  
  /// Tooltip position
  final TutorialPosition position;
  
  /// Icon (opsiyonel)
  final IconData? icon;
  
  /// Callback - Adım tamamlandığında çalışır
  final VoidCallback? onStepCompleted;
  
  /// Additional data (opsiyonel)
  final Map<String, dynamic>? metadata;

  TutorialStep({
    required this.id,
    required this.targetKey,
    required this.titleKey,
    required this.descriptionKey,
    this.position = TutorialPosition.bottom,
    this.icon,
    this.onStepCompleted,
    this.metadata,
  });

  /// Create FAB tutorial step (ikinci adım)
  factory TutorialStep.fab({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'fab_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialTitle',
      descriptionKey: 'tutorialDescription',
      position: TutorialPosition.top,
      icon: Icons.add_circle_outline,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Balance Overview tutorial step (ilk adım - Total Assets)
  factory TutorialStep.balanceOverview({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'balance_overview_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialBalanceOverviewTitle',
      descriptionKey: 'tutorialBalanceOverviewDescription',
      position: TutorialPosition.bottom,
      icon: Icons.account_balance_wallet,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Recent Transactions tutorial step (üçüncü adım)
  factory TutorialStep.recentTransactions({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'recent_transactions_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialRecentTransactionsTitle',
      descriptionKey: 'tutorialRecentTransactionsDescription',
      position: TutorialPosition.bottom,
      icon: Icons.receipt_long,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create AI Chat tutorial step (dördüncü adım)
  factory TutorialStep.aiChat({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'ai_chat_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialAIChatTitle',
      descriptionKey: 'tutorialAIChatDescription',
      position: TutorialPosition.top,
      icon: Icons.auto_awesome,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Cards Section tutorial step
  factory TutorialStep.cardsSection({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'cards_section_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialCardsTitle',
      descriptionKey: 'tutorialCardsDescription',
      position: TutorialPosition.bottom,
      icon: Icons.credit_card,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Bottom Navigation Bar tutorial step
  factory TutorialStep.bottomNavigation({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'bottom_navigation_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialBottomNavigationTitle',
      descriptionKey: 'tutorialBottomNavigationDescription',
      position: TutorialPosition.top,
      icon: Icons.navigation,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Budget Overview tutorial step
  factory TutorialStep.budgetOverview({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'budget_overview_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialBudgetTitle',
      descriptionKey: 'tutorialBudgetDescription',
      position: TutorialPosition.bottom,
      icon: Icons.account_balance_wallet,
      onStepCompleted: onStepCompleted,
    );
  }

  /// Create Profile Avatar tutorial step
  factory TutorialStep.profileAvatar({
    required GlobalKey targetKey,
    VoidCallback? onStepCompleted,
  }) {
    return TutorialStep(
      id: 'profile_avatar_tutorial',
      targetKey: targetKey,
      titleKey: 'tutorialProfileTitle',
      descriptionKey: 'tutorialProfileDescription',
      position: TutorialPosition.bottom,
      icon: Icons.person,
      onStepCompleted: onStepCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TutorialStep && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

