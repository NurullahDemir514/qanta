import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/stock_models.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../mini_chart_widget.dart';
import '../../../transactions/widgets/forms/date_selector.dart';

/// Hisse işlem özet step'i
class StockSummaryStep extends StatefulWidget {
  final Stock stock;
  final AccountModel? account;
  final double quantity;
  final double price;
  final StockTransactionType transactionType;
  final List<double>? historicalData;
  final Function(double)? onCommissionRateChanged;
  final DateTime selectedDate;
  final Function(DateTime)? onDateChanged;
  
  const StockSummaryStep({
    super.key,
    required this.stock,
    this.account,
    required this.quantity,
    required this.price,
    required this.transactionType,
    this.historicalData,
    this.onCommissionRateChanged,
    required this.selectedDate,
    this.onDateChanged,
  });

  @override
  State<StockSummaryStep> createState() => _StockSummaryStepState();
}

class _StockSummaryStepState extends State<StockSummaryStep> {
  double _commissionRate = 0.0; // %0 varsayılan komisyon
  late TextEditingController _commissionController;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    _commissionController = TextEditingController(text: '0.0');
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _commissionController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cleanStockName(widget.stock.symbol),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.stock.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Mini grafik
                          if (widget.historicalData != null && widget.historicalData!.isNotEmpty)
                            MiniChartWidget(
                              data: widget.historicalData!,
                              width: 70,
                              height: 18,
                              isPositive: widget.stock.changePercent >= 0,
                              isDark: isDark,
                            )
                          else
                            Container(
                              width: 70,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'Grafik yükleniyor...',
                                  style: GoogleFonts.inter(
                                    fontSize: 7,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // İşlem detayları
                  _buildSummaryRow(l10n.quantity, '${widget.quantity.toStringAsFixed(2)} ${l10n.pieces}'),
                  _buildSummaryRow(l10n.price, '${CurrencyUtils.formatAmountWithoutSymbol(widget.price, currency)}$currencySymbol'),
                  _buildSummaryRow(l10n.total, '${CurrencyUtils.formatAmountWithoutSymbol(totalAmount, currency)}$currencySymbol'),
                  
                  const SizedBox(height: 12),
                  
                  // Komisyon ayarı - Kompakt ve zarif tasarım
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        
                        const SizedBox(height: 8),
                        
                        // Komisyon oranı girişi
                        TextField(
                          controller: _commissionController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: isDark ? Colors.white54 : Colors.grey[400],
                            ),
                            suffixText: '%',
                            suffixStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF007AFF),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (value) {
                            // Sadece sayı ve nokta kabul et
                            final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
                            
                            // Birden fazla nokta kontrolü
                            final dotCount = cleanValue.split('.').length - 1;
                            if (dotCount > 1) {
                              _commissionController.text = cleanValue.substring(0, cleanValue.lastIndexOf('.'));
                              _commissionController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _commissionController.text.length),
                              );
                              return;
                            }
                            
                            final parsedValue = double.tryParse(cleanValue) ?? 0.0;
                            _commissionRate = parsedValue / 100.0; // Yüzde olarak sakla
                            
                            setState(() {});
                            widget.onCommissionRateChanged?.call(_commissionRate);
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Bilgi metni
                        Text(
                          'Komisyon oranını yüzde olarak girin',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  _buildSummaryRow(l10n.commission, '${CurrencyUtils.formatAmountWithoutSymbol(commission, currency)}$currencySymbol'),
                  
                  const SizedBox(height: 12),
                  
                  // Final tutar
                  Container(
                    padding: const EdgeInsets.all(12),
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
            
            const SizedBox(height: 16),
            
            // Hesap bilgisi
            if (widget.account != null)
              Container(
                padding: const EdgeInsets.all(12),
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
                            widget.account!.name == 'CASH_WALLET'
                                ? (AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap')
                                : widget.account!.name,
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
            
            const SizedBox(height: 16),
            
            // Tarih seçici
            DateSelector(
              selectedDate: widget.selectedDate,
              onDateSelected: (date) {
                widget.onDateChanged?.call(date);
              },
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