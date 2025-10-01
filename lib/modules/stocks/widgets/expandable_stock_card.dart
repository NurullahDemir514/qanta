import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../screens/stock_transaction_form_screen.dart';
import '../providers/stock_provider.dart';
import '../../../l10n/app_localizations.dart';
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

class _ExpandableStockCardState extends State<ExpandableStockCard> {

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
                  ? [
                      const Color(0xFF1C1C1E),
                      const Color(0xFF2C2C2E),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFFAFAFA),
                    ],
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
          child: _buildCompactView(isDark, l10n),
        ),
      ),
    );
  }

  Widget _buildCompactView(bool isDark, AppLocalizations l10n) {
    final position = widget.position;
    final isProfit = position != null && position.profitLoss > 0;
    final isLoss = position != null && position.profitLoss < 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header - Hisse adı, mini grafik ve adet sayısı
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: isProfit ? Colors.green : isLoss ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
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
                    const SizedBox(width: 8),
                    // Mini grafik
                    Builder(
                      builder: (context) {
                        final positionData = widget.position?.historicalData;
                        final stockData = widget.stock.historicalData;
                        final hasData = positionData != null || stockData != null;
                        
                        
                        if (hasData) {
                          return MiniChartWidget(
                            data: positionData ?? stockData!,
                            width: 70,
                            height: 10,
                            isPositive: widget.stock.changePercent >= 0,
                            isDark: isDark,
                          );
                        } else {
                          return Container(
                            width: 70,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                'No data',
                                style: TextStyle(
                                  fontSize: 6,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              // Adet sayısı - Sağ üstte
              if (widget.position != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${widget.position!.totalQuantity.toStringAsFixed(0)} ${l10n.pieces}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Ana bilgiler - 4'lü grid
          if (position != null)
            Row(
              children: [
                // 1. Maliyet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.cost,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(widget.position!.averagePrice, isUSD: widget.stock.currency == 'USD')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. Güncel Fiyat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.currentPrice,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.stock.currentPrice > 0.0 ? widget.stock.displayPrice : '₺0,00',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 3. Mevcut Değer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.currentValue,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(widget.position!.currentValue, isUSD: widget.stock.currency == 'USD')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 4. Kar/Zarar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.profitLoss,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.position!.profitLoss >= 0 ? '+' : ''}${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(widget.position!.profitLoss, isUSD: widget.stock.currency == 'USD')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isProfit ? Colors.green : isLoss ? Colors.red : Colors.grey,
                        ).copyWith(
                          fontFeatures: [FontFeature.superscripts()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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
              ? [
                  const Color(0xFF1A1A1C),
                  const Color(0xFF2A2A2C),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFAFBFC),
                ],
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
                  color: isProfit ? Colors.green : isLoss ? Colors.red : Colors.grey,
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
                    Text(
                      '${position.totalQuantity.toStringAsFixed(0)} ${l10n.pieces}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Kar/Zarar yüzdesi - Vurgulu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: isProfit ? Colors.green : isLoss ? Colors.red : Colors.grey,
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
                  value: '${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(position.averagePrice, isUSD: widget.stock.currency == 'USD')}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              // Güncel Değer
              Expanded(
                child: _buildValueCard(
                  label: 'Güncel Değer',
                  value: '${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(currentValue, isUSD: widget.stock.currency == 'USD')}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              // Kar/Zarar
              Expanded(
                child: _buildValueCard(
                  label: 'Kar/Zarar',
                  value: '${position.profitLoss >= 0 ? '+' : ''}${widget.stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(position.profitLoss, isUSD: widget.stock.currency == 'USD')}',
                  isDark: isDark,
                  valueColor: isProfit ? Colors.green : isLoss ? Colors.red : Colors.grey,
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
  String _formatNumber(double number, {required bool isUSD}) {
    final currency = isUSD ? Currency.USD : Currency.TRY;
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
