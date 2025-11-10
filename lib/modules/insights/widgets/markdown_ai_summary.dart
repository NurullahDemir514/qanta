import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Markdown formatında AI özeti gösterimi
class MarkdownAISummary extends StatelessWidget {
  final String markdownContent;

  const MarkdownAISummary({
    super.key,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1C1E) 
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MarkdownBody(
        data: markdownContent,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.5,
          ),
          h1: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
          h2: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.3,
          ),
          h3: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
          strong: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
          em: GoogleFonts.inter(
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          code: GoogleFonts.jetBrainsMono(
            fontSize: 13.sp,
            color: isDark ? Colors.green.shade500 : const Color(0xFF007AFF),
            backgroundColor: isDark 
                ? const Color(0xFF2C2C2E) 
                : Colors.white,
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF2C2C2E) 
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.white60 : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
          listBullet: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.green.shade500 : const Color(0xFF007AFF),
          ),
          a: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF007AFF),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}




