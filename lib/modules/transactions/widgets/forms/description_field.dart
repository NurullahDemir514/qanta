import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final String? hintText;

  const DescriptionField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.description,
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
            onChanged: onChanged,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              labelText: hintText ?? l10n.description,
              hintText: hintText,
              labelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                letterSpacing: -0.2,
              ),
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                letterSpacing: -0.2,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
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