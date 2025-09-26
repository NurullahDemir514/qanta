import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/animated_empty_state.dart';

class BudgetOverviewCard extends StatefulWidget {
  const BudgetOverviewCard({super.key});

  @override
  State<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<BudgetOverviewCard> {
  // Uyarı bildirimi cooldown sistemi
  final Map<String, DateTime> _lastAlertTimes = {};
  static const Duration _alertCooldown = Duration(minutes: 5); // 5 dakika cooldown

  @override
  void initState() {
    super.initState();
  }

  /// Calculate budget stats from current budgets
  List<BudgetCategoryStats> _calculateBudgetStats(List<BudgetModel> budgets) {
    return budgets.map((budget) {
      final percentage = budget.monthlyLimit > 0 
          ? (budget.spentAmount / budget.monthlyLimit) * 100 
          : 0.0;
      final isOverBudget = budget.spentAmount > budget.monthlyLimit;
      
      return BudgetCategoryStats(
        categoryId: budget.categoryId,
        categoryName: budget.categoryName,
        monthlyLimit: budget.monthlyLimit,
        currentSpent: budget.spentAmount,
        transactionCount: 0, // Will be calculated separately if needed
        percentage: percentage,
        isOverBudget: isOverBudget,
      );
    }).toList();
  }


  Widget _buildEmptyStateWithAddButton(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      height: 120,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noBudgetDefined,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createBudgetDescription,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _showAddBudgetBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.createBudget,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        // Get current month budgets from provider
        final currentBudgets = provider.currentMonthBudgets;

          // Show empty state if no budgets - but still show the header with add button
          if (currentBudgets.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.expenseLimitTracking,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showAddBudgetBottomSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showBudgetManagement(context),
                          child: Text(
                            l10n.manage,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Empty state with add button
                _buildEmptyStateWithAddButton(context, isDark),
              ],
            );
          }

        // Calculate budget stats from current budgets
        final budgetStats = _calculateBudgetStats(currentBudgets);

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.expenseLimitTracking,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _showAddBudgetBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showBudgetManagement(context),
                        child: Text(
                          l10n.manage,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Horizontal scroll cards
              SizedBox(
                height: () {
                  double cardHeight;
                  if (screenHeight < 700) {
                    cardHeight = 90.0; // Küçük ekranlar
                  } else if (screenHeight < 800) {
                    cardHeight = 95.0; // Orta ekranlar
                  } else {
                    cardHeight = 100.0; // Büyük ekranlar
                  }
                  
                  return cardHeight;
                }(),
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: budgetStats.length,
                    itemBuilder: (context, index) => _buildBudgetCard(budgetStats[index], isDark, index, budgetStats.length),
                  ),
              ),
            ],
        );
      },
    );
  }

  Widget _buildBudgetCard(BudgetCategoryStats stat, bool isDark, int index, int totalCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive card sizing
    final isSmallScreen = screenHeight < 700;
    final isMediumScreen = screenHeight >= 700 && screenHeight < 800;
    final isTablet = screenWidth > 600;
    
    final cardWidth = isTablet ? 250.0 : (isSmallScreen ? 180.0 : 200.0);
    final cardHeight = isSmallScreen ? 100.0 : isMediumScreen ? 110.0 : 120.0;
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.only(
        right: index == (totalCount - 1) ? 0 : 12,
      ),
      child: Card(
        elevation: 0,
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark 
              ? const Color(0xFF2C2C2E) 
              : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category name and icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(stat.categoryName).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getCategoryIcon(stat.categoryName),
                      size: 12,
                      color: _getCategoryColor(stat.categoryName),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stat.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Progress bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isDark 
                    ? const Color(0xFF2C2C2E) 
                    : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stat.progressPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: stat.isOverBudget 
                        ? const Color(0xFFFF453A) 
                        : const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Amount info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      '${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(stat.currentSpent)} / ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(stat.monthlyLimit)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stat.percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: stat.isOverBudget 
                        ? const Color(0xFFFF453A) 
                        : const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    return CategoryIconService.getColorFromMap(categoryName.toLowerCase());
  }

  IconData _getCategoryIcon(String categoryName) {
    return CategoryIconService.getIcon(categoryName.toLowerCase());
  }

  void _showBudgetManagement(BuildContext context) {
    context.push('/budget-management');
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    // Navigate to BudgetManagementPage instead of showing modal
    context.push('/budget-management');
  }
}
