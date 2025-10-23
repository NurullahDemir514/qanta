import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/firebase_client.dart';
import '../../../modules/stocks/providers/stock_provider.dart';
import '../../../shared/models/stock_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../insights/providers/statistics_provider.dart';
import '../../insights/models/statistics_model.dart';
import '../../stocks/screens/stock_transaction_form_screen.dart';
import '../../../shared/utils/currency_utils.dart';

class TopGainersSection extends StatefulWidget {
  const TopGainersSection({super.key});

  @override
  State<TopGainersSection> createState() => _TopGainersSectionState();
}

class _TopGainersSectionState extends State<TopGainersSection> {
  bool _isMarketOpen = false;

  @override
  void initState() {
    super.initState();
    _checkMarketStatus();
  }

  void _checkMarketStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final isWeekday = now.weekday >= 1 && now.weekday <= 5;

    // Market hours: 09:00 - 18:30
    final isAfterOpen = hour > 9 || (hour == 9 && minute >= 0);
    final isBeforeClose = hour < 18 || (hour == 18 && minute <= 15);

    _isMarketOpen = isWeekday && isAfterOpen && isBeforeClose;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ COMPOSITE READINESS: Gelişmiş loading state ayrımı
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        // 🔍 DEBUG LOG: TopGainersSection build çağrıları (sadece değişiklik olduğunda)
        // debugPrint('🎯 TopGainersSection.build() - isDataLoaded: ${providerV2.isDataLoaded}, watchedStocks: ${providerV2.watchedStocks.length}, isStockDataReady: ${providerV2.isStockDataReady}, isPositionsReady: ${providerV2.isPositionsReady}, positions: ${providerV2.stockPositions.length}');
        
        // Ana veriler yüklenmemişse sessizce bekle
        if (!providerV2.isDataLoaded) {
          debugPrint('❌ TopGainersSection → SizedBox.shrink() (isDataLoaded: false)');
          return const SizedBox.shrink();
        }
        
        // ✅ POSITIONS READINESS: Hisse verileri var ama positions hazır değilse loading göster
        if (providerV2.watchedStocks.isNotEmpty && !providerV2.isPositionsReady) {
          debugPrint('⏳ TopGainersSection → LoadingState (watchedStocks: ${providerV2.watchedStocks.length}, positions not ready)');
          return _buildLoadingState(l10n, isDark);
        }
        
        // ✅ GELİŞMİŞ AYRI: Gerçek boş portföy vs loading state
        if (providerV2.watchedStocks.isEmpty) {
          // Hisse verileri yükleniyorsa loading göster
          if (providerV2.isStockDataReady == false) {
            debugPrint('⏳ TopGainersSection → LoadingState (watchedStocks empty, stock data not ready)');
            return _buildLoadingState(l10n, isDark);
          } else {
            // Gerçekten boş portföy
            debugPrint('📭 TopGainersSection → EmptyPortfolioState (watchedStocks empty, stock data ready)');
            return _buildEmptyPortfolioStateWithTitle(l10n, isDark);
          }
        }

        final userStocks = providerV2.watchedStocks;

        // Sıfır adetli pozisyonları filtrele
        final validStocks = userStocks.where((stock) {
          try {
            final position = providerV2.stockPositions.firstWhere(
              (pos) => pos.stockSymbol == stock.symbol,
            );
            
            return position.totalQuantity > 0 && 
                   position.averagePrice != null &&
                   position.averagePrice! > 0;
          } catch (e) {
            return false;
          }
        }).toList();

        // ✅ OPTİMİZASYON: İlk 5 hisseyi al (en çok değerlenen veya en az düşen)
        if (validStocks.isEmpty) {
          debugPrint('📭 TopGainersSection → EmptyPortfolioState (validStocks empty)');
          return _buildEmptyPortfolioStateWithTitle(l10n, isDark);
        }

        // ✅ STABİL SIRALAMA: Değişim yüzdesine göre sırala ama aynı değerlerde sembol sırasını koru
        final sortedStocks = List<Stock>.from(validStocks)
          ..sort((a, b) {
            // Önce değişim yüzdesine göre sırala
            final changeComparison = b.changePercent.compareTo(a.changePercent);
            if (changeComparison != 0) return changeComparison;
            
            // Aynı değişim yüzdesinde sembol alfabetik sırasını koru
            return a.symbol.compareTo(b.symbol);
          });

        // ✅ TÜM HİSSELER: Tüm geçerli hisseleri göster
        final topStocks = sortedStocks;
        
        debugPrint('✅ TopGainersSection → Rendering ${topStocks.length} stocks: ${topStocks.map((s) => s.symbol).join(', ')}');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.dailyPerformance,
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (topStocks.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            _buildTotalProfitLoss(topStocks, providerV2.watchedStocks, providerV2.stockPositions, isDark),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content - Artık sadece topStocks render edilir
            _buildStocksList(topStocks, providerV2.stockPositions, isDark, l10n),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark, bool noStocks) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                noStocks
                    ? Icons.trending_up_rounded
                    : Icons.hourglass_empty_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                           Text(
                             noStocks
                                 ? l10n.noStocksTracked
                                 : l10n.stockDataLoading,
                             style: GoogleFonts.inter(
                               fontSize: 16,
                               fontWeight: FontWeight.w600,
                               color: isDark ? Colors.white : Colors.black,
                               letterSpacing: -0.2,
                             ),
                           ),
                           if (noStocks) ...[
                             const SizedBox(height: 2),
                             Text(
                               l10n.addStocksInstruction,
                               style: GoogleFonts.inter(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w400,
                                 color: isDark
                                     ? const Color(0xFF8E8E93)
                                     : const Color(0xFF6D6D70),
                               ),
                             ),
                           ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStocksList(List<Stock> stocks, List<StockPosition> positions, bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            stocks.length,
            (index) {
              final stock = stocks[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < stocks.length - 1 ? 8.w : 0,
                ),
                child: _buildStockCard(stock, positions, isDark, l10n),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTotalProfitLoss(List<Stock> topStocks, List<Stock> allStocks, List<StockPosition> positions, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    double totalProfitLoss = 0.0;
    double totalCost = 0.0;

    for (final stock in allStocks) {
      try {
        final position = positions.firstWhere(
          (pos) => pos.stockSymbol == stock.symbol,
        );

        if (position.averagePrice != null) {
          // Bugün alınan hisse lotlarını bul
          final today = DateTime.now();
          final todayTransactions = stockProvider.stockTransactions.where((txn) {
            final txnDate = txn.transactionDate;
            return txn.stockSymbol == stock.symbol &&
                   txn.type == StockTransactionType.buy &&
                   txnDate.year == today.year &&
                   txnDate.month == today.month &&
                   txnDate.day == today.day;
          }).toList();
          
          double todayLots = 0.0;
          double todayTotalCost = 0.0;
          
          for (final txn in todayTransactions) {
            todayLots += txn.quantity;
            todayTotalCost += txn.totalAmount;
          }
          
          final previousLots = position.totalQuantity - todayLots;
          
          double dailyProfitLoss = 0.0;
          
          // Günlük P/L hesaplama - İKİ FARKLI MANTIK
          if (todayLots > 0 && stock.openPrice != null) {
            // 1. Önceki günlerde alınan lotlar için: Açılış fiyatı referans
            final previousDailyChange = previousLots > 0
                ? ((stock.currentPrice - stock.openPrice!) * previousLots)
                : 0.0;
            
            // 2. Bugün alınan lotlar için: Alış fiyatı referans
            final todayAvgPrice = todayTotalCost / todayLots;
            final todayDailyChange = (stock.currentPrice - todayAvgPrice) * todayLots;
            
            // Toplam günlük kar/zarar
            dailyProfitLoss = previousDailyChange + todayDailyChange;
          } else {
            // Bugün alış yoksa veya açılış fiyatı yoksa - eski mantık
            final dailyChangeAmount =
                (stock.changePercent / 100) * position.averagePrice;
            dailyProfitLoss = dailyChangeAmount * position.totalQuantity;
          }
          
          totalProfitLoss += dailyProfitLoss;
          
          // Toplam maliyet hesaplama (yüzde hesaplaması için)
          totalCost += position.totalCost;
        }
      } catch (e) {
        // Pozisyon bulunamadı, atla
      }
    }

    // Toplam yüzde hesaplama
    double totalPercent = 0.0;
    if (totalCost > 0) {
      totalPercent = (totalProfitLoss / totalCost) * 100;
    }

    final isPositive = totalProfitLoss >= 0;
    final color = isPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF4C4C);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isPositive ? '+' : ''}${themeProvider.formatAmount(totalProfitLoss)}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '(${isPositive ? '+' : ''}${totalPercent.abs().toStringAsFixed(1)}%)',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Stock stock, List<StockPosition> positions, bool isDark, AppLocalizations l10n) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    // Pozisyonu bul
    StockPosition? position;
    try {
      position = positions.firstWhere(
        (pos) => pos.stockSymbol == stock.symbol,
      );
    } catch (e) {
      position = null;
    }

    // Günlük ve Toplam Kar/Zarar Hesaplamaları
    double dailyProfitLoss = 0.0;
    double dailyProfitLossPercent = stock.changePercent;
    double? weightedOpenPrice; // Ağırlıklı ortalama açılış fiyatı
    
    double totalProfitLoss = 0.0;
    double totalProfitLossPercent = 0.0;
    
    if (position != null) {
      // Bugün alınan hisse lotlarını bul
      final today = DateTime.now();
      final todayTransactions = stockProvider.stockTransactions.where((txn) {
        final txnDate = txn.transactionDate;
        return txn.stockSymbol == stock.symbol &&
               txn.type == StockTransactionType.buy &&
               txnDate.year == today.year &&
               txnDate.month == today.month &&
               txnDate.day == today.day;
      }).toList();
      
      double todayLots = 0.0;
      double todayTotalCost = 0.0;
      
      for (final txn in todayTransactions) {
        todayLots += txn.quantity;
        todayTotalCost += txn.totalAmount;
      }
      
      final previousLots = position.totalQuantity - todayLots;
      
      // Günlük P/L hesaplama - İKİ FARKLI MANTIK
      if (todayLots > 0 && stock.openPrice != null) {
        // 1. Önceki günlerde alınan lotlar için: Açılış fiyatı referans
        final previousDailyChange = previousLots > 0
            ? ((stock.currentPrice - stock.openPrice!) * previousLots)
            : 0.0;
        
        // 2. Bugün alınan lotlar için: Alış fiyatı referans
        final todayAvgPrice = todayTotalCost / todayLots;
        final todayDailyChange = (stock.currentPrice - todayAvgPrice) * todayLots;
        
        // Toplam günlük kar/zarar
        dailyProfitLoss = previousDailyChange + todayDailyChange;
        
        // Ağırlıklı ortalama açılış fiyatı hesapla
        // (Önceki lotlar × açılış fiyatı + Bugün alınan lotlar × alış fiyatı) / Toplam lotlar
        final previousOpenValue = previousLots > 0 ? (previousLots * stock.openPrice!) : 0.0;
        final todayOpenValue = todayLots * todayAvgPrice;
        weightedOpenPrice = (previousOpenValue + todayOpenValue) / position.totalQuantity;
        
        // Günlük yüzde - ağırlıklı ortalama açılış fiyatına göre
        if (weightedOpenPrice > 0) {
          dailyProfitLossPercent = ((stock.currentPrice - weightedOpenPrice) / weightedOpenPrice) * 100;
        }
      } else {
        // Bugün alış yoksa veya açılış fiyatı yoksa - eski mantık
        final dailyChangeAmount =
            (stock.changePercent / 100) * position.averagePrice;
        dailyProfitLoss = dailyChangeAmount * position.totalQuantity;
        // Açılış fiyatını kullan (varsa)
        weightedOpenPrice = stock.openPrice;
      }
      
      // Toplam P/L hesaplama
      totalProfitLoss = position.currentValue - position.totalCost;
      if (position.totalCost > 0) {
        totalProfitLossPercent = (totalProfitLoss / position.totalCost) * 100;
      }
    }
    
    // Daily P/L rengi - günlük kar/zarara göre
    final dailyIsPositive = dailyProfitLoss >= 0;
    final changeColor = dailyIsPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF4C4C);
    
    // Total P/L rengi - toplam kar/zarara göre
    final totalIsPositive = totalProfitLoss >= 0;
    final totalChangeColor = totalIsPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF4C4C);

    return Container(
      width: 170.w,
      padding: EdgeInsets.only(top: 7.w, bottom: 5.w, left: 6.w, right: 6.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Symbol + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Text(
                    stock.symbol,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Current price with opening price and arrow
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Opening price with arrow (if available)
                    // Ağırlıklı ortalama açılış fiyatı kullan (bugün alım varsa)
                    if (weightedOpenPrice != null) ...[
                      Text(
                        themeProvider.formatAmount(weightedOpenPrice),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6D6D70),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        stock.currentPrice >= weightedOpenPrice 
                            ? Icons.arrow_upward 
                            : Icons.arrow_downward,
                        size: 10.sp,
                        color: stock.currentPrice >= weightedOpenPrice 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFFF4C4C),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    // Current price
                    Text(
                      themeProvider.formatAmount(stock.currentPrice),
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // Performance Data - Kompakt
          if (position != null) ...[
            // Daily Performance Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label (Sol)
                  Text(
                    l10n.today,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFA0A0A0)
                          : const Color(0xFF4A4A4A),
                    ),
                  ),
                  // Tutar + Yüzde (Sağ)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_formatCompactNumber(dailyProfitLoss, currency: themeProvider.currency)} ${themeProvider.currency.symbol}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: changeColor,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatCompactNumber(dailyProfitLossPercent, isPercent: true),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: changeColor.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Divider - Dashed Style
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: SizedBox(
                height: 1,
                child: CustomPaint(
                  painter: DashedLinePainter(
                    color: isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFE5E5EA),
                    dashWidth: 3,
                    dashSpace: 2,
                  ),
                  child: Container(),
                ),
              ),
            ),
            
            // Total Performance Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label (Sol)
                  Text(
                    l10n.total,
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFA0A0A0)
                          : const Color(0xFF4A4A4A),
                    ),
                  ),
                  // Tutar + Yüzde (Sağ)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_formatCompactNumber(totalProfitLoss, currency: themeProvider.currency)} ${themeProvider.currency.symbol}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: totalChangeColor,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatCompactNumber(totalProfitLossPercent, isPercent: true),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: totalChangeColor.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF2C2C2E).withOpacity(0.5)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Center(
                child: Text(
                  l10n.noPosition,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5.w,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.stockDataLoading,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPortfolioStateWithTitle(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            l10n.dailyPerformance,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Balanced Compact Empty State
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Balanced Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFFF9500) : const Color(0xFFFF9500),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Balanced Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.noStocksTracked,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Balanced CTA Button
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      _checkBalanceAndNavigate(context);
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.addStocks,
                            style: GoogleFonts.inter(
                              fontSize: 13,
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
  }

  Widget _buildEmptyPortfolioState(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 32.sp,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.noStocksTracked,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.addStocksInstruction,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
        ],
      ),
    );
  }

  void _checkBalanceAndNavigate(BuildContext context) {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    // Debit kart bakiyesi kontrolü
    double totalDebitBalance = 0.0;
    for (final card in provider.debitCards) {
      totalDebitBalance += card['balance'] ?? 0.0;
    }
    
    // Kredi kartı kullanılabilir limit kontrolü
    double totalCreditLimit = 0.0;
    for (final card in provider.creditCards) {
      totalCreditLimit += card['availableLimit'] ?? 0.0;
    }
    
    // Nakit bakiyesi kontrolü
    double totalCashBalance = 0.0;
    for (final cash in provider.cashAccounts) {
      totalCashBalance += cash.balance;
    }
    
    // Toplam kullanılabilir para (sadece nakit + debit bakiye)
    double totalAvailableBalance = totalCashBalance + totalDebitBalance;
    
    if (totalAvailableBalance <= 0) {
      // Toplam kullanılabilir para sıfır ise uyarı göster
      _showInsufficientBalanceSnackBar(context, l10n);
      return;
    }
    
    // Bakiye varsa hisse al ekranını aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockTransactionFormScreen(
          transactionType: StockTransactionType.buy,
        ),
      ),
    );
  }

  void _showInsufficientBalanceSnackBar(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.insufficientBalance,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.addMoneyToAccount,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF4C4C),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: l10n.addMoney,
          textColor: Colors.white,
          onPressed: () {
            // Para ekleme sayfasına yönlendir
            context.go('/cards');
          },
        ),
      ),
    );
  }
}

// Helper function to format compact numbers
String _formatCompactNumber(double value, {bool isPercent = false, Currency? currency}) {
  final absValue = value.abs();
  final sign = value >= 0 ? '+' : '-';
  
  if (isPercent) {
    // Yüzde formatı - %1000 üzeri için k, m, b
    if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(1)}M%';
    } else if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}K%';
    } else {
      return '$sign${absValue.toStringAsFixed(1)}%';
    }
  } else {
    // Tutar formatı - 5 basamak (10,000) üzeri için k, m, b - ondalıklı
    if (absValue >= 1000000000) {
      return '$sign${(absValue / 1000000000).toStringAsFixed(2)}B';
    } else if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(2)}M';
    } else if (absValue >= 10000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      // 10K altında CurrencyUtils kullan
      final formatted = CurrencyUtils.formatAmountWithoutSymbol(absValue, currency ?? Currency.TRY);
      return '$sign$formatted';
    }
  }
}

// Custom Painter for Dashed Line
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
