import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../core/providers/savings_provider.dart';
import 'add_savings_goal_form.dart';
import 'dart:math' as math;

/// Goal tamamlandı kutlama dialog'u
class GoalCompletedDialog extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback? onArchive;
  final VoidCallback? onKeepActive;
  final VoidCallback? onNewGoal;

  const GoalCompletedDialog({
    super.key,
    required this.goal,
    this.onArchive,
    this.onKeepActive,
    this.onNewGoal,
  });

  @override
  State<GoalCompletedDialog> createState() => _GoalCompletedDialogState();
}

class _GoalCompletedDialogState extends State<GoalCompletedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _calculateDaysTaken() {
    final now = DateTime.now();
    final created = widget.goal.createdAt;
    return now.difference(created).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    
    final days = _calculateDaysTaken();
    final amount = themeProvider.formatAmount(widget.goal.targetAmount);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Confetti particles
                ...List.generate(30, (index) => _buildConfetti(index)),
                
                // Main content
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy emoji with scale animation
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🏆',
                                style: TextStyle(fontSize: 56),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          l10n.goalCompletedTitle,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4CAF50),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Goal name
                        Text(
                          widget.goal.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Message
                        Text(
                          l10n.goalCompletedMessage(widget.goal.name),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                                ? Colors.white.withOpacity(0.7) 
                                : Colors.black.withOpacity(0.6),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stats card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF2C2C2E),
                                      const Color(0xFF1C1C1E),
                                    ]
                                  : [
                                      const Color(0xFFF5F5F5),
                                      const Color(0xFFE8E8E8),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.goalCompletedStats(days.toString(), amount),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Column(
                          children: [
                            // Archive button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onArchive?.call();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.archive_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.archiveGoal,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Secondary actions row
                            Row(
                              children: [
                                // Keep Active button
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onKeepActive?.call();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.keepActive,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 10),
                                
                                // New Goal button
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onNewGoal?.call();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF4CAF50),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.createNewGoal,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfetti(int index) {
    final random = math.Random(index);
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFD700),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    
    final color = colors[random.nextInt(colors.length)];
    final size = 6.0 + random.nextDouble() * 6.0;
    final startX = -200.0 + random.nextDouble() * 600.0;
    final endY = 300.0 + random.nextDouble() * 200.0;
    final rotation = random.nextDouble() * 2 * math.pi;
    final delay = random.nextDouble() * 0.4;
    
    final animation = Tween<double>(begin: -100, end: endY).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delay,
          1.0,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    
    final fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.6 + delay,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: startX,
          top: animation.value,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Transform.rotate(
              angle: rotation * _controller.value * 3,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: random.nextBool() ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: random.nextBool() ? null : BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

