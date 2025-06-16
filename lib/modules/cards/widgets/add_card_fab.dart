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
                'Kart Türü Seçin',
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
                    title: 'Banka Kartı',
                    subtitle: 'Vadesiz hesap kartı ekleyin',
                    onTap: () {
                      Navigator.pop(context);
                      _showDebitCardForm();
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Credit Card Option
                  _buildCardTypeOption(
                    icon: Icons.credit_card_outlined,
                    title: 'Kredi Kartı',
                    subtitle: 'Kredi kartı bilgilerinizi ekleyin',
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
    
    // Responsive değerler - TransactionFab ile aynı
    final isSmallScreen = screenWidth < 375;
    
    // Basitleştirilmiş konum hesaplama - TransactionFab'ın solundan 5px boşluk
    final rightPosition = isSmallScreen ? 140.0 : 150.0; // 5px daha sağa kaydırıldı
    
    // TransactionFab ile aynı bottom position
    final bottomPosition = screenHeight < 700 ? 70.0 : 80.0;
    
    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                    ? const Color(0xFF1C1C1E).withOpacity(0.9) // TransactionFab ile aynı opacity
                    : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28), // TransactionFab ile aynı radius
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                        ? Colors.black.withOpacity(0.4) // TransactionFab ile aynı
                        : Colors.black.withOpacity(0.1),
                      blurRadius: 16, // TransactionFab ile aynı
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: isDark
                        ? Colors.black.withOpacity(0.2) // TransactionFab ile aynı
                        : Colors.black.withOpacity(0.04),
                      blurRadius: 4, // TransactionFab ile aynı
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                  border: isDark
                    ? Border.all(
                        color: const Color(0xFF38383A).withOpacity(0.3), // TransactionFab ile aynı
                        width: 0.5,
                      )
                    : Border.all(
                        color: const Color(0xFFE5E5EA).withOpacity(0.3),
                        width: 0.5,
                      ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28), // TransactionFab ile aynı
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // TransactionFab ile aynı blur
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onFabPressed,
                        borderRadius: BorderRadius.circular(28),
                        splashColor: Colors.transparent,
                        highlightColor: isDark
                          ? Colors.white.withOpacity(0.05) // TransactionFab ile aynı
                          : Colors.black.withOpacity(0.03),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20, // TransactionFab ile aynı
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.credit_card_outlined,
                                size: isSmallScreen ? 18 : 20, // TransactionFab ile aynı
                                color: isDark 
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF1C1C1E),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Text(
                                isSmallScreen ? 'Kart' : 'Kart Ekle',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w500, // TransactionFab ile aynı
                                  letterSpacing: -0.1, // TransactionFab ile aynı
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
              ),
            ),
          );
        },
      ),
    );
  }
} 