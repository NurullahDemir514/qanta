import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/ai_insight_model.dart';

/// Compact AI Insight Card - Stocks sayfasındaki CompactStockCard gibi
class AIInsightCard extends StatelessWidget {
  final AIInsight insight;
  final VoidCallback? onTap;

  const AIInsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = themeProvider.currency;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renk çubuğu
            Container(
              width: 3,
              height: 48,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: insight.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Sol: Insight bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve ikon
                  Row(
                    children: [
                      Icon(
                        insight.icon,
                        size: 16,
                        color: insight.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Açıklama
                  Text(
                    insight.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // İşlem sayısı (varsa)
                  if (insight.transactionCount != null && insight.transactionCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${insight.transactionCount} işlem',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Sağ: Tutar ve yüzde
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Tutar (varsa)
                if (insight.amount != null && insight.amount! > 0)
                  Text(
                    CurrencyUtils.formatAmount(insight.amount!, currency),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                const SizedBox(height: 2),
                // Yüzde (varsa)
                if (insight.percentage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: insight.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${insight.percentage! > 0 ? '+' : ''}${insight.percentage!.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: insight.color,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

