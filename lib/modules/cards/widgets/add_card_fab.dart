import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../premium/premium_offer_screen.dart';
import '../widgets/add_debit_card_form.dart';
import '../widgets/add_credit_card_form.dart';
import '../widgets/add_savings_goal_form.dart';

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
  bool _isExpanded = false;
  late AppLocalizations l10n;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
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
                    title: AppLocalizations.of(context)?.debitCard ?? 'Banka Kartı',
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
                    title: AppLocalizations.of(context)?.creditCard ?? 'Kredi Kartı',
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

  void _showDebitCardForm() async {
    // Check card limit
    if (!await _checkCardLimit()) return;
    
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

  void _showCreditCardForm() async {
    // Check card limit
    if (!await _checkCardLimit()) return;
    
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

  /// Kart limiti kontrolü - false dönerse ekleme yapılamaz
  Future<bool> _checkCardLimit() async {
    final premiumService = context.read<PremiumService>();
    final l10n = AppLocalizations.of(context);
    
    // Premium kullanıcı limitsize
    if (premiumService.isPremium) {
      return true;
    }
    
    // Firebase'den gerçek kart sayısını al (cache sorununu çözer)
    final totalCards = await premiumService.getCurrentCardCount();
    
    // Limit kontrolü
    if (!premiumService.canAddCard(totalCards)) {
      if (mounted) {
        // Premium'dan free'ye geçenler için özel mesaj
        if (totalCards > 3) {
          _showCardLimitDialog(
            title: l10n?.cardLimitExceeded ?? 'Kart Limiti',
            message: l10n?.cardLimitExceededMessage(totalCards, totalCards - 2) ?? 
                'Şu anda $totalCards kartınız var.\n\nFree kullanıcılar en fazla 3 kart ekleyebilir.\n\n${totalCards - 2} kart silin veya Premium\'a geçin.',
            totalCards: totalCards,
          );
        } else {
          // Tam limit (3 kart): Premium ekranı göster
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumOfferScreen(),
              fullscreenDialog: true,
            ),
          );
        }
      }
      return false;
    }
    
    return true;
  }

  /// Kart limiti dialog'u göster
  void _showCardLimitDialog({
    required String title,
    required String message,
    required int totalCards,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: const Color(0xFFFF9500), // Orange
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n?.close ?? 'Kapat',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumOfferScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              l10n?.upgradeToPremium ?? 'Premium\'a Geç',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive değerler - Navbar'ın hemen üstünde
    final rightPosition = FabPositioning.getRightPosition(context);
    final bottomPosition = FabPositioning.getBottomPosition(context);
    final fabSize = FabPositioning.getFabSize(context);
    final iconSize = FabPositioning.getIconSize(context);
    
    // Consumer ile sarmala - test modu değişince rebuild olsun
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) => Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speed Dial Options
          if (_isExpanded) ...[
            // Debit Card Option
            _buildCardOption(
              context: context,
              isDark: isDark,
              icon: Icons.account_balance_rounded,
              label: l10n.debitCard,
              color: const Color(0xFF007AFF), // iOS Blue
              onTap: () => _onCardTypeSelected('debit'),
            ),
            
            const SizedBox(height: 12),
            
            // Credit Card Option
            _buildCardOption(
              context: context,
              isDark: isDark,
              icon: Icons.credit_card_rounded,
              label: l10n.creditCard,
              color: const Color(0xFFE74C3C), // Red
              onTap: () => _onCardTypeSelected('credit'),
            ),
            
            const SizedBox(height: 12),
            
            // Savings Goal Option
            _buildCardOption(
              context: context,
              isDark: isDark,
              icon: Icons.rocket_launch_rounded,
              label: l10n.savingsGoals,
              color: const Color(0xFFBF5AF2), // Purple
              onTap: () => _onCardTypeSelected('savings'),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Main FAB
          _buildMainFab(context, isDark, fabSize, iconSize),
        ],
      ),
      ),
    );
  }

  Widget _buildCardOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
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
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color, // Sadece text rengi - diğer FAB'lar gibi
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232326).withOpacity(0.85) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, color: color, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              splashRadius: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFab(BuildContext context, bool isDark, double fabSize, double iconSize) {
    return GestureDetector(
      onTap: _onFabPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: fabSize,
            height: fabSize,
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
              _isExpanded ? Icons.close : Icons.add_card_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  void _onCardTypeSelected(String cardType) {
    setState(() {
      _isExpanded = false;
    });
    
    switch (cardType) {
      case 'debit':
        _showDebitCardForm();
        break;
      case 'credit':
        _showCreditCardForm();
        break;
      case 'savings':
        _showSavingsGoalForm();
        break;
    }
  }

  void _showSavingsGoalForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddSavingsGoalForm(
          onSuccess: () {
            // Goals yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }
} 