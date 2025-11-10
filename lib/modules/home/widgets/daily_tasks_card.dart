import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/services/point_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../shared/models/point_balance_model.dart';
import '../../../shared/models/point_activity_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/providers/point_provider.dart';

/// Daily Tasks Card Widget
/// Shows daily tasks and points that can be earned
/// Only visible for Turkish users
class DailyTasksCard extends StatefulWidget {
  const DailyTasksCard({super.key});

  @override
  State<DailyTasksCard> createState() => _DailyTasksCardState();
}

class _DailyTasksCardState extends State<DailyTasksCard> {
  bool _isTurkishUser = false;
  bool _isCheckingCountry = true;
  bool _isDismissed = false;
  static const String _dismissedDateKey = 'daily_tasks_card_dismissed_date';

  @override
  void initState() {
    super.initState();
    _checkIfTurkishUser();
    _checkIfDismissed();
  }

  Future<void> _checkIfDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(_dismissedDateKey) ?? false;
      
      if (isDismissed) {
        // Uygulama açıldığında flag'i reset et (bir sonraki açılışta tekrar görünsün)
        await prefs.setBool(_dismissedDateKey, false);
        // Bu açılışta göster
        if (mounted) {
          setState(() {
            _isDismissed = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isDismissed = false;
          });
        }
      }
    } catch (e) {
      // Hata durumunda göster
      if (mounted) {
        setState(() {
          _isDismissed = false;
        });
      }
    }
  }

  Future<void> _dismissCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Kapatıldı olarak işaretle (bir sonraki uygulama açılışına kadar gizli kalacak)
      await prefs.setBool(_dismissedDateKey, true);
      
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _checkIfTurkishUser() async {
    try {
      final countryService = CountryDetectionService();
      // Use getUserCountry() instead of isTurkishPlayStoreUser() 
      // to allow fallback for Turkish users when Play Store detection fails
      final countryCode = await countryService.getUserCountry();
      final isTurkish = countryCode == 'TR';
      debugPrint('🌍 DailyTasksCard: Country code: $countryCode, isTurkish: $isTurkish');
      if (mounted) {
        setState(() {
          _isTurkishUser = isTurkish;
          _isCheckingCountry = false;
        });
      }
    } catch (e) {
      debugPrint('❌ DailyTasksCard: Error checking country: $e');
      if (mounted) {
        setState(() {
          _isTurkishUser = false;
          _isCheckingCountry = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if not Turkish user
    if (_isCheckingCountry) {
      return const SizedBox.shrink();
    }
    if (!_isTurkishUser) {
      return const SizedBox.shrink();
    }
    // Don't show if dismissed today
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PointProvider>(
      builder: (context, pointProvider, child) {
        if (pointProvider.isLoading || pointProvider.balance == null) {
          return const SizedBox.shrink();
        }

        final balance = pointProvider.balance!;
        final premiumService = PremiumService();
        final isPremium = premiumService.isPremium;
        final isPremiumPlus = premiumService.isPremiumPlus;

        // Calculate points with premium multiplier
        final dailyLoginPoints = _getPointsWithMultiplier(25, isPremium, isPremiumPlus);
        final rewardedAdPoints = _getPointsWithMultiplier(50, isPremium, isPremiumPlus);
        final transactionPoints = _getPointsWithMultiplier(15, isPremium, isPremiumPlus);
        
        // Calculate total possible points per day
        final maxDailyLoginPoints = dailyLoginPoints;
        final maxRewardedAdPoints = rewardedAdPoints * 10; // 10 ads max
        final maxTransactionPoints = transactionPoints * 20; // 20 transactions max
        final totalDailyPoints = maxDailyLoginPoints + maxRewardedAdPoints + maxTransactionPoints;

        // Check completion status
        final hasDailyLogin = _hasDailyLogin(balance);
        final rewardedAdCount = _getRewardedAdCountToday(balance);
        final transactionCount = _getTransactionCountToday(balance);

        return InkWell(
          onTap: () => context.push('/daily-tasks'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                width: 1,
              ),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 14,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Günlük Görevler',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 11,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatPoints(balance.totalEarned),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              ' toplam puan',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isPremium || isPremiumPlus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isPremiumPlus ? '2x' : '1.5x',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _dismissCard(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tasks
              _buildTaskItem(
                context: context,
                isDark: isDark,
                icon: Icons.login_rounded,
                title: 'Günlük Giriş',
                points: dailyLoginPoints,
                maxPoints: maxDailyLoginPoints,
                isCompleted: hasDailyLogin,
                progress: hasDailyLogin ? 1.0 : 0.0,
                maxProgress: 1.0,
                onTap: null,
              ),
              const SizedBox(height: 4),
              _buildTaskItem(
                context: context,
                isDark: isDark,
                icon: Icons.play_circle_outline_rounded,
                title: 'Reklam İzle',
                points: rewardedAdPoints,
                maxPoints: maxRewardedAdPoints,
                isCompleted: rewardedAdCount >= 10,
                progress: rewardedAdCount / 10.0,
                maxProgress: 10.0,
                currentCount: rewardedAdCount,
                onTap: rewardedAdCount < 10 ? () => _watchRewardedAd(context) : null,
                showActionButton: true,
                actionButtonOnTap: () => _watchRewardedAd(context),
              ),
              const SizedBox(height: 4),
              _buildTaskItem(
                context: context,
                isDark: isDark,
                icon: Icons.add_circle_outline_rounded,
                title: 'İşlem Ekle',
                points: transactionPoints,
                maxPoints: maxTransactionPoints,
                isCompleted: transactionCount >= 20,
                progress: transactionCount / 20.0,
                maxProgress: 20.0,
                currentCount: transactionCount,
                onTap: () => _navigateToTransactions(context),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required int points,
    required int maxPoints,
    required bool isCompleted,
    required double progress,
    required double maxProgress,
    int? currentCount,
    VoidCallback? onTap,
    bool showActionButton = false,
    VoidCallback? actionButtonOnTap,
  }) {
    // Use Material green for all tasks
    final taskColor = Colors.green[700]!;
    final taskBackgroundColor = Colors.green.withValues(alpha: 0.1);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark 
              ? (isCompleted 
                  ? Colors.green.withValues(alpha: 0.15)
                  : const Color(0xFF2C2C2E))
              : (isCompleted 
                  ? taskBackgroundColor
                  : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isCompleted
                      ? taskColor
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showActionButton && actionButtonOnTap != null)
                      Consumer<RewardedAdService>(
                        builder: (context, rewardedAdService, child) {
                          final isAdReady = rewardedAdService.isAdReady;
                          return GestureDetector(
                            onTap: isAdReady ? actionButtonOnTap : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAdReady
                                    ? taskColor
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 12,
                                    color: isAdReady
                                        ? Colors.white
                                        : (isDark ? Colors.white38 : Colors.black38),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'İzle',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isAdReady
                                          ? Colors.white
                                          : (isDark ? Colors.white38 : Colors.black38),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else if (isCompleted)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: taskColor,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      '$points puan',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted 
                            ? taskColor
                            : taskColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currentCount != null
                      ? '$currentCount/${maxProgress.toInt()}'
                      : (isCompleted ? '1/1' : '0/1'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    // Turkish format: 1.234 (dot as thousands separator)
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(points).replaceAll(',', '.');
  }

  int _getPointsWithMultiplier(int basePoints, bool isPremium, bool isPremiumPlus) {
    if (isPremiumPlus) {
      return (basePoints * 2).round();
    } else if (isPremium) {
      return (basePoints * 1.5).round();
    }
    return basePoints;
  }

  bool _hasDailyLogin(PointBalance balance) {
    if (balance.lastDailyLogin == null) return false;
    final today = DateTime.now();
    final lastLogin = balance.lastDailyLogin!;
    return lastLogin.year == today.year &&
        lastLogin.month == today.month &&
        lastLogin.day == today.day;
  }

  int _getRewardedAdCountToday(PointBalance balance) {
    // Get count from PointProvider transactions
    final pointProvider = Provider.of<PointProvider>(context, listen: false);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return pointProvider.transactions
        .where((transaction) =>
            transaction.activity == PointActivity.rewardedAd &&
            transaction.earnedAt.isAfter(startOfDay) &&
            transaction.earnedAt.isBefore(endOfDay))
        .length;
  }

  int _getTransactionCountToday(PointBalance balance) {
    // Get count from PointProvider transactions
    final pointProvider = Provider.of<PointProvider>(context, listen: false);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return pointProvider.transactions
        .where((transaction) =>
            transaction.activity == PointActivity.transaction &&
            transaction.earnedAt.isAfter(startOfDay) &&
            transaction.earnedAt.isBefore(endOfDay))
        .length;
  }

  Future<void> _watchRewardedAd(BuildContext context) async {
    try {
      final rewardedAdService = Provider.of<RewardedAdService>(context, listen: false);
      final pointProvider = Provider.of<PointProvider>(context, listen: false);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Reklam yükleniyor...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      final success = await rewardedAdService.showRewardedAd();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        if (success) {
          // Wait a bit for Firestore to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Refresh point balance
          await pointProvider.refresh();
          
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reklam izlendi! Puanlarınız eklendi.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Reklam yüklenemedi. Lütfen tekrar deneyin.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reklam yüklenemedi. Lütfen tekrar deneyin.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToTransactions(BuildContext context) {
    // Navigate to transactions tab in MainScreen (index 1)
    GoRouter.of(context).go('/home?tab=1');
  }
}

