import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

class BalanceDetailBottomSheet {
  static void show(BuildContext context, ThemeProvider themeProvider, AppLocalizations l10n, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _BalanceDetailContent(
          scrollController: scrollController,
          themeProvider: themeProvider,
          l10n: l10n,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _BalanceDetailContent extends StatelessWidget {
  final ScrollController scrollController;
  final ThemeProvider themeProvider;
  final AppLocalizations l10n;
  final bool isDark;

  const _BalanceDetailContent({
    required this.scrollController,
    required this.themeProvider,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E)
          : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF48484A)
                : const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Total Balance Card
                _DetailCard(
                  isDark: isDark,
                  title: l10n.totalBalance,
                  amount: themeProvider.formatAmount(47320.75),
                  subtitle: l10n.allAccountsTotal,
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF007AFF),
                ),
                
                const SizedBox(height: 16),
                
                // Account Breakdown
                Text(
                  l10n.accountBreakdown,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                _AccountItem(
                  isDark: isDark,
                  themeProvider: themeProvider,
                  accountName: l10n.qantaDebit,
                  accountType: l10n.checkingAccount,
                  balance: 24580.50,
                  color: const Color(0xFF10B981),
                ),
                
                const SizedBox(height: 12),
                
                _AccountItem(
                  isDark: isDark,
                  themeProvider: themeProvider,
                  accountName: l10n.qantaCredit,
                  accountType: l10n.creditCard,
                  balance: 15240.00,
                  color: const Color(0xFFEF4444),
                ),
                
                const SizedBox(height: 12),
                
                _AccountItem(
                  isDark: isDark,
                  themeProvider: themeProvider,
                  accountName: l10n.qantaSavings,
                  accountType: l10n.savingsAccount,
                  balance: 7500.25,
                  color: const Color(0xFF60A5FA),
                ),
                
                const SizedBox(height: 24),
                
                // Monthly Summary
                Text(
                  l10n.monthlySummary,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        title: l10n.income,
                        amount: 8420.00,
                        icon: Icons.trending_up,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        title: l10n.expenses,
                        amount: 3280.00,
                        icon: Icons.trending_down,
                        color: const Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.isDark,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle card tap
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            amount,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountItem extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final String accountName;
  final String accountType;
  final double balance;
  final Color color;

  const _AccountItem({
    required this.isDark,
    required this.themeProvider,
    required this.accountName,
    required this.accountType,
    required this.balance,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle account tap
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              accountName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            accountType,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeProvider.formatAmount(balance),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.isDark,
    required this.themeProvider,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle summary tap
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeProvider.formatAmount(amount),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 