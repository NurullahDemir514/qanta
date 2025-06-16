import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/animated_empty_state.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../core/providers/unified_provider_v2.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/transaction_search_bar.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/widgets/ios_transaction_list.dart';
import '../../../shared/models/payment_card_model.dart' as pcm;
import '../../../shared/widgets/installment_expandable_card.dart';
import '../../../shared/services/category_icon_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Filter state using V2 transaction types
  v2.TransactionType? _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // V2 provider will handle data loading automatically
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<v2.TransactionWithDetailsV2> _getFilteredTransactions(List<v2.TransactionWithDetailsV2> transactions) {
    var filtered = transactions;
    
    // Apply type filter
    if (_selectedFilter != null) {
      filtered = filtered.where((t) => t.type == _selectedFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (t.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(v2.TransactionType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _onRefresh() async {
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    await providerV2.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final filteredTransactions = _getFilteredTransactions(Provider.of<UnifiedProviderV2>(context).transactions);
    
    return AppPageScaffold(
      title: l10n.transactions,
      searchBar: TransactionSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
      filters: TransactionFilterChips(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
            ),
      onRefresh: _onRefresh,
      scrollController: _scrollController,
      body: _buildBody(filteredTransactions, l10n, isDark),
    );
  }

  Widget _buildBody(List<v2.TransactionWithDetailsV2> transactions, AppLocalizations l10n, bool isDark) {
    print('🔍 TransactionsScreen build - TransactionCount: ${transactions.length}');

    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        // Show loading if provider is still loading
        if (providerV2.isLoadingTransactions && transactions.isEmpty) {
      return SliverFillRemaining(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TransactionDesignSystem.buildLoadingSkeleton(
            isDark: isDark,
            itemCount: 8,
          ),
        ),
      );
    }

        // Empty state
        if (transactions.isEmpty) {
      return SliverFillRemaining(
              child: _buildEmptyState(l10n, isDark),
      );
    }

        // Transaction list
    return SliverToBoxAdapter(
      child: Column(
        children: [
          if (transactions.isNotEmpty) ...[
            TransactionDesignSystem.buildTransactionList(
              transactions: _buildTransactionWidgets(transactions, isDark),
              isDark: isDark,
              emptyTitle: 'Henüz işlem yok',
              emptyDescription: 'İlk işleminizi eklemek için + butonuna dokunun',
              emptyIcon: Icons.receipt_long_outlined,
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  List<Widget> _buildTransactionWidgets(List<v2.TransactionWithDetailsV2> transactions, bool isDark) {
    return transactions.map((transaction) => _buildTransactionWidget(transaction, isDark)).toList();
  }

  Widget _buildTransactionWidget(v2.TransactionWithDetailsV2 transaction, bool isDark) {
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
      final isIncomeCategory = transactionType == TransactionType.income;
      categoryColor = CategoryIconService.getCategoryColor(
        iconName: category!.icon,
        colorHex: category.color,
        isIncomeCategory: isIncomeCategory,
      );
    }

    // FALLBACK: Check if description contains installment pattern like (1/4)
    final hasInstallmentPattern = RegExp(r'\(\d+/\d+\)').hasMatch(transaction.description);
    final isActualInstallment = transaction.isInstallment || hasInstallmentPattern;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;

    // Format amount
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType);

    // Format time
    final time = TransactionDesignSystem.formatTime(transaction.transactionDate);

    // Card name
    String cardName = transaction.sourceAccountName ?? 'Hesap';
    
    // For transfer transactions, show source → target
    if (transactionType == TransactionType.transfer) {
      final sourceAccount = transaction.sourceAccountName ?? 'Hesap';
      final targetAccount = transaction.targetAccountName ?? 'Hesap';
      cardName = TransactionDesignSystem.formatTransferSubtitle(sourceAccount, targetAccount);
    } else {
      // Shorten regular card names
      cardName = TransactionDesignSystem.shortenAccountName(cardName);
    }

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
      final cleanTitle = transaction.categoryName ?? transaction.description.replaceAll(RegExp(r'\s*\(\d+/\d+\)'), '');
      
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
        currentInstallment: installmentInfo?['currentInstallment'],
        totalInstallments: installmentInfo?['totalInstallments'],
        onLongPress: () {
          _showInstallmentDeleteDialog(context, transaction, installmentInfo);
        },
      );
    }
    
    // Regular transaction - use new centralized color system
    return TransactionDesignSystem.buildTransactionItem(
      title: title,
      subtitle: cardName,
      amount: amount,
      time: time,
      type: transactionType,
      categoryIconData: categoryIcon,      // Use direct IconData
      categoryColorData: categoryColor,    // Use direct Color
      isDark: isDark,
      onLongPress: () {
        // TODO: Add delete functionality if needed
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return AnimatedEmptyState(
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFF10B981),
      title: l10n.noTransactionsYet,
      description: l10n.noTransactionsDescription,
    );
  }

  void _showInstallmentDeleteDialog(BuildContext context, v2.TransactionWithDetailsV2 transaction, Map<String, int?>? installmentInfo) {
    // Implement the logic to show the delete dialog
  }
} 