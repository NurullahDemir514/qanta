import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class MainTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final Key? tutorialKey; // Tutorial için key

  const MainTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.tutorialKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        key: tutorialKey, // Tutorial key ekle
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18181A).withOpacity(0.92)
                      : Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.18)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month,
                        label: l10n.calendar,
                        index: 4,
                        isSelected: currentIndex == 4,
                        onTap: onTabChanged,
                      ),
                      _TabItem(
                        icon: Icons.trending_up_outlined,
                        activeIcon: Icons.trending_up,
                        label: l10n.stocks,
                        index: 5,
                        isSelected: currentIndex == 5,
                        onTap: onTabChanged,
                      ),
                    ],
                  ),
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
        onTap: () {
          Feedback.forTap(context);
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.zero,
          decoration: isSelected
              ? BoxDecoration(
                  color: isDark
                      ? const Color(0xFF232326).withOpacity(0.38)
                      : Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.18)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: isSelected
                  ? (isDark
                      ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
                      : ImageFilter.blur(sigmaX: 8, sigmaY: 8))
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? (isDark 
                                ? [
                                    Colors.white,
                                    const Color(0xFFE0E0E0), // Açık gri
                                  ]
                                : [
                                    Colors.black,
                                    const Color(0xFF3C3C43), // Koyu gri
                                  ])
                            : [
                                isDark ? const Color(0xFFD1D1D6) : const Color(0xFF444446),
                                isDark ? const Color(0xFFD1D1D6) : const Color(0xFF444446),
                              ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: AnimatedScale(
                      scale: isSelected ? 1.18 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.9,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? (isDark 
                                ? [
                                    Colors.white,
                                    const Color(0xFFE0E0E0), // Açık gri
                                  ]
                                : [
                                    Colors.black,
                                    const Color(0xFF3C3C43), // Koyu gri
                                  ])
                            : [
                                isDark ? const Color(0xFFD1D1D6) : const Color(0xFF444446),
                                isDark ? const Color(0xFFD1D1D6) : const Color(0xFF444446),
                              ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 