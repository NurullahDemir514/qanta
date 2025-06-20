import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/events/card_events.dart';
import '../../home/widgets/credit_card_widget.dart';
import '../widgets/add_credit_card_form.dart';
import '../widgets/edit_credit_card_form.dart';
import '../widgets/card_transaction_section.dart';
import '../../home/bottom_sheets/card_detail_bottom_sheet.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';

class CreditCardsTab extends StatefulWidget {
  final AppLocalizations l10n;

  const CreditCardsTab({
    super.key,
    required this.l10n
  });

  @override
  State<CreditCardsTab> createState() => _CreditCardsTabState();
}

class _CreditCardsTabState extends State<CreditCardsTab> {
  final PageController _pageController = PageController(
    viewportFraction: 1.0, // Tam genişlik
  );
  int _currentPage = 0;
  VoidCallback? _providerListener;
  UnifiedProviderV2? _unifiedProviderV2;

  @override
  void initState() {
    super.initState();
    
    // Provider referansını sakla - SADECE REFERANS, YÜKLEMİYORUZ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _unifiedProviderV2 = UnifiedProviderV2.instance;
        // _creditCardProvider!.loadCreditCards(); // ← KALDIRILDI: Event'ler bakiyeyi güncelliyor
        
        // Provider listener'ı ekle
        if (_providerListener != null) {
          _unifiedProviderV2!.addListener(_providerListener!);
        }
      }
    });
    
    // Sayfa değişikliklerini dinle
    _pageController.addListener(() {
      if (!mounted) return;
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
    
    // 🔔 Credit card event listener'larını kur
    _setupCreditCardEventListeners();
    
    // Provider listener'ı hazırla (henüz ekleme)
    _providerListener = () {
      if (!mounted) return;
      try {
        final provider = _unifiedProviderV2;
        if (provider != null) {
          if (provider.creditCards.isEmpty) {
            setState(() {
              _currentPage = 0;
            });
          } else if (_currentPage >= provider.creditCards.length) {
            setState(() {
              _currentPage = provider.creditCards.length - 1;
            });
          }
        }
      } catch (e) {
        debugPrint('Provider listener error: $e');
      }
    };
  }

  void _setupCreditCardEventListeners() {
    cardEvents.listen<CreditCardAdded>((event) {
      if (mounted) {
        debugPrint('💳 Credit card added: ${event.creditCard.cardName}');
      }
    });
    
    cardEvents.listen<CreditCardUpdated>((event) {
      if (mounted) {
        debugPrint('💳 Credit card updated: ${event.newCard.cardName}');
      }
    });
    
    cardEvents.listen<CreditCardDeleted>((event) {
      if (mounted) {
        debugPrint('💳 Credit card deleted: ${event.cardId}');
      }
    });
    
    cardEvents.listen<CreditCardBalanceUpdated>((event) {
      if (mounted) {
        debugPrint('💳 Credit card balance updated: ${event.cardId} (${event.changeAmount})');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_providerListener != null && _unifiedProviderV2 != null) {
      try {
        _unifiedProviderV2!.removeListener(_providerListener!);
      } catch (e) {
        debugPrint('Error removing provider listener: $e');
      }
    }
    super.dispose();
  }

  void _showAddCreditCardForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddCreditCardForm(
          onSuccess: () {
            // Cards will be automatically updated via provider
          },
        ),
      ),
    );
  }

  void _showCardDetail(BuildContext context, creditCard, ThemeProvider themeProvider, bool isDark) {
    final gradientColors = AppConstants.getBankGradientColors(creditCard['bankCode'] ?? 'qanta');
    final accentColor = AppConstants.getBankAccentColor(creditCard['bankCode'] ?? 'qanta');
    
    CardDetailBottomSheet.show(
      context,
      creditCard['cardName'] ?? AppConstants.getBankName(creditCard['bankCode'] ?? 'qanta'),
      widget.l10n.credit,
      creditCard['formattedCardNumber'] ?? '**** **** **** ****',
      creditCard['availableLimit']?.toDouble() ?? 0.0,
      gradientColors,
      accentColor,
      themeProvider,
      isDark,
      totalDebt: creditCard['totalDebt']?.toDouble() ?? 0.0,
      creditLimit: creditCard['creditLimit']?.toDouble() ?? 0.0,
      usagePercentage: creditCard['usagePercentage']?.toDouble() ?? 0.0,
      statementDate: creditCard['statementDate'] ?? 1,
      dueDate: creditCard['dueDate'] ?? 15,
    );
  }

  void _showCardActions(BuildContext context, creditCard) {
    HapticFeedback.mediumImpact();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          creditCard['cardName'] ?? AppConstants.getBankName(creditCard['bankCode'] ?? 'qanta'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          creditCard['formattedCardNumber'] ?? '**** **** **** ****',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCard(creditCard);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Düzenle',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(creditCard);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sil',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(creditCard) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          'Kartı Sil',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${creditCard['cardName'] ?? AppConstants.getBankName(creditCard['bankCode'] ?? 'qanta')} kartını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'İptal',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemBlue,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'Sil',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.destructiveRed,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(creditCard);
            },
          ),
        ],
      ),
    );
  }

  void _editCard(creditCard) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EditCreditCardForm(
          creditCard: creditCard,
          onSuccess: () {
            // Kartlar yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }

  void _deleteCard(creditCard) async {
    HapticFeedback.heavyImpact();
    
    try {
      final success = await _unifiedProviderV2!.deleteCreditCard(creditCard['id']);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kart başarıyla silindi',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kart silinirken hata oluştu',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UnifiedProviderV2.instance,
      builder: (context, child) {
        final unifiedProviderV2 = UnifiedProviderV2.instance;
        if (unifiedProviderV2.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (unifiedProviderV2.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${unifiedProviderV2.error}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => unifiedProviderV2.retry(),
                  child: Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (unifiedProviderV2.creditCards.isEmpty) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60), // Üstten boşluk (CashTab ile aynı)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kredi Kartı Yok',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kredi kartı eklemek için + butonuna dokunun',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // CashTab ile aynı bottom spacing
              ],
            ),
          );
        }
    
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Üst seviye scroll'a bırak
              child: Column(
                children: [
                  // Kredi kartları tam genişlik
                  SizedBox(
                    height: 180, // Banka kartı ile aynı yükseklik
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: unifiedProviderV2.creditCards.length,
                      itemBuilder: (context, index) {
                        final creditCard = unifiedProviderV2.creditCards[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _showCardDetail(context, creditCard, themeProvider, isDark),
                            onLongPress: () => _showCardActions(context, creditCard),
                            child: SizedBox(
                              width: double.infinity,
                              height: 180, // Banka kartı ile aynı yükseklik
                              child: CreditCardWidget(
                                cardType: 'credit',
                                cardTypeLabel: AppConstants.getBankName(creditCard['bankCode'] ?? 'qanta'),
                                cardNumber: creditCard['formattedCardNumber'] ?? '**** **** **** ****',
                                balance: creditCard['availableLimit']?.toDouble() ?? 0.0,
                                bankCode: creditCard['bankCode'] ?? 'qanta',
                                totalDebt: creditCard['totalDebt']?.toDouble() ?? 0.0,
                                creditLimit: creditCard['creditLimit']?.toDouble() ?? 0.0,
                                usagePercentage: creditCard['usagePercentage']?.toDouble() ?? 0.0,
                                statementDate: creditCard['statementDate'] ?? 1,
                                dueDate: creditCard['dueDate'] ?? 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Sayfa göstergesi (dots)
                  if (unifiedProviderV2.creditCards.length > 1)
                    Center(
                      child: SizedBox(
                        height: 8,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: unifiedProviderV2.creditCards.length,
                          itemBuilder: (context, index) {
                            final isActive = index == _currentPage;
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive 
                                  ? (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)) // iOS System Gray
                                  : (isDark ? const Color(0xFF48484A) : const Color(0xFFAEAEB2)), // iOS System Gray 4/5
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 30), // CashTab ile aynı spacing
                  
                  // Aktif kartın son işlemleri
                  if (unifiedProviderV2.creditCards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CardTransactionSection(
                        cardId: unifiedProviderV2.creditCards.isNotEmpty 
                            ? unifiedProviderV2.creditCards[_currentPage.clamp(0, (unifiedProviderV2.creditCards.length - 1).clamp(0, 999))]['id']
                            : '',
                        cardName: unifiedProviderV2.creditCards.isNotEmpty 
                            ? unifiedProviderV2.creditCards[_currentPage.clamp(0, (unifiedProviderV2.creditCards.length - 1).clamp(0, 999))]['cardName'] ?? 'Kredi Kartı'
                            : '',
                      ),
                    ),
                  
                  const SizedBox(height: 20), // CashTab ile aynı bottom spacing
                ],
              ),
            );
          },
        );
      },
    );
  }
} 