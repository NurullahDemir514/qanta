import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/services/amazon_reward_service.dart';
import '../../../shared/models/amazon_reward_credit_model.dart';
import '../../../shared/models/point_transaction_model.dart';
import '../../../shared/models/point_activity_model.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/amazon_reward_provider.dart';
import '../providers/point_provider.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

/// Reward History Page
/// Shows list of all credits earned by user
class AmazonRewardHistoryPage extends StatefulWidget {
  const AmazonRewardHistoryPage({super.key});

  @override
  State<AmazonRewardHistoryPage> createState() =>
      _AmazonRewardHistoryPageState();
}

class _AmazonRewardHistoryPageState extends State<AmazonRewardHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Ensure providers are initialized and load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final amazonProvider = Provider.of<AmazonRewardProvider>(context, listen: false);
      final pointProvider = Provider.of<PointProvider>(context, listen: false);
      
      if (!amazonProvider.isEligible) {
        await amazonProvider.initialize();
      }
      // Always load credits to ensure fresh data
      await amazonProvider.loadCredits();
      
      // Load point transactions
      if (!pointProvider.isInitialized) {
        await pointProvider.initialize();
      } else {
        await pointProvider.loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Ödül Geçmişi',
      onRefresh: () async {
        final amazonProvider = Provider.of<AmazonRewardProvider>(context, listen: false);
        final pointProvider = Provider.of<PointProvider>(context, listen: false);
        await Future.wait([
          amazonProvider.refresh(),
          pointProvider.refresh(),
        ]);
      },
      body: Consumer2<AmazonRewardProvider, PointProvider>(
        builder: (context, amazonProvider, pointProvider, child) {
          if (amazonProvider.isLoading || pointProvider.isLoading) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final credits = amazonProvider.credits;
          final pointTransactions = pointProvider.transactions
              .where((t) => t.isEarning && t.activity != PointActivity.redemption)
              .toList();

          // Combine and sort all activities
          final allActivities = <_ActivityItem>[];
          
          // Add Amazon reward credits
          for (var credit in credits) {
            allActivities.add(_ActivityItem(
              type: _ActivityType.amazonReward,
              amazonCredit: credit,
              pointTransaction: null,
              earnedAt: credit.earnedAt,
            ));
          }
          
          // Add point transactions (excluding rewardedAd and transaction as they're already in Amazon credits)
          for (var transaction in pointTransactions) {
            if (transaction.activity != PointActivity.rewardedAd && 
                transaction.activity != PointActivity.transaction) {
              allActivities.add(_ActivityItem(
                type: _ActivityType.pointTransaction,
                amazonCredit: null,
                pointTransaction: transaction,
                earnedAt: transaction.earnedAt,
              ));
            }
          }
          
          // Sort by date (most recent first)
          allActivities.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));

          if (allActivities.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz ödül kazanmadınız',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reklam izleyin veya harcama ekleyin',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildTimelineView(context, isDark, allActivities);
        },
      ),
    );
  }

  Widget _buildTimelineView(
    BuildContext context,
    bool isDark,
    List<_ActivityItem> activities,
  ) {
    // Group activities by date
    final Map<String, List<_ActivityItem>> groupedActivities = {};
    
    for (var activity in activities) {
      final dateKey = _getDateKey(activity.earnedAt);
      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }
      groupedActivities[dateKey]!.add(activity);
    }

    final sortedKeys = groupedActivities.keys.toList()
      ..sort((a, b) {
        // Sort by date (most recent first)
        final dateA = _parseDateKey(a);
        final dateB = _parseDateKey(b);
        return dateB.compareTo(dateA);
      });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= sortedKeys.length) return null;
          
          final dateKey = sortedKeys[index];
          final dayActivities = groupedActivities[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _getDateHeader(dateKey),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
              // Timeline items
              ...dayActivities.asMap().entries.map((entry) {
                final activityIndex = entry.key;
                final activity = entry.value;
                final isLast = activityIndex == dayActivities.length - 1;
                return _buildTimelineItem(
                  context,
                  activity,
                  isDark,
                  isLast,
                );
              }),
            ],
          );
        },
        childCount: sortedKeys.length,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    _ActivityItem activity,
    bool isDark,
    bool isLast,
  ) {
    final timeFormat = DateFormat('HH:mm', 'tr_TR');
    
    String title;
    IconData icon;
    int points;
    Color iconColor;
    
    if (activity.type == _ActivityType.amazonReward) {
      final credit = activity.amazonCredit!;
      title = credit.source == RewardSource.rewardedAd
          ? 'Reklam İzleme'
          : 'Harcama Ekleme';
      icon = credit.source == RewardSource.rewardedAd
          ? Icons.play_circle_outline
          : Icons.add_circle_outline;
      points = credit.source == RewardSource.rewardedAd ? 50 : 15;
      iconColor = const Color(0xFFFF9900);
    } else {
      final transaction = activity.pointTransaction!;
      title = transaction.description ?? transaction.activity.getDisplayName('tr');
      icon = _getActivityIcon(transaction.activity);
      points = transaction.points;
      iconColor = Colors.green[700]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: iconColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '+${NumberFormat('#,###').format(points)} puan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(activity.earnedAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(PointActivity activity) {
    switch (activity) {
      case PointActivity.dailyLogin:
        return Icons.login;
      case PointActivity.weeklyStreak:
        return Icons.local_fire_department;
      case PointActivity.monthlyGoal:
        return Icons.flag;
      case PointActivity.referral:
        return Icons.person_add;
      case PointActivity.budgetGoal:
        return Icons.account_balance_wallet;
      case PointActivity.savingsMilestone:
        return Icons.savings;
      case PointActivity.premiumBonus:
        return Icons.star;
      case PointActivity.specialEvent:
        return Icons.celebration;
      case PointActivity.firstCard:
        return Icons.credit_card;
      case PointActivity.firstBudget:
        return Icons.account_balance;
      case PointActivity.firstStockPurchase:
        return Icons.trending_up;
      case PointActivity.firstSubscription:
        return Icons.subscriptions;
      default:
        return Icons.stars;
    }
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'today';
    } else if (transactionDate == yesterday) {
      return 'yesterday';
    } else {
      return DateFormat('yyyy-MM-dd').format(transactionDate);
    }
  }

  String _getDateHeader(String dateKey) {
    if (dateKey == 'today') {
      return 'Bugün';
    } else if (dateKey == 'yesterday') {
      return 'Dün';
    } else {
      final date = _parseDateKey(dateKey);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      if (date.isAfter(weekAgo)) {
        // This week
        return DateFormat('EEEE, d MMMM', 'tr_TR').format(date);
      } else {
        return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
      }
    }
  }

  DateTime _parseDateKey(String dateKey) {
    if (dateKey == 'today') {
      return DateTime.now();
    } else if (dateKey == 'yesterday') {
      return DateTime.now().subtract(const Duration(days: 1));
    } else {
      return DateFormat('yyyy-MM-dd').parse(dateKey);
    }
  }
}

/// Activity item wrapper to combine Amazon credits and point transactions
class _ActivityItem {
  final _ActivityType type;
  final AmazonRewardCredit? amazonCredit;
  final PointTransaction? pointTransaction;
  final DateTime earnedAt;

  _ActivityItem({
    required this.type,
    this.amazonCredit,
    this.pointTransaction,
    required this.earnedAt,
  });
}

enum _ActivityType {
  amazonReward,
  pointTransaction,
}

