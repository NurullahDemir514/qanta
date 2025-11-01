import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../shared/models/budget_model.dart';
import '../../../../shared/utils/currency_utils.dart';

class TransactionSummary extends StatelessWidget {
  final double amount;
  final String? category;
  final String? categoryName; // Backward compatibility
  final String? paymentMethod;
  final String? paymentMethodName; // Backward compatibility
  final DateTime date;
  final String? description;
  final String? transactionType;
  final bool? isIncome;

  const TransactionSummary({
    super.key,
    required this.amount,
    this.category,
    this.categoryName, // Deprecated, use category
    this.paymentMethod,
    this.paymentMethodName, // Deprecated, use paymentMethod
    required this.date,
    this.description,
    this.transactionType,
    this.isIncome,
  });

  String _formatCurrency(double amount, BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: Provider.of<ThemeProvider>(context, listen: false).currency.locale,
      symbol: Provider.of<ThemeProvider>(context, listen: false).currency.symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Fallback to English format
      final formatter = DateFormat('dd MMMM yyyy', 'en_US');
      return formatter.format(date);
    }
    
    // Use localized date format based on current locale
    final locale = Localizations.localeOf(context);
    final formatter = DateFormat('dd MMMM yyyy', locale.toString());
    return formatter.format(date);
  }

  String get _categoryDisplay => category ?? categoryName ?? '';
  String get _paymentMethodDisplay => paymentMethod ?? paymentMethodName ?? '';
  String _getTransactionTypeDisplay(BuildContext context) {
    if (transactionType != null) return transactionType!;
    if (isIncome == true) return AppLocalizations.of(context)?.income ?? 'Income';
    return AppLocalizations.of(context)?.transaction ?? 'Transaction';
  }

  /// Check budget limits for this transaction
  Map<String, dynamic>? _checkBudgetLimits(BuildContext context) {
    // Only check for expense transactions
    if (isIncome == true) return null;
    
    final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final categoryName = _categoryDisplay;
    
    if (categoryName.isEmpty) return null;
    
    // Find matching budget for the category
    final matchingBudget = provider.budgets.firstWhere(
      (budget) => budget.categoryName.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => BudgetModel(
        id: '',
        userId: '',
        categoryId: '',
        categoryName: '',
        limit: 0.0,
        period: BudgetPeriod.monthly,
        month: DateTime.now().month,
        year: DateTime.now().year,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // If no budget found, no warning
    if (matchingBudget.id.isEmpty) return null;

    // Check if transaction amount exceeds budget limit
    final remainingBudget = matchingBudget.limit - matchingBudget.spentAmount;
    final isOverBudget = amount > remainingBudget;
    
    // Check if transaction would exceed budget significantly
    final exceedsBudget = amount > matchingBudget.limit;
    
    String? warning;
    String? warningType;
    Color? warningColor;
    
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    
    if (isOverBudget) {
      final overAmount = amount - remainingBudget;
      final formattedAmount = CurrencyUtils.formatAmountWithoutSymbol(overAmount, currency);
      warning = l10n.budgetExceededWarning(formattedAmount);
      warningType = 'over_budget';
      warningColor = const Color(0xFFFF4C4C);
    } else if (exceedsBudget) {
      final overAmount = amount - matchingBudget.limit;
      final formattedAmount = CurrencyUtils.formatAmountWithoutSymbol(overAmount, currency);
      warning = l10n.budgetExceededWarningTotal(formattedAmount);
      warningType = 'exceeds_budget';
      warningColor = const Color(0xFFFF9500);
    } else if (amount > matchingBudget.limit * 0.8) {
      warning = l10n.budgetNearLimitWarning;
      warningType = 'near_limit';
      warningColor = const Color(0xFFFFC300);
    }

    if (warning == null) return null;

    return {
      'warning': warning,
      'warningType': warningType,
      'warningColor': warningColor,
      'budget': matchingBudget,
      'remainingBudget': remainingBudget,
      'isOverBudget': isOverBudget,
      'exceedsBudget': exceedsBudget,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check budget limits
    final budgetCheck = _checkBudgetLimits(context);
    
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    final isLandscape = screenHeight < screenWidth;
    
    // Responsive değerler - Mobil odaklı
    final titleFontSize = isSmallMobile ? 16.0 :
                         isMobile ? 17.0 :
                         isLargeMobile ? 18.0 :
                         isSmallTablet ? 19.0 :
                         isTablet ? 20.0 : 22.0;
    
    final titleSpacing = isSmallMobile ? 12.0 :
                        isMobile ? 14.0 :
                        isLargeMobile ? 16.0 :
                        isSmallTablet ? 18.0 :
                        isTablet ? 20.0 : 24.0;
    
    final cardPadding = isSmallMobile ? 12.0 :
                       isMobile ? 14.0 :
                       isLargeMobile ? 16.0 :
                       isSmallTablet ? 18.0 :
                       isTablet ? 20.0 : 24.0;
    
    final cardBorderRadius = isSmallMobile ? 10.0 :
                            isMobile ? 11.0 :
                            isLargeMobile ? 12.0 :
                            isSmallTablet ? 14.0 :
                            isTablet ? 16.0 : 18.0;
    
    final amountContainerPadding = isSmallMobile ? 12.0 :
                                  isMobile ? 14.0 :
                                  isLargeMobile ? 16.0 :
                                  isSmallTablet ? 18.0 :
                                  isTablet ? 20.0 : 24.0;
    
    final amountContainerBorderRadius = isSmallMobile ? 6.0 :
                                       isMobile ? 7.0 :
                                       isLargeMobile ? 8.0 :
                                       isSmallTablet ? 9.0 :
                                       isTablet ? 10.0 : 12.0;
    
    final amountLabelFontSize = isSmallMobile ? 12.0 :
                               isMobile ? 13.0 :
                               isLargeMobile ? 14.0 :
                               isSmallTablet ? 15.0 :
                               isTablet ? 16.0 : 18.0;
    
    final amountFontSize = isSmallMobile ? 22.0 :
                          isMobile ? 24.0 :
                          isLargeMobile ? 26.0 :
                          isSmallTablet ? 28.0 :
                          isTablet ? 30.0 : 32.0;
    
    final detailSpacing = isSmallMobile ? 8.0 :
                         isMobile ? 10.0 :
                         isLargeMobile ? 12.0 :
                         isSmallTablet ? 14.0 :
                         isTablet ? 16.0 : 18.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mevcut alanı hesapla
        final availableHeight = constraints.maxHeight;
        
        // Landscape modda daha kompakt spacing kullan
        final adjustedTitleSpacing = isLandscape ? titleSpacing * 0.8 : titleSpacing;
        final adjustedCardPadding = isLandscape ? cardPadding * 0.8 : cardPadding;
        final adjustedDetailSpacing = isLandscape ? detailSpacing * 0.8 : detailSpacing;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Özet Title (Detaylar yerine)
            Text(
              l10n.summary,
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
            ),
            
            SizedBox(height: adjustedTitleSpacing),
            
            // Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(adjustedCardPadding),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(cardBorderRadius),
                border: Border.all(
                  color: isDark 
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount (Main highlight)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(amountContainerPadding),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(amountContainerBorderRadius),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTransactionTypeDisplay(context),
                          style: GoogleFonts.inter(
                            fontSize: amountLabelFontSize,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                          ),
                        ),
                        SizedBox(height: isSmallMobile ? 3.0 : 4.0),
                        Text(
                          _formatCurrency(amount, context),
                          style: GoogleFonts.inter(
                            fontSize: amountFontSize,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: adjustedDetailSpacing),
                  
                  // Details
                  if (_categoryDisplay.isNotEmpty) ...[
                    _buildDetailRow(l10n.category, _categoryDisplay, isDark, screenWidth),
                    SizedBox(height: adjustedDetailSpacing),
                  ],
                  if (_paymentMethodDisplay.isNotEmpty) ...[
                    _buildDetailRow(l10n.payment, _paymentMethodDisplay, isDark, screenWidth),
                    SizedBox(height: adjustedDetailSpacing),
                  ],
                  _buildDetailRow(l10n.date, _formatDate(date, context), isDark, screenWidth),
                  
                  if (description != null && description!.isNotEmpty) ...[
                    SizedBox(height: adjustedDetailSpacing),
                    _buildDetailRow(l10n.description, description!, isDark, screenWidth),
                  ],
                ],
              ),
            ),
            
            // Budget Warning (if any)
            if (budgetCheck != null) ...[
              SizedBox(height: adjustedTitleSpacing),
              _buildBudgetWarning(budgetCheck, isDark, screenWidth),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, double screenWidth) {
    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360;      // iPhone SE, küçük telefonlar
    final isMobile = screenWidth > 360 && screenWidth <= 480;  // Standart telefonlar
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;  // Büyük telefonlar
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;  // Küçük tabletler
    final isTablet = screenWidth > 768 && screenWidth <= 1024;      // Standart tabletler
    final isLargeTablet = screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200;          // Desktop/laptop
    
    // Responsive değerler
    final labelWidth = isSmallMobile ? 70.0 :
                      isMobile ? 75.0 :
                      isLargeMobile ? 80.0 :
                      isSmallTablet ? 85.0 :
                      isTablet ? 90.0 : 100.0;
    
    final labelFontSize = isSmallMobile ? 12.0 :
                         isMobile ? 13.0 :
                         isLargeMobile ? 14.0 :
                         isSmallTablet ? 15.0 :
                         isTablet ? 16.0 : 18.0;
    
    final valueFontSize = isSmallMobile ? 12.0 :
                         isMobile ? 13.0 :
                         isLargeMobile ? 14.0 :
                         isSmallTablet ? 15.0 :
                         isTablet ? 16.0 : 18.0;
    
    final spacing = isSmallMobile ? 8.0 :
                   isMobile ? 10.0 :
                   isLargeMobile ? 12.0 :
                   isSmallTablet ? 14.0 :
                   isTablet ? 16.0 : 20.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
              color: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetWarning(Map<String, dynamic> budgetCheck, bool isDark, double screenWidth) {
    final warning = budgetCheck['warning'] as String;
    final warningColor = budgetCheck['warningColor'] as Color;
    final warningType = budgetCheck['warningType'] as String;
    
    // Responsive değerler
    final isSmallMobile = screenWidth <= 360;
    final isMobile = screenWidth > 360 && screenWidth <= 480;
    final isLargeMobile = screenWidth > 480 && screenWidth <= 600;
    
    final warningPadding = isSmallMobile ? 12.0 :
                          isMobile ? 14.0 :
                          isLargeMobile ? 16.0 : 18.0;
    
    final warningBorderRadius = isSmallMobile ? 8.0 :
                               isMobile ? 10.0 :
                               isLargeMobile ? 12.0 : 14.0;
    
    final iconSize = isSmallMobile ? 16.0 :
                    isMobile ? 18.0 :
                    isLargeMobile ? 20.0 : 22.0;
    
    final textFontSize = isSmallMobile ? 12.0 :
                        isMobile ? 13.0 :
                        isLargeMobile ? 14.0 : 15.0;
    
    IconData iconData;
    switch (warningType) {
      case 'over_budget':
        iconData = Icons.warning_amber_rounded;
        break;
      case 'exceeds_budget':
        iconData = Icons.error_outline_rounded;
        break;
      case 'near_limit':
        iconData = Icons.info_outline_rounded;
        break;
      default:
        iconData = Icons.info_outline_rounded;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(warningPadding),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(warningBorderRadius),
        border: Border.all(
          color: warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: warningColor,
            size: iconSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warning,
              style: GoogleFonts.inter(
                fontSize: textFontSize,
                fontWeight: FontWeight.w500,
                color: warningColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 