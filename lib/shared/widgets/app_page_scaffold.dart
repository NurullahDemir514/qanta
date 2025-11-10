import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ortak sayfa taslağı - tüm sayfalar için tutarlı tasarım
class AppPageScaffold extends StatelessWidget {
  /// Sayfa başlığı
  final String title;
  
  /// Alt başlık (opsiyonel)
  final String? subtitle;
  
  /// Sayfa içeriği
  final Widget body;
  
  /// Arama çubuğu (opsiyonel)
  final Widget? searchBar;
  
  /// Filtre widget'ları (opsiyonel)
  final Widget? filters;
  
  /// Tab bar (opsiyonel)
  final PreferredSizeWidget? tabBar;
  
  /// Tab bar controller (tab bar varsa gerekli)
  final TabController? tabController;
  
  /// Refresh callback (opsiyonel)
  final Future<void> Function()? onRefresh;
  
  /// Scroll controller (opsiyonel)
  final ScrollController? scrollController;
  
  /// Floating action button (opsiyonel)
  final Widget? floatingActionButton;
  
  /// Floating action button location (opsiyonel)
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  /// Alt boşluk (tab bar için)
  final double bottomPadding;
  
  /// Horizontal padding
  final double horizontalPadding;
  
  /// Body top padding (varsayılan 20)
  final double bodyTopPadding;
  
  /// SliverAppBar'ın expanded height'ı
  final double expandedHeight;
  
  /// Başlık font boyutu
  final double titleFontSize;
  
  /// Alt başlık font boyutu
  final double subtitleFontSize;
  
  /// App bar actions (profil fotoğrafı vs.)
  final List<Widget>? actions;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.searchBar,
    this.filters,
    this.tabBar,
    this.tabController,
    this.onRefresh,
    this.scrollController,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomPadding = 120,
    this.horizontalPadding = 15,
    this.bodyTopPadding = 20,
    this.expandedHeight = 120,
    this.titleFontSize = 28,
    this.subtitleFontSize = 14,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          surfaceTintColor: Colors.transparent,
          pinned: true,
          expandedHeight: tabBar != null ? expandedHeight + 17 : expandedHeight,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: horizontalPadding, 
              right: horizontalPadding,
              top: tabBar != null ? 16 : 8,
              bottom: tabBar != null ? 61 : 8,
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: subtitle != null 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: isDark 
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.6,
                  ),
                      ),
                ),
                if (actions != null) ...actions!,
              ],
                ),
          ),
          bottom: tabBar,
        ),
        
        // Search Bar
        if (searchBar != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: searchBar!,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        
        // Filters
        if (filters != null) ...[
          SliverToBoxAdapter(child: filters!),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        
        // Body Content
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding, 
            bodyTopPadding,
            horizontalPadding, 
            bottomPadding,
          ),
          sliver: body,
        ),
      ],
    );

    // Refresh wrapper
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: SafeArea(
        top: true, // Android 15+ için status bar altında içerik görünmemesi için
        bottom: true,
        left: true,  // Edge-to-edge overflow'u önle
        right: true, // Edge-to-edge overflow'u önle
        child: content,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Tab bilgisi modeli
class TabItem {
  final String label;
  final IconData? icon;
  final int? badgeCount;

  const TabItem({
    required this.label,
    this.icon,
    this.badgeCount,
  });
}

/// Tab bar için özel widget - Minimal Line Style
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;
  final double horizontalPadding;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.horizontalPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
        child: TabBar(
          controller: controller,
          isScrollable: false,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: isDark 
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.8),
              width: 2.5,
            ),
            insets: const EdgeInsets.symmetric(horizontal: 24),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark 
            ? const Color(0xFF8E8E93)
            : const Color(0xFF6D6D70),
          labelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
          dividerColor: isDark 
            ? const Color(0xFF38383A).withValues(alpha: 0.3)
            : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
          dividerHeight: 0.5,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabAlignment: TabAlignment.fill,
          tabs: tabs.map((tab) => Tab(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(tab),
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// Enhanced tab bar with icons and badges - Kullanıcı dostu tasarım
class EnhancedTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<TabItem> tabs;
  final double horizontalPadding;

  const EnhancedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.horizontalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(61),
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 17, horizontalPadding, 8),
        decoration: BoxDecoration(
          color: isDark 
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark 
              ? const Color(0xFF38383A).withValues(alpha: 0.5)
              : const Color(0xFFE5E5EA).withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: TabBar(
            controller: controller,
            isScrollable: false,
            indicator: BoxDecoration(
              color: isDark 
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabAlignment: TabAlignment.fill,
            tabs: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final isSelected = controller.index == index;
                  return Tab(
                    child: _buildTabContent(tab, isSelected, isDark),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(TabItem tab, bool isSelected, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tab.icon != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      tab.icon,
                      size: isSelected ? 18 : 16,
                      color: isSelected 
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: GoogleFonts.inter(
                      fontSize: isSelected ? 13 : 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                      color: isSelected 
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
                    ),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Badge
          if (tab.badgeCount != null && tab.badgeCount! > 0)
            Positioned(
              top: tab.icon != null ? 0 : 8,
              right: tab.icon != null ? 4 : 8,
              child: AnimatedScale(
                scale: isSelected ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500, // Mint green
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade500.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    tab.badgeCount! > 99 ? '99+' : '${tab.badgeCount}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(61);
} 