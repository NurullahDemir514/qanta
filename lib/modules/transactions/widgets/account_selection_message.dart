import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';

/// WhatsApp tarzı interaktif hesap seçim mesajı
/// SOLID: Single Responsibility - Sadece hesap seçimi
class AccountSelectionMessage extends StatelessWidget {
  final Function(String accountId, String accountName) onAccountSelected;

  const AccountSelectionMessage({
    super.key,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<UnifiedProviderV2>();
    final accounts = provider.accounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D6D70).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.wallet_rounded,
                      color: Color(0xFF6D6D70),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hesap seçin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Account Buttons (Compact)
              ...accounts.map((account) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => onAccountSelected(account.id, account.displayName),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAccountIcon(account.type.toString()),
                            color: const Color(0xFF6D6D70),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              account.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    if (type.contains('cash')) return Icons.payments_rounded;
    if (type.contains('credit')) return Icons.credit_card_rounded;
    if (type.contains('debit')) return Icons.account_balance_wallet_rounded;
    if (type.contains('savings')) return Icons.account_balance_wallet_rounded;
    if (type.contains('investment')) return Icons.trending_up_rounded;
    return Icons.account_balance_rounded;
  }

  String _getAccountTypeLabel(String type) {
    if (type.contains('cash')) return 'Nakit';
    if (type.contains('credit')) return 'Kredi Kartı';
    if (type.contains('debit')) return 'Banka Kartı';
    if (type.contains('savings')) return 'Tasarruf Hesabı';
    if (type.contains('investment')) return 'Yatırım Hesabı';
    return 'Banka Hesabı';
  }
}

