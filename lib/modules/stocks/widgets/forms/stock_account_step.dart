import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/account_model.dart';
import '../../../../shared/models/stock_models.dart';
import '../../../../shared/utils/currency_utils.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../l10n/app_localizations.dart';

/// Hesap seçim step'i
class StockAccountStep extends StatefulWidget {
  final AccountModel? selectedAccount;
  final Function(AccountModel) onAccountSelected;
  final StockTransactionType transactionType;

  const StockAccountStep({
    super.key,
    this.selectedAccount,
    required this.onAccountSelected,
    required this.transactionType,
  });

  @override
  State<StockAccountStep> createState() => _StockAccountStepState();
}

class _StockAccountStepState extends State<StockAccountStep> {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        // Tüm aktif hesapları göster
        final allAccounts = provider.accounts
            .where((account) => account.isActive)
            .toList();

        return Column(
          children: [

            // Hesap listesi
            if (allAccounts.isEmpty)
              _buildEmptyState(isDark)
            else
              ...allAccounts.map((account) {
                final isSelected = widget.selectedAccount?.id == account.id;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAccountOption(
                    context: context,
                    account: account,
                    isSelected: isSelected,
                    onTap: () {
                      widget.onAccountSelected(account);
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noCashAccountFound,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addCashAccountForStockTrading,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption({
    required BuildContext context,
    required AccountModel account,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getAccountColor(account.type);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? color.withOpacity(0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? color
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getAccountIcon(account.type),
                    color: color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? color
                            : (isDark ? Colors.white : Colors.black),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _getAccountTypeName(account.type),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyUtils.formatAmount(account.balance, Currency.TRY),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.account_balance_wallet;
      case AccountType.credit:
        return Icons.credit_card;
      case AccountType.debit:
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }
  
  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return const Color(0xFF4CAF50); // Yeşil
      case AccountType.credit:
        return const Color(0xFFFF9800); // Turuncu
      case AccountType.debit:
        return const Color(0xFF2196F3); // Mavi
      default:
        return const Color(0xFF6D6D70); // Gri
    }
  }
  
  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return l10n.cash;
      case AccountType.credit:
        return l10n.creditCard;
      case AccountType.debit:
        return l10n.debitCard;
      default:
        return l10n.account;
    }
  }
}
