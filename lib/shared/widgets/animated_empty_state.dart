import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget? actionButton;
  final double iconSize;
  final double containerSize;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.actionButton,
    this.iconSize = 40,
    this.containerSize = 80,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Animated Icon Container
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: widget.containerSize,
                height: widget.containerSize,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.iconColor,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Animated Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Animated Description
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                      letterSpacing: -0.2,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            // Action Button (if provided)
            if (widget.actionButton != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: widget.actionButton!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 