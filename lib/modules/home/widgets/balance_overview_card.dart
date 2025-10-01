import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/models/transaction_model_v2.dart';

class BalanceOverviewCard extends StatefulWidget {
  const BalanceOverviewCard({super.key});

  @override
  State<BalanceOverviewCard> createState() => _BalanceOverviewCardState();
}

class _BalanceOverviewCardState extends State<BalanceOverviewCard> {
  bool _includeInvestments = true; // Varsayılan olarak yatırımlar dahil

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, providerV2, child) {
        final monthlySummary = providerV2.monthlySummary;
        final thisMonthIncome = providerV2.thisMonthIncome;
        final netAmount = monthlySummary['netAmount'] ?? 0.0;
        
        // Hisse kar/zarar bilgileri
        final totalStockValue = providerV2.balanceSummary['totalStockValue'] ?? 0.0;
        final totalStockCost = providerV2.balanceSummary['totalStockCost'] ?? 0.0;
        final stockProfitLoss = totalStockValue - totalStockCost;
        final stockProfitLossPercent = totalStockCost > 0 ? (stockProfitLoss / totalStockCost) * 100 : 0.0;
        
        // Net worth hesaplaması (yatırımlar dahil/hariç)
        final baseBalance = providerV2.totalBalance - totalStockValue; // Yatırımlar hariç bakiye
        final netWorth = _includeInvestments ? providerV2.totalBalance : baseBalance;
        
        
    

        return GestureDetector(
          onTap: () => BalanceDetailBottomSheet.show(context),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF1C1C1E) 
                : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.netWorth,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: isDark 
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                        size: 20,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Net Worth Amount
                  Builder(
                    builder: (context) {
                      final formatted = themeProvider.formatAmount(netWorth);
                      final currency = themeProvider.currency;
                      String numberOnly = formatted.replaceAll(currency.symbol, '').trim();
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
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${currency.symbol}$mainPart',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      currency.locale.startsWith('tr') ? ',$decimalPart' : '.$decimalPart',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Toggle butonu (sadece hisse varsa göster)
                              if (totalStockValue > 0) ...[
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _includeInvestments = !_includeInvestments;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _includeInvestments 
                                          ? const Color(0xFF007AFF).withValues(alpha: 0.15)
                                          : const Color(0xFF8E8E93).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _includeInvestments 
                                            ? const Color(0xFF007AFF).withValues(alpha: 0.4)
                                            : const Color(0xFF8E8E93).withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _includeInvestments 
                                              ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                                              : const Color(0xFF8E8E93).withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _includeInvestments ? l10n.stocksIncluded : l10n.stocksExcluded,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _includeInvestments 
                                            ? const Color(0xFF007AFF) 
                                            : const Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Hisse kar/zarar bilgisi (sadece hisse varsa ve yatırımlar dahilse göster)
                          if (totalStockValue > 0 && _includeInvestments) ...[
                            const SizedBox(height: 4),
                            Text(
                              stockProfitLoss >= 0 
                                ? '+${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)'
                                : '${themeProvider.formatAmount(stockProfitLoss)} (${stockProfitLossPercent.abs().toStringAsFixed(1)}%)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: stockProfitLoss >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

} 