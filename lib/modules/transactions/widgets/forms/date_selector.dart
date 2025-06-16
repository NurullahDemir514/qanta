import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String? errorText;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use locale-aware date formatting
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final dateFormat = DateFormat(
      isEnglish ? 'MMM dd, yyyy' : 'dd MMMM yyyy', 
      isEnglish ? 'en_US' : 'tr_TR'
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.date,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                  ? const Color(0xFFFF3B30)
                  : (isDark 
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE8E8E8)),
                width: errorText != null ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateFormat.format(selectedDate),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFFF3B30),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }

  void _showDatePicker(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF10B981),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }
} 