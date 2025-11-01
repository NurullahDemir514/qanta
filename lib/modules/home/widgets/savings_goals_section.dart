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

        // Aktif hedef yoksa gösterme
        if (activeGoals.isEmpty) {
          return const SizedBox.shrink();
        }

        // İlk 5 hedefi göster
        final displayGoals = activeGoals.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.savingsGoals,
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/cards?tab=3'), // Savings tab
                    child: Text(
                      l10n.seeAll,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6D6D70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Goals List - Horizontal scrollable cards
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: displayGoals.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return _buildGoalItem(
                    context,
                    displayGoals[index],
                    isDark,
                    themeProvider,
                    l10n,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalItem(
    BuildContext context,
    SavingsGoal goal,
    bool isDark,
    ThemeProvider themeProvider,
    AppLocalizations l10n,
  ) {
    final progress = goal.progress;
    final cardColor = _getColorFromHex(goal.color);
    final progressPercent = (progress * 100).clamp(0, 100);
    final remainingAmount = goal.remainingAmount;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/cards/savings/${goal.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Name + Progress %
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${progressPercent.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cardColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ),
              const SizedBox(height: 8),
              // Amount info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                    '${themeProvider.formatAmount(goal.currentAmount)} / ${themeProvider.formatAmount(goal.targetAmount)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.5),
                      letterSpacing: -0.2,
                    ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (remainingAmount > 0) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Text(
                      '${themeProvider.formatAmount(remainingAmount)} ${l10n.remaining.toLowerCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ],
              ),
              ],
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
      return const Color(0xFF34D399); // Default mint green
    }
  }
}

