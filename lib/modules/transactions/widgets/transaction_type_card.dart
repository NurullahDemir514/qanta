import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../l10n/app_localizations.dart';

class TransactionTypeCard extends StatefulWidget {
  final TransactionType transactionType;
  final bool isDark;
  final VoidCallback onTap;

  const TransactionTypeCard({
    super.key,
    required this.transactionType,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<TransactionTypeCard> createState() => _TransactionTypeCardState();
}

class _TransactionTypeCardState extends State<TransactionTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark 
                ? const Color(0xFF2C2C2E)
                : Colors.white,
              borderRadius: BorderRadius.circular(16), // Daha yuvarlak
              border: widget.isDark ? null : Border.all(
                color: const Color(0xFFE8E8E8),
                width: 0.5,
              ),
              boxShadow: [
                if (!widget.isDark) // Light mode'da subtle shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.transparent,
                highlightColor: widget.isDark 
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(20), // Daha geniş padding
                  child: Row(
                    children: [
                      // Icon Container - daha büyük ve refined
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.transactionType.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.transactionType.color.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.transactionType.icon,
                          color: widget.transactionType.color,
                          size: 26, // Daha büyük icon
                        ),
                      ),
                      
                      const SizedBox(width: 16), // Daha geniş spacing
                      
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transactionType.getName(l10n),
                              style: GoogleFonts.inter(
                                fontSize: 17, // Biraz daha büyük
                                fontWeight: FontWeight.w600,
                                color: widget.isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6), // Daha geniş spacing
                            Text(
                              widget.transactionType.getDescription(l10n),
                              style: GoogleFonts.inter(
                                fontSize: 15, // Biraz daha büyük
                                fontWeight: FontWeight.w400,
                                color: widget.isDark 
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                                letterSpacing: -0.1,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Arrow Icon - daha subtle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isPressed 
                            ? (widget.isDark 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05))
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: widget.isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 