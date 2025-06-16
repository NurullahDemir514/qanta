import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/category_icon_service.dart';

/// **QANTA Transaction Design System**
/// 
/// Bu dosya tüm transaction UI bileşenlerinin tasarım standartlarını,
/// renklerini, boyutlarını ve davranışlarını tek bir yerden yönetir.
/// 
/// **Kullanım:**
/// ```dart
/// import '../shared/design_system/transaction_design_system.dart';
/// 
/// // Transaction item kullanımı
/// TransactionDesignSystem.buildTransactionItem(
///   title: 'Kahve',
///   subtitle: 'Akbank',
///   amount: '-25.50₺',
///   icon: Icons.local_cafe,
///   onTap: () {},
/// )
/// ```

class TransactionDesignSystem {
  // ==================== DESIGN TOKENS ====================
  
  /// Transaction Icon Specifications
  static const double iconContainerSize = 40.0;
  static const double iconSize = 20.0;
  static const double iconBorderRadius = 10.0;
  
  /// Typography Specifications
  static const double titleFontSize = 15.0;
  static const FontWeight titleFontWeight = FontWeight.w500;
  static const double subtitleFontSize = 13.0;
  static const FontWeight subtitleFontWeight = FontWeight.w400;
  static const double amountFontSize = 15.0;
  static const FontWeight amountFontWeight = FontWeight.w600;
  
  /// Spacing Specifications
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 12.0;
  static const double iconContentSpacing = 12.0;
  static const double titleSubtitleSpacing = 2.0;
  
  /// Container Specifications
  static const double containerBorderRadius = 12.0;
  static const double containerBorderWidth = 0.5;
  
  /// Animation Specifications
  static const Duration tapAnimationDuration = Duration(milliseconds: 150);
  static const Duration longPressAnimationDuration = Duration(milliseconds: 200);
  
  // ==================== NUMBER FORMATTING ====================
  
  /// Turkish number formatter with thousand separators
  static final NumberFormat _turkishNumberFormat = NumberFormat('#,##0.00', 'tr_TR');
  
  /// Format number with Turkish thousand separators (dots)
  static String formatNumber(double number) {
    return _turkishNumberFormat.format(number).replaceAll(',', '.');
  }
  
  /// Shorten long account names for better display
  static String shortenAccountName(String accountName, {int maxLength = 15}) {
    if (accountName.length <= maxLength) {
      return accountName;
    }
    
    // Common bank name replacements for shorter display
    final bankReplacements = {
      'Türkiye İş Bankası': 'İş Bankası',
      'Türkiye Garanti Bankası': 'Garanti',
      'Akbank T.A.Ş.': 'Akbank',
      'Yapı ve Kredi Bankası': 'Yapı Kredi',
      'Türkiye Halk Bankası': 'Halkbank',
      'Türkiye Vakıflar Bankası': 'VakıfBank',
      'Ziraat Bankası': 'Ziraat',
      'QNB Finansbank': 'Finansbank',
      'İNG Bank': 'ING',
      'HSBC Bank': 'HSBC',
      'Denizbank': 'Denizbank',
      'Türk Ekonomi Bankası': 'TEB',
      'Şekerbank': 'Şekerbank',
    };
    
    // Try bank name replacements first
    for (final entry in bankReplacements.entries) {
      if (accountName.contains(entry.key)) {
        final shortened = accountName.replaceAll(entry.key, entry.value);
        if (shortened.length <= maxLength) {
          return shortened;
        }
      }
    }
    
    // If still too long, truncate with ellipsis
    return '${accountName.substring(0, maxLength - 1)}…';
  }
  
  /// Format transfer subtitle with shortened account names
  static String formatTransferSubtitle(String sourceAccount, String targetAccount, {int maxLength = 12}) {
    final shortSource = shortenAccountName(sourceAccount, maxLength: maxLength);
    final shortTarget = shortenAccountName(targetAccount, maxLength: maxLength);
    return '$shortSource → $shortTarget';
  }
  
  // ==================== COLOR SYSTEM ====================
  
  /// **CENTRALIZED COLOR SYSTEM**
  /// 
  /// All colors now managed through CategoryIconService for consistency.
  /// This eliminates duplicate color definitions and ensures uniform
  /// color usage across the entire application.
  
  /// Transaction Type Colors - delegated to CategoryIconService
  static Color get incomeColor => CategoryIconService.getColorFromMap('income_default');
  static Color get expenseColor => CategoryIconService.getColorFromMap('expense_default');
  static Color get transferColor => CategoryIconService.getColorFromMap('transfer_default');
  
  /// Theme Colors
  static Color getContainerColor(bool isDark) {
    return isDark ? const Color(0xFF1C1C1E) : Colors.white;
  }
  
  static Color getBorderColor(bool isDark) {
    return isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
  }
  
  static Color getTitleColor(bool isDark) {
    return isDark ? Colors.white : Colors.black;
  }
  
  static Color getSubtitleColor(bool isDark) {
    return isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);
  }
  
  static Color getAmountColor(TransactionType type, bool isDark) {
    switch (type) {
      case TransactionType.income:
        return incomeColor;
      case TransactionType.expense:
        return const Color(0xFFFF3B30); // Red color for expenses
      case TransactionType.transfer:
        return transferColor;
    }
  }
  
  // ==================== ICON SYSTEM ====================
  
  /// Get transaction type icon
  static IconData getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }
  
  /// Get category icon from icon name - delegated to CategoryIconService
  static IconData getCategoryIcon(String iconName) {
    return CategoryIconService.getIcon(iconName);
  }
  
  /// Get category color from hex string - delegated to CategoryIconService
  static Color getCategoryColor(String colorHex) {
    return CategoryIconService.getColor(colorHex);
  }
  
  /// Get transaction icon and color using centralized system
  static TransactionIconData getTransactionIconData({
    required TransactionType type,
    String? categoryIcon,
    String? categoryColor,
    IconData? categoryIconData,
    Color? categoryColorData,
  }) {
    IconData icon;
    Color iconColor;
    
    // Prioritize direct IconData/Color parameters (new system)
    if (categoryIconData != null) {
      icon = categoryIconData;
      iconColor = categoryColorData ?? _getDefaultColorForType(type);
    } else if (categoryIcon != null) {
      // Use category icon and centralized color system (legacy support)
      icon = getCategoryIcon(categoryIcon);
      
      if (categoryColor != null) {
        // Use provided color (hex or predefined)
        iconColor = getCategoryColor(categoryColor);
      } else {
        // Use centralized color based on category type
        final categoryType = type == TransactionType.income ? 'income' : 'expense';
        iconColor = CategoryIconService.getColorFromMap(categoryIcon, categoryType: categoryType);
      }
    } else {
      // Use transaction type icon and color
      icon = getTransactionTypeIcon(type);
      iconColor = _getDefaultColorForType(type);
    }
    
    return TransactionIconData(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: iconColor.withValues(alpha: 0.1),
    );
  }
  
  static Color _getDefaultColorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return incomeColor;
      case TransactionType.expense:
        return expenseColor;
      case TransactionType.transfer:
        return transferColor;
    }
  }
  
  // ==================== TEXT FORMATTING ====================
  
  /// Format transaction amount
  static String formatAmount(double amount, TransactionType type) {
    final formattedAmount = formatNumber(amount.abs());
    
    switch (type) {
      case TransactionType.income:
        return '+$formattedAmount₺';
      case TransactionType.expense:
        return '-$formattedAmount₺';
      case TransactionType.transfer:
        return '$formattedAmount₺';
    }
  }
  
  /// Format transaction time
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Bugün ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  /// Add installment info to title
  static String addInstallmentInfo(String title, int? currentInstallment, int? installmentCount) {
    if (currentInstallment != null && installmentCount != null && installmentCount > 1) {
      return '$title ($currentInstallment/$installmentCount)';
    }
    return title;
  }
  
  // ==================== MAIN COMPONENTS ====================
  
  /// Build standard transaction item
  static Widget buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required TransactionType type,
    required bool isDark,
    String? time,
    String? categoryIcon,
    String? categoryColor,
    IconData? categoryIconData,
    Color? categoryColorData,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isFirst = false,
    bool isLast = false,
  }) {
    IconData icon;
    Color iconColor;
    
    if (categoryIconData != null) {
      icon = categoryIconData;
      iconColor = categoryColorData ?? _getDefaultColorForType(type);
    } else if (categoryIcon != null) {
      icon = getCategoryIcon(categoryIcon);
      iconColor = categoryColor != null 
          ? getCategoryColor(categoryColor)
          : _getDefaultColorForType(type);
    } else {
      icon = getTransactionTypeIcon(type);
      iconColor = _getDefaultColorForType(type);
    }
    
    return TransactionItem(
      title: title,
      subtitle: subtitle,
      amount: amount,
      time: time,
      icon: icon,
      iconColor: iconColor,
      backgroundColor: iconColor.withValues(alpha: 0.1),
      amountColor: getAmountColor(type, isDark),
      isDark: isDark,
      onTap: onTap,
      onLongPress: onLongPress,
      isFirst: isFirst,
      isLast: isLast,
    );
  }
  
  /// Build transaction list container
  static Widget buildTransactionList({
    required List<Widget> transactions,
    required bool isDark,
    String? emptyTitle,
    String? emptyDescription,
    IconData? emptyIcon,
  }) {
    if (transactions.isEmpty) {
      return TransactionEmptyState(
        title: emptyTitle ?? 'Henüz işlem yok',
        description: emptyDescription ?? 'İlk işleminizi ekleyerek başlayın',
        icon: emptyIcon ?? Icons.receipt_long_outlined,
        isDark: isDark,
      );
    }
    
    return TransactionListContainer(
      transactions: transactions,
      isDark: isDark,
    );
  }
  
  /// Build loading skeleton
  static Widget buildLoadingSkeleton({
    required bool isDark,
    int itemCount = 3,
  }) {
    return TransactionLoadingSkeleton(
      isDark: isDark,
      itemCount: itemCount,
    );
  }
  
  /// Build transaction item with specific icon override
  static Widget buildTransactionItemWithIcon({
    required String title,
    required String subtitle,
    required String amount,
    required bool isDark,
    String? time,
    IconData? specificIcon,
    Color? specificIconColor,
    Color? specificBackgroundColor,
    Color? specificAmountColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return TransactionItem(
      title: title,
      subtitle: subtitle,
      amount: amount,
      time: time,
      icon: specificIcon ?? Icons.receipt_outlined,
      iconColor: specificIconColor ?? const Color(0xFF6B7280),
      backgroundColor: specificBackgroundColor ?? const Color(0xFF6B7280).withValues(alpha: 0.1),
      amountColor: specificAmountColor ?? getTitleColor(isDark),
      isDark: isDark,
      onTap: onTap,
      onLongPress: onLongPress,
      isFirst: isFirst,
      isLast: isLast,
    );
  }
}

// ==================== DATA CLASSES ====================

enum TransactionType {
  income,
  expense,
  transfer,
}

class TransactionIconData {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  
  const TransactionIconData({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

// ==================== UI COMPONENTS ====================

/// Standard transaction item widget
class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String? time;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color amountColor;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isFirst;
  final bool isLast;

  const TransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.amountColor,
    required this.isDark,
    this.time,
    this.onTap,
    this.onLongPress,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? TransactionDesignSystem.verticalPadding + 4 : TransactionDesignSystem.verticalPadding,
        bottom: isLast ? TransactionDesignSystem.verticalPadding + 4 : TransactionDesignSystem.verticalPadding,
        left: TransactionDesignSystem.horizontalPadding,
        right: TransactionDesignSystem.horizontalPadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            // Icon Container
            Container(
              width: TransactionDesignSystem.iconContainerSize,
              height: TransactionDesignSystem.iconContainerSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(TransactionDesignSystem.iconBorderRadius),
              ),
              child: Stack(
                children: [
                  // Main icon
                  Center(
              child: Icon(
                icon,
                color: iconColor,
                size: TransactionDesignSystem.iconSize,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: TransactionDesignSystem.iconContentSpacing),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: TransactionDesignSystem.titleFontSize,
                      fontWeight: TransactionDesignSystem.titleFontWeight,
                      color: TransactionDesignSystem.getTitleColor(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: TransactionDesignSystem.titleSubtitleSpacing),
                  Text(
                    time != null ? '$subtitle • $time' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: TransactionDesignSystem.subtitleFontSize,
                      fontWeight: TransactionDesignSystem.subtitleFontWeight,
                      color: TransactionDesignSystem.getSubtitleColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: TransactionDesignSystem.amountFontSize,
                fontWeight: TransactionDesignSystem.amountFontWeight,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction list container
class TransactionListContainer extends StatelessWidget {
  final List<Widget> transactions;
  final bool isDark;

  const TransactionListContainer({
    super.key,
    required this.transactions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TransactionDesignSystem.getContainerColor(isDark),
        borderRadius: BorderRadius.circular(TransactionDesignSystem.containerBorderRadius),
        border: Border.all(
          color: TransactionDesignSystem.getBorderColor(isDark),
          width: TransactionDesignSystem.containerBorderWidth,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            transactions[i],
            if (i < transactions.length - 1)
              Padding(
                padding: EdgeInsets.only(left: TransactionDesignSystem.horizontalPadding + TransactionDesignSystem.iconContainerSize + TransactionDesignSystem.iconContentSpacing),
                child: Container(
                  height: 0.5,
                  color: TransactionDesignSystem.getBorderColor(isDark),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Transaction empty state
class TransactionEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;

  const TransactionEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: TransactionDesignSystem.getSubtitleColor(isDark).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 30,
                color: TransactionDesignSystem.getSubtitleColor(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TransactionDesignSystem.getTitleColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TransactionDesignSystem.getSubtitleColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction loading skeleton
class TransactionLoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final int itemCount;

  const TransactionLoadingSkeleton({
    super.key,
    required this.isDark,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TransactionDesignSystem.getContainerColor(isDark),
        borderRadius: BorderRadius.circular(TransactionDesignSystem.containerBorderRadius),
        border: Border.all(
          color: TransactionDesignSystem.getBorderColor(isDark),
          width: TransactionDesignSystem.containerBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(itemCount, (index) => Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 12 : 0),
          child: Row(
            children: [
              // Icon skeleton
              Container(
                width: TransactionDesignSystem.iconContainerSize,
                height: TransactionDesignSystem.iconContainerSize,
                decoration: BoxDecoration(
                  color: TransactionDesignSystem.getTitleColor(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TransactionDesignSystem.iconBorderRadius),
                ),
              ),
              SizedBox(width: TransactionDesignSystem.iconContentSpacing),
              
              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: TransactionDesignSystem.getTitleColor(isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: TransactionDesignSystem.getTitleColor(isDark).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount skeleton
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: TransactionDesignSystem.getTitleColor(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
} 