import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/recurring_transaction_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/recurring_transaction_model.dart';
import '../../../modules/transactions/models/recurring_frequency.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';
import '../widgets/subscription_card.dart';
import '../widgets/add_subscription_form.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../../../modules/transactions/widgets/quick_add_chat_fab.dart';
import '../../../core/services/country_detection_service.dart';

class SubscriptionsManagementPage extends StatefulWidget {
  const SubscriptionsManagementPage({super.key});

  @override
  State<SubscriptionsManagementPage> createState() => _SubscriptionsManagementPageState();
}

class _SubscriptionsManagementPageState extends State<SubscriptionsManagementPage> {
  bool _showInactiveSubscriptions = false;
  late GoogleAdsRealBannerService _subscriptionBannerService;

  @override
  void initState() {
    super.initState();
    _subscriptionBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.budgetManagementBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    // Banner'ı yükle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _subscriptionBannerService.loadAd();
      }
    });
    
    // Load subscriptions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecurringTransactionProvider>(context, listen: false)
          .loadSubscriptions();
    });
  }

  @override
  void dispose() {
    _subscriptionBannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: Text(
          l10n.subscriptions,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Consumer<RecurringTransactionProvider>(
            builder: (context, provider, child) {
              final activeSubscriptions = provider.activeSubscriptions;
              final inactiveSubscriptions = provider.inactiveSubscriptions;
              final allSubscriptions = [...activeSubscriptions, ...inactiveSubscriptions];
              final allEmpty = allSubscriptions.isEmpty;

              if (allEmpty) {
                return _buildSubscriptionsEmptyState(isDark);
              }

              return Column(
                children: [
                  // Summary Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _buildSubscriptionsSummaryCard(isDark),
                  ),
                  const SizedBox(height: 8),
                  
                  // Content
                  Expanded(
                    child: _buildSubscriptionsContent(isDark, activeSubscriptions, inactiveSubscriptions),
                  ),
                  
                  // Banner Reklam (Premium olmayanlara göster)
                  Consumer<PremiumService>(
                    builder: (context, premiumService, child) {
                      if (!premiumService.isPremium && 
                          _subscriptionBannerService.isLoaded && 
                          _subscriptionBannerService.bannerWidget != null) {
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: _subscriptionBannerService.bannerWidget!,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
          
          // FABs (AI + Add Subscription)
          _buildFABStack(isDark),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsContent(
    bool isDark,
    List<RecurringTransaction> activeSubscriptions,
    List<RecurringTransaction> inactiveSubscriptions,
  ) {
    // Calculate item count
    int itemCount = 1; // Aktif Abonelikler header
    itemCount += activeSubscriptions.length;
    if (inactiveSubscriptions.isNotEmpty) {
      itemCount += 1; // Pasif Abonelikler header
      if (_showInactiveSubscriptions) {
        itemCount += inactiveSubscriptions.length;
      }
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final l10n = AppLocalizations.of(context)!;
        final provider = Provider.of<RecurringTransactionProvider>(context);
        
        // Aktif Abonelikler header (index 0)
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.activeSubscriptions,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
            ),
          );
        }
        
        // Aktif subscription'ları göster
        if (index > 0 && index <= activeSubscriptions.length) {
          final subscriptionIndex = index - 1;
          final subscription = activeSubscriptions[subscriptionIndex];
          return SubscriptionCard(
            subscription: subscription,
            onTap: () {
              // TODO: Navigate to subscription detail
            },
            onToggle: (isActive) {
              provider.toggleActiveStatus(subscription.id, isActive);
            },
            onDelete: () {
              _deleteSubscription(context, subscription, provider);
            },
          );
        }
        
        // Pasif Abonelikler header'ı
        if (inactiveSubscriptions.isNotEmpty && index == activeSubscriptions.length + 1) {
          return Column(
            children: [
              if (index > 0) const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showInactiveSubscriptions = !_showInactiveSubscriptions;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        size: 16,
                        color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.inactiveSubscriptionsWithCount(inactiveSubscriptions.length),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showInactiveSubscriptions
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // Pasif subscription'ları göster
        if (_showInactiveSubscriptions && 
            index > activeSubscriptions.length + 1) {
          final inactiveIndex = index - activeSubscriptions.length - 2;
          if (inactiveIndex < inactiveSubscriptions.length) {
            final subscription = inactiveSubscriptions[inactiveIndex];
            return SubscriptionCard(
              subscription: subscription,
              onTap: () {
                // TODO: Navigate to subscription detail
              },
              onToggle: (isActive) {
                provider.toggleActiveStatus(subscription.id, isActive);
              },
              onDelete: () {
                _deleteSubscription(context, subscription, provider);
              },
            );
          }
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSubscriptionsSummaryCard(bool isDark) {
    return Consumer2<RecurringTransactionProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        final subscriptions = provider.activeSubscriptions;
        
        // Calculations
        final totalMonthly = _calculateTotalMonthly(subscriptions);
        final totalYearly = _calculateTotalYearly(subscriptions);
        final activeCount = subscriptions.length;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF6E48AA), // Mor (koyu)
                      const Color(0xFF9D50BB),
                      const Color(0xFF6E48AA),
                    ]
                  : [
                      const Color(0xFF9D50BB), // Mor (açık)
                      const Color(0xFF6E48AA),
                      const Color(0xFF8E44AD),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9D50BB).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side: Icon and labels
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.subscriptions,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.monthlyTotal,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$activeCount ${l10n.active}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Right side: Amount and yearly info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Monthly amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            CurrencyUtils.formatAmount(totalMonthly, themeProvider.currency),
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.perMonth,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Yearly projection
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.yearlyPrefix} ${CurrencyUtils.formatAmount(totalYearly, themeProvider.currency)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Calculate total monthly amount
  double _calculateTotalMonthly(List<RecurringTransaction> subscriptions) {
    return subscriptions.fold<double>(0, (sum, sub) {
      switch (sub.frequency) {
        case RecurringFrequency.weekly:
          return sum + (sub.amount * 4.33); // Ortalama hafta sayısı
        case RecurringFrequency.monthly:
          return sum + sub.amount;
        case RecurringFrequency.quarterly:
          return sum + (sub.amount / 3); // 3 ayda bir
        case RecurringFrequency.yearly:
          return sum + (sub.amount / 12); // 12 ayda bir
      }
    });
  }

  /// Calculate total yearly amount
  double _calculateTotalYearly(List<RecurringTransaction> subscriptions) {
    return subscriptions.fold<double>(0, (sum, sub) {
      switch (sub.frequency) {
        case RecurringFrequency.weekly:
          return sum + (sub.amount * 52);
        case RecurringFrequency.monthly:
          return sum + (sub.amount * 12);
        case RecurringFrequency.quarterly:
          return sum + (sub.amount * 4);
        case RecurringFrequency.yearly:
          return sum + sub.amount;
      }
    });
  }

  /// Subscriptions Empty State
  Widget _buildSubscriptionsEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noSubscriptionsYet,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstSubscriptionDescription,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            // Reward message for Turkish users
            FutureBuilder<bool>(
              future: CountryDetectionService().isTurkishPlayStoreUser(),
              builder: (context, snapshot) {
                final isTurkish = snapshot.data ?? false;
                if (!isTurkish) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.shade500.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: Colors.green.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.firstSubscriptionRewardMessage,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showAddSubscriptionBottomSheet(context),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l10n.addSubscription,
                          style: GoogleFonts.inter(
                            fontSize: 14,
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
    );
  }

  void _showAddSubscriptionBottomSheet(BuildContext context) async {
    // 2025 Best Practice: Request permission when user adds subscription (context-aware)
    final hasPermission = await NotificationService().hasNotificationPermission;
    
    if (!hasPermission) {
      // Show explanatory dialog before requesting permission
      final shouldRequest = await _showNotificationPermissionDialog(context);
      if (shouldRequest == true && context.mounted) {
        await NotificationService().requestNotificationPermission(context);
      } else if (shouldRequest == false) {
        // User declined, but still allow adding subscription
        // Just show a subtle warning
      }
    }
    
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddSubscriptionForm(
          onSubscriptionSaved: () {
            final provider = Provider.of<RecurringTransactionProvider>(
              context,
              listen: false,
            );
            provider.loadSubscriptions();
          },
        ),
      );
    }
  }
  
  /// Show notification permission explanation dialog (2025 best practice)
  Future<bool?> _showNotificationPermissionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.enableNotifications ?? 'Bildirimleri Etkinleştir',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.subscriptionNotificationPermissionMessage ?? 
          'Abonelik ödemeleri için otomatik bildirim almak ister misiniz? Bildirimler, ödemelerin ne zaman yapıldığını ve bir sonraki ödeme tarihini hatırlatır.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.notNow ?? 'Şimdi Değil',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.enable ?? 'Etkinleştir',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Delete subscription
  Future<void> _deleteSubscription(
    BuildContext context,
    RecurringTransaction subscription,
    RecurringTransactionProvider provider,
  ) async {
    try {
      HapticFeedback.heavyImpact();
      
      final success = await provider.deleteSubscription(subscription.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (AppLocalizations.of(context)!.subscriptionDeleted ?? 'Abonelik silindi')
                  : (AppLocalizations.of(context)!.errorOccurred ?? 'Hata oluştu'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: success ? Colors.green.shade500 : const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorOccurred}: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildFABStack(bool isDark) {
    final fabSize = FabPositioning.getFabSize(context);
    final iconSize = FabPositioning.getIconSize(context);
    final rightPosition = FabPositioning.getRightPosition(context);
    
    // Subscriptions sayfasında navbar yok, FAB'lar ekranın dibine yakın olmalı
    // Safe area (home indicator) üstüne konumlandır
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final bottomPosition = safeAreaBottom + 16.0; // Safe area + 16px padding
    
    return Stack(
      children: [
        // AI Chat FAB (her zaman görünür, üstte)
        Positioned(
          right: rightPosition,
          bottom: bottomPosition + 70,
          child: const QuickAddChatFAB(),
        ),
        
        // Add Subscription FAB
        Positioned(
          right: rightPosition,
          bottom: bottomPosition,
          child: GestureDetector(
            onTap: () => _showAddSubscriptionBottomSheet(context),
            child: Container(
              width: fabSize,
              height: fabSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF007AFF),
                    Color(0xFF0051D5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

