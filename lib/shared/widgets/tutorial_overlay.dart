import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../models/tutorial_step_model.dart';
import '../../core/services/tutorial_service.dart';
import '../utils/fab_positioning.dart';

/// Tutorial Overlay
/// Spotlight efektli tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onTutorialCompleted;
  final VoidCallback? onTutorialSkipped;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onTutorialCompleted,
    this.onTutorialSkipped,
  });

  /// Show tutorial overlay
  static Future<void> show(
    BuildContext context,
    List<TutorialStep> steps, {
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
  }) async {
    if (steps.isEmpty) return;

    // Wait for target widgets to render
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TutorialOverlay(
            steps: steps,
            onTutorialCompleted: onCompleted,
            onTutorialSkipped: onSkipped,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _overlayController;
  late AnimationController _tooltipController;
  late Animation<double> _overlayAnimation;
  late Animation<Offset> _tooltipAnimation;

  @override
  void initState() {
    super.initState();

    // Overlay fade animation
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Tooltip slide animation
    _tooltipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    );

    _tooltipAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tooltipController,
        curve: Curves.easeOut,
      ),
    );

    // Tutorial'ı aktif olarak işaretle
    TutorialService.setTutorialActive(true, stepId: _currentStep.id);

    // Start animations
    _overlayController.forward();
    _tooltipController.forward();
    
    // Scroll to first step's target widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _scrollToFirstStep();
    });
  }
  
  /// Scroll to first step's target widget
  Future<void> _scrollToFirstStep() async {
    final targetKey = _currentStep.targetKey;
    final context = targetKey.currentContext;
    
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
      
      // Widget'ın render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {}); // Tooltip'i göster
      }
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  TutorialStep get _currentStep => widget.steps[_currentStepIndex];

  void _nextStep() async {
    if (_currentStepIndex < widget.steps.length - 1) {
      // Önce scroll yap, sonra step'i güncelle
      await _scrollToNextStep();
      
      setState(() {
        _currentStepIndex++;
        _tooltipController.reset();
        _tooltipController.forward();
        // Tutorial step'ini güncelle
        TutorialService.setTutorialActive(true, stepId: _currentStep.id);
      });
    } else {
      _completeTutorial();
    }
  }
  
  /// Scroll to next step's target widget before showing tooltip
  Future<void> _scrollToNextStep() async {
    if (_currentStepIndex + 1 >= widget.steps.length) return;
    
    final nextStep = widget.steps[_currentStepIndex + 1];
    final targetKey = nextStep.targetKey;
    final context = targetKey.currentContext;
    
    if (context != null) {
      // Scroll animation'ı başlat
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.25, // Widget'ı ekranın üst %25'ine hizala (tooltip için yer bırak)
      );
      
      // Scroll tamamlandıktan sonra widget'ın render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Widget'ın görünür olduğunu kontrol et
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenSize = MediaQuery.of(context).size;
        
        // Widget ekranda görünür mü kontrol et
        if (position.dy < -50 || position.dy > screenSize.height + 50) {
          // Hala görünür değil, tekrar scroll yap
          await Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.25,
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } else {
      // Context yoksa, widget'ın render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
  
  /// Scroll to current step's target widget (previous için)
  void _scrollToTarget() {
    final targetKey = _currentStep.targetKey;
    final context = targetKey.currentContext;
    
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _tooltipController.reset();
        _tooltipController.forward();
        // Tutorial step'ini güncelle
        TutorialService.setTutorialActive(true, stepId: _currentStep.id);
      });
      
      // Scroll to previous step's target widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTarget();
      });
    }
  }

  Future<void> _completeTutorial() async {
    // Complete current step
    await TutorialService.completeStep(_currentStep.id);
    await TutorialService.completeTutorial();
    
    // Tutorial'ı inaktif olarak işaretle
    TutorialService.setTutorialActive(false);

    // Callback
    _currentStep.onStepCompleted?.call();

    // Exit animation
    await _tooltipController.reverse();
    await _overlayController.reverse();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTutorialCompleted?.call();
    }
  }

  Future<void> _skipTutorial() async {
    await TutorialService.skipTutorial();
    
    // Tutorial'ı inaktif olarak işaretle
    TutorialService.setTutorialActive(false);

    // Exit animation
    await _tooltipController.reverse();
    await _overlayController.reverse();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTutorialSkipped?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _overlayAnimation,
        child: Stack(
          children: [
            // Dark overlay with spotlight cutout
            IgnorePointer(
              ignoring: false,
              child:               CustomPaint(
                painter: _SpotlightPainter(
                  targetKey: _currentStep.targetKey,
                  context: context,
                  hideFABs: _currentStep.id == 'recent_transactions_tutorial', // Recent Transactions için FAB'ları gizle
                  stepId: _currentStep.id, // Step ID'yi geçir (Profile Avatar offset için)
                ),
                size: Size.infinite,
              ),
            ),
            
            // Tooltip card
            _buildTooltip(l10n, isDark),

            // Navigation buttons
            _buildNavigation(l10n, isDark),

            // Skip button (sağ üstte)
            _buildSkipButton(l10n, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(AppLocalizations l10n, bool isDark) {
    final RenderBox? renderBox = _currentStep.targetKey.currentContext
        ?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      // Widget henüz render olmadıysa bekle
      // Recent Transactions gibi scroll gereken widget'lar için daha fazla bekleme
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {}); // Rebuild to try again
        }
      });
      return const SizedBox.shrink();
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position - Dinamik positioning (Cards Section için optimize)
    double tooltipTop;
    double tooltipLeft = 16;
    double tooltipRight = 16;
    double tooltipWidth = screenSize.width - 32;
    
    // Tooltip yüksekliği (approximate)
    const double tooltipHeight = 180;
    
    // Target widget'ın ekrandaki pozisyonunu al
    final targetTop = position.dy;
    final targetBottom = position.dy + size.height;
    final targetCenter = targetTop + (size.height / 2);
    final targetWidth = size.width;
    final targetHeight = size.height;
    
    // Widget büyüklüğüne göre strateji belirle
    final isLargeWidget = targetWidth > screenSize.width * 0.7 || targetHeight > screenSize.height * 0.4;
    final isSmallWidget = targetWidth < 100 && targetHeight < 100;

    switch (_currentStep.position) {
      case TutorialPosition.top:
        // Widget'ın üstünde, kesinlikle bindirmeme
        tooltipTop = targetTop - tooltipHeight - 24;
        break;
      case TutorialPosition.bottom:
        // Widget'ın altında - Recent Transactions gibi büyük widget'lar için optimize
        if (isLargeWidget) {
          // Büyük widget için üstüne göster (ekranda yer yoksa)
          final availableSpaceBelow = screenSize.height - targetBottom - 200; // Navigation + padding
          if (availableSpaceBelow < tooltipHeight + 50) {
            tooltipTop = targetTop - tooltipHeight - 24;
          } else {
            tooltipTop = targetBottom + 24;
          }
        } else {
          tooltipTop = targetBottom + 24;
        }
        break;
      case TutorialPosition.left:
      case TutorialPosition.right:
      case TutorialPosition.center:
        // Widget'ın yanında veya ortada - merkeze göre hizala
        if (isLargeWidget) {
          // Büyük widget için altında göster
          tooltipTop = targetBottom + 24;
        } else {
          // Küçük widget için merkeze hizala
          tooltipTop = targetCenter - (tooltipHeight / 2);
        }
        break;
    }

    // Ensure tooltip doesn't overlap with target widget
    // Widget ile tooltip arasında minimum 20px boşluk olmalı
    if (tooltipTop + tooltipHeight > targetTop - 20 && tooltipTop < targetBottom + 20) {
      // Çakışma var, daha yukarı taşı
      if (_currentStep.position == TutorialPosition.top || isLargeWidget) {
        tooltipTop = targetTop - tooltipHeight - 40;
      } else {
        // Altında göster
        tooltipTop = targetBottom + 40;
      }
    }

    // Ensure tooltip doesn't go off screen
    if (tooltipTop < 16) {
      // Ekranın üstünden taşıyor, altına al
      tooltipTop = targetBottom + 24;
    }
    if (tooltipTop + tooltipHeight > screenSize.height - 100) {
      // Ekranın altından taşıyor, üstüne al
      tooltipTop = targetTop - tooltipHeight - 24;
    }
    
    // Son kontrol: Hala çakışma varsa, ekranın uygun yerine yerleştir
    if (tooltipTop < targetBottom + 20 && tooltipTop + tooltipHeight > targetTop - 20) {
      // Hala çakışıyor, en uygun yere yerleştir
      if (targetTop > screenSize.height / 2) {
        // Widget ekranın alt yarısında, tooltip'i üstüne koy
        tooltipTop = targetTop - tooltipHeight - 40;
      } else {
        // Widget ekranın üst yarısında, tooltip'i altına koy
        tooltipTop = targetBottom + 40;
      }
    }

    return Positioned(
      top: tooltipTop,
      left: tooltipLeft,
      right: tooltipRight,
      child: SlideTransition(
        position: _tooltipAnimation,
        child: _TooltipCard(
          step: _currentStep,
          l10n: l10n,
          isDark: isDark,
          arrowPosition: _currentStep.position,
          targetPosition: position,
          targetSize: size,
        ),
      ),
    );
  }

  /// FAB'ları gizlemek için overlay katmanı (Recent Transactions için)
  Widget _buildFABBlocker(AppLocalizations l10n, bool isDark) {
    final fabSize = FabPositioning.getFabSize(context);
    final rightPosition = FabPositioning.getRightPosition(context);
    final baseBottom = FabPositioning.getBottomPosition(context);
    
    return Stack(
      children: [
        // Transaction FAB'ı kapat (üstte, +60 offset)
        Positioned(
          right: rightPosition,
          bottom: baseBottom + 60, // Transaction FAB bottom pozisyonu
          child: Container(
            width: fabSize + 8,
            height: fabSize + 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85), // Overlay ile aynı renk
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // AI Chat FAB'ı kapat (altta)
        Positioned(
          right: rightPosition,
          bottom: baseBottom, // AI Chat FAB bottom pozisyonu
          child: Container(
            width: fabSize + 8,
            height: fabSize + 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85), // Overlay ile aynı renk
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(AppLocalizations l10n, bool isDark) {
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == widget.steps.length - 1;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: safeAreaBottom + 16, // En altta - safe area + padding
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          if (!isFirstStep)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                l10n.tutorialPrevious,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            const SizedBox(width: 80),

          // Next/Anladım button
          ElevatedButton(
            onPressed: isLastStep ? _completeTutorial : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D6D70),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isLastStep ? l10n.tutorialGotIt : l10n.tutorialNext,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(AppLocalizations l10n, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: TextButton(
        onPressed: _skipTutorial,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          l10n.tutorialSkip,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

}

/// Tooltip Card Widget
class _TooltipCard extends StatelessWidget {
  final TutorialStep step;
  final AppLocalizations l10n;
  final bool isDark;
  final TutorialPosition arrowPosition;
  final Offset targetPosition;
  final Size targetSize;

  const _TooltipCard({
    required this.step,
    required this.l10n,
    required this.isDark,
    required this.arrowPosition,
    required this.targetPosition,
    required this.targetSize,
  });

  /// Get title text based on step
  String _getTitleText() {
    try {
      switch (step.titleKey) {
        case 'tutorialBalanceOverviewTitle':
          return l10n.tutorialBalanceOverviewTitle;
        case 'tutorialTitle':
          return l10n.tutorialTitle;
        case 'tutorialRecentTransactionsTitle':
          return l10n.tutorialRecentTransactionsTitle;
        case 'tutorialAIChatTitle':
          return l10n.tutorialAIChatTitle;
        case 'tutorialCardsTitle':
          return l10n.tutorialCardsTitle;
        case 'tutorialBottomNavigationTitle':
          return l10n.tutorialBottomNavigationTitle;
        case 'tutorialBudgetTitle':
          return l10n.tutorialBudgetTitle;
        case 'tutorialProfileTitle':
          return l10n.tutorialProfileTitle;
        default:
          debugPrint('⚠️ Unknown titleKey: ${step.titleKey}');
          return l10n.tutorialTitle;
      }
    } catch (e) {
      debugPrint('❌ Error getting title: $e for key: ${step.titleKey}');
      return l10n.tutorialTitle;
    }
  }

  /// Get description text based on step
  String _getDescriptionText() {
    try {
      switch (step.descriptionKey) {
        case 'tutorialBalanceOverviewDescription':
          return l10n.tutorialBalanceOverviewDescription;
        case 'tutorialDescription':
          return l10n.tutorialDescription;
        case 'tutorialRecentTransactionsDescription':
          return l10n.tutorialRecentTransactionsDescription;
        case 'tutorialAIChatDescription':
          return l10n.tutorialAIChatDescription;
        case 'tutorialCardsDescription':
          return l10n.tutorialCardsDescription;
        case 'tutorialBottomNavigationDescription':
          return l10n.tutorialBottomNavigationDescription;
        case 'tutorialBudgetDescription':
          return l10n.tutorialBudgetDescription;
        case 'tutorialProfileDescription':
          return l10n.tutorialProfileDescription;
        default:
          debugPrint('⚠️ Unknown descriptionKey: ${step.descriptionKey}');
          return l10n.tutorialDescription;
      }
    } catch (e) {
      debugPrint('❌ Error getting description: $e for key: ${step.descriptionKey}');
      return l10n.tutorialDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              if (step.icon != null) ...[
                Icon(
                  step.icon,
                  size: 24,
                  color: const Color(0xFF6D6D70),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _getTitleText(),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            _getDescriptionText(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Spotlight Painter - Dark overlay with cutout (glow/shadow yok)
class _SpotlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final BuildContext context;
  final bool hideFABs; // FAB'ları gizle (Recent Transactions için)
  final String? stepId; // Step ID (Profile Avatar offset için)

  _SpotlightPainter({
    required this.targetKey,
    required this.context,
    this.hideFABs = false,
    this.stepId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay paint - daha koyu
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Get target widget position
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      // No target, draw full dark overlay
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Create cutout area with padding - Dinamik padding
    // Recent Transactions için daha fazla padding (yüksek çerçeve)
    final basePadding = 8.0;
    final isRecentTransactions = targetSize.height > 300; // Recent Transactions büyük widget
    final dynamicPadding = isRecentTransactions
        ? basePadding * 4.0  // Recent Transactions için çok fazla padding (yüksek çerçeve)
        : targetSize.width > 200 
            ? basePadding * 0.5  // Büyük widget için az padding
            : basePadding * 1.5; // Küçük widget için fazla padding
    
    // Profile Avatar için dinamik ve doğru çerçeveleme
    double offsetX = 0.0;
    double offsetY = 0.0;
    double profilePadding = dynamicPadding;
    
    if (stepId == 'profile_avatar_tutorial') {
      // Widget'ın gerçek görünür alanını hesapla (border, shadow dahil)
      // ProfileAvatar widget'ı genellikle 44px (HomeScreen'de), border 2px, shadow ~8px
      final borderWidth = 2.0;
      final shadowBlur = 8.0;
      final effectiveSize = targetSize.width + (borderWidth * 2) + (shadowBlur * 2);
      
      // Ekran boyutuna göre dinamik offset hesapla
      // Küçük ekranlar için daha az offset, büyük ekranlar için daha fazla
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;
      
      // Widget'ın ekrandaki konumunu kontrol et
      final isTopRight = position.dx > screenWidth * 0.65;
      final isTop = position.dy < screenHeight * 0.15;
      
      // Ekran kenarına olan mesafe
      final distanceFromRight = screenWidth - (position.dx + targetSize.width);
      final distanceFromTop = position.dy;
      
      if (isTopRight && isTop) {
        // Sağ üst köşede - çerçeveyi widget'ın görünür alanını tam kapsayacak şekilde ayarla
        // Offset: widget'ın görünür alanına göre dinamik hesapla
        // Çerçeve widget'ın merkezinden biraz sola ve yukarı kaymalı
        offsetX = -(effectiveSize * 0.2).clamp(-15.0, -10.0); // Sola kaydır (negatif)
        offsetY = -(effectiveSize * 0.2).clamp(-15.0, -10.0); // Yukarı kaydır (negatif)
        
        // Padding'i de widget boyutuna göre ayarla (küçük widget için daha fazla padding)
        profilePadding = (effectiveSize * 0.15).clamp(6.0, 12.0);
        
        // Ekran kenarına çok yakınsa offset'i azalt
        if (distanceFromRight < 20) {
          offsetX = offsetX * 0.8; // Sola kaydırmayı biraz azalt
        }
        if (distanceFromTop < 20) {
          offsetY = offsetY * 0.8; // Yukarı kaydırmayı biraz azalt
        }
      } else {
        // Başka konumlarda standart offset
        offsetX = (targetSize.width * 0.3).clamp(20.0, 30.0);
        offsetY = (targetSize.height * 0.3).clamp(20.0, 30.0);
      }
    }
    
    // Profile Avatar için özel padding kullan, diğerleri için dinamik padding
    final finalPadding = stepId == 'profile_avatar_tutorial' ? profilePadding : dynamicPadding;
    
    final cutoutRect = Rect.fromLTWH(
      position.dx - finalPadding + offsetX, // Dinamik sağa kaydır
      position.dy - finalPadding + offsetY, // Dinamik aşağı kaydır
      targetSize.width + (finalPadding * 2),
      targetSize.height + (finalPadding * 2),
    );

    // Draw full dark overlay first
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create cutout path (spotlight) - rounded rectangle
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cutoutRect,
          const Radius.circular(12),
        ),
      );

    // FAB'ları gizle (Recent Transactions için) - FAB pozisyonlarını overlay ile kapat
    // FAB'lar overlay'in altında olduğu için zaten görünmez, ekstra bir şey yapmaya gerek yok

    // Combine paths: full path MINUS cutout = dark overlay with hole
    final resultPath = Path.combine(
      PathOperation.difference,
      fullPath,
      cutoutPath,
    );

    // Draw the result (dark overlay with cutout)
    canvas.drawPath(resultPath, darkPaint);
    
    // NO glow, NO shadow, NO anything else - FAB is completely clear
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

