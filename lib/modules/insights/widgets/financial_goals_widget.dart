import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/theme/theme_provider.dart';

class FinancialGoalsWidget extends StatefulWidget {
  final List<FinancialGoal> goals;
  final Function(FinancialGoal)? onGoalTap;
  final VoidCallback? onAddGoal;

  const FinancialGoalsWidget({
    super.key,
    required this.goals,
    this.onGoalTap,
    this.onAddGoal,
  });

  @override
  State<FinancialGoalsWidget> createState() => _FinancialGoalsWidgetState();
}

class _FinancialGoalsWidgetState extends State<FinancialGoalsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _progressControllers;
  late List<Animation<double>> _progressAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressControllers = List.generate(
      widget.goals.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000 + (index * 200)),
        vsync: this,
      ),
    );

    _progressAnimations = _progressControllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    _animationController.forward();
    for (var controller in _progressControllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFB3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flag_outlined,
                  color: const Color(0xFF00FFB3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Finansal Hedefler',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.onAddGoal != null)
                GestureDetector(
                  onTap: widget.onAddGoal,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add,
                      color: const Color(0xFF00FFB3),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Goals List
          if (widget.goals.isEmpty)
            _buildEmptyState()
          else
            ...widget.goals.asMap().entries.map((entry) {
              final index = entry.key;
              final goal = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnimatedBuilder(
                  animation: _progressAnimations[index],
                  builder: (context, child) {
                    return _buildGoalCard(
                      goal,
                      _progressAnimations[index].value,
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFB3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FFB3).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: const Color(0xFF00FFB3).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz hedef belirlemediniz',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'İlk finansal hedefinizi oluşturun',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.onAddGoal != null)
            ElevatedButton(
              onPressed: widget.onAddGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFB3),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Hedef Oluştur'),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(FinancialGoal goal, double animationValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).currency;
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
    );
    final progress = goal.targetAmount > 0
        ? goal.currentAmount / goal.targetAmount
        : 0.0;
    final animatedProgress = progress * animationValue;

    final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;

    return GestureDetector(
      onTap: () => widget.onGoalTap?.call(goal),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: goal.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        goal.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: goal.color,
                      ),
                    ),
                    Text(
                      isOverdue
                          ? '${daysRemaining.abs()} gün geçti'
                          : '$daysRemaining gün kaldı',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: goal.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Amount Info
            Row(
              children: [
                Text(
                  formatter.format(goal.currentAmount),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' / ${formatter.format(goal.targetAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getGoalStatusText(goal, progress, isOverdue),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: goal.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGoalStatusText(
    FinancialGoal goal,
    double progress,
    bool isOverdue,
  ) {
    if (progress >= 1.0) return 'Tamamlandı';
    if (isOverdue) return 'Gecikmiş';
    if (progress >= 0.8) return 'Neredeyse bitti';
    if (progress >= 0.5) return 'Yarı yolda';
    if (progress >= 0.2) return 'İyi gidiyor';
    return 'Başlangıç';
  }
}

// Data model
class FinancialGoal {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final Color color;
  final GoalCategory category;

  const FinancialGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.color,
    required this.category,
  });

  FinancialGoal copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    Color? color,
    GoalCategory? category,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      category: category ?? this.category,
    );
  }
}

enum GoalCategory {
  savings,
  investment,
  purchase,
  debt,
  emergency,
  travel,
  education,
  other,
}
