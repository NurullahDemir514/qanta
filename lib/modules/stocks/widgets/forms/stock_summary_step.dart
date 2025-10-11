import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/stock_models.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../mini_chart_widget.dart';

/// Hisse işlem özet step'i
class StockSummaryStep extends StatefulWidget {
  final Stock stock;
  final AccountModel? account;
  final double quantity;
  final double price;
  final StockTransactionType transactionType;
  final List<double>? historicalData;
  final Function(double)? onCommissionRateChanged;
  
  const StockSummaryStep({
    super.key,
    required this.stock,
    this.account,
    required this.quantity,
    required this.price,
    required this.transactionType,
    this.historicalData,
    this.onCommissionRateChanged,
  });

  @override
  State<StockSummaryStep> createState() => _StockSummaryStepState();
}

class _StockSummaryStepState extends State<StockSummaryStep> {
  double _commissionRate = 0.0; // %0 varsayılan komisyon
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = widget.quantity * widget.price;
    final commission = totalAmount * _commissionRate;
    final finalAmount = totalAmount + commission;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final currency = themeProvider.currency;
        final currencySymbol = currency.symbol;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hisse bilgileri kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hisse bilgileri
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: widget.transactionType == StockTransactionType.buy 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.transactionType == StockTransactionType.buy 
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: widget.transactionType == StockTransactionType.buy 
                              ? Colors.green
                              : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cleanStockName(widget.stock.symbol),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.stock.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${CurrencyUtils.formatAmountWithoutSymbol(widget.stock.currentPrice, currency)}$currencySymbol',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Mini grafik
                          if (widget.historicalData != null && widget.historicalData!.isNotEmpty)
                            MiniChartWidget(
                              data: widget.historicalData!,
                              width: 80,
                              height: 20,
                              isPositive: widget.stock.changePercent >= 0,
                              isDark: isDark,
                            )
                          else
                            Container(
                              width: 80,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'Grafik yükleniyor...',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // İşlem detayları
                  _buildSummaryRow(l10n.quantity, '${widget.quantity.toStringAsFixed(2)} ${l10n.pieces}'),
                  _buildSummaryRow(l10n.price, '${CurrencyUtils.formatAmountWithoutSymbol(widget.price, currency)}$currencySymbol'),
                  _buildSummaryRow(l10n.total, '${CurrencyUtils.formatAmountWithoutSymbol(totalAmount, currency)}$currencySymbol'),
                  
                  const SizedBox(height: 16),
                  
                  // Komisyon ayarı - Kompakt ve zarif tasarım
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Başlık ve değer - tek satır
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.commissionRate,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(_commissionRate * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Slider - kompakt
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF007AFF),
                            inactiveTrackColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            trackHeight: 4,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _commissionRate,
                            min: 0.0, // %0
                            max: 0.1, // %10
                            divisions: 10,
                            onChanged: (value) {
                              setState(() {
                                _commissionRate = value;
                              });
                              // Parent'a komisyon oranını bildir
                              widget.onCommissionRateChanged?.call(value);
                            },
                          ),
                        ),
                        
                        // Değer aralığı - tek satırda
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white54 : Colors.grey[400],
                              ),
                            ),
                            Text(
                              '10%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white54 : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  _buildSummaryRow(l10n.commission, '${CurrencyUtils.formatAmountWithoutSymbol(commission, currency)}$currencySymbol'),
                  
                  const SizedBox(height: 16),
                  
                  // Final tutar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.transactionType == StockTransactionType.buy 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.transactionType == StockTransactionType.buy 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.transactionType == StockTransactionType.buy ? l10n.totalToPay : l10n.totalToReceive,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.transactionType == StockTransactionType.buy 
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Text(
                          '${CurrencyUtils.formatAmountWithoutSymbol(finalAmount, currency)}$currencySymbol',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.transactionType == StockTransactionType.buy 
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Hesap bilgisi
            if (widget.account != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.account,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                          Text(
                            widget.account!.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(widget.account!.balance, Currency.TRY),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  // Hisse adı ve sembol temizleme
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