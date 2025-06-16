import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: 'İşlem ara...',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
            letterSpacing: -0.2,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: Icon(
                  Icons.clear_rounded,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                  size: 18,
                ),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
} 