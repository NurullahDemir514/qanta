import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/gift_card_provider_model.dart';

/// Elegant animated gift card button
/// Supports provider-specific colors for better brand identity
class ElegantGiftCardButton extends StatefulWidget {
  final int currentPoints;
  final VoidCallback onPressed;
  final GiftCardProviderConfig? providerConfig; // Optional provider config for brand colors

  const ElegantGiftCardButton({
    super.key,
    required this.currentPoints,
    required this.onPressed,
    this.providerConfig,
  });

  @override
  State<ElegantGiftCardButton> createState() => _ElegantGiftCardButtonState();
}

class _ElegantGiftCardButtonState extends State<ElegantGiftCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Use provider-specific threshold or default to 20000 (100 TL)
    final threshold = widget.providerConfig?.requiredPoints ?? 20000;
    final hasEnoughPoints = widget.currentPoints >= threshold;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Neutral colors when not active
    final neutralColor = isDark ? const Color(0xFF6D6D70) : const Color(0xFFA0A0A0);
    final neutralBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    
    // Get button colors from provider config or use default Amazon orange
    final buttonColor = hasEnoughPoints 
        ? (widget.providerConfig?.primaryColor ?? const Color(0xFFFF9900))
        : neutralColor;
    final buttonAccentColor = hasEnoughPoints
        ? (widget.providerConfig?.accentColor ?? const Color(0xFFFF7700))
        : neutralColor;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: hasEnoughPoints ? _handleTapDown : null,
        onTapUp: hasEnoughPoints ? _handleTapUp : null,
        onTapCancel: hasEnoughPoints ? _handleTapCancel : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Use gradient background when enough points, neutral background otherwise
            gradient: hasEnoughPoints
                ? LinearGradient(
                    colors: [buttonColor, buttonAccentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: hasEnoughPoints ? null : neutralBgColor,
            border: Border.all(
              color: hasEnoughPoints
                  ? Colors.transparent
                  : neutralColor.withValues(alpha: 0.3),
              width: hasEnoughPoints ? 0 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasEnoughPoints
                ? [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: (1 - value) * 0.3,
                    child: Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Icon(
                        Icons.card_giftcard,
                        size: 18,
                        color: hasEnoughPoints
                            ? Colors.white
                            : neutralColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                hasEnoughPoints ? 'Hediye Kartı Al' : 'Hediye Kartlarım',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasEnoughPoints
                      ? Colors.white
                      : neutralColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

