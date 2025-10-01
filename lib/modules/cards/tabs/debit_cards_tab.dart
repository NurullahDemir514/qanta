import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/debit_card_widget.dart';
import '../widgets/edit_debit_card_form.dart';
import '../widgets/card_transaction_section.dart';
import '../../home/bottom_sheets/card_detail_bottom_sheet.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/account_model.dart';
import '../../../core/events/card_events.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/models/transaction_model.dart';
import '../widgets/add_debit_card_form.dart';

class DebitCardsTab extends StatefulWidget {
  final AppLocalizations l10n;

  const DebitCardsTab({
    super.key,
    required this.l10n
  });

  @override
  State<DebitCardsTab> createState() => _DebitCardsTabState();
}

class _DebitCardsTabState extends State<DebitCardsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final PageController _pageController = PageController(
    viewportFraction: 1.0, // Tam genişlik
  );
  int _currentPage = 0;
  VoidCallback? _providerListener;
  UnifiedProviderV2? _unifiedProviderV2;

  @override
  void initState() {
    super.initState();
    
    // Card event listener'larını başlat
    _setupCardEventListeners();
    
    // Provider referansını sakla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _unifiedProviderV2 = UnifiedProviderV2.instance;
        
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
    
    // Provider listener'ı hazırla (henüz ekleme)
    _providerListener = () {
      if (!mounted) {
        return;
      }
      try {
        final provider = _unifiedProviderV2;
        if (provider != null) {
          if (provider.debitCards.isEmpty) {
            setState(() {
              _currentPage = 0;
            });
          } else if (_currentPage >= provider.debitCards.length) {
            setState(() {
              _currentPage = provider.debitCards.length - 1;
            });
          }
        }
      } catch (e) {
        // debugPrint('Provider listener error: $e');
      }
    };
  }

  /// Card event listener'larını başlat
  void _setupCardEventListeners() {
    // Debit card events
    cardEvents.listen<DebitCardAdded>((event) {
      if (mounted) {
        // Yeni kart eklendi - sayfa güncellenmesi provider listener'ı ile halledilecek
      }
    });
    
    cardEvents.listen<DebitCardUpdated>((event) {
      if (mounted) {
        // Kart güncellendi - provider listener'ı ile halledilecek
      }
    });
    
    cardEvents.listen<DebitCardDeleted>((event) {
      if (mounted) {
        // Kart silindi - sayfa güncellenmesi provider listener'ı ile halledilecek
        
        // Eğer silinen kart şu anki sayfadaysa, sayfa pozisyonunu ayarla
        final provider = _unifiedProviderV2;
        if (provider != null && provider.debitCards.isNotEmpty) {
          if (_currentPage >= provider.debitCards.length) {
            setState(() {
              _currentPage = provider.debitCards.length - 1;
            });
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          // Hiç kart kalmadıysa
          setState(() {
            _currentPage = 0;
          });
        }
      }
    });
    
    cardEvents.listen<DebitCardBalanceUpdated>((event) {
      if (mounted) {
        // Bakiye güncellendi - provider listener'ı ile halledilecek
      }
    });
    
    // Test event emit et (listener'ların çalışıp çalışmadığını kontrol etmek için)
    Future.delayed(Duration(seconds: 2), () {
      // Test için sahte bir event emit et
      // cardEvents.emitDebitCardDeleted(cardId: 'test-card-id', deletedCard: null);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_providerListener != null && _unifiedProviderV2 != null) {
      try {
        _unifiedProviderV2!.removeListener(_providerListener!);
      } catch (e) {
        // debugPrint('Error removing provider listener: $e');
      }
    }
    super.dispose();
  }

  void _showCardDetail(BuildContext context, card, ThemeProvider themeProvider, bool isDark) {
    final gradientColors = AppConstants.getBankGradientColors(card['bankCode'] ?? 'qanta');
    final accentColor = AppConstants.getBankAccentColor(card['bankCode'] ?? 'qanta');
    
    CardDetailBottomSheet.show(
      context,
      card['cardName'] ?? AppConstants.getBankName(card['bankCode'] ?? 'qanta'),
      widget.l10n.debit,
      card['maskedCardNumber'] ?? '**** **** **** ****',
      card['balance']?.toDouble() ?? 0.0,
      gradientColors,
      accentColor,
      themeProvider,
      isDark,
    );
  }

  void _showCardActions(BuildContext context, card) {
    HapticFeedback.mediumImpact();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          card['cardName'] ?? AppConstants.getBankName(card['bankCode'] ?? 'qanta'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          'Banka Kartı',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCard(card);
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
              _showDeleteConfirmation(card);
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
                  AppLocalizations.of(context)?.delete ?? 'Delete',
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
            AppLocalizations.of(context)?.cancel ?? 'Cancel',
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

  void _showDeleteConfirmation(card) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Kartı Sil',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          '${card['cardName'] ?? AppConstants.getBankName(card['bankCode'] ?? 'qanta')} kartını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(card);
            },
            child: Text(
              'Sil',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)?.cancel ?? 'Cancel',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _editCard(card) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EditDebitCardForm(
          debitCard: card,
          onSuccess: () {
            // Kartlar yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }

  void _deleteCard(card) async {
    HapticFeedback.heavyImpact();
    
    try {
      
      if (card['id'] == null || card['id'].toString().isEmpty) {
        return;
      }
      
      final success = await _unifiedProviderV2!.deleteDebitCard(card['id']);
      
      // Başarı snackbarı kaldırıldı
      // if (success && mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'Kart başarıyla silindi',
      //         style: GoogleFonts.inter(
      //           fontSize: 14,
      //           fontWeight: FontWeight.w500,
      //           color: Colors.white,
      //         ),
      //       ),
      //       backgroundColor: const Color(0xFF34C759),
      //       behavior: SnackBarBehavior.floating,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(12),
      //       ),
      //     ),
      //   );
      // }
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
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    return ListenableBuilder(
      listenable: UnifiedProviderV2.instance,
      builder: (context, child) {
        final unifiedProviderV2 = UnifiedProviderV2.instance;
        if (unifiedProviderV2.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hata oluştu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  unifiedProviderV2.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => unifiedProviderV2.loadDebitCards(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFB3),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Tekrar Dene',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }
    
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // Transaction list'in arkadan kayabilmesi için
              child: Column(
                children: [
                  // Banka kartları veya Empty State
                  if (unifiedProviderV2.debitCards.isNotEmpty) ...[
                    // Tam genişlik kart görünümü
                    SizedBox(
                      height: 180, // Kredi kartı ile aynı yükseklik
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: unifiedProviderV2.debitCards.length,
                        itemBuilder: (context, index) {
                          final card = unifiedProviderV2.debitCards[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => _showCardDetail(context, card, themeProvider, isDark),
                              onLongPress: () => _showCardActions(context, card),
                              child: SizedBox(
                                width: double.infinity,
                                height: 180, // Kredi kartı ile aynı yükseklik
                                child: DebitCardWidget(
                                  card: card,
                                  onTap: () => _showCardDetail(context, card, themeProvider, isDark),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),
                  
                  // Sayfa göstergesi (dots)
                  if (unifiedProviderV2.debitCards.length > 1)
                    Center(
                      child: SizedBox(
                        height: 8,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: unifiedProviderV2.debitCards.length,
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
                  if (unifiedProviderV2.debitCards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CardTransactionSection(
                        cardId: unifiedProviderV2.debitCards[_currentPage.clamp(0, (unifiedProviderV2.debitCards.length - 1).clamp(0, 999))]['id'],
                        cardName: unifiedProviderV2.debitCards[_currentPage.clamp(0, (unifiedProviderV2.debitCards.length - 1).clamp(0, 999))]['cardName'],
                      ),
                    ),
                  ] else ...[
                    // Kart yoksa empty state - kart alanının yerine
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
                            'Banka Kartı Yok',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Banka kartı eklemek için + butonuna dokunun',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

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