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
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_time_period_selector.dart';
import '../widgets/transaction_combined_filters.dart';
import '../widgets/transaction_sort_selector.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../core/theme/theme_provider.dart';
import '../../stocks/providers/stock_provider.dart';
import '../../../shared/widgets/installment_expandable_card.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _numberFormat = NumberFormat('#,##0', 'tr_TR'); // Türkçe binlik ayıraç
  late AppLocalizations l10n;
  late GoogleAdsRealBannerService _transactionsBannerService;

  // Filter state using V2 transaction types
  v2.TransactionType? _selectedFilter;
  TimePeriod _selectedTimePeriod = TimePeriod.all;
  SortType _selectedSortType = SortType.dateNewest;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // V2 provider will handle data loading automatically
    
    // İşlemler sayfası banner reklamını başlat
    _transactionsBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.testBanner1.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: true,
    );
    
    debugPrint('🔄 İŞLEMLER SAYFASI Banner reklam yükleniyor...');
    debugPrint('📱 Ad Unit ID: ${config.AdvertisementConfig.testBanner1.bannerAdUnitId}');
    debugPrint('🧪 Test Mode: true');
    debugPrint('📍 Konum: İşlemler sayfası - Gelir/Gider kartı altı');
    
    // İşlemler sayfası reklamını 5 saniye geciktir
    Future.delayed(const Duration(seconds: 5), () {
      _transactionsBannerService.loadAd();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _transactionsBannerService.dispose();
    super.dispose();
  }

  String _getTransactionSubtitle(
    List<v2.TransactionWithDetailsV2> transactions,
    AppLocalizations l10n,
  ) {
    if (transactions.isEmpty) {
      return l10n.noTransactionsFound;
    }

    // Gider işlemlerini filtrele (yatırım işlemleri hariç)
    final expenseTransactions = transactions
        .where((t) => t.signedAmount < 0 && !t.isStockTransaction)
        .toList();

    if (expenseTransactions.isEmpty) {
      return l10n.noExpenseTransactions;
    }

    // Toplam gider tutarı
    final totalExpense = expenseTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    // Günlük ortalama hesapla
    final now = DateTime.now();
    final firstTransactionDate = expenseTransactions
        .map((t) => t.transactionDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final daysDiff = now.difference(firstTransactionDate).inDays + 1;
    final dailyAverage = totalExpense / daysDiff;

    return '${l10n.dailyAverageExpense}: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(dailyAverage)}';
  }

  List<v2.TransactionWithDetailsV2> _getFilteredTransactions(
    List<v2.TransactionWithDetailsV2> transactions,
  ) {
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
        return transactionDate.isAfter(
              dateRange.start.subtract(const Duration(seconds: 1)),
            ) &&
            transactionDate.isBefore(
              dateRange.end.add(const Duration(seconds: 1)),
            );
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (t.categoryName?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
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
        filtered.sort(
          (a, b) => a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          ),
        );
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
    final filteredTransactions = _getFilteredTransactions(
      Provider.of<UnifiedProviderV2>(context).transactions,
    );

    return AppPageScaffold(
      title: l10n.transactions,
      subtitle: _getTransactionSubtitle(filteredTransactions, l10n),
      titleFontSize: 24,
      subtitleFontSize: 12,
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

  Widget _buildBody(
    List<v2.TransactionWithDetailsV2> transactions,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        // Loading skeleton kaldırıldı - normal UI göster
        // if (providerV2.isLoadingTransactions && transactions.isEmpty) {
        //   return SliverFillRemaining(
        //     child: Padding(
        //       padding: const EdgeInsets.all(16),
        //       child: TransactionDesignSystem.buildLoadingSkeleton(
        //         isDark: isDark,
        //         itemCount: 8,
        //       ),
        //     ),
        //   );
        // }

        // Empty state
        if (transactions.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState(l10n, isDark));
        }

        // Transaction list with quick stats
        return SliverToBoxAdapter(
          child: Column(
            children: [
              // Quick stats card
              _buildQuickStatsCard(transactions, isDark),
              
              // Banner reklam - Gelir/Gider kartından sonra (sadece yüklendiyse göster)
              if (_transactionsBannerService.isLoaded && _transactionsBannerService.bannerWidget != null) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  child: _transactionsBannerService.bannerWidget!,
                ),
              ],
              
              const SizedBox(height: 16),

              // Transaction list
              if (transactions.isNotEmpty) ...[
                TransactionDesignSystem.buildTransactionList(
                  transactions: _buildTransactionWidgets(transactions, isDark),
                  isDark: isDark,
                  emptyTitle:
                      AppLocalizations.of(context)?.noTransactionsYet ??
                      'No transactions yet',
                  emptyDescription:
                      AppLocalizations.of(context)?.addFirstTransaction ??
                      'Add your first transaction to get started',
                  emptyIcon: Icons.receipt_long_outlined,
                  context: context,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsCard(
    List<v2.TransactionWithDetailsV2> transactions,
    bool isDark,
  ) {
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
              title: AppLocalizations.of(context)?.income ?? 'Income',
              amount: totalIncome,
              color: const Color(0xFF4CAF50),
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
              title: AppLocalizations.of(context)?.expense ?? 'Expense',
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
              title: AppLocalizations.of(context)?.net ?? 'Net',
              amount: netAmount,
              color: netAmount >= 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF4444),
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
    // Gelir sayısı için yeşil renk kullan
    final amountColor = title.toLowerCase().contains('gelir') || title.toLowerCase().contains('income')
        ? const Color(0xFF4CAF50) // Yeşil renk
        : color;
    
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).formatAmount(amount),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: amountColor,
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

  List<Widget> _buildTransactionWidgets(
    List<v2.TransactionWithDetailsV2> transactions,
    bool isDark,
  ) {
    return transactions
        .map((transaction) => _buildTransactionWidget(transaction, isDark))
        .toList();
  }

  Widget _buildTransactionWidget(
    v2.TransactionWithDetailsV2 transaction,
    bool isDark,
  ) {
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
        transactionType =
            TransactionType.income; // Treat stock as income for display
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
      categoryIcon = CategoryIconService.getIcon(
        transaction.categoryName!.toLowerCase(),
      );
    }

    // Only fallback to category.icon if category name lookup failed
    if (categoryIcon == null || categoryIcon == Icons.more_horiz_rounded) {
      if (category?.icon != null && category!.icon != 'category') {
        categoryIcon = CategoryIconService.getIcon(category.iconName);
      }
    }

    // Use transaction type color instead of category color
    // This ensures all income transactions are green, all expense transactions are red

    // FALLBACK: Check if description contains installment pattern like (1/4)
    final hasInstallmentPattern = RegExp(
      r'\(\d+/\d+\)',
    ).hasMatch(transaction.description);
    final isActualInstallment =
        transaction.isInstallment || hasInstallmentPattern;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;
    // Taksitli ise taksit bilgisini ekle
    String installmentText = '';
    int? effectiveInstallmentCount = transaction.installmentCount;
    int currentInstallment = 1;
    if ((transaction.installmentCount == null ||
            transaction.installmentCount! < 1) &&
        transaction.installmentId != null) {
      final info = Provider.of<UnifiedProviderV2>(
        context,
        listen: false,
      ).getInstallmentInfo(transaction.installmentId);
      if (info != null) {
        effectiveInstallmentCount = info['totalInstallments'];
        currentInstallment = info['currentInstallment'] ?? 1;
      }
    }
    if (effectiveInstallmentCount != null && effectiveInstallmentCount > 1) {
      installmentText =
          '$effectiveInstallmentCount ${AppLocalizations.of(context)?.installment ?? 'Installment'}';
    } else if (effectiveInstallmentCount == 1) {
      installmentText = AppLocalizations.of(context)?.cash ?? 'NAKİT';
    }
    if (installmentText.isNotEmpty) {
      title += ' [$installmentText]';
    }

    // Format amount with dynamic currency
    final currencySymbol = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).currency.symbol;
    final amount = TransactionDesignSystem.formatAmount(
      transaction.amount,
      transactionType,
      currencySymbol: currencySymbol,
    );

    // Use displayTime from transaction model and localize it
    final rawTime = transaction.displayTime;
    final time = _localizeDisplayTime(rawTime);

    // Card name - centralized logic
    final cardName = TransactionDesignSystem.formatCardName(
      cardName:
          transaction.sourceAccountName ??
          AppLocalizations.of(context)?.account ??
          'HESAP',
      transactionType: transactionType.name,
      sourceAccountName: transaction.sourceAccountName,
      targetAccountName: transaction.targetAccountName,
      context: context,
      isInstallment: isActualInstallment,
    );

    // Check if this should be displayed as an installment
    if (isActualInstallment) {
      // Extract installment info from pattern if available
      Map<String, int?>? installmentInfo;
      if (hasInstallmentPattern) {
        final match = RegExp(
          r'\((\d+)/(\d+)\)',
        ).firstMatch(transaction.description);
        if (match != null) {
          installmentInfo = {
            'currentInstallment': int.tryParse(match.group(1)!),
            'totalInstallments': int.tryParse(match.group(2)!),
          };
        }
      }

      // Get installment count for title
      final totalInstallments = installmentInfo?['totalInstallments'];
      final installmentSuffix = totalInstallments != null
          ? ' ($totalInstallments Taksit)'
          : ' (Taksitli)';

      // Remove installment pattern from title for cleaner display
      final cleanTitle =
          transaction.categoryName ??
          transaction.description
              .replaceAll(RegExp(r'\s*\(\d+/\d+\)'), '')
              .replaceAll(
                AppLocalizations.of(context)?.installment ?? 'Installment',
                '',
              )
              .trim();
      final displayText = installmentText;

      // Parse installment info
      int? installmentCount = effectiveInstallmentCount;
      double? installmentTotalAmount = transaction.amount;
      double? installmentMonthlyAmount =
          installmentTotalAmount / (installmentCount ?? 1);

      return InstallmentExpandableCard(
        installmentId: transaction.installmentId,
        title:
            transaction.categoryName ?? transaction.description, // Kategori adı
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
      context: context,
      transaction: transaction,
      isDark: isDark,
      time: time,
      categoryIconData: categoryIcon,
      onLongPress: () {
        _showTransactionDeleteDialog(context, transaction);
      },
    );
  }

  String _localizeDisplayTime(String rawTime) {
    return TransactionDesignSystem.localizeDisplayTime(rawTime, context);
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
  void _showTransactionDeleteDialog(
    BuildContext context,
    v2.TransactionWithDetailsV2 transaction,
  ) {
    // Hisse işlemleri için bottom sheet gösterme, direkt uyarı göster
    if (transaction.isStockTransaction) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stockTransactionCannotDelete,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.stockTransactionDeleteWarning,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF9500), // Orange warning color
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Normal işlemler için bottom sheet göster
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
          '${transaction.description} ${l10n.deleteTransactionConfirm}\n\n${l10n.amount}: ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(transaction.amount)}',
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
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// Show delete dialog for installment transactions
  void _showInstallmentDeleteDialog(
    BuildContext context,
    v2.TransactionWithDetailsV2 transaction,
    Map<String, int?>? installmentInfo,
  ) {
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
          '${transaction.description} ${l10n.deleteInstallmentConfirm}\n\n${l10n.totalAmount}: ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(transaction.amount)}\n\n${l10n.deleteInstallmentWarning}',
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
              l10n.deleteAll,
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
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// Delete regular transaction
  void _deleteTransaction(v2.TransactionWithDetailsV2 transaction) {
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

    // Check if this is a stock transaction
    if (transaction.isStockTransaction) {
      // Hisse işlemleri silinemez - uyarı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stockTransactionCannotDelete,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.stockTransactionDeleteWarning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF9500), // Orange warning color
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return; // Silme işlemini durdur
    } else {
      // Regular transaction - use UnifiedProviderV2
      providerV2
          .deleteTransaction(transaction.id)
          .then((success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? (AppLocalizations.of(context)?.transactionDeleted ??
                              'Transaction deleted')
                        : (AppLocalizations.of(context)?.deleteFailed ??
                              'Delete failed'),
                  ),
                  backgroundColor: success
                      ? const Color(0xFF34C759)
                      : Colors.red,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          })
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.errorDeletingTransaction}: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
    }
  }

  /// Delete installment transaction
  Future<void> _deleteInstallmentTransaction(
    v2.TransactionWithDetailsV2 transaction,
  ) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deletingInstallmentTransaction),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Delete installment transaction using provider
      final success = await providerV2.deleteInstallmentTransaction(
        transaction.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.installmentTransactionDeleted ??
                  'Installment transaction deleted',
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorDeletingInstallmentTransaction}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
