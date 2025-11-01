import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import 'package:provider/provider.dart';
import 'budget_add_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../../transactions/screens/expense_form_screen.dart';
import '../../transactions/widgets/quick_add_chat_fab.dart';
import '../../../core/services/premium_service.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';

class BudgetManagementPage extends StatefulWidget {
  final VoidCallback? onBudgetSaved;

  const BudgetManagementPage({super.key, this.onBudgetSaved});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  final TextEditingController _limitController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;
  final PageController _overallPageController = PageController();
  late GoogleAdsRealBannerService _budgetBannerService;
  
  
  // Sadece aylık bütçe destekleniyor - filter gerekmez
  final String _selectedFilter = 'monthly';
  final List<String> _availableFilters = [];

  @override
  void initState() {
    super.initState();
    
    // Budget Management banner servisini başlat
    _budgetBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.budgetManagementBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Banner'ı yükle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _budgetBannerService.loadAd();
      }
    });
    
    _updateAvailableFilters();
  }

  @override
  void dispose() {
    _limitController.dispose();
    _overallPageController.dispose();
    _budgetBannerService.dispose();
    super.dispose();
  }

  /// Format date range for budget duration with clear calculation info
  String _formatDateRange(DateTime startDate, DateTime endDate, BudgetPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final startFormatter = DateFormat('dd MMM', locale.toString());
    final endFormatter = DateFormat('dd MMM', locale.toString());
    
    // Calculate duration in days
    final durationInDays = endDate.difference(startDate).inDays;
    
    // Sadece aylık format
    return '${startFormatter.format(startDate)} - ${endFormatter.format(endDate)} ($durationInDays ${l10n.days})';
  }

  BudgetCategoryStats _calculateBudgetStats(BudgetModel budget) {
    final percentage = budget.limit > 0
        ? (budget.spentAmount / budget.limit) * 100
        : 0.0;
    final isOverBudget = budget.spentAmount > budget.limit;

    // Get localized category name
    final localizedCategoryName = CategoryIconService.getLocalizedCategoryName(budget.categoryName, context);

    return BudgetCategoryStats(
      categoryId: budget.categoryId,
      categoryName: localizedCategoryName, // Use localized name
      limit: budget.limit,
      period: budget.period,
      currentSpent: budget.spentAmount,
      transactionCount: 0, // Will be calculated separately if needed
      percentage: percentage,
      isOverBudget: isOverBudget,
      isRecurring: budget.isRecurring,
      startDate: budget.startDate,
    );
  }

  /// Update available filters based on existing budgets
  void _updateAvailableFilters() {
    // Artık filter gerekmez - sadece aylık bütçeler gösteriliyor
    // Bu metod geriye dönük uyumluluk için boş bırakıldı
  }

  /// Filter budgets based on selected filter
  List<BudgetModel> _getFilteredBudgets(List<BudgetModel> allBudgets) {
    // Sadece aylık bütçeler göster
    return allBudgets.where((budget) => budget.period == BudgetPeriod.monthly).toList();
  }

  /// Check if current filter has any budgets and switch to available filter if needed
  void _checkAndSwitchFilterIfNeeded() {
    // Artık filter switching gerekmez - sadece aylık bütçe var
  }

  bool _canSave() {
    return _selectedCategoryName != null &&
        _selectedCategoryName!.isNotEmpty &&
        _limitController.text.isNotEmpty;
  }

  Future<void> _saveBudget() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSave()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterCategoryAndLimit),
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      final limit = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _limitController.text,
        locale,
      );
      if (limit == null || limit <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.enterValidLimit)),
        );
        return;
      }

      setState(() => _isSaving = true);

      await provider.createBudget(
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        limit: limit,
        period: BudgetPeriod.monthly,
        isRecurring: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.limitSavedSuccessfully)),
        );
        widget.onBudgetSaved?.call();
        // Update filters after successful creation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAvailableFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorOccurred}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getPeriodDisplayName(BudgetPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.monthly; // Sadece aylık destekleniyor
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isLoading = providerV2.isLoadingBudgets;
        final allBudgets = providerV2.budgets;
        final currentBudgets = _getFilteredBudgets(allBudgets);
        
        // Check if we need to switch to another filter (after build completes)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndSwitchFilterIfNeeded();
        });

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context)!.expenseLimitTracking,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Main content
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    )
                  : (currentBudgets.isEmpty && _availableFilters.isEmpty)
                      ? _buildEmptyState(isDark)
                      : Column(
                          children: [
                            const SizedBox(height: 16),
                            
                            // Genel bütçe kartı (bütçe varsa göster)
                            if (currentBudgets.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildOverallBudgetCard(
                                  currentBudgets.map((budget) => _calculateBudgetStats(budget)).toList(),
                                  isDark,
                                ),
                              ),
                              _buildPageIndicator(currentBudgets.map((budget) => _calculateBudgetStats(budget)).toList(), isDark),
                              const SizedBox(height: 8),
                            ],
                            
                            // İçerik
                            Expanded(
                              child: _buildBudgetsContent(currentBudgets, isDark),
                            ),
                            
                            // Banner Reklam (Premium olmayanlara göster)
                            Consumer<PremiumService>(
                              builder: (context, premiumService, child) {
                                if (!premiumService.isPremium && 
                                    _budgetBannerService.isLoaded && 
                                    _budgetBannerService.bannerWidget != null) {
                                  return Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 50,
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        child: _budgetBannerService.bannerWidget!,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
              // FABs (AI + Add Budget/Subscription)
              _buildFABStack(currentBudgets, isDark),
            ],
          ),
        );
      },
    );
  }

  /// Budgets Content
  Widget _buildBudgetsContent(List<BudgetModel> budgets, bool isDark) {
    if (budgets.isEmpty) {
      return _buildEmptyState(isDark);
    }
    
    return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: budgets.length,
                            itemBuilder: (context, index) {
        final budget = budgets[index];
                              final stat = _calculateBudgetStats(budget);
        return _buildBudgetCard(stat, isDark, index, budgets.length);
      },
    );
  }

  Widget _buildFABStack(List<BudgetModel> currentBudgets, bool isDark) {
    final fabSize = FabPositioning.getFabSize(context);
    final iconSize = FabPositioning.getIconSize(context);
    final rightPosition = FabPositioning.getRightPosition(context);
    
    // Budget sayfasında navbar yok, FAB'lar ekranın dibine yakın olmalı
    // Safe area (home indicator) üstüne konumlandır
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final bottomPosition = safeAreaBottom + 16.0; // Safe area + 16px padding
    
    return Stack(
      children: [
        // Budget Add FAB
        Positioned(
          right: rightPosition,
          bottom: bottomPosition,
          child: GestureDetector(
            onTap: () => _showAddBudgetBottomSheet(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF232326).withOpacity(0.85)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.18)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE5E5EA),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? Colors.white : Colors.black,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // AI Chat FAB (her zaman görünür, üstte)
        QuickAddChatFAB(
          customRight: rightPosition,
          customBottom: bottomPosition + 60, // Add FAB'ın 60px üstünde
        ),
      ],
    );
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetAddSheet(
        onBudgetSaved: widget.onBudgetSaved,
        onReload: () async {
          // Budget will be reloaded automatically via provider
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple Icon
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              l10n.noDataYet,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle - Açıklama
            Text(
              l10n.budgetManagementDescription,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Simple Add Budget Button
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A), // Red - consistent with FAB
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showAddBudgetBottomSheet(context),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.addNewLimit,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallBudgetCard(List<BudgetCategoryStats> stats, bool isDark) {
    if (stats.isEmpty) return const SizedBox.shrink();
    
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    final totalSpent = stats.fold<double>(0, (sum, stat) => sum + stat.currentSpent);
    final totalPercentage = totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0;
    final remainingAmount = totalLimit - totalSpent;
    final isOverBudget = totalSpent > totalLimit;
    
    // Dinamik yükseklik: 3 kategoriden az varsa %30 küçük
    final cardHeight = stats.length < 3 ? 145.0 : 200.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: cardHeight,
      child: PageView(
        controller: _overallPageController,
        children: [
          // İlk kart: Temel bilgiler
          _buildOverallBudgetBasicCard(
            stats, isDark, totalLimit, totalSpent, 
            totalPercentage.toDouble(), remainingAmount, isOverBudget
          ),
          // İkinci kart: Donut grafik
          _buildOverallBudgetChartCard(stats, isDark),
          // Üçüncü kart: Limit vs Harcama durumu
          _buildOverallBudgetSpendingCard(stats, isDark),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetBasicCard(
    List<BudgetCategoryStats> stats,
    bool isDark,
    double totalLimit,
    double totalSpent,
    double totalPercentage,
    double remainingAmount,
    bool isOverBudget,
  ) {
    final isCompactMode = stats.length < 3;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2A2E),
                  Color(0xFF1A1A1C),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFE8E8ED),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.20)
                : const Color(0xFF6D6D70).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                Container(
                  width: isCompactMode ? 32 : 40, // Biraz büyüttük
                  height: isCompactMode ? 32 : 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isCompactMode ? 8 : 10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: isCompactMode ? 16 : 20, // Font boyutunu büyüttük
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.overallBudget,
                        style: GoogleFonts.inter(
                          fontSize: isCompactMode ? 17 : 19, // Font boyutunu büyüttük
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.length} ${AppLocalizations.of(context)!.categories}',
                        style: GoogleFonts.inter(
                          fontSize: isCompactMode ? 10 : 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Kompakt modda ortalama günlük harcama kartını buraya yerleştir
                if (isCompactMode) ...[
                  const SizedBox(width: 8),
                  _buildCompactDailySpendingCard(stats, isDark, totalSpent),
                ],
                // Normal modda over budget badge'i
                if (!isCompactMode && isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.overBudget,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: totalPercentage / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            width: MediaQuery.of(context).size.width * value.clamp(0.0, 1.0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isOverBudget
                                  ? const Color(0xFFD32F2F)
                                  : _getProgressBarColor(totalPercentage.toDouble()),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(totalSpent)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(totalLimit)}',
                          style: GoogleFonts.inter(
                            fontSize: 14, // 13'ten 14'e büyütüldü
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1C1C1E).withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${totalPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 14, // 13'ten 14'e büyütüldü
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (remainingAmount < 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                size: 14,
                                color: const Color(0xFFD32F2F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!.budgetExceededBy(
                                  Provider.of<ThemeProvider>(context, listen: false).formatAmount(-remainingAmount),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 12, // 11'den 12'ye büyütüldü
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(), // Boş widget ile sağ tarafı doldur
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.remaining,
                            style: GoogleFonts.inter(
                              fontSize: isCompactMode ? 13 : 12, // 12/11'den 13/12'ye büyütüldü
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.6),
                            ),
                          ),
                          Text(
                            Provider.of<ThemeProvider>(context, listen: false).formatAmount(remainingAmount),
                            style: GoogleFonts.inter(
                              fontSize: isCompactMode ? 13 : 12, // 12/11'den 13/12'ye büyütüldü
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Average daily spending - sadece normal modda göster
            if (!isCompactMode)
              _buildAverageDailySpendingCard(stats, isDark, totalSpent),
            ],
          ),
        ),
      ),
    );
  }

  /// Kompakt mod için ortalama günlük harcama kartı
  Widget _buildCompactDailySpendingCard(List<BudgetCategoryStats> stats, bool isDark, double totalSpent) {
    // Calculate average daily spending
    final now = DateTime.now();
    final avgDaysSinceStart = stats.fold<double>(0, (sum, stat) {
      final daysDiff = now.difference(stat.startDate).inDays;
      return sum + (daysDiff.clamp(1, 365));
    }) / stats.length;
    
    final dailyAverage = avgDaysSinceStart > 0 ? totalSpent / avgDaysSinceStart : 0.0;
    
    // Calculate required daily spending
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    final remainingDays = stats.fold<double>(0, (sum, stat) {
      final endDate = stat.endDate;
      final daysLeft = endDate.difference(now).inDays;
      return sum + (daysLeft.clamp(1, 365));
    }) / stats.length;
    
    final requiredDaily = remainingDays > 0 ? totalLimit / remainingDays : 0.0;
    
    // Calculate percentage and determine color
    final percentage = requiredDaily > 0 ? (dailyAverage / requiredDaily) * 100 : 0.0;
    final cardColor = _getDailySpendingCardColor(percentage, isDark);
    final iconColor = _getDailySpendingIconColor(percentage, isDark);
    final textColor = _getDailySpendingTextColor(percentage, isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDailySpendingIcon(percentage),
            size: 12,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(dailyAverage)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(requiredDaily)}',
            style: GoogleFonts.inter(
              fontSize: 13, // 12'den 13'e büyütüldü
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageDailySpendingCard(List<BudgetCategoryStats> stats, bool isDark, double totalSpent) {
    // Calculate average daily spending
    final now = DateTime.now();
    final avgDaysSinceStart = stats.fold<double>(0, (sum, stat) {
      final daysDiff = now.difference(stat.startDate).inDays;
      return sum + (daysDiff.clamp(1, 365));
    }) / stats.length;
    
    final dailyAverage = avgDaysSinceStart > 0 ? totalSpent / avgDaysSinceStart : 0.0;
    
    // Calculate required daily spending (total limit / remaining days)
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    final remainingDays = stats.fold<double>(0, (sum, stat) {
      final endDate = stat.endDate;
      final daysLeft = endDate.difference(now).inDays;
      return sum + (daysLeft.clamp(1, 365));
    }) / stats.length;
    
    final requiredDaily = remainingDays > 0 ? totalLimit / remainingDays : 0.0;
    
    // Calculate percentage and determine color
    final percentage = requiredDaily > 0 ? (dailyAverage / requiredDaily) * 100 : 0.0;
    final cardColor = _getDailySpendingCardColor(percentage, isDark);
    final iconColor = _getDailySpendingIconColor(percentage, isDark);
    final textColor = _getDailySpendingTextColor(percentage, isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getDailySpendingIcon(percentage),
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.averageDailySpending,
            style: GoogleFonts.inter(
              fontSize: 12, // 11'den 12'ye büyütüldü
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(dailyAverage)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(requiredDaily)}',
            style: GoogleFonts.inter(
              fontSize: 12, // 11'den 12'ye büyütüldü
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(List<BudgetCategoryStats> stats, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _overallPageController,
          builder: (context, child) {
            double value = 0.0;
            if (_overallPageController.hasClients) {
              value = _overallPageController.page ?? 0.0;
            }
            
            final isActive = (value - index).abs() < 0.5;
            
            return GestureDetector(
              onTap: () {
                _overallPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive 
                      ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                      : (isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF1C1C1E).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getDailySpendingCardColor(double percentage, bool isDark) {
    if (percentage <= 50) {
      // Green - Good spending pace
      return isDark 
          ? const Color(0xFF1B5E20).withOpacity(0.2)
          : const Color(0xFFE8F5E8);
    } else if (percentage <= 80) {
      // Yellow - Moderate spending pace
      return isDark 
          ? const Color(0xFFF57F17).withOpacity(0.2)
          : const Color(0xFFFFF8E1);
    } else if (percentage <= 100) {
      // Orange - High spending pace
      return isDark 
          ? const Color(0xFFE65100).withOpacity(0.2)
          : const Color(0xFFFFF3E0);
    } else {
      // Red - Over spending pace
      return isDark 
          ? const Color(0xFFB71C1C).withOpacity(0.2)
          : const Color(0xFFFFEBEE);
    }
  }

  Color _getDailySpendingIconColor(double percentage, bool isDark) {
    if (percentage <= 50) {
      return const Color(0xFF2E7D32); // Rich Green
    } else if (percentage <= 80) {
      return const Color(0xFFFFC300); // Yellow
    } else if (percentage <= 100) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return const Color(0xFFD32F2F); // Red
    }
  }

  Color _getDailySpendingTextColor(double percentage, bool isDark) {
    if (percentage <= 50) {
      return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    } else if (percentage <= 80) {
      return isDark ? const Color(0xFFFFC300) : const Color(0xFFF57F17);
    } else if (percentage <= 100) {
      return isDark ? const Color(0xFFFF9800) : const Color(0xFFE65100);
    } else {
      return isDark ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);
    }
  }

  IconData _getDailySpendingIcon(double percentage) {
    if (percentage <= 50) {
      return Icons.check_circle_outline; // Check circle for good pace
    } else if (percentage <= 80) {
      return Icons.trending_flat; // Flat trend for moderate pace
    } else if (percentage <= 100) {
      return Icons.trending_up; // Up trend for high pace
    } else {
      return Icons.warning_amber_outlined; // Warning for over pace
    }
  }

  List<PieChartSectionData> _buildPieChartSections(List<BudgetCategoryStats> stats) {
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    if (totalLimit == 0) return [];

    final colors = [
      const Color(0xFF2E7D32), // Rich Green
      const Color(0xFF2196F3), // Mavi
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFF9C27B0), // Mor
      const Color(0xFFE91E63), // Pembe
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFC300), // Sarı
      const Color(0xFF795548), // Kahverengi
    ];

    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final percentage = (stat.limit / totalLimit) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '',
        radius: 30,
        titleStyle: const TextStyle(
          fontSize: 0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildChartLegend(List<BudgetCategoryStats> stats, bool isDark) {
    final colors = [
      const Color(0xFF2E7D32), // Rich Green
      const Color(0xFF2196F3), // Mavi
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFF9C27B0), // Mor
      const Color(0xFFE91E63), // Pembe
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFC300), // Sarı
      const Color(0xFF795548), // Kahverengi
    ];

    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final color = colors[index % colors.length];
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stat.categoryName,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1C1C1E).withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit)}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1C1C1E).withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }).toList(    );
  }

  Widget _buildOverallBudgetChartCard(List<BudgetCategoryStats> stats, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2A2E),
                  Color(0xFF1A1A1C),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFE8E8ED),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.20)
                : const Color(0xFF6D6D70).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pie_chart_outline,
                    size: 18,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.categoryDistribution,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.length} ${AppLocalizations.of(context)!.categories}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category distribution chart (same as spending status)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _buildSpendingStatusChart(stats, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHorizontalBarChart(List<BudgetCategoryStats> stats, bool isDark) {
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    if (totalLimit == 0) return [];

    final colors = [
      const Color(0xFF2E7D32), // Rich Green
      const Color(0xFF2196F3), // Mavi
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFF9C27B0), // Mor
      const Color(0xFFE91E63), // Pembe
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFC300), // Sarı
      const Color(0xFF795548), // Kahverengi
    ];

    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final percentage = (stat.limit / totalLimit);
      final color = colors[index % colors.length];
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            // Category name
            Expanded(
              flex: 2,
              child: Text(
                stat.categoryName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1C1C1E).withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              flex: 3,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 600 + (index * 150)),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * percentage.clamp(0.0, 1.0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOverallBudgetSpendingCard(List<BudgetCategoryStats> stats, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2A2E),
                  Color(0xFF1A1A1C),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFE8E8ED),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.20)
                : const Color(0xFF6D6D70).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_up_outlined,
                    size: 18,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.spendingStatus,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.length} ${AppLocalizations.of(context)!.categories}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Spending status chart
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _buildSpendingStatusChart(stats, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSpendingStatusChart(List<BudgetCategoryStats> stats, bool isDark) {
    final colors = [
      const Color(0xFF2E7D32), // Rich Green
      const Color(0xFF2196F3), // Mavi
      const Color(0xFFFF9800), // Turuncu
      const Color(0xFF9C27B0), // Mor
      const Color(0xFFE91E63), // Pembe
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFC300), // Sarı
      const Color(0xFF795548), // Kahverengi
    ];

    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final spendingPercentage = stat.limit > 0 ? (stat.currentSpent / stat.limit) : 0.0;
      final color = colors[index % colors.length];
      final isOverSpent = stat.currentSpent > stat.limit;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: isOverSpent ? const Color(0xFFD32F2F) : color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            // Category name
            Expanded(
              flex: 2,
              child: Text(
                stat.categoryName,
                style: GoogleFonts.inter(
                  fontSize: 14, // 12'den 14'e büyütüldü
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1C1C1E).withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              flex: 3,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 600 + (index * 150)),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * spendingPercentage.clamp(0.0, 1.0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isOverSpent ? const Color(0xFFD32F2F) : color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Amount and percentage
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.currentSpent)}',
                    style: GoogleFonts.inter(
                      fontSize: 13, // 11'den 13'e büyütüldü
                      fontWeight: FontWeight.w700,
                      color: isOverSpent ? const Color(0xFFD32F2F) : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(spendingPercentage * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11, // 9'dan 11'e büyütüldü
                      fontWeight: FontWeight.w500,
                      color: isOverSpent ? const Color(0xFFD32F2F) : (isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF1C1C1E).withOpacity(0.6)),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildBudgetCard(
    BudgetCategoryStats stat,
    bool isDark,
    int index,
    int totalCount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0', 'tr_TR');
    final categoryIcon = CategoryIconService.getIcon(
      stat.categoryName.toLowerCase(),
    );
    final categoryColor = CategoryIconService.getColorFromMap(
      stat.categoryName.toLowerCase(),
    );
    final spent = stat.currentSpent;
    final percent = stat.progressPercentage;
    final percentText = (percent * 100).toStringAsFixed(0);
    final remaining = stat.remainingAmount;
    final isOver = stat.isOverBudget;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return GestureDetector(
          onTap: () => _showDeleteDialog(stat),
          onTapDown: (_) => setState(() {}),
          onTapUp: (_) => setState(() {}),
          onTapCancel: () => setState(() {}),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: EdgeInsets.only(bottom: index == totalCount - 1 ? 0 : 12),
              decoration: BoxDecoration(
                gradient: isDark 
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2A2A2E),
                          Color(0xFF1A1A1C),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF8F9FA),
                          Color(0xFFE8E8ED),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.20)
                        : const Color(0xFF6D6D70).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 14,
                            color: categoryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        stat.categoryName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (stat.isRecurring) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.repeat,
                                          size: 14,
                                          color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.6),
                                        ),
                                      ],
                                        if (isOver) ...[
                                          const SizedBox(width: 8),
                                          Transform.translate(
                                            offset: const Offset(0, -3),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                l10n.exceeded,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFD32F2F),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateRange(stat.startDate, stat.endDate, stat.period),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1C1C1E).withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Add transaction button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openTransactionForm(stat),
                              child: Text(
                                AppLocalizations.of(context)!.addExpense,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percent),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    width: MediaQuery.of(context).size.width * value.clamp(0.0, 1.0),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isOver
                                          ? const Color(0xFFD32F2F)
                                          : _getProgressBarColor(percent * 100),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(spent)} / ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(stat.limit)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1C1C1E).withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  '${percentText}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Open transaction form with pre-selected category
  void _openTransactionForm(BudgetCategoryStats stat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(
          initialCategoryId: stat.categoryName, // Use category name instead of ID
          initialStep: 0, // Start from amount step (step 0)
        ),
      ),
    ).then((_) {
      // Refresh budgets after transaction is added
      widget.onBudgetSaved?.call();
    });
  }

  void _showDeleteDialog(BudgetCategoryStats stat) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        titlePadding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 20.h,
          bottom: 8.h,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 0,
        ),
        actionsPadding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
          top: 8.h,
        ),
        title: Text(
          l10n.deleteLimit,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          l10n.deleteLimitConfirm(stat.categoryName),
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudget(stat);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4C4C),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.delete,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(BudgetCategoryStats stat) async {
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Find the budget by categoryId
      final budget = provider.budgets.firstWhere(
        (b) => b.categoryId == stat.categoryId,
        orElse: () => throw Exception('Budget not found'),
      );
      
      await provider.deleteBudget(budget.id);

      if (mounted) {
        widget.onBudgetSaved?.call();
        // Update filters after budget is deleted
        _updateAvailableFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorOccurred}: Limit silinemedi'),
          ),
        );
      }
    }
  }

  Color _getProgressBarColor(double percentage) {
    // Daha yumuşak geçişler için 3 renk noktası
    if (percentage <= 30) {
      // Yeşilden açık yeşile (0-30%)
      return Color.lerp(
        const Color(0xFF2E7D32), // Rich Green
        const Color(0xFF66BB6A), // Açık yeşil
        percentage / 30,
      )!;
    } else if (percentage <= 60) {
      // Açık yeşilden sarıya (30-60%)
      return Color.lerp(
        const Color(0xFF66BB6A), // Açık yeşil
        const Color(0xFFFFC300), // Sarı
        (percentage - 30) / 30,
      )!;
    } else if (percentage <= 85) {
      // Sarıdan turuncuya (60-85%)
      return Color.lerp(
        const Color(0xFFFFC300), // Sarı
        const Color(0xFFFF9800), // Turuncu
        (percentage - 60) / 25,
      )!;
    } else {
      // Turuncudan kırmızıya (85-100%)
      return Color.lerp(
        const Color(0xFFFF9800), // Turuncu
        const Color(0xFFD32F2F), // Kırmızı
        (percentage - 85) / 15,
      )!;
    }
  }



  List<double> _calculateWeeklySpendingData(List<BudgetCategoryStats> stats) {
    // Calculate real weekly spending based on budget stats
    final now = DateTime.now();
    final data = <double>[];
    
    // Calculate average daily spending for each day of the week
    final totalSpent = stats.fold<double>(0, (sum, stat) => sum + stat.currentSpent);
    final avgDaysSinceStart = stats.fold<double>(0, (sum, stat) {
      final daysDiff = now.difference(stat.startDate).inDays;
      print('DEBUG: Budget ${stat.categoryName} - startDate: ${stat.startDate}, daysDiff: $daysDiff, spent: ${stat.currentSpent}');
      // Ensure at least 1 day to avoid division by zero
      return sum + (daysDiff.clamp(1, 365));
    }) / stats.length;
    
    print('DEBUG: totalSpent: $totalSpent, avgDaysSinceStart: $avgDaysSinceStart');
    
    if (avgDaysSinceStart <= 0) {
      print('DEBUG: avgDaysSinceStart <= 0, returning zeros');
      return List.filled(7, 0.0);
    }
    
    final dailyAverage = totalSpent / avgDaysSinceStart;
    print('DEBUG: dailyAverage: $dailyAverage');
    
    // Generate realistic weekly pattern
    for (int i = 6; i >= 0; i--) {
      final dayOfWeek = (now.subtract(Duration(days: i)).weekday - 1) % 7;
      double multiplier = 1.0;
      
      // Weekend spending pattern
      if (dayOfWeek == 5 || dayOfWeek == 6) { // Saturday, Sunday
        multiplier = 1.3; // Higher spending on weekends
      } else if (dayOfWeek == 0) { // Monday
        multiplier = 0.8; // Lower spending on Monday
      }
      
      data.add(dailyAverage * multiplier);
    }
    
    print('DEBUG: weeklyData: $data');
    return data;
  }

  Map<String, dynamic> _calculateTrendDirection(List<double> weeklyData) {
    if (weeklyData.length < 2) {
      return {
        'icon': Icons.trending_flat,
        'color': const Color(0xFF6D6D70),
        'text': 'Veri Yok',
      };
    }
    
    final firstHalf = weeklyData.take(3).fold<double>(0, (sum, val) => sum + val) / 3;
    final secondHalf = weeklyData.skip(4).fold<double>(0, (sum, val) => sum + val) / 3;
    
    final changePercent = ((secondHalf - firstHalf) / firstHalf) * 100;
    
    if (changePercent > 10) {
      return {
        'icon': Icons.trending_up,
        'color': const Color(0xFFD32F2F),
        'text': '+${changePercent.toStringAsFixed(0)}%',
      };
    } else if (changePercent < -10) {
      return {
        'icon': Icons.trending_down,
        'color': const Color(0xFF2E7D32),
        'text': '${changePercent.toStringAsFixed(0)}%',
      };
    } else {
      return {
        'icon': Icons.trending_flat,
        'color': const Color(0xFF6D6D70),
        'text': 'Sabit',
      };
    }
  }

  double _calculateDailyBudgetLimit(List<BudgetCategoryStats> stats) {
    if (stats.isEmpty) return 0.0;
    
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    final now = DateTime.now();
    
    // Calculate average days remaining for all budgets
    final avgDaysRemaining = stats.fold<double>(0, (sum, stat) {
      final endDate = stat.startDate.add(Duration(days: _getPeriodDays(stat.period)));
      final remainingDays = endDate.difference(now).inDays;
      return sum + remainingDays.clamp(1, 30); // Clamp to avoid negative values
    }) / stats.length;
    
    return avgDaysRemaining > 0 ? totalLimit / avgDaysRemaining : totalLimit / 30;
  }

  int _getPeriodDays(BudgetPeriod period) {
    return 30; // Sadece aylık destekleniyor
  }

  Map<String, dynamic> _calculateSpendingSpeed(List<BudgetCategoryStats> stats) {
    if (stats.isEmpty) {
      return {
        'icon': Icons.trending_flat,
        'color': const Color(0xFF6D6D70),
        'text': 'Veri Yok',
      };
    }

    final totalSpent = stats.fold<double>(0, (sum, stat) => sum + stat.currentSpent);
    final totalLimit = stats.fold<double>(0, (sum, stat) => sum + stat.limit);
    final percentage = totalLimit > 0 ? (totalSpent / totalLimit * 100) : 0;
    
    // Calculate days since start
    final now = DateTime.now();
    final avgDaysSinceStart = stats.fold<double>(0, (sum, stat) {
      return sum + now.difference(stat.startDate).inDays;
    }) / stats.length;
    
    final dailySpendingRate = avgDaysSinceStart > 0 ? (percentage / avgDaysSinceStart) : 0;
    
    if (dailySpendingRate > 15) {
      return {
        'icon': Icons.trending_up,
        'color': const Color(0xFFD32F2F),
        'text': 'Hızlı Harcama',
      };
    } else if (dailySpendingRate > 8) {
      return {
        'icon': Icons.trending_up,
        'color': const Color(0xFFFF9800),
        'text': 'Normal Hız',
      };
    } else {
      return {
        'icon': Icons.trending_down,
        'color': const Color(0xFF2E7D32),
        'text': 'Yavaş Harcama',
      };
    }
  }

  /// Build filter toggle widget
  // _buildFilterToggle kaldırıldı - artık filter toggle UI'ı yok (sadece aylık bütçe)

  /// Get filter label based on filter type
  String _getFilterLabel(String filter, AppLocalizations l10n) {
    // Sadece aylık destekleniyor
    return l10n.monthly;
  }
}