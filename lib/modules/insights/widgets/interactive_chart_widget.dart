import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/theme/theme_provider.dart';

class InteractiveChartWidget extends StatefulWidget {
  final List<ChartData> data;
  final String title;
  final String subtitle;
  final ChartType chartType;
  final Function(ChartData)? onDataPointTap;

  const InteractiveChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.subtitle = '',
    this.chartType = ChartType.line,
    this.onDataPointTap,
  });

  @override
  State<InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;
  bool _showTrendLine = false;
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildControlButtons(context),
          const SizedBox(height: 20),
          _buildChart(context),
          if (_selectedIndex != null) ...[
            const SizedBox(height: 16),
            _buildDataPointDetails(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (widget.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Row(
      children: [
        _buildToggleButton(
          context,
          'Trend',
          _showTrendLine,
          Icons.trending_up,
          () => setState(() => _showTrendLine = !_showTrendLine),
        ),
        const SizedBox(width: 12),
        _buildToggleButton(
          context,
          'Karşılaştır',
          _showComparison,
          Icons.compare_arrows,
          () => setState(() => _showComparison = !_showComparison),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String label,
    bool isActive,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
            ? const Color(0xFF00FFB3).withValues(alpha: 0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
              ? const Color(0xFF00FFB3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                ? const Color(0xFF00FFB3)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive 
                  ? const Color(0xFF00FFB3)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 200,
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: ChartPainter(
              data: widget.data,
              chartType: widget.chartType,
              animationValue: _animation.value,
              selectedIndex: _selectedIndex,
              showTrendLine: _showTrendLine,
              showComparison: _showComparison,
              onDataPointTap: (index) {
                setState(() {
                  _selectedIndex = _selectedIndex == index ? null : index;
                });
                if (widget.onDataPointTap != null && index < widget.data.length) {
                  widget.onDataPointTap!(widget.data[index]);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataPointDetails(BuildContext context) {
    final data = widget.data[_selectedIndex!];
    final previousData = _selectedIndex! > 0 ? widget.data[_selectedIndex! - 1] : null;
    final change = previousData != null ? data.value - previousData.value : 0;
    final changePercent = previousData != null && previousData.value != 0 
      ? (change / previousData.value * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFB3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FFB3).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(data.value)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00FFB3),
                ),
              ),
            ],
          ),
          if (previousData != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  change >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: change >= 0 ? const Color(0xFF00FFB3) : const Color(0xFFFF6B6B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${Provider.of<ThemeProvider>(context, listen: false).formatAmount(change)} (%${changePercent.toStringAsFixed(1)})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: change >= 0 ? const Color(0xFF00FFB3) : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<ChartData> data;
  final ChartType chartType;
  final double animationValue;
  final int? selectedIndex;
  final bool showTrendLine;
  final bool showComparison;
  final Function(int)? onDataPointTap;

  ChartPainter({
    required this.data,
    required this.chartType,
    required this.animationValue,
    this.selectedIndex,
    this.showTrendLine = false,
    this.showComparison = false,
    this.onDataPointTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF00FFB3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF00FFB3).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Calculate bounds
    final maxValue = data.map((d) => d.value).reduce(math.max);
    final minValue = data.map((d) => d.value).reduce(math.min);
    final valueRange = maxValue - minValue;
    
    // Add padding to prevent clipping
    final paddedMax = maxValue + (valueRange * 0.1);
    final paddedMin = minValue - (valueRange * 0.1);
    final paddedRange = paddedMax - paddedMin;

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].value - paddedMin) / paddedRange) * size.height;
      points.add(Offset(x, y * animationValue + size.height * (1 - animationValue)));
    }

    // Draw chart based on type
    switch (chartType) {
      case ChartType.line:
        _drawLineChart(canvas, size, points, paint, fillPaint);
        break;
      case ChartType.bar:
        _drawBarChart(canvas, size, paint, fillPaint, paddedMin, paddedRange);
        break;
      case ChartType.area:
        _drawAreaChart(canvas, size, points, paint, fillPaint);
        break;
    }

    // Draw trend line if enabled
    if (showTrendLine && points.length > 1) {
      _drawTrendLine(canvas, size, points, paint);
    }

    // Draw comparison data if enabled
    if (showComparison) {
      _drawComparisonData(canvas, size, paint, paddedMin, paddedRange);
    }

    // Draw data points and selection
    _drawDataPoints(canvas, points, paint);
  }

  void _drawLineChart(Canvas canvas, Size size, List<Offset> points, Paint paint, Paint fillPaint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curves
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) * 0.5,
        points[i - 1].dy,
      );
      final cp2 = Offset(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) * 0.5,
        points[i].dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawBarChart(Canvas canvas, Size size, Paint paint, Paint fillPaint, double paddedMin, double paddedRange) {
    final barWidth = size.width / data.length * 0.6;
    final spacing = size.width / data.length * 0.4;

    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / data.length) + spacing / 2;
      final height = ((data[i].value - paddedMin) / paddedRange) * size.height * animationValue;
      final y = size.height - height;

      final rect = Rect.fromLTWH(x, y, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawAreaChart(Canvas canvas, Size size, List<Offset> points, Paint paint, Paint fillPaint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.lineTo(points.last.dx, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    
    // Draw line on top
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);
  }

  void _drawTrendLine(Canvas canvas, Size size, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    // Calculate linear regression
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (int i = 0; i < points.length; i++) {
      sumX += i;
      sumY += points[i].dy;
      sumXY += i * points[i].dy;
      sumXX += i * i;
    }

    final n = points.length;
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final startY = intercept;
    final endY = slope * (n - 1) + intercept;

    final trendPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashed trend line
    final path = Path();
    path.moveTo(0, startY);
    path.lineTo(size.width, endY);

    canvas.drawPath(path, trendPaint);
  }

  void _drawComparisonData(Canvas canvas, Size size, Paint paint, double paddedMin, double paddedRange) {
    // Draw previous period data as ghost bars/line
    final comparisonPaint = Paint()
      ..color = const Color(0xFF8E8E93).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // This would be implemented with actual comparison data
    // For now, showing placeholder implementation
  }

  void _drawDataPoints(Canvas canvas, List<Offset> points, Paint paint) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = selectedIndex == i;
      
      // Draw point
      final pointPaint = Paint()
        ..color = isSelected ? const Color(0xFF00FFB3) : Colors.white
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = const Color(0xFF00FFB3)
        ..strokeWidth = isSelected ? 3 : 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(point, isSelected ? 8 : 6, pointPaint);
      canvas.drawCircle(point, isSelected ? 8 : 6, borderPaint);

      // Draw selection ring
      if (isSelected) {
        final ringPaint = Paint()
          ..color = const Color(0xFF00FFB3).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(point, 12, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) => true;
}

class ChartData {
  final String label;
  final double value;
  final Color? color;
  final Map<String, dynamic>? metadata;

  ChartData({
    required this.label,
    required this.value,
    this.color,
    this.metadata,
  });
}

enum ChartType {
  line,
  bar,
  area,
} 