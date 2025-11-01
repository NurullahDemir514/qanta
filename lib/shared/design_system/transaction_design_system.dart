import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/category_icon_service.dart';
import '../utils/currency_utils.dart';
import '../../l10n/app_localizations.dart';
import '../models/transaction_model_v2.dart';

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
  static const double horizontalPadding = 8.0;
  static const double verticalPadding = 8.0;
  static const double iconContentSpacing = 12.0;
  static const double titleSubtitleSpacing = 2.0;

  /// Container Specifications
  static const double containerBorderRadius = 12.0;
  static const double containerBorderWidth = 0.5;

  /// Animation Specifications
  static const Duration tapAnimationDuration = Duration(milliseconds: 150);
  static const Duration longPressAnimationDuration = Duration(
    milliseconds: 200,
  );

  // ==================== NUMBER FORMATTING ====================

  /// Turkish number formatter with thousand separators
  static final NumberFormat _turkishNumberFormat = NumberFormat(
    '#,##0.00',
    'tr_TR',
  );

  /// Format number with Turkish thousand separators (dots)
  static String formatNumber(double number) {
    return _turkishNumberFormat.format(number).replaceAll(',', '.');
  }

  /// Shorten long account names for better display
  static String shortenAccountName(String accountName, {int maxLength = 15, BuildContext? context, bool isInstallment = false}) {
    // Taksitli işlemler için daha uzun karakter limiti
    if (isInstallment) {
      maxLength = 25;
    }
    // Localize special account names
    if (accountName == 'CASH_WALLET' && context != null) {
      return AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap';
    }
    
    // Localize card type names and cash account names
    if (context != null) {
      final l10n = AppLocalizations.of(context)!;
      
      // Remove card type phrases in any language and re-add in current language
      String localizedName = accountName;
      
      // Check if it's a cash account (various formats)
      final isCashAccount = RegExp(r'^(Cash Account|Nakit Hesap|Nakit|Cash)$', caseSensitive: false).hasMatch(localizedName);
      
      // Check if it contains card type phrases
      final hasCreditCard = RegExp(r'(Credit Card|Kredi Kartı)', caseSensitive: false).hasMatch(localizedName);
      final hasDebitCard = RegExp(r'(Debit Card|Banka Kartı)', caseSensitive: false).hasMatch(localizedName);
      
      if (isCashAccount) {
        // Replace with localized cash account name
        localizedName = l10n.cashAccount;
      } else if (hasCreditCard) {
        // Remove all variants and add localized version
        localizedName = localizedName
            .replaceAll(RegExp(r'\s*(Credit Card|Kredi Kartı)\s*', caseSensitive: false), ' ')
            .trim();
        localizedName = '$localizedName ${l10n.creditCard}';
      } else if (hasDebitCard) {
        // Remove all variants and add localized version
        localizedName = localizedName
            .replaceAll(RegExp(r'\s*(Debit Card|Banka Kartı)\s*', caseSensitive: false), ' ')
            .trim();
        localizedName = '$localizedName ${l10n.debitCard}';
      }
      
      accountName = localizedName;
    }
    
    if (accountName.length <= maxLength) {
      return accountName;
    }

    // Clean up common patterns like "Bank - Bank Card Name"
    String cleanedName = accountName;

    // Remove patterns like "Akbank - Akbank Kredi Kartı" -> "Akbank Kredi Kartı"
    final duplicatePattern = RegExp(r'^([^-]+)\s*-\s*\1\s*(.*)$');
    final duplicateMatch = duplicatePattern.firstMatch(cleanedName);
    if (duplicateMatch != null) {
      final bankName = duplicateMatch.group(1)!.trim();
      final cardName = duplicateMatch.group(2)!.trim();
      cleanedName = '$bankName $cardName';
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
      if (cleanedName.contains(entry.key)) {
        final shortened = cleanedName.replaceAll(entry.key, entry.value);
        if (shortened.length <= maxLength) {
          return shortened;
        }
      }
    }

    // If still too long, truncate with ellipsis
    return '${cleanedName.substring(0, maxLength - 1)}…';
  }

  /// Format transfer subtitle with first and second word of account names
  static String formatTransferSubtitle(
    String sourceAccount,
    String targetAccount, {
    int maxLength = 10,
    BuildContext? context,
  }) {
    final shortSource = _getFirstTwoWords(sourceAccount);
    final shortTarget = _getFirstTwoWords(targetAccount);
    return '$shortSource → $shortTarget';
  }

  /// Get first and second word from account name
  static String _getFirstTwoWords(String accountName) {
    final words = accountName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0]} ${words[1]}';
    } else if (words.length == 1) {
      return words[0];
    }
    return accountName;
  }

  /// **CENTRALIZED CARD NAME LOGIC**
  ///
  /// This method centralizes the card name formatting logic used across
  /// all transaction display components (CardTransactionSection, RecentTransactionsSection, TransactionsScreen).
  ///
  /// Parameters:
  /// - [cardName]: The base card name (from widget.cardName or transaction.sourceAccountName)
  /// - [transactionType]: The type of transaction (expense, income, transfer)
  /// - [sourceAccountName]: Source account name for transfers
  /// - [targetAccountName]: Target account name for transfers
  /// - [isInstallment]: Whether this is an installment transaction (uses 25 char limit)
  ///
  /// Returns formatted card name based on transaction type.
  static String formatCardName({
    required String cardName,
    required String transactionType,
    String? sourceAccountName,
    String? targetAccountName,
    BuildContext? context,
    bool isInstallment = false,
  }) {
    if (transactionType == 'transfer') {
      final sourceAccount =
          sourceAccountName ??
          (context != null ? AppLocalizations.of(context)?.account : null) ??
          'HESAP';
      final targetAccount =
          targetAccountName ??
          (context != null ? AppLocalizations.of(context)?.account : null) ??
          'HESAP';
      return formatTransferSubtitle(sourceAccount, targetAccount, context: context);
    } else {
      // Shorten regular card names
      return shortenAccountName(cardName, context: context, isInstallment: isInstallment);
    }
  }

  // ==================== COLOR SYSTEM ====================

  /// **CENTRALIZED COLOR SYSTEM**
  ///
  /// All colors now managed through CategoryIconService for consistency.
  /// This eliminates duplicate color definitions and ensures uniform
  /// color usage across the entire application.

  /// Transaction Type Colors - delegated to CategoryIconService
  static Color get incomeColor =>
      CategoryIconService.getColorFromMap('income_default');
  static Color get expenseColor =>
      CategoryIconService.getColorFromMap('expense_default');
  static Color get transferColor =>
      CategoryIconService.getColorFromMap('transfer_default');

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
      // Always use transaction type color, ignore category color
      iconColor = _getDefaultColorForType(type);
    } else if (categoryIcon != null) {
      // Use category icon but always use transaction type color
      icon = getCategoryIcon(categoryIcon);
      iconColor = _getDefaultColorForType(type);
    } else {
      // Use transaction type icon and color
      icon = getTransactionTypeIcon(type);
      iconColor = _getDefaultColorForType(type);
    }

    return TransactionIconData(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
    );
  }

  static Color _getDefaultColorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF22C55E); // Yeşil - Gelir
      case TransactionType.expense:
        return const Color(0xFFFF3B30); // Kırmızı - Gider
      case TransactionType.transfer:
        return const Color(0xFF007AFF); // Mavi - Transfer
    }
  }

  // ==================== TEXT FORMATTING ====================

  /// Format transaction amount
  static String formatAmount(
    double amount,
    TransactionType type, {
    String? currencySymbol,
    Currency? currency,
  }) {
    // Use provided currency or determine from symbol
    Currency activeCurrency = currency ?? Currency.TRY;
    if (currency == null && currencySymbol != null) {
      if (currencySymbol == '\$') {
        activeCurrency = Currency.USD;
      } else if (currencySymbol == '€') {
        activeCurrency = Currency.EUR;
      } else if (currencySymbol == '£') {
        activeCurrency = Currency.GBP;
      } else if (currencySymbol == '₺') {
        activeCurrency = Currency.TRY;
      }
    }
    
    // Use CurrencyUtils for proper formatting
    final formattedAmount = CurrencyUtils.formatAmountWithoutSymbol(amount.abs(), activeCurrency);
    final symbol = currencySymbol ?? activeCurrency.symbol;

    switch (type) {
      case TransactionType.income:
        return '+$formattedAmount$symbol';
      case TransactionType.expense:
        return '-$formattedAmount$symbol';
      case TransactionType.transfer:
        return '$formattedAmount$symbol';
    }
  }

  /// Add installment info to title
  static String addInstallmentInfo(
    String title,
    int? currentInstallment,
    int? installmentCount,
  ) {
    if (currentInstallment != null &&
        installmentCount != null &&
        installmentCount > 1) {
      return '$title ($currentInstallment/$installmentCount)';
    }
    return title;
  }

  // ==================== MAIN COMPONENTS ====================

  /// Localize display time with proper locale formatting
  static String localizeDisplayTime(String rawTime, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    
    switch (rawTime) {
      case 'TODAY': 
        return l10n.today;
      case 'YESTERDAY': 
        return l10n.yesterday;
      default: 
        // Raw date format like "10/10" - convert to localized format
        if (rawTime.contains('/')) {
          final parts = rawTime.split('/');
          if (parts.length == 2) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            if (day != null && month != null) {
              // Create a DateTime object for current year
              final now = DateTime.now();
              final date = DateTime(now.year, month, day);
              
              // Format with proper locale based on language code
              String localeString;
              switch (languageCode) {
                case 'en':
                  localeString = 'en_US';
                  break;
                case 'de':
                  localeString = 'de_DE';
                  break;
                case 'tr':
                default:
                  localeString = 'tr_TR';
                  break;
              }
              
              final formatter = DateFormat('d MMM', localeString);
              return formatter.format(date);
            }
          }
        }
        return rawTime;
    }
  }

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
    bool isPaid = false,
    bool isInstallment = false, // New parameter
    bool isStock = false, // Stock transaction parameter
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
      isInstallment: isInstallment, // Pass installment flag
      isStock: isStock, // Pass stock flag
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      amountColor: getAmountColor(type, isDark),
      isDark: isDark,
      onTap: onTap,
      onLongPress: onLongPress,
      isFirst: isFirst,
      isLast: isLast,
      isPaid: isPaid,
    );
  }

  /// Build transaction list container
  static Widget buildTransactionList({
    required List<Widget> transactions,
    required bool isDark,
    String? emptyTitle,
    String? emptyDescription,
    IconData? emptyIcon,
    BuildContext? context,
  }) {
    if (transactions.isEmpty) {
      return TransactionEmptyState(
        title:
            emptyTitle ??
            (context != null
                ? AppLocalizations.of(context)?.noTransactionsYet
                : null) ??
            'No transactions yet',
        description:
            emptyDescription ??
            (context != null
                ? AppLocalizations.of(context)?.addFirstTransaction
                : null) ??
            'Add your first transaction to get started',
        icon: emptyIcon ?? Icons.receipt_long_outlined,
        isDark: isDark,
      );
    }

    return TransactionListContainer(transactions: transactions, isDark: isDark);
  }

  /// Build loading skeleton
  static Widget buildLoadingSkeleton({
    required bool isDark,
    int itemCount = 3,
  }) {
    return TransactionLoadingSkeleton(isDark: isDark, itemCount: itemCount);
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
    bool isPaid = false,
    bool isInstallment = false,
  }) {
    return TransactionItem(
      title: title,
      subtitle: subtitle,
      amount: amount,
      time: time,
      icon: specificIcon ?? Icons.receipt_outlined,
      iconColor: specificIconColor ?? const Color(0xFF6B7280),
      backgroundColor:
          specificBackgroundColor ?? Colors.grey.withValues(alpha: 0.1),
      amountColor: specificAmountColor ?? getTitleColor(isDark),
      isDark: isDark,
      onTap: onTap,
      onLongPress: onLongPress,
      isFirst: isFirst,
      isLast: isLast,
      isPaid: isPaid,
      isInstallment: isInstallment,
    );
  }

  /// Build transaction item from TransactionWithDetailsV2 (Firebase integrated)
  static Widget buildTransactionItemFromV2({
    required dynamic transaction, // TransactionWithDetailsV2
    required bool isDark,
    required BuildContext context,
    String? time,
    IconData? categoryIconData,
    Color? categoryColorData,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isFirst = false,
    bool isLast = false,
    bool isInstallment = false,
    int? totalInstallments,
    double? totalAmount,
    double? monthlyAmount,
    Currency? currency,
  }) {
    // Convert V2 transaction type to design system type
    TransactionType transactionType;
    switch (transaction.type.toString().split('.').last) {
      case 'income':
        transactionType = TransactionType.income;
        break;
      case 'expense':
        transactionType = TransactionType.expense;
        break;
      case 'transfer':
        transactionType = TransactionType.transfer;
        break;
      case 'stock':
        transactionType = TransactionType
            .income; // Stock transactions show as income for display
        break;
      default:
        transactionType = TransactionType.expense;
    }

    // Format amount with user's currency
    final amount = formatAmount(transaction.amount, transactionType, currency: currency);

    // Use displayTime from transaction model (dynamic date formatting)
    final displayTime = time ?? transaction.displayTime;

    // Handle installment transactions
    String displayTitle = transaction.getLocalizedDisplayTitle(context);
    String displaySubtitle = transaction.displaySubtitle;
    
    // Localize account names in subtitle (for all account name formats)
    // Check if it's a transfer (contains →)
    if (displaySubtitle.contains('→')) {
      // Transfer: localize both source and target
      final parts = displaySubtitle.split('→');
      if (parts.length == 2) {
        final localizedSource = shortenAccountName(parts[0].trim(), maxLength: 100, context: context);
        final localizedTarget = shortenAccountName(parts[1].trim(), maxLength: 100, context: context);
        displaySubtitle = '$localizedSource → $localizedTarget';
      }
    } else {
      // Single account: localize directly
      displaySubtitle = shortenAccountName(displaySubtitle, maxLength: 100, context: context);
    }

    // Check if this is a credit card installment transaction
    bool isCreditCardInstallment = false;
    if (isInstallment && totalInstallments != null) {
      // Add installment indicator to title
      displayTitle =
          '${transaction.displayTitle} (${AppLocalizations.of(context)?.installmentCount(totalInstallments) ?? '$totalInstallments Taksit'})';
      isCreditCardInstallment = true;
    } else {
      // Check if transaction description contains installment pattern
      final hasInstallmentPattern = RegExp(
        r'\(\d+ taksit\)',
      ).hasMatch(transaction.description ?? '');
      isCreditCardInstallment = hasInstallmentPattern;
    }

    // Check if this is a stock transaction and use expandable card
    if (transaction.isStockTransaction) {
      return StockExpandableCard(
        transaction: transaction,
        isDark: isDark,
        onLongPress: onLongPress,
        isFirst: isFirst,
        isLast: isLast,
        currency: currency,
      );
    }

    // Use the new display getters from TransactionWithDetailsV2
    return buildTransactionItem(
      title: displayTitle,
      subtitle: displaySubtitle,
      amount: amount,
      time: TransactionDesignSystem.localizeDisplayTime(displayTime, context),
      type: transactionType,
      isDark: isDark,
      categoryIconData: categoryIconData,
      categoryColorData: categoryColorData,
      onTap: onTap,
      onLongPress: onLongPress,
      isFirst: isFirst,
      isLast: isLast,
      isPaid: transaction.isPaid,
      isInstallment: isCreditCardInstallment, // Pass installment flag
      isStock: transaction.isStockTransaction, // Pass stock flag
    );
  }
}

// ==================== DATA CLASSES ====================

enum TransactionType { income, expense, transfer }

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
  final bool isPaid;
  final bool isInstallment; // New parameter
  final bool isStock; // Stock transaction parameter

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
    this.isPaid = false,
    this.isInstallment = false, // New parameter
    this.isStock = false, // Stock transaction parameter
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst
            ? TransactionDesignSystem.verticalPadding + 4
            : TransactionDesignSystem.verticalPadding,
        bottom: isLast
            ? TransactionDesignSystem.verticalPadding + 4
            : TransactionDesignSystem.verticalPadding,
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
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  TransactionDesignSystem.iconBorderRadius,
                ),
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
              child: _buildContentSection(context),
            ),

            // Amount (right aligned - outside of content)
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

  /// Build content section with dynamic description support
  Widget _buildContentSection(BuildContext context) {
    // Split title by bullet point to separate category and description
    final parts = title.split(' • ');
    final categoryName = parts[0];
    final description = parts.length > 1 ? parts.sublist(1).join(' • ') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title row with chip (no amount here)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category name (flexible to take available space)
            Flexible(
              child: Text(
                categoryName,
                style: GoogleFonts.inter(
                  fontSize: TransactionDesignSystem.titleFontSize,
                  fontWeight: TransactionDesignSystem.titleFontWeight,
                  color: TransactionDesignSystem.getTitleColor(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInstallment) ...[
              const SizedBox(width: 6),
              // Taksitli chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.shade800
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.orange.shade600
                        : Colors.orange.shade300,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.installment ?? 'Installment',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
            if (isStock) ...[
              const SizedBox(width: 6),
              // Stock chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.shade800
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.blue.shade600
                        : Colors.blue.shade300,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.stockChip ?? 'Stock',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Description (if available) - shown below category
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark 
                  ? const Color(0xFF98989F)
                  : const Color(0xFF6B6B70),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        const SizedBox(height: 2),
        
        // Subtitle (card name + time)
        Text(
          time != null ? '$subtitle • $time' : subtitle,
          style: GoogleFonts.inter(
            fontSize: TransactionDesignSystem.subtitleFontSize,
            fontWeight: TransactionDesignSystem.subtitleFontWeight,
            color: TransactionDesignSystem.getSubtitleColor(isDark),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        borderRadius: BorderRadius.circular(
          TransactionDesignSystem.containerBorderRadius,
        ),
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
                padding: EdgeInsets.only(
                  left:
                      TransactionDesignSystem.horizontalPadding +
                      TransactionDesignSystem.iconContainerSize +
                      TransactionDesignSystem.iconContentSpacing,
                ),
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
                color: TransactionDesignSystem.getSubtitleColor(
                  isDark,
                ).withValues(alpha: 0.1),
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
        borderRadius: BorderRadius.circular(
          TransactionDesignSystem.containerBorderRadius,
        ),
        border: Border.all(
          color: TransactionDesignSystem.getBorderColor(isDark),
          width: TransactionDesignSystem.containerBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 12 : 0),
            child: Row(
              children: [
                // Icon skeleton
                Container(
                  width: TransactionDesignSystem.iconContainerSize,
                  height: TransactionDesignSystem.iconContainerSize,
                  decoration: BoxDecoration(
                    color: TransactionDesignSystem.getTitleColor(
                      isDark,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      TransactionDesignSystem.iconBorderRadius,
                    ),
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
                          color: TransactionDesignSystem.getTitleColor(
                            isDark,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: TransactionDesignSystem.getTitleColor(
                            isDark,
                          ).withValues(alpha: 0.05),
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
                    color: TransactionDesignSystem.getTitleColor(
                      isDark,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hisse işlemleri için expandable kart (taksitli kart yapısını referans alır)
class StockExpandableCard extends StatefulWidget {
  final TransactionWithDetailsV2 transaction;
  final bool isDark;
  final VoidCallback? onLongPress;
  final bool isFirst;
  final bool isLast;
  final Currency? currency;

  const StockExpandableCard({
    super.key,
    required this.transaction,
    required this.isDark,
    this.onLongPress,
    this.isFirst = false,
    this.isLast = false,
    this.currency,
  });

  @override
  State<StockExpandableCard> createState() => _StockExpandableCardState();
}

class _StockExpandableCardState extends State<StockExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final transaction = widget.transaction;
    final currency = widget.currency ?? Currency.TRY;

    // Format amount with user's currency
    final amount = TransactionDesignSystem.formatAmount(
      transaction.amount,
      TransactionType.income,
      currency: currency,
    );
    final rawTime = transaction.displayTime;
    final time = TransactionDesignSystem.localizeDisplayTime(rawTime, context);

    // Get account name
    final accountName = transaction.sourceAccountName ?? 'Hesap';
    
    // Localize CASH_WALLET
    final localizedAccountName = accountName == 'CASH_WALLET' 
        ? (AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap')
        : accountName;

    // Get stock details
    final stockSymbol = transaction.stockSymbol ?? '';
    final stockName = transaction.stockName ?? '';
    final stockQuantity = transaction.stockQuantity;
    final stockPrice = transaction.stockPrice;

    // Determine action
    final l10n = AppLocalizations.of(context)!;
    final action = transaction.amount > 0 ? l10n.stockSale : l10n.stockPurchase;
    final actionColor = transaction.amount > 0 ? Colors.green : Colors.red;

    // Choose icon based on action (sale/purchase) - both use bar_chart
    final stockIcon = Icons.bar_chart;

    // Use neutral background but colored icon for stock transactions
    final iconData = TransactionIconData(
      icon: stockIcon,
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      iconColor: actionColor, // Alış kırmızı, satış yeşil
    );

    return Padding(
      padding: EdgeInsets.only(
        top: widget.isFirst
            ? TransactionDesignSystem.verticalPadding + 4
            : TransactionDesignSystem.verticalPadding,
        bottom: widget.isLast
            ? TransactionDesignSystem.verticalPadding + 4
            : TransactionDesignSystem.verticalPadding,
        left: TransactionDesignSystem.horizontalPadding,
        right: TransactionDesignSystem.horizontalPadding,
      ),
      child: Column(
        children: [
          // Main transaction row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            onLongPress: widget.onLongPress,
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: TransactionDesignSystem.iconContainerSize,
                  height: TransactionDesignSystem.iconContainerSize,
                  decoration: BoxDecoration(
                    color: iconData.backgroundColor,
                    borderRadius: BorderRadius.circular(
                      TransactionDesignSystem.iconBorderRadius,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData.icon,
                      color: iconData.iconColor,
                      size: TransactionDesignSystem.iconSize,
                    ),
                  ),
                ),

                SizedBox(width: TransactionDesignSystem.iconContentSpacing),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title - sadece hisse sembolü
                          Flexible(
                            child: Text(
                              stockSymbol,
                              style: GoogleFonts.inter(
                                fontSize: TransactionDesignSystem.titleFontSize,
                                fontWeight:
                                    TransactionDesignSystem.titleFontWeight,
                                color: TransactionDesignSystem.getTitleColor(
                                  isDark,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Investment badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.shade800
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? Colors.blue.shade600
                                    : Colors.blue.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.stockChip ??
                                  'Stock',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: TransactionDesignSystem.titleSubtitleSpacing,
                      ),

                      // Subtitle
                      Text(
                        time != null ? '$localizedAccountName • $time' : localizedAccountName,
                        style: GoogleFonts.inter(
                          fontSize: TransactionDesignSystem.subtitleFontSize,
                          color: TransactionDesignSystem.getSubtitleColor(
                            isDark,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Amount and expand arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amount column - flexible
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Ana tutar
                          Text(
                            amount,
                            style: GoogleFonts.inter(
                              fontSize: TransactionDesignSystem.amountFontSize,
                              fontWeight:
                                  TransactionDesignSystem.amountFontWeight,
                              color: actionColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Stock detail (small)
                          if (stockQuantity != null && stockPrice != null)
                            Text(
                              '${stockQuantity.toStringAsFixed(0)} ${l10n.pieces} @ ${CurrencyUtils.formatAmount(stockPrice, currency)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: TransactionDesignSystem.getSubtitleColor(
                                  isDark,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expandable stock details
          SizeTransition(sizeFactor: _animation, child: _buildStockDetails()),
        ],
      ),
    );
  }

  Widget _buildStockDetails() {
    final isDark = widget.isDark;
    final transaction = widget.transaction;
    final currency = widget.currency ?? Currency.TRY;
    final l10n = AppLocalizations.of(context)!;
    final stockName = transaction.stockName ?? '';
    final stockQuantity = transaction.stockQuantity;
    final stockPrice = transaction.stockPrice;
    final totalAmount = (stockQuantity ?? 0) * (stockPrice ?? 0);

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 52), // Align with content
      child: Column(
        children: [
          if (stockName.isNotEmpty) ...[
            _buildDetailRow(l10n.stockName, stockName, isDark),
            const SizedBox(height: 8),
          ],
          if (stockQuantity != null) ...[
            _buildDetailRow(
              l10n.quantity,
              '${stockQuantity.toStringAsFixed(0)} ${l10n.pieces}',
              isDark,
            ),
            const SizedBox(height: 8),
          ],
          if (stockPrice != null) ...[
            _buildDetailRow(
              l10n.price,
              CurrencyUtils.formatAmount(stockPrice, currency),
              isDark,
            ),
            const SizedBox(height: 8),
          ],
          _buildDetailRow(
            l10n.total,
            CurrencyUtils.formatAmount(totalAmount, currency),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label - flexible
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TransactionDesignSystem.getSubtitleColor(isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Value - sağa yaslanmış
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
