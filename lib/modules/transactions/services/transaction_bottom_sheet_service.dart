import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/transaction_type_selector.dart';
import '../../../shared/models/transaction_model.dart';
import '../screens/expense_form_screen.dart';
import '../screens/income_form_screen.dart';
import '../screens/transfer_form_screen.dart';

class TransactionBottomSheetService {
  static void show(
    BuildContext context, {
    VoidCallback? onClosed,
  }) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.6],
        builder: (context, scrollController) => TransactionTypeSelector(
          scrollController: scrollController,
          onTransactionTypeSelected: (transactionType) {
            Navigator.pop(context);
            _handleTransactionTypeSelection(context, transactionType);
          },
        ),
      ),
    ).whenComplete(() {
      onClosed?.call();
    });
  }

  static void _handleTransactionTypeSelection(
    BuildContext context,
    TransactionType transactionType,
  ) {
    HapticFeedback.selectionClick();
    
    switch (transactionType) {
      case TransactionType.income:
        _showIncomeForm(context);
        break;
      case TransactionType.expense:
        _showExpenseForm(context);
        break;
      case TransactionType.transfer:
        _showTransferForm(context);
        break;
    }
  }

  static void _showIncomeForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomeFormScreen(),
      ),
    );
  }

  static void _showExpenseForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseFormScreen(),
      ),
    );
  }

  static void _showTransferForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransferFormScreen(),
      ),
    );
  }
} 