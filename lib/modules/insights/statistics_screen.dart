import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/providers/unified_provider_v2.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/services/category_icon_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/models/category_model.dart';
import '../../l10n/app_localizations.dart';

enum TimePeriod { thisMonth, lastMonth, last3Months }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
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
              
              // Spending by Category
              SliverToBoxAdapter(
                child: _buildCategoryBreakdown(provider, isDark),
              ),
              
              // Monthly Trend
              SliverToBoxAdapter(
                child: _buildMonthlyTrend(provider, isDark),
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
              '₺${_numberFormat.format(income)}',
              AppColors.success,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
            child: _buildStatCard(
                    'Gider',
              '₺${_numberFormat.format(expenses)}',
              AppColors.error,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
            child: _buildStatCard(
              'Net',
              '₺${_numberFormat.format(balance)}',
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
                '₺${_numberFormat.format(category.amount)}',
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
                                   '${categoryTransactions.length} hareket • ₺${_numberFormat.format(category.amount)}',
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
              '-₺${_numberFormat.format(amount)}',
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

  Widget _buildMonthlyTrend(UnifiedProviderV2 provider, bool isDark) {
    final currentTransactions = _getFilteredTransactions(provider);
    final previousTransactions = _getPreviousPeriodTransactions(provider);
    
    final currentIncome = currentTransactions.where((t) => t.signedAmount > 0).fold<double>(0, (sum, t) => sum + t.amount);
    final currentExpenses = currentTransactions.where((t) => t.signedAmount < 0).fold<double>(0, (sum, t) => sum + t.amount);
    final currentNet = currentIncome - currentExpenses;
    
    final previousIncome = previousTransactions.where((t) => t.signedAmount > 0).fold<double>(0, (sum, t) => sum + t.amount);
    final previousExpenses = previousTransactions.where((t) => t.signedAmount < 0).fold<double>(0, (sum, t) => sum + t.amount);
    final previousNet = previousIncome - previousExpenses;
    
         // Doğru hesaplama mantığı
     final expenseChange = previousExpenses > 0 
         ? ((currentExpenses - previousExpenses) / previousExpenses * 100) 
         : (currentExpenses > 0 ? 100.0 : 0.0); // Önceki dönem 0, bu dönem var ise %100 artış
         
     final incomeChange = previousIncome > 0 
         ? ((currentIncome - previousIncome) / previousIncome * 100)
         : (currentIncome > 0 ? 100.0 : 0.0); // Önceki dönem 0, bu dönem var ise %100 artış
         
     final netChange = previousNet != 0 
         ? ((currentNet - previousNet) / previousNet.abs() * 100)
         : (currentNet != 0 ? (currentNet > 0 ? 100.0 : -100.0) : 0.0);

    // Eğer önceki dönemde hiç işlem yoksa karşılaştırma gösterme
    if (previousTransactions.isEmpty) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 32,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
                                      Text(
               '${_getPreviousPeriodName()} ile Karşılaştırma',
               style: GoogleFonts.inter(
                 fontSize: 16,
                 fontWeight: FontWeight.w600,
                 color: isDark ? AppColors.darkText : AppColors.lightText,
               ),
             ),
             const SizedBox(height: 4),
                Text(
                                                    'Bu dönemde hareket bulunmuyor',
                  style: GoogleFonts.inter(
                 fontSize: 12,
                 color: AppColors.secondary,
                  ),
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
          Text(
            '${_getPreviousPeriodName()} ile Karşılaştırma',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          
          // Gider Karşılaştırması
          _buildComparisonItem(
            'Giderler',
            currentExpenses,
            previousExpenses,
            expenseChange,
            AppColors.error,
            isDark,
            isExpense: true,
          ),
          
          const SizedBox(height: 12),
          
          // Gelir Karşılaştırması
          _buildComparisonItem(
            'Gelirler',
            currentIncome,
            previousIncome,
            incomeChange,
            AppColors.success,
            isDark,
          ),
          
          const SizedBox(height: 12),
          
          // Net Karşılaştırması
          _buildComparisonItem(
            'Net Bakiye',
            currentNet,
            previousNet,
            netChange,
            currentNet >= 0 ? AppColors.success : AppColors.error,
            isDark,
            isNet: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    String title,
    double currentValue,
    double previousValue,
    double changePercent,
    Color color,
    bool isDark, {
    bool isExpense = false,
    bool isNet = false,
  }) {
         final isIncrease = changePercent > 0;
     final isDecrease = changePercent < 0;
     final isStable = changePercent.abs() < 0.1;
     
     // Özel durumlar için kontrol
     final hadPreviousValue = previousValue != 0;
     final hasCurrentValue = currentValue != 0;
     
     Color trendColor;
     IconData trendIcon;
     String trendText;
     
     // Önceki dönem 0, bu dönem var
     if (!hadPreviousValue && hasCurrentValue) {
       if (isExpense) {
         trendColor = AppColors.warning;
         trendIcon = Icons.warning_amber_rounded;
         trendText = 'Yeni harcama başladı';
       } else if (isNet) {
         trendColor = AppColors.success;
         trendIcon = Icons.savings_rounded;
         trendText = 'Artık tasarruf var';
       } else {
         trendColor = AppColors.success;
         trendIcon = Icons.attach_money_rounded;
         trendText = 'Yeni gelir kaynağı';
       }
     }
     // Önceki dönem var, bu dönem 0
     else if (hadPreviousValue && !hasCurrentValue) {
       if (isExpense) {
         trendColor = AppColors.success;
         trendIcon = Icons.check_circle_rounded;
         trendText = 'Harcama durdu';
       } else if (isNet) {
         trendColor = AppColors.error;
         trendIcon = Icons.money_off_rounded;
         trendText = 'Tasarruf bitti';
       } else {
         trendColor = AppColors.error;
         trendIcon = Icons.trending_down_rounded;
         trendText = 'Gelir kesildi';
       }
     }
     // Normal karşılaştırma
     else if (isStable) {
       trendColor = AppColors.secondary;
       trendIcon = Icons.horizontal_rule_rounded;
       trendText = 'Sabit kaldı';
     } else if (isExpense) {
       // Gider için azalış iyi, artış kötü
       if (isDecrease) {
         trendColor = AppColors.success;
         trendIcon = Icons.trending_down_rounded;
         trendText = 'Harcama azaldı';
       } else {
         trendColor = AppColors.error;
         trendIcon = Icons.trending_up_rounded;
         trendText = 'Harcama arttı';
       }
     } else if (isNet) {
       // Net için pozitif artış iyi, negatif artış kötü
       if (isIncrease && currentValue > 0) {
         trendColor = AppColors.success;
         trendIcon = Icons.trending_up_rounded;
         trendText = 'Tasarruf arttı';
       } else if (isIncrease && currentValue < 0) {
         trendColor = AppColors.error;
         trendIcon = Icons.trending_up_rounded;
         trendText = 'Zarar arttı';
       } else if (isDecrease && previousValue > 0) {
         trendColor = AppColors.warning;
         trendIcon = Icons.trending_down_rounded;
         trendText = 'Tasarruf azaldı';
       } else {
         trendColor = AppColors.success;
         trendIcon = Icons.trending_down_rounded;
         trendText = 'Zarar azaldı';
       }
     } else {
       // Gelir için artış iyi, azalış kötü
       if (isIncrease) {
         trendColor = AppColors.success;
         trendIcon = Icons.trending_up_rounded;
         trendText = 'Gelir arttı';
       } else {
         trendColor = AppColors.error;
         trendIcon = Icons.trending_down_rounded;
         trendText = 'Gelir azaldı';
       }
     }

    return Row(
                  children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            trendIcon,
                      size: 20,
            color: trendColor,
          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                        style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  Text(
                    '₺${_numberFormat.format(currentValue.abs())}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 2),
                             Text(
                 _getComparisonText(trendText, changePercent, hadPreviousValue, hasCurrentValue),
                 style: GoogleFonts.inter(
                   fontSize: 12,
                   fontWeight: FontWeight.w400,
                   color: AppColors.secondary,
                 ),
               ),
          ],
        ),
      ),
      ],
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

   String _getComparisonText(String trendText, double changePercent, bool hadPreviousValue, bool hasCurrentValue) {
     // Özel durumlar
     if (!hadPreviousValue && hasCurrentValue) {
       return 'İlk kez görüldü';
     } else if (hadPreviousValue && !hasCurrentValue) {
       return 'Tamamen durdu';
     } else if (changePercent.abs() < 0.1) {
       return 'Neredeyse aynı';
     } else {
       // Yüzde değerine göre farklı ifadeler
       final absPercent = changePercent.abs();
       String intensityText = '';
       
       if (absPercent >= 100) {
         intensityText = 'çok büyük oranda';
       } else if (absPercent >= 50) {
         intensityText = 'büyük oranda';
       } else if (absPercent >= 25) {
         intensityText = 'önemli ölçüde';
       } else if (absPercent >= 10) {
         intensityText = 'belirgin şekilde';
       } else {
         intensityText = 'hafif';
       }
       
       return '$intensityText (%${absPercent.toStringAsFixed(1)})';
     }
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
        name: category?.name ?? _getFallbackCategoryName(categoryId),
        icon: _getCategoryIcon(category?.icon ?? categoryId),
        amount: amount,
        transactionCount: count,
        percentage: percentage,
        color: _getCategoryColor(category?.color ?? categoryId),
      ));
    });
    
    categoryStats.sort((a, b) => b.percentage.compareTo(a.percentage));
    return categoryStats;
  }

  // Provider'dan kategori verisini al
  CategoryModel? _getCategoryFromProvider(UnifiedProviderV2 provider, String categoryId) {
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