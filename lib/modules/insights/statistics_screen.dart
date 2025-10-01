import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_page_scaffold.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  late AppLocalizations l10n;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  String _getStatisticsSubtitle() {
    return l10n.analyzeYourFinances;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppPageScaffold(
      title: l10n.statistics,
      subtitle: _getStatisticsSubtitle(),
      titleFontSize: 20,
      subtitleFontSize: 12,
      body: SliverFillRemaining(
        child: _buildComingSoonScreen(isDark),
      ),
    );
  }

  Widget _buildComingSoonScreen(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
          // Minimal ikon
                                  Icon(
            Icons.analytics_outlined,
            size: 64,
            color: isDark 
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6D6D70),
          ),
          
          const SizedBox(height: 32),
          
          // Basit başlık
                              Text(
            l10n.comingSoon,
                                style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 1.2,
                              ),
              textAlign: TextAlign.center,
                            ),
          
                                  const SizedBox(height: 16),
          
          // Minimal açıklama
                                      Text(
            l10n.analysisFeaturesInDevelopment,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Şık animasyonlu loading
          _buildElegantLoading(isDark),
        ],
      ),
    );
  }

  Widget _buildElegantLoading(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
      children: [
                // Dış halka - dönen
                Positioned.fill(
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark 
                          ? const Color(0xFF8E8E93).withOpacity(0.2)
                          : const Color(0xFF6D6D70).withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                // Orta halka - ters yönde dönen
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Transform.rotate(
                      angle: -_rotationAnimation.value * 2 * 3.14159,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark 
                            ? const Color(0xFF8E8E93).withOpacity(0.4)
                            : const Color(0xFF6D6D70).withOpacity(0.4),
                        ),
                    ),
                  ),
                ),
                ),
                // İç halka - hızlı dönen
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 4 * 3.14159,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                        ),
                      ),
                    ),
                  ),
                ),
                // Merkez nokta - pulsing
                Center(
                  child: Transform.scale(
                    scale: 0.5 + (_pulseAnimation.value - 0.8) * 0.5,
                    child: Container(
                      width: 6,
                      height: 6,
          decoration: BoxDecoration(
                        color: isDark 
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70)).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
               ),
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
    );
  }

} 