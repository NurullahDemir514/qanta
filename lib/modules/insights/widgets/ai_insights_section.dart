import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/statistics_model.dart';
import 'category_expense_card.dart';

/// AI Insights Section - Kategori bazlı harcamalar ve grafikler
class AIInsightsSection extends StatelessWidget {
  final StatisticsData statistics;
  final TimePeriod period;

  const AIInsightsSection({
    super.key,
    required this.statistics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = statistics.categoryBreakdown;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Bazlı Harcamalar',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF2C2C2E) 
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${categories.length} kategori',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category Cards
        Column(
          children: categories.map((category) {
              return CategoryExpenseCard(
                category: category,
                totalExpenses: statistics.totalExpenses,
              );
            }).toList(),
        ),
        
        SizedBox(height: 20.h),
      ],
    );
  }
}

