import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/point_service.dart';
import '../../../shared/models/gift_card_provider_model.dart';
import '../../../shared/models/amazon_gift_card_model.dart';
import '../providers/point_provider.dart';
import '../pages/amazon_reward_history_page.dart';
import '../pages/amazon_gift_card_history_page.dart';
import 'elegant_gift_card_request_flow.dart';
import 'elegant_gift_card_button.dart';

/// Multi-Provider Gift Card Widget
/// Shows gift card options with horizontal swipe
class MultiProviderGiftCardWidget extends StatefulWidget {
  const MultiProviderGiftCardWidget({super.key});

  @override
  State<MultiProviderGiftCardWidget> createState() =>
      _MultiProviderGiftCardWidgetState();
}

class _MultiProviderGiftCardWidgetState
    extends State<MultiProviderGiftCardWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<GiftCardProviderConfig> _providers;
  StreamSubscription<QuerySnapshot>? _giftCardSubscription;
  Set<String> _shownNotifications = {}; // Track which gift cards we've already shown notifications for
  bool _isShowingSnackBar = false; // Prevent multiple snackbars from showing simultaneously

  @override
  void initState() {
    super.initState();
    _providers = GiftCardProviderConfig.getEnabledProviders();
    _pageController = PageController(initialPage: _currentPage);
    _setupGiftCardListener();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _giftCardSubscription?.cancel();
    // Clear snackbar when disposing to prevent memory leaks
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    super.dispose();
  }

  void _setupGiftCardListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Listen to real-time updates for gift cards
    _giftCardSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('amazon_gift_cards')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      // On first load, add all existing 'sent' cards to shown notifications
      // This prevents showing notifications for cards that were already sent before widget was created
      if (_shownNotifications.isEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          if (status == 'sent') {
            _shownNotifications.add(doc.id);
          }
        }
      }
      
      // Check if any gift card status changed to 'sent' and show notification
      _checkForNewSentCards(snapshot);
    });
  }

  void _checkForNewSentCards(QuerySnapshot snapshot) {
    if (!mounted || _isShowingSnackBar) return;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final giftCardId = doc.id;

      // If status is 'sent' and we haven't shown notification for this card yet
      if (status == 'sent' && !_shownNotifications.contains(giftCardId)) {
        // Mark as shown immediately to prevent duplicate notifications
        _shownNotifications.add(giftCardId);
        
        // Set flag to prevent multiple snackbars
        _isShowingSnackBar = true;
        
        try {
          final giftCard = AmazonGiftCard.fromQueryDocument(
            doc as QueryDocumentSnapshot<Map<String, dynamic>>,
          );
          
          // Get provider info from gift card or default to Amazon
          final provider = data['provider'] as String?;
          final providerId = (provider != null && provider.trim().isNotEmpty) 
              ? provider.trim() 
              : 'amazon';
          
          // Get provider config for name and color
          final providerConfig = GiftCardProviderConfig.getProviderById(providerId);
          final providerName = providerConfig?.name ?? 'Hediye Kartı';
          final providerColor = providerConfig?.primaryColor ?? Colors.green;
          
          // Show in-app notification with provider-specific color
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              _isShowingSnackBar = false;
              return;
            }
            
            // Clear any existing snackbars first
            ScaffoldMessenger.of(context).clearSnackBars();
            
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
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🎉 ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0).format(giftCard.amount)} $providerName hediye kartınız email\'inize gönderildi!',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: providerColor,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Görüntüle',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AmazonGiftCardHistoryPage(),
                      ),
                    );
                  },
                ),
              ),
            ).closed.then((_) {
              // Reset flag when snackbar is dismissed
              if (mounted) {
                _isShowingSnackBar = false;
              }
            });
          });
          
          // Only show one notification at a time
          break;
        } catch (e) {
          debugPrint('❌ Error showing gift card notification: $e');
          _isShowingSnackBar = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<bool>(
      future: CountryDetectionService().shouldShowAmazonRewards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Consumer<PointProvider>(
          builder: (context, pointProvider, child) {
            final pointBalance = pointProvider.balance;
            final currentPoints = pointBalance?.totalPoints ?? 0;

            if (_providers.isEmpty) {
              return const SizedBox.shrink();
            }

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
                borderRadius: BorderRadius.circular(16),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Hediye Kartları',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Page Indicator
                      Row(
                        children: _providers.asMap().entries.map((entry) {
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == entry.key
                                  ? _providers[_currentPage].primaryColor
                                  : isDark
                                      ? const Color(0xFF6D6D70)
                                      : const Color(0xFFA0A0A0),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Provider Cards (Horizontal Swipe)
                  // Use LayoutBuilder to measure content and set appropriate height
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate exact height needed based on content (optimized spacing):
                      // Provider header: ~48px (reduced)
                      // Spacing: 8px
                      // Balance display: ~58px (reduced font sizes)
                      // Spacing: 8px
                      // Progress bar section: ~36px (reduced)
                      // Spacing: 8px
                      // Ad button (always shown): ~50px (increased padding) + 8px margin
                      // Action buttons: ~46px (increased padding)
                      // Add some extra padding for safety: ~6px
                      
                      // Ad button is always visible now, so always include it in height calculation
                      double cardHeight = 48.0 + 8.0 + 58.0 + 8.0 + 26.0 + 8.0 + 50.0 + 8.0 + 40.0 + 6.0;
                      
                      return SizedBox(
                        height: cardHeight,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: _providers.length,
                          itemBuilder: (context, index) {
                            final config = _providers[index];
                            return _buildProviderCard(
                              context,
                              config,
                              currentPoints,
                              isDark,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    GiftCardProviderConfig config,
    int currentPoints,
    bool isDark,
  ) {
    final progress = config.getProgress(currentPoints);
    final remainingPoints = config.getRemainingPoints(currentPoints);
    final canRedeem = config.canRedeem(currentPoints);
    final balanceInTL = currentPoints / 200.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: config.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: _buildProviderIcon(config, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      config.description,
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
          const SizedBox(height: 8),

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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: config.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '≈ ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(balanceInTL)}',
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
                    NumberFormat('#,###').format(config.requiredPoints),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0).format(config.minimumThreshold),
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
          const SizedBox(height: 8),

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
                      fontWeight: FontWeight.w600,
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
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    config.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Watch Ad Button (always visible)
          Consumer<RewardedAdService>(
              builder: (context, rewardedAdService, child) {
                final isReady = rewardedAdService.isAdReady;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: isReady
                        ? LinearGradient(
                            colors: [
                              config.primaryColor,
                              config.accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isReady
                        ? [
                            BoxShadow(
                              color: config.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
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
                          ? () => _showRewardedAd(context, config)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isReady) ...[
                              const Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reklam İzle',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+50',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Yükleniyor...',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
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
                        builder: (context) => const AmazonRewardHistoryPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.history,
                    size: 18,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF6D6D70),
                  ),
                  label: Text(
                    'Geçmiş',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFFE5E5EA),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElegantGiftCardButton(
                  currentPoints: currentPoints,
                  providerConfig: config, // Pass provider config for brand colors
                  onPressed: canRedeem
                      ? () async {
                          // Get current points
                          final pointProvider = Provider.of<PointProvider>(context, listen: false);
                          await pointProvider.refresh();
                          final updatedPoints = pointProvider.currentPoints;
                          
                          // Check if user has enough points for current provider
                          if (!config.canRedeem(updatedPoints)) {
                            // Don't open anything if not enough points
                            return;
                          }
                          
                          // Show gift card request flow
                          await ElegantGiftCardRequestFlow.show(
                            context,
                            updatedPoints,
                            providerConfig: config,
                          );
                        }
                      : () {
                          // Navigate to gift card history page
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
  }

  /// Build provider icon (PNG format)
  /// All icons are rendered at the same size (32x32)
  Widget _buildProviderIcon(GiftCardProviderConfig config, bool isDark) {
    // Use ClipRect to ensure icons don't overflow
    return ClipRect(
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Image.asset(
            config.iconPath,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if asset not found
              return Icon(
                Icons.card_giftcard,
                size: 32,
                color: config.primaryColor,
              );
            },
          ),
        ),
      ),
    );
  }

  /// Show rewarded ad
  Future<void> _showRewardedAd(
    BuildContext context,
    GiftCardProviderConfig config,
  ) async {
    final rewardedAdService =
        Provider.of<RewardedAdService>(context, listen: false);
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
    if (!context.mounted) return;
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

