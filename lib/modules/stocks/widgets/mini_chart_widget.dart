import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Mini grafik widget'ı - hisse senedi kartlarında kullanılır
class MiniChartWidget extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final bool isPositive;
  final bool isDark;

  const MiniChartWidget({
    super.key,
    required this.data,
    this.width = 60,
    this.height = 20,
    this.isPositive = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    
    if (data.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'N/A',
            style: TextStyle(
              fontSize: 8,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _MiniChartPainter(
        data: data,
        isPositive: isPositive,
        isDark: isDark,
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final bool isPositive;
  final bool isDark;

  _MiniChartPainter({
    required this.data,
    required this.isPositive,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    
    if (data.isEmpty) {
      return;
    }
    
    if (data.length < 2) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0  // Daha kalın çizgi
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Renk belirleme - tema renklerini kullan
    if (isPositive) {
      paint.color = const Color(0xFF4CAF50); // AppColors.success
    } else {
      paint.color = const Color(0xFFFF4C4C); // AppColors.error
    }

    // Veri normalizasyonu
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    
    
    if (range == 0) {
      // Sabit fiyat durumu - yatay çizgi
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    // Path oluşturma
    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minValue) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    
    // Çizgiyi çiz
    canvas.drawPath(path, paint);

    // Alan doldurma (gradient efekti için)
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF4C4C)).withOpacity(0.3),  // Tema renkleri
          (isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF4C4C)).withOpacity(0.0),
        ],
      );

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _MiniChartPainter &&
        (oldDelegate.data != data ||
            oldDelegate.isPositive != isPositive ||
            oldDelegate.isDark != isDark);
  }
}
