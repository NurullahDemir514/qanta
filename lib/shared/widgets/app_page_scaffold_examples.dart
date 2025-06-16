import 'package:flutter/material.dart';
import 'app_page_scaffold.dart';

/// AppPageScaffold kullanım örnekleri
/// Bu dosya farklı sayfa türleri için nasıl kullanılacağını gösterir

class AppPageScaffoldExamples {
  
  /// Basit sayfa - sadece başlık ve içerik
  static Widget simplePage(String title, Widget content) {
    return AppPageScaffold(
      title: title,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }

  /// Alt başlıklı sayfa (Home screen gibi)
  static Widget pageWithSubtitle(String title, String subtitle, Widget content) {
    return AppPageScaffold(
      title: title,
      subtitle: subtitle,
      titleFontSize: 18,
      subtitleFontSize: 14,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }

  /// Tab'lı sayfa (Cards screen gibi)
  static Widget pageWithTabs(
    String title, 
    TabController controller, 
    List<String> tabs, 
    Widget tabContent,
  ) {
    return AppPageScaffold(
      title: title,
      tabBar: AppTabBar(
        controller: controller,
        tabs: tabs,
      ),
      body: SliverFillRemaining(child: tabContent),
    );
  }

  /// Arama ve filtreli sayfa (Transactions screen gibi)
  static Widget pageWithSearchAndFilters(
    String title,
    Widget searchBar,
    Widget filters,
    Widget content,
  ) {
    return AppPageScaffold(
      title: title,
      searchBar: searchBar,
      filters: filters,
      body: content,
    );
  }

  /// Refresh'li sayfa
  static Widget pageWithRefresh(
    String title,
    Widget content,
    Future<void> Function() onRefresh,
  ) {
    return AppPageScaffold(
      title: title,
      onRefresh: onRefresh,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }

  /// FAB'li sayfa
  static Widget pageWithFAB(
    String title,
    Widget content,
    Widget fab,
  ) {
    return AppPageScaffold(
      title: title,
      floatingActionButton: fab,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }

  /// Özel padding'li sayfa
  static Widget pageWithCustomPadding(
    String title,
    Widget content, {
    double horizontalPadding = 16,
    double bottomPadding = 80,
  }) {
    return AppPageScaffold(
      title: title,
      horizontalPadding: horizontalPadding,
      bottomPadding: bottomPadding,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }

  /// Liste sayfası (boş durum ile)
  static Widget listPage(
    String title,
    List<Widget> items, {
    Widget? emptyState,
  }) {
    return AppPageScaffold(
      title: title,
      body: items.isEmpty && emptyState != null
        ? SliverFillRemaining(child: emptyState)
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => items[index],
              childCount: items.length,
            ),
          ),
    );
  }

  /// Grid sayfası
  static Widget gridPage(
    String title,
    List<Widget> items, {
    int crossAxisCount = 2,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
  }) {
    return AppPageScaffold(
      title: title,
      body: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
        ),
      ),
    );
  }

  /// Detay sayfası (geri butonu ile)
  static Widget detailPage(
    String title,
    Widget content, {
    VoidCallback? onBack,
  }) {
    return AppPageScaffold(
      title: title,
      expandedHeight: 100, // Daha küçük header
      titleFontSize: 24,
      body: SliverList(
        delegate: SliverChildListDelegate([content]),
      ),
    );
  }
}

/// Kullanım örnekleri:
/// 
/// 1. Basit sayfa:
/// ```dart
/// AppPageScaffoldExamples.simplePage(
///   'Başlık',
///   Text('İçerik'),
/// )
/// ```
/// 
/// 2. Tab'lı sayfa:
/// ```dart
/// AppPageScaffoldExamples.pageWithTabs(
///   'Kartlarım',
///   _tabController,
///   ['Nakit', 'Banka', 'Kredi'],
///   TabBarView(...),
/// )
/// ```
/// 
/// 3. Arama ve filtreli sayfa:
/// ```dart
/// AppPageScaffoldExamples.pageWithSearchAndFilters(
///   'İşlemler',
///   SearchBar(...),
///   FilterChips(...),
///   TransactionsList(...),
/// )
/// ``` 