import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// AI Limit Göstergesi Widget
/// 
/// Kullanıcının günlük AI kullanım limitini gösterir
/// Free kullanıcılar için reklam izleme seçeneği sunar
class AILimitIndicator extends StatelessWidget {
  final int currentUsage;
  final int totalLimit;
  final int bonusCount;
  final bool bonusAvailable;
  final int maxBonus;
  final VoidCallback? onAdWatched; // Reklam izlenince çağrılacak
  final bool isCompact; // Kompakt mod (AppBar için)

  const AILimitIndicator({
    super.key,
    required this.currentUsage,
    required this.totalLimit,
    this.bonusCount = 0,
    this.bonusAvailable = false,
    this.maxBonus = 0,
    this.onAdWatched,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rewardedAdService = Provider.of<RewardedAdService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final remaining = totalLimit - currentUsage;
    final percentage = totalLimit > 0 ? currentUsage / totalLimit : 0.0;
    
    // Debug: Limit bilgilerini logla
    if (!isCompact) {
      debugPrint('🎨 AILimitIndicator:');
      debugPrint('   Current Usage: $currentUsage');
      debugPrint('   Total Limit: $totalLimit');
      debugPrint('   Bonus: $bonusCount');
      debugPrint('   Remaining: $remaining');
      debugPrint('   Percentage: ${(percentage * 100).toStringAsFixed(1)}%');
    }
    
    // Renk duruma göre
    Color indicatorColor;
    if (percentage >= 1.0) {
      indicatorColor = Colors.red;
    } else if (percentage >= 0.8) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.green;
    }
    
    // Kompakt mod - AppBar için
    if (isCompact) {
      return _buildCompactMode(context, isDark, indicatorColor, remaining, percentage);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: indicatorColor),
                const SizedBox(width: 8),
                Text(
                  l10n.aiUsageLimit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.remainingCount(remaining),
                  style: TextStyle(
                    fontSize: 14,
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                minHeight: 8,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Detaylı bilgi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentUsage / $totalLimit ${l10n.messages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (bonusCount > 0)
                  Text(
                    '+$bonusCount ${l10n.bonus}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            
            // Reklam izleme butonu (bonus varsa)
            if (bonusAvailable && remaining <= 2) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.video_library,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.watchAdBonusInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: rewardedAdService.isAdReady
                      ? () => _showRewardedAd(context)
                      : null,
                  icon: const Icon(Icons.play_circle_filled),
                  label: Text(
                    rewardedAdService.isAdReady
                        ? l10n.watchAdBonus
                        : l10n.adLoading,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              if (bonusCount < maxBonus)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.maxBonusRemaining(maxBonus - bonusCount),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            
            // Premium teklifi (limit dolmuşsa)
            if (remaining == 0 && !bonusAvailable) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(
                    Icons.stars,
                    size: 20,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.unlimitedAIWithPremium,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Premium sayfasına yönlendir
                    Navigator.pushNamed(context, '/premium');
                  },
                  icon: const Icon(Icons.workspace_premium),
                  label: Text(l10n.upgradeToPremium),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Kompakt mod UI - AppBar için
  Widget _buildCompactMode(BuildContext context, bool isDark, Color indicatorColor, int remaining, double percentage) {
    final rewardedAdService = Provider.of<RewardedAdService>(context);
    final premiumService = Provider.of<PremiumService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Plan period - localized
    final planPeriod = (premiumService.isPremiumPlus || premiumService.isPremium) 
        ? l10n.perMonth 
        : l10n.perDay;
    
    return GestureDetector(
      onTap: () {
        // Eğer bonus kazanılabilirse ve limit dolmuşsa direkt reklam göster
        if (bonusAvailable && remaining <= 0) {
          if (rewardedAdService.isAdReady) {
            _showRewardedAd(context);
          } else {
            // Reklam hazır değilse bilgi mesajı göster
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.adLoadingWait),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: indicatorColor,
              size: 12,
            ),
            const SizedBox(width: 4),
            // Limit bilgisi
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$remaining/$totalLimit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: indicatorColor,
                    ),
                  ),
                  // Period göster
                  TextSpan(
                    text: planPeriod,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: indicatorColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Limit dolmuşsa ve bonus kazanılabilirse video ikonu göster
            if (bonusAvailable && remaining <= 0) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.play_circle_filled,
                color: AppColors.secondary,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Limit bilgisi ve reklam butonu içeren dialog
  void _showLimitDialog(BuildContext context) {
    final rewardedAdService = context.read<RewardedAdService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(l10n.aiUsageLimit),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanım bilgisi
            Text(
              '${l10n.dailyUsage}: $currentUsage / $totalLimit',
              style: const TextStyle(fontSize: 14),
            ),
            if (bonusCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.bonus}: +$bonusCount ${l10n.rights}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            ],
            
            // Reklam izleme seçeneği
            if (bonusAvailable) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.video_library, size: 20, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.watchAdBonusInfo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: rewardedAdService.isAdReady
                      ? () {
                          Navigator.pop(context);
                          _showRewardedAd(context);
                        }
                      : null,
                  icon: const Icon(Icons.play_circle_filled, size: 20),
                  label: Text(
                    rewardedAdService.isAdReady
                        ? l10n.watchAdBonusShort
                        : l10n.loading,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Ödüllü reklam göster
  Future<void> _showRewardedAd(BuildContext context) async {
    final rewardedAdService = context.read<RewardedAdService>();
    
    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final success = await rewardedAdService.showRewardedAd();
    
    // Loading dialog kapat
    if (context.mounted) {
      Navigator.of(context).pop();
      
      if (success) {
        // 🔔 Reklam izlendi, AI limitlerini güncelle
        debugPrint('🎁 AILimitIndicator: Ad rewarded, triggering callback...');
        onAdWatched?.call();
        
        // Context hala geçerliyse UnifiedProviderV2'yi de güncelle
        if (context.mounted) {
          try {
            final provider = context.read<UnifiedProviderV2>();
            await provider.loadAIUsage();
            debugPrint('✅ AILimitIndicator: AI limits reloaded');
          } catch (e) {
            debugPrint('❌ AILimitIndicator: Failed to reload AI limits: $e');
          }
        }
      } else {
        // Hata mesajı - sadece hata durumunda göster
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adLoadError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

