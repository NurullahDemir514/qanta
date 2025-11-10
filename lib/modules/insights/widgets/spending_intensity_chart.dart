import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../l10n/app_localizations.dart';

/// Spending Intensity Chart
/// Shows spending intensity heatmap by time of day and day of week
class SpendingIntensityChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SpendingIntensityChart({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UnifiedProviderV2>(
      builder: (context, dataProvider, child) {
        // Get expense transactions in date range
        final transactions = dataProvider.transactions.where((t) {
          return t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 t.transactionDate.isBefore(endDate.add(const Duration(days: 1))) &&
                 t.type == TransactionType.expense &&
                 t.type != TransactionType.transfer &&
                 !t.isStockTransaction;
        }).toList();

        if (transactions.isEmpty) {
          return _buildEmptyState(context, isDark, l10n);
        }

        // Calculate spending intensity
        final intensityData = _calculateIntensityData(transactions, startDate, endDate);
        final maxIntensity = intensityData.values.reduce((a, b) => a > b ? a : b);

        return Container(
          margin: EdgeInsets.only(bottom: 20.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                l10n.spendingIntensity ?? 'Harcama Yoğunluğu',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Legend
              Row(
                children: [
                  _buildLegendItem(context, isDark, l10n.low ?? 'Düşük', 
                      _getIntensityColor(0.0, maxIntensity), 0.0),
                  SizedBox(width: 12.w),
                  _buildLegendItem(context, isDark, l10n.medium ?? 'Orta', 
                      _getIntensityColor(0.5, maxIntensity), 0.5),
                  SizedBox(width: 12.w),
                  _buildLegendItem(context, isDark, l10n.high ?? 'Yüksek', 
                      _getIntensityColor(1.0, maxIntensity), 1.0),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Heatmap
              _buildHeatmap(context, isDark, intensityData, maxIntensity),
            ],
          ),
        );
      },
    );
  }

  Map<String, double> _calculateIntensityData(
    List<TransactionWithDetailsV2> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final Map<String, double> intensityMap = {};
    
    // Time slots: 00-06, 06-12, 12-18, 18-24
    final timeSlots = ['00-06', '06-12', '12-18', '18-24'];
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    // Initialize all cells with 0
    for (final timeSlot in timeSlots) {
      for (final day in days) {
        intensityMap['$timeSlot-$day'] = 0.0;
      }
    }
    
    // Calculate spending per time slot and day
    for (final transaction in transactions) {
      final hour = transaction.transactionDate.hour;
      // weekday: 1=Monday, 7=Sunday
      // days array: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
      // So: Monday (1) -> Pzt (0), Tuesday (2) -> Sal (1), ..., Sunday (7) -> Paz (6)
      final dayIndex = (transaction.transactionDate.weekday - 1) % 7;
      final dayLabel = days[dayIndex];
      
      String timeSlot;
      if (hour >= 0 && hour < 6) {
        timeSlot = '00-06';
      } else if (hour >= 6 && hour < 12) {
        timeSlot = '06-12';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = '12-18';
      } else {
        timeSlot = '18-24';
      }
      
      final key = '$timeSlot-$dayLabel';
      intensityMap[key] = (intensityMap[key] ?? 0.0) + transaction.amount;
    }
    
    return intensityMap;
  }

  Color _getIntensityColor(double intensity, double maxIntensity) {
    // Normalize intensity to 0-1
    final normalized = maxIntensity > 0 ? (intensity / maxIntensity) : 0.0;
    
    // Color gradient: light blue (low) -> medium blue -> dark blue (high)
    if (normalized < 0.33) {
      // Low intensity - light blue
      return const Color(0xFF81D4FA);
    } else if (normalized < 0.66) {
      // Medium intensity - medium blue
      return const Color(0xFF42A5F5);
    } else {
      // High intensity - dark blue
      return const Color(0xFF1976D2);
    }
  }

  Widget _buildHeatmap(
    BuildContext context,
    bool isDark,
    Map<String, double> intensityData,
    double maxIntensity,
  ) {
    final timeSlots = ['00-06', '06-12', '12-18', '18-24'];
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return Column(
      children: [
        // Y-axis labels (time slots) and heatmap cells
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-axis labels
            SizedBox(
              width: 50.w,
              child: Column(
                children: timeSlots.reversed.map((timeSlot) {
                  return SizedBox(
                    height: 40.h,
                    child: Center(
                      child: Text(
                        timeSlot,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: 8.w),
            // Heatmap grid
            Expanded(
              child: Column(
                children: [
                  // X-axis labels (days)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: days.map((day) {
                      return SizedBox(
                        width: 32.w,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 4.h),
                  // Heatmap cells
                  ...timeSlots.reversed.map((timeSlot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: days.map((day) {
                        final key = '$timeSlot-$day';
                        final intensity = intensityData[key] ?? 0.0;
                        final normalized = maxIntensity > 0 
                            ? (intensity / maxIntensity) 
                            : 0.0;
                        final color = _getIntensityColor(intensity, maxIntensity);
                        
                        return Container(
                          width: 32.w,
                          height: 32.h,
                          margin: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.7 + (normalized * 0.3)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    bool isDark,
    String label,
    Color color,
    double intensity,
  ) {
    return Row(
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7 + (intensity * 0.3)),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.spendingIntensity ?? 'Harcama Yoğunluğu',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noDataAvailable ?? 'Veri yok',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

