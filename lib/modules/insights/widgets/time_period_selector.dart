import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/statistics_model.dart';

class TimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const TimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: TimePeriod.values.asMap().entries.map((entry) {
            final index = entry.key;
            final period = entry.value;
            final isSelected = period == selectedPeriod;
            
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 2,
                right: index == TimePeriod.values.length - 1 ? 0 : 2,
              ),
              child: _buildPeriodChip(context, period, isSelected, l10n),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    TimePeriod period,
    bool isSelected,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
            ? (isDark ? Colors.white : const Color(0xFF007AFF))
            : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isDark ? Colors.white : const Color(0xFF007AFF))
                      .withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                ? (isDark ? const Color(0xFF007AFF) : Colors.white)
                : (isDark 
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.8)
                    : const Color(0xFF000000).withValues(alpha: 0.7)),
              letterSpacing: -0.2,
            ),
            child: Text(
              _getPeriodLabel(period, l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period, AppLocalizations l10n) {
    switch (period) {
      case TimePeriod.thisMonth:
        return l10n.thisMonth;
      case TimePeriod.lastMonth:
        return l10n.lastMonth;
      case TimePeriod.last3Months:
        return l10n.last3Months;
      case TimePeriod.last6Months:
        return l10n.last6Months;
      case TimePeriod.yearToDate:
        return l10n.yearToDate;
    }
  }
} 