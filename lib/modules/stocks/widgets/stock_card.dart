import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../screens/stock_transaction_form_screen.dart';
import '../providers/stock_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Hisse kartı widget'ı
class StockCard extends StatelessWidget {
  final Stock stock;
  final StockPosition? position;
  final VoidCallback? onTap;
  
  const StockCard({
    super.key,
    required this.stock,
    this.position,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        const Color(0xFF1C1C1E),
                        const Color(0xFF2C2C2E),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFFAFAFA),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Hisse adı, sembol ve kaldırma butonu
                  Row(
                    children: [
                      // Hisse bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cleanStockName(stock.symbol),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stock.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Kaldırma butonu
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showRemoveConfirmation(context, l10n),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isDark ? Colors.red[300] : Colors.red[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
              
                  // Anlık fiyat ve değişim - TradingView tarzı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Anlık fiyat - her zaman göster
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                        child: Text(
                          stock.currentPrice > 0.0 ? stock.displayPrice : '₺0,00',
                        ),
                      ),
                      
                      // Yüzdelik değişim - her zaman göster
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: stock.isPositive 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: stock.isPositive 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: stock.isPositive ? Colors.green : Colors.red,
                          ),
                          child: Text(
                            stock.currentPrice > 0.0 ? stock.displayChangePercent : '+0,00%',
                          ),
                        ),
                      ),
                    ],
                  ),
              
                  // Portföy bilgileri (eğer varsa) - kompakt
                  if (position != null && position!.totalQuantity > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 16,
                            color: const Color(0xFF007AFF),
                          ),
                          const SizedBox(width: 8),
                          Consumer<StockProvider>(
                            builder: (context, stockProvider, child) {
                              final totalPortfolioValue = stockProvider.totalPortfolioValue;
                              final portfolioPercentage = totalPortfolioValue > 0
                                  ? (position!.currentValue / totalPortfolioValue) * 100
                                  : 0.0;
                              
                              return Text(
                                '${position!.totalQuantity.toStringAsFixed(0)} adet (${portfolioPercentage.toStringAsFixed(1)}%)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Text(
                            '${stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(position!.totalQuantity * stock.currentPrice, isUSD: stock.currency == 'USD')}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${position!.profitLossPercent >= 0 ? '+' : ''}${_formatNumber(position!.profitLossPercent, isUSD: stock.currency == 'USD')}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: position!.profitLossPercent > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              
                  // Faydalı bilgiler - 3'lü grid: gün yüksek, gün düşük, hacim
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Gün Yüksek
                      Expanded(
                        child: _buildInfoRow(
                          icon: Icons.trending_up,
                          label: l10n.dayHigh,
                          value: stock.dayHigh != null 
                              ? '${stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(stock.dayHigh!, isUSD: stock.currency == 'USD')}'
                              : 'N/A',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gün Düşük
                      Expanded(
                        child: _buildInfoRow(
                          icon: Icons.trending_down,
                          label: l10n.dayLow,
                          value: stock.dayLow != null 
                              ? '${stock.currency == 'USD' ? '\$' : '₺'}${_formatNumber(stock.dayLow!, isUSD: stock.currency == 'USD')}'
                              : 'N/A',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hacim
                      Expanded(
                        child: _buildInfoRow(
                          icon: Icons.bar_chart,
                          label: l10n.volume,
                          value: stock.volume != null 
                              ? _formatVolume(stock.volume!)
                              : 'N/A',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Alım-Satım butonları
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: l10n.buy,
                          icon: Icons.trending_up,
                          color: Colors.green,
                          onTap: () => _navigateToTransaction(context, StockTransactionType.buy),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: l10n.sell,
                          icon: Icons.trending_down,
                          color: Colors.red,
                          onTap: () => _navigateToTransaction(context, StockTransactionType.sell),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionDetail(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isDark ? Colors.white60 : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? Colors.white60 : Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTransaction(BuildContext context, StockTransactionType type) {
    if (!context.mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockTransactionFormScreen(
          stock: stock,
          transactionType: type,
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, AppLocalizations l10n) {
    if (!context.mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.removeStock,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: Text(
            l10n.confirmRemoveStock,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[700],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeStock(context, l10n);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.remove,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeStock(BuildContext context, AppLocalizations l10n) {
    if (!context.mounted) return;
    
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final userId = FirebaseAuthService.currentUserId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.userSessionNotFound,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Optimistic UI update - anında kaldır
    stockProvider.removeWatchedStockOptimistically(stock.symbol);
    
    // Backend'den kaldır
    stockProvider.removeWatchedStock(userId, stock.symbol).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.stockRemovedFromPortfolio(_cleanStockName(stock.symbol)),
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }).catchError((error) {
      // Hata durumunda UI'yi geri yükle
      stockProvider.addWatchedStockOptimistically(stock);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorRemovingStock,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  
  // Currency'ye göre sayı formatlaması
  String _formatNumber(double number, {required bool isUSD}) {
    final currency = isUSD ? Currency.USD : Currency.TRY;
    return CurrencyUtils.formatAmountWithoutSymbol(number, currency);
  }
  
  // Hacim formatlaması (M, K, B)
  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }
  
  // Hisse adı ve sembol temizleme
  String _cleanStockName(String name) {
    return name
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.NET$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.ORG$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.CO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TR$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.US$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.L$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.PA$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.DE$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.HK$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.T$', caseSensitive: false), '')
        .trim();
  }
}