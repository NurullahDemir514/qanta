import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/premium_service.dart';
import '../../shared/utils/currency_utils.dart';

/// Premium teklif ekranı - Free vs Premium karşılaştırması
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
  bool _isYearly = true; // Varsayılan olarak yıllık seçili (daha iyi değer)
  bool _isLoadingPrices = true;
  String _monthlyPrice = '₺9,99'; // Fallback
  String _yearlyPrice = '₺99,99'; // Fallback
  double _monthlyPriceValue = 9.99; // Hesaplama için
  double _yearlyPriceValue = 99.99; // Hesaplama için
  
  @override
  void initState() {
    super.initState();
    _loadProductPrices();
  }
  
  /// Yıllık plandaki indirim oranını hesapla
  int _calculateDiscountPercentage() {
    if (_monthlyPriceValue == 0) return 17; // Fallback
    
    final yearlyIfMonthly = _monthlyPriceValue * 12;
    final discount = yearlyIfMonthly - _yearlyPriceValue;
    final percentage = (discount / yearlyIfMonthly * 100).round();
    
    return percentage;
  }
  
  /// Play Store'dan gerçek fiyatları yükle
  Future<void> _loadProductPrices() async {
    try {
      final InAppPurchase iap = InAppPurchase.instance;
      
      // Ürün ID'leri
      const Set<String> productIds = {
        'qanta_premium_monthly',
        'qanta_premium_yearly',
      };
      
      // 3 saniye timeout ile ürün bilgilerini çek
      final ProductDetailsResponse response = await iap
          .queryProductDetails(productIds)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏱️ Price loading timeout - using fallback prices');
              return ProductDetailsResponse(
                productDetails: [],
                notFoundIDs: productIds.toList(),
              );
            },
          );
      
      if (response.productDetails.isNotEmpty) {
        for (final product in response.productDetails) {
          if (product.id == 'qanta_premium_monthly') {
            _monthlyPrice = product.price; // Örn: "₺9,99" veya "$9.99"
            _monthlyPriceValue = product.rawPrice; // Numeric değer
          } else if (product.id == 'qanta_premium_yearly') {
            _yearlyPrice = product.price;
            _yearlyPriceValue = product.rawPrice;
          }
        }
        debugPrint('💰 Prices loaded: Monthly=$_monthlyPrice ($_monthlyPriceValue), Yearly=$_yearlyPrice ($_yearlyPriceValue)');
      } else {
        debugPrint('⚠️ No product details found (${response.notFoundIDs}), using fallback prices');
      }
    } catch (e) {
      debugPrint('❌ Error loading prices: $e');
      // Fallback fiyatları zaten set edildi
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrices = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumService = context.watch<PremiumService>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: IconButton(
                  icon: Icon(Icons.close, size: 20.sp),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark 
                        ? const Color(0xFF1C1C1E) 
                        : Colors.white,
                    padding: EdgeInsets.all(8.r),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    
                    // Premium Icon
                    Container(
                      width: 70.r,
                      height: 70.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA500).withOpacity(0.3),
                            blurRadius: 20.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        size: 40.sp,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Title
                    Text(
                      l10n.premiumOfferTitle,
                      style: GoogleFonts.inter(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    // Subtitle
                    Text(
                      l10n.premiumOfferSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Subscription Plan Selector (Aylık/Yıllık) - Compact & Elegant
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1C1C1E) 
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          // Monthly Plan
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isYearly) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isYearly = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 8.w,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isYearly
                                      ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: !_isYearly
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2.h),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: !_isYearly 
                                            ? FontWeight.w600 
                                            : FontWeight.w500,
                                        color: !_isYearly
                                            ? (isDark ? Colors.white : Colors.black87)
                                            : (isDark ? Colors.white60 : Colors.black45),
                                        letterSpacing: 0.1,
                                      ),
                                      child: Text(l10n.monthly),
                                    ),
                                    SizedBox(height: 3.h),
                                    _isLoadingPrices
                                        ? SizedBox(
                                            height: 18.sp,
                                            width: 18.sp,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          )
                                        : AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            style: GoogleFonts.inter(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : Colors.black87,
                                              letterSpacing: -0.5,
                                            ),
                                            child: Text(_monthlyPrice),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 4.w),
                          
                          // Yearly Plan (Best Value)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isYearly) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isYearly = true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 8.w,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isYearly
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                          ],
                                        )
                                      : null,
                                  color: !_isYearly
                                      ? Colors.transparent
                                      : null,
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: _isYearly
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFFA500).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: Offset(0, 4.h),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: _isYearly 
                                                ? FontWeight.w600 
                                                : FontWeight.w500,
                                            color: _isYearly
                                                ? Colors.white
                                                : (isDark ? Colors.white60 : Colors.black45),
                                            letterSpacing: 0.1,
                                          ),
                                          child: Text(l10n.yearly),
                                        ),
                                        SizedBox(width: 4.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 5.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B35), // Turuncu-kırmızı
                                                Color(0xFFFF8E53), // Açık turuncu
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(4.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${_calculateDiscountPercentage()}%',
                                            style: GoogleFonts.inter(
                                              fontSize: 8.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.25),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3.h),
                                    _isLoadingPrices
                                        ? SizedBox(
                                            height: 18.sp,
                                            width: 18.sp,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Normal fiyat (üzeri çizili)
                                              AnimatedDefaultTextStyle(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeOutCubic,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: _isYearly
                                                      ? Colors.white
                                                      : (isDark ? Colors.white60 : Colors.black45),
                                                  letterSpacing: -0.3,
                                                  decoration: TextDecoration.lineThrough,
                                                  decorationColor: _isYearly
                                                      ? Colors.white
                                                      : (isDark ? Colors.white60 : Colors.black45),
                                                  decorationThickness: 2,
                                                ),
                                                child: Text(
                                                  CurrencyUtils.formatAmount(
                                                    _monthlyPriceValue * 12,
                                                    Currency.TRY,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              // İndirimli fiyat
                                              AnimatedDefaultTextStyle(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeOutCubic,
                                                style: GoogleFonts.inter(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: _isYearly
                                                      ? Colors.white
                                                      : (isDark ? Colors.white : Colors.black87),
                                                  letterSpacing: -0.5,
                                                ),
                                                child: Text(_yearlyPrice),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Comparison Table
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF38383A).withOpacity(0.3)
                              : const Color(0xFFE5E5EA).withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                topRight: Radius.circular(16.r),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark 
                                      ? const Color(0xFF38383A).withOpacity(0.3)
                                      : const Color(0xFFE5E5EA).withOpacity(0.4),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(width: 1.w),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      l10n.freeVersion,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark 
                                            ? const Color(0xFF98989D)
                                            : const Color(0xFF8E8E93),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFA500).withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        l10n.premiumVersion,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Features
                          _buildFeatureRow(
                            context,
                            l10n.featureCardLimit,
                            l10n.featureCardLimitFree,
                            l10n.featureCardLimitPremium,
                            Icons.credit_card,
                            isDark,
                          ),
                          _buildDivider(isDark),
                          _buildFeatureRow(
                            context,
                            l10n.featureStockLimit,
                            l10n.featureStockLimitFree,
                            l10n.featureStockLimitPremium,
                            Icons.trending_up,
                            isDark,
                          ),
                          _buildDivider(isDark),
                          _buildFeatureRow(
                            context,
                            l10n.featureAds,
                            l10n.featureAdsFree,
                            l10n.featureAdsPremium,
                            Icons.ads_click,
                            isDark,
                          ),
                          _buildDivider(isDark),
                          _buildFeatureRow(
                            context,
                            l10n.featureSupport,
                            l10n.featureSupportFree,
                            l10n.featureSupportPremium,
                            Icons.support_agent,
                            isDark,
                          ),
                          _buildDivider(isDark),
                          _buildFeatureRow(
                            context,
                            l10n.featureUpdates,
                            l10n.featureUpdatesFree,
                            l10n.featureUpdatesPremium,
                            Icons.update,
                            isDark,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // Premium Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Gerçek IAP satın alma
                          final premiumService = context.read<PremiumService>();
                          
                          // Loading göster
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFD700),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      l10n.loading ?? 'Yükleniyor...',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: isDark ? Colors.white : Colors.black,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          
                          try {
                            final success = await premiumService.purchasePremium(
                              isYearly: _isYearly,
                            );
                            
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              
                              if (success) {
                                // Başarılı satın alma
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🎉 Premium aktif! Tüm özellikler açıldı.',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                
                                if (widget.onPremiumPurchased != null) {
                                  widget.onPremiumPurchased!();
                                }
                                Navigator.pop(context); // Close offer screen
                              } else {
                                // Satın alma iptal/başarısız
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Satın alma tamamlanamadı',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: const Color(0xFFFF4C4C),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Hata: ${e.toString()}',
                                    style: GoogleFonts.inter(),
                                  ),
                                  backgroundColor: const Color(0xFFFF4C4C),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.getQantaPremium,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Continue with Free button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      child: Text(
                        l10n.continueWithFree,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    String feature,
    String freeValue,
    String premiumValue,
    IconData icon,
    bool isDark, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: isLast ? 16.h : 12.h,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF3A3A3C),
                              const Color(0xFF2C2C2E),
                            ]
                          : [
                              const Color(0xFFF5F5F5),
                              const Color(0xFFE8E8E8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(
                    icon,
                    size: 15.sp,
                    color: isDark 
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF6D6D70),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? Colors.white.withOpacity(0.87)
                          : Colors.black.withOpacity(0.87),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                freeValue,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93),
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFFFFD700).withOpacity(0.15),
                            const Color(0xFFFFA500).withOpacity(0.15),
                          ]
                        : [
                            const Color(0xFFFFD700).withOpacity(0.1),
                            const Color(0xFFFFA500).withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  premiumValue,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFD4AF37),
                    letterSpacing: -0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF38383A).withOpacity(0.3),
                    const Color(0xFF38383A).withOpacity(0.6),
                    const Color(0xFF38383A).withOpacity(0.3),
                  ]
                : [
                    const Color(0xFFE5E5EA).withOpacity(0.3),
                    const Color(0xFFE5E5EA).withOpacity(0.6),
                    const Color(0xFFE5E5EA).withOpacity(0.3),
                  ],
          ),
        ),
      ),
    );
  }
}

