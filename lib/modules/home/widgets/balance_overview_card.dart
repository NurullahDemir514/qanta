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
        final totalBalance = providerV2.totalBalance;
        final thisMonthIncome = providerV2.thisMonthIncome;
        final thisMonthExpense = providerV2.thisMonthExpense;
        final balanceChangePercentage = providerV2.balanceChangePercentage;
        final isLoading = providerV2.isLoading;
        
        debugPrint('🎯 BalanceOverviewCard using QANTA v2 provider');

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
              child: isLoading 
                ? _buildLoadingState(isDark)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalBalance,
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
                              Icons.visibility_outlined,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Main balance with currency formatting
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, provider, child) {
                              final formattedAmount = provider.formatAmount(totalBalance);
                              final currency = provider.currency;
                              
                              // Remove currency symbol to get just the number
                              String numberOnly = formattedAmount.replaceAll(currency.symbol, '').trim();
                              
                              // Handle different decimal separators based on locale
                              String mainPart;
                              String decimalPart;
                              
                              if (currency.locale.startsWith('tr')) {
                                // Turkish uses comma as decimal separator
                                final parts = numberOnly.split(',');
                                mainPart = parts[0];
                                decimalPart = parts.length > 1 ? parts[1] : '00';
                              } else {
                                // English and others use dot as decimal separator
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
                                    style: CurrencyUtils.getCurrencyTextStyle(
                                      baseStyle: GoogleFonts.inter(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black,
                                        letterSpacing: -0.5,
                                      ),
                                      currency: currency,
                                    ),
                                  ),
                                  Text(
                                    currency.locale.startsWith('tr') ? ',$decimalPart' : '.$decimalPart',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark 
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: balanceChangePercentage >= 0 
                                ? const Color(0xFF34C759).withValues(alpha: 0.1)
                                : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  balanceChangePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: balanceChangePercentage >= 0 
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFFFF3B30),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${balanceChangePercentage.abs().toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: balanceChangePercentage >= 0 
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF3B30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Stats row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                label: l10n.thisMonthIncome,
                                amount: themeProvider.formatAmount(thisMonthIncome),
                                isPositive: true,
                                isDark: isDark,
                              ),
                            ),
                            Container(
                              width: 1,
                              color: isDark 
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                label: l10n.thisMonthExpense,
                                amount: themeProvider.formatAmount(thisMonthExpense),
                                isPositive: false,
                                isDark: isDark,
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

  Widget _buildBalanceItem({
    required String label,
    required String amount,
    required bool isPositive,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Toplam Bakiye',
              style: GoogleFonts.inter(
                fontSize: 14,
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
                Icons.visibility_outlined,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                size: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Loading indicator
        Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Veriler yükleniyor...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
} 