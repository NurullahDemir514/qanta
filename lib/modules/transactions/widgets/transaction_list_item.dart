import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model.dart' as tm;
import '../../../shared/design_system/transaction_design_system.dart';

// Remove the duplicate Transaction class definition
// Import the Transaction class from the models directory

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Convert transaction type to design system type
    TransactionType transactionType;
    switch (transaction.type) {
      case tm.TransactionType.income:
        transactionType = TransactionType.income;
        break;
      case tm.TransactionType.expense:
        transactionType = TransactionType.expense;
        break;
      case tm.TransactionType.transfer:
        transactionType = TransactionType.transfer;
        break;
      default:
        transactionType = TransactionType.expense;
    }

    // Format amount
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType);

    // Format time
    final time = TransactionDesignSystem.formatTime(transaction.date);

    // Get category name
    final categoryName = transaction.category.getName(AppLocalizations.of(context)!);

    return TransactionDesignSystem.buildTransactionItem(
      title: transaction.description,
      subtitle: categoryName,
      amount: amount,
      time: time,
      type: transactionType,
      isDark: isDark,
    );
  }
} 