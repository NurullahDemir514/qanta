import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/providers/unified_card_provider.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../profile/profile_screen.dart';
import '../cards/cards_screen.dart';
import '../cards/widgets/add_card_fab.dart';
import '../transactions/index.dart';
import '../transactions/screens/transactions_screen.dart';
import 'widgets/main_tab_bar.dart';
import 'widgets/balance_overview_card.dart';
import 'widgets/cards_section.dart';
import 'widgets/recent_transactions_section.dart';
import 'utils/greeting_utils.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              const TransactionsScreen(),
              const CardsScreen(),
              _buildPlaceholderPage(l10n.analytics, Icons.bar_chart_outlined, const Color(0xFFF59E0B)),
              const ProfileScreen(),
            ],
          ),
          MainTabBar(
            currentIndex: _currentIndex,
            onTabChanged: _onTabChanged,
          ),
          const TransactionFab(),
          if (_currentIndex == 2)
            AddCardFab(currentTabIndex: _currentIndex),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.comingSoon,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data with new provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithNewProvider();
    });
  }

  Future<void> _loadDataWithNewProvider() async {
    try {
      if (!mounted) return;
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Load data with new provider
      if (providerV2.accounts.isEmpty) {
        debugPrint('🔄 Loading data with QANTA v2 provider...');
        await providerV2.loadAllData();
        debugPrint('✅ Data loaded with QANTA v2 provider');
      } else {
        debugPrint('✅ Data already loaded with QANTA v2 provider');
      }
    } catch (e) {
      debugPrint('❌ Error loading data with QANTA v2 provider: $e');
      
      // Fallback to legacy provider
      try {
        if (!mounted) return;
        final cardProvider = Provider.of<UnifiedCardProvider>(context, listen: false);
        debugPrint('🔄 Falling back to legacy provider...');
        await cardProvider.loadAllData();
        debugPrint('✅ Data loaded with legacy provider');
      } catch (legacyError) {
        debugPrint('❌ Error with legacy provider: $legacyError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = SupabaseService.instance.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? l10n.defaultUserName;
    final firstName = GreetingUtils.getFirstName(fullName);
    final profileImageUrl = ProfileImageService.instance.getProfileImageUrl();
    
    return AppPageScaffold(
      title: l10n.greetingHello(firstName),
      subtitle: GreetingUtils.getGreetingByTime(l10n),
      titleFontSize: 18,
      subtitleFontSize: 14,
      bottomPadding: 125,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ProfileAvatar(
            imageUrl: profileImageUrl,
            userName: fullName,
            size: 44,
            showBorder: true,
            onTap: () {
              // TODO: Navigate to profile or show profile menu
              debugPrint('Profile avatar tapped');
            },
          ),
        ),
      ],
      onRefresh: () async {
        // Try new provider first, fallback to legacy
        try {
          if (!mounted) return;
          final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
          await providerV2.refresh();
          debugPrint('✅ Data refreshed with QANTA v2 provider');
        } catch (e) {
          debugPrint('❌ Error refreshing with QANTA v2 provider: $e');
          
          // Fallback to legacy provider
          if (!mounted) return;
          final cardProvider = Provider.of<UnifiedCardProvider>(context, listen: false);
          await cardProvider.loadAllData();
          debugPrint('✅ Data refreshed with legacy provider');
        }
      },
      body: SliverList(
        delegate: SliverChildListDelegate([
          // Balance Overview Card
          const BalanceOverviewCard(),
          const SizedBox(height: 24),
          
          // Cards Section
          const CardsSection(),
          const SizedBox(height: 24),
          
          // Recent Transactions
          const RecentTransactionsSection(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
} 