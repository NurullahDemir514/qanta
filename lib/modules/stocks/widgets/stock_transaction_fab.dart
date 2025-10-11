import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../screens/stock_transaction_form_screen.dart';
import 'stock_search_screen.dart';

class StockTransactionFab extends StatefulWidget {
  const StockTransactionFab({super.key});

  @override
  State<StockTransactionFab> createState() => _StockTransactionFabState();
}

class _StockTransactionFabState extends State<StockTransactionFab> {
  bool _isExpanded = false;
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onSearchSelected() {
    HapticFeedback.selectionClick();
    
    // Önce FAB'ı kapat
    setState(() {
      _isExpanded = false;
    });
    
    // Arama ekranını aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockSearchScreen(),
      ),
    );
  }

  void _onStockTransactionSelected(StockTransactionType type) {
    HapticFeedback.selectionClick();
    
    // Önce FAB'ı kapat
    setState(() {
      _isExpanded = false;
    });
    
    // Form'u aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockTransactionFormScreen(
          transactionType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive değerler
    final fabSize = FabPositioning.getFabSize(context);
    final iconSize = FabPositioning.getIconSize(context);
    final speedDialSpacing = FabPositioning.getSpeedDialSpacing(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed Dial Options
        if (_isExpanded) ...[
          // Arama Option
          _buildSearchOption(
            context: context,
            isDark: isDark,
            iconSize: iconSize,
          ),
          
          SizedBox(height: speedDialSpacing),
          
          // Satış Option
          _buildSpeedDialOption(
            context: context,
            transactionType: StockTransactionType.sell,
            isDark: isDark,
            iconSize: iconSize,
          ),
          
          SizedBox(height: speedDialSpacing),
          
          // Alış Option
          _buildSpeedDialOption(
            context: context,
            transactionType: StockTransactionType.buy,
            isDark: isDark,
            iconSize: iconSize,
          ),
          
          SizedBox(height: speedDialSpacing + 4),
        ],
        
        // Main FAB
        _buildMainFab(context, l10n, isDark, fabSize, iconSize),
      ],
    );
  }

  Widget _buildSearchOption({
    required BuildContext context,
    required bool isDark,
    required double iconSize,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232326).withOpacity(0.92) : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Text(
            l10n.searchStocks,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232326).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.search_rounded, color: isDark ? Colors.white : Colors.black, size: iconSize - 6),
                onPressed: _onSearchSelected,
                splashRadius: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialOption({
    required BuildContext context,
    required StockTransactionType transactionType,
    required bool isDark,
    required double iconSize,
  }) {
    final iconData = transactionType == StockTransactionType.buy
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final label = transactionType == StockTransactionType.buy
        ? l10n.buyStock
        : l10n.sellStock;
    
    // Renk kodlaması - Transaction FAB ile aynı
    Color color;
    switch (transactionType) {
      case StockTransactionType.buy:
        color = const Color(0xFF22C55E); // Yeşil - Transaction FAB ile aynı
        break;
      case StockTransactionType.sell:
        color = const Color(0xFFFF5858); // Kırmızı - Transaction FAB ile aynı
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232326).withOpacity(0.92) : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color, // Sadece text rengi
              letterSpacing: -0.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232326).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(iconData, color: color, size: iconSize - 6),
                onPressed: () => _onStockTransactionSelected(transactionType),
                splashRadius: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFab(BuildContext context, AppLocalizations l10n, bool isDark, double fabSize, double iconSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: fabSize,
          height: fabSize,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232326).withOpacity(0.85) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              _isExpanded ? Icons.close_rounded : Icons.trending_up_rounded,
              color: isDark ? Colors.white : const Color(0xFF6D6D70),
              size: iconSize - 4,
            ),
            onPressed: _toggleFab,
            splashRadius: 28,
          ),
        ),
      ),
    );
  }
}
