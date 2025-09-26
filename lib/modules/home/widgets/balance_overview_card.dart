import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../bottom_sheets/balance_detail_bottom_sheet.dart';
import '../../../shared/utils/currency_utils.dart';

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
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
              border: isDark 
                ? Border.all(
                    color: const Color(0xFF38383A),
                    width: 0.5,
                  )
                : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Net Worth
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
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
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                currency.locale.startsWith('tr') ? ',$decimalPart' : '.$decimalPart',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                                ),
                              ),
                            ],
                          );
                        },
                      ),                      
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Monthly change indicator
                  Row(
                    children: [
                      Icon(
                        netAmount >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: netAmount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        netAmount >= 0 
                          ? 'Bu ay: +${themeProvider.formatAmount(netAmount)}'
                          : 'Bu ay: ${themeProvider.formatAmount(netAmount)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: netAmount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF3B30),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${themeProvider.formatAmount(thisMonthIncome)} gelir',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
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