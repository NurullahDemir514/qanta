import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model_v2.dart';
import 'transaction_time_period_selector.dart';
import 'transaction_sort_selector.dart';

class TransactionCombinedFilters extends StatefulWidget {
  final TransactionType? selectedTransactionType;
  final TimePeriod selectedTimePeriod;
  final SortType selectedSortType;
  final Function(TransactionType?) onTransactionTypeChanged;
  final Function(TimePeriod) onTimePeriodChanged;
  final Function(SortType) onSortTypeChanged;

  const TransactionCombinedFilters({
    super.key,
    this.selectedTransactionType,
    required this.selectedTimePeriod,
    required this.selectedSortType,
    required this.onTransactionTypeChanged,
    required this.onTimePeriodChanged,
    required this.onSortTypeChanged,
  });

  @override
  State<TransactionCombinedFilters> createState() => _TransactionCombinedFiltersState();
}

class _TransactionCombinedFiltersState extends State<TransactionCombinedFilters> {
  bool _showAdvancedFilters = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Filter Row - Transaction Type + More Button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Transaction Type Chips
              _buildTransactionTypeChip(
                context: context,
                label: AppLocalizations.of(context)?.all ?? 'All',
                isSelected: widget.selectedTransactionType == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTransactionTypeChanged(null);
                },
              ),
              const SizedBox(width: 8),
              ...TransactionType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildTransactionTypeChip(
                  context: context,
                  label: type.displayName,
                  isSelected: widget.selectedTransactionType == type,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTransactionTypeChanged(type);
                  },
                ),
              )),
              
              // More Filters Button
              _buildMoreFiltersButton(context),
            ],
          ),
        ),
        
        // Advanced Filters (Collapsible) - Time Period + Sort
        if (_showAdvancedFilters) ...[
          const SizedBox(height: 12),
          
          // Time Period Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: TimePeriod.values.map((period) => Padding(
                padding: EdgeInsets.only(right: period == TimePeriod.values.last ? 0 : 8),
                child: _buildTimePeriodChip(
                  context: context,
                  period: period,
                  label: period.getName(l10n),
                  isSelected: widget.selectedTimePeriod == period,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTimePeriodChanged(period);
                  },
                ),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sort Filters
          TransactionSortSelector(
            selectedSort: widget.selectedSortType,
            onSortChanged: widget.onSortTypeChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionTypeChip({
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

  Widget _buildTimePeriodChip({
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
            ? const Color(0xFF8E8E93) // Gray color
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

  Widget _buildMoreFiltersButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showAdvancedFilters
            ? const Color(0xFF8E8E93)
            : (isDark 
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(20),
          border: _showAdvancedFilters
            ? null
            : Border.all(
                color: isDark 
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showAdvancedFilters ? (AppLocalizations.of(context)?.less ?? 'Less') : (AppLocalizations.of(context)?.more ?? 'More'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _showAdvancedFilters
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _showAdvancedFilters ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: _showAdvancedFilters
                  ? Colors.white
                  : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
