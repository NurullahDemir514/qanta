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

class _CashTabState extends State<CashTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
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
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, providerV2, child) {
        // Get cash accounts from v2 provider
        final cashAccounts = providerV2.accounts.where((a) => a.type == AccountType.cash).toList();
        final hasCashAccount = cashAccounts.isNotEmpty;
        final cashBalance = hasCashAccount ? cashAccounts.first.balance : 0.0;
        
        // Loading durumunda normal UI göster
        // if (providerV2.isLoading) {
        //   return _buildLoadingSkeleton(themeProvider);
        // }

        // Error durumunda retry butonu göster
        if (providerV2.error != null) {
          return _buildErrorState(providerV2, l10n);
        }

        // Normal UI - Cash account should always exist due to auto-creation
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (hasCashAccount) ...[
              // Cash Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      // Direkt güncelleme dialog'u aç
                      CashManagementService.showDirectUpdateDialog(
                        context,
                        cashBalance,
                        (newBalance) {
                          // Balance updated callback - provider will automatically update
                        },
                      );
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
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              
              // Cash Transactions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CardTransactionSection(
                    cardId: cashAccounts.first.id,
                    cardName: cashAccounts.first.name,
                  ),
                ),
              ),
            ] else ...[
              // Empty state - cash account yoksa (çok nadir durum)
              const SliverToBoxAdapter(
                child: SizedBox(height: 60), // Üstten boşluk (diğer tab'larla aynı)
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nakit Hesabı Yok',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nakit hesabınız bulunamadı',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
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
              providerV2.error?.toString() ?? 'Bilinmeyen hata',
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