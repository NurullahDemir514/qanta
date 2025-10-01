import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

/// Hisse miktar step'i
class StockQuantityStep extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;
  
  const StockQuantityStep({
    super.key,
    required this.controller,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Miktar girişi
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            suffixText: l10n.pieces,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF007AFF),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
