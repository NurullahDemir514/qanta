import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/models/transaction_model_v2.dart' as txn;
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/stock_provider.dart';
import 'mini_chart_widget.dart';

/// Açılır-kapanır hisse kartı widget'ı
class ExpandableStockCard extends StatefulWidget {
  final Stock stock;
  final StockPosition? position;
  final VoidCallback? onTap;

  const ExpandableStockCard({
    super.key,
    required this.stock,
    this.position,
    this.onTap,
  });

  @override
  State<ExpandableStockCard> createState() => _ExpandableStockCardState();
}

class _ExpandableStockCardState extends State<ExpandableStockCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  double? _previousPrice;

  @override
  void initState() {
    super.initState();
    _previousPrice = widget.stock.currentPrice;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandableStockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fiyat değiştiğinde önceki fiyatı güncelle
    if (oldWidget.stock.currentPrice != widget.stock.currentPrice) {
      _previousPrice = oldWidget.stock.currentPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (_isExpanded) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  });
                },
                child: _buildCompactView(isDark, l10n),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedView(context, isDark, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriceColor(bool isDark) {
    if (_previousPrice == null) {
      return isDark ? Colors.white : Colors.black;
    }
    
    final currentPrice = widget.stock.currentPrice;
    final previousPrice = _previousPrice!;
    
    if (currentPrice > previousPrice) {
      return Colors.green;
    } else if (currentPrice < previousPrice) {
      return Colors.red;
    } else {
      return isDark ? Colors.white : Colors.black;
    }
  }

  Widget _buildCompactView(bool isDark, AppLocalizations l10n) {
    final position = widget.position;
    final isProfit = position != null && position.profitLoss > 0;
    final isLoss = position != null && position.profitLoss < 0;

    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          // Header - Hisse adı, mini grafik ve adet sayısı
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: isProfit
                      ? Colors.green
                      : isLoss
                      ? Colors.red
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _cleanStockName(widget.stock.symbol),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini grafik
                    Builder(
                      builder: (context) {
                        final positionData = widget.position?.historicalData;
                        final stockData = widget.stock.historicalData;
                        final hasData =
                            positionData != null || stockData != null;

                        if (hasData) {
                          final chartData = positionData ?? stockData!;
                          // 30 günlük veriye göre renklendirme: ilk değer vs son değer
                          final isPositive =
                              chartData.isNotEmpty &&
                              chartData.length > 1 &&
                              chartData.last >= chartData.first;

                          return MiniChartWidget(
                            data: chartData,
                            width: 70,
                            height: 10,
                            isPositive: isPositive,
                            isDark: isDark,
                          );
                        } else {
                          return Container(
                            width: 70,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                'No data',
                                style: TextStyle(
                                  fontSize: 6,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Adet sayısı ve güncel fiyat - Sağ üstte
              if (widget.position != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lot bilgisi
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
                        '${widget.position!.totalQuantity.toStringAsFixed(0)} ${l10n.pieces}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Güncel fiyat ve yüzde kar/zarar - Başlıksız
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.stock.currentPrice > 0.0
                                ? widget.stock.displayPrice
                                : '₺0,00',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _getPriceColor(isDark),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            position != null && position.profitLossPercent != 0
                                ? '${position.profitLossPercent > 0 ? '+' : ''}${position.profitLossPercent.toStringAsFixed(1)}%'
                                : '0.0%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: position != null && position.profitLossPercent > 0
                                  ? Colors.green
                                  : position != null && position.profitLossPercent < 0
                                      ? Colors.red
                                      : isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),


        ],
      ),
    );
  }

  Widget _buildExpandedView(BuildContext buildContext, bool isDark, AppLocalizations l10n) {
    final position = widget.position;
    final themeProvider = Provider.of<ThemeProvider>(buildContext, listen: false);
    final userCurrency = themeProvider.currency;
    final currencySymbol = userCurrency.symbol;
    
    if (position == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Hisse pozisyonu bulunamadı',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      );
    }

    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        // Bu hisse ile ilgili transaction'ları filtrele
        final stockTransactions = stockProvider.stockTransactions.where((transaction) {
          return transaction.stockSymbol == widget.stock.symbol;
        }).toList();

        // Tarihe göre sırala (en yeni üstte)
        stockTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
                  : [Colors.white, const Color(0xFFFAFAFA)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ana bilgiler - 3'lü grid
              Row(
                children: [
                  // 1. Maliyet
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.cost,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currencySymbol${_formatNumber(position.averagePrice, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
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

                  // 2. Mevcut Değer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.currentValue,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currencySymbol${_formatNumber(position.currentValue, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
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

                  // 3. Kar/Zarar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.profitLoss,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${position.profitLoss >= 0 ? '+' : ''}$currencySymbol${_formatNumber(position.profitLoss, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: position.profitLoss >= 0
                                ? const Color(0xFF4CAF50)
                                : position.profitLoss < 0
                                ? const Color(0xFFFF4C4C)
                                : Colors.grey,
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
              
              const SizedBox(height: 16),
              
              // Transaction listesi
              if (stockTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 32,
                          color: isDark ? Colors.white30 : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz işlem bulunmuyor',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...stockTransactions.map((transaction) {
                  final isBuy = transaction.type == StockTransactionType.buy;
                  final quantity = transaction.quantity;
                  final price = transaction.price;
                  final totalAmount = transaction.totalAmount;
                  
                  // Mevcut fiyata göre kar/zarar hesapla
                  final currentPrice = widget.stock.currentPrice;
                  final profitLoss = isBuy 
                      ? (currentPrice - price) * quantity  // Alış için: (mevcut - alış) × miktar
                      : (price - currentPrice) * quantity; // Satış için: (satış - mevcut) × miktar
                  final profitLossPercent = isBuy
                      ? ((currentPrice - price) / price) * 100  // Alış için: ((mevcut - alış) / alış) × 100
                      : ((price - currentPrice) / currentPrice) * 100; // Satış için: ((satış - mevcut) / mevcut) × 100
                  
                  return Column(
                    children: [
                      _buildTransactionItem(
                        context: context,
                        isDark: isDark,
                        l10n: l10n,
                        type: isBuy ? l10n.buy : l10n.sell,
                        quantity: quantity.toStringAsFixed(0),
                        price: '$currencySymbol${_formatNumber(price, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                        totalAmount: '$currencySymbol${_formatNumber(totalAmount, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                        profitLoss: '$currencySymbol${_formatNumber(profitLoss, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                        profitLossPercent: '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(1)}%',
                        date: TransactionDesignSystem.localizeDisplayTime(
                          _getRawTransactionDate(transaction.transactionDate),
                          context,
                        ),
                        isBuy: isBuy,
                        isProfit: profitLoss >= 0,
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required bool isDark,
    required AppLocalizations l10n,
    required String type,
    required String quantity,
    required String price,
    required String totalAmount,
    required String profitLoss,
    required String profitLossPercent,
    required String date,
    required bool isBuy,
    required bool isProfit,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Transaction type icon - Stock specific icons
          Icon(
            Icons.bar_chart,
            size: 14,
            color: isBuy ? Colors.red : Colors.green,
          ),
          
          const SizedBox(width: 8),
          
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  '$price × $quantity lot = $totalAmount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Profit/Loss
          Text(
            '$profitLoss ($profitLossPercent)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _getRawTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final transactionDay = DateTime(date.year, date.month, date.day);
    
    if (transactionDay == today) {
      return 'TODAY';
    } else if (transactionDay == yesterday) {
      return 'YESTERDAY';
    } else {
      // Format: DD/MM (same as transaction displayTime)
      return '${date.day}/${date.month}';
    }
  }

  Widget _buildPortfolioInfo(bool isDark, AppLocalizations l10n) {
    final position = widget.position!;
    final isProfit = position.profitLoss > 0;
    final isLoss = position.profitLoss < 0;
    final currentValue = position.totalQuantity * widget.stock.currentPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A1C), const Color(0xFF2A2A2C)]
              : [Colors.white, const Color(0xFFFAFBFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Hisse adı ve adet
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isProfit
                      ? Colors.green
                      : isLoss
                      ? Colors.red
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanStockName(widget.stock.symbol),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${position.totalQuantity.toStringAsFixed(0)} ${l10n.pieces}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.stock.currentPrice > 0.0
                              ? widget.stock.displayPrice
                              : '₺0,00',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          position.profitLossPercent != 0
                              ? '${position.profitLossPercent > 0 ? '+' : ''}${position.profitLossPercent.toStringAsFixed(1)}%'
                              : '0.0%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: position.profitLossPercent > 0
                                ? Colors.green
                                : position.profitLossPercent < 0
                                    ? Colors.red
                                    : isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Kar/Zarar yüzdesi - Vurgulu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isProfit
                      ? Colors.green.withOpacity(0.1)
                      : isLoss
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfit
                        ? Colors.green.withOpacity(0.3)
                        : isLoss
                        ? Colors.red.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${position.profitLossPercent >= 0 ? '+' : ''}${position.profitLossPercent.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isProfit
                        ? Colors.green
                        : isLoss
                        ? Colors.red
                        : Colors.grey,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ana değerler - 3'lü grid
          Row(
            children: [
              // Maliyet
              Expanded(
                child: _buildValueCard(
                  label: l10n.cost,
                  value:
                      '$currencySymbol${_formatNumber(position.averagePrice, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              // Güncel Değer
              Expanded(
                child: _buildValueCard(
                  label: 'Güncel Değer',
                  value:
                      '$currencySymbol${_formatNumber(currentValue, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              // Kar/Zarar
              Expanded(
                child: _buildValueCard(
                  label: 'Kar/Zarar',
                  value:
                      '${position.profitLoss >= 0 ? '+' : ''}$currencySymbol${_formatNumber(position.profitLoss, isUSD: widget.stock.currency == 'USD', context: buildContext)}',
                  isDark: isDark,
                  valueColor: isProfit
                      ? Colors.green
                      : isLoss
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey[600],
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : Colors.black),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Utility methods
  String _formatNumber(double number, {required bool isUSD, BuildContext? context}) {
    // Kullanıcının seçtiği currency'yi kullan, yoksa stock'un currency'sini kullan
    Currency currency;
    if (context != null) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      currency = themeProvider.currency;
    } else {
      currency = isUSD ? Currency.USD : Currency.TRY;
    }
    return CurrencyUtils.formatAmountWithoutSymbol(number, currency);
  }

  String _cleanStockName(String name) {
    return name
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.NET$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.ORG$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.CO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TR$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.US$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.L$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.PA$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.DE$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.HK$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.T$', caseSensitive: false), '')
        .trim();
  }

}
