import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/point_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../shared/models/point_balance_model.dart';
import '../../../shared/models/point_activity_model.dart';
import '../../../shared/models/point_transaction_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/providers/point_provider.dart';

/// Daily Tasks Page
/// Shows detailed information about daily tasks and point system
class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  bool _isTurkishUser = false;
  bool _isCheckingCountry = true;

  @override
  void initState() {
    super.initState();
    _checkIfTurkishUser();
  }

  Future<void> _checkIfTurkishUser() async {
    try {
      final countryService = CountryDetectionService();
      // Use getUserCountry() instead of isTurkishPlayStoreUser() 
      // to allow fallback for Turkish users when Play Store detection fails
      final countryCode = await countryService.getUserCountry();
      final isTurkish = countryCode == 'TR';
      debugPrint('🌍 DailyTasksPage: Country code: $countryCode, isTurkish: $isTurkish');
      if (mounted) {
        setState(() {
          _isTurkishUser = isTurkish;
          _isCheckingCountry = false;
        });
      }
    } catch (e) {
      debugPrint('❌ DailyTasksPage: Error checking country: $e');
      if (mounted) {
        setState(() {
          _isTurkishUser = false;
          _isCheckingCountry = false;
        });
      }
    }
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
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return balance.lastDailyLogin != null &&
        balance.lastDailyLogin!.isAfter(todayStart);
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

  String _formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(points);
  }

  Future<void> _watchRewardedAd(BuildContext context) async {
    final rewardedAdService = RewardedAdService();
    
    if (!rewardedAdService.isAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reklam henüz hazır değil. Lütfen bekleyin...'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await rewardedAdService.showRewardedAd();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Refresh point provider
        Provider.of<PointProvider>(context, listen: false).loadBalance();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Puanlarınız eklendi!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reklam gösterilirken hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingCountry) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (!_isTurkishUser) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Günlük Görevler'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Bu özellik sadece Türkiye\'de kullanılabilir.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumService = PremiumService();
    final isPremium = premiumService.isPremium;
    final isPremiumPlus = premiumService.isPremiumPlus;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Günlük Görevler',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Consumer<PointProvider>(
        builder: (context, pointProvider, child) {
          if (pointProvider.isLoading || pointProvider.balance == null) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          final balance = pointProvider.balance!;

          // Calculate points with premium multiplier
          final dailyLoginPoints = _getPointsWithMultiplier(25, isPremium, isPremiumPlus);
          final rewardedAdPoints = _getPointsWithMultiplier(50, isPremium, isPremiumPlus);
          final transactionPoints = _getPointsWithMultiplier(15, isPremium, isPremiumPlus);

          // Check completion status
          final hasDailyLogin = _hasDailyLogin(balance);
          final rewardedAdCount = _getRewardedAdCountToday(balance);
          final transactionCount = _getTransactionCountToday(balance);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with Total Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF59E0B),
                        const Color(0xFFD97706),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Puan',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPoints(balance.totalEarned),
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPremium || isPremiumPlus)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPremiumPlus ? '2x' : '1.5x',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.login_rounded,
                              label: 'Günlük Giriş',
                              value: hasDailyLogin ? 'Tamamlandı' : 'Bekliyor',
                              isCompleted: hasDailyLogin,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.play_circle_outline_rounded,
                              label: 'Reklam İzle',
                              value: '$rewardedAdCount/10',
                              isCompleted: rewardedAdCount >= 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'İşlem Ekle',
                              value: '$transactionCount/20',
                              isCompleted: transactionCount >= 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Premium Multiplier Info
                if (isPremium || isPremiumPlus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          const Color(0xFFD97706).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF59E0B),
                                const Color(0xFFD97706),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPremiumPlus ? 'Premium Plus Aktif' : 'Premium Aktif',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPremiumPlus
                                    ? 'Tüm puanlarınız 2 katına çıkarılıyor!'
                                    : 'Tüm puanlarınız 1.5 katına çıkarılıyor!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium ile Daha Fazla Puan',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Premium üyelik ile tüm puanlarınız 1.5x, Premium Plus ile 2x değerinde!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/premium-offer'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Keşfet', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Daily Tasks Section
                Text(
                  'Günlük Görevler',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Daily Login Task
                _buildDetailedTaskCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.login_rounded,
                  title: 'Günlük Giriş',
                  description: 'Her gün uygulamaya giriş yaparak puan kazanın',
                  points: dailyLoginPoints,
                  isCompleted: hasDailyLogin,
                  progress: hasDailyLogin ? 1.0 : 0.0,
                  maxProgress: 1.0,
                  onTap: null,
                ),
                const SizedBox(height: 12),

                // Rewarded Ad Task
                _buildDetailedTaskCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Reklam İzle',
                  description: 'Günde 10 reklam izleyerek toplam ${_formatPoints(rewardedAdPoints * 10)} puan kazanın',
                  points: rewardedAdPoints,
                  isCompleted: rewardedAdCount >= 10,
                  progress: rewardedAdCount / 10.0,
                  maxProgress: 10.0,
                  currentCount: rewardedAdCount,
                  onTap: rewardedAdCount < 10 ? () => _watchRewardedAd(context) : null,
                  showActionButton: true,
                  actionButtonOnTap: () => _watchRewardedAd(context),
                ),
                const SizedBox(height: 10),

                // Transaction Task
                _buildDetailedTaskCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.add_circle_outline_rounded,
                  title: 'İşlem Ekle',
                  description: 'Günde 20 işlem ekleyerek toplam ${_formatPoints(transactionPoints * 20)} puan kazanın',
                  points: transactionPoints,
                  isCompleted: transactionCount >= 20,
                  progress: transactionCount / 20.0,
                  maxProgress: 20.0,
                  currentCount: transactionCount,
                  onTap: () => context.go('/home?tab=1'),
                ),
                const SizedBox(height: 20),

                // How to Earn Points Section
                Text(
                  'Puan Kazanma Yolları',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                _buildEarningMethodCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.credit_card_rounded,
                  title: 'İlk Kart Ekleme',
                  description: 'İlk banka veya kredi kartınızı eklediğinizde',
                  points: _getPointsWithMultiplier(250, isPremium, isPremiumPlus),
                ),
                const SizedBox(height: 10),

                _buildEarningMethodCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'İlk Bütçe Oluşturma',
                  description: 'İlk bütçenizi oluşturduğunuzda',
                  points: _getPointsWithMultiplier(250, isPremium, isPremiumPlus),
                ),
                const SizedBox(height: 10),

                _buildEarningMethodCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.trending_up_rounded,
                  title: 'İlk Hisse Alımı',
                  description: 'İlk hisse senedi alımınızda',
                  points: _getPointsWithMultiplier(250, isPremium, isPremiumPlus),
                ),
                const SizedBox(height: 10),

                _buildEarningMethodCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.repeat_rounded,
                  title: 'İlk Abonelik Oluşturma',
                  description: 'İlk aboneliğinizi oluşturduğunuzda',
                  points: _getPointsWithMultiplier(250, isPremium, isPremiumPlus),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTaskCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required int points,
    required bool isCompleted,
    required double progress,
    required double maxProgress,
    int? currentCount,
    VoidCallback? onTap,
    bool showActionButton = false,
    VoidCallback? actionButtonOnTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
            width: isCompleted ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B),
                        const Color(0xFFD97706),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPoints(points),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currentCount != null
                      ? '$currentCount/${maxProgress.toInt()}'
                      : (isCompleted ? 'Tamamlandı' : '0/${maxProgress.toInt()}'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (showActionButton && actionButtonOnTap != null && !isCompleted) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Consumer<RewardedAdService>(
                  builder: (context, rewardedAdService, child) {
                    final isAdReady = rewardedAdService.isAdReady;
                    return ElevatedButton(
                      onPressed: isAdReady ? actionButtonOnTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdReady
                            ? const Color(0xFFF59E0B)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05)),
                        foregroundColor: isAdReady
                            ? Colors.white
                            : (isDark ? Colors.white38 : Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: isAdReady
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reklam İzle',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningMethodCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B),
                  const Color(0xFFD97706),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatPoints(points),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

