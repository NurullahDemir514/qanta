import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/recurring_transaction_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/recurring_transaction_model.dart';
import '../../../modules/transactions/models/recurring_frequency.dart';
import '../../../l10n/app_localizations.dart';

class SubscriptionsOverviewCard extends StatefulWidget {
  const SubscriptionsOverviewCard({super.key});

  @override
  State<SubscriptionsOverviewCard> createState() => _SubscriptionsOverviewCardState();
}

class _SubscriptionsOverviewCardState extends State<SubscriptionsOverviewCard> {
  @override
  void initState() {
    super.initState();
    // Load subscriptions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecurringTransactionProvider>(context, listen: false)
          .loadSubscriptions();
    });
  }

  Widget _buildEmptyStateWithAddButton(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.subscriptions_outlined,
              size: 20,
              color: const Color(0xFF007AFF),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.noSubscriptionsYet,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // CTA Button
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showSubscriptionsManagement(context),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.add,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<RecurringTransactionProvider>(
      builder: (context, provider, child) {
        // Get active subscriptions
        final activeSubscriptions = provider.activeSubscriptions;

        // Show empty state if no subscriptions - but still show the header with add button
        if (activeSubscriptions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with manage button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.subscriptions,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showSubscriptionsManagement(context),
                    child: Text(
                      l10n.manage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6D6D70),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Empty state with add button
              _buildEmptyStateWithAddButton(context, isDark),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.subscriptions,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showSubscriptionsManagement(context),
                  child: Text(
                    l10n.manage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6D6D70),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Horizontal scroll cards
            SizedBox(
              height: 90.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: activeSubscriptions.length,
                itemBuilder: (context, index) => _buildSubscriptionCard(
                  activeSubscriptions[index],
                  isDark,
                  index,
                  activeSubscriptions.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(
    RecurringTransaction subscription,
    bool isDark,
    int index,
    int totalCount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final categoryColor = _getCategoryColor(subscription.category);
    final categoryIcon = subscription.category.icon;
    final frequencyText = subscription.frequency.getName(l10n);
    final nextPaymentDate = subscription.nextExecutionDate ?? subscription.calculateNextExecutionDate();
    final daysUntilNext = nextPaymentDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilNext <= 3 && daysUntilNext >= 0;
    final isOverdue = daysUntilNext < 0;
    final hasLastPayment = subscription.lastExecutedDate != null;
    final daysSinceLastPayment = hasLastPayment 
        ? DateTime.now().difference(subscription.lastExecutedDate!).inDays 
        : null;

    return Container(
      width: 180.w,
      height: 110.h, // Sabit yükseklik - badge'ler üstte olduğu için yeterli
      margin: EdgeInsets.only(right: index == (totalCount - 1) ? 0 : 12.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSubscriptionsManagement(context),
          borderRadius: BorderRadius.circular(16.r),
          child: Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(
                color: (isUrgent || isOverdue)
                    ? (isOverdue ? const Color(0xFFFF3B30).withOpacity(0.5) : categoryColor.withOpacity(0.3))
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                width: isUrgent || isOverdue ? 1.5.w : 1.w,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withOpacity(isUrgent ? 0.12 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subscription name and icon with frequency badge
                    Row(
                      children: [
                        Container(
                          width: 28.w, // Biraz büyük
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 14.w,
                            color: categoryColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscription.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 3.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      frequencyText,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w600,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ),
                                  if (hasLastPayment && daysSinceLastPayment != null && daysSinceLastPayment >= 0) ...[
                                    SizedBox(width: 4.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34C759).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 9.w,
                                            color: const Color(0xFF34C759),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            _formatLastPaymentDate(daysSinceLastPayment, l10n),
                                            style: GoogleFonts.inter(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF34C759),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (isUrgent || isOverdue) ...[
                                    SizedBox(width: 4.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: isOverdue 
                                            ? const Color(0xFFFF3B30).withOpacity(0.15)
                                            : const Color(0xFFFF9500).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isOverdue ? Icons.warning_rounded : Icons.access_time_rounded,
                                            size: 9.w,
                                            color: isOverdue ? const Color(0xFFFF3B30) : const Color(0xFFFF9500),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            isOverdue ? l10n.overdue : (daysUntilNext == 0 ? l10n.today : daysUntilNext == 1 ? l10n.tomorrow : '${daysUntilNext} ${l10n.days}'),
                                            style: GoogleFonts.inter(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600,
                                              color: isOverdue ? const Color(0xFFFF3B30) : const Color(0xFFFF9500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6.h),

                    // Next payment date and amount info (same row)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 11.w,
                                    color: isUrgent || isOverdue
                                        ? (isOverdue ? const Color(0xFFFF3B30) : const Color(0xFFFF9500))
                                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      _formatNextPaymentDate(nextPaymentDate, daysUntilNext, l10n),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: isUrgent || isOverdue
                                            ? (isOverdue ? const Color(0xFFFF3B30) : const Color(0xFFFF9500))
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Provider.of<ThemeProvider>(context, listen: false)
                              .formatAmount(subscription.amount),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNextPaymentDate(DateTime date, int daysUntil, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paymentDay = DateTime(date.year, date.month, date.day);

    if (daysUntil == 0) {
      return l10n.today;
    } else if (daysUntil == 1) {
      return l10n.tomorrow;
    } else if (daysUntil < 0) {
      return l10n.overdue;
    } else if (daysUntil <= 7) {
      return '${daysUntil} ${l10n.days}';
    } else {
      final formatter = DateFormat('dd MMM', Localizations.localeOf(context).toString());
      return formatter.format(date);
    }
  }

  String _formatLastPaymentDate(int daysAgo, AppLocalizations l10n) {
    if (daysAgo == 0) {
      return l10n.today;
    } else if (daysAgo == 1) {
      return l10n.yesterday;
    } else if (daysAgo < 7) {
      return l10n.daysAgo(daysAgo);
    } else if (daysAgo < 30) {
      final weeks = (daysAgo / 7).floor();
      return l10n.weeksAgo(weeks);
    } else if (daysAgo < 365) {
      final months = (daysAgo / 30).floor();
      return l10n.monthsAgo(months);
    } else {
      final years = (daysAgo / 365).floor();
      return l10n.yearsAgo(years);
    }
  }

  Color _getCategoryColor(RecurringCategory category) {
    switch (category) {
      case RecurringCategory.subscription:
        return const Color(0xFF007AFF);
      case RecurringCategory.utilities:
        return const Color(0xFF34C759);
      case RecurringCategory.insurance:
        return const Color(0xFFFF9500);
      case RecurringCategory.rent:
        return const Color(0xFFFF3B30);
      case RecurringCategory.loan:
        return const Color(0xFFAF52DE);
      case RecurringCategory.other:
        return const Color(0xFF8E8E93);
    }
  }

  void _showSubscriptionsManagement(BuildContext context) {
    context.push('/subscriptions-management');
  }
}

