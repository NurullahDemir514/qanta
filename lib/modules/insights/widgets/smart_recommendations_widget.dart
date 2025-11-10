import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/smart_recommendation.dart';

class SmartRecommendationsWidget extends StatefulWidget {
  final List<SmartRecommendation> recommendations;
  final Function(SmartRecommendation)? onRecommendationTap;
  final Function(SmartRecommendation)? onRecommendationDismiss;

  const SmartRecommendationsWidget({
    super.key,
    required this.recommendations,
    this.onRecommendationTap,
    this.onRecommendationDismiss,
  });

  @override
  State<SmartRecommendationsWidget> createState() =>
      _SmartRecommendationsWidgetState();
}

class _SmartRecommendationsWidgetState extends State<SmartRecommendationsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _dismissedIds = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<SmartRecommendation> get _visibleRecommendations {
    return widget.recommendations
        .where((rec) => !_dismissedIds.contains(rec.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecs = _visibleRecommendations;

    if (visibleRecs.isEmpty) {
      return _buildEmptyState(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildRecommendationsCarousel(context, visibleRecs),
          if (visibleRecs.length > 1) ...[
            const SizedBox(height: 12),
            _buildPageIndicators(context, visibleRecs.length),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF4ECDC4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akıllı Öneriler',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Finansal hedeflerinize ulaşmanız için öneriler',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCarousel(
    BuildContext context,
    List<SmartRecommendation> recommendations,
  ) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildRecommendationCard(context, recommendations[index]),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    SmartRecommendation recommendation,
  ) {
    return Dismissible(
      key: Key(recommendation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 24),
      ),
      onDismissed: (direction) {
        setState(() {
          _dismissedIds.add(recommendation.id);
        });
        widget.onRecommendationDismiss?.call(recommendation);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneri kapatıldı'),
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () {
                setState(() {
                  _dismissedIds.remove(recommendation.id);
                });
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => widget.onRecommendationTap?.call(recommendation),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                recommendation.color.withValues(alpha: 0.1),
                recommendation.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recommendation.color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: recommendation.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      recommendation.icon,
                      color: recommendation.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (recommendation.category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: recommendation.color.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recommendation.category,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: recommendation.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildPriorityBadge(recommendation.priority),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (recommendation.potentialSavings > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFB3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 12,
                            color: Color(0xFF00FFB3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Provider.of<ThemeProvider>(context, listen: false).formatAmount(recommendation.potentialSavings)}${AppLocalizations.of(context)?.perMonth ?? '/month'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00FFB3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (recommendation.actionable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: recommendation.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 12,
                            color: recommendation.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Uygula',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: recommendation.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _getTimeAgoText(recommendation.generatedAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(RecommendationPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case RecommendationPriority.high:
        color = const Color(0xFFFF6B6B);
        text = 'Yüksek';
        break;
      case RecommendationPriority.medium:
        color = const Color(0xFFFFB800);
        text = 'Orta';
        break;
      case RecommendationPriority.low:
        color = const Color(0xFF4ECDC4);
        text = 'Düşük';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPageIndicators(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == _currentPage
                ? const Color(0xFF4ECDC4)
                : const Color(0xFF8E8E93).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Öneri Yok',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Daha fazla işlem yaptıkça size özel öneriler sunacağız.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgoText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }
}

// SmartRecommendation sınıfı statistics_screen.dart'ta tanımlandı
