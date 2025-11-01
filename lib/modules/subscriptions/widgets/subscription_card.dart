import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/recurring_transaction_model.dart';
import '../../../shared/models/account_model.dart';
import '../../../modules/transactions/models/recurring_frequency.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';

/// Subscription Card Widget
/// 
/// Displays a subscription/recurring transaction in a gradient card format.
/// Similar to SavingsGoalCard but designed for subscriptions.
class SubscriptionCard extends StatelessWidget {
  final RecurringTransaction subscription;
  final VoidCallback? onTap;
  final Function(bool)? onToggle;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

/// Format next payment date
  String _formatNextPaymentDate(AppLocalizations l10n, DateTime? nextDate) {
    if (nextDate == null) {
      final calculated = subscription.calculateNextExecutionDate();
      return DateFormat('dd MMM yyyy', l10n.localeName).format(calculated);
    }
    return DateFormat('dd MMM yyyy', l10n.localeName).format(nextDate);
  }

  /// Get account short name
  String _getAccountShortName(UnifiedProviderV2 provider, String accountId, AppLocalizations l10n) {
    final account = provider.getAccountById(accountId);
    if (account == null) return 'N/A';
    
    // For cash wallet, use localized name
    if (account.type == AccountType.cash) {
      return l10n.cashWallet;
    }
    
    // Get first word of account name (bank name or card name)
    final words = account.name.trim().split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      return words.first;
    }
    return account.name;
  }

  /// Get category color (for icon container)
  Color _getCategoryColor(RecurringCategory category) {
    switch (category) {
      case RecurringCategory.subscription:
        return const Color(0xFF9D50BB);
      case RecurringCategory.utilities:
        return const Color(0xFF2196F3);
      case RecurringCategory.insurance:
        return const Color(0xFF4CAF50);
      case RecurringCategory.rent:
        return const Color(0xFFFF6B6B);
      case RecurringCategory.loan:
        return const Color(0xFFD32F2F);
      case RecurringCategory.other:
        return const Color(0xFF6D6D70);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final unifiedProvider = context.watch<UnifiedProviderV2>();
    final l10n = AppLocalizations.of(context)!;

    final nextPaymentDate = subscription.nextExecutionDate ?? 
        subscription.calculateNextExecutionDate();
    final categoryColor = _getCategoryColor(subscription.category);
    final accountName = _getAccountShortName(unifiedProvider, subscription.accountId, l10n);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () {
              HapticFeedback.mediumImpact();
              _showDeleteDialog(context, l10n, isDark);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  // Icon container (budget card style)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      subscription.category.icon,
                      size: 14,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      subscription.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!subscription.isActive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? const Color(0xFF3A3A3C)
                                            : const Color(0xFFE5E5EA),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.inactive,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.6)
                                              : const Color(0xFF6D6D70),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${subscription.category.getName(l10n)} • ${subscription.frequency.getDisplayName(l10n)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF1C1C1E).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle switch (iOS style)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onToggle != null) {
                        onToggle!(!subscription.isActive);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color: subscription.isActive
                            ? (isDark 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05))
                            : (isDark 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            left: subscription.isActive ? 22 : 2,
                            top: 2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subscription.isActive
                                    ? const Color(0xFF34C759)
                                    : (isDark 
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: subscription.isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF34C759).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Amount and next payment info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyUtils.formatAmount(subscription.amount, themeProvider.currency),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isDark 
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF1C1C1E).withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNextPaymentDate(l10n, nextPaymentDate),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark 
                                  ? Colors.white.withOpacity(0.85)
                                  : const Color(0xFF1C1C1E).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Account badge
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
                    child: Text(
                      accountName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, AppLocalizations l10n, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.deleteSubscription ?? 'Aboneliği Sil',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          l10n.deleteSubscriptionConfirm(subscription.name),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF453A),
            ),
            child: Text(
              l10n.delete,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF453A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


