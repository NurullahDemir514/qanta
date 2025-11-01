import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/savings_goal.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/add_savings_goal_form.dart';
import '../widgets/premium_features_card.dart';
import '../../premium/premium_offer_screen.dart';
import '../screens/savings_goal_detail_screen.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/models/advertisement_models.dart';

/// Tasarruf hedefleri tab'ı
class SavingsTab extends StatefulWidget {
  final AppLocalizations l10n;

  const SavingsTab({super.key, required this.l10n});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  // Expandable sections state
  bool _isArchivedExpanded = false;
  bool _isCompletedExpanded = false;
  
  // Banner reklam servisi
  late GoogleAdsRealBannerService _savingsBannerService;

  @override
  void initState() {
    super.initState();
    
    // Banner reklamı başlat
    _savingsBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.savingsTabBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Banner reklamını gecikmeli yükle
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _savingsBannerService.loadAd();
      }
    });
    
    // Hedefleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savingsProvider = context.read<SavingsProvider>();
      savingsProvider.loadGoals();
    });
  }
  
  @override
  void dispose() {
    _savingsBannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Loading state
        if (savingsProvider.isLoading && !savingsProvider.hasGoals) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF007AFF),
            ),
          );
        }

        // Error state
        if (savingsProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.l10n.error,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  savingsProvider.error!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => savingsProvider.loadGoals(forceRefresh: true),
                  child: Text(widget.l10n.retry),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!savingsProvider.hasGoals) {
          return _buildEmptyState(context, isDark);
        }

        // Hedefleri kategorize et
        final activeGoals = savingsProvider.activeGoals;
        final archivedGoals = savingsProvider.archivedGoals;
        final completedGoals = savingsProvider.completedGoals;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
                // Aktif Hedefler
                if (activeGoals.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeGoals.length,
                    itemBuilder: (context, index) {
                      return SavingsGoalCard(
                        goal: activeGoals[index],
                        onTap: () => _navigateToGoalDetail(activeGoals[index]),
                      );
                    },
                  ),
                ],
                
                // Arşivlenen Bölümü
                if (archivedGoals.isNotEmpty) ...[
                  _buildExpandableSection(
                    title: widget.l10n.archived,
                    count: archivedGoals.length,
                    isExpanded: _isArchivedExpanded,
                    onTap: () {
                      setState(() {
                        _isArchivedExpanded = !_isArchivedExpanded;
                      });
                    },
                    isDark: isDark,
                  ),
                if (_isArchivedExpanded)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: archivedGoals.length,
                    itemBuilder: (context, index) {
                      return SavingsGoalCard(
                        goal: archivedGoals[index],
                        onTap: () => _navigateToGoalDetail(archivedGoals[index]),
                      );
                    },
                  ),
                const SizedBox(height: 4),
              ],
              
              // Tamamlanan Bölümü
              if (completedGoals.isNotEmpty) ...[
                _buildExpandableSection(
                  title: widget.l10n.completed,
                  count: completedGoals.length,
                  isExpanded: _isCompletedExpanded,
                  onTap: () {
                    setState(() {
                      _isCompletedExpanded = !_isCompletedExpanded;
                    });
                  },
                  isDark: isDark,
                ),
                if (_isCompletedExpanded)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedGoals.length,
                    itemBuilder: (context, index) {
                      return SavingsGoalCard(
                        goal: completedGoals[index],
                        onTap: () => _navigateToGoalDetail(completedGoals[index]),
                      );
                    },
                  ),
                ],
                
                // Banner Reklam
                if (_savingsBannerService.isLoaded && 
                    _savingsBannerService.bannerWidget != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: _savingsBannerService.bannerWidget!,
                    ),
                  ),
                  const SizedBox(height: 80), // Alt boşluk
                ],
              ],
            ),
          );
      },
    );
  }

  /// Empty state - Minimal ve şık
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container - Minimal ve zarif
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      size: 36,
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.3),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Başlık
                  Text(
                    widget.l10n.noSavingsGoals,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Açıklama
                  Text(
                    widget.l10n.createFirstGoal,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Buton - Modern ve minimal
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddGoalForm(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.l10n.createGoal,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Banner Reklam (Empty State)
                  if (_savingsBannerService.isLoaded && 
                      _savingsBannerService.bannerWidget != null) ...[
                    const SizedBox(height: 40),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: _savingsBannerService.bannerWidget!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hedef ekleme formu göster
  void _showAddGoalForm(BuildContext context) async {
    // Premium kontrolü
    final premiumService = context.read<PremiumService>();
    final savingsProvider = context.read<SavingsProvider>();

    if (!premiumService.isPremium && savingsProvider.activeGoalsCount >= 3) {
      // Premium teklif ekranını göster
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumOfferScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    // Form göster
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddSavingsGoalForm(
          onSuccess: () {
            // Hedefler yeniden yüklenecek
          },
        ),
      ),
    );
  }

  /// Expandable section header
  Widget _buildExpandableSection({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Expand/Collapse icon
                Icon(
                  isExpanded 
                      ? Icons.keyboard_arrow_down_rounded 
                      : Icons.keyboard_arrow_right_rounded,
                  size: 20,
                  color: isDark 
                      ? Colors.white.withOpacity(0.6) 
                      : Colors.black.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? Colors.white.withOpacity(0.8) 
                        : Colors.black.withOpacity(0.8),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? Colors.white.withOpacity(0.6) 
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hedef detay ekranına git
  void _navigateToGoalDetail(SavingsGoal goal) {
    // Validate goal ID
    if (goal.id.isEmpty) {
      debugPrint('❌ Cannot navigate: Goal ID is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.goalInfoFailed),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    debugPrint('🔗 Navigating to goal detail: ${goal.id}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SavingsGoalDetailScreen(goalId: goal.id),
      ),
    );
  }
}


