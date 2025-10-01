import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/models_v2.dart' as v2;
import '../../../shared/widgets/installment_expandable_card.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../stocks/providers/stock_provider.dart';

class RecentTransactionsSection extends StatefulWidget {
  const RecentTransactionsSection({super.key});

  @override
  State<RecentTransactionsSection> createState() => _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<RecentTransactionsSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        final buildStartTime = DateTime.now();
        final v2Transactions = providerV2.recentTransactions;
        final isLoadingV2 = providerV2.isLoadingTransactions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Text(
                l10n.recentTransactions,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // V2 İçerik
            // Loading skeleton kaldırıldı - normal UI göster
            // if (isLoadingV2 && v2Transactions.isEmpty)
            //   TransactionDesignSystem.buildLoadingSkeleton(
            //     isDark: isDark,
            //     itemCount: 3,
            //   )
            // else 
            if (v2Transactions.isEmpty)
              _buildEmptyState(isDark)
            else
              _buildV2TransactionList(context, v2Transactions, isDark),
          ],
        );
        
        // Debug: Measure build time
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final buildEndTime = DateTime.now();
          final buildDuration = buildEndTime.difference(buildStartTime).inMilliseconds;
        });
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.addFirstTransaction ?? 'Add your first transaction to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build transaction list for V2 provider
  Widget _buildV2TransactionList(BuildContext context, List<v2.TransactionWithDetailsV2> transactions, bool isDark) {
    if (transactions.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final transactionWidgets = transactions.asMap().entries.map((entry) {
      final index = entry.key;
      final transaction = entry.value;
      
      return _buildV2TransactionWidget(
        context,
        transaction, 
        isDark,
        isFirst: index == 0,
        isLast: index == transactions.length - 1,
      );
    }).toList();

    return TransactionDesignSystem.buildTransactionList(
      transactions: transactionWidgets,
      isDark: isDark,
      emptyTitle: AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet',
      emptyDescription: AppLocalizations.of(context)?.addFirstTransaction ?? 'Add your first transaction to get started',
      emptyIcon: Icons.receipt_long_outlined,
      context: context,
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
      case v2.TransactionType.stock:
        transactionType = TransactionType.income; // Treat stock as income for display
        break;
    }

    // Get category info from provider
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    final category = transaction.categoryId != null 
        ? providerV2.getCategoryById(transaction.categoryId!)
        : null;

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

    // Use transaction type color instead of category color
    // This ensures all income transactions are green, all expense transactions are red

    // Check if this is an installment transaction
    final hasInstallmentPattern = RegExp(r'\(\d+ taksit\)').hasMatch(transaction.description);
    final isActualInstallment = transaction.isInstallment || hasInstallmentPattern;
    
    // Parse installment info if it's an installment
    int? totalInstallments;
    double? totalAmount;
    double? monthlyAmount;
    
    if (isActualInstallment) {
      final installmentMatch = RegExp(r'\((\d+) taksit\)').firstMatch(transaction.description);
      if (installmentMatch != null) {
        totalInstallments = int.tryParse(installmentMatch.group(1)!);
        totalAmount = transaction.amount;
        monthlyAmount = totalAmount / (totalInstallments ?? 1);
      }
    }

    // Format amount with dynamic currency
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: false).currency.symbol;
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType, currencySymbol: currencySymbol);

    // Use displayTime from transaction model (dynamic date formatting)
    final time = transaction.displayTime;

    // Card name - centralized logic
    final cardName = TransactionDesignSystem.formatCardName(
      cardName: transaction.sourceAccountName ?? AppLocalizations.of(context)?.account ?? 'Account',
      transactionType: transactionType.name,
      sourceAccountName: transaction.sourceAccountName,
      targetAccountName: transaction.targetAccountName,
      context: context,
    );

    // Check if this should be displayed as an installment
    if (isActualInstallment) {
      return InstallmentExpandableCard(
        installmentId: transaction.installmentId,
        title: transaction.categoryName ?? transaction.description, // Kategori adı
        subtitle: cardName, // Banka adı
        amount: amount,
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
        isPaid: transaction.isPaid,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showInstallmentDeleteActionSheet(context, transaction, null);
        },
      );
    }

    // Regular transaction - use Firebase integrated design system
    return TransactionDesignSystem.buildTransactionItemFromV2(
      transaction: transaction,
      isDark: isDark,
      time: time,
      categoryIconData: categoryIcon,
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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          l10n.deleteTransaction,
                  style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          l10n.deleteTransactionConfirmation(transaction.description),
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

  /// Delete V2 transaction
  void _deleteV2Transaction(BuildContext context, v2.TransactionWithDetailsV2 transaction) {
    final l10n = AppLocalizations.of(context)!;
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    
    // Check if this is a stock transaction
    if (transaction.isStockTransaction) {
      
      // 1. OPTIMISTIC UI UPDATE - Önce UI'yi anında güncelle (net değer ve kartlar dahil)
      providerV2.removeStockTransactionOptimistically(
        transaction.id, 
        transaction.amount, 
        transaction.sourceAccountId
      );
      
      // 2. Use StockProvider for stock transactions
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      
      stockProvider.deleteStockTransaction(transaction.id).then((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.transactionDeleted ?? 'Transaction deleted'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }).catchError((e) {
        
        // Hata durumunda UI'yi geri yükle
        providerV2.refreshTransactions();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.transactionDeleteError(e.toString())),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      // Regular transaction - use UnifiedProviderV2
      providerV2.deleteTransaction(transaction.id).then((success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? (AppLocalizations.of(context)?.transactionDeleted ?? 'Transaction deleted') : (AppLocalizations.of(context)?.deleteFailed ?? 'Delete failed')),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }).catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.transactionDeleteError(e.toString())),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }


  /// Show installment delete action sheet
  void _showInstallmentDeleteActionSheet(BuildContext context, v2.TransactionWithDetailsV2 transaction, Map<String, int?>? installmentInfo) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          l10n.deleteInstallmentTransaction,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          l10n.deleteInstallmentConfirmation(transaction.description),
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

  /// Delete installment transaction
  Future<void> _deleteInstallmentTransaction(BuildContext context, v2.TransactionWithDetailsV2 transaction) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      await providerV2.deleteInstallmentTransaction(transaction.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.installmentTransactionDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.installmentDeleteError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 