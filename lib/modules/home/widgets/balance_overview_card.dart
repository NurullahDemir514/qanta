import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/utils/screen_compatibility.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';
import '../../cards/widgets/add_debit_card_form.dart';
import '../../cards/widgets/add_credit_card_form.dart';
import '../../stocks/providers/stock_provider.dart';
import '../../../shared/models/account_model.dart';
import '../../premium/premium_offer_screen.dart';

class BalanceOverviewCard extends StatefulWidget {
  final Key? tutorialKey; // Tutorial için key - sadece Balance Card için
  
  const BalanceOverviewCard({
    super.key,
    this.tutorialKey,
  });

  @override
  State<BalanceOverviewCard> createState() => _BalanceOverviewCardState();
}

class _BalanceOverviewCardState extends State<BalanceOverviewCard> {
  bool _includeInvestments = true; // Varsayılan olarak yatırımlar dahil
  late GoogleAdsRealBannerService _bannerService;

  @override
  void initState() {
    super.initState();
    _bannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.production.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Debug bilgisi
    debugPrint('🔄 TOPLAM VARLIK Banner reklam yükleniyor...');
    debugPrint('📱 Ad Unit ID: ${config.AdvertisementConfig.production.bannerAdUnitId}');
    debugPrint('🧪 Test Mode: false');
    debugPrint('📍 Konum: Toplam Varlık kartı altı');
    
    _bannerService.loadAd();
    
    // Hisse değişimlerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStockChanges();
    });
  }

  /// Hisse değişimlerini yükle
  Future<void> _loadStockChanges() async {
    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await Future.wait([
        stockProvider.loadStockChanges7Days(),
        stockProvider.loadStockChanges30Days(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading stock changes: $e');
    }
  }

  @override
  void dispose() {
    _bannerService.dispose();
    super.dispose();
  }

  // Responsive font size calculation based on number of digits
  double _calculateResponsiveFontSize(BuildContext context, double amount, {bool isDecimal = false}) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    // Get the number of digits in the main part (before decimal)
    final formatted = amount.toStringAsFixed(2);
    final mainPart = formatted.split('.')[0];
    final digitCount = mainPart.length;
    
    // Base font sizes for different screen sizes (reduced by 15%)
    final baseAmountSize = isSmallScreen ? 24.0 : 
                          screenSize == ScreenSizeCategory.medium ? 27.0 :
                          screenSize == ScreenSizeCategory.large ? 30.0 : 34.0;
    
    final baseDecimalSize = isSmallScreen ? 14.0 :
                           screenSize == ScreenSizeCategory.medium ? 15.0 :
                           screenSize == ScreenSizeCategory.large ? 17.0 : 19.0;
    
    // Minimum font sizes to ensure readability (reduced by 15%)
    final minAmountSize = isSmallScreen ? 14.0 : 16.0;
    final minDecimalSize = isSmallScreen ? 9.0 : 11.0;
    
    // Calculate responsive size based on digit count
    double responsiveSize;
    if (isDecimal) {
      // Decimal part scaling - 5 basamaktan sonra her basamakta %5 azalma
      if (digitCount <= 5) {
        responsiveSize = baseDecimalSize;
      } else {
        // 5 basamaktan sonra her basamak için %5 azalma
        final extraDigits = digitCount - 5;
        final reductionFactor = math.pow(0.95, extraDigits);
        responsiveSize = baseDecimalSize * reductionFactor;
      }
      
      // Apply minimum size constraint
      responsiveSize = math.max(responsiveSize, minDecimalSize);
    } else {
      // Main amount scaling - 5 basamaktan sonra her basamakta %5 azalma
      if (digitCount <= 5) {
        responsiveSize = baseAmountSize;
      } else {
        // 5 basamaktan sonra her basamak için %5 azalma
        final extraDigits = digitCount - 5;
        final reductionFactor = math.pow(0.95, extraDigits);
        responsiveSize = baseAmountSize * reductionFactor;
      }
      
      // Apply minimum size constraint
      responsiveSize = math.max(responsiveSize, minAmountSize);
    }
    
    return ScreenCompatibility.responsiveFontSize(context, responsiveSize);
  }

  /// Hisse değişimlerini hesapla (sadece bugün)
  Map<String, double> _calculateStockChanges(UnifiedProviderV2 provider, StockProvider stockProvider) {
    final Map<String, double> changes = {
      'today': 0.0,
    };

    if (!_includeInvestments || provider.stockPositions.isEmpty) {
      return changes;
    }

    double totalTodayChange = 0.0;
    double totalStockValue = 0.0;

    for (final position in provider.stockPositions) {
      final stockValue = position.currentValue;
      totalStockValue += stockValue;

      // Bugünkü değişim - sadece yüzde değeri
      final todayChangePercent = stockProvider.getStockChangeToday(position.stockSymbol);
      totalTodayChange += todayChangePercent;
    }

    if (totalStockValue > 0) {
      // Ağırlıklı ortalama değişim yüzdesi
      changes['today'] = (totalTodayChange / totalStockValue) * 100;
    }

    return changes;
  }

  /// Bu ayki günlük ortalama harcama hesapla (ilk işlemi referans al)
  double _calculateMonthlyDailyAverageSpending(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    // Bu ayki giderleri hesapla
    final monthlyExpenses = provider.transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.transactionDate.isAfter(startOfMonth) &&
            t.transactionDate.isBefore(endOfMonth))
        .toList();
    
    if (monthlyExpenses.isEmpty) return 0.0;
    
    final totalExpenses = monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);
    
    // İlk işlemi referans al
    final firstTransaction = monthlyExpenses.reduce((a, b) => 
        a.transactionDate.isBefore(b.transactionDate) ? a : b);
    final firstTransactionDate = firstTransaction.transactionDate;
    
    // İlk işlemden bugüne kadar geçen gün sayısı
    final daysSinceFirstTransaction = now.difference(firstTransactionDate).inDays + 1;
    
    // Günlük ortalama harcama (ilk işlemden itibaren)
    return daysSinceFirstTransaction > 0 ? totalExpenses / daysSinceFirstTransaction : 0.0;
  }

  /// Genel günlük ortalama harcama hesapla (ilk işlemi referans al)
  double _calculateGeneralDailyAverageSpending(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    
    // Tüm giderleri al
    final allExpenses = provider.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    if (allExpenses.isEmpty) return 0.0;
    
    // İlk işlemi referans al
    final firstTransaction = allExpenses.reduce((a, b) => 
        a.transactionDate.isBefore(b.transactionDate) ? a : b);
    final firstTransactionDate = firstTransaction.transactionDate;
    
    // İlk işlemden bugüne kadar geçen gün sayısı
    final daysSinceFirstTransaction = now.difference(firstTransactionDate).inDays + 1;
    
    // Son 30 gün veya ilk işlemden itibaren, hangisi daha kısaysa
    final referenceDays = daysSinceFirstTransaction < 30 ? daysSinceFirstTransaction : 30;
    
    // Son 30 günlük giderleri hesapla (veya ilk işlemden itibaren)
    final thirtyDaysAgo = now.subtract(Duration(days: referenceDays - 1));
    final last30DaysExpenses = allExpenses
        .where((t) => t.transactionDate.isAfter(thirtyDaysAgo) && t.transactionDate.isBefore(now))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Genel günlük ortalama harcama
    return referenceDays > 0 ? last30DaysExpenses / referenceDays : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive boyutlar - Daha duyarlı tasarım
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    final isLargeScreen = ScreenCompatibility.isLargeScreen(context);
    
    // Responsive padding ve boyutlar - ScreenCompatibility kullanarak
    final cardPadding = ScreenCompatibility.responsivePadding(context, 
        EdgeInsets.all(screenSize == ScreenSizeCategory.small ? 12.0 : 
                       screenSize == ScreenSizeCategory.medium ? 14.0 :
                       screenSize == ScreenSizeCategory.large ? 16.0 : 18.0));
    
    final borderRadius = ScreenCompatibility.responsiveWidth(context,
        screenSize == ScreenSizeCategory.small ? 16.0 :
        screenSize == ScreenSizeCategory.medium ? 18.0 :
        screenSize == ScreenSizeCategory.large ? 20.0 : 22.0);
    
    final headerFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 11.0 :
        screenSize == ScreenSizeCategory.medium ? 12.0 :
        screenSize == ScreenSizeCategory.large ? 13.0 : 14.0);
    
    final profitFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 10.0 :
        screenSize == ScreenSizeCategory.medium ? 11.0 :
        screenSize == ScreenSizeCategory.large ? 12.0 : 13.0);
    
    final iconSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 14.0 :
        screenSize == ScreenSizeCategory.medium ? 15.0 :
        screenSize == ScreenSizeCategory.large ? 16.0 : 17.0);
    
    final spacingSmall = ScreenCompatibility.responsiveHeight(context, 8.0);
    final spacingMedium = ScreenCompatibility.responsiveHeight(context, 16.0);

    return Consumer3<ThemeProvider, UnifiedProviderV2, StockProvider>(
      builder: (context, themeProvider, providerV2, stockProvider, child) {
        final monthlySummary = providerV2.monthlySummary;
        final thisMonthIncome = providerV2.thisMonthIncome;
        final netAmount = monthlySummary['netAmount'] ?? 0.0;

        // Hisse kar/zarar bilgileri
        final totalStockValue =
            providerV2.balanceSummary['totalStockValue'] ?? 0.0;
        final totalStockCost =
            providerV2.balanceSummary['totalStockCost'] ?? 0.0;
        final stockProfitLoss = totalStockValue - totalStockCost;
        final stockProfitLossPercent = totalStockCost > 0
            ? (stockProfitLoss / totalStockCost) * 100
            : 0.0;

        // Hisse değişimlerini hesapla
        final stockChanges = _calculateStockChanges(providerV2, stockProvider);
        final todayStockChange = stockChanges['today'] ?? 0.0;

        // Günlük ortalama harcama hesapla
        final monthlyDailyAverage = _calculateMonthlyDailyAverageSpending(providerV2);
        final generalDailyAverage = _calculateGeneralDailyAverageSpending(providerV2);

        // Net worth hesaplaması (yatırımlar dahil/hariç)
        final baseBalance =
            providerV2.totalBalance -
            totalStockValue; // Yatırımlar hariç bakiye
        final netWorth = _includeInvestments
            ? providerV2.totalBalance
            : baseBalance;

        return Column(
          children: [
            // Premium Badge Section (Free kullanıcılar için)
            Consumer<PremiumService>(
              builder: (context, premiumService, child) {
                if (premiumService.isPremium) return const SizedBox.shrink();
                
                return Container(
                  margin: EdgeInsets.only(
                    bottom: ScreenCompatibility.responsiveHeight(context, 12.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenCompatibility.responsiveWidth(context, 16.0),
                    vertical: ScreenCompatibility.responsiveHeight(context, 12.0),
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA500).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.upgradeToPremiumBanner,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.1,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.premiumBannerSubtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 0,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PremiumOfferScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.upgradeNow,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFA500),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Ana kart
            GestureDetector(
              onTap: () => BalanceDetailBottomSheet.show(context),
              child: Container(
                key: widget.tutorialKey, // Tutorial key - sadece Balance Card için
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: ScreenCompatibility.responsiveHeight(context,
                      screenSize == ScreenSizeCategory.small ? 180.0 :
                      screenSize == ScreenSizeCategory.medium ? 200.0 :
                      screenSize == ScreenSizeCategory.large ? 220.0 : 240.0),
                ),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1C1C1E),
                            const Color(0xFF2C2C2E),
                            const Color(0xFF1C1C1E),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            const Color(0xFFF8F9FA),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: cardPadding.left,
                    right: cardPadding.right,
                    top: cardPadding.top,
                    bottom: cardPadding.bottom + ScreenCompatibility.responsiveHeight(context, 8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Header - Sadece empty state değilse göster
                      if (!(netWorth == 0.0 && providerV2.transactions.isEmpty)) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.netWorth,
                                style: GoogleFonts.inter(
                                  fontSize: headerFontSize,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF6D6D70).withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w400, // Daha hafif font weight
                                  letterSpacing: 0.5, // Letter spacing ekle
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Modern Segmented Control Toggle - Sadece hisse senedi varsa göster
                          if (totalStockValue > 0) Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : const Color(0xFFF2F2F7),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3A3A3C)
                                    : const Color(0xFFE5E5EA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // OUT Button
                                GestureDetector(
                                  onTap: () {
                                    if (_includeInvestments) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _includeInvestments = false;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: !_includeInvestments
                                          ? const Color(0xFFFF4C4C) // Kırmızı
                                          : Colors.transparent,
                                      boxShadow: !_includeInvestments
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFF4C4C).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: !_includeInvestments
                                            ? Colors.white
                                            : isDark
                                                ? Colors.white.withValues(alpha: 0.6)
                                                : const Color(0xFF6D6D70),
                                        letterSpacing: 0.2,
                                      ),
                                      child: Text(l10n.stocksExcluded),
                                    ),
                                  ),
                                ),
                                // IN Button
                                GestureDetector(
                                  onTap: () {
                                    if (!_includeInvestments) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _includeInvestments = true;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _includeInvestments
                                          ? const Color(0xFF2E7D32) // Rich Green
                                          : Colors.transparent,
                                      boxShadow: _includeInvestments
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: _includeInvestments
                                            ? Colors.white
                                            : isDark
                                                ? Colors.white.withValues(alpha: 0.6)
                                                : const Color(0xFF6D6D70),
                                        letterSpacing: 0.2,
                                      ),
                                      child: Text(l10n.stocksIncluded),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ],

                      // Spacing - Sadece empty state değilse göster
                      if (!(netWorth == 0.0 && providerV2.transactions.isEmpty))
                        SizedBox(height: spacingSmall - 3),

                      // Net Worth Amount veya Empty State
                      Builder(
                        builder: (context) {
                          // Yeni kullanıcı kontrolü - toplam varlık 0 ise empty state göster
                          if (netWorth == 0.0 && providerV2.transactions.isEmpty) {
                            return _buildEmptyState(context, themeProvider, isDark, l10n);
                          }
                          
                          final formatted = themeProvider.formatAmount(netWorth);
                          final currency = themeProvider.currency;
                          String numberOnly = formatted
                              .replaceAll(currency.symbol, '')
                              .trim();
                          String mainPart;
                          String decimalPart;
                          
                          // Currency locale'ine göre dinamik binlik ve ondalık ayırıcı belirleme
                          final thousandsSeparator = CurrencyUtils.getThousandsSeparator(currency.locale);
                          final decimalSeparator = CurrencyUtils.getDecimalSeparator(currency.locale);
                          
                          // Decimal separator'a göre split yap
                          final parts = numberOnly.split(decimalSeparator);
                          // Binlik ayırıcıları temizle (parse için)
                          final cleanedMainPart = parts[0].replaceAll(thousandsSeparator, '').replaceAll(' ', '');
                          decimalPart = parts.length > 1 ? parts[1].replaceAll(' ', '') : '00';
                          
                          // Binlik ayırıcıları tekrar ekle (gösterim için)
                          mainPart = CurrencyUtils.addThousandsSeparators(cleanedMainPart, currency.locale);
                          
                          // Calculate responsive font sizes based on the amount
                          final amountFontSize = _calculateResponsiveFontSize(context, netWorth);
                          final decimalFontSize = _calculateResponsiveFontSize(context, netWorth, isDecimal: true);
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Net Worth ana tutarı ve badge'ler
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${currency.symbol}$mainPart',
                                            style: GoogleFonts.inter(
                                              fontSize: amountFontSize,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : Colors.black,
                                              letterSpacing: -1.0,
                                              height: 1.0,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${CurrencyUtils.getDecimalSeparator(currency.locale)}$decimalPart',
                                            style: GoogleFonts.inter(
                                              fontSize: decimalFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.8),
                                              letterSpacing: -0.3,
                                              height: 1.0,
                                            ),
                                          ),
                                          if (totalStockValue > 0 && _includeInvestments)
                                            TextSpan(
                                              text: ' ${_formatCompactNumber(stockProfitLoss, currency)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)',
                                              style: GoogleFonts.inter(
                                                fontSize: (decimalFontSize - 2).clamp(9, 14).toDouble(),
                                                fontWeight: FontWeight.w600,
                                                color: stockProfitLoss >= 0
                                                    ? const Color(0xFF4CAF50) // Material Green
                                                    : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F)),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Inline P/L moved next to amount (left cluster)
                                  // Günlük ortalama rozetleri kaldırıldı
                                ],
                              ),

                              // Kredi kartı borcu - sadece borç varsa göster
                              Builder(
                                builder: (context) {
                                  final creditAccounts = providerV2.accounts
                                      .where((a) => a.type == AccountType.credit)
                                      .toList();
                                  
                                  // Kredi kartı yoksa gösterme
                                  if (creditAccounts.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final totalUsed = creditAccounts
                                      .fold<double>(0.0, (sum, a) => sum + a.usedCredit);
                                  final totalLimit = creditAccounts
                                      .fold<double>(0.0, (sum, a) => sum + (a.creditLimit ?? 0.0));
                                  
                                  // Borç yoksa gösterme
                                  if (totalUsed <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  // Kullanım yüzdesi hesapla
                                  final usagePercent = totalLimit > 0 
                                      ? (totalUsed / totalLimit * 100).clamp(0, 100)
                                      : 0.0;
                                  
                                  // Renk - kullanım yüzdesine göre
                                  Color debtColor;
                                  if (usagePercent >= 80) {
                                    debtColor = const Color(0xFFD32F2F); // Kırmızı - kritik
                                  } else if (usagePercent >= 50) {
                                    debtColor = const Color(0xFFFF9500); // Turuncu - uyarı
                                  } else {
                                    debtColor = const Color(0xFFFF4C4C); // Açık kırmızı - normal
                                  }
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(top: isSmallScreen ? 8.0 : 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Sol taraf - Label
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              size: isSmallScreen ? 15 : 16,
                                              color: debtColor,
                                            ),
                                            SizedBox(width: isSmallScreen ? 6 : 8),
                                            Text(
                                              AppLocalizations.of(context)!.creditCardDebt,
                                              style: GoogleFonts.inter(
                                                fontSize: isSmallScreen ? 12 : 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark 
                                                    ? Colors.white.withValues(alpha: 0.8)
                                                    : const Color(0xFF3C3C43),
                                              ),
                                            ),
                                            if (creditAccounts.length > 1) ...[
                                              SizedBox(width: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.1)
                                                      : Colors.black.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context)!.cardCount(creditAccounts.length),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark 
                                                        ? Colors.white.withValues(alpha: 0.5)
                                                        : const Color(0xFF8E8E93),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        
                                        // Sağ taraf - Tutar
                                        Text(
                                          themeProvider.formatAmount(totalUsed),
                                          style: GoogleFonts.inter(
                                            fontSize: isSmallScreen ? 13 : 14,
                                            fontWeight: FontWeight.w700,
                                            color: debtColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Alt hisse kar/zarar etiketi kaldırıldı (inline gösteriliyor)
                            ],
                          );
                        },
                      ),
                    ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Banner Reklam - Kartın altında (Premium kullanıcılara gösterilmez)
            Consumer<PremiumService>(
              builder: (context, premiumService, child) {
                if (premiumService.isPremium) return const SizedBox.shrink();
                
                if (_bannerService.isLoaded && _bannerService.bannerWidget != null) {
                  return Column(
                    children: [
                      SizedBox(height: spacingMedium),
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: ScreenCompatibility.responsiveWidth(context,
                              screenSize == ScreenSizeCategory.small ? 10.0 :
                              screenSize == ScreenSizeCategory.medium ? 12.0 :
                              screenSize == ScreenSizeCategory.large ? 14.0 : 16.0)),
                        width: double.infinity,
                        height: ScreenCompatibility.responsiveHeight(context, 50.0),
                        child: _bannerService.bannerWidget!,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeProvider themeProvider, bool isDark, AppLocalizations l10n) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    final isLargeScreen = ScreenCompatibility.isLargeScreen(context);
    
    // Daha kompakt responsive boyutlar
    final titleFontSize = ScreenCompatibility.responsiveFontSize(context, 
        screenSize == ScreenSizeCategory.small ? 16.0 : 
        screenSize == ScreenSizeCategory.medium ? 18.0 :
        screenSize == ScreenSizeCategory.large ? 20.0 : 22.0);
    
    final subtitleFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 12.0 :
        screenSize == ScreenSizeCategory.medium ? 13.0 :
        screenSize == ScreenSizeCategory.large ? 14.0 : 15.0);
    
    final buttonFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 11.0 :
        screenSize == ScreenSizeCategory.medium ? 12.0 :
        screenSize == ScreenSizeCategory.large ? 13.0 : 14.0);
    
    final iconSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 11.0 :
        screenSize == ScreenSizeCategory.medium ? 13.0 :
        screenSize == ScreenSizeCategory.large ? 15.0 : 17.0);
    
    final spacingSmall = ScreenCompatibility.responsiveHeight(context, 4.0);
    final spacingMedium = ScreenCompatibility.responsiveHeight(context, 8.0);
    final spacingLarge = ScreenCompatibility.responsiveHeight(context, 12.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ana mesaj
        Text(
          l10n.welcomeToQanta,
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        
        SizedBox(height: spacingSmall),
        
        // Alt mesaj
        Text(
          l10n.startYourFinancialJourney,
          style: GoogleFonts.inter(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w400,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF6D6D70),
            letterSpacing: 0.2,
            height: 1.4,
          ),
        ),
        
        SizedBox(height: spacingLarge),
        
        // Kart Ekleme Butonları - Yan yana şık tasarım
        Row(
          children: [
            // Banka Kartı Ekle
            Expanded(
              child: _buildCardButton(
                context: context,
                l10n: l10n,
                isDark: isDark,
                buttonFontSize: buttonFontSize,
                iconSize: iconSize,
                title: l10n.debit,
                icon: Icons.account_balance_wallet,
                color: const Color(0xFF007AFF), // iOS Blue - FAB ile aynı
                onTap: () => _showDebitCardForm(context),
              ),
            ),
            
            SizedBox(width: ScreenCompatibility.responsiveWidth(context, 8.0)),
            
            // Kredi Kartı Ekle
            Expanded(
              child: _buildCardButton(
                context: context,
                l10n: l10n,
                isDark: isDark,
                buttonFontSize: buttonFontSize,
                iconSize: iconSize,
                title: l10n.credit,
                icon: Icons.credit_card,
                color: const Color(0xFFE74C3C), // Red - FAB ile aynı
                onTap: () => _showCreditCardForm(context),
              ),
            ),
          ],
        ),
        
        SizedBox(height: spacingMedium),
        
        // İpucu mesajı - Responsive tasarım
        Container(
          padding: ScreenCompatibility.responsivePadding(context, 
              EdgeInsets.all(screenSize == ScreenSizeCategory.small ? 8.0 : 12.0)),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.5)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(ScreenCompatibility.responsiveWidth(context, 12.0)),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: iconSize,
                color: const Color(0xFFFFC300),
              ),
              SizedBox(width: ScreenCompatibility.responsiveWidth(context, 12.0)),
              Expanded(
                child: Text(
                  l10n.tipTrackYourExpenses,
                  style: GoogleFonts.inter(
                    fontSize: ScreenCompatibility.responsiveFontSize(context,
                        screenSize == ScreenSizeCategory.small ? 11.0 :
                        screenSize == ScreenSizeCategory.medium ? 12.0 :
                        screenSize == ScreenSizeCategory.large ? 13.0 : 14.0),
                    fontWeight: FontWeight.w400,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.8)
                        : const Color(0xFF6D6D70),
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardButton({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isDark,
    required double buttonFontSize,
    required double iconSize,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ScreenCompatibility.responsivePadding(context, 
            EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0)),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(ScreenCompatibility.responsiveWidth(context, 12.0)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: ScreenCompatibility.responsiveWidth(context, 8.0),
              offset: Offset(0, ScreenCompatibility.responsiveHeight(context, 2.0)),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            
            SizedBox(width: ScreenCompatibility.responsiveWidth(context, 6.0)),
            
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebitCardForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddDebitCardForm(
          onSuccess: () {
            // Provider otomatik güncellenecek, modal kapatma işlemi kaldırıldı
            // GoRouter hatası nedeniyle modal kapatma işlemi devre dışı bırakıldı
          },
        ),
      ),
    );
  }

  void _showCreditCardForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddCreditCardForm(
          onSuccess: () {
            // Provider otomatik güncellenecek, modal kapatma işlemi kaldırıldı
            // GoRouter hatası nedeniyle modal kapatma işlemi devre dışı bırakıldı
          },
        ),
      ),
    );
  }

  /// Kompakt sayı formatı (Daily Performance ile aynı)
  /// 5 basamak (10,000) üzeri için K, M, B kısaltması kullanır
  String _formatCompactNumber(double value, Currency currency) {
    final absValue = value.abs();
    final sign = value >= 0 ? '+' : '-';
    
    // 5 basamak (10,000) üzeri için k, m, b - ondalıklı
    if (absValue >= 1000000000) {
      return '$sign${(absValue / 1000000000).toStringAsFixed(2)}B';
    } else if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(2)}M';
    } else if (absValue >= 10000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      // 10K altında normal format
      final formatted = CurrencyUtils.formatAmountWithoutSymbol(absValue, currency);
      return '$sign$formatted';
    }
  }

}
