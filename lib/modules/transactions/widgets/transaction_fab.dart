import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model.dart';
import '../screens/expense_form_screen.dart';
import '../screens/income_form_screen.dart';
import '../screens/transfer_form_screen.dart';
import '../../home/pages/quick_notes_page.dart';

class TransactionFab extends StatefulWidget {
  const TransactionFab({super.key});

  @override
  State<TransactionFab> createState() => _TransactionFabState();
}

class _TransactionFabState extends State<TransactionFab> {
  bool _isExpanded = false;

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onTransactionTypeSelected(TransactionType type) {
    HapticFeedback.selectionClick();
    
    // Önce FAB'ı kapat
    setState(() {
      _isExpanded = false;
    });
    
    // Form'u aç
    switch (type) {
      case TransactionType.income:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IncomeFormScreen(),
          ),
        );
        break;
      case TransactionType.expense:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExpenseFormScreen(),
          ),
        );
        break;
      case TransactionType.transfer:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransferFormScreen(),
          ),
        );
        break;
    }
  }

  void _onQuickNoteSelected() {
    HapticFeedback.selectionClick();
    
    // Önce FAB'ı kapat
    setState(() {
      _isExpanded = false;
    });
    
    // Hızlı Not sayfasını aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuickNotesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive değerler
    final isSmallScreen = screenWidth < 375;
    final rightPosition = isSmallScreen ? 16.0 : 20.0;
    final bottomPosition = screenHeight < 700 ? 70.0 : 80.0;
    
    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speed Dial Options
          if (_isExpanded) ...[
            // Quick Note Option
            _buildQuickNoteOption(
              context: context,
              isDark: isDark,
            ),
            
            const SizedBox(height: 12),
            
            // Transfer Option
            _buildSpeedDialOption(
              context: context,
              transactionType: TransactionType.transfer,
              isDark: isDark,
            ),
            
            const SizedBox(height: 12),
            
            // Expense Option
            _buildSpeedDialOption(
              context: context,
              transactionType: TransactionType.expense,
              isDark: isDark,
            ),
            
            const SizedBox(height: 12),
            
            // Income Option
            _buildSpeedDialOption(
              context: context,
              transactionType: TransactionType.income,
              isDark: isDark,
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Main FAB
          _buildMainFab(context, l10n, isDark, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildQuickNoteOption({
    required BuildContext context,
    required bool isDark,
  }) {
    const color = Color(0xFF6D6D70); // Nötr gri
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
            'Hızlı Not',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
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
                icon: const Icon(Icons.edit_note_rounded, color: color, size: 22),
                onPressed: _onQuickNoteSelected,
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
    required TransactionType transactionType,
    required bool isDark,
  }) {
    final iconData = transactionType == TransactionType.income
        ? Icons.arrow_downward_rounded
        : transactionType == TransactionType.expense
            ? Icons.arrow_upward_rounded
            : Icons.compare_arrows_rounded;
    final label = transactionType == TransactionType.income
        ? (AppLocalizations.of(context)?.income ?? 'Income')
        : transactionType == TransactionType.expense
            ? (AppLocalizations.of(context)?.expense ?? 'Expense')
            : (AppLocalizations.of(context)?.transfer ?? 'Transfer');
    // Her seçenek için düz renkler
    Color color;
    switch (transactionType) {
      case TransactionType.income:
        color = const Color(0xFF22C55E); // Yeşil
        break;
      case TransactionType.expense:
        color = const Color(0xFFFF5858); // Kırmızı
        break;
      case TransactionType.transfer:
        color = const Color(0xFF007AFF); // Mavi
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
              color: color,
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
                icon: Icon(iconData, color: color, size: 22),
                onPressed: () => _onTransactionTypeSelected(transactionType),
                splashRadius: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFab(BuildContext context, AppLocalizations l10n, bool isDark, bool isSmallScreen) {
    return GestureDetector(
      onTap: _toggleFab,
      child: AnimatedScale(
        scale: _isExpanded ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232326).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  width: 1.2,
                ),
              ),
              child: Icon(
                _isExpanded ? Icons.close : Icons.add,
                color: isDark ? Colors.white : Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 