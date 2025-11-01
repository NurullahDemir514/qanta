import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../l10n/app_localizations.dart';

/// Compact vertical tasarruf hedefi kartı widget'ı (kredi kartları gibi)
class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onLongPress,
  });

  String _getTimeRemainingText(AppLocalizations l10n) {
    if (goal.daysRemaining == null || goal.daysRemaining! <= 0) return '';
    
    final days = goal.daysRemaining!;
    
    // Yıldan fazla
    if (days >= 365) {
      final years = days ~/ 365;
      final remainingDays = days % 365;
      final months = remainingDays ~/ 30;
      
      if (months > 0) {
        return '$years ${l10n.yearsUnit} $months ${l10n.monthsUnit} ${l10n.timeRemaining}';
      }
      return '$years ${l10n.yearsUnit} ${l10n.timeRemaining}';
    }
    
    // Aydan fazla
    if (days >= 30) {
      final months = days ~/ 30;
      final remainingDays = days % 30;
      
      if (remainingDays > 0) {
        return '$months ${l10n.monthsUnit} $remainingDays ${l10n.daysUnit} ${l10n.timeRemaining}';
      }
      return '$months ${l10n.monthsUnit} ${l10n.timeRemaining}';
    }
    
    // Günlük
    return '$days ${l10n.daysUnit} ${l10n.timeRemaining}';
  }
  
  double? _getRequiredSavingAmount() {
    if (goal.daysRemaining == null || goal.daysRemaining! <= 0) return null;
    
    final remainingAmount = goal.remainingAmount;
    if (remainingAmount <= 0) return null;
    
    // 30 günden az ise günlük, fazla ise aylık
    if (goal.daysRemaining! < 30) {
      return remainingAmount / goal.daysRemaining!;
    } else {
      return goal.monthlyRequiredSaving;
    }
  }
  
  String _getSavingPeriodText(AppLocalizations l10n) {
    if (goal.daysRemaining == null || goal.daysRemaining! <= 0) return '';
    
    if (goal.daysRemaining! < 30) {
      return l10n.perDay;
    } else {
      return l10n.perMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;

    final cardColor = _getColorFromHex(goal.color);
    final requiredSaving = _getRequiredSavingAmount();
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [
                    const Color(0xFF1C1C1E),
                    const Color(0xFF1C1C1E),
                  ]
                : [
                    Colors.white,
                    Colors.white.withOpacity(0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım: İsim + Yüzde badge
            Row(
              children: [
                // İsim ve kategori
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim - daha okunabilir
                      Text(
                        goal.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Kategori (varsa)
                      if (goal.category != null && goal.category!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.category!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                                ? Colors.white.withOpacity(0.6) 
                                : Colors.black.withOpacity(0.5),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Yüzde ve miktar badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${goal.completionPercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: cardColor,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeProvider.formatAmount(goal.currentAmount),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.6),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Progress bar - modern ve renkli
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.08)
                        : cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColor,
                          cardColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Hedef ve kalan bilgisi - kompakt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hedef
                Text(
                  themeProvider.formatAmount(goal.targetAmount),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.6),
                    letterSpacing: -0.2,
                  ),
                ),
                
                // Kalan
                Row(
                  children: [
                    Text(
                      '${themeProvider.formatAmount(goal.remainingAmount)} ${l10n.remaining}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark 
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.4),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Alt bilgiler - kompakt ve ikonlar ile
            if ((goal.daysRemaining != null && goal.daysRemaining! > 0) || requiredSaving != null) ...[
              const SizedBox(height: 8),
              Divider(
                color: isDark 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                height: 1,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Kalan süre (dinamik: yıl/ay/gün)
                  if (goal.daysRemaining != null && goal.daysRemaining! > 0) ...[
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: isDark 
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _getTimeRemainingText(l10n),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark 
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (requiredSaving != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 1,
                          height: 12,
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                  ],
                  
                  // Günlük/Aylık hedef (dinamik)
                  if (requiredSaving != null) ...[
                    Text(
                      '${themeProvider.formatAmount(requiredSaving)}${_getSavingPeriodText(l10n)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cardColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hex'ten renk çıkar
  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return const Color(0xFF007AFF);
    }
  }
}
