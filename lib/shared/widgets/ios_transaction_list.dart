import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/payment_card_model.dart' as pcm;
import 'transaction_detail_modal.dart';
import '../design_system/transaction_design_system.dart';
import '../utils/currency_utils.dart';
import 'package:intl/intl.dart';

class IOSTransactionList extends StatelessWidget {
  final List<IOSTransactionItem> transactions;
  final List<pcm.CardTransactionModel>? cardTransactions;
  final String? title;
  final VoidCallback? onSeeAllTap;
  final String? emptyTitle;
  final String? emptyDescription;
  final IconData? emptyIcon;
  final Function(pcm.CardTransactionModel)? onDeleteTransaction;

  const IOSTransactionList({
    super.key,
    this.transactions = const [],
    this.cardTransactions,
    this.title,
    this.onSeeAllTap,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon,
    this.onDeleteTransaction,
  });

  const IOSTransactionList.fromCardTransactions({
    super.key,
    required List<pcm.CardTransactionModel> this.cardTransactions,
    this.title,
    this.onSeeAllTap,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon,
    this.onDeleteTransaction,
  }) : transactions = const [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final displayTransactions = cardTransactions != null 
      ? _convertCardTransactionsToIOSItems(context, cardTransactions!)
      : transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (onSeeAllTap != null)
                  TextButton(
                    onPressed: onSeeAllTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.seeAll,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (displayTransactions.isEmpty)
          _buildEmptyState(isDark, context)
        else
          _buildTransactionList(isDark, displayTransactions),
      ],
    );
  }

  List<IOSTransactionItem> _convertCardTransactionsToIOSItems(BuildContext context, List<pcm.CardTransactionModel> cardTransactions) {
    return cardTransactions.map((cardTransaction) {
      return IOSTransactionItem(
        title: cardTransaction.title,
        subtitle: cardTransaction.card.displayName,
        amount: _formatCardTransactionAmount(cardTransaction, context),
        time: _formatTransactionDate(cardTransaction.date, context),
        icon: cardTransaction.transactionIcon,
        iconColor: cardTransaction.transactionColor,
        iconBackgroundColor: cardTransaction.transactionColor.withValues(alpha: 0.1),
        amountColor: cardTransaction.transactionColor,
        onTap: () => TransactionDetailModal.show(
          context,
          cardTransaction,
        ),
        onLongPress: onDeleteTransaction != null 
          ? () => _showDeleteActionSheet(context, cardTransaction)
          : null,
        cardTransaction: cardTransaction,
      );
    }).toList();
  }

  void _showDeleteActionSheet(BuildContext context, pcm.CardTransactionModel transaction) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'İşlemi Sil',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          '${transaction.title} işlemini silmek istediğinizden emin misiniz?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onDeleteTransaction?.call(transaction);
            },
            child: Text(
              AppLocalizations.of(context)?.delete ?? 'Delete',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)?.cancel ?? 'Cancel',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _buildCardTransactionSubtitle(pcm.CardTransactionModel transaction) {
    return transaction.card.displayName;
  }

  String _formatCardTransactionAmount(pcm.CardTransactionModel transaction, BuildContext context) {
    final amount = transaction.amount.abs();
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    
    // Use CurrencyUtils for proper formatting
    final formattedAmount = CurrencyUtils.formatAmountWithoutSymbol(amount, currency);
    final currencySymbol = currency.symbol;
    
    if (transaction.isIncome) {
      return '+$formattedAmount$currencySymbol';
    } else {
      return '-$formattedAmount$currencySymbol';
    }
  }

  String _formatTransactionDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(date.year, date.month, date.day);
    
    if (transactionDay == today) {
      return AppLocalizations.of(context)?.today ?? 'Today';
    } else if (transactionDay == yesterday) {
      return AppLocalizations.of(context)?.yesterday ?? 'Yesterday';
    } else {
      // Simple date format: 8 Sep or 8/9 format with proper locale
      try {
        final locale = Localizations.localeOf(context);
        final languageCode = locale.languageCode;
        
        String localeString;
        switch (languageCode) {
          case 'en':
            localeString = 'en_US';
            break;
          case 'de':
            localeString = 'de_DE';
            break;
          case 'tr':
          default:
            localeString = 'tr_TR';
            break;
        }
        
        final formatter = DateFormat('d MMM', localeString);
        return formatter.format(date);
      } catch (e) {
        // Fallback: simple format
        return '${date.day}/${date.month}';
      }
    }
  }

  Widget _buildEmptyState(bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            emptyIcon ?? Icons.receipt_long_outlined,
            size: 48,
            color: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
          ),
          const SizedBox(height: 12),
          Text(
            emptyTitle ?? AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emptyDescription ?? AppLocalizations.of(context)?.addFirstTransaction ?? 'Add your first transaction to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isDark, List<IOSTransactionItem> transactions) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
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
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            _IOSTransactionListItem(
              transaction: transactions[i],
              isDark: isDark,
              isFirst: i == 0,
              isLast: i == transactions.length - 1,
            ),
            if (i < transactions.length - 1)
              _IOSTransactionDivider(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _IOSTransactionListItem extends StatelessWidget {
  final IOSTransactionItem transaction;
  final bool isDark;
  final bool isFirst;
  final bool isLast;

  const _IOSTransactionListItem({
    required this.transaction,
    required this.isDark,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Use the new TransactionDesignSystem method that supports specific icons
    return TransactionDesignSystem.buildTransactionItemWithIcon(
      title: transaction.title,
      subtitle: transaction.subtitle,
      amount: transaction.amount,
      time: transaction.time,
      isDark: isDark,
      specificIcon: transaction.icon,
      specificIconColor: transaction.iconColor,
      specificBackgroundColor: transaction.iconBackgroundColor,
      specificAmountColor: transaction.amountColor,
      onTap: transaction.onTap,
      onLongPress: transaction.onLongPress,
      isFirst: isFirst,
      isLast: isLast,
      isPaid: false, // CardTransactionModel doesn't have isPaid field yet
    );
  }
}

class _IOSTransactionDivider extends StatelessWidget {
  final bool isDark;

  const _IOSTransactionDivider({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(
        height: 0.5,
        color: isDark 
          ? const Color(0xFF38383A)
          : const Color(0xFFE5E5EA),
      ),
    );
  }
}

class IOSTransactionItem {
  final String title;
  final String subtitle;
  final String amount;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color amountColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final pcm.CardTransactionModel? cardTransaction;

  const IOSTransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.amountColor,
    this.onTap,
    this.onLongPress,
    this.cardTransaction,
  });

  factory IOSTransactionItem.income({
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    IconData? icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    pcm.CardTransactionModel? cardTransaction,
  }) {
    const incomeColor = Color(0xFF34C759);
    return IOSTransactionItem(
      title: title,
      subtitle: subtitle,
      amount: '+$amount',
      time: time,
      icon: icon ?? Icons.trending_up_rounded,
      iconColor: incomeColor,
      iconBackgroundColor: incomeColor.withValues(alpha: 0.1),
      amountColor: incomeColor,
      onTap: onTap,
      onLongPress: onLongPress,
      cardTransaction: cardTransaction,
    );
  }

  factory IOSTransactionItem.expense({
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    IconData? icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    pcm.CardTransactionModel? cardTransaction,
  }) {
    const expenseColor = Color(0xFFFF3B30);
    return IOSTransactionItem(
      title: title,
      subtitle: subtitle,
      amount: '-$amount',
      time: time,
      icon: icon ?? Icons.trending_down_rounded,
      iconColor: expenseColor,
      iconBackgroundColor: expenseColor.withValues(alpha: 0.1),
      amountColor: expenseColor,
      onTap: onTap,
      onLongPress: onLongPress,
      cardTransaction: cardTransaction,
    );
  }
} 