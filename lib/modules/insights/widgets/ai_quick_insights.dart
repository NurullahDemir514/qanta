import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// AI Quick Insights - Kısa öz bullet pointler, uzun metin yerine
class AIQuickInsights extends StatelessWidget {
  final String overview;
  
  const AIQuickInsights({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Markdown içeriğini parse et ve bullet pointleri çıkar
    final insights = _parseInsights(overview);
    
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade500.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.green.shade500,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Hızlı İçgörüler',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Insight chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: insights.take(3).map((insight) {
              return _buildInsightChip(
                insight: insight,
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Markdown içeriğinden bullet pointleri çıkar
  List<String> _parseInsights(String markdown) {
    final insights = <String>[];
    
    // Markdown listelerini bul (- ile başlayan satırlar)
    final lines = markdown.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Bullet point (- veya * ile başlayan)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final text = trimmed.substring(2).trim();
        // Markdown formatting'i temizle (**bold**, *italic*)
        final cleanText = text
            .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // **bold** -> bold
            .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // *italic* -> italic
            .trim();
        
        if (cleanText.isNotEmpty && cleanText.length < 80) {
          insights.add(cleanText);
        }
      }
    }
    
    // Eğer bullet point yoksa, cümleleri böl
    if (insights.isEmpty) {
      final sentences = markdown
          .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
          .split(RegExp(r'[.!?]\s+'))
          .where((s) => s.trim().isNotEmpty && s.trim().length < 80)
          .take(3)
          .toList();
      
      insights.addAll(sentences);
    }
    
    return insights;
  }

  Widget _buildInsightChip({
    required String insight,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2C2C2E) 
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF38383A) 
              : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              insight,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

