import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/stock_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/theme/theme_provider.dart';
import 'mini_chart_widget.dart';

/// Compact hisse kartı - Arkapansız, basit tasarım
class CompactStockCard extends StatelessWidget {
  final Stock stock;
  final StockPosition? position;
  final VoidCallback? onTap;

  const CompactStockCard({
    super.key,
    required this.stock,
    this.position,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = themeProvider.currency;
    final isProfit = position != null && position!.profitLoss > 0;
    final isLoss = position != null && position!.profitLoss < 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renk çubuğu - 2 satırı kapsayan
            Container(
              width: 3,
              height: 48, // 2 satırı kapsayacak yükseklik
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isProfit
                    ? Colors.green
                    : isLoss
                    ? Colors.red
                    : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Sol: Hisse bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hisse kodu ve mini chart
                  Row(
                    children: [
                      // Sembol
                      Text(
                        _cleanStockName(stock.symbol),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini chart
                      Builder(
                        builder: (context) {
                          final positionData = position?.historicalData;
                          final stockData = stock.historicalData;
                          final hasData = positionData != null || stockData != null;

                          if (hasData) {
                            final chartData = positionData ?? stockData!;
                            final isPositive = chartData.isNotEmpty &&
                                chartData.length > 1 &&
                                chartData.last >= chartData.first;

                            return MiniChartWidget(
                              data: chartData,
                              width: 60,
                              height: 8,
                              isPositive: isPositive,
                              isDark: isDark,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Şirket adı
                  if (stock.name.isNotEmpty && stock.name != stock.symbol)
                    Text(
                      _cleanStockName(stock.name),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // Adet ve ortalama fiyat
                  if (position != null)
                    Builder(
                      builder: (context) {
                        final quantity = position!.totalQuantity.toStringAsFixed(0);
                        final quantityNum = position!.totalQuantity;
                        final unit = quantityNum == 1 ? l10n.pieces : l10n.piecesPlural;
                        
                        return Text(
                          '$quantity $unit • ${l10n.avg}: ${CurrencyUtils.formatAmount(position!.averagePrice, currency)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Sağ: Fiyat ve kar/zarar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Güncel fiyat
                Text(
                  stock.currentPrice > 0.0 ? stock.displayPrice : '₺0,00',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                // Kar/Zarar
                if (position != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyUtils.formatAmount(position!.profitLoss.abs(), currency),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isProfit
                              ? Colors.green
                              : isLoss
                              ? Colors.red
                              : isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isProfit
                              ? Colors.green.withOpacity(0.1)
                              : isLoss
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${position!.profitLossPercent > 0 ? '+' : ''}${position!.profitLossPercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isProfit
                                ? Colors.green
                                : isLoss
                                ? Colors.red
                                : isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _cleanStockName(String name) {
    return name
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .trim();
  }
}

