import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/savings_goal.dart';

class SavingsGoalsSection extends StatelessWidget {
  const SavingsGoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Consumer<UnifiedProviderV2>(
      builder: (context, unifiedProvider, child) {
        // Sadece aktif ve tamamlanmamış hedefleri al
        final activeGoals = unifiedProvider.activeSavingsGoals;

        // Boş durum - abonelikler gibi empty state card göster
        if (activeGoals.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header with manage button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.savingsGoals,
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/cards?tab=3'),
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
              _buildEmptyStateWithAddButton(context, isDark, l10n),
            ],
          );
        }

        // İlk 5 hedefi göster
        final displayGoals = activeGoals.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.savingsGoals,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/cards?tab=3'), // Savings tab
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

            // Goals List - Horizontal scrollable cards (subscriptions gibi)
            SizedBox(
              height: 95.h, // Yükseklik artırıldı (90 -> 95) overflow için
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: displayGoals.length,
                itemBuilder: (context, index) => _buildGoalCard(
                    context,
                    displayGoals[index],
                    isDark,
                  index,
                  displayGoals.length,
                    themeProvider,
                    l10n,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Empty state widget - Abonelikler section gibi
  Widget _buildEmptyStateWithAddButton(BuildContext context, bool isDark, AppLocalizations l10n) {
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
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: Colors.green.shade500, // Material green
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
                  l10n.noSavingsGoals,
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
              color: Colors.green.shade500, // Material green
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade500.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go('/cards?tab=3'),
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

  /// Build goal card - Modern ve temiz tasarım
  Widget _buildGoalCard(
    BuildContext context,
    SavingsGoal goal,
    bool isDark,
    int index,
    int totalCount,
    ThemeProvider themeProvider,
    AppLocalizations l10n,
  ) {
    final progress = goal.progress;
    final cardColor = _getColorFromHex(goal.color);
    final progressPercent = (progress * 100).clamp(0, 100);
    final remainingAmount = goal.remainingAmount;

    return Container(
      width: 180.w,
      height: 110.h,
      margin: EdgeInsets.only(right: index == (totalCount - 1) ? 0 : 12.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/cards/savings/${goal.id}'),
          borderRadius: BorderRadius.circular(16.r),
          child: Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 1.w,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), // Vertical padding azaltıldı
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Üst: Name + Progress percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Expanded(
                          child: Text(
                            goal.name,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp, // Küçültüldü (14 -> 13)
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // Progress percentage
                        Text(
                          '${progressPercent.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp, // Küçültüldü (13 -> 12)
                            fontWeight: FontWeight.w700,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h), // Azaltıldı (10 -> 8)

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5.h, // Küçültüldü (6 -> 5)
                        backgroundColor: isDark 
                            ? const Color(0xFF2C2C2E) 
                            : const Color(0xFFF2F2F7),
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                    ),

                    SizedBox(height: 8.h), // Azaltıldı (10 -> 8)

                    // Alt: Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                themeProvider.formatAmountWithLetterFormat(goal.currentAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp, // Küçültüldü (16 -> 15)
                                  fontWeight: FontWeight.w700,
                                  color: cardColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 1.h), // Azaltıldı (2 -> 1)
                              Text(
                                remainingAmount > 0
                                    ? '${l10n.remaining}: ${themeProvider.formatAmountWithLetterFormat(remainingAmount)}'
                                    : l10n.completed,
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp, // Küçültüldü (10 -> 9)
                                  fontWeight: FontWeight.w500,
                                  color: remainingAmount > 0
                                      ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                      : Colors.green.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // Target amount (sağda, küçük)
                        Text(
                          themeProvider.formatAmountWithLetterFormat(goal.targetAmount),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp, // Küçültüldü (11 -> 10)
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.green.shade500; // Default Material green
    }
  }
}
