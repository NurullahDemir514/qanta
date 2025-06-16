import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/design_system/transaction_design_system.dart' as design;
import '../../../shared/services/category_icon_service.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionWithDetailsV2 transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unifiedProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
    
    // Map transaction type from V2 to design system enum
    design.TransactionType transactionType;
    switch (transaction.type) {
      case TransactionType.income:
        transactionType = design.TransactionType.income;
        break;
      case TransactionType.expense:
        transactionType = design.TransactionType.expense;
        break;
      case TransactionType.transfer:
        transactionType = design.TransactionType.transfer;
        break;
    }

    // Get category information
    final category = unifiedProvider.categories
        .where((cat) => cat.id == transaction.categoryId)
        .firstOrNull;

    // Format amount with proper sign and currency
    final amount = design.TransactionDesignSystem.formatAmount(transaction.amount, transactionType);
    
    // Format time
    final time = transaction.transactionDate != null 
        ? design.TransactionDesignSystem.formatTime(transaction.transactionDate!)
        : null;

    // Get category name
    final categoryName = category?.name ?? transaction.categoryName ?? 'Kategori';

    // Get category icon using CategoryIconService
    IconData? categoryIcon;
    if (category?.icon != null) {
      categoryIcon = CategoryIconService.getIcon(category!.icon);
    } else if (transaction.categoryName != null) {
      // Fallback to category name for icon lookup
      categoryIcon = CategoryIconService.getIcon(transaction.categoryName!);
    }

    // Get category color using CategoryIconService
    Color? categoryColor;
    if (category?.color != null) {
      categoryColor = CategoryIconService.getColor(category!.color);
    } else if (category?.icon != null) {
      // Use predefined colors based on category type and icon
      final isIncomeCategory = transactionType == design.TransactionType.income;
      categoryColor = CategoryIconService.getCategoryColor(
        iconName: category!.icon,
        colorHex: category.color,
        isIncomeCategory: isIncomeCategory,
      );
    }

    return design.TransactionDesignSystem.buildTransactionItem(
      title: transaction.description,
      subtitle: categoryName,
      amount: amount,
      time: time,
      type: transactionType,
      categoryIconData: categoryIcon,      // Use direct IconData
      categoryColorData: categoryColor,    // Use direct Color
      isDark: isDark,
    );
  }
} 