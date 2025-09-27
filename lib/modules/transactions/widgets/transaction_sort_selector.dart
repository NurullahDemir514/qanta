import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

enum SortType {
  dateNewest,
  dateOldest,
  amountHighest,
  amountLowest,
  alphabetical;

  String getName(AppLocalizations l10n) {
    switch (this) {
      case SortType.dateNewest:
        return l10n.newest;
      case SortType.dateOldest:
        return l10n.oldest;
      case SortType.amountHighest:
        return l10n.highestToLowest;
      case SortType.amountLowest:
        return l10n.lowestToHighest;
      case SortType.alphabetical:
        return l10n.alphabetical;
    }
  }


}

class TransactionSortSelector extends StatelessWidget {
  final SortType selectedSort;
  final Function(SortType) onSortChanged;

  const TransactionSortSelector({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: SortType.values.map((sort) => Padding(
          padding: EdgeInsets.only(right: sort == SortType.values.last ? 0 : 8),
          child: _buildSortChip(
            context: context,
            sort: sort,
            label: sort.getName(l10n),
            isSelected: selectedSort == sort,
            onTap: () {
              HapticFeedback.selectionClick();
              onSortChanged(sort);
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSortChip({
    required BuildContext context,
    required SortType sort,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFF8E8E93) // Gray for sort
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