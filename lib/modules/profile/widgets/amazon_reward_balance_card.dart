import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/amazon_reward_service.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/point_service.dart';
import '../../../shared/models/amazon_reward_stats_model.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/amazon_reward_provider.dart';
import '../providers/point_provider.dart';
import '../pages/amazon_reward_history_page.dart';
import '../pages/amazon_gift_card_history_page.dart';
import 'amazon_email_input_dialog.dart';
import 'elegant_gift_card_request_flow.dart';
import 'elegant_gift_card_button.dart';

/// Amazon Reward Balance Card Widget
/// Shows current balance and progress to next gift card
class AmazonRewardBalanceCard extends StatelessWidget {
  const AmazonRewardBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AmazonRewardProvider>(
      builder: (context, provider, child) {
        // Don't show card if not eligible
        if (!provider.isEligible) {
          return const SizedBox.shrink();
        }

        final stats = provider.stats;
        if (stats == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get points from PointProvider instead of TL balance
        final pointProvider = Provider.of<PointProvider>(context);
        final pointBalance = pointProvider.balance;
        final currentPoints = pointBalance?.totalPoints ?? 0;
        
        // Convert points to TL for display (200 points = 1 TL for Amazon gift cards)
        final balanceInTL = currentPoints / 200.0;
        final targetPoints = 20000; // 100 TL = 20,000 points (200 × 100)
        final progress = (currentPoints / targetPoints).clamp(0.0, 1.0);
        final remainingPoints = (targetPoints - currentPoints).clamp(0, targetPoints);
        final remainingInTL = remainingPoints / 200.0;
        
        final totalEarned = pointBalance?.totalEarned ?? 0;
        final totalEarnedInTL = totalEarned / 200.0;
        final totalGiftCards = stats.totalGiftCards;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1C1C1E),
                      const Color(0xFF2C2C2E),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF5F5F5),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: isDark
                ? Border.all(color: const Color(0xFF38383A), width: 0.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.asset(
                      'assets/images/amazon_logo_new.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      color: isDark ? Colors.white : null,
                      colorBlendMode: isDark ? BlendMode.srcIn : BlendMode.dst,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amazon Hediye Kartı',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Puanlarınızı biriktirin, 20.000 puan = 100 TL hediye kartı',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Balance Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mevcut Puan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat('#,###').format(currentPoints),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9900),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '≈ ${balanceInTL.toStringAsFixed(2)} TL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Hedef',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '20,000',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '100.00 TL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% tamamlandı',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(remainingPoints)} puan kaldı',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE5E5EA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF9900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Toplam Kazanç',
                    '${NumberFormat('#,###').format(totalEarned)} puan',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                  ),
                  _buildStatItem(
                    context,
                    'Hediye Kartı',
                    '$totalGiftCards adet',
                  ),
                ],
              ),
              const SizedBox(height: 12),


              // Watch Ad Button (if points < 20,000 = 100 TL)
              if (currentPoints < 20000)
                Consumer<RewardedAdService>(
                  builder: (context, rewardedAdService, child) {
                    final isReady = rewardedAdService.isAdReady;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: isReady
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF9900),
                                  const Color(0xFFFF7700),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isReady
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF9900)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isReady
                              ? () => _showRewardedAdForAmazonReward(context)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isReady) ...[
                                  Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reklam İzle',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+50',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Yükleniyor...',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AmazonRewardHistoryPage(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.history,
                        size: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF6D6D70),
                      ),
                      label: Text(
                        'Geçmiş',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF6D6D70),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : const Color(0xFFE5E5EA),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElegantGiftCardButton(
                      currentPoints: currentPoints,
                      onPressed: currentPoints >= 20000
                          ? () async {
                              // Show elegant gift card request flow
                              final success = await ElegantGiftCardRequestFlow.show(
                                context,
                                currentPoints,
                              );
                              
                              if (success && context.mounted) {
                                // Refresh point balance
                                final pointProvider = Provider.of<PointProvider>(context, listen: false);
                                await pointProvider.refresh();
                                
                                // Show success snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Hediye kartı talebiniz başarıyla alındı!',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade500,
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AmazonGiftCardHistoryPage(),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Show rewarded ad for Amazon reward
  Future<void> _showRewardedAdForAmazonReward(BuildContext context) async {
    final rewardedAdService = Provider.of<RewardedAdService>(context, listen: false);
    final provider = Provider.of<AmazonRewardProvider>(context, listen: false);
    
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
        // Wait a bit for Firestore to update (rewards are written async)
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh Amazon reward stats (force reload from Firestore)
        await provider.loadStats();
        
        // Wait a bit more and refresh again to ensure we have latest data
        await Future.delayed(const Duration(milliseconds: 300));
        await provider.loadStats();
        
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tebrikler!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '50 puan kazandınız!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reklam izlenemedi. Lütfen tekrar deneyin.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  /// Show gift card request dialog
  Future<void> _showGiftCardRequestDialog(
    BuildContext context,
    int currentPoints,
  ) async {
    final pointService = PointService();
    final pointProvider = Provider.of<PointProvider>(context, listen: false);
    
    // Convert points to TL (200 points = 1 TL for Amazon gift cards)
    final balanceInTL = currentPoints / 200.0;
    
    // Calculate how many 100 TL gift cards can be requested (20,000 points each)
    final giftCardCount = (currentPoints / 20000).floor();
    final maxGiftCards = giftCardCount.clamp(1, 10); // Max 10 at once
    
    if (maxGiftCards == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimum 20,000 puan (100 TL) bakiyeniz olmalı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show email input dialog
    final email = await AmazonEmailInputDialog.show(
      context,
      balance: balanceInTL,
    );

    if (email == null || email.isEmpty) {
      return;
    }

    // Show loading
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
                'Hediye kartı hazırlanıyor...',
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

    int? totalPointsToSpend;
    try {
      // Spend points for gift cards (20,000 points = 100 TL each)
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final pointsPerCard = 20000; // 100 TL = 20,000 points (200 × 100)
      totalPointsToSpend = maxGiftCards * pointsPerCard;

      // Check if user has enough points
      final balance = await pointService.getCurrentBalance(userId);
      if (balance < totalPointsToSpend) {
        throw Exception('Yetersiz puan bakiyesi');
      }

      // Spend points
      final success = await pointService.spendPoints(
        userId,
        totalPointsToSpend,
        'Amazon Hediye Kartı (${maxGiftCards * 100} TL)',
      );

      if (!success) {
        throw Exception('Puan harcama başarısız');
      }

      // Request gift card from Amazon service (using points spent)
      // Note: Points have already been spent, so we create the request directly
      final amazonRewardService = AmazonRewardService();
      final giftCardRequestSuccess = await amazonRewardService.createGiftCardRequestDirectly(
        userId,
        email,
        maxGiftCards * 100.0,
        totalPointsToSpend!,
      );

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();

        if (giftCardRequestSuccess) {
          // Refresh point balance
          await pointProvider.refresh();

          // Show success
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${maxGiftCards * 100} TL değerinde hediye kartı talebiniz alındı! ${NumberFormat('#,###').format(totalPointsToSpend ?? 0)} puan harcandı. E-posta adresinize gönderilecek.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Hediye kartı talebi başarısız oldu'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting gift card: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

