import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/account_model.dart';
import '../../../core/events/card_events.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/models/transaction_model.dart';
import '../widgets/cash_balance_card.dart';
import '../widgets/card_transaction_section.dart';
import '../services/cash_management_service.dart';

class CashTab extends StatefulWidget {
  const CashTab({super.key});

  @override
  State<CashTab> createState() => _CashTabState();
}

class _CashTabState extends State<CashTab> {
  @override
  void initState() {
    super.initState();
    // Load all data from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
        provider.loadAllData();
      }
    });
    
    // 🔔 Cash account event listener'ını kur
    _setupCashEventListeners();
  }
  
  void _setupCashEventListeners() {
    cardEvents.listen<CashAccountUpdated>((event) {
      if (mounted) {
        // Nakit bakiyesi değiştiğinde UI'ı güncelle
        // Provider zaten notifyListeners() çağırıyor, bu sadece debug için
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, providerV2, child) {
        // Get cash accounts from v2 provider
        final cashAccounts = providerV2.accounts.where((a) => a.type == AccountType.cash).toList();
        final hasCashAccount = cashAccounts.isNotEmpty;
        final cashBalance = hasCashAccount ? cashAccounts.first.balance : 0.0;
        
        // Loading durumunda skeleton göster
        if (providerV2.isLoading) {
          return _buildLoadingSkeleton(themeProvider);
        }

        // Error durumunda retry butonu göster
        if (providerV2.error != null) {
          return _buildErrorState(providerV2, l10n);
        }

        // Normal UI - Cash account should always exist due to auto-creation
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Transaction list'in arkadan kayabilmesi için
          child: Column(
            children: [
              // Cash Balance Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    if (hasCashAccount) {
                      // Direkt güncelleme dialog'u aç
                      CashManagementService.showDirectUpdateDialog(
                        context,
                        cashBalance,
                        (newBalance) {
                          // Balance updated callback - provider will automatically update
                        },
                      );
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: CashBalanceCard(
                      balance: cashBalance,
                      themeProvider: themeProvider,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Cash Transactions Section
              if (hasCashAccount)
                CardTransactionSection(
                  cardId: cashAccounts.first.id,
                  cardName: cashAccounts.first.name,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(ThemeProvider themeProvider) {
    return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Loading skeleton for cash card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
                width: double.infinity,
                height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Loading skeleton for transactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TransactionDesignSystem.buildLoadingSkeleton(
              isDark: themeProvider.isDarkMode,
              itemCount: 3,
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(UnifiedProviderV2 providerV2, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cashAccountLoadError,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              providerV2.error ?? l10n.unknownError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => providerV2.loadAccounts(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
} 