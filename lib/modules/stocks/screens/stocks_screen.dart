import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
import '../../../core/services/premium_service.dart';
import '../../premium/premium_offer_screen.dart';
import '../widgets/stock_transaction_fab.dart';
import '../../../core/providers/unified_provider_v2.dart';

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
  
  // Filtreleme state'i
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'gainers', 'losers', 'portfolioRatio', 'alphabetical'];

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
                                        Color(0xFF2E7D32),
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

                  // Filtreleme seçenekleri
                  if (stockProvider.watchedStocks.isNotEmpty && _hasActivePositions(stockProvider))
                    _buildFilterOptions(isDark),

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
      margin: const EdgeInsets.only(bottom: 10),
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
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Header - Portföy adı ve toplam hisse sayısı
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.myPortfolio,
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Toplam hisse sayısı ve return - Sağ üstte
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            '${isProfit ? '+' : ''}${totalReturnPercent.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isProfit
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF4C4C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                // Ana bilgiler - 3'lü grid
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
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            CurrencyUtils.formatAmount(totalCost, Currency.TRY),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
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

                    SizedBox(width: 12.w),

                    // 2. Toplam Değer (sonra value)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.value,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            CurrencyUtils.formatAmount(
                              totalValue,
                              Currency.TRY,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
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

                    SizedBox(width: 12.w),

                    // 3. Toplam Kar/Zarar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.profitLoss,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${isProfit ? '+' : ''}${CurrencyUtils.formatAmount(totalProfitLoss, Currency.TRY)}',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
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

  Widget _buildFilterOptions(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Column(
        children: [
          // Segmented Control Style Filter
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)],
                    )
                  : null,
              color: isDark ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                width: 1,
              ),
            ),
            child: Row(
              children: _filterOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final filter = entry.value;
                final isSelected = _selectedFilter == filter;
                final isFirst = index == 0;
                final isLast = index == _filterOptions.length - 1;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(
                        left: isFirst ? 2 : 1,
                        right: isLast ? 2 : 1,
                        top: 2,
                        bottom: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFFFF9500) : const Color(0xFFFF9500))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _getFilterLabel(filter),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'gainers':
        return Icons.trending_up_rounded;
      case 'losers':
        return Icons.trending_down_rounded;
      case 'stable':
        return Icons.horizontal_rule_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return l10n.all;
      case 'gainers':
        return l10n.gainers;
      case 'losers':
        return l10n.losers;
      case 'alphabetical':
        return l10n.alphabetical;
      case 'portfolioRatio':
        return l10n.portfolioRatio;
      default:
        return l10n.all;
    }
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

  /// Check if stock should be shown based on current filter
  bool _shouldShowStock(StockPosition position) {
    switch (_selectedFilter) {
      case 'gainers':
        // Pozitif performans gösterenler (kar edenler)
        return position.profitLoss > 0;
      case 'losers':
        // Negatif performans gösterenler (zarar edenler)
        return position.profitLoss < 0;
      case 'alphabetical':
      case 'portfolioRatio':
        // Sıralama filtreleri - tüm hisseleri göster
        return true;
      case 'all':
      default:
        return true;
    }
  }

  /// Sort stocks based on current filter
  List<Widget> _sortStocks(List<Widget> stocks, StockProvider stockProvider) {
    if (_selectedFilter == 'alphabetical') {
      // Alfabetik sıralama için stocks listesini yeniden oluştur
      final sortedStocks = <Widget>[];
      final stockPositions = <String, StockPosition>{};
      
      // Pozisyonları map'e çevir
      for (final position in stockProvider.stockPositions) {
        stockPositions[position.stockSymbol] = position;
      }
      
      // Hisse sembollerini alfabetik sırala
      final sortedSymbols = stockProvider.watchedStocks
          .where((stock) => stockPositions.containsKey(stock.symbol) && 
                           stockPositions[stock.symbol]!.totalQuantity > 0)
          .map((stock) => stock.symbol)
          .toList()
        ..sort();
      
      // Sıralı şekilde widget'ları oluştur
      for (final symbol in sortedSymbols) {
        final stock = stockProvider.watchedStocks.firstWhere((s) => s.symbol == symbol);
        final position = stockPositions[symbol]!;
        
        sortedStocks.add(
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
      
      return sortedStocks;
    } else if (_selectedFilter == 'portfolioRatio') {
      // Portföy oranına göre sıralama
      final sortedStocks = <Widget>[];
      final stockPositions = <String, StockPosition>{};
      
      // Pozisyonları map'e çevir
      for (final position in stockProvider.stockPositions) {
        stockPositions[position.stockSymbol] = position;
      }
      
      // Hisse sembollerini portföy oranına göre sırala
      final sortedSymbols = stockProvider.watchedStocks
          .where((stock) => stockPositions.containsKey(stock.symbol) && 
                           stockPositions[stock.symbol]!.totalQuantity > 0)
          .toList()
        ..sort((a, b) {
          final positionA = stockPositions[a.symbol]!;
          final positionB = stockPositions[b.symbol]!;
          return positionB.currentValue.compareTo(positionA.currentValue);
        });
      
      // Sıralı şekilde widget'ları oluştur
      for (final stock in sortedSymbols) {
        final position = stockPositions[stock.symbol]!;
        
        sortedStocks.add(
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
      
      return sortedStocks;
    }
    
    return stocks;
  }

  Widget _buildContent(StockProvider stockProvider, bool isDark) {
    if (stockProvider.error != null) {
      return SizedBox(
        height: 400,
        child: _buildErrorState(stockProvider.error!),
      );
    } else if (stockProvider.watchedStocks.isEmpty) {
      // Hiç hisse takip edilmiyorsa empty state göster
      return _buildEmptyPortfolioState(isDark);
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

        if (hasPosition && _shouldShowStock(position!)) {
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
        // Filtreleme sonucunda hiç hisse yoksa farklı mesaj göster
        if (_selectedFilter != 'all') {
          return _buildNoStocksMatchFilter(isDark);
        } else {
          return _buildEmptyPortfolioState(isDark);
        }
      }

      // Sıralama uygula
      final sortedStocks = _sortStocks(stocksWithPositions, stockProvider);

      // Hisse listesi
      return Column(children: sortedStocks);
    }
  }

  Widget _buildEmptyPortfolioState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6, // Take up 60% of screen height
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple Icon
              Icon(
                Icons.trending_up_rounded,
                size: 80,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              
              const SizedBox(height: 24),
              
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
              
              const SizedBox(height: 32),
              
              // Simple Add Stocks Button
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(8),
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
        ),
      ),
    );
  }

  Widget _buildNoStocksMatchFilter(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6, // Take up 60% of screen height
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Filter Icon
              Icon(
                Icons.filter_list_off_rounded,
                size: 80,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                l10n.noStocksMatchFilter,
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
                l10n.tryDifferentFilter,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    // Free kullanıcılar da hisse arayabilir
    // Limit kontrolü hisse eklerken yapılacak
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockSearchScreen()),
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
    
    // Kart varlığı kontrolü
    bool hasDebitCards = provider.debitCards.isNotEmpty;
    bool hasCreditCards = provider.creditCards.isNotEmpty;
    bool hasAnyCards = hasDebitCards || hasCreditCards;
    
    // Toplam kullanılabilir para (sadece nakit + debit bakiye)
    double totalAvailableBalance = totalCashBalance + totalDebitBalance;
    
    // Senaryo 1: Nakit sıfır ve banka hesabı yok
    if (totalCashBalance <= 0 && !hasAnyCards) {
      _showNoAccountCashZeroSnackBar(context, l10n);
      return;
    }
    
    // Senaryo 2: Nakit sıfır ama banka hesabı var
    if (totalCashBalance <= 0 && hasAnyCards && totalDebitBalance <= 0) {
      _showUpdateCashBalanceSnackBar(context, l10n);
      return;
    }
    
    // Senaryo 3: Banka hesabı yok ama nakit var
    if (totalCashBalance > 0 && !hasAnyCards) {
      _showAddBankAccountSnackBar(context, l10n);
      return;
    }
    
    // Senaryo 4: Hem nakit hem banka hesabı sıfır
    if (totalAvailableBalance <= 0) {
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

  void _showNoAccountCashZeroSnackBar(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
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
                    l10n.noBankAccountCashZero,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.updateCashOrAddBank,
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
        backgroundColor: const Color(0xFFFF9500),
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
            context.go('/cards');
          },
        ),
      ),
    );
  }

  void _showUpdateCashBalanceSnackBar(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.monetization_on_outlined,
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
                    l10n.updateCashBalance,
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
        backgroundColor: const Color(0xFF007AFF),
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
            context.go('/cards');
          },
        ),
      ),
    );
  }

  void _showAddBankAccountSnackBar(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
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
                    l10n.addBankAccount,
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
        backgroundColor: const Color(0xFF2E7D32),
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
            context.go('/cards');
          },
        ),
      ),
    );
  }

  void _showStockDetail(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockDetailScreen(stock: stock)),
    );
  }
}
