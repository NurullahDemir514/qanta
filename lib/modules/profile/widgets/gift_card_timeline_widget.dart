import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/gift_card_provider_model.dart';

/// Timeline milestone for gift card providers
class TimelineMilestone {
  final GiftCardProviderConfig config;
  final double progress; // 0.0 to 1.0
  final bool isReached;
  final bool isCurrent;

  const TimelineMilestone({
    required this.config,
    required this.progress,
    required this.isReached,
    required this.isCurrent,
  });
}

/// Gift Card Timeline Widget
/// Shows timeline of gift card providers with progress
class GiftCardTimelineWidget extends StatelessWidget {
  final int currentPoints;
  final List<GiftCardProviderConfig> providers;
  final ValueChanged<GiftCardProvider>? onProviderSelected;

  const GiftCardTimelineWidget({
    super.key,
    required this.currentPoints,
    required this.providers,
    this.onProviderSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create milestones
    final milestones = providers.map((config) {
      final progress = config.getProgress(currentPoints);
      final isReached = config.canRedeem(currentPoints);
      // Find if this is the current target (not reached but closest to current points)
      bool isCurrent = false;
      if (!isReached && progress > 0) {
        // Check if this is the first unreached milestone with progress
        final index = providers.indexOf(config);
        final previousReached = index > 0
            ? providers
                .sublist(0, index)
                .every((p) => p.canRedeem(currentPoints))
            : true;
        isCurrent = previousReached && progress > 0;
      }

      return TimelineMilestone(
        config: config,
        progress: progress,
        isReached: isReached,
        isCurrent: isCurrent,
      );
    }).toList();

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // Timeline line (background)
          Positioned.fill(
            child: CustomPaint(
              painter: TimelinePainter(
                milestones: milestones,
                currentPoints: currentPoints,
              ),
            ),
          ),
          // Milestone items
          Row(
            children: milestones
                .map((milestone) => Expanded(
                      child: _buildMilestoneItem(context, milestone),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(BuildContext context, TimelineMilestone milestone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = milestone.config;
    final isReached = milestone.isReached;
    final isCurrent = milestone.isCurrent;

    return GestureDetector(
      onTap: () => onProviderSelected?.call(config.provider),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReached
                  ? config.primaryColor
                  : isCurrent
                      ? config.primaryColor.withValues(alpha: 0.6)
                      : isDark
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE5E5EA),
              border: Border.all(
                color: isReached
                    ? config.accentColor
                    : isCurrent
                        ? config.primaryColor
                        : isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFE5E5EA),
                width: isCurrent ? 2 : 1.5,
              ),
              boxShadow: isReached || isCurrent
                  ? [
                      BoxShadow(
                        color: config.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isReached
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : isCurrent
                    ? Icon(
                        Icons.radio_button_checked,
                        color: config.primaryColor,
                        size: 20,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        color: isDark
                            ? const Color(0xFF6D6D70)
                            : const Color(0xFFA0A0A0),
                        size: 20,
                      ),
          ),
          const SizedBox(height: 8),
          // Provider Name
          Text(
            config.name,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isCurrent || isReached ? FontWeight.w600 : FontWeight.w500,
              color: isReached
                  ? config.primaryColor
                  : isCurrent
                      ? config.primaryColor
                      : isDark
                          ? const Color(0xFF6D6D70)
                          : const Color(0xFFA0A0A0),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Amount
          Text(
            '${config.minimumThreshold.toInt()} TL',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Timeline Painter
/// Draws the progress line connecting milestones
class TimelinePainter extends CustomPainter {
  final List<TimelineMilestone> milestones;
  final int currentPoints;

  TimelinePainter({
    required this.milestones,
    required this.currentPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (milestones.isEmpty) return;

    final linePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final backgroundLinePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw background line
    final startY = size.height * 0.25;
    final lineStartX = 20.0;
    final lineEndX = size.width - 20.0;

    // Draw background line (gray)
    backgroundLinePaint.color = const Color(0xFFE5E5EA).withValues(alpha: 0.3);
    canvas.drawLine(
      Offset(lineStartX, startY),
      Offset(lineEndX, startY),
      backgroundLinePaint,
    );

    // Draw progress line
    if (milestones.isNotEmpty) {
      // Find the highest reached milestone
      int highestReachedIndex = -1;
      int currentIndex = -1;

      for (int i = 0; i < milestones.length; i++) {
        final milestone = milestones[i];
        if (milestone.isReached) {
          highestReachedIndex = i;
        } else if (milestone.isCurrent && currentIndex == -1) {
          currentIndex = i;
        }
      }

      // Draw progress up to highest reached milestone
      if (highestReachedIndex >= 0) {
        final segmentWidth = (lineEndX - lineStartX) / milestones.length;
        final progressEndX = lineStartX + (segmentWidth * (highestReachedIndex + 1));

        // Use the color of the reached milestone
        final reachedConfig = milestones[highestReachedIndex].config;
        linePaint.color = reachedConfig.primaryColor;

        canvas.drawLine(
          Offset(lineStartX, startY),
          Offset(progressEndX, startY),
          linePaint,
        );
      }

      // Draw progress for current milestone
      if (currentIndex >= 0 && highestReachedIndex < currentIndex) {
        final currentConfig = milestones[currentIndex].config;
        final segmentWidth = (lineEndX - lineStartX) / milestones.length;
        final segmentStartX = lineStartX + (segmentWidth * currentIndex);
        final progress = milestones[currentIndex].progress;
        final progressEndX = segmentStartX + (segmentWidth * progress);

        linePaint.color = currentConfig.primaryColor;

        // Draw from start or from previous milestone
        final drawStartX = highestReachedIndex >= 0
            ? lineStartX + (segmentWidth * (highestReachedIndex + 1))
            : lineStartX;

        canvas.drawLine(
          Offset(drawStartX, startY),
          Offset(progressEndX, startY),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.currentPoints != currentPoints ||
        oldDelegate.milestones.length != milestones.length;
  }
}

