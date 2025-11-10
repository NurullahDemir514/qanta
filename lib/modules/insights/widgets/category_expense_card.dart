import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/services/category_icon_service.dart';
import '../models/statistics_model.dart';

/// Kategori Bazlı Harcama Kartı - Kompakt ve şık tasarım
class CategoryExpenseCard extends StatelessWidget {
  final CategoryStatistic category;
  final double totalExpenses;

  const CategoryExpenseCard({
    super.key,
    required this.category,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = themeProvider.currency;

    // Kategori ikonu ve rengi
    final categoryIcon = CategoryIconService.getIcon(category.categoryIcon);
    final categoryColor = CategoryIconService.getCategoryColor(
      iconName: category.categoryIcon,
      colorHex: '',
      isIncomeCategory: false,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF38383A) 
              : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Kategori detay sayfasına yönlendirme (gelecekte eklenebilir)
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // İkon container (daha küçük)
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                // Kategori adı ve bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.categoryName,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${category.transactionCount} işlem • ${category.percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tutar
                Text(
                  CurrencyUtils.formatAmount(category.amount, currency),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

