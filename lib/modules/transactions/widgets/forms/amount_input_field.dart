import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final bool autofocus;

  const AmountInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.amount,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: '0,00',
              hintStyle: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                letterSpacing: -0.2,
              ),
              prefixIcon: Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  Provider.of<ThemeProvider>(context, listen: false).currency.symbol,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
} 