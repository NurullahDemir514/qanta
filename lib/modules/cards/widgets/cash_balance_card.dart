import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

class CashBalanceCard extends StatelessWidget {
  final double balance;
  final ThemeProvider themeProvider;

  const CashBalanceCard({
    super.key,
    required this.balance,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF2C2C2E),
                const Color(0xFF1C1C1E),
                const Color(0xFF0A0A0A),
              ]
            : [
                const Color(0xFFF8F9FA),
                const Color(0xFFE9ECEF),
                const Color(0xFFDEE2E6),
              ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: isDark 
          ? Border.all(color: const Color(0xFF38383A), width: 1)
          : Border.all(color: const Color(0xFFE5E5EA), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark 
                      ? const Color(0xFF2C2C2E) 
                      : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: isDark ? Colors.white : const Color(0xFF6D6D70),
                    size: 20,
                  ),
                ),
                Text(
                  l10n.cash,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                      ? const Color(0xFF8E8E93) 
                      : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Balance
            Text(
              l10n.cashBalance,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark 
                  ? const Color(0xFF8E8E93) 
                  : const Color(0xFF6D6D70),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              themeProvider.formatAmount(balance),
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
} 