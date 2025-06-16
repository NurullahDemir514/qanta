import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class MainTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const MainTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(
                  color: const Color(0xFF38383A).withValues(alpha: 0.5),
                  width: 0.5,
                )
              : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TabItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: l10n.home,
                      index: 0,
                      isSelected: currentIndex == 0,
                      onTap: onTabChanged,
                    ),
                    _TabItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long,
                      label: l10n.transactions,
                      index: 1,
                      isSelected: currentIndex == 1,
                      onTap: onTabChanged,
                    ),
                    _TabItem(
                      icon: Icons.credit_card_outlined,
                      activeIcon: Icons.credit_card,
                      label: l10n.myCards,
                      index: 2,
                      isSelected: currentIndex == 2,
                      onTap: onTabChanged,
                    ),
                    _TabItem(
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      label: l10n.analytics,
                      index: 3,
                      isSelected: currentIndex == 3,
                      onTap: onTabChanged,
                    ),
                    _TabItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: l10n.profile,
                      index: 4,
                      isSelected: currentIndex == 4,
                      onTap: onTabChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool isSelected;
  final Function(int) onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  size: 24,
                  color: isSelected 
                    ? const Color(0xFF10B981) 
                    : (isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70)),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                    ? const Color(0xFF10B981) 
                    : (isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70)),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 