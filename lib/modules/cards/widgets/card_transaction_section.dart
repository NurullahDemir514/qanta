import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/widgets/installment_expandable_card.dart';
import '../../../shared/services/category_icon_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CardTransactionSection extends StatefulWidget {
  final String cardId;
  final String cardName;

  const CardTransactionSection({
    super.key,
    required this.cardId,
    required this.cardName,
  });

  @override
  State<CardTransactionSection> createState() => _CardTransactionSectionState();
}

class _CardTransactionSectionState extends State<CardTransactionSection> {
  @override
  void initState() {
    super.initState();
    // V2 provider handles all data loading automatically
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        debugPrint('🎯 CardTransactionSection using V2 provider for card: ${widget.cardName}');
        
        // Use v2 provider data - filter transactions by account
        final account = providerV2.getAccountById(widget.cardId);
        if (account == null) {
          return _buildEmptyState(isDark);
        }
        
        final v2Transactions = providerV2.getTransactionsByAccount(widget.cardId);
        final isLoadingV2 = providerV2.isLoadingTransactions;
        
        // V2 Content
        if (isLoadingV2 && v2Transactions.isEmpty) {
          return TransactionDesignSystem.buildLoadingSkeleton(
            isDark: isDark,
            itemCount: 3,
          );
        } else if (v2Transactions.isEmpty) {
          return _buildEmptyState(isDark);
        } else {
          // Use TransactionDesignSystem.buildTransactionList for consistent design
          final transactionWidgets = v2Transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            
            return _buildV2TransactionWidget(
              context,
              transaction, 
              isDark,
              isFirst: index == 0,
              isLast: index == v2Transactions.length - 1,
            );
          }).toList();
          
          return TransactionDesignSystem.buildTransactionList(
            transactions: transactionWidgets,
            isDark: isDark,
            emptyTitle: 'Henüz işlem yok',
            emptyDescription: 'Bu kart için henüz işlem bulunmuyor',
            emptyIcon: Icons.receipt_long_outlined,
          );
        }
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz işlem yok',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kart için henüz işlem bulunmuyor',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build individual transaction widget for V2 provider
  Widget _buildV2TransactionWidget(
    BuildContext context,
    v2.TransactionWithDetailsV2 transaction, 
    bool isDark, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Convert V2 transaction type to design system type
    TransactionType transactionType;
    switch (transaction.type) {
      case v2.TransactionType.income:
        transactionType = TransactionType.income;
        break;
      case v2.TransactionType.expense:
        transactionType = TransactionType.expense;
        break;
      case v2.TransactionType.transfer:
        transactionType = TransactionType.transfer;
        break;
    }

    // Get category info from provider
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    final category = transaction.categoryId != null 
        ? providerV2.getCategoryById(transaction.categoryId!)
        : null;

    // FALLBACK: Check if description contains installment pattern like (1/4)
    final hasInstallmentPattern = RegExp(r'\(\d+/\d+\)').hasMatch(transaction.description);
    final isActualInstallment = transaction.isInstallment || hasInstallmentPattern;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;
    
    // Card name - for transfers, show source → target
    String cardName = widget.cardName;
    if (transactionType == TransactionType.transfer) {
      final sourceAccount = transaction.sourceAccountName ?? 'Hesap';
      final targetAccount = transaction.targetAccountName ?? 'Hesap';
      cardName = TransactionDesignSystem.formatTransferSubtitle(sourceAccount, targetAccount);
    } else {
      // Shorten regular card names
      cardName = TransactionDesignSystem.shortenAccountName(cardName);
    }

    // Format amount
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType);

    // Format time
    final time = TransactionDesignSystem.formatTime(transaction.transactionDate);

    // Check if this should be displayed as an installment
    if (isActualInstallment) {
      // Extract installment info from pattern if available
      Map<String, int?>? installmentInfo;
      if (hasInstallmentPattern) {
        final match = RegExp(r'\((\d+)/(\d+)\)').firstMatch(transaction.description);
        if (match != null) {
          installmentInfo = {
            'currentInstallment': int.tryParse(match.group(1)!),
            'totalInstallments': int.tryParse(match.group(2)!),
          };
        }
      }

      // Get installment count for title
      final totalInstallments = installmentInfo?['totalInstallments'];
      final installmentSuffix = totalInstallments != null ? ' ($totalInstallments Taksit)' : ' (Taksitli)';

      // Remove installment pattern from title for cleaner display
      final cleanTitle = title.replaceAll(RegExp(r'\s*\(\d+/\d+\)'), '');

      return InstallmentExpandableCard(
        installmentId: transaction.installmentId, // This might be null for fallback cases
        title: '$cleanTitle$installmentSuffix',
        subtitle: cardName,
        amount: amount,
        time: time,
        type: transactionType,
        categoryIcon: category?.icon,
        categoryColor: category?.color,
        isDark: isDark,
        isFirst: isFirst,
        isLast: isLast,
        currentInstallment: installmentInfo?['currentInstallment'],
        totalInstallments: installmentInfo?['totalInstallments'],
        onLongPress: () {
          print('🔍 Long press detected on installment transaction: ${transaction.description}');
          HapticFeedback.mediumImpact();
          _showInstallmentDeleteActionSheet(context, transaction, installmentInfo);
        },
      );
    }

    // Get category icon using CategoryIconService - prioritize category name
    IconData? categoryIcon;
    
    // First try category name (more reliable than database icon field)
    if (transaction.categoryName != null) {
      categoryIcon = CategoryIconService.getIcon(transaction.categoryName!.toLowerCase());
    } 
    
    // Only fallback to category.icon if category name lookup failed
    if (categoryIcon == null || categoryIcon == Icons.more_horiz_rounded) {
      if (category?.icon != null && category!.icon != 'category') {
        categoryIcon = CategoryIconService.getIcon(category.icon);
      }
    }

    // Get category color using CategoryIconService - prioritize centralized colors
    Color? categoryColor;
    
    // First try to get color from centralized map using category name or icon
    if (transaction.categoryName != null) {
      // Try category name first (e.g., "market", "yemek", etc.)
      categoryColor = CategoryIconService.getColorFromMap(
        transaction.categoryName!.toLowerCase(),
        categoryType: transactionType == TransactionType.income ? 'income' : 'expense',
      );
    } else if (category?.icon != null) {
      // Try icon name (e.g., "restaurant", "car", etc.)
      categoryColor = CategoryIconService.getColorFromMap(
        category!.icon,
        categoryType: transactionType == TransactionType.income ? 'income' : 'expense',
      );
    }
    
    // If no centralized color found, fall back to hex color from database
    if (categoryColor == null || categoryColor == CategoryIconService.getColorFromMap('default')) {
      if (category?.color != null) {
        categoryColor = CategoryIconService.getColor(category!.color);
      } else if (category?.icon != null) {
        // Use predefined colors based on category type and icon
        final isIncomeCategory = transactionType == TransactionType.income;
        categoryColor = CategoryIconService.getCategoryColor(
          iconName: category!.icon,
          colorHex: category.color,
          isIncomeCategory: isIncomeCategory,
        );
      }
    }

    return TransactionDesignSystem.buildTransactionItem(
      title: title,
      subtitle: cardName,
      amount: amount,
      time: time,
      type: transactionType,
      categoryIconData: categoryIcon,      // Use direct IconData
      categoryColorData: categoryColor,    // Use direct Color
      isDark: isDark,
      isFirst: isFirst,
      isLast: isLast,
      onLongPress: () {
        print('🔍 Long press detected on v2 card transaction: ${transaction.description}');
        HapticFeedback.mediumImpact();
        _showV2DeleteActionSheet(context, transaction);
      },
    );
  }

  /// Show delete action sheet for V2 transactions
  void _showV2DeleteActionSheet(BuildContext context, v2.TransactionWithDetailsV2 transaction) {
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
          '${transaction.description} işlemini silmek istediğinizden emin misiniz?',
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
              _deleteV2Transaction(context, transaction);
            },
            child: Text(
              'Sil',
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
            'İptal',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Delete V2 transaction
  Future<void> _deleteV2Transaction(BuildContext context, v2.TransactionWithDetailsV2 transaction) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      await providerV2.deleteTransaction(transaction.id);
      
      // Başarı mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silindi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Hata mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show installment delete action sheet
  void _showInstallmentDeleteActionSheet(BuildContext context, v2.TransactionWithDetailsV2 transaction, Map<String, int?>? installmentInfo) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Taksitli İşlemi Sil',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          '${transaction.description} taksitli işlemini tamamen silmek istediğinizden emin misiniz? Bu işlem tüm taksitleri silecektir.',
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
              _deleteInstallmentTransaction(context, transaction);
            },
            child: Text(
              'Sil',
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
            'İptal',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Delete installment transaction
  Future<void> _deleteInstallmentTransaction(BuildContext context, v2.TransactionWithDetailsV2 transaction) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      debugPrint('🗑️ CardTransactionSection: Deleting installment transaction: ${transaction.id}');

      // Use enhanced installment deletion that refunds total amount
      await providerV2.deleteInstallmentTransaction(transaction.id);

      debugPrint('✅ CardTransactionSection: Installment transaction deleted successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Taksitli işlem başarıyla silindi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ CardTransactionSection: Error deleting installment transaction: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 