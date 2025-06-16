import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model_v2.dart';

class TransactionFilterChips extends StatelessWidget {
  final TransactionType? selectedFilter;
  final Function(TransactionType?) onFilterChanged;

  const TransactionFilterChips({
    super.key,
    this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            label: 'Tümü',
            isSelected: selectedFilter == null,
            onTap: () {
              HapticFeedback.selectionClick();
              onFilterChanged(null);
            },
          ),
          const SizedBox(width: 8),
          ...TransactionType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(
              context: context,
              label: type.displayName,
              isSelected: selectedFilter == type,
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterChanged(type);
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
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
            ? const Color(0xFF8E8E93)
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