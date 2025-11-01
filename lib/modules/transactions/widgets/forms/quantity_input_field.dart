import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/thousands_separator_input_formatter.dart';

class QuantityInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool autofocus;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? label;
  final String? unit;
  final FocusNode? focusNode;

  const QuantityInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.unit,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final locale = themeProvider.currency.locale;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Container(
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF1C1C1E)
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                ? const Color(0xFFFF3B30)
                : (isDark 
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6)),
              width: errorText != null ? 1.5 : 0.33,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              ThousandsSeparatorInputFormatter(locale: locale),
            ],
            cursorColor: isDark ? Colors.white : Colors.black,
            cursorWidth: 2,
            cursorRadius: const Radius.circular(1),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                letterSpacing: -0.4,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
          ),
        ),
        
        if (errorText != null) ...[
          const SizedBox(height: 12),
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