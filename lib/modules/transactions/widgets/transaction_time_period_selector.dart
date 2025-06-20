import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

enum TimePeriod {
  all,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months;

  String getName(AppLocalizations l10n) {
    switch (this) {
      case TimePeriod.all:
        return 'Tümü';
      case TimePeriod.today:
        return 'Bugün';
      case TimePeriod.thisWeek:
        return 'Bu Hafta';
      case TimePeriod.thisMonth:
        return 'Bu Ay';
      case TimePeriod.lastMonth:
        return 'Geçen Ay';
      case TimePeriod.last3Months:
        return 'Son 3 Ay';
    }
  }

  /// Get date range for filtering
  DateTimeRange? getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case TimePeriod.all:
        return null; // No filtering
      case TimePeriod.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
      case TimePeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1)),
        );
      case TimePeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
        return DateTimeRange(
          start: startOfMonth,
          end: endOfMonth,
        );
      case TimePeriod.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(microseconds: 1));
        return DateTimeRange(
          start: startOfLastMonth,
          end: endOfLastMonth,
        );
      case TimePeriod.last3Months:
        final startOf3MonthsAgo = DateTime(now.year, now.month - 2, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
        return DateTimeRange(
          start: startOf3MonthsAgo,
          end: endOfMonth,
        );
    }
  }
}

class TransactionTimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const TransactionTimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: TimePeriod.values.map((period) => Padding(
          padding: EdgeInsets.only(right: period == TimePeriod.values.last ? 0 : 8),
          child: _buildPeriodChip(
            context: context,
            period: period,
            label: period.getName(l10n),
            isSelected: selectedPeriod == period,
            onTap: () {
              HapticFeedback.selectionClick();
              onPeriodChanged(period);
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPeriodChip({
    required BuildContext context,
    required TimePeriod period,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFF10B981) // Mint green for selected
            : (isDark 
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
            ? null
            : Border.all(
                color: isDark 
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
              ? Colors.white
              : (isDark ? Colors.white : Colors.black),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
} 