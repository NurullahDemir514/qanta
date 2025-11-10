import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../core/services/premium_service.dart';
import '../../shared/utils/fab_positioning.dart';
import '../advertisement/providers/advertisement_provider.dart';
import '../advertisement/services/google_ads_real_banner_service.dart';
import '../advertisement/config/advertisement_config.dart' as config;
import '../advertisement/models/advertisement_models.dart';
import 'providers/statistics_provider.dart';
import 'providers/ai_insights_provider.dart';
import 'models/statistics_model.dart';
import 'widgets/ai_overview_card.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/ai_insights_section.dart';
import 'widgets/staggered_insights_list.dart';
import 'widgets/monthly_balance_chart.dart';
import 'widgets/income_expense_flow_chart.dart';
import 'widgets/spending_intensity_chart.dart';
import 'widgets/budget_spending_distribution_chart.dart';
import 'widgets/income_expense_comparison_chart.dart';
import 'widgets/spending_distribution_chart.dart';
import 'widgets/category_spending_rates_chart.dart';
import '../../modules/transactions/widgets/quick_add_chat_fab.dart';
import '../../shared/models/unified_category_model.dart';
import '../../core/providers/unified_provider_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AnalysisPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

class StatisticsScreen extends StatefulWidget {
  final bool isActive; // Bu tab aktif mi?
  
  const StatisticsScreen({super.key, this.isActive = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AppLocalizations l10n;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  GoogleAdsRealBannerService? _statisticsBannerService;
  
  bool _isShowingAd = false; // Aynı anda birden fazla reklam gösterilmesini engelle
  
  // Filtreleme state'i
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.weekly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Karşılaştırma state'i
  bool _isComparing = false;
  AnalysisPeriod? _comparisonPeriod;
  
  // Filtreleme state'i
  Set<String> _selectedCategoryIds = {};
  
  final List<AnalysisPeriod> _periodOptions = [
    AnalysisPeriod.weekly,
    AnalysisPeriod.monthly,
    AnalysisPeriod.quarterly,
    AnalysisPeriod.yearly,
    AnalysisPeriod.custom,
  ];
  
  // Date range for current period
  ({DateTime start, DateTime end}) get _dateRange => _getDateRangeForPeriod(_selectedPeriod);
  
  // Date range for comparison period
  ({DateTime start, DateTime end})? get _comparisonDateRange {
    if (_comparisonPeriod == null) return null;
    return _getDateRangeForPeriod(_comparisonPeriod!);
  }

  @override
  void initState() {
    super.initState();
    
    // Statistics banner servisini başlat
    _statisticsBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.analyticsBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Banner'ı yükle (3 saniye delay)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _statisticsBannerService?.loadAd();
      }
    });
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    
    // Eğer widget aktif olarak oluşturulduysa sayaç kontrolü yap
    debugPrint('📊 StatisticsScreen initState - isActive: ${widget.isActive}');
    if (widget.isActive) {
      _checkAndShowInterstitialAd();
    }
    
    // AI insights initialize - Sadece ilk açılışta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = Provider.of<AIInsightsProvider>(context, listen: false);
      aiProvider.initializeInsights(context);
    });
  }
  
  /// Her 3 açılışta tam ekran reklam göster (SharedPreferences ile kalıcı sayaç)
  Future<void> _checkAndShowInterstitialAd() async {
    try {
      // Premium kontrolü
      final premiumService = context.read<PremiumService>();
      if (premiumService.isPremium) {
        debugPrint('👑 Statistics: Premium user - No interstitial ad');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Kullanıcıya özel sayaç key
      final countKey = 'statistics_screen_open_count_${user.uid}';
      
      // Mevcut sayacı al (default: 0)
      int currentCount = prefs.getInt(countKey) ?? 0;
      
      // Sayacı artır
      currentCount++;
      await prefs.setInt(countKey, currentCount);
      
      debugPrint('🔢 Statistics screen open count: $currentCount');
      
      // 3'ün katlarında reklam göster (3, 6, 9, 12, ...)
      if (currentCount % 3 == 0) {
        debugPrint('🎬 Statistics: Showing interstitial ad at count: $currentCount');
        
        // Bir saniye bekle (smooth geçiş için)
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        // Reklam göster
        await _showInterstitialAd();
      } else {
        debugPrint('📊 Statistics: Ad will show at count ${((currentCount ~/ 3) + 1) * 3} (current: $currentCount)');
      }
    } catch (e) {
      debugPrint('❌ Statistics: Error checking/showing interstitial ad: $e');
    }
  }
  
  /// Geçiş reklamını göster
  Future<void> _showInterstitialAd() async {
    if (_isShowingAd) return; // Zaten gösteriliyorsa tekrar gösterme
    
    // Premium kullanıcılar için reklam gösterme
    final premiumService = context.read<PremiumService>();
    if (premiumService.isPremium) {
      debugPrint('💎 Statistics: Premium user - Skipping interstitial ad');
      return;
    }
    
    _isShowingAd = true;
    
    final adProvider = context.read<AdvertisementProvider>();
    
    // Ad provider initialize olana kadar bekle (max 10 saniye)
    int initAttempts = 0;
    while (!adProvider.isInitialized && initAttempts < 20) {
      debugPrint('⏳ Insights: Waiting for ad provider to initialize... (${initAttempts + 1}/20)');
      await Future.delayed(const Duration(milliseconds: 500));
      initAttempts++;
    }
    
    if (!adProvider.isInitialized) {
      debugPrint('⚠️ Insights: Ad provider not initialized after 10 seconds, skipping ad');
      _isShowingAd = false;
      return;
    }
    
    // Interstitial reklamın yüklenmesini bekle (max 15 saniye)
    int loadAttempts = 0;
    while (!adProvider.adManager.interstitialService.isLoaded && loadAttempts < 30) {
      debugPrint('⏳ Insights: Waiting for interstitial ad to load... (${loadAttempts + 1}/30)');
      await Future.delayed(const Duration(milliseconds: 500));
      loadAttempts++;
    }
    
    if (!adProvider.adManager.interstitialService.isLoaded) {
      debugPrint('⚠️ Insights: Interstitial ad not loaded after 15 seconds, skipping ad');
      debugPrint('💡 TIP: Test cihazlarda AdMob "No fill" nedeniyle reklam göstermeyebilir');
      _isShowingAd = false;
      return;
    }
    
    try {
      debugPrint('🎬 Insights: Showing interstitial ad...');
      await adProvider.showInterstitialAd();
      debugPrint('✅ Insights: Interstitial ad shown successfully');
    } catch (e) {
      debugPrint('❌ Insights: Failed to show interstitial ad: $e');
    } finally {
      // Reklam gösterildikten sonra flag'i reset et (bir sonraki sayfa açılışında tekrar gösterilebilsin)
      _isShowingAd = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _statisticsBannerService?.dispose();
    super.dispose();
  }

  String _getStatisticsSubtitle() {
    return l10n.analyzeYourFinances;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        AppPageScaffold(
          title: l10n.statistics,
          subtitle: _getStatisticsSubtitle(),
          titleFontSize: 20,
          subtitleFontSize: 12,
          body: Consumer3<StatisticsProvider, AIInsightsProvider, UnifiedProviderV2>(
            builder: (context, statisticsProvider, aiProvider, unifiedProvider, child) {
              return SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Filtreleme ve Kontroller (en üstte)
                  _buildFilterOptions(context, isDark),
                  
                  // Karşılaştırma ve Filtreleme butonları
                  _buildComparisonAndFilterButtons(context, isDark),
                  
                  // Aktif filtreler
                  if (_selectedCategoryIds.isNotEmpty)
                    _buildActiveFilters(context, isDark, unifiedProvider),
                  
                  // 2. Aylık Bakiye Grafiği (filtrelerin hemen altında)
                  const MonthlyBalanceChart(),
                  
                  // 3. Karşılaştırma Grafiği (eğer karşılaştırma aktifse)
                  if (_isComparing && _comparisonDateRange != null)
                    IncomeExpenseComparisonChart(
                      period1Start: _dateRange.start,
                      period1End: _dateRange.end,
                      period1Label: _getPeriodLabelForChart(_selectedPeriod),
                      period2Start: _comparisonDateRange!.start,
                      period2End: _comparisonDateRange!.end,
                      period2Label: _getPeriodLabelForChart(_comparisonPeriod!),
                    ),
                  
                  // 4. Genel Bakış Grafikleri (büyük resim)
                  // 4.1 Gelir & Gider Akışı (en önemli - genel trend)
                  IncomeExpenseFlowChart(
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                    periodLabel: _getPeriodLabelForChart(_selectedPeriod),
                  ),
                  
                  // 4.2 Harcama Dağılımı (treemap - görsel özet)
                  SpendingDistributionChart(
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                  ),
                  
                  // 5. Detaylı Analiz Grafikleri
                  // 5.1 Kategori Harcama Trendleri (kategori bazlı trend analizi)
                  CategorySpendingRatesChart(
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                  ),
                  
                  // 5.2 Harcama Yoğunluğu (zaman bazlı yoğunluk analizi)
                  SpendingIntensityChart(
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                  ),
                  
                  // 6. Bütçe Analizi
                  BudgetSpendingDistributionChart(
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                  ),
                  
                  // 7. AI Insights (en altta - öneriler ve detaylı analiz)
                  if (statisticsProvider.statistics != null && statisticsProvider.statistics!.hasData)
                    AIInsightsSection(
                      statistics: statisticsProvider.statistics!,
                      period: _convertToTimePeriod(_selectedPeriod),
                    ),
                ]),
              );
            },
          ),
        ),
        // AI Chat FAB (altta, sağda)
        QuickAddChatFAB(
          customRight: FabPositioning.getRightPosition(context),
          customBottom: FabPositioning.getBottomPosition(context),
        ),
      ],
    );
  }
  
  Widget _buildFilterOptions(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
            child: Row(
              children: _periodOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final period = entry.value;
                final isSelected = _selectedPeriod == period;
                
            return Padding(
              padding: EdgeInsets.only(right: index < _periodOptions.length - 1 ? 8.w : 0),
                  child: GestureDetector(
                onTap: () async {
                  if (!mounted) return;
                  
                  if (period == AnalysisPeriod.custom) {
                    // Show date picker for custom period
                    final picked = await _showCustomDateRangePicker(context);
                    if (picked != null && mounted) {
                      setState(() {
                        _selectedPeriod = period;
                        _customStartDate = picked.start;
                        _customEndDate = picked.end;
                      });
                      // Filter değiştiğinde statistics güncelle
                      final statisticsProvider = Provider.of<StatisticsProvider>(
                        context,
                        listen: false,
                      );
                      final timePeriod = _convertToTimePeriod(_selectedPeriod);
                      statisticsProvider.loadStatistics(timePeriod);
                      // AI provider sadece period'u güncelle, cache kullan
                      final aiProvider = Provider.of<AIInsightsProvider>(
                        context,
                        listen: false,
                      );
                      aiProvider.loadInsights(timePeriod, context, forceRefresh: false);
                    }
                  } else {
                    if (mounted) {
                      setState(() {
                        _selectedPeriod = period;
                        _customStartDate = null;
                        _customEndDate = null;
                      });
                      // Filter değiştiğinde statistics güncelle
                      final statisticsProvider = Provider.of<StatisticsProvider>(
                        context,
                        listen: false,
                      );
                      final timePeriod = _convertToTimePeriod(_selectedPeriod);
                      statisticsProvider.loadStatistics(timePeriod);
                      // AI provider sadece period'u güncelle, cache kullan
                      final aiProvider = Provider.of<AIInsightsProvider>(
                        context,
                        listen: false,
                      );
                      aiProvider.loadInsights(timePeriod, context, forceRefresh: false);
                    }
                  }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFFFF9500) : const Color(0xFFFF9500))
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1)),
                      width: 1,
                    ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (period == AnalysisPeriod.custom) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 16.w,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Text(
                          _getPeriodLabel(period),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                    ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      ),
    );
  }
  
  String _getPeriodLabel(AnalysisPeriod period) {
    switch (period) {
      case AnalysisPeriod.weekly:
        return l10n.weekly;
      case AnalysisPeriod.monthly:
        return l10n.thisMonth;
      case AnalysisPeriod.quarterly:
        return l10n.last3Months;
      case AnalysisPeriod.yearly:
        return l10n.yearToDate;
      case AnalysisPeriod.custom:
        return l10n.custom ?? 'Özel';
    }
  }
  
  String _getPeriodLabelForChart(AnalysisPeriod period) {
    switch (period) {
      case AnalysisPeriod.weekly:
        return l10n.last7Days;
      case AnalysisPeriod.monthly:
        return l10n.thisMonth;
      case AnalysisPeriod.quarterly:
        return l10n.last3Months;
      case AnalysisPeriod.yearly:
        return l10n.yearToDate;
      case AnalysisPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          final start = _customStartDate!;
          final end = _customEndDate!;
          return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
        }
        return l10n.custom ?? 'Özel';
    }
  }
  
  ({DateTime start, DateTime end}) _getDateRangeForPeriod(AnalysisPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case AnalysisPeriod.weekly:
        final start = now.subtract(const Duration(days: 7));
        return (start: DateTime(start.year, start.month, start.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case AnalysisPeriod.monthly:
        return (start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case AnalysisPeriod.quarterly:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return (start: DateTime(now.year, quarterStartMonth, 1), end: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case AnalysisPeriod.yearly:
        return (start: DateTime(now.year, 1, 1), end: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case AnalysisPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return (start: _customStartDate!, end: _customEndDate!);
        }
        // Default to weekly if custom dates not set
        final start = now.subtract(const Duration(days: 7));
        return (start: DateTime(start.year, start.month, start.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59));
    }
  }
  
  TimePeriod _convertToTimePeriod(AnalysisPeriod period) {
    switch (period) {
      case AnalysisPeriod.weekly:
      case AnalysisPeriod.monthly:
        return TimePeriod.thisMonth;
      case AnalysisPeriod.quarterly:
        return TimePeriod.last3Months;
      case AnalysisPeriod.yearly:
        return TimePeriod.yearToDate;
      case AnalysisPeriod.custom:
        return TimePeriod.last3Months; // Default
    }
  }
  
  Future<({DateTime start, DateTime end})?> _showCustomDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = now;
    
    // Pick start date
    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now.subtract(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (startDate == null) return null;
    
    // Pick end date
    final endDate = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? now,
      firstDate: startDate,
      lastDate: lastDate,
    );
    
    if (endDate == null) return null;
    
    return (start: startDate, end: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));
  }
  
  Widget _buildComparisonAndFilterButtons(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Karşılaştır butonu
          Expanded(
            child: GestureDetector(
              onTap: () => _showComparisonDialog(context, isDark),
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: _isComparing
                      ? (isDark ? const Color(0xFF9C27B0) : const Color(0xFF9C27B0))
                      : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 18.w,
                      color: _isComparing
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.compare ?? 'Karşılaştır',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _isComparing
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Filtrele butonu
          Expanded(
            child: GestureDetector(
              onTap: () => _showFilterDialog(context, isDark),
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: _selectedCategoryIds.isNotEmpty
                      ? (isDark ? const Color(0xFF9C27B0) : const Color(0xFF9C27B0))
                      : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 18.w,
                      color: _selectedCategoryIds.isNotEmpty
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.filter ?? 'Filtrele',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategoryIds.isNotEmpty
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveFilters(BuildContext context, bool isDark, UnifiedProviderV2 provider) {
    final categories = provider.expenseCategories;
    final activeFilters = categories
        .where((cat) => _selectedCategoryIds.contains(cat.id))
        .toList();
    
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          ...activeFilters.map((category) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _selectedCategoryIds.remove(category.id);
                        });
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 16.w,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Add more filter button
          GestureDetector(
            onTap: () => _showFilterDialog(context, isDark),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 16.w,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showComparisonDialog(BuildContext context, bool isDark) async {
    final result = await showDialog<AnalysisPeriod>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          l10n.compare ?? 'Karşılaştır',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _periodOptions.map((period) {
            return ListTile(
              title: Text(
                _getPeriodLabel(period),
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () => Navigator.pop(context, period),
            );
          }).toList(),
        ),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _isComparing = true;
        _comparisonPeriod = result;
      });
    }
  }
  
  Future<void> _showFilterDialog(BuildContext context, bool isDark) async {
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    final categories = provider.expenseCategories;
    final selectedIds = Set<String>.from(_selectedCategoryIds);
    
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            title: Text(
              l10n.filter ?? 'Filtrele',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedIds.contains(category.id);
                  
                  return CheckboxListTile(
                    title: Text(
                      category.displayName,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedIds.add(category.id);
                        } else {
                          selectedIds.remove(category.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel ?? 'İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedIds),
                child: Text(l10n.apply ?? 'Uygula'),
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedCategoryIds = result;
      });
    }
  }
  
  Widget _buildContent(AIInsightsProvider aiProvider, bool isDark) {
    if (aiProvider.isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF007AFF),
          ),
        ),
      );
    }
    
    if (aiProvider.hasError) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                aiProvider.error ?? 'Hata oluştu',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final timePeriod = _convertToTimePeriod(_selectedPeriod);
                  aiProvider.loadInsights(timePeriod, context);
                },
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    
    if (aiProvider.summary == null) {
      return _buildComingSoonScreen(isDark);
    }
    
    final insights = aiProvider.summary!.insights;
    
    if (insights.isEmpty) {
      return _buildEmptyState(isDark);
    }
    
    // Insight listesi - Staggered animasyonlu
    return StaggeredInsightsList(
      insights: insights,
      isDark: isDark,
    );
  }
  
  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 80,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Analiz için yeterli veri yok',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Daha fazla işlem ekledikçe AI analizleri görünecek',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonScreen(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minimal ikon
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),

          const SizedBox(height: 32),

          // Basit başlık
          Text(
            l10n.comingSoon,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Minimal açıklama
          Text(
            l10n.analysisFeaturesInDevelopment,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Şık animasyonlu loading
          _buildElegantLoading(isDark),
          
          // Banner Reklam (Premium olmayanlara göster)
          const SizedBox(height: 48),
          Consumer<PremiumService>(
            builder: (context, premiumService, child) {
              if (!premiumService.isPremium && 
                  _statisticsBannerService?.isLoaded == true && 
                  _statisticsBannerService?.bannerWidget != null) {
                return Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: _statisticsBannerService!.bannerWidget!,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildElegantLoading(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                // Dış halka - dönen
                Positioned.fill(
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFF8E8E93).withOpacity(0.2)
                            : const Color(0xFF6D6D70).withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                // Orta halka - ters yönde dönen
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Transform.rotate(
                      angle: -_rotationAnimation.value * 2 * 3.14159,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF8E8E93).withOpacity(0.4)
                              : const Color(0xFF6D6D70).withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                // İç halka - hızlı dönen
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 4 * 3.14159,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                        ),
                      ),
                    ),
                  ),
                ),
                // Merkez nokta - pulsing
                Center(
                  child: Transform.scale(
                    scale: 0.5 + (_pulseAnimation.value - 0.8) * 0.5,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70))
                                    .withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
