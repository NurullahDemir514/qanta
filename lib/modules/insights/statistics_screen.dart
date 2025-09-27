import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers/unified_provider_v2.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/services/category_icon_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/models/unified_category_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/theme_provider.dart';

enum TimePeriod { thisMonth, lastMonth, last3Months }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
  bool _showChart = true; // Default to chart view
  int _selectedTab = 0; // 0: Harcama, 1: Gelir, 2: Net
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Consumer<UnifiedProviderV2>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // SliverAppBar
              SliverAppBar(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                elevation: 0,
                pinned: true,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'İstatistikler',
                style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                ),
              ),
              
              // Period Selector
              SliverToBoxAdapter(
                child: _buildPeriodSelector(isDark),
              ),
              
              // Quick Stats
              SliverToBoxAdapter(
                child: _buildQuickStats(provider, isDark),
              ),
              
              // Monthly Trend Chart
              SliverToBoxAdapter(
                child: _buildMonthlyTrendChart(provider, isDark),
              ),
              
              // Spending by Category
              SliverToBoxAdapter(
                child: _buildCategoryBreakdown(provider, isDark),
              ),
              
              SliverToBoxAdapter(
                child: const SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkText : AppColors.lightText)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPeriodTitle(period),
                  textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.darkBackground : AppColors.lightBackground)
                        : AppColors.secondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats(UnifiedProviderV2 provider, bool isDark) {
    final transactions = _getFilteredTransactions(provider);
    final income = transactions.where((t) => t.signedAmount > 0).fold<double>(0, (sum, t) => sum + t.amount);
    final expenses = transactions.where((t) => t.signedAmount < 0).fold<double>(0, (sum, t) => sum + t.amount);
    final balance = income - expenses;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
              children: [
                Expanded(
            child: _buildStatCard(
                    'Gelir',
              Provider.of<ThemeProvider>(context, listen: false).formatAmount(income),
              AppColors.success,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
            child: _buildStatCard(
                    'Gider',
              Provider.of<ThemeProvider>(context, listen: false).formatAmount(expenses),
              AppColors.error,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
            child: _buildStatCard(
              'Net',
              Provider.of<ThemeProvider>(context, listen: false).formatAmount(balance),
              balance >= 0 ? AppColors.success : AppColors.error,
                    isDark,
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                  title,
                  style: GoogleFonts.inter(
              fontSize: 13,
                    fontWeight: FontWeight.w500,
              color: AppColors.secondary,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(UnifiedProviderV2 provider, bool isDark) {
    final categoryStats = _calculateCategoryStats(provider);
    final transactions = _getFilteredTransactions(provider);
    final hasTransactions = transactions.isNotEmpty;
    
    if (categoryStats.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
      children: [
            Icon(
              hasTransactions ? Icons.analytics_outlined : Icons.pie_chart_outline_rounded,
              size: 48,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
                          Text(
                hasTransactions ? 'Henüz gider kaydı yok' : 'Hareket geçmişi boş',
            style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              hasTransactions 
                                      ? 'Seçilen dönemde harcama yapılmamış'
                      : 'İlk harcamanızı ekleyerek başlayın',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                'Harcama Kategorileri',
              style: GoogleFonts.inter(
                  fontSize: 18,
                fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              
            ],
          ),
          const SizedBox(height: 16),
          ...categoryStats.take(5).map((category) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryItem(category, isDark),
            )
          ),
          if (categoryStats.length > 5) ...[
            const SizedBox(height: 8),
                            Text(
              '+${categoryStats.length - 5} kategori daha',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.secondary,
                              ),
              textAlign: TextAlign.center,
                            ),
                          ],
          ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryStat category, bool isDark) {
    return GestureDetector(
      onTap: () => _showCategoryDetails(category),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
      decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category.icon,
              size: 20,
              color: category.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  category.name,
              style: GoogleFonts.inter(
                    fontSize: 15,
                fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.transactionCount} hareket • %${category.percentage.toStringAsFixed(1)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
                        Text(
                Provider.of<ThemeProvider>(context, listen: false).formatAmount(category.amount),
                          style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(CategoryStat category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<UnifiedProviderV2>(
        builder: (context, provider, child) {
          final categoryTransactions = _getCategoryTransactions(provider, category.id);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
    return Container(
      decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
        child: Column(
          children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
              children: [
                Container(
                            width: 48,
                            height: 48,
                  decoration: BoxDecoration(
                              color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                              category.icon,
                    size: 24,
                              color: category.color,
                  ),
                ),
                const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                Text(
                                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                                                                 Text(
                                   '${categoryTransactions.length} hareket • ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(category.amount)}',
                                   style: GoogleFonts.inter(
                                     fontSize: 14,
                                     fontWeight: FontWeight.w400,
                                     color: AppColors.secondary,
                  ),
                ),
              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Transactions List
                    Expanded(
                      child: categoryTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(height: 16),
                                                                     Text(
                                     'Bu kategoride hareket bulunamadı',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                                       fontWeight: FontWeight.w400,
                                       color: AppColors.secondary,
                                     ),
                                   ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: categoryTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = categoryTransactions[index];
                                return Column(
                                  children: [
                                    _buildTransactionItem(transaction, isDark),
                                    if (index < categoryTransactions.length - 1)
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        height: 1,
                                        color: AppColors.secondary.withOpacity(0.1),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(dynamic transaction, bool isDark) {
    final date = transaction.transactionDate as DateTime;
    final amount = transaction.amount as double;
    final description = transaction.description as String? ?? 'Hareket';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
            width: 40,
            height: 40,
                          decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
                          ),
            child: Icon(
              Icons.arrow_outward_rounded,
              size: 20,
              color: AppColors.secondary,
                        ),
          ),
          const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                    description,
                                style: GoogleFonts.inter(
                      fontSize: 15,
                                  fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                              ),
                  const SizedBox(height: 4),
                              Text(
                    _formatDate(date),
                                style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
              '-${Provider.of<ThemeProvider>(context, listen: false).formatAmount(amount)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ],
      ),
    );
  }

  List<dynamic> _getCategoryTransactions(UnifiedProviderV2 provider, String categoryId) {
    final transactions = _getFilteredTransactions(provider);
    return transactions
        .where((transaction) => 
            transaction.signedAmount < 0 && 
            (transaction.categoryId == categoryId))
        .toList()
      ..sort((a, b) => (b.transactionDate as DateTime).compareTo(a.transactionDate as DateTime));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Bugün, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate == yesterday) {
      return 'Dün, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${date.day} ${months[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMonthlyTrendChart(UnifiedProviderV2 provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabButton('Harcama', 0, Icons.trending_down, isDark),
                const SizedBox(width: 8),
                _buildTabButton('Gelir', 1, Icons.trending_up, isDark),
                const SizedBox(width: 8),
                _buildTabButton('Net', 2, Icons.account_balance, isDark),
              ],
            ),
          ),
          
          // Content based on selected tab
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildTabContent(provider, isDark),
          ),
        ],
      ),
    );
  }


  String _getPeriodTitle(TimePeriod period) {
    switch (period) {
      case TimePeriod.thisMonth:
        return 'Bu Ay';
      case TimePeriod.lastMonth:
        return 'Geçen Ay';
      case TimePeriod.last3Months:
        return 'Son 3 Ay';
    }
  }

  String _getPreviousPeriodName() {
    final now = DateTime.now();
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                   'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    
    switch (_selectedPeriod) {
      case TimePeriod.thisMonth:
        // Bu ay seçiliyse, önceki dönem = geçen ay
        final lastMonth = _subtractMonths(now, 1);
        return '${months[lastMonth.month - 1]} ${lastMonth.year}';
      case TimePeriod.lastMonth:
        // Geçen ay seçiliyse, önceki dönem = ondan önceki ay
        final twoMonthsAgo = _subtractMonths(now, 2);
        return '${months[twoMonthsAgo.month - 1]} ${twoMonthsAgo.year}';
      case TimePeriod.last3Months:
        // Son 3 ay seçiliyse, önceki dönem = ondan önceki 3 ay (6 ay öncesinden 4 ay öncesine kadar)
        final sixMonthsAgo = _subtractMonths(now, 6);
        final fourMonthsAgo = _subtractMonths(now, 4);
        return '${months[sixMonthsAgo.month - 1]} ${sixMonthsAgo.year} - ${months[fourMonthsAgo.month - 1]} ${fourMonthsAgo.year}';
    }
  }

  DateTime _subtractMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month - months;
    
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    
    return DateTime(year, month, 1);
  }

  List<MonthlyTrendData> _getMonthlyExpenseData(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    final months = <MonthlyTrendData>[];
    
    // İlk işlem tarihini bul
    DateTime? firstTransactionDate;
    for (final transaction in provider.transactions) {
      if (transaction.transactionDate != null) {
        if (firstTransactionDate == null || transaction.transactionDate!.isBefore(firstTransactionDate)) {
          firstTransactionDate = transaction.transactionDate;
        }
      }
    }
    
    if (firstTransactionDate == null) return months; // Hiç işlem yoksa boş döndür
    
    // İlk işlem tarihinden itibaren tüm ayları göster
    final firstMonth = DateTime(firstTransactionDate.year, firstTransactionDate.month, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    
    DateTime monthDate = firstMonth;
    while (monthDate.isBefore(currentMonth) || monthDate.isAtSameMomentAs(currentMonth)) {
      final monthTransactions = provider.transactions.where((transaction) {
        if (transaction.transactionDate == null) return false;
        final transactionDate = transaction.transactionDate!;
        return transactionDate.year == monthDate.year && 
               transactionDate.month == monthDate.month &&
               transaction.signedAmount < 0; // Sadece harcamalar
      }).toList();
      
      final totalExpenses = monthTransactions.fold<double>(0, (sum, t) => sum + t.signedAmount.abs());
      
      final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      
      months.add(MonthlyTrendData(
        month: monthNames[monthDate.month - 1],
        expenses: totalExpenses,
        income: 0.0,
      ));
      
      // Sonraki aya geç
      monthDate = DateTime(monthDate.year, monthDate.month + 1, 1);
    }
    
    return months;
  }

  List<MonthlyTrendData> _getMonthlyIncomeData(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    final months = <MonthlyTrendData>[];
    
    // İlk işlem tarihini bul
    DateTime? firstTransactionDate;
    for (final transaction in provider.transactions) {
      if (transaction.transactionDate != null) {
        if (firstTransactionDate == null || transaction.transactionDate!.isBefore(firstTransactionDate)) {
          firstTransactionDate = transaction.transactionDate;
        }
      }
    }
    
    if (firstTransactionDate == null) return months; // Hiç işlem yoksa boş döndür
    
    // İlk işlem tarihinden itibaren tüm ayları göster
    final firstMonth = DateTime(firstTransactionDate.year, firstTransactionDate.month, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    
    DateTime monthDate = firstMonth;
    while (monthDate.isBefore(currentMonth) || monthDate.isAtSameMomentAs(currentMonth)) {
      final monthTransactions = provider.transactions.where((transaction) {
        if (transaction.transactionDate == null) return false;
        final transactionDate = transaction.transactionDate!;
        return transactionDate.year == monthDate.year && 
               transactionDate.month == monthDate.month &&
               transaction.signedAmount > 0; // Sadece gelirler
      }).toList();
      
      final totalIncome = monthTransactions.fold<double>(0, (sum, t) => sum + t.signedAmount);
      
      final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      
      months.add(MonthlyTrendData(
        month: monthNames[monthDate.month - 1],
        expenses: totalIncome, // Gelir verisi için expenses alanını kullanıyoruz
        income: totalIncome,
      ));
      
      // Sonraki aya geç
      monthDate = DateTime(monthDate.year, monthDate.month + 1, 1);
    }
    
    return months;
  }

  List<MonthlyTrendData> _getMonthlyNetData(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    final months = <MonthlyTrendData>[];
    
    // Tüm hesapların toplam başlangıç bakiyesini hesapla
    final totalInitialBalance = provider.accounts.fold<double>(0, (sum, account) {
      return sum + account.balance;
    });
    
    // İlk işlem tarihini bul
    DateTime? firstTransactionDate;
    for (final transaction in provider.transactions) {
      if (transaction.transactionDate != null) {
        if (firstTransactionDate == null || transaction.transactionDate!.isBefore(firstTransactionDate)) {
          firstTransactionDate = transaction.transactionDate;
        }
      }
    }
    
    if (firstTransactionDate == null) return months; // Hiç işlem yoksa boş döndür
    
    // İlk işlem tarihinden itibaren tüm ayları göster
    final firstMonth = DateTime(firstTransactionDate.year, firstTransactionDate.month, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    
    DateTime monthDate = firstMonth;
    while (monthDate.isBefore(currentMonth) || monthDate.isAtSameMomentAs(currentMonth)) {
      // Bu aya kadar olan tüm işlemleri al
      final transactionsUpToMonth = provider.transactions.where((transaction) {
        if (transaction.transactionDate == null) return false;
        final transactionDate = transaction.transactionDate!;
        return transactionDate.isBefore(DateTime(monthDate.year, monthDate.month + 1, 1));
      }).toList();
      
      // Bu aya kadar olan işlemlerin net etkisini hesapla
      final totalIncomeUpToMonth = transactionsUpToMonth
          .where((t) => t.signedAmount > 0)
          .fold<double>(0, (sum, t) => sum + t.signedAmount);
      
      final totalExpensesUpToMonth = transactionsUpToMonth
          .where((t) => t.signedAmount < 0)
          .fold<double>(0, (sum, t) => sum + t.signedAmount.abs());
      
      // Net bakiye = Başlangıç bakiyesi + Gelirler - Harcamalar
      final netAmount = totalInitialBalance + totalIncomeUpToMonth - totalExpensesUpToMonth;
      
      final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      
      months.add(MonthlyTrendData(
        month: monthNames[monthDate.month - 1],
        expenses: netAmount, // Net bakiye için expenses alanını kullanıyoruz
        income: totalIncomeUpToMonth,
      ));
      
      // Sonraki aya geç
      monthDate = DateTime(monthDate.year, monthDate.month + 1, 1);
    }
    
    return months;
  }

  String _getTabTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Harcama';
      case 1:
        return 'Gelir';
      case 2:
        return 'Net Bakiye';
      default:
        return 'Harcama';
    }
  }

  double _calculateDynamicInterval(List<MonthlyTrendData> data) {
    if (data.isEmpty) return 1000;
    
    final values = data.map((e) => e.expenses).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    
    // Net bakiye için negatif değerleri de dikkate al
    final range = maxValue - minValue;
    final absMaxValue = maxValue.abs() > minValue.abs() ? maxValue.abs() : minValue.abs();
    
    // Aralığa göre uygun interval hesapla
    if (absMaxValue <= 1000) {
      return 200; // 0-1000 arası için 200'şer
    } else if (absMaxValue <= 5000) {
      return 1000; // 0-5000 arası için 1000'er
    } else if (absMaxValue <= 10000) {
      return 2000; // 0-10000 arası için 2000'şer
    } else if (absMaxValue <= 50000) {
      return 10000; // 0-50000 arası için 10000'şer
    } else {
      return 25000; // 50000+ için 25000'şer
    }
  }

  Widget _buildTabButton(String label, int tabIndex, IconData icon, bool isDark) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primary 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                icon,
                size: 16,
                color: isSelected 
                  ? Colors.white 
                  : AppColors.secondary,
              ),
              const SizedBox(width: 6),
                                      Text(
                label,
               style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                    ? Colors.white 
                    : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showChart = label == 'Grafik';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primary 
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppColors.primary 
              : AppColors.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                ? Colors.white 
                : AppColors.secondary,
            ),
            const SizedBox(width: 6),
                Text(
              label,
                  style: GoogleFonts.inter(
                 fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected 
                  ? Colors.white 
                  : AppColors.secondary,
                  ),
                ),
              ],
        ),
            ),
      );
    }

  Widget _buildTabContent(UnifiedProviderV2 provider, bool isDark) {
    List<MonthlyTrendData> monthlyData;
    String title;
    Color dataColor;
    IconData dataIcon;
    
    switch (_selectedTab) {
      case 0: // Harcama
        monthlyData = _getMonthlyExpenseData(provider);
        title = 'Aylık Harcama Analizi';
        dataColor = AppColors.error;
        dataIcon = Icons.trending_down;
        break;
      case 1: // Gelir
        monthlyData = _getMonthlyIncomeData(provider);
        title = 'Aylık Gelir Analizi';
        dataColor = AppColors.success;
        dataIcon = Icons.trending_up;
        break;
      case 2: // Net
        monthlyData = _getMonthlyNetData(provider);
        title = 'Aylık Net Bakiye Analizi';
        dataColor = AppColors.primary;
        dataIcon = Icons.account_balance;
        break;
      default:
        monthlyData = _getMonthlyExpenseData(provider);
        title = 'Aylık Harcama Analizi';
        dataColor = AppColors.error;
        dataIcon = Icons.trending_down;
    }
    
    if (monthlyData.isEmpty) {
      return Column(
        children: [
          Icon(
            dataIcon,
            size: 48,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aylık $title Verisi Yok',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk işleminizi ekleyerek başlayın',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle buttons - full width
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                'Grafik',
                Icons.show_chart,
                _showChart,
            isDark,
          ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleButton(
                'Tablo',
                Icons.table_chart,
                !_showChart,
            isDark,
              ),
          ),
        ],
      ),
        const SizedBox(height: 20),
        
        // Chart or Table based on toggle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showChart 
            ? _buildChartView(monthlyData, isDark, dataColor, dataIcon)
            : _buildTableView(monthlyData, isDark, dataColor),
        ),
      ],
    );
  }

  Widget _buildChartView(List<MonthlyTrendData> monthlyData, bool isDark, Color dataColor, IconData dataIcon) {
    final values = monthlyData.map((e) => e.expenses).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    
    // Dinamik Y ekseni aralığı hesapla
    final range = maxValue - minValue;
    final padding = range * 0.1; // %10 padding
    final chartMinY = (minValue - padding).toDouble();
    final chartMaxY = (maxValue + padding).toDouble();
    
    return Column(
      key: const ValueKey('chart'),
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateDynamicInterval(monthlyData),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.secondary.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthlyData[value.toInt()].month,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateDynamicInterval(monthlyData),
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        Provider.of<ThemeProvider>(context, listen: false).formatAmount(value.toInt().toDouble()),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              minX: 0,
              maxX: (monthlyData.length - 1).toDouble(),
              minY: chartMinY,
              maxY: chartMaxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppColors.primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final index = touchedSpot.spotIndex;
                      if (index >= 0 && index < monthlyData.length) {
                        final data = monthlyData[index];
                        return LineTooltipItem(
                          '${data.month}\n${Provider.of<ThemeProvider>(context, listen: false).formatAmount(data.expenses)}',
                          GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white, // Beyaz yazı
                          ),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: dataColor,
                        strokeWidth: 2,
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: dataColor,
                            strokeWidth: 2,
                            strokeColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: monthlyData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.expenses);
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      dataColor.withOpacity(0.8),
                      dataColor.withOpacity(0.3),
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: dataColor,
                        strokeWidth: 2,
                        strokeColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        dataColor.withOpacity(0.1),
                        dataColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
                  children: [
        Container(
              width: 12,
              height: 12,
          decoration: BoxDecoration(
                color: dataColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getTabTitle(_selectedTab),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableView(List<MonthlyTrendData> monthlyData, bool isDark, Color dataColor) {
    return Column(
      key: const ValueKey('table'),
            children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dataColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
                children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Ay',
                        style: GoogleFonts.inter(
                    fontSize: 14,
                      fontWeight: FontWeight.w600,
                    color: dataColor,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _getTabTitle(_selectedTab),
                    style: GoogleFonts.inter(
                    fontSize: 14,
                      fontWeight: FontWeight.w600,
                    color: dataColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Değişim',
                 style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dataColor,
                  ),
                 ),
               ),
          ],
        ),
      ),
        const SizedBox(height: 8),
        
        // Table Rows
        ...monthlyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final previousData = index > 0 ? monthlyData[index - 1] : null;
          
          double changePercent = 0.0;
          if (previousData != null && previousData.expenses > 0) {
            changePercent = ((data.expenses - previousData.expenses) / previousData.expenses) * 100;
          } else if (previousData == null && data.expenses > 0) {
            changePercent = 100.0; // İlk ay için %100 artış
          }
          
         final isIncrease = changePercent > 0;
     final isDecrease = changePercent < 0;
     final isStable = changePercent.abs() < 0.1;
     
          Color changeColor = AppColors.secondary;
          IconData changeIcon = Icons.horizontal_rule;
          
          if (isStable) {
            changeColor = AppColors.secondary;
            changeIcon = Icons.horizontal_rule;
          } else if (isIncrease) {
            changeColor = dataColor;
            changeIcon = Icons.trending_up;
          } else if (isDecrease) {
            changeColor = dataColor.withOpacity(0.7);
            changeIcon = Icons.trending_down;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard.withOpacity(0.5) : AppColors.lightCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
            children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    data.month,
                        style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    Provider.of<ThemeProvider>(context, listen: false).formatAmount(data.expenses),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dataColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        changeIcon,
                        size: 16,
                        color: changeColor,
                      ),
                      const SizedBox(width: 4),
                             Text(
                        changePercent.abs() < 0.1 
                          ? 'Sabit'
                          : '${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                 style: GoogleFonts.inter(
                   fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: changeColor,
                 ),
               ),
          ],
        ),
      ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  List<dynamic> _getFilteredTransactions(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate;
    
    switch (_selectedPeriod) {
      case TimePeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        // Bu ay için end date yok (bugüne kadar)
        break;
      case TimePeriod.lastMonth:
        // Geçen ayın tamamı
        startDate = _subtractMonths(now, 1);
        endDate = DateTime(now.year, now.month, 1); // Bu ayın başı
        break;
      case TimePeriod.last3Months:
        // Son 3 ay: 3 ay öncesinin başından bugüne kadar
        startDate = _subtractMonths(now, 3);
        // End date yok, bugüne kadar
        break;
    }
    
    return provider.transactions.where((transaction) {
      final transactionDate = transaction.transactionDate;
      final isAfterStart = transactionDate.isAfter(startDate) || 
                          transactionDate.isAtSameMomentAs(startDate) ||
                          (transactionDate.year == startDate.year && 
                           transactionDate.month == startDate.month && 
                           transactionDate.day >= startDate.day);
      final isBeforeEnd = endDate == null || transactionDate.isBefore(endDate);
      return isAfterStart && isBeforeEnd;
    }).toList();
  }

  List<dynamic> _getPreviousPeriodTransactions(UnifiedProviderV2 provider) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case TimePeriod.thisMonth:
        // Bu ay seçiliyse, önceki dönem = geçen ay
        startDate = _subtractMonths(now, 1);
        endDate = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.lastMonth:
        // Geçen ay seçiliyse, önceki dönem = ondan önceki ay
        startDate = _subtractMonths(now, 2);
        endDate = _subtractMonths(now, 1);
        break;
      case TimePeriod.last3Months:
        // Son 3 ay seçiliyse, önceki dönem = ondan önceki 3 ay (6 ay öncesinden 3 ay öncesine kadar)
        startDate = _subtractMonths(now, 6);
        endDate = _subtractMonths(now, 3);
        break;
    }
    
    return provider.transactions.where((transaction) {
      final transactionDate = transaction.transactionDate;
      final isAfterStart = transactionDate.isAfter(startDate) || 
                          transactionDate.isAtSameMomentAs(startDate) ||
                          (transactionDate.year == startDate.year && 
                           transactionDate.month == startDate.month && 
                           transactionDate.day >= startDate.day);
      final isBeforeEnd = transactionDate.isBefore(endDate);
      return isAfterStart && isBeforeEnd;
    }).toList();
   }


  List<CategoryStat> _calculateCategoryStats(UnifiedProviderV2 provider) {
    final transactions = _getFilteredTransactions(provider);
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    
    double totalExpenses = 0;
    
    for (var transaction in transactions) {
      if (transaction.signedAmount < 0) {
        final categoryId = transaction.categoryId ?? 'other';
        final amount = transaction.amount;
        
        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
        totalExpenses += amount;
      }
    }
    
    if (totalExpenses == 0) return [];
    
    final categoryStats = <CategoryStat>[];
    
    categoryTotals.forEach((categoryId, amount) {
      final percentage = (amount / totalExpenses) * 100;
      final count = categoryCounts[categoryId] ?? 0;
      
      // Provider'dan gerçek kategori verisini al
      final category = _getCategoryFromProvider(provider, categoryId);
      
      categoryStats.add(CategoryStat(
        id: categoryId,
        name: category?.displayName ?? _getFallbackCategoryName(categoryId),
        icon: _getCategoryIcon(category?.iconName ?? categoryId),
        amount: amount,
        transactionCount: count,
        percentage: percentage,
        color: _getCategoryColor(category?.colorHex ?? categoryId),
      ));
    });
    
    categoryStats.sort((a, b) => b.percentage.compareTo(a.percentage));
    return categoryStats;
  }

  // Provider'dan kategori verisini al
  UnifiedCategoryModel? _getCategoryFromProvider(UnifiedProviderV2 provider, String categoryId) {
    try {
      return provider.categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  String _getFallbackCategoryName(String categoryId) {
    final categoryNames = {
      'food': 'Yemek',
      'transport': 'Ulaşım',
      'shopping': 'Alışveriş',
      'entertainment': 'Eğlence',
      'bills': 'Faturalar',
      'health': 'Sağlık',
      'education': 'Eğitim',
      'travel': 'Seyahat',
      'other': 'Diğer',
    };
    return categoryNames[categoryId] ?? 'Bilinmeyen Kategori';
  }

  String _getCategoryName(String categoryId) {
    final categoryNames = {
      'food': 'Yemek',
      'transport': 'Ulaşım',
      'shopping': 'Alışveriş',
      'entertainment': 'Eğlence',
      'bills': 'Faturalar',
      'health': 'Sağlık',
      'education': 'Eğitim',
      'travel': 'Seyahat',
      'other': 'Diğer',
    };
    return categoryNames[categoryId] ?? 'Diğer';
  }

  IconData _getCategoryIcon(String iconName) {
    try {
      return CategoryIconService.getIcon(iconName);
    } catch (e) {
      // Fallback ikonlar
      switch (iconName.toLowerCase()) {
        case 'food':
        case 'restaurant':
        case 'yemek':
          return Icons.restaurant_rounded;
        case 'transport':
        case 'car':
        case 'ulaşım':
          return Icons.directions_car_rounded;
        case 'shopping':
        case 'alışveriş':
          return Icons.shopping_bag_rounded;
        case 'entertainment':
        case 'eğlence':
          return Icons.movie_rounded;
        case 'bills':
        case 'faturalar':
          return Icons.receipt_long_rounded;
        case 'health':
        case 'sağlık':
          return Icons.local_hospital_rounded;
        case 'education':
        case 'eğitim':
          return Icons.school_rounded;
        case 'travel':
        case 'seyahat':
          return Icons.flight_rounded;
        default:
          return Icons.category_rounded;
      }
    }
  }

  Color _getCategoryColor(String colorOrId) {
    // Eğer hex renk kodu ise parse et
    if (colorOrId.startsWith('#')) {
      try {
        return Color(int.parse(colorOrId.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        // Parse edilemezse fallback renk
      }
    }
    
    // Fallback renk sistemi
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
      AppColors.secondary,
      AppColors.neutral,
    ];
    return colors[colorOrId.hashCode % colors.length];
  }
}

class CategoryStat {
  final String id;
  final String name;
  final IconData icon;
  final double amount;
  final int transactionCount;
  final double percentage;
  final Color color;

  CategoryStat({
    required this.id,
    required this.name,
    required this.icon,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
    required this.color,
  });
}

class MonthlyTrendData {
  final String month;
  final double expenses;
  final double income;

  MonthlyTrendData({
    required this.month,
    required this.expenses,
    required this.income,
  });
} 