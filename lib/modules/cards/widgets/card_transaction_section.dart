import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../shared/models/account_model.dart';
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
    // Card section açılırken taksit verilerini güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      provider.loadInstallments();
      // Load transactions for this specific card
      _loadCardTransactions(provider);
    });
  }

  /// Load transactions for this specific card
  Future<void> _loadCardTransactions(UnifiedProviderV2 provider) async {
    try {
      final account = provider.getAccountById(widget.cardId);
      if (account == null) return;

      switch (account.type) {
        case AccountType.credit:
          await provider.getCreditCardTransactions(creditCardId: widget.cardId);
          break;
        case AccountType.debit:
          await provider.getDebitCardTransactions(debitCardId: widget.cardId);
          break;
        case AccountType.cash:
          await provider.getCashAccountTransactions(cashAccountId: widget.cardId);
          break;
      }
    } catch (e) {
      debugPrint('Error loading card transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
    
        
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
            emptyTitle: AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet',
            emptyDescription: AppLocalizations.of(context)?.noTransactionsForThisCard ?? 'No transactions found for this card',
            emptyIcon: Icons.receipt_long_outlined,
            context: context,
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
            AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.noTransactionsForThisCard ?? 'No transactions found for this card',
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

    // FALLBACK: Check if description contains installment pattern like (1/4) or (3 taksit)
    final hasInstallmentPattern = RegExp(r'\(\d+/\d+\)').hasMatch(transaction.description);
    final hasInstallmentText = RegExp(r'\(\d+ taksit\)').hasMatch(transaction.description);
    final isActualInstallment = transaction.isInstallment || hasInstallmentPattern || hasInstallmentText;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;
    // Taksitli ise taksit bilgisini ekleme, sadece InstallmentExpandableCard'da gösterilecek
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
      installmentText = '$currentInstallment/$effectiveInstallmentCount Taksit';
    } else if (effectiveInstallmentCount == 1) {
      installmentText = AppLocalizations.of(context)?.cash ?? 'Cash';
    }
    
    // Card name - centralized logic
    final cardName = TransactionDesignSystem.formatCardName(
      cardName: widget.cardName,
      transactionType: transactionType.name,
      sourceAccountName: transaction.sourceAccountName,
      targetAccountName: transaction.targetAccountName,
      context: context,
    );

    // Format amount with dynamic currency
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: false).currency.symbol;
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType, currencySymbol: currencySymbol);

    // Use displayTime from transaction model (dynamic date formatting)
    final time = transaction.displayTime;

    // Check if this should be displayed as an installment
    if (isActualInstallment) {
      // Extract installment info from description
      String cleanTitle = title;
      int? totalInstallments;
      double? totalAmount;
      double? monthlyAmount;
      
      // Parse "(3 taksit)" pattern
      final installmentMatch = RegExp(r'\((\d+) taksit\)').firstMatch(transaction.description);
      if (installmentMatch != null) {
        totalInstallments = int.tryParse(installmentMatch.group(1)!);
        totalAmount = transaction.amount; // This is the total amount
        monthlyAmount = totalAmount / (totalInstallments ?? 1); // Calculate monthly amount
        cleanTitle = transaction.description.replaceAll(RegExp(r'\s*\(\d+ taksit\)'), '').trim();
        
      }
      
      
      return InstallmentExpandableCard(
        installmentId: transaction.installmentId,
        title: transaction.categoryName ?? transaction.description, // Kategori adı
        subtitle: cardName, // Banka adı
        amount: TransactionDesignSystem.formatAmount(totalAmount ?? transaction.amount, transactionType, currencySymbol: currencySymbol),
        time: time,
        type: transactionType,
        categoryIcon: transaction.categoryName ?? category?.iconName,
        categoryColor: category?.colorHex,
        isDark: isDark,
        isFirst: isFirst,
        isLast: isLast,
        currentInstallment: 1,
        totalInstallments: totalInstallments,
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        isPaid: false,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showInstallmentDeleteActionSheet(context, transaction, null);
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
        categoryIcon = CategoryIconService.getIcon(category.iconName);
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
        category!.iconName,
        categoryType: transactionType == TransactionType.income ? 'income' : 'expense',
      );
    }
    
    // If no centralized color found, fall back to hex color from database
    if (categoryColor == null || categoryColor == CategoryIconService.getColorFromMap('default')) {
      if (category?.color != null) {
        categoryColor = CategoryIconService.getColor(category!.colorHex);
      } else if (category?.icon != null) {
        // Use predefined colors based on category type and icon
        final isIncomeCategory = transactionType == TransactionType.income;
        categoryColor = CategoryIconService.getCategoryColor(
          iconName: category!.iconName,
          colorHex: category.colorHex,
          isIncomeCategory: isIncomeCategory,
        );
      }
    }

    // Regular transaction - use Firebase integrated design system
    return TransactionDesignSystem.buildTransactionItemFromV2(
      transaction: transaction,
      isDark: isDark,
      time: time,
      categoryIconData: categoryIcon,
      categoryColorData: categoryColor,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showV2DeleteActionSheet(context, transaction);
      },
      isFirst: isFirst,
      isLast: isLast,
    );
  }

  /// Show delete action sheet for V2 transactions
  void _showV2DeleteActionSheet(BuildContext context, v2.TransactionWithDetailsV2 transaction) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)!.deleteTransaction,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          AppLocalizations.of(context)!.deleteTransactionConfirm(transaction.description),
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
              AppLocalizations.of(context)!.delete,
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
            AppLocalizations.of(context)!.cancel,
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
            content: Text(AppLocalizations.of(context)!.transactionDeleted),
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
            content: Text(AppLocalizations.of(context)!.transactionDeleteError(e.toString())),
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
          AppLocalizations.of(context)!.deleteInstallmentTransaction,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          AppLocalizations.of(context)!.deleteInstallmentTransactionConfirm(transaction.description),
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
              AppLocalizations.of(context)!.delete,
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
            AppLocalizations.of(context)!.cancel,
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


      // Use enhanced installment deletion that refunds total amount
      await providerV2.deleteInstallmentTransaction(transaction.id);

      

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.installmentTransactionDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.transactionDeleteError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 