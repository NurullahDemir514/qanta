import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../../../shared/utils/currency_utils.dart';
import '../providers/stock_provider.dart';
import '../widgets/expandable_stock_card.dart';
import '../widgets/stock_search_screen.dart';
import '../widgets/stock_detail_screen.dart';
import 'stock_transaction_form_screen.dart';
import '../../../shared/models/stock_models.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../widgets/stock_transaction_fab.dart';

/// Hisse takip ana ekranı
class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen>
    with TickerProviderStateMixin {
  Timer? _priceUpdateTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();

    // Progress animasyonu için controller
    _progressController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Data already loaded in splash screen, no need to reload
    // Timer'ı başlat
    _startPriceUpdateTimer();

    // Geçmiş veri yükle (mini grafik için) - sadece geçmiş veri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ SADECE GEÇMİŞ VERİ YÜKLE: Hisse verileri zaten splash'te yüklendi
        stockProvider.loadAllHistoricalData(days: 30);
        
        // ✅ Sıfır pozisyonları temizle ve watched listten kaldır
        await stockProvider.clearZeroPositionsAndRemoveFromWatchedList(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;

    // Geçmiş veri yükle (mini grafik için) - hot reload için
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ GEREKSIZ YÜKLEME ENGELLEME: Veriler zaten splash'te yüklendi
        if (stockProvider.watchedStocks.isEmpty) {
          await stockProvider.loadWatchedStocks(user.uid);
        }
        // Sonra geçmiş verileri yükle
        stockProvider.loadAllHistoricalData(days: 30);
      }
    });
  }

  void _startPriceUpdateTimer() {
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final stockProvider = Provider.of<StockProvider>(context, listen: false);

      if (stockProvider.watchedStocks.isNotEmpty) {
        // Progress animasyonunu başlat
        _progressController.reset();
        _progressController.forward();

        stockProvider.updateRealTimePricesSilently();
      } else {}
    });

    // İlk güncelleme kaldırıldı - splash screen'de zaten güncelleniyor
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        AppPageScaffold(
          title: l10n.stocks ?? 'Hisse Senetleri',
          subtitle: l10n.trackYourStocks,
          titleFontSize: 20,
          subtitleFontSize: 12,
          body: Consumer<StockProvider>(
            builder: (context, stockProvider, child) {
              return SliverList(
                delegate: SliverChildListDelegate([
                  // Progress Bar - Sadece aktif pozisyon varsa göster
                  if (stockProvider.watchedStocks.isNotEmpty && _hasActivePositions(stockProvider))
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 1,
                        bottom: 10,
                        left: 5,
                        right: 5,
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                            ),
                            child: Stack(
                              children: [
                                // Progress bar
                                Container(
                                  height: 3,
                                  width:
                                      MediaQuery.of(context).size.width *
                                      _progressAnimation.value,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(1),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF007AFF),
                                        Color(0xFF34D399),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Portfolio Overview Table - Hidden when no positions
                  if (stockProvider.watchedStocks.isNotEmpty && _hasActivePositions(stockProvider))
                    _buildPortfolioOverviewTable(stockProvider, isDark),

                  // Content
                  _buildContent(stockProvider, isDark),
                ]),
              );
            },
          ),
        ),
        // Positioned FAB - Responsive positioning
        Positioned(
          right: FabPositioning.getRightPosition(context),
          bottom: FabPositioning.getBottomPosition(context),
          child: const StockTransactionFab(),
        ),
      ],
    );
  }

  Widget _buildPortfolioOverviewTable(
    StockProvider stockProvider,
    bool isDark,
  ) {
    // Portföy istatistiklerini hesapla
    double totalValue = 0.0;
    double totalCost = 0.0;
    double totalProfitLoss = 0.0;
    int totalStocks = 0;

    for (final stock in stockProvider.watchedStocks) {
      try {
        final position = stockProvider.stockPositions.firstWhere(
          (p) => p.stockSymbol == stock.symbol,
        );

        if (position.totalQuantity > 0) {
          totalValue += position.currentValue;
          totalCost += position.totalCost;
          totalProfitLoss += position.profitLoss;
          totalStocks++;
        }
      } catch (e) {
        // Position bulunamadı, atla
      }
    }

    final totalReturnPercent = totalCost != 0
        ? (totalProfitLoss / totalCost) * 100
        : 0.0;
    final isProfit = totalProfitLoss >= 0;
    final isLoss = totalProfitLoss < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
                  : [Colors.white, const Color(0xFFFAFAFA)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                // Header - Portföy adı ve toplam hisse sayısı
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.portfolioOverview,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Toplam hisse sayısı - Sağ üstte
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$totalStocks ${l10n.stocks}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ana bilgiler - 4'lü grid
                Row(
                  children: [
                    // 1. Toplam Maliyet (önce cost)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.cost,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            CurrencyUtils.formatAmount(totalCost, Currency.TRY),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // 2. Toplam Değer (sonra value)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.value,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            CurrencyUtils.formatAmount(
                              totalValue,
                              Currency.TRY,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // 3. Toplam Kar/Zarar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.profitLoss,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '${isProfit ? '+' : ''}${CurrencyUtils.formatAmount(totalProfitLoss, Currency.TRY)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isProfit
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF4C4C),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // 4. Toplam Getiri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.returnLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '${isProfit ? '+' : ''}${totalReturnPercent.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isProfit
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF4C4C),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumberWithCommas(double number) {
    // Virgül ile sayı formatı, K/M kullanmadan
    final formatter = NumberFormat('#,###');
    return formatter.format(number.abs().round());
  }

  /// Check if there are any active positions (quantity > 0)
  bool _hasActivePositions(StockProvider stockProvider) {
    return stockProvider.stockPositions.any((position) => position.totalQuantity > 0);
  }

  Widget _buildContent(StockProvider stockProvider, bool isDark) {
    if (stockProvider.error != null) {
      return SizedBox(
        height: 400,
        child: _buildErrorState(stockProvider.error!),
      );
    } else if (stockProvider.watchedStocks.isEmpty) {
      // Hisse yoksa shrink yap, loading state gösterme
      return const SizedBox.shrink();
    } else {
      // Pozisyonu olan hisseleri filtrele
      final stocksWithPositions = <Widget>[];
      
      for (int index = 0; index < stockProvider.watchedStocks.length; index++) {
        final stock = stockProvider.watchedStocks[index];
        StockPosition? position;
        try {
          position = stockProvider.stockPositions.firstWhere(
            (p) => p.stockSymbol == stock.symbol,
          );
        } catch (e) {
          position = null;
        }

        // Sıfır adetli pozisyonları filtrele - sadece pozisyonu olan hisseleri göster
        final hasPosition = position != null && position.totalQuantity > 0;

        if (hasPosition) {
          stocksWithPositions.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ExpandableStockCard(
                stock: stock,
                position: position,
                onTap: () => _showStockDetail(stock),
              ),
            ),
          );
        }
      }

      // Eğer pozisyonu olan hisse yoksa empty state göster
      if (stocksWithPositions.isEmpty) {
        return _buildEmptyPortfolioState(isDark);
      }

      // Hisse listesi
      return Column(children: stocksWithPositions);
    }
  }

  Widget _buildEmptyPortfolioState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Simple Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 28,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            l10n.noStocksTracked,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            l10n.addStocksInstruction,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Simple Add Stocks Button
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
                onTap: () {
                  // Navigate directly to stock transaction form (buy)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockTransactionFormScreen(
                        transactionType: StockTransactionType.buy,
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addStocks,
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
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            '${l10n.error}: $error',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.red[300],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final stockProvider = Provider.of<StockProvider>(
                context,
                listen: false,
              );
              final userId = FirebaseAuthService.currentUserId;
              if (userId != null) {
                stockProvider.loadWatchedStocks(userId);
              }
            },
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            l10n.noStocksYet,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFirstStock,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showStockSearch,
            icon: const Icon(Icons.search),
            label: Text(l10n.searchStocks),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showStockSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockSearchScreen()),
    );
  }

  void _showStockDetail(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockDetailScreen(stock: stock)),
    );
  }
}
