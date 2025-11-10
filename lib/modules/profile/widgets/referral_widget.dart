import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/referral_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/widgets/referral_code_modal.dart';

/// Referral Widget
/// Shows referral code and allows users to invite friends
/// Each referral earns 500 points
class ReferralWidget extends StatefulWidget {
  const ReferralWidget({super.key});

  @override
  State<ReferralWidget> createState() => _ReferralWidgetState();
}

class _ReferralWidgetState extends State<ReferralWidget>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _referralCode;
  int _referralCount = 0;
  bool _hasEnteredReferralCode = false; // Track if user has entered a code
  static const int maxReferrals = 5; // Maximum 5 referrals allowed
  bool _isInitialized = false; // Track if widget has been initialized
  
  // Stream subscriptions to prevent memory leaks and infinite loops
  StreamSubscription<int>? _referralCountSubscription;
  StreamSubscription<bool>? _hasEnteredReferralCodeSubscription;
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent rebuilds

  @override
  void initState() {
    super.initState();
    // Only load data once, not on every rebuild
    if (!_isInitialized) {
      _loadReferralData();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _referralCountSubscription?.cancel();
    _hasEnteredReferralCodeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final referralService = ReferralService();
      
      // Check if user has entered a referral code
      _hasEnteredReferralCode = await referralService.hasEnteredReferralCode();
      
      // Get referral code
      _referralCode = referralService.getReferralCode();
      
      // Load referral count from Firestore
      _referralCount = await referralService.getReferralCount();
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Cancel existing subscriptions before creating new ones
      await _referralCountSubscription?.cancel();
      await _hasEnteredReferralCodeSubscription?.cancel();
      
      // Listen to real-time updates for referral count (background updates only)
      _referralCountSubscription = referralService.getReferralCountStream().listen((count) {
        if (mounted && _referralCount != count) {
          setState(() {
            _referralCount = count;
          });
        }
      });
      
      // Listen to referral code status changes (background updates only)
      _hasEnteredReferralCodeSubscription = referralService.hasEnteredReferralCodeStream().listen((hasEntered) {
        if (mounted && _hasEnteredReferralCode != hasEntered) {
          setState(() {
            _hasEnteredReferralCode = hasEntered;
          });
          // Reload referral count when status changes (but don't reload streams)
          _refreshReferralCount();
        }
      });
    } catch (e) {
      debugPrint('❌ ReferralWidget: Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Refresh referral count without reloading streams
  Future<void> _refreshReferralCount() async {
    try {
      final referralService = ReferralService();
      final count = await referralService.getReferralCount();
      if (mounted && _referralCount != count) {
        setState(() {
          _referralCount = count;
        });
      }
    } catch (e) {
      debugPrint('❌ ReferralWidget: Error refreshing referral count: $e');
    }
  }
  
  /// Show referral code entry bottom sheet
  Future<void> _showReferralCodeEntryModal() async {
    try {
      // Import the modal widget
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        isDismissible: false,
        enableDrag: false,
        builder: (context) => const ReferralCodeModal(),
      );
      
      if (result == true && mounted) {
        // Reload data after successful code entry
        await _loadReferralData();
        
        // Show success message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Referans kodu başarıyla eklendi! 🎉',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                          ),
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
            } catch (e) {
              debugPrint('⚠️ Could not show snackbar: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ ReferralWidget: Error showing referral code modal: $e');
    }
  }

  Future<void> _copyReferralCode() async {
    if (_referralCode == null) return;
    
    await Clipboard.setData(ClipboardData(text: _referralCode!));
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Use postFrameCallback to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
        try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              Text(
                          'Kopyalandı!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                            fontWeight: FontWeight.w600,
                  color: Colors.white,
                          ),
                        ),
                        Text(
                          'Referans kodu panoya kopyalandı',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
          ),
              margin: const EdgeInsets.all(16),
              elevation: 6,
        ),
      );
        } catch (e) {
          debugPrint('⚠️ Could not show snackbar: $e');
        }
    }
    });
  }

  Future<void> _shareReferralCode() async {
    debugPrint('🔄 ReferralWidget: Share button pressed');
    debugPrint('   Referral Code: $_referralCode');
    debugPrint('   Referral Count: $_referralCount');
    debugPrint('   Max Referrals: $maxReferrals');
    
    if (_referralCode == null || _referralCode!.isEmpty) {
      debugPrint('❌ ReferralWidget: Referral code is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Referans kodu bulunamadı',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Check if max referrals reached
    if (_referralCount >= maxReferrals) {
      debugPrint('⚠️ ReferralWidget: Max referrals reached');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maksimum arkadaş sayısına ulaştınız ($maxReferrals/5)',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.grey.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Use fixed 500 points for referral (matching Cloud Function and model)
    // Remote Config might have different value, but we want to show 500 in message
    const referralPoints = 500;
    
    final shareText = '''
Merhaba! 👋

Qanta'yı kullanıyorum ve gerçekten çok faydalı buluyorum.

Sen de dener misin? İkimiz de $referralPoints puan kazanıyoruz!

📲 İndir: https://play.google.com/store/apps/details?id=com.qanta

Referans kodum: $_referralCode

Kodunu profiline gir, puanlar hemen hesabına eklensin!

Qanta ile yapabileceklerin:

• Bütçeni kolayca yönet
• Harcamalarını analiz et
• Yatırımlarını takip et
• Qanta AI'dan kişisel finans önerileri al
• Puan biriktir, hediye kartı kazan 

🎁 Hediye Kartları:
• Amazon (100 TL)
• D&R (100 TL)
• Gratis (100 TL)
• Paribu Cineverse (500 TL)

Her işlem ve aktivitede puan kazan, hediye kartlarını hemen kullan!

Gerçekten denemeye değer 😉
''';

    debugPrint('📤 ReferralWidget: Sharing text: $shareText');
    
    try {
      final result = await Share.share(
        shareText,
        subject: 'Qanta\'ya katıl!',
      );
      
      debugPrint('✅ ReferralWidget: Share result: ${result.status}');
      
      if (result.status == ShareResultStatus.success) {
        debugPrint('✅ ReferralWidget: Share successful');
      } else if (result.status == ShareResultStatus.dismissed) {
        debugPrint('ℹ️ ReferralWidget: Share dismissed by user');
      } else {
        debugPrint('⚠️ ReferralWidget: Share result: ${result.status}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ReferralWidget: Error sharing: $e');
      debugPrint('❌ ReferralWidget: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paylaşım sırasında bir hata oluştu',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                if (kDebugMode)
                  Text(
                    'Hata: $e',
                    style: GoogleFonts.inter(fontSize: 10),
                  ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Build referral code entry card (shown when user hasn't entered a code)
  Widget _buildReferralCodeEntryCard(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.green,
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
                  l10n.referralCodeTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '500 puan kazan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _showReferralCodeEntryModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  l10n.referralCodeSubmit,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<bool>(
      future: CountryDetectionService().shouldShowAmazonRewards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        if (_isLoading) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF2C2C2E),
                        const Color(0xFF1C1C1E),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFFAFAFA),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(color: const Color(0xFF38383A), width: 0.5)
                : Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
        }

        // Use fixed 500 points for referral display (matching actual reward)
        const referralPoints = 500;
        final progress = _referralCount / maxReferrals;
        final remainingReferrals = maxReferrals - _referralCount;
        final isMaxReached = _referralCount >= maxReferrals;
        
        // Build widget content
        // If user hasn't entered a referral code, show entry card at the top
        // Then always show the normal referral widget (with user's own referral code)
        // Note: _referralCode is always available (generated from user ID)
        return Column(
          children: [
            // Show entry card if user hasn't entered a referral code (referred_by is null)
            if (!_hasEnteredReferralCode) ...[
              _buildReferralCodeEntryCard(context, isDark),
              const SizedBox(height: 16),
            ],
            
            // Always show the normal referral widget (user's own referral code to share)
            Container(
                margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                  ),
                        const SizedBox(width: 10),
                  Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                      'Arkadaşını Getir',
                      style: GoogleFonts.inter(
                                  fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$referralPoints puan',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                    ),
                  ),
                  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                            color: isMaxReached
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_referralCount/$maxReferrals',
                      style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isMaxReached ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
                    const SizedBox(height: 8),
                    
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMaxReached ? Colors.grey : Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

              // Referral Code
              if (_referralCode != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                                    ? const Color(0xFF38383A)
                                    : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF48484A)
                                      : const Color(0xFFE5E5EA),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _referralCode!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                          Material(
                      color: isDark
                          ? const Color(0xFF48484A)
                          : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: _copyReferralCode,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.copy_rounded,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  size: 16,
                          ),
                        ),
                      ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

              // Share Button
              SizedBox(
                width: double.infinity,
                      child: Material(
                        color: isMaxReached
                            ? Colors.grey.shade300
                            : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            if (isMaxReached) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                    'Maksimum arkadaş sayısına ulaştınız',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            backgroundColor: Colors.grey.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      return;
                    }
                    _shareReferralCode();
                  },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isMaxReached
                                      ? Icons.check_circle_rounded
                                      : Icons.share_rounded,
                                  color: Colors.white,
                                  size: 16,
                  ),
                                const SizedBox(width: 6),
                                Text(
                                  isMaxReached ? 'Tamamlandı' : 'Paylaş',
                    style: GoogleFonts.inter(
                                    fontSize: 12,
                      fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
            ),
          ],
        );
      },
    );
  }
}

