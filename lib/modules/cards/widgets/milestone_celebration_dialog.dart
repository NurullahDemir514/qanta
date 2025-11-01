import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

/// Milestone kutlama dialog'u
class MilestoneCelebrationDialog extends StatefulWidget {
  final String goalName;
  final int milestonePercentage;
  final double currentAmount;
  final double targetAmount;

  const MilestoneCelebrationDialog({
    super.key,
    required this.goalName,
    required this.milestonePercentage,
    required this.currentAmount,
    required this.targetAmount,
  });

  @override
  State<MilestoneCelebrationDialog> createState() => _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getMilestoneEmoji() {
    switch (widget.milestonePercentage) {
      case 25:
        return '🎯';
      case 50:
        return '🔥';
      case 75:
        return '⚡';
      case 100:
        return '🎉';
      default:
        return '✨';
    }
  }

  String _getMilestoneTitle(AppLocalizations l10n) {
    switch (widget.milestonePercentage) {
      case 25:
        return l10n.milestone25Title;
      case 50:
        return l10n.milestone50Title;
      case 75:
        return l10n.milestone75Title;
      case 100:
        return l10n.milestone100Title;
      default:
        return l10n.milestoneDefaultTitle;
    }
  }

  String _getMilestoneMessage(AppLocalizations l10n) {
    switch (widget.milestonePercentage) {
      case 25:
        return l10n.milestone25Message;
      case 50:
        return l10n.milestone50Message;
      case 75:
        return l10n.milestone75Message;
      case 100:
        return l10n.milestone100Message;
      default:
        return l10n.milestoneDefaultMessage;
    }
  }

  Color _getMilestoneColor() {
    switch (widget.milestonePercentage) {
      case 25:
        return const Color(0xFF007AFF); // Blue
      case 50:
        return const Color(0xFFFF9500); // Orange
      case 75:
        return const Color(0xFFAF52DE); // Purple
      case 100:
        return const Color(0xFF34C759); // Green
      default:
        return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getMilestoneColor().withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji with animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getMilestoneColor().withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getMilestoneEmoji(),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  _getMilestoneTitle(l10n),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _getMilestoneColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Goal name
                Text(
                  widget.goalName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Message
                Text(
                  _getMilestoneMessage(l10n),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.current,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '₺${widget.currentAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _getMilestoneColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.milestonePercentage / 100,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getMilestoneColor(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.target,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '₺${widget.targetAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getMilestoneColor(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Harika!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

