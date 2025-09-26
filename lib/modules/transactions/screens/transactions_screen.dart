import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/animated_empty_state.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/services/transaction_service_v2.dart' as service;
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_time_period_selector.dart';
import '../widgets/transaction_combined_filters.dart';
import '../widgets/transaction_sort_selector.dart';
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
  final _numberFormat = NumberFormat('#,##0', 'tr_TR'); // Türkçe binlik ayıraç
  
  // Filter state using V2 transaction types
  v2.TransactionType? _selectedFilter;
  TimePeriod _selectedTimePeriod = TimePeriod.all;
  SortType _selectedSortType = SortType.dateNewest;
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
    
    // Apply time period filter
    final dateRange = _selectedTimePeriod.getDateRange();
    if (dateRange != null) {
      filtered = filtered.where((t) {
        final transactionDate = t.transactionDate;
        return transactionDate.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
               transactionDate.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      }).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (t.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Apply sorting
    switch (_selectedSortType) {
      case SortType.dateNewest:
        filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        break;
      case SortType.dateOldest:
        filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        break;
      case SortType.amountHighest:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortType.amountLowest:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortType.alphabetical:
        filtered.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
        break;
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

  void _onTimePeriodChanged(TimePeriod period) {
    setState(() {
      _selectedTimePeriod = period;
    });
  }

  void _onSortTypeChanged(SortType sortType) {
    setState(() {
      _selectedSortType = sortType;
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
      bodyTopPadding: 0, // Stats kartını filtrelerden hemen sonra başlat
      searchBar: TransactionSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
      filters: TransactionCombinedFilters(
        selectedTransactionType: _selectedFilter,
        selectedTimePeriod: _selectedTimePeriod,
        selectedSortType: _selectedSortType,
        onTransactionTypeChanged: _onFilterChanged,
        onTimePeriodChanged: _onTimePeriodChanged,
        onSortTypeChanged: _onSortTypeChanged,
      ),
      onRefresh: _onRefresh,
      scrollController: _scrollController,
      body: _buildBody(filteredTransactions, l10n, isDark),
    );
  }

  Widget _buildBody(List<v2.TransactionWithDetailsV2> transactions, AppLocalizations l10n, bool isDark) {


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

        // Transaction list with quick stats
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Quick stats card
          _buildQuickStatsCard(transactions, isDark),
          const SizedBox(height: 16),
          
          // Transaction list
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

  Widget _buildQuickStatsCard(List<v2.TransactionWithDetailsV2> transactions, bool isDark) {
    // Calculate stats
    double totalIncome = 0;
    double totalExpenses = 0;
    int transactionCount = transactions.length;
    
    for (final transaction in transactions) {
      if (transaction.type == v2.TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == v2.TransactionType.expense) {
        totalExpenses += transaction.amount;
      }
    }
    
    final netAmount = totalIncome - totalExpenses;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Income
          Expanded(
            child: _buildStatItem(
              title: 'Gelir',
              amount: totalIncome,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
          
          // Expenses
          Expanded(
            child: _buildStatItem(
              title: 'Gider',
              amount: totalExpenses,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
          
          // Net
          Expanded(
            child: _buildStatItem(
              title: 'Net',
              amount: netAmount,
              color: netAmount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required double amount,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₺${_formatNumber(amount)}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      // Binlik ayıraçlı tam sayı formatı
      return _numberFormat.format(number);
    }
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

    // FALLBACK: Check if description contains installment pattern like (1/4)
    final hasInstallmentPattern = RegExp(r'\(\d+/\d+\)').hasMatch(transaction.description);
    final isActualInstallment = transaction.isInstallment || hasInstallmentPattern;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;
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
      installmentText = '$effectiveInstallmentCount Taksit';
    } else if (effectiveInstallmentCount == 1) {
      installmentText = 'Peşin';
    }
    if (installmentText.isNotEmpty) {
      title += ' [$installmentText]';
    }

    // Format amount
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType);

    // Use displayTime from transaction model (dynamic date formatting)
    final time = transaction.displayTime;

    // Card name - centralized logic
    final cardName = TransactionDesignSystem.formatCardName(
      cardName: transaction.sourceAccountName ?? 'Hesap',
      transactionType: transactionType.name,
      sourceAccountName: transaction.sourceAccountName,
      targetAccountName: transaction.targetAccountName,
    );

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
      final cleanTitle = transaction.categoryName ?? transaction.description.replaceAll(RegExp(r'\s*\(\d+/\d+\)'), '').replaceAll('Taksitli', '').trim();
      final displayText = installmentText;
      
      // Parse installment info
      int? installmentCount = effectiveInstallmentCount;
      double? installmentTotalAmount = transaction.amount;
      double? installmentMonthlyAmount = installmentTotalAmount / (installmentCount ?? 1);
      
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
        isFirst: false,
        isLast: false,
        currentInstallment: 1,
        totalInstallments: installmentCount,
        totalAmount: installmentTotalAmount,
        monthlyAmount: installmentMonthlyAmount,
        isPaid: transaction.isPaid,
        onLongPress: () {
          _showInstallmentDeleteDialog(context, transaction, null);
        },
      );
    }
    
    // Regular transaction - use Firebase integrated design system
    return TransactionDesignSystem.buildTransactionItemFromV2(
      transaction: transaction,
      isDark: isDark,
      time: time,
      categoryIconData: categoryIcon,
      categoryColorData: categoryColor,
      onLongPress: () {
        _showTransactionDeleteDialog(context, transaction);
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

  /// Show delete dialog for regular transactions
  void _showTransactionDeleteDialog(BuildContext context, v2.TransactionWithDetailsV2 transaction) {
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
          '${transaction.description} işlemini silmek istediğinizden emin misiniz?\n\nTutar: ₺${_numberFormat.format(transaction.amount)}',
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
              _deleteTransaction(transaction);
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


  /// Show delete dialog for installment transactions
  void _showInstallmentDeleteDialog(BuildContext context, v2.TransactionWithDetailsV2 transaction, Map<String, int?>? installmentInfo) {
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
          '${transaction.description} taksitli işlemini tamamen silmek istediğinizden emin misiniz?\n\nToplam Tutar: ₺${_numberFormat.format(transaction.amount)}\n\nBu işlem tüm taksitleri silecek ve ödenen tutarlar geri iade edilecektir.',
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
              _deleteInstallmentTransaction(transaction);
            },
            child: Text(
              'Tümünü Sil',
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

  /// Delete regular transaction
  void _deleteTransaction(v2.TransactionWithDetailsV2 transaction) {
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    
    // Delete in background immediately
    providerV2.deleteTransaction(transaction.id).then((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'İşlem silindi' : 'Silme işlemi başarısız'),
            backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silinirken hata oluştu: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  /// Delete installment transaction
  Future<void> _deleteInstallmentTransaction(v2.TransactionWithDetailsV2 transaction) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taksitli işlem siliniyor...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Delete installment transaction using provider
      final success = await providerV2.deleteInstallmentTransaction(transaction.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taksitli işlem silindi'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Taksitli işlem silinirken hata oluştu: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 