import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/cash_account_provider.dart';
import '../../core/providers/debit_card_provider.dart';
import '../../core/providers/credit_card_provider.dart';
import '../../core/events/card_events.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import 'tabs/cash_tab.dart';
import 'tabs/debit_cards_tab.dart';
import 'tabs/credit_cards_tab.dart';
import 'services/cash_management_service.dart';
import 'widgets/add_debit_card_form.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      animationDuration: const Duration(milliseconds: 300),
    );
    
    // 🔔 Card event listener'larını kur
    _setupCardEventListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupCardEventListeners() {
    // Credit card events
    cardEvents.listen<CreditCardAdded>((event) {
      if (mounted) {
        _showEventSnackBar('Kredi kartı eklendi: ${event.creditCard.cardName}', isSuccess: true);
      }
    });
    
    cardEvents.listen<CreditCardUpdated>((event) {
      if (mounted) {
        _showEventSnackBar('Kredi kartı güncellendi: ${event.newCard.cardName}', isSuccess: true);
      }
    });
    
    cardEvents.listen<CreditCardDeleted>((event) {
      if (mounted) {
        _showEventSnackBar('Kredi kartı silindi', isSuccess: true);
      }
    });
    
    cardEvents.listen<CreditCardBalanceUpdated>((event) {
      if (mounted) {
        final changeText = event.changeAmount > 0 ? '+${event.changeAmount.toStringAsFixed(2)}' : '${event.changeAmount.toStringAsFixed(2)}';
        _showEventSnackBar('Kredi kartı bakiyesi güncellendi ($changeText ₺)', isSuccess: true);
      }
    });
    
    // Debit card events
    cardEvents.listen<DebitCardAdded>((event) {
      if (mounted) {
        _showEventSnackBar('Banka kartı eklendi: ${event.debitCard.cardName}', isSuccess: true);
      }
    });
    
    cardEvents.listen<DebitCardUpdated>((event) {
      if (mounted) {
        _showEventSnackBar('Banka kartı güncellendi: ${event.newCard.cardName}', isSuccess: true);
      }
    });
    
    cardEvents.listen<DebitCardDeleted>((event) {
      if (mounted) {
        _showEventSnackBar('Banka kartı silindi', isSuccess: true);
      }
    });
    
    cardEvents.listen<DebitCardBalanceUpdated>((event) {
      if (mounted) {
        final changeText = event.changeAmount > 0 ? '+${event.changeAmount.toStringAsFixed(2)}' : '${event.changeAmount.toStringAsFixed(2)}';
        _showEventSnackBar('Banka kartı bakiyesi güncellendi ($changeText ₺)', isSuccess: true);
      }
    });
    
    // Cash account events
    cardEvents.listen<CashAccountUpdated>((event) {
      if (mounted) {
        final changeText = event.changeAmount > 0 ? '+${event.changeAmount.toStringAsFixed(2)}' : '${event.changeAmount.toStringAsFixed(2)}';
        _showEventSnackBar('Nakit bakiyesi güncellendi ($changeText ₺)', isSuccess: true);
      }
    });
  }
  
  void _showEventSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAddCardForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddDebitCardForm(
          onSuccess: () {
            // Kartlar yeniden yüklenecek (provider otomatik günceller)
          },
        ),
      ),
    );
  }

  void _onFabPressed() {
    _showAddCardForm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
        return AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return AppPageScaffold(
              title: l10n.myCards,
              tabBar: AppTabBar(
                        controller: _tabController,
                        tabs: [
                  l10n.cash,
                  l10n.debit,
                  l10n.credit,
                ],
                          ),
              onRefresh: () async {
                // Tüm kartları yenile
                await Future.wait([
                  CashAccountProvider.instance.loadCashAccount(),
                  DebitCardProvider.instance.loadDebitCards(),
                  CreditCardProvider.instance.loadCreditCards(),
                ]);
              },
              body: SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                    // Cash Tab - artık gerçek verilerle çalışıyor
                        const CashTab(),
                        // Debit Cards Tab
                        DebitCardsTab(l10n: l10n),
                        // Credit Cards Tab
                        CreditCardsTab(l10n: l10n),
                      ],
                    ),
                  ),
            );
          },
          );
        },
    );
  }

  void _showCashManagement(BuildContext context) {
    final cashProvider = CashAccountProvider.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    CashManagementService.showCashManagementBottomSheet(
      context, 
      isDark, 
      cashProvider.balance, // Gerçek bakiye
      (difference) async {
        // Gerçek bakiye güncelleme fonksiyonu
        await cashProvider.updateCashBalance(difference);
      },
    );
  }
} 