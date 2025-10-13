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
        // Tüm aktif hesapları al
        final allAccounts = provider.accounts
            .where((account) => account.isActive)
            .toList();
            
        // Sadece nakit ve banka kartlarını göster (kredi kartlarını hariç tut)
        final filteredAccounts = allAccounts
            .where((account) => account.type != AccountType.credit)
            .toList();

        return Column(
          children: [

            // Hesap listesi
            if (filteredAccounts.isEmpty)
              _buildEmptyState(isDark)
            else
              ...filteredAccounts.map((account) {
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
    final l10n = AppLocalizations.of(context)!;
    final color = _getAccountColor(account.type);
    final isDisabled = false; // Hisse formunda disabled state yok
    
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
            ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7))
            : isSelected
              ? color.withOpacity(0.1)
              : (isDark 
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF8F8F8)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
              : isSelected
                ? color
                : (isDark 
                    ? const Color(0xFF38383A)
                    : const Color(0xFFE8E8E8)),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDisabled
                  ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
                  : isSelected 
                    ? color 
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                account.type == AccountType.cash
                  ? Icons.payments_rounded 
                  : Icons.credit_card_rounded,
                size: 16,
                color: isDisabled
                  ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                  : isSelected 
                    ? Colors.white 
                    : color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.type == AccountType.cash
                        ? l10n.cash 
                        : (account.name == 'CASH_WALLET' 
                            ? (AppLocalizations.of(context)?.cashWallet ?? 'Nakit Hesap')
                            : account.name),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                        ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                        : isSelected
                          ? color
                          : (isDark ? Colors.white : Colors.black),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        account.type == AccountType.cash
                          ? l10n.cashAccount
                          : account.type == AccountType.credit 
                            ? l10n.creditCard
                            : l10n.debitCard,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDisabled
                            ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                            : (isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70)),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyUtils.formatAmount(account.balance, Currency.TRY),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDisabled
                            ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                            : (isDark 
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6D6D70)),
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
    );
  }
  
  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.credit:
        return Icons.credit_card_rounded;
      case AccountType.debit:
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }
  
  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return const Color(0xFF34C759); // iOS Green
      case AccountType.credit:
        return const Color(0xFFFF9500); // iOS Orange
      case AccountType.debit:
        return const Color(0xFF007AFF); // iOS Blue
      default:
        return const Color(0xFF6D6D70); // iOS Gray
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
