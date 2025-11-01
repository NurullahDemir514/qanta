import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_colors.dart';

enum PremiumTier { free, premium, premiumPlus }
enum SubscriptionPeriod { monthly, yearly }

/// Premium teklif ekranı - 3 Plan: Free, Premium, Premium Plus
class PremiumOfferScreen extends StatefulWidget {
  final VoidCallback? onPremiumPurchased;
  
  const PremiumOfferScreen({
    super.key,
    this.onPremiumPurchased,
  });

  @override
  State<PremiumOfferScreen> createState() => _PremiumOfferScreenState();
}

class _PremiumOfferScreenState extends State<PremiumOfferScreen> {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly; // Varsayılan: Aylık
  PremiumTier _currentTier = PremiumTier.free; // TODO: Get from PremiumService
  final PageController _pageController = PageController(
    initialPage: 1, // Start at Premium (middle)
    viewportFraction: 0.85,
  );
  
  bool _isLoadingPrices = true;

  // Premium prices (₺49,99/ay, ₺499/yıl %17 indirim)
  String _premiumMonthlyPriceString = '₺49,99';
  String _premiumYearlyPriceString = '₺499';
  double _premiumMonthlyPrice = 49.99;
  double _premiumYearlyPrice = 499.0;

  // Premium Plus prices (₺119,99/ay, ₺1199/yıl %17 indirim)
  String _premiumPlusMonthlyPriceString = '₺119,99';
  String _premiumPlusYearlyPriceString = '₺1199';
  double _premiumPlusMonthlyPrice = 119.99;
  double _premiumPlusYearlyPrice = 1199.0;
  
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadProductPrices();
    _checkCurrentTier();
    _listenToPurchaseUpdates();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _purchaseSubscription.cancel();
    super.dispose();
  }
  
  /// Listen to purchase updates for navigation
  void _listenToPurchaseUpdates() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () => _purchaseSubscription.cancel(),
      onError: (error) {
        debugPrint('❌ PremiumOfferScreen: Purchase stream error: $error');
      },
    );
  }
  
  /// Handle purchase updates and navigate to onboarding
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('📦 PremiumOfferScreen: Purchase update - Status: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Premium satın alındı - onboarding'e yönlendir
        debugPrint('🎉 Purchase completed! Navigating to onboarding...');
        
        if (mounted) {
          // Kısa bir gecikme ile smooth transition
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/premium-onboarding');
            }
          });
        }
      }
    }
  }
  
  /// Check user's current premium tier
  void _checkCurrentTier() {
    final premiumService = context.read<PremiumService>();
    final isPremium = premiumService.isPremium;
    
    setState(() {
      _currentTier = isPremium ? PremiumTier.premium : PremiumTier.free;
      // TODO: Check for Premium Plus when implemented
    });
  }
  
  /// Load prices from Play Store / App Store
  Future<void> _loadProductPrices() async {
    try {
      final InAppPurchase iap = InAppPurchase.instance;
      
      const Set<String> productIds = {
        'qanta_premium_monthly',
        'qanta_premium_yearly',
        'qanta_premium_plus_monthly',
        'qanta_premium_plus_yearly',
      };
      
      debugPrint('💰 Loading product prices from Play Store...');
      
      final ProductDetailsResponse response = await iap
          .queryProductDetails(productIds)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Price loading timeout - using fallback prices');
              return ProductDetailsResponse(
                productDetails: [],
                notFoundIDs: productIds.toList(),
              );
            },
          );
      
      if (response.productDetails.isNotEmpty) {
        debugPrint('✅ Loaded ${response.productDetails.length} products');
        
        for (final product in response.productDetails) {
          debugPrint('💳 ${product.id}: ${product.price} (raw: ${product.rawPrice})');
          
          switch (product.id) {
            case 'qanta_premium_monthly':
              _premiumMonthlyPriceString = product.price;
              _premiumMonthlyPrice = product.rawPrice;
              break;
            case 'qanta_premium_yearly':
              _premiumYearlyPriceString = product.price;
              _premiumYearlyPrice = product.rawPrice;
              break;
            case 'qanta_premium_plus_monthly':
              _premiumPlusMonthlyPriceString = product.price;
              _premiumPlusMonthlyPrice = product.rawPrice;
              break;
            case 'qanta_premium_plus_yearly':
              _premiumPlusYearlyPriceString = product.price;
              _premiumPlusYearlyPrice = product.rawPrice;
              break;
          }
        }
        
        debugPrint('💰 Final Prices:');
        debugPrint('  Premium Monthly: $_premiumMonthlyPriceString ($_premiumMonthlyPrice)');
        debugPrint('  Premium Yearly: $_premiumYearlyPriceString ($_premiumYearlyPrice)');
        debugPrint('  Premium Plus Monthly: $_premiumPlusMonthlyPriceString ($_premiumPlusMonthlyPrice)');
        debugPrint('  Premium Plus Yearly: $_premiumPlusYearlyPriceString ($_premiumPlusYearlyPrice)');
      } else {
        debugPrint('⚠️ No products found. Missing IDs: ${response.notFoundIDs}');
        debugPrint('📝 Using fallback prices');
      }
    } catch (e) {
      debugPrint('❌ Error loading prices: $e');
      debugPrint('📝 Using fallback prices');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrices = false);
      }
    }
  }
  
  /// Calculate discount percentage for yearly plans
  int _calculateDiscount(double monthlyPrice, double yearlyPrice) {
    if (monthlyPrice == 0) return 17;
    final yearlyIfMonthly = monthlyPrice * 12;
    final discount = yearlyIfMonthly - yearlyPrice;
    return (discount / yearlyIfMonthly * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
                  onPressed: () => context.pop(),
        ),
        actions: [
          // DEBUG: Test Onboarding butonu
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.preview,
                color: isDark ? Colors.white70 : AppColors.primary,
              ),
              tooltip: 'Test Premium Onboarding',
              onPressed: () {
                context.go('/premium-onboarding');
              },
            ),
        ],
      ),
      body: Column(
                  children: [
          // Header
          _buildHeader(l10n, isDark),
          
          SizedBox(height: 24.h),
          
          // Period Toggle (Monthly ↔ Yearly)
          _buildPeriodToggle(l10n, isDark),
          
          SizedBox(height: 32.h),
          
          // Plan Cards (Swipeable)
            Expanded(
            child: _buildPlanCards(l10n, isDark),
          ),
          
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
  
  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Text(
            l10n.premiumOfferTitle,
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          ...[
            SizedBox(height: 8.h),
            Text(
              l10n.unlockAllFeatures,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPeriodToggle(AppLocalizations l10n, bool isDark) {
    final premiumDiscount = _calculateDiscount(_premiumMonthlyPrice, _premiumYearlyPrice);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
            child: _buildPeriodOption(
              l10n.monthly,
              SubscriptionPeriod.monthly,
              isDark,
            ),
          ),
          Expanded(
            child: _buildPeriodOption(
              l10n.yearly,
              SubscriptionPeriod.yearly,
              isDark,
              badge: l10n.savePercentage(premiumDiscount),
            ),
                                          ),
                                  ],
                                ),
    );
  }
  
  Widget _buildPeriodOption(
    String label,
    SubscriptionPeriod period,
    bool isDark, {
    String? badge,
  }) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                                decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
                                      : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
            Text(
              label,
                                      style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textDark)
                    : (isDark ? Colors.white60 : AppColors.textLight),
              ),
            ),
            if (badge != null && isSelected) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700), // Gold
                      Color(0xFFFFA500), // Orange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA500).withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                                            style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
                                  ],
                                ),
                              ),
    );
  }
  
  Widget _buildPlanCards(AppLocalizations l10n, bool isDark) {
    return PageView(
      controller: _pageController,
                                            children: [
        _buildPlanCard(
          tier: PremiumTier.free,
          name: l10n.planFree,
          description: l10n.planFreeDescription,
          price: 0,
          features: [
            _PlanFeature(Icons.auto_awesome, l10n.featureAIMessagesPerDay('10')),
            _PlanFeature(Icons.credit_card, l10n.featureLimitedCards('3')),
            _PlanFeature(Icons.trending_up, l10n.featureLimitedStocks('3')),
            _PlanFeature(Icons.ads_click, l10n.featureWithAds),
            _PlanFeature(Icons.support_agent, l10n.featureBasicSupport),
          ],
          l10n: l10n,
          isDark: isDark,
        ),
        _buildPlanCard(
          tier: PremiumTier.premium,
          name: l10n.planPremium,
          description: l10n.planPremiumDescription,
          price: _selectedPeriod == SubscriptionPeriod.monthly
              ? _premiumMonthlyPrice
              : _premiumYearlyPrice,
          priceString: _selectedPeriod == SubscriptionPeriod.monthly
              ? _premiumMonthlyPriceString
              : _premiumYearlyPriceString,
          features: [
            _PlanFeature(Icons.auto_awesome, l10n.featureAIMessagesPerDay('1500')),
            _PlanFeature(Icons.credit_card, l10n.featureUnlimitedCards),
            _PlanFeature(Icons.trending_up, l10n.featureUnlimitedStocks),
            _PlanFeature(Icons.block, l10n.featureNoAds),
            _PlanFeature(Icons.support, l10n.featurePrioritySupport),
          ],
          isPopular: true,
          l10n: l10n,
          isDark: isDark,
        ),
        _buildPlanCard(
          tier: PremiumTier.premiumPlus,
          name: l10n.planPremiumPlus,
          description: l10n.planPremiumPlusDescription,
          price: _selectedPeriod == SubscriptionPeriod.monthly
              ? _premiumPlusMonthlyPrice
              : _premiumPlusYearlyPrice,
          priceString: _selectedPeriod == SubscriptionPeriod.monthly
              ? _premiumPlusMonthlyPriceString
              : _premiumPlusYearlyPriceString,
          features: [
            _PlanFeature(Icons.auto_awesome, l10n.featureAIMessagesPerDay('3000')),
            _PlanFeature(Icons.credit_card, l10n.featureUnlimitedCards),
            _PlanFeature(Icons.trending_up, l10n.featureUnlimitedStocks),
            _PlanFeature(Icons.block, l10n.featureNoAds),
            _PlanFeature(Icons.support_agent, l10n.feature247Support),
            _PlanFeature(Icons.rocket_launch, l10n.featureEarlyAccessDescription),
          ],
          l10n: l10n,
          isDark: isDark,
        ),
      ],
    );
  }
  
  Widget _buildPlanCard({
    required PremiumTier tier,
    required String name,
    required String description,
    required double price,
    String? priceString, // Play Store formatted price
    required List<_PlanFeature> features,
    required AppLocalizations l10n,
    required bool isDark,
    bool isPopular = false,
  }) {
    final isCurrent = _currentTier == tier;
    final isYearly = _selectedPeriod == SubscriptionPeriod.yearly;
    
    // Use Play Store formatted price if available, otherwise format manually
    final displayPrice = priceString ?? '₺${price.toStringAsFixed(2).replaceAll('.00', '')}';
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                                decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: isPopular
            ? Border.all(color: const Color(0xFFFFD700), width: 2.5)
                                      : null,
                        boxShadow: [
                                          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
      child: Stack(
                                  children: [
          // Popular Badge
          if (isPopular)
            Positioned(
              top: 16.h,
              left: 0,
              right: 0,
                                  child: Center(
                                    child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                              colors: [
                        Color(0xFFFFD700), // Gold
                        Color(0xFFFFA500), // Orange
                                              ],
                                            ),
                    borderRadius: BorderRadius.circular(20.r),
                                            boxShadow: [
                                              BoxShadow(
                        color: const Color(0xFFFFA500).withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                    l10n.mostPopular,
                                            style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                                ),
                                            ),
                                          ),
                                        ),
                                ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                if (isPopular) SizedBox(height: 36.h),
                
                // Plan Name
                    Text(
                  name,
                      style: GoogleFonts.inter(
                    fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),

                SizedBox(height: 4.h),

                // Description
                    Text(
                  description,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                    color: isDark ? Colors.white60 : AppColors.textLight,
                      ),
                    ),

                    SizedBox(height: 24.h),

                // Price
                if (tier == PremiumTier.free)
                  Text(
                    l10n.freeVersion,
                    style: GoogleFonts.inter(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  )
                else
                  Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                      Text(
                        displayPrice,
                                                style: GoogleFonts.inter(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                                                child: Text(
                          isYearly ? l10n.perYear : l10n.perMonth,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: isDark ? Colors.white60 : AppColors.textLight,
                                                  ),
                                                ),
                                              ),
                    ],
                  ),
                
                if (tier != PremiumTier.free && isYearly) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '₺${(price / 12).toStringAsFixed(2)} ${l10n.perMonth}',
                                                style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: isDark ? Colors.white60 : AppColors.textLight,
                    ),
                  ),
                ],
                
                SizedBox(height: 32.h),
                
                // Features
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: features.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return Row(
                                            children: [
                          Icon(
                            feature.icon,
                            size: 20.w,
                            color: isPopular ? const Color(0xFFFFA500) : AppColors.primary,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                                                child: Text(
                              feature.label,
                                                style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                      ),
                    ),

                    SizedBox(height: 24.h),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: isCurrent
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white30 : AppColors.textLight,
                            ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                                    child: Text(
                            l10n.currentPlan,
                                      style: GoogleFonts.inter(
                              fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : AppColors.textLight,
                            ),
                          ),
                        )
                      : Container(
                          decoration: isPopular
                              ? BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                      Color(0xFFFFD700), // Gold
                                      Color(0xFFFFA500), // Orange
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                      color: const Color(0xFFFFA500).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null,
                          child: ElevatedButton(
                            onPressed: tier == PremiumTier.free
                                ? () => context.pop()
                                : () => _selectPlan(tier),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPopular
                                  ? Colors.transparent
                                  : (isDark ? AppColors.primary : AppColors.primary),
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                                      ),
                                      child: Text(
                              tier == PremiumTier.free
                                  ? l10n.continueWithFree
                                  : l10n.choosePlan,
                                        style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPlan(PremiumTier tier) async {
    final l10n = AppLocalizations.of(context)!;
    final premiumService = context.read<PremiumService>();
    
    debugPrint('🛒 Selected plan: $tier (${_selectedPeriod.name})');
    
    try {
      // Satın alma işlemini başlat
      final isYearly = _selectedPeriod == SubscriptionPeriod.yearly;
      final isPremiumPlus = tier == PremiumTier.premiumPlus;
      
      final bool success = await premiumService.purchasePremium(
        isYearly: isYearly,
        isPremiumPlus: isPremiumPlus,
      );
      
      if (!success) {
        // Satın alma başlatılamadı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        // Satın alma başlatıldı, kullanıcı Play Store dialog'unda
        debugPrint('✅ Purchase flow started successfully');
      }
    } catch (e) {
      debugPrint('❌ Error starting purchase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _PlanFeature {
  final IconData icon;
  final String label;
  
  _PlanFeature(this.icon, this.label);
}
