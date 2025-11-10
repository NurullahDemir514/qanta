import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/services/point_service.dart';
import '../../../core/services/amazon_reward_service.dart';
import '../../../shared/models/gift_card_provider_model.dart';
import '../providers/point_provider.dart';

/// Elegant multi-step gift card request flow
class ElegantGiftCardRequestFlow {
  static Future<bool> show(
    BuildContext context,
    int currentPoints, {
    GiftCardProviderConfig? providerConfig,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isDismissible: false,
      builder: (context) => _GiftCardRequestFlowSheet(
        currentPoints: currentPoints,
        providerConfig: providerConfig,
      ),
    );
    
    return result ?? false;
  }
}

class _GiftCardRequestFlowSheet extends StatefulWidget {
  final int currentPoints;
  final GiftCardProviderConfig? providerConfig;

  const _GiftCardRequestFlowSheet({
    required this.currentPoints,
    this.providerConfig,
  });

  @override
  State<_GiftCardRequestFlowSheet> createState() => _GiftCardRequestFlowSheetState();
}

class _GiftCardRequestFlowSheetState extends State<_GiftCardRequestFlowSheet>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  String _email = '';
  String? _emailError;
  String _phoneNumber = '';
  String? _phoneError;
  GiftCardProviderConfig? _selectedProvider;
  bool _isProcessing = false;
  double? _requestedAmount;
  int _selectedCardCount = 1; // Number of cards to request

  late AnimationController _slideController;
  late AnimationController _successController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Set default provider if provided, otherwise use Amazon
    _selectedProvider = widget.providerConfig ?? 
        GiftCardProviderConfig.getEnabledProviders().firstWhere(
          (p) => p.provider == GiftCardProvider.amazon,
          orElse: () => GiftCardProviderConfig.getEnabledProviders().first,
        );
    
    // If provider is pre-selected (from widget), skip provider selection step (step 0)
    // and start directly at email step (step 1)
    if (widget.providerConfig != null) {
      _currentStep = 1;
    }
    
    // Initialize card count based on available points
    _updateCardCount();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    if (_email.isEmpty) {
      setState(() {
        _emailError = 'Email adresi gerekli';
      });
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(_email)) {
      setState(() {
        _emailError = 'Geçerli bir email adresi girin';
      });
      return;
    }

    setState(() {
      _emailError = null;
    });
  }

  void _validatePhone() {
    if (_phoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Telefon numarası gerekli';
      });
      return;
    }

    // Turkish phone number validation (10 digits, can start with 0 or +90)
    final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
    final cleanedPhone = _phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (!phoneRegex.hasMatch(cleanedPhone) && cleanedPhone.length < 10) {
      setState(() {
        _phoneError = 'Geçerli bir telefon numarası girin (örn: 0555 123 45 67)';
      });
      return;
    }

    setState(() {
      _phoneError = null;
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate provider selection (if not pre-selected)
      if (_selectedProvider == null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir hediye kartı seçeneği seçin'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate email
      _validateEmail();
      if (_emailError != null) {
        HapticFeedback.mediumImpact();
        return;
      }
    } else if (_currentStep == 2) {
      // Validate phone (only for Paribu Cineverse)
      if (_needsPhoneNumber()) {
        _validatePhone();
        if (_phoneError != null) {
          HapticFeedback.mediumImpact();
          return;
        }
      }
    }

    HapticFeedback.selectionClick();
    setState(() {
      _currentStep++;
      // If provider doesn't need phone, skip phone step
      if (_currentStep == 2 && !_needsPhoneNumber()) {
        _currentStep = 3; // Skip to confirmation
      }
    });
  }

  /// Check if current provider needs phone number (only Paribu Cineverse)
  bool _needsPhoneNumber() {
    return _selectedProvider?.provider == GiftCardProvider.paribu;
  }

  /// Update card count based on available points and selected provider
  void _updateCardCount() {
    if (_selectedProvider == null) return;
    final requiredPoints = _selectedProvider!.requiredPoints;
    final maxCards = (widget.currentPoints / requiredPoints).floor().clamp(1, 10);
    if (_selectedCardCount > maxCards) {
      _selectedCardCount = maxCards;
    }
  }

  /// Get maximum cards user can select for current provider
  int _getMaxCards() {
    if (_selectedProvider == null) return 1;
    final requiredPoints = _selectedProvider!.requiredPoints;
    return (widget.currentPoints / requiredPoints).floor().clamp(1, 10);
  }

  void _previousStep() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentStep--;
      
      // If provider doesn't need phone, skip phone step when going back
      if (_currentStep == 2 && !_needsPhoneNumber()) {
        _currentStep = 1; // Go back to email step
      }
      
      // If provider is pre-selected, don't go back to provider selection step (step 0)
      // Close the sheet instead
      if (_currentStep < 1 || (_currentStep < 0 && widget.providerConfig != null)) {
        Navigator.of(context).pop(false);
      } else if (_currentStep < 0) {
        Navigator.of(context).pop(false);
      }
    });
  }

  Future<void> _processRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentStep = 4; // Loading step
    });

    HapticFeedback.mediumImpact();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Calculate amount and points based on selected provider
      if (_selectedProvider == null) {
        throw Exception('Hediye kartı seçeneği seçilmedi');
      }
      
      final requiredPoints = _selectedProvider!.requiredPoints;
      final totalPointsToSpend = _selectedCardCount * requiredPoints;
      final requestedAmount = _selectedCardCount * _selectedProvider!.giftCardAmount;

      setState(() {
        _requestedAmount = requestedAmount;
      });

      // Check balance
      final pointService = PointService();
      final balance = await pointService.getCurrentBalance(userId);
      if (balance < totalPointsToSpend) {
        throw Exception('Yetersiz puan bakiyesi');
      }

      // Spend points
      final success = await pointService.spendPoints(
        userId,
        totalPointsToSpend,
        '${_selectedProvider!.name} Hediye Kartı x$_selectedCardCount (${requestedAmount.toStringAsFixed(0)} TL)',
      );

      if (!success) {
        throw Exception('Puan harcama başarısız');
      }

      // Create gift card requests (one for each card)
      final amazonRewardService = AmazonRewardService();
      // Only send phone number for Paribu Cineverse
      final phoneToSend = _needsPhoneNumber() ? _phoneNumber : '';
      
      // Ensure provider value is always sent
      final providerValue = _selectedProvider!.provider.value;
      debugPrint('🎁 Creating gift card request with provider: $providerValue (${_selectedProvider!.name})');
      
      int successCount = 0;
      int failCount = 0;
      
      // Create a separate request for each card
      for (int i = 0; i < _selectedCardCount; i++) {
        final giftCardRequestSuccess = await amazonRewardService.createGiftCardRequestDirectly(
          userId,
          _email,
          _selectedProvider!.giftCardAmount,
          _selectedProvider!.requiredPoints,
          provider: providerValue, // Always send the actual provider value
          phoneNumber: phoneToSend,
        );
        
        if (giftCardRequestSuccess) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (successCount == 0) {
        throw Exception('Hediye kartı talebi başarısız oldu');
      }
      
      if (failCount > 0) {
        debugPrint('⚠️ Warning: $failCount out of ${successCount + failCount} requests failed');
      }

      // Refresh point balance
      final pointProvider = Provider.of<PointProvider>(context, listen: false);
      await pointProvider.refresh();

      // Show success
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _currentStep = 5; // Success step
      });

      _successController.forward();

      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });

      // Don't auto close - let user choose to request another card or close
    } catch (e) {
      debugPrint('❌ Error requesting gift card: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = 3; // Go back to confirmation step
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _closeSheet() {
    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final selectedProvider = _selectedProvider ?? 
        GiftCardProviderConfig.getEnabledProviders().firstWhere(
          (p) => p.provider == GiftCardProvider.amazon,
          orElse: () => GiftCardProviderConfig.getEnabledProviders().first,
        );
    final balanceInTL = widget.currentPoints / 200.0;
    final giftCardCount = (widget.currentPoints / selectedProvider.requiredPoints).floor();
    final maxGiftCards = giftCardCount.clamp(1, 10);
    final estimatedAmount = maxGiftCards * selectedProvider.giftCardAmount;
    final estimatedPoints = maxGiftCards * selectedProvider.requiredPoints;

    return GestureDetector(
      onTap: () {}, // Prevent tap through
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar with drag gesture
              GestureDetector(
                onTap: _closeSheet,
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Progress indicator - hide for loading and success steps
            Builder(
              builder: (context) {
                final actualStep = _getActualStep(_currentStep);
                if (actualStep == 'loading' || actualStep == 'success') {
                  return const SizedBox.shrink();
                }
                
                // Determine steps to show
                final showProviderStep = widget.providerConfig == null;
                final showPhoneStep = _needsPhoneNumber();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      if (showProviderStep) ...[
                        _buildProgressDot(context, 0, _currentStep >= 0, selectedProvider),
                        _buildProgressLine(context, _currentStep > 0, selectedProvider),
                      ],
                      _buildProgressDot(context, 1, _currentStep >= 1, selectedProvider),
                      if (showPhoneStep) ...[
                        _buildProgressLine(context, _currentStep > 1, selectedProvider),
                        _buildProgressDot(context, 2, _currentStep >= 2, selectedProvider),
                        _buildProgressLine(context, _currentStep > 2, selectedProvider),
                        _buildProgressDot(context, 3, _currentStep >= 3, selectedProvider),
                      ] else ...[
                        _buildProgressLine(context, _currentStep > 1, selectedProvider),
                        _buildProgressDot(context, 2, _currentStep >= 2, selectedProvider),
                      ],
                    ],
                  ),
                );
              },
            ),

            // Content with fade transition
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildStepContent(context, isDark, balanceInTL, estimatedAmount, estimatedPoints, selectedProvider),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, bool isDark, double balanceInTL, double estimatedAmount, int estimatedPoints, GiftCardProviderConfig provider) {
    // Determine actual step based on provider pre-selection and phone requirement
    final actualStep = _getActualStep(_currentStep);
    
    switch (actualStep) {
      case 'provider_selection':
        return _buildProviderSelectionStep(context, isDark, balanceInTL);
      case 'email':
        return _buildEmailStep(context, isDark, balanceInTL, provider);
      case 'phone':
        return _buildPhoneStep(context, isDark, provider);
      case 'confirmation':
        return _buildConfirmationStep(context, isDark, estimatedAmount, estimatedPoints, provider);
      case 'loading':
        return _buildLoadingStep(context, isDark, provider);
      case 'success':
        return _buildSuccessStep(context, isDark);
      default:
        return _buildEmailStep(context, isDark, balanceInTL, provider);
    }
  }
  
  /// Get actual step name based on current step number and configuration
  String _getActualStep(int step) {
    if (step == 0) {
      return widget.providerConfig == null ? 'provider_selection' : 'email';
    } else if (step == 1) {
      return 'email';
    } else if (step == 2) {
      // Phone step only for Paribu Cineverse
      return _needsPhoneNumber() ? 'phone' : 'confirmation';
    } else if (step == 3) {
      // If phone was skipped, this is confirmation, otherwise it's confirmation after phone
      return 'confirmation';
    } else if (step == 4) {
      return 'loading';
    } else if (step == 5) {
      return 'success';
    }
    return 'email';
  }

  Widget _buildProviderSelectionStep(BuildContext context, bool isDark, double balanceInTL) {
    final providers = GiftCardProviderConfig.getEnabledProviders()
        .where((p) => p.canRedeem(widget.currentPoints))
        .toList();
    
    if (providers.isEmpty) {
      return Column(
        key: const ValueKey('no_provider_step'),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Yetersiz Puan',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Henüz hiçbir hediye kartı için yeterli puanınız yok.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextButton(
              onPressed: _closeSheet,
              child: Text(
                'Kapat',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      key: const ValueKey('provider_selection_step'),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF9900).withValues(alpha: 0.2),
                      const Color(0xFFFFB84D).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFFFF9900),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hediye Kartı Seçin',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${balanceInTL.toStringAsFixed(2)} TL birikiminiz var!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hangi hediye kartını almak istiyorsunuz?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isSelected = _selectedProvider?.provider == provider.provider;
              final availableCards = provider.getAvailableGiftCards(widget.currentPoints);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedProvider = provider;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? provider.primaryColor.withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? provider.primaryColor
                          : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: provider.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          provider.iconPath,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.card_giftcard,
                              color: provider.primaryColor,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.giftCardAmount.toStringAsFixed(0)} TL • $availableCards adet alabilirsiniz',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: provider.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: provider.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedProvider != null ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedProvider?.primaryColor ?? const Color(0xFFFF9900),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFF9900).withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _selectedProvider != null ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Devam Et',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.providerConfig != null ? _closeSheet : _previousStep,
                child: Text(
                  widget.providerConfig != null ? 'İptal' : 'Geri Dön',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(BuildContext context, bool isDark, double balanceInTL, GiftCardProviderConfig provider) {
    // Get provider-specific email description
    String getEmailDescription() {
      switch (provider.provider) {
        case GiftCardProvider.amazon:
          return 'Amazon hesabınızın email adresini girin';
        case GiftCardProvider.paribu:
          return 'Paribu Cineverse hesabınızın email adresini girin';
        case GiftCardProvider.dnr:
          return 'D&R hesabınızın email adresini girin';
        case GiftCardProvider.gratis:
          return 'Gratis hesabınızın email adresini girin';
        default:
          return '${provider.name} hesabınızın email adresini girin';
      }
    }

    return Column(
      key: const ValueKey('email_step'),
      children: [
        // Compact Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      provider.primaryColor.withValues(alpha: 0.2),
                      provider.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: provider.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.name} Email Adresi',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getEmailDescription(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Email input
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _email = value;
                      if (_emailError != null) {
                        _validateEmail();
                      }
                    });
                  },
                  onEditingComplete: () {
                    _validateEmail();
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ornek@email.com',
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emailError != null
                            ? Colors.red
                            : Colors.transparent,
                        width: _emailError != null ? 1.5 : 0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emailError != null
                            ? Colors.red
                            : provider.primaryColor,
                        width: _emailError != null ? 2 : 2,
                      ),
                    ),
                    errorText: _emailError,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _emailError != null
                          ? Colors.red
                          : provider.primaryColor,
                      size: 20,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSubmitted: (_) {
                    _validateEmail();
                    if (_emailError == null) {
                      _nextStep();
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Action button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _email.isNotEmpty && _emailError == null
                      ? () {
                          _validateEmail();
                          if (_emailError == null) {
                            _nextStep();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        provider.primaryColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _email.isNotEmpty && _emailError == null ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Devam Et',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.providerConfig != null ? _closeSheet : _previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  widget.providerConfig != null ? 'İptal' : 'Geri Dön',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep(BuildContext context, bool isDark, GiftCardProviderConfig provider) {
    return Column(
      key: const ValueKey('phone_step'),
      children: [
        // Compact Header (same design as email step)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      provider.primaryColor.withValues(alpha: 0.2),
                      provider.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: provider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telefon Numarası',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hediye kartı kodunu gönderebilmek için telefon numaranızı girin',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Phone input
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _phoneNumber = value;
                      if (_phoneError != null) {
                        _validatePhone();
                      }
                    });
                  },
                  onEditingComplete: () {
                    _validatePhone();
                  },
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '0555 123 45 67',
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _phoneError != null
                            ? Colors.red
                            : Colors.transparent,
                        width: _phoneError != null ? 1.5 : 0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _phoneError != null
                            ? Colors.red
                            : provider.primaryColor,
                        width: _phoneError != null ? 2 : 2,
                      ),
                    ),
                    errorText: _phoneError,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: _phoneError != null
                          ? Colors.red
                          : provider.primaryColor,
                      size: 20,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSubmitted: (_) {
                    _validatePhone();
                    if (_phoneError == null) {
                      _nextStep();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Action button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _phoneNumber.isNotEmpty && _phoneError == null
                      ? () {
                          _validatePhone();
                          if (_phoneError == null) {
                            _nextStep();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        provider.primaryColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _phoneNumber.isNotEmpty && _phoneError == null ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Devam Et',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'Geri Dön',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(BuildContext context, bool isDark, double amount, int points, GiftCardProviderConfig provider) {
    
    return Column(
      key: const ValueKey('confirmation_step'),
      children: [
        // Compact Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talebinizi Onaylayın',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detayları kontrol edin',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Compact Details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Card count selector (if more than 1 card can be selected)
                if (_getMaxCards() > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          provider.primaryColor.withValues(alpha: 0.12),
                          provider.accentColor.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: provider.primaryColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Kart Sayısı',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        // Decrease button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectedCardCount > 1
                                ? () {
                                    setState(() {
                                      _selectedCardCount--;
                                    });
                                    HapticFeedback.selectionClick();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _selectedCardCount > 1
                                    ? provider.primaryColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedCardCount > 1
                                      ? provider.primaryColor.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                color: _selectedCardCount > 1
                                    ? provider.primaryColor
                                    : (isDark ? const Color(0xFF6D6D70) : const Color(0xFFA0A0A0)),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Number display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: provider.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: provider.primaryColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$_selectedCardCount',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: provider.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Increase button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectedCardCount < _getMaxCards()
                                ? () {
                                    setState(() {
                                      _selectedCardCount++;
                                    });
                                    HapticFeedback.selectionClick();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _selectedCardCount < _getMaxCards()
                                    ? provider.primaryColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedCardCount < _getMaxCards()
                                      ? provider.primaryColor.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: _selectedCardCount < _getMaxCards()
                                    ? provider.primaryColor
                                    : (isDark ? const Color(0xFF6D6D70) : const Color(0xFFA0A0A0)),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Compact details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompactDetailRow(
                        context,
                        provider.name,
                        '${(_selectedCardCount * provider.giftCardAmount).toStringAsFixed(0)} TL',
                        provider.primaryColor,
                      ),
                      const SizedBox(height: 10),
                      _buildCompactDetailRow(
                        context,
                        'Harcanacak Puan',
                        NumberFormat('#,###').format(_selectedCardCount * provider.requiredPoints),
                        Colors.green.shade500,
                      ),
                      const SizedBox(height: 10),
                      _buildCompactDetailRow(
                        context,
                        'Email',
                        _email,
                        const Color(0xFF007AFF),
                      ),
                      // Only show phone number for Paribu Cineverse
                      if (_needsPhoneNumber()) ...[
                        const SizedBox(height: 10),
                        _buildCompactDetailRow(
                          context,
                          'Telefon',
                          _phoneNumber,
                          const Color(0xFF34D399),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'İşleniyor...',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Onayla ve Gönder',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'Geri Dön',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStep(BuildContext context, bool isDark, GiftCardProviderConfig provider) {
    return Center(
      key: const ValueKey('loading_step'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        provider.primaryColor.withValues(alpha: 0.2),
                        provider.accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(provider.primaryColor),
                      strokeWidth: 4,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            '${provider.name} hediye kartı hazırlanıyor...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(BuildContext context, int step, bool isActive, GiftCardProviderConfig provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? provider.primaryColor : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildProgressLine(BuildContext context, bool isActive, GiftCardProviderConfig provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? provider.primaryColor : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6)),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context, bool isDark) {
    // Get provider color for success step
    final providerColor = _selectedProvider?.primaryColor ?? Colors.green;
    final providerAccentColor = _selectedProvider?.accentColor ?? Colors.green.shade700;
    
    return AnimatedBuilder(
      key: const ValueKey('success_step'),
      animation: _successController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon with animation and provider color
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          providerColor,
                          providerAccentColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: providerColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Başarılı!',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      _requestedAmount != null
                          ? '$_selectedCardCount adet ${_selectedProvider?.name ?? "hediye kartı"} talebiniz alındı! (${_requestedAmount!.toStringAsFixed(0)} TL)'
                          : 'Hediye kartı talebiniz alındı!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'E-posta adresinize gönderilecek',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedProvider?.primaryColor ?? const Color(0xFFFF9900),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Tamam',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

