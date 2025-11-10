import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/ai_insight_model.dart';
import 'ai_insight_card.dart';

/// Staggered animasyonlu insights listesi
class StaggeredInsightsList extends StatelessWidget {
  final List<AIInsight> insights;
  final bool isDark;

  const StaggeredInsightsList({
    super.key,
    required this.insights,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: List.generate(
          insights.length,
          (index) {
            final insight = insights[index];
            
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Column(
                    children: [
                      AIInsightCard(
                        insight: insight,
                        onTap: () {
                          // Detay sayfasına git (gelecekte eklenebilir)
                        },
                      ),
                      if (index < insights.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                        ),
                      if (index == insights.length - 1)
                        const SizedBox(height: 75),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




