import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../modules/profile/providers/point_provider.dart';
import '../../../core/services/country_detection_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/screen_compatibility.dart';

/// Daily Streak Indicator Widget
/// Shows user's current streak and progress to 7-day bonus
/// Professional and unique design with advanced animations
class DailyStreakIndicator extends StatefulWidget {
  const DailyStreakIndicator({super.key});

  @override
  State<DailyStreakIndicator> createState() => _DailyStreakIndicatorState();
}

class _DailyStreakIndicatorState extends State<DailyStreakIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  late List<AnimationController> _linkControllers = [];
  bool _isTurkishUser = false;
  bool _isCheckingCountry = true;

  @override
  void initState() {
    super.initState();
    _checkIfTurkishUser();
    
    // Initialize link controllers for staggered animation
    for (int i = 0; i < 7; i++) {
      _linkControllers.add(
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 300 + (i * 100)),
        ),
      );
    }
    
    // Pulse animation for completed days
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Glow animation for bonus day
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Shimmer animation for active link
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    
    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    for (var controller in _linkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkIfTurkishUser() async {
    try {
      final countryService = CountryDetectionService();
      // Use getUserCountry() instead of isTurkishPlayStoreUser() 
      // to allow fallback for Turkish users when Play Store detection fails
      final countryCode = await countryService.getUserCountry();
      final isTurkish = countryCode == 'TR';
      debugPrint('🌍 DailyStreakIndicator: Country code: $countryCode, isTurkish: $isTurkish');
      if (mounted) {
        setState(() {
          _isTurkishUser = isTurkish;
          _isCheckingCountry = false;
        });
      }
    } catch (e) {
      debugPrint('❌ DailyStreakIndicator: Error checking country: $e');
      if (mounted) {
        setState(() {
          _isTurkishUser = false;
          _isCheckingCountry = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingCountry) {
      return const SizedBox.shrink();
    }

    if (!_isTurkishUser) {
      return const SizedBox.shrink();
    }

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Consumer<PointProvider>(
      builder: (context, pointProvider, child) {
        if (pointProvider.balance == null) {
          return const SizedBox.shrink();
        }

        final balance = pointProvider.balance!;
        final currentStreak = balance.weeklyStreakCount;
        final completedDays = currentStreak % 7;
        final daysToBonus = 7 - completedDays;
        final progress = completedDays / 7.0;
        final isBonusDay = (currentStreak % 7 == 0 && currentStreak > 0);
        
        // Calculate bonus points with premium multiplier
        final premiumService = PremiumService();
        final isPremium = premiumService.isPremium;
        final isPremiumPlus = premiumService.isPremiumPlus;
        final baseBonus = 1000;
        final bonusPoints = isPremiumPlus
            ? baseBonus * 2
            : isPremium
                ? (baseBonus * 1.5).round()
                : baseBonus;

        final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
        final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
        
        final cardPadding = ScreenCompatibility.responsivePadding(
          context,
          EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 :
            screenSize == ScreenSizeCategory.medium ? 14.0 :
            screenSize == ScreenSizeCategory.large ? 16.0 : 18.0,
            vertical: isSmallScreen ? 8.0 :
            screenSize == ScreenSizeCategory.medium ? 10.0 :
            screenSize == ScreenSizeCategory.large ? 12.0 : 14.0,
          ),
        );
        
        final borderRadius = ScreenCompatibility.responsiveWidth(
          context,
          isSmallScreen ? 12.0 :
          screenSize == ScreenSizeCategory.medium ? 14.0 :
          screenSize == ScreenSizeCategory.large ? 16.0 : 18.0,
        );
        
        return Container(
          margin: EdgeInsets.only(
            bottom: ScreenCompatibility.responsiveHeight(context, 10.0),
          ),
          padding: cardPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBonusDay
                  ? [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                      const Color(0xFFFF6347),
                    ]
                  : [
                      isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFF5F5F7),
                      isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFF5F5F7),
                    ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isBonusDay
                  ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
              width: isBonusDay ? 2 : 1,
            ),
            boxShadow: isBonusDay
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated chain - full width
              _buildAdvancedChainAnimation(completedDays, isBonusDay, isDark),
              SizedBox(height: ScreenCompatibility.responsiveHeight(context, 8.0)),
              // Streak info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBonusDay
                              ? '🎉 Haftalık Seri Tamamlandı!'
                              : currentStreak > 0
                                  ? '$currentStreak Günlük Seri'
                                  : 'Günlük Seri Başlat',
                          style: GoogleFonts.inter(
                            fontSize: ScreenCompatibility.responsiveFontSize(
                              context,
                              isSmallScreen ? 12.0 :
                              screenSize == ScreenSizeCategory.medium ? 13.0 :
                              screenSize == ScreenSizeCategory.large ? 14.0 : 15.0,
                            ),
                            fontWeight: FontWeight.w700,
                            color: isBonusDay
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        SizedBox(height: ScreenCompatibility.responsiveHeight(context, 2.0)),
                        Text(
                          isBonusDay
                              ? 'Tebrikler! $bonusPoints bonus puan kazandınız 🎊'
                              : daysToBonus == 7
                                  ? '7 gün üst üste giriş yaparak bonus puan kazanın'
                                  : 'Üst üste $daysToBonus gün daha gir, $bonusPoints bonus puan kazan!',
                          style: GoogleFonts.inter(
                            fontSize: ScreenCompatibility.responsiveFontSize(
                              context,
                              isSmallScreen ? 10.0 :
                              screenSize == ScreenSizeCategory.medium ? 11.0 :
                              screenSize == ScreenSizeCategory.large ? 12.0 : 13.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: isBonusDay
                                ? Colors.white.withValues(alpha: 0.95)
                                : (isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Points badge
                  if (isBonusDay)
                    _buildBonusBadge(bonusPoints),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build advanced chain animation with 3D effects and particles
  Widget _buildAdvancedChainAnimation(int completedDays, bool isBonusDay, bool isDark) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final isCompleted = index < completedDays;
            final isCurrentDay = index == completedDays && completedDays > 0;
            final isBonus = isBonusDay && index == 6;
            final isLastLink = index == 6; // Son halka (7. gün)
            
            // Start animation when link becomes active
            if (isCurrentDay && !_linkControllers[index].isAnimating) {
              _linkControllers[index].forward();
            }
            
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: _buildAdvancedChainLink(
                        index: index,
                        isCompleted: isCompleted,
                        isCurrentDay: isCurrentDay,
                        isBonus: isBonus,
                        isLastLink: isLastLink,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: index < 6
                        ? _buildChainConnector(
                            isCompleted: isCompleted,
                            isDark: isDark,
                            index: index,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Build individual chain link with advanced effects
  Widget _buildAdvancedChainLink({
    required int index,
    required bool isCompleted,
    required bool isCurrentDay,
    required bool isBonus,
    required bool isLastLink,
    required bool isDark,
  }) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    final size = ScreenCompatibility.responsiveWidth(
      context,
      isSmallScreen ? 22.0 :
      screenSize == ScreenSizeCategory.medium ? 24.0 :
      screenSize == ScreenSizeCategory.large ? 26.0 : 28.0,
    );
    
    if (isBonus) {
      // Special celebration animation for bonus day
      return AnimatedBuilder(
        animation: Listenable.merge([_glowController, _particleController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glowing background
              Container(
                width: size + 6,
                height: size + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value * 0.8),
                      const Color(0xFFFF6347).withValues(alpha: _glowAnimation.value * 0.4),
                    ],
                  ),
                ),
              ),
              // Main link
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF6347),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: ScreenCompatibility.responsiveFontSize(context, 12.0),
                ),
              ),
              // Particle effects
              ...List.generate(8, (i) {
                final angle = (i * math.pi * 2) / 8;
                final radius = 20.0 + (_particleController.value * 10);
                return Transform.translate(
                  offset: Offset(
                    math.cos(angle + _particleController.value * 2) * radius,
                    math.sin(angle + _particleController.value * 2) * radius,
                  ),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withValues(
                        alpha: 1.0 - (_particleController.value * 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
    }
    
    if (isLastLink) {
      // Son halka (7. gün) - her zaman özel görünüm
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: size + 2,
            height: size + 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFFA500).withValues(alpha: 0.6),
                width: 2.5,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isCompleted
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: ScreenCompatibility.responsiveFontSize(context, 11.0),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.star_border_rounded,
                        color: const Color(0xFFFFA500).withValues(alpha: 0.5),
                        size: ScreenCompatibility.responsiveFontSize(context, 10.0),
                      ),
                    ),
                  ),
          );
        },
      );
    }
    
    if (isCompleted) {
      // Completed day - 3D effect with shimmer
      return AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _shimmerAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFCD34D),
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_shimmerAnimation.value, -1),
                            end: Alignment(_shimmerAnimation.value, 1),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Check icon
                  Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: ScreenCompatibility.responsiveFontSize(context, 10.0),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    if (isCurrentDay) {
      // Current day - pulsing with ripple effect
      return AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _linkControllers[index]]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect
              if (_linkControllers[index].value > 0)
                Container(
                  width: size + (_linkControllers[index].value * 15),
                  height: size + (_linkControllers[index].value * 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(
                        alpha: 1.0 - _linkControllers[index].value,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              // Main link
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(
                      alpha: 0.6 + (_pulseAnimation.value - 1.0) * 0.4,
                    ),
                    width: 2.5,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.radio_button_checked_rounded,
                  color: const Color(0xFFF59E0B),
                  size: ScreenCompatibility.responsiveFontSize(context, 9.0),
                ),
              ),
            ],
          );
        },
      );
    }
    
    // Future day - subtle outline
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.15),
          width: 2,
        ),
        color: Colors.transparent,
      ),
    );
  }

  /// Build fire icon with intensity based on streak
  Widget _buildFireIcon(int completedDays, bool isDark) {
    final intensity = (completedDays / 7.0).clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: Color.lerp(
              isDark ? Colors.white70 : Colors.black54,
              const Color(0xFFF59E0B),
              intensity,
            ),
            size: ScreenCompatibility.responsiveFontSize(
              context,
              14.0 + (intensity * 3),
            ),
          ),
        );
      },
    );
  }

  /// Build celebration icon for bonus day
  Widget _buildCelebrationIcon() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value * 0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.celebration_rounded,
            color: Colors.white,
            size: ScreenCompatibility.responsiveFontSize(context, 16.0),
          ),
        );
      },
    );
  }

  /// Build bonus badge
  Widget _buildBonusBadge(int points) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: ScreenCompatibility.responsivePadding(
            context,
            EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : 10.0,
              vertical: isSmallScreen ? 5.0 : 6.0,
            ),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(
              ScreenCompatibility.responsiveWidth(context, 8.0),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value * 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: Colors.white,
                size: ScreenCompatibility.responsiveFontSize(context, 12.0),
              ),
              SizedBox(width: ScreenCompatibility.responsiveWidth(context, 4.0)),
              Text(
                '+${NumberFormat('#,###').format(points)}',
                style: GoogleFonts.inter(
                  fontSize: ScreenCompatibility.responsiveFontSize(
                    context,
                    isSmallScreen ? 11.0 : 12.0,
                  ),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build professional chain connector between links
  Widget _buildChainConnector({
    required bool isCompleted,
    required bool isDark,
    required int index,
  }) {
    final screenSize = ScreenCompatibility.getScreenSizeCategory(context);
    final isSmallScreen = ScreenCompatibility.isSmallScreen(context);
    final connectorHeight = ScreenCompatibility.responsiveHeight(
      context,
      isSmallScreen ? 2.0 :
      screenSize == ScreenSizeCategory.medium ? 2.5 :
      screenSize == ScreenSizeCategory.large ? 3.0 : 3.0,
    );
    
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: connectorHeight,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Base line
              Container(
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFFCD34D).withValues(alpha: 0.8),
                            const Color(0xFFF59E0B).withValues(alpha: 0.9),
                            const Color(0xFFD97706).withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        )
                      : null,
                  color: isCompleted
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              // Shimmer effect for completed connectors
              if (isCompleted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnimation.value - 1, 0),
                        end: Alignment(_shimmerAnimation.value, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              // Animated pulse for active connectors
              if (isCompleted)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        gradient: RadialGradient(
                          center: Alignment(_pulseAnimation.value - 1, 0),
                          radius: 2,
                          colors: [
                            const Color(0xFFF59E0B).withValues(
                              alpha: 0.3 * (2 - _pulseAnimation.value),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build advanced progress bar with gradient
  Widget _buildAdvancedProgressBar(double progress, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          // Background
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Progress with gradient
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFCD34D),
                        const Color(0xFFF59E0B),
                        const Color(0xFFD97706),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shimmer effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnimation.value, 0),
                              end: Alignment(_shimmerAnimation.value + 0.5, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
