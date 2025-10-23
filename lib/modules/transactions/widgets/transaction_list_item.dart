import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/design_system/transaction_design_system.dart' as design;
import '../../../core/theme/theme_provider.dart';
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
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: false).currency.symbol;
    final amount = design.TransactionDesignSystem.formatAmount(transaction.amount, transactionType, currencySymbol: currencySymbol);
    
    // Use displayTime from transaction model (dynamic date formatting)
    final time = transaction.displayTime;

    // Get category name
    final categoryName = category?.name ?? transaction.categoryName ?? (AppLocalizations.of(context)?.category ?? 'Category');

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

    // Taksitli ise taksit bilgisini ekle
    String installmentText = '';
    int? effectiveInstallmentCount = transaction.installmentCount;
    int currentInstallment = 1;
    if ((transaction.installmentCount == null || transaction.installmentCount! < 1) && transaction.installmentId != null) {
      final info = Provider.of<UnifiedProviderV2>(context, listen: false).getInstallmentInfo(transaction.installmentId);
      if (info != null) {
        effectiveInstallmentCount = info['totalInstallments'];
        currentInstallment = info['currentInstallment'] ?? 1;
      }
    }
    if (effectiveInstallmentCount != null && effectiveInstallmentCount > 1) {
      installmentText = '$currentInstallment/$effectiveInstallmentCount ${AppLocalizations.of(context)?.installment_summary ?? 'Taksit'}';
    } else if (effectiveInstallmentCount == 1) {
      installmentText = AppLocalizations.of(context)?.cash ?? 'NAKİT';
    }
    final subtitle = installmentText.isNotEmpty ? installmentText : categoryName;

    return design.TransactionDesignSystem.buildTransactionItemFromV2(
      transaction: transaction,
      isDark: isDark,
      time: time,
      categoryIconData: categoryIcon,      // Use direct IconData
      categoryColorData: categoryColor,    // Use direct Color
    );
  }
} 