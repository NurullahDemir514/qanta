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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark 
                ? Border.all(
                    color: const Color(0xFF38383A).withOpacity(0.3),
                    width: 0.5,
                  )
                : null,
          ),
          child: Text(
            'Hızlı Not',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF1C1C1E),
              letterSpacing: -0.1,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Mini FAB - iOS tarzı sade
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark 
                ? Border.all(
                    color: const Color(0xFF38383A).withOpacity(0.5),
                    width: 0.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onQuickNoteSelected,
              borderRadius: BorderRadius.circular(22),
              child: const Icon(
                Icons.note_add_rounded,
                color: Color(0xFFFF9500), // iOS turuncu
                size: 20,
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
    final l10n = AppLocalizations.of(context)!;
    
    // iOS tarzı sade renkler
    Color optionColor;
    switch (transactionType) {
      case TransactionType.income:
        optionColor = const Color(0xFF34C759); // iOS yeşil
        break;
      case TransactionType.expense:
        optionColor = const Color(0xFFFF3B30); // iOS kırmızı
        break;
      case TransactionType.transfer:
        optionColor = const Color(0xFF007AFF); // iOS mavi
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark 
                ? Border.all(
                    color: const Color(0xFF38383A).withOpacity(0.3),
                    width: 0.5,
                  )
                : null,
          ),
          child: Text(
            transactionType.getName(l10n),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF1C1C1E),
              letterSpacing: -0.1,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Mini FAB - iOS tarzı sade
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark 
                ? Border.all(
                    color: const Color(0xFF38383A).withOpacity(0.5),
                    width: 0.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onTransactionTypeSelected(transactionType),
              borderRadius: BorderRadius.circular(22),
              child: Icon(
                transactionType.icon,
                color: optionColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFab(BuildContext context, AppLocalizations l10n, bool isDark, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(
                color: const Color(0xFF38383A).withOpacity(0.3),
                width: 0.5,
              )
            : Border.all(
                color: const Color(0xFFE5E5EA).withOpacity(0.3),
                width: 0.5,
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleFab,
              borderRadius: BorderRadius.circular(28),
              splashColor: Colors.transparent,
              highlightColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 12 : 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                      size: isSmallScreen ? 18 : 20,
                      color: isDark 
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1C1C1E),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    Text(
                      _isExpanded
                          ? l10n.close 
                          : (isSmallScreen ? 'İşlem' : l10n.addTransaction),
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        color: isDark 
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 