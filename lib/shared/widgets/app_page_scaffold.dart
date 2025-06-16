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
    this.horizontalPadding = 20,
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
          expandedHeight: tabBar != null ? expandedHeight + 12 : expandedHeight,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: horizontalPadding, 
              right: horizontalPadding,
              top: tabBar != null ? 16 : 8,
              bottom: tabBar != null ? 56 : 8,
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
            20, 
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
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
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