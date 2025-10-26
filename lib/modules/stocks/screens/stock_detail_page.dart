import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/stock_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/utils/currency_utils.dart';
import '../providers/stock_provider.dart';
import '../utils/recalculate_stock_profit_loss.dart';

/// iOS-style hisse detay sayfası - Minimal, kompakt, şık
class StockDetailPage extends StatefulWidget {
  final Stock stock;
  final StockPosition? position;

  const StockDetailPage({
    super.key,
    required this.stock,
    this.position,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  @override
  void initState() {
    super.initState();
    _checkAndRecalculateProfitLoss();
  }

  Future<void> _checkAndRecalculateProfitLoss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRecalculated = prefs.getBool('stock_profit_loss_recalculated') ?? false;
      
      if (!hasRecalculated) {
        debugPrint('🔄 Recalculating stock profit/loss for all transactions...');
        await recalculateAllStockProfitLoss();
        await prefs.setBool('stock_profit_loss_recalculated', true);
        debugPrint('✅ Stock profit/loss recalculation completed!');
        
        // Reload transactions to show updated values
        if (mounted) {
          final stockProvider = context.read<StockProvider>();
          // Trigger a rebuild to show updated values
          stockProvider.notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error in profit/loss recalculation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = widget.stock.currency == 'USD' ? Currency.USD : Currency.TRY;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          _cleanStockName(widget.stock.symbol),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.position == null
          ? _buildNoPositionView(isDark, l10n)
          : Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                final stockTransactions = stockProvider.stockTransactions
                    .where((t) => t.stockSymbol == widget.stock.symbol)
                    .toList();
                stockTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merged Hero + Position kartı
                      _buildMergedHeroCard(isDark, l10n, currency),
                      const SizedBox(height: 20),
                      
                      // Transaction başlık
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          l10n.transactionHistory ?? 'İşlem Geçmişi',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      // Transaction list with dividers
                      if (stockTransactions.isEmpty)
                        _buildNoTransactionsView(isDark, l10n)
                      else
                        Column(
                          children: List.generate(
                            stockTransactions.length,
                            (index) {
                              final transaction = stockTransactions[index];
                              return Column(
                                children: [
                                  _buildTransactionItem(
                                    context: context,
                                    isDark: isDark,
                                    l10n: l10n,
                                    transaction: transaction,
                                    currency: currency,
                                  ),
                                  if (index < stockTransactions.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: isDark 
                                          ? const Color(0xFF38383A) 
                                          : const Color(0xFFE5E5EA),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNoPositionView(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: isDark ? Colors.white30 : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Pozisyon bulunamadı',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedHeroCard(bool isDark, AppLocalizations l10n, Currency currency) {
    final pos = widget.position!;
    final stock = widget.stock;
    final isProfit = pos.profitLoss >= 0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Üst: Symbol + Günlük Değişim
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanStockName(stock.symbol),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: stock.isPositive
                      ? const Color(0xFF34C759).withOpacity(0.15)
                      : const Color(0xFFFF3B30).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stock.displayChangePercent,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: stock.isPositive 
                        ? const Color(0xFF34C759) 
                        : const Color(0xFFFF3B30),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Merkez: Büyük Fiyat
          Text(
            stock.displayPrice,
            style: GoogleFonts.inter(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 18),
          
          // Estetik Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? Colors.white : Colors.black).withOpacity(0),
                  (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  (isDark ? Colors.white : Colors.black).withOpacity(0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // 3 Sütun: Toplam Değer | Adet | Ort. Fiyat
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.totalValue ?? 'Toplam Değer',
                  value: CurrencyUtils.formatAmount(pos.currentValue, currency),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.quantity,
                  value: '${pos.totalQuantity.toStringAsFixed(0)} ${l10n.pieces}',
                  isDark: isDark,
                  centered: true,
                ),
              ),
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.averagePrice,
                  value: CurrencyUtils.formatAmount(pos.averagePrice, currency),
                  isDark: isDark,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 2 Sütun: Maliyet | Kar/Zarar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalCost,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyUtils.formatAmount(pos.totalCost, currency),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.profitLoss,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isProfit ? '+' : ''}${CurrencyUtils.formatAmount(pos.profitLoss, currency)}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isProfit 
                          ? const Color(0xFF34C759) 
                          : const Color(0xFFFF3B30),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}${pos.profitLossPercent.toStringAsFixed(2)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isProfit 
                          ? const Color(0xFF34C759) 
                          : const Color(0xFFFF3B30),
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
  
  Widget _buildCompactMetric({
    required String label,
    required String value,
    required bool isDark,
    bool centered = false,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: centered 
          ? CrossAxisAlignment.center 
          : (alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start),
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          textAlign: centered ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
          textAlign: centered ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
        ),
      ],
    );
  }

  Widget _buildNoTransactionsView(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: isDark ? Colors.white30 : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noTransactionsYet,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required bool isDark,
    required AppLocalizations l10n,
    required StockTransaction transaction,
    required Currency currency,
  }) {
    final isBuy = transaction.type == StockTransactionType.buy;
    
    // FIFO mantığıyla gerçekleşmiş kar/zarar (transaction'da kaydedilmiş)
    // Eğer kayıtlı değilse (eski transaction'lar için), position'dan hesapla
    double profitLoss = transaction.profitLoss;
    double profitLossPercent = transaction.profitLossPercent;
    
    // Fallback: Eğer satış işlemi ve profitLoss == 0 ise, position'dan hesapla
    if (!isBuy && profitLoss == 0.0 && widget.position != null) {
      profitLoss = (transaction.price - widget.position!.averagePrice) * transaction.quantity;
      profitLossPercent = widget.position!.averagePrice > 0
          ? (profitLoss / (widget.position!.averagePrice * transaction.quantity)) * 100
          : 0.0;
    }
    
    final isProfit = profitLoss >= 0;
    
    // Alış işlemleri için kar/zarar gösterme (henüz satılmadı)
    final showProfitLoss = !isBuy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Sol: İkon + İşlem Tipi
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isBuy
                  ? const Color(0xFF34C759).withOpacity(0.12)
                  : const Color(0xFFFF3B30).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBuy ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: 20,
              color: isBuy ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(width: 12),
          
          // Orta: İşlem Detayları
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İşlem tipi + Adet
                Row(
                  children: [
                    Text(
                      isBuy ? l10n.buy : l10n.sell,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${transaction.quantity.toStringAsFixed(0)} ${l10n.pieces}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Fiyat + Tarih
                Row(
                  children: [
                    Text(
                      CurrencyUtils.formatAmount(transaction.price, currency),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTransactionDate(transaction.transactionDate, context),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sağ: Kar/Zarar veya Toplam Tutar
          if (showProfitLoss)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isProfit ? '+' : '-'}${CurrencyUtils.formatAmount(profitLoss.abs(), currency)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isProfit ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isProfit ? '+' : '-'}${profitLossPercent.abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isProfit ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.formatAmount(transaction.totalAmount, currency),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.total ?? 'Toplam',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTransactionDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(date.year, date.month, date.day);
    
    final l10n = AppLocalizations.of(context)!;
    
    if (transactionDay == today) {
      return l10n.today;
    } else if (transactionDay == yesterday) {
      return l10n.yesterday;
    } else {
      // Use simple date format: "15 Eki" or "15 Oct"
      final locale = Localizations.localeOf(context);
      final formatter = DateFormat(
        'd MMM',
        locale.languageCode == 'en' ? 'en_US' : 'tr_TR',
      );
      return formatter.format(date);
    }
  }

  String _cleanStockName(String name) {
    // BIST:THYAO -> THYAO, THYAO.IS -> THYAO
    String cleaned = name;
    
    // Remove exchange prefix (BIST:, NASDAQ:, etc.)
    if (cleaned.contains(':')) {
      cleaned = cleaned.split(':').last;
    }
    
    // Remove suffixes (.IS, .COM, etc.)
    cleaned = cleaned
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .trim();
    
    return cleaned;
  }
}
