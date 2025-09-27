import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/add_debit_card_form.dart';
import '../widgets/add_credit_card_form.dart';

class AddCardFab extends StatefulWidget {
  final int currentTabIndex;

  const AddCardFab({
    super.key,
    required this.currentTabIndex,
  });

  @override
  State<AddCardFab> createState() => _AddCardFabState();
}

class _AddCardFabState extends State<AddCardFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // FAB'ı göster
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    HapticFeedback.lightImpact();
    _showCardTypeSelection();
  }

  void _showCardTypeSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context)?.selectCardType ?? 'Select Card Type',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Card type options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Debit Card Option
                  _buildCardTypeOption(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AppLocalizations.of(context)?.debitCard ?? 'Debit Card',
                    subtitle: AppLocalizations.of(context)?.addDebitCardDescription ?? 'Add checking account card',
                    onTap: () {
                      Navigator.pop(context);
                      _showDebitCardForm();
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Credit Card Option
                  _buildCardTypeOption(
                    icon: Icons.credit_card_outlined,
                    title: AppLocalizations.of(context)?.creditCard ?? 'Credit Card',
                    subtitle: AppLocalizations.of(context)?.addCreditCardDescription ?? 'Add your credit card information',
                    onTap: () {
                      Navigator.pop(context);
                      _showCreditCardForm();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF48484A).withValues(alpha: 0.3)
                        : const Color(0xFFAEAEB2).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDark 
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.8)
                        : const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDebitCardForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddDebitCardForm(
          onSuccess: () {
            // Kartlar yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }

  void _showCreditCardForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddCreditCardForm(
          onSuccess: () {
            // Kartlar yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375;
    final rightPosition = isSmallScreen ? 16.0 : 20.0;
    final bottomPosition = screenHeight < 700 ? 70.0 : 80.0;
    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: _onFabPressed,
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
                    Icons.add_card_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 