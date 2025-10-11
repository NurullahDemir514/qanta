import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/utils/screen_compatibility.dart';
import '../../../l10n/app_localizations.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';

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
    
    // Responsive boyutlar
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    // Responsive padding ve boyutlar - Visual hierarchy odaklı tasarım
    final cardPadding = isSmallScreen ? 14.0 : 18.0;
    final borderRadius = isSmallScreen ? 16.0 : 20.0;
    final headerFontSize = isSmallScreen ? 12.0 : 14.0; // Daha küçük header
    final amountFontSize = isSmallScreen ? 28.0 : 38.0; // Daha büyük ana tutar
    final decimalFontSize = isSmallScreen ? 16.0 : 22.0; // Daha büyük decimal
    final profitFontSize = isSmallScreen ? 11.0 : 13.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;
    final spacingSmall = isSmallScreen ? 8.0 : 12.0; // Daha fazla spacing
    final spacingMedium = isSmallScreen ? 12.0 : 16.0;

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
                  maxHeight: isSmallScreen ? 140 : 160,
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
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.netWorth,
                            style: GoogleFonts.inter(
                              fontSize: headerFontSize,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : const Color(0xFF6D6D70).withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400, // Daha hafif font weight
                              letterSpacing: 0.5, // Letter spacing ekle
                            ),
                          ),
                          // Modern Segmented Control Toggle
                          Container(
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
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: !_includeInvestments
                                          ? const Color(0xFF007AFF)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      l10n.stocksExcluded,
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
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _includeInvestments
                                          ? const Color(0xFF007AFF)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      l10n.stocksIncluded,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacingSmall),

                      // Net Worth Amount
                      Builder(
                        builder: (context) {
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
                              // Net Worth ana tutarı ve toggle butonu
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
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
                                        Text(
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
                                      ],
                                    ),
                                  ),

                                ],
                              ),

                              // Hisse kar/zarar bilgisi (sadece hisse varsa ve yatırımlar dahilse göster)
                              if (totalStockValue > 0 && _includeInvestments) ...[
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 6 : 8,
                                    vertical: isSmallScreen ? 2 : 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stockProfitLoss >= 0
                                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                        : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: stockProfitLoss >= 0
                                          ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                          : const Color(0xFFFF3B30).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    stockProfitLoss >= 0
                                        ? '+${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)'
                                        : '${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)',
                                    style: GoogleFonts.inter(
                                      fontSize: profitFontSize,
                                      fontWeight: FontWeight.w600, // Daha bold
                                      color: stockProfitLoss >= 0
                                          ? const Color(0xFF2E7D32) // Daha koyu yeşil
                                          : const Color(0xFFD32F2F), // Daha koyu kırmızı
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
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
            
            // Banner Reklam - Kartın altında (sadece yüklendiyse göster)
            if (_bannerService.isLoaded && _bannerService.bannerWidget != null) ...[
              SizedBox(height: spacingMedium),
              Container(
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14),
                width: double.infinity,
                height: 50,
                child: _bannerService.bannerWidget!,
              ),
            ],
            
          ],
        );
      },
    );
  }
}
