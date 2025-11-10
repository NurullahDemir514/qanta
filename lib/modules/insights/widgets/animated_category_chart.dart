import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animasyonlu kategori harcama grafiği
class AnimatedCategoryChart extends StatefulWidget {
  final List<double> monthlyData;
  final Color chartColor;
  final String categoryName;

  const AnimatedCategoryChart({
    super.key,
    required this.monthlyData,
    required this.chartColor,
    required this.categoryName,
  });

  @override
  State<AnimatedCategoryChart> createState() => _AnimatedCategoryChartState();
}

class _AnimatedCategoryChartState extends State<AnimatedCategoryChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.monthlyData.isEmpty || widget.monthlyData.length < 2) {
      return const SizedBox.shrink();
    }

    // Normalize data
    final maxValue = widget.monthlyData.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 100.h,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF2C2C2E) 
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            _buildChartData(isDark),
          ),
        );
      },
    );
  }

  LineChartData _buildChartData(bool isDark) {
    final spots = widget.monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      return FlSpot(index.toDouble(), value * _animation.value);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: widget.monthlyData.reduce((a, b) => a > b ? a : b) / 3,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark 
                ? const Color(0xFF38383A) 
                : const Color(0xFFE5E5EA),
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                'Ay ${value.toInt() + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: widget.chartColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: widget.chartColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      minY: 0,
      maxY: widget.monthlyData.reduce((a, b) => a > b ? a : b) * 1.1,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: isDark 
              ? const Color(0xFF1C1C1E) 
              : Colors.white,
          tooltipRoundedRadius: 8,
          tooltipPadding: EdgeInsets.all(8.w),
          tooltipMargin: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '${barSpot.y.toStringAsFixed(0)}₺',
                GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

