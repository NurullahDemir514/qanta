import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../cards/widgets/cash_balance_card.dart';
import 'credit_card_widget.dart';
import '../../cards/widgets/debit_card_widget.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/utils/currency_utils.dart';

class CardsSection extends StatefulWidget {
  const CardsSection({super.key});

  @override
  State<CardsSection> createState() => _CardsSectionState();
}

class _CardsSectionState extends State<CardsSection> {
  late PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        return _buildV2CardsSection(context, providerV2, l10n, isDark);
      },
    );
  }

  /// Build cards section using V2 provider
  Widget _buildV2CardsSection(BuildContext context, UnifiedProviderV2 providerV2, AppLocalizations l10n, bool isDark) {
    // Convert V2 accounts to card format
    final allCards = <Map<String, dynamic>>[];
    
    // Add credit cards (already in legacy format)
    for (final card in providerV2.creditCards) {
      allCards.add({
        'cardType': 'credit',
        'cardTypeLabel': card['bankName'] ?? card['cardName'],
        'cardNumber': card['formattedCardNumber'] ?? '**** **** **** ${card['id'].substring(0, 4)}',
        'balance': card['availableLimit']?.toDouble() ?? 0.0, // Use provider's availableLimit directly
        'bankCode': card['bankCode'] ?? 'qanta',
        'expiryDate': '',
        'totalDebt': card['totalDebt'] ?? 0.0,
        'creditLimit': card['creditLimit'] ?? 0.0,
        'usagePercentage': card['usagePercentage'] ?? 0.0,
        'statementDate': card['statementDate'] ?? 1,
        'dueDate': card['dueDate'] ?? 15,
        'accountId': card['id'], // Add account ID for usage tracking
      });
    }
    
    // Add debit cards (already in legacy format)
    for (final card in providerV2.debitCards) {
      allCards.add({
        'cardType': 'debit',
        'cardTypeLabel': card['cardName'] ?? card['bankName'] ?? 'Banka Kartı',
        'cardName': card['cardName'] ?? card['bankName'] ?? 'Banka Kartı',
        'cardNumber': card['maskedCardNumber'] ?? '**** **** **** ${card['id'].substring(0, 4)}',
        'balance': card['balance'] ?? 0.0,
        'bankCode': card['bankCode'] ?? 'qanta',
        'accountId': card['id'], // Add account ID for usage tracking
      });
    }
    
    // Add cash accounts (use raw AccountModel)
    for (final account in providerV2.cashAccounts) {
      allCards.add({
        'cardType': 'cash',
        'cardTypeLabel': 'Nakit',
        'cardNumber': 'Cebinizdeki nakit',
        'balance': account.balance,
        'bankCode': 'qanta',
        'accountId': account.id, // Add account ID for usage tracking
      });
    }
    
    // Sort cards by usage frequency (most used first)
    final sortedCards = _sortCardsByUsage(allCards, providerV2.recentTransactions);
    
    return _buildCardsUI(context, sortedCards, l10n, isDark);
  }

  /// Sort cards by usage frequency based on transaction count
  List<Map<String, dynamic>> _sortCardsByUsage(List<Map<String, dynamic>> cards, List<dynamic> transactions) {
    // Calculate usage count for each card
    for (final card in cards) {
      final accountId = card['accountId'] as String;
      final usageCount = transactions.where((tx) {
        // Check if this transaction involves this account
        // V2 transactions have sourceAccountId and targetAccountId properties
        if (tx.sourceAccountId == accountId || tx.targetAccountId == accountId) {
          return true;
        }
        return false;
      }).length;
      
      card['usageCount'] = usageCount;
    }
    
    // Sort by usage count (descending - most used first)
    cards.sort((a, b) {
      final usageA = a['usageCount'] as int? ?? 0;
      final usageB = b['usageCount'] as int? ?? 0;
      
      // If usage counts are equal, sort by card type priority (cash > debit > credit)
      if (usageA == usageB) {
        return _getCardTypePriority(a['cardType'] as String)
            .compareTo(_getCardTypePriority(b['cardType'] as String));
      }
      
      return usageB.compareTo(usageA); // Descending order
    });
    
    return cards;
  }
  
  /// Get card type priority for sorting (lower number = higher priority)
  int _getCardTypePriority(String cardType) {
    switch (cardType) {
      case 'cash':
        return 0; // Highest priority
      case 'debit':
        return 1; // Medium priority
      case 'credit':
        return 2; // Lowest priority
      default:
        return 3;
    }
  }

  /// Build the actual cards UI (shared between V2 and legacy)
  Widget _buildCardsUI(BuildContext context, List<Map<String, dynamic>> allCards, AppLocalizations l10n, bool isDark) {
    // Eğer hiç kart yoksa boş durum göster
    if (allCards.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.myCards,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/cards');
                  },
                  child: Text(
                    l10n.seeAll,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
          Container(
            height: AppConstants.cardSectionHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 48,
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kart eklenmemiş',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk kartınızı eklemek için Kartlarım sayfasına gidin',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.myCards,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.push('/cards');
                },
                child: Text(
                  l10n.seeAll,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        // Cards PageView
        SizedBox(
          height: AppConstants.cardSectionHeight,
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return PageView.builder(
                controller: _pageController,
                padEnds: false,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: allCards.length,
                itemBuilder: (context, index) {
                  final card = allCards[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                      }
                      
                      return Transform.scale(
                        scale: Curves.easeOut.transform(value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: card['cardType'] == 'cash'
                              ? CashBalanceCard(
                                  balance: card['balance'] as double,
                                  themeProvider: themeProvider,
                                )
                              : card['cardType'] == 'debit'
                                  ? DebitCardWidget(
                                      card: card,
                                      onTap: () {
                                        // Handle debit card tap
                                      },
                                    )
                                  : CreditCardWidget(
                                      cardType: card['cardType'] as String,
                                      cardTypeLabel: card['cardTypeLabel'] as String,
                                      cardNumber: card['cardNumber'] as String,
                                      balance: card['balance'] as double,
                                      bankCode: card['bankCode'] as String?,
                                      expiryDate: card['expiryDate'] as String?,
                                      totalDebt: card['totalDebt'] as double?,
                                      creditLimit: card['creditLimit'] as double?,
                                      usagePercentage: card['usagePercentage'] as double?,
                                      statementDate: card['statementDate'] as int?,
                                      dueDate: card['dueDate'] as int?,
                                    ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Page Indicators
        if (allCards.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              allCards.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                    ? isDark 
                      ? Colors.white
                      : Colors.black
                    : isDark 
                      ? const Color(0xFF48484A)
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 