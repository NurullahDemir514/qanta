import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/models/transaction_model_v2.dart';

class BalanceOverviewCard extends StatelessWidget {
  const BalanceOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, providerV2, child) {
        final monthlySummary = providerV2.monthlySummary;
        final netWorth = providerV2.totalBalance;
        final thisMonthIncome = providerV2.thisMonthIncome;
        final netAmount = monthlySummary['netAmount'] ?? 0.0;
        
        // Geçen ayın net worth'unu hesapla
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        
        // Geçen ayın gelir ve giderlerini hesapla
        final lastMonthIncome = providerV2.transactions
            .where((t) => t.type == TransactionType.income && 
                         t.transactionDate.isAfter(lastMonth) && 
                         t.transactionDate.isBefore(lastMonthEnd))
            .fold(0.0, (sum, t) => sum + t.amount);
            
        final lastMonthExpense = providerV2.transactions
            .where((t) => t.type == TransactionType.expense && 
                         t.transactionDate.isAfter(lastMonth) && 
                         t.transactionDate.isBefore(lastMonthEnd))
            .fold(0.0, (sum, t) => sum + t.amount);
        
        // Geçen ayın net değişimi
        final lastMonthNetChange = lastMonthIncome - lastMonthExpense;
        
        // Geçen ayın net worth'u (mevcut net worth - bu ayın net değişimi + geçen ayın net değişimi)
        final thisMonthNetChange = netAmount;
        final lastMonthNetWorth = netWorth - thisMonthNetChange + lastMonthNetChange;
        
        // Değişim hesaplamaları
        final changeAmount = netWorth - lastMonthNetWorth;
        final changePercentage = lastMonthNetWorth != 0 ? (changeAmount / lastMonthNetWorth) * 100 : 0.0;
        
    

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
                      return Row(
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
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Geçen aya göre değişim - Kompakt tasarım
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                        : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: changeAmount >= 0 
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                          : const Color(0xFFFF3B30).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Trend ikonu
                        Icon(
                          changeAmount >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: changeAmount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                          size: 18,
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Başlık
                        Text(
                          l10n.lastMonthChange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Tutar
                        Text(
                          changeAmount >= 0 
                            ? '+${themeProvider.formatAmount(changeAmount)}'
                            : themeProvider.formatAmount(changeAmount),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: changeAmount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                          ),
                        ),
                        
                        const SizedBox(width: 6),
                        
                        // Yüzde
                        Text(
                          '(${changePercentage.abs().toStringAsFixed(1)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: changeAmount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

} 