import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/ai_insight_model.dart';

/// AI Overview Card - Stocks sayfasındaki Portfolio Overview Table gibi
class AIOverviewCard extends StatelessWidget {
  final AIInsightsSummary summary;

  const AIOverviewCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = themeProvider.currency;
    final isPositive = summary.netBalance >= 0;
    
    // Yeterli veri olmadığında özel empty state göster
    final isEmpty = summary.overview.contains('Yeterli veri bulunmuyor') ||
                    summary.overview.contains('Nicht genügend Daten') ||
                    summary.overview.contains('Insufficient Data');

    if (isEmpty) {
      return _buildEmptyStateCard(context, isDark);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - Minimal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade500.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Colors.green.shade500,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Finansal Özet',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Hero Value - Net Bakiye
          Column(
            children: [
              Text(
                CurrencyUtils.formatAmount(summary.netBalance, currency),
                style: GoogleFonts.inter(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                'Net Bakiye',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Divider
          Container(
            height: 1,
            color: isDark 
                ? const Color(0xFF38383A) 
                : const Color(0xFFE5E5EA),
          ),
          
          SizedBox(height: 16.h),
          
          // Metrikler - 3'lü kompakt satır
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Gelir
              Expanded(
                child: _buildMetricItem(
                  label: 'Gelir',
                  value: CurrencyUtils.formatAmount(summary.totalIncome, currency),
                  valueColor: const Color(0xFF4CAF50),
                  isDark: isDark,
                ),
              ),
              
              // 2. Gider
              Expanded(
                child: _buildMetricItem(
                  label: 'Gider',
                  value: CurrencyUtils.formatAmount(summary.totalExpenses, currency),
                  valueColor: const Color(0xFFFF4C4C),
                  isDark: isDark,
                ),
              ),
              
              // 3. Tasarruf Oranı
              Expanded(
                child: _buildMetricItem(
                  label: 'Tasarruf',
                  value: '${summary.savingsRate.toStringAsFixed(1)}%',
                  valueColor: isPositive
                      ? Colors.green.shade500
                      : const Color(0xFFFF4C4C),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }
  
  /// Empty state card - Şık tasarım
  Widget _buildEmptyStateCard(BuildContext context, bool isDark) {
    final locale = Localizations.localeOf(context);
    final isTurkish = locale.languageCode == 'tr';
    final isGerman = locale.languageCode == 'de';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Büyük icon
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 50.sp,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 24.h),
          // Başlık
          Text(
            isTurkish
                ? 'Yeterli Veri Bulunmuyor'
                : isGerman
                    ? 'Nicht genügend Daten'
                    : 'Insufficient Data',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          // Açıklama
          Text(
            isTurkish
                ? 'Daha fazla harcama işlemi kaydettikten sonra analiz yapılabilecektir.\n\nYeterli veriye sahip olunduğunda AI size kapsamlı ve doğru öneriler sunabilecektir.'
                : isGerman
                    ? 'Nach der Erfassung weiterer Ausgabentransaktionen kann eine Analyse durchgeführt werden.\n\nSobald ausreichend Daten vorhanden sind, kann KI Ihnen umfassende und genaue Empfehlungen geben.'
                    : 'Analysis will be available after recording more expense transactions.\n\nOnce sufficient data is available, AI can provide comprehensive and accurate recommendations.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              height: 1.6,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          // İpucu kartı
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    isTurkish
                        ? 'İşlemlerinizi kaydetmeye devam edin, analiz özelliği otomatik olarak aktif olacaktır.'
                        : isGerman
                            ? 'Erfassen Sie weiterhin Ihre Transaktionen, die Analysefunktion wird automatisch aktiviert.'
                            : 'Keep recording your transactions, the analysis feature will automatically activate.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Yardımcı metod: Minimal metrik item
  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

