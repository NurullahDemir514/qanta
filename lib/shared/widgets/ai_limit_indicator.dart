import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/services/premium_service.dart';

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
    final premiumService = Provider.of<PremiumService>(context);
    final rewardedAdService = Provider.of<RewardedAdService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium kullanıcılar için gösterme
    if (premiumService.isPremium) {
      return const SizedBox.shrink();
    }

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
                const Text(
                  'AI Kullanım Limiti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$remaining kaldı',
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
                  '$currentUsage / $totalLimit mesaj',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (bonusCount > 0)
                  Text(
                    '+$bonusCount bonus',
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
                  const Icon(
                    Icons.video_library,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reklam izleyerek +5 ek kullanım hakkı kazanabilirsiniz',
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
                        ? 'Reklam İzle (+5 Hak)'
                        : 'Reklam Yükleniyor...',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              if (bonusCount < maxBonus)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Günlük maksimum ${maxBonus - bonusCount} bonus daha kazanabilirsiniz',
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
                      'Premium ile sınırsız AI kullanımı',
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
                  label: const Text('Premium\'a Geç'),
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
    
    return GestureDetector(
      onTap: () {
        // Eğer bonus kazanılabilirse ve limit dolmuşsa direkt reklam göster
        if (bonusAvailable && remaining <= 0) {
          if (rewardedAdService.isAdReady) {
            _showRewardedAd(context);
          } else {
            // Reklam hazır değilse bilgi mesajı göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reklam yükleniyor, lütfen bekleyin...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: indicatorColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: indicatorColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: indicatorColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '$remaining/$totalLimit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
            ),
            // Bonus varsa göster
            if (bonusCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '+$bonusCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: indicatorColor.withOpacity(0.7),
                ),
              ),
            ],
            // Limit dolmuşsa ve bonus kazanılabilirse video ikonu göster
            if (bonusAvailable && remaining <= 0) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.play_circle_filled,
                color: Colors.blue,
                size: 16,
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            const Text('AI Kullanım Limiti'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanım bilgisi
            Text(
              'Günlük kullanım: $currentUsage / $totalLimit',
              style: const TextStyle(fontSize: 14),
            ),
            if (bonusCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Bonus: +$bonusCount hak',
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
                  const Icon(Icons.video_library, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reklam izleyerek +5 ek kullanım hakkı kazanabilirsiniz',
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
                        ? 'Reklam İzle (+5)'
                        : 'Yükleniyor...',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
            child: const Text('Kapat'),
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
        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tebrikler! +5 AI kullanım hakkı kazandınız'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Callback çağır
        onAdWatched?.call();
      } else {
        // Hata mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Reklam izlenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

