import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../l10n/app_localizations.dart';

/// Development için Premium Test Sayfası
/// Bu sayfa sadece debug build'de görünür olmalı
class PremiumTestPage extends StatelessWidget {
  const PremiumTestPage({super.key});

  Future<void> _togglePremium(BuildContext context, bool value) async {
    final premiumService = context.read<PremiumService>();
    await premiumService.setTestPremium(value);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
                ? '🎉 Premium aktif edildi - Reklamlar kapatıldı!'
                : '📱 Free mode aktif - Reklamlar açıldı',
            style: GoogleFonts.inter(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _resetPremiumStatus(BuildContext context) async {
    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Premium Durumunu Sıfırla?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bu işlem SharedPreferences\'taki premium kaydını silecek ve Google Play\'den restore yapacak. Aktif abonelik varsa tekrar aktif olur, yoksa free olur.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sıfırla', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Loading göster
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Sıfırlanıyor...',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final premiumService = context.read<PremiumService>();
      await premiumService.resetPremiumStatus();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Premium durumu sıfırlandı!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Hata: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final isPremium = premiumService.isPremium;
        
        return Scaffold(
          appBar: AppBar(
        title: Text(
          '🧪 Premium Test (Debug)',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
        elevation: 0,
      ),
      body: Container(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu sayfa sadece debug modda test için kullanılır. Production\'da bu sayfa görünmez.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Premium Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPremium
                      ? [
                          const Color(0xFFFFD700),
                          const Color(0xFFFFA500),
                        ]
                      : [
                          isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isPremium
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isPremium ? Icons.stars_rounded : Icons.person_outline,
                    size: 64,
                    color: isPremium
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPremium ? '💎 PREMIUM' : '📱 FREE',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPremium
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                        ? 'Tüm reklamlar kapalı'
                        : 'Reklamlar görünüyor',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isPremium
                          ? Colors.white.withOpacity(0.9)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Toggle Premium
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Durumu',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Test için premium aç/kapat',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isPremium,
                        onChanged: (value) => _togglePremium(context, value),
                        activeColor: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reset Premium Button
            OutlinedButton.icon(
              onPressed: () => _resetPremiumStatus(context),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Premium Durumunu Sıfırla',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF007AFF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Test Talimatları',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(context, '1', 'Premium\'u AÇ ve uygulamayı gezin'),
                  _buildInstruction(context, '2', 'Hiçbir reklam görünmemeli'),
                  _buildInstruction(context, '3', 'Premium\'u KAPAT ve uygulamayı gezin'),
                  _buildInstruction(context, '4', 'Reklamlar tekrar görünmeli'),
                  _buildInstruction(context, '5', 'Abonelik iptali test için: "Sıfırla" butonu ile Google Play\'den kontrol'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'Testi Bitir',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildInstruction(BuildContext context, String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

