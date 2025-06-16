import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../l10n/app_localizations.dart';

class BalanceDetailBottomSheet {
  static void show(BuildContext context) {
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
        ),
      ),
    );
  }
}

class _BalanceDetailContent extends StatelessWidget {
  final ScrollController scrollController;

  const _BalanceDetailContent({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, dataProvider, child) {
        // Calculate totals
        final totalBalance = dataProvider.totalBalance;
        final accounts = dataProvider.accounts;
        
        // Get current month transactions for summary
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
        
        final monthlyTransactions = dataProvider.transactions.where((transaction) {
          return transaction.transactionDate.isAfter(currentMonthStart) &&
                 transaction.transactionDate.isBefore(currentMonthEnd.add(const Duration(days: 1)));
        }).toList();
        
        final monthlyIncome = monthlyTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
            
        final monthlyExpenses = monthlyTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

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
                      amount: themeProvider.formatAmount(totalBalance),
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
                    
                    // Dynamic account list
                    ...accounts.map((account) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AccountItem(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        account: account,
                      ),
                    )),
                    
                    if (accounts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF1C1C1E) 
                            : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark 
                            ? Border.all(
                                color: const Color(0xFF38383A),
                                width: 0.5,
                              )
                            : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 48,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz hesap eklenmemiş',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark 
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'İlk hesabınızı ekleyerek başlayın',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark 
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                              ),
                            ),
                          ],
                        ),
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
                            amount: monthlyIncome,
                            icon: Icons.trending_up,
                            color: const Color(0xFF6D6D70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            isDark: isDark,
                            themeProvider: themeProvider,
                            title: l10n.expenses,
                            amount: monthlyExpenses,
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
      },
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
  final AccountModel account;

  const _AccountItem({
    required this.isDark,
    required this.themeProvider,
    required this.account,
  });

  Color _getAccountColor() {
    switch (account.type) {
      case AccountType.debit:
        return const Color(0xFF6D6D70);
      case AccountType.credit:
        return const Color(0xFFEF4444);
      case AccountType.cash:
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF6D6D70);
    }
  }

  String _getAccountTypeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (account.type) {
      case AccountType.debit:
        return l10n.checkingAccount;
      case AccountType.credit:
        return l10n.creditCard;
      case AccountType.cash:
        return l10n.cashAccount;
      default:
        return 'Hesap';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAccountColor();
    final isCreditCard = account.type == AccountType.credit;
    
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
            // TODO: Navigate to account details
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isCreditCard 
                          ? Icons.credit_card_outlined
                          : Icons.account_balance_outlined,
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
                                  account.name,
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
                                _getAccountTypeLabel(context),
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
                          if (isCreditCard) ...[
                            // Credit card specific info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mevcut Borç',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark 
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                  ),
                                ),
                                Text(
                                  themeProvider.formatAmount(account.usedCredit),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: account.usedCredit > 0 
                                      ? const Color(0xFFFF3B30)
                                      : isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kullanılabilir Limit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark 
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                  ),
                                ),
                                Text(
                                  themeProvider.formatAmount(account.availableAmount),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF34C759),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Toplam Limit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark 
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                  ),
                                ),
                                Text(
                                  themeProvider.formatAmount(account.creditLimit ?? 0.0),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark 
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Regular account balance
                            Text(
                              themeProvider.formatAmount(account.balance),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Credit utilization bar for credit cards
                if (isCreditCard && account.creditLimit != null && account.creditLimit! > 0) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kullanım Oranı',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                            ),
                          ),
                          Text(
                            '${account.creditUtilization.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: account.creditUtilization > 80 
                                ? const Color(0xFFFF3B30)
                                : account.creditUtilization > 50
                                  ? const Color(0xFFFF9500)
                                  : const Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (account.creditUtilization / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: account.creditUtilization > 80 
                                ? const Color(0xFFFF3B30)
                                : account.creditUtilization > 50
                                  ? const Color(0xFFFF9500)
                                  : const Color(0xFF34C759),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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