import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/utils/screen_compatibility.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';
import '../../cards/widgets/add_debit_card_form.dart';
import '../../cards/widgets/add_credit_card_form.dart';

class BalanceOverviewCard extends StatefulWidget {
  const BalanceOverviewCard({super.key});

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
      adUnitId: config.AdvertisementConfig.testBanner1.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: true,
    );
    
    // Debug bilgisi
    debugPrint('🔄 TOPLAM VARLIK Banner reklam yükleniyor...');
    debugPrint('📱 Ad Unit ID: ${config.AdvertisementConfig.testBanner1.bannerAdUnitId}');
    debugPrint('🧪 Test Mode: true');
    debugPrint('📍 Konum: Toplam Varlık kartı altı');
    
    _bannerService.loadAd();
  }

  @override
  void dispose() {
    _bannerService.dispose();
    super.dispose();
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
        screenSize == ScreenSizeCategory.small ? 12.0 :
        screenSize == ScreenSizeCategory.medium ? 13.0 :
        screenSize == ScreenSizeCategory.large ? 14.0 : 15.0);
    
    final amountFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 28.0 :
        screenSize == ScreenSizeCategory.medium ? 32.0 :
        screenSize == ScreenSizeCategory.large ? 36.0 : 40.0);
    
    final decimalFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 16.0 :
        screenSize == ScreenSizeCategory.medium ? 18.0 :
        screenSize == ScreenSizeCategory.large ? 20.0 : 22.0);
    
    final profitFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 11.0 :
        screenSize == ScreenSizeCategory.medium ? 12.0 :
        screenSize == ScreenSizeCategory.large ? 13.0 : 14.0);
    
    final iconSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 16.0 :
        screenSize == ScreenSizeCategory.medium ? 17.0 :
        screenSize == ScreenSizeCategory.large ? 18.0 : 19.0);
    
    final spacingSmall = ScreenCompatibility.responsiveHeight(context, 8.0);
    final spacingMedium = ScreenCompatibility.responsiveHeight(context, 16.0);

    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, providerV2, child) {
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

        // Net worth hesaplaması (yatırımlar dahil/hariç)
        final baseBalance =
            providerV2.totalBalance -
            totalStockValue; // Yatırımlar hariç bakiye
        final netWorth = _includeInvestments
            ? providerV2.totalBalance
            : baseBalance;

        return Column(
          children: [
            // Ana kart
            GestureDetector(
              onTap: () => BalanceDetailBottomSheet.show(context),
              child: Container(
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
                  boxShadow: [
                    // Ana gölge
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : const Color(0xFF007AFF).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    // İç gölge efekti (üstte)
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.white.withValues(alpha: 0.9),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                      spreadRadius: -2,
                    ),
                    // Dış parlama
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : const Color(0xFF007AFF).withValues(alpha: 0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                      spreadRadius: 4,
                    ),
                  ],
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
                    bottom: cardPadding.bottom - ScreenCompatibility.responsiveHeight(context, 8.0),
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
                                        fontSize: 10,
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
                                          ? const Color(0xFF4CAF50) // Yeşil
                                          : Colors.transparent,
                                      boxShadow: _includeInvestments
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
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
                          if (currency.locale.startsWith('tr')) {
                            final parts = numberOnly.split(',');
                            mainPart = parts[0];
                            decimalPart = parts.length > 1 ? parts[1] : '00';
                          } else {
                            final parts = numberOnly.split('.');
                            mainPart = parts[0];
                            decimalPart = parts.length > 1 ? parts[1] : '00';
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Net Worth ana tutarı ve badge'ler
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Text(
                                            '${currency.symbol}$mainPart',
                                            style: GoogleFonts.inter(
                                              fontSize: amountFontSize,
                                              fontWeight: FontWeight.w800, // Daha bold
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              letterSpacing: -1.0, // Daha sıkı letter spacing
                                              height: 1.0, // Line height optimize et
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: Text(
                                            currency.locale.startsWith('tr')
                                                ? ',$decimalPart'
                                                : '.$decimalPart',
                                            style: GoogleFonts.inter(
                                              fontSize: decimalFontSize,
                                              fontWeight: FontWeight.w600, // Daha bold
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.9)
                                                  : Colors.black.withValues(alpha: 0.8),
                                              letterSpacing: -0.3,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                   // Haftalık ve aylık değişim badge'leri - Sağda biraz aşağıda
                                   Padding(
                                     padding: EdgeInsets.only(
                                       top: 6.0,
                                       left: ScreenCompatibility.responsiveWidth(context, 8.0),
                                     ),
                                     child: _buildWeeklyChange(providerV2, themeProvider, isDark, l10n),
                                   ),
                                ],
                              ),

                              // Hisse kar/zarar bilgisi (sadece hisse varsa ve yatırımlar dahilse göster)
                              if (totalStockValue > 0 && _includeInvestments)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 6 : 8,
                                    vertical: isSmallScreen ? 2 : 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stockProfitLoss >= 0
                                        ? isDark
                                            ? const Color(0xFF4CAF50).withValues(alpha: 0.15) // Daha görünür dark modda
                                            : const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                        : isDark
                                            ? const Color(0xFFFF3B30).withValues(alpha: 0.15) // Daha görünür dark modda
                                            : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: stockProfitLoss >= 0
                                          ? isDark
                                              ? const Color(0xFF4CAF50).withValues(alpha: 0.4) // Daha görünür dark modda
                                              : const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                          : isDark
                                              ? const Color(0xFFFF3B30).withValues(alpha: 0.4) // Daha görünür dark modda
                                              : const Color(0xFFFF3B30).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Flexible(
                                    child: Text(
                                      stockProfitLoss >= 0
                                          ? '+${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)'
                                          : '${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)',
                                      style: GoogleFonts.inter(
                                        fontSize: profitFontSize,
                                        fontWeight: FontWeight.w600, // Daha bold
                                        color: stockProfitLoss >= 0
                                            ? isDark 
                                                ? const Color(0xFF4CAF50) // Daha parlak yeşil dark modda
                                                : const Color(0xFF2E7D32) // Daha koyu yeşil light modda
                                            : isDark
                                                ? const Color(0xFFFF6B6B) // Daha parlak kırmızı dark modda
                                                : const Color(0xFFD32F2F), // Daha koyu kırmızı light modda
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: spacingMedium),
                    ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Banner Reklam - Kartın altında (sadece yüklendiyse göster)
            if (_bannerService.isLoaded && _bannerService.bannerWidget != null) ...[
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
        screenSize == ScreenSizeCategory.small ? 18.0 : 
        screenSize == ScreenSizeCategory.medium ? 20.0 :
        screenSize == ScreenSizeCategory.large ? 22.0 : 24.0);
    
    final subtitleFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 13.0 :
        screenSize == ScreenSizeCategory.medium ? 14.0 :
        screenSize == ScreenSizeCategory.large ? 15.0 : 16.0);
    
    final buttonFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 12.0 :
        screenSize == ScreenSizeCategory.medium ? 13.0 :
        screenSize == ScreenSizeCategory.large ? 14.0 : 15.0);
    
    final iconSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 12.0 :
        screenSize == ScreenSizeCategory.medium ? 14.0 :
        screenSize == ScreenSizeCategory.large ? 16.0 : 18.0);
    
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
                        screenSize == ScreenSizeCategory.small ? 12.0 :
                        screenSize == ScreenSizeCategory.medium ? 13.0 :
                        screenSize == ScreenSizeCategory.large ? 14.0 : 15.0),
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

  Widget _buildWeeklyChange(UnifiedProviderV2 provider, ThemeProvider themeProvider, bool isDark, AppLocalizations l10n) {
    // Responsive boyutlar
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    // Haftalık değişim hesaplama
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));
    
    // Bu hafta içindeki işlemler
    final thisWeekTransactions = provider.transactions.where((transaction) {
      return transaction.transactionDate.isAfter(weekAgo) && 
             transaction.transactionDate.isBefore(now);
    }).toList();
    
    // Bu ay içindeki işlemler
    final thisMonthTransactions = provider.transactions.where((transaction) {
      return transaction.transactionDate.isAfter(monthAgo) && 
             transaction.transactionDate.isBefore(now);
    }).toList();
    
    // Bu hafta gelir ve gider hesaplama
    double thisWeekIncome = 0.0;
    double thisWeekExpense = 0.0;
    
    for (final transaction in thisWeekTransactions) {
      if (transaction.type == TransactionType.income) {
        thisWeekIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        thisWeekExpense += transaction.amount;
      }
    }
    
    // Bu ay gelir ve gider hesaplama
    double thisMonthIncome = 0.0;
    double thisMonthExpense = 0.0;
    
    for (final transaction in thisMonthTransactions) {
      if (transaction.type == TransactionType.income) {
        thisMonthIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        thisMonthExpense += transaction.amount;
      }
    }
    
    final weeklyChange = thisWeekIncome - thisWeekExpense;
    final monthlyChange = thisMonthIncome - thisMonthExpense;
    
    // Veri yoksa widget'ı gizle
    if (thisWeekTransactions.isEmpty && thisMonthTransactions.isEmpty) {
      return SizedBox.shrink();
    }
    
    final isWeeklyPositive = weeklyChange >= 0;
    final isMonthlyPositive = monthlyChange >= 0;
    
    final weeklyColor = isWeeklyPositive
        ? isDark 
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E7D32)
        : isDark
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFD32F2F);
            
    final monthlyColor = isMonthlyPositive
        ? isDark 
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E7D32)
        : isDark
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFD32F2F);
    
    // Responsive font boyutları
    final badgeFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 10.0 :
        screenSize == ScreenSizeCategory.medium ? 11.0 :
        screenSize == ScreenSizeCategory.large ? 12.0 : 13.0);
    
    final periodFontSize = ScreenCompatibility.responsiveFontSize(context,
        screenSize == ScreenSizeCategory.small ? 8.0 :
        screenSize == ScreenSizeCategory.medium ? 9.0 :
        screenSize == ScreenSizeCategory.large ? 10.0 : 11.0);
    
    // Responsive padding ve spacing
    final badgePadding = ScreenCompatibility.responsivePadding(context,
        EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 5.0 : 6.0,
          vertical: isSmallScreen ? 2.0 : 3.0,
        ));
    
    final badgeSpacing = ScreenCompatibility.responsiveHeight(context, 
        isSmallScreen ? 4.0 : 5.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Haftalık değişim
        Container(
          padding: badgePadding,
          decoration: BoxDecoration(
            color: weeklyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ScreenCompatibility.responsiveWidth(context, 6.0)),
            border: Border.all(
              color: weeklyColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${isWeeklyPositive ? '+' : ''}${themeProvider.formatAmount(weeklyChange)}',
                  style: GoogleFonts.inter(
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                    color: weeklyColor,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: ScreenCompatibility.responsiveWidth(context, 4.0)),
              Flexible(
                child: Text(
                  l10n.last7Days,
                  style: GoogleFonts.inter(
                    fontSize: periodFontSize,
                    fontWeight: FontWeight.w500,
                    color: isDark 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: badgeSpacing),
        // Aylık değişim
        Container(
          padding: badgePadding,
          decoration: BoxDecoration(
            color: monthlyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ScreenCompatibility.responsiveWidth(context, 6.0)),
            border: Border.all(
              color: monthlyColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${isMonthlyPositive ? '+' : ''}${themeProvider.formatAmount(monthlyChange)}',
                  style: GoogleFonts.inter(
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                    color: monthlyColor,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: ScreenCompatibility.responsiveWidth(context, 4.0)),
              Flexible(
                child: Text(
                  l10n.last30Days,
                  style: GoogleFonts.inter(
                    fontSize: periodFontSize,
                    fontWeight: FontWeight.w500,
                    color: isDark 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
