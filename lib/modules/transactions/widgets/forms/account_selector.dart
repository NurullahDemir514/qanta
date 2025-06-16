import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/card.dart';
import '../../../../l10n/app_localizations.dart';

class AccountSelector extends StatelessWidget {
  final PaymentCard? selectedAccount;
  final Function(PaymentCard) onAccountSelected;
  final String? errorText;
  final String? excludeAccountId; // To prevent selecting the same account
  final String title;

  const AccountSelector({
    super.key,
    this.selectedAccount,
    required this.onAccountSelected,
    this.errorText,
    this.excludeAccountId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        
        // Account options
        ..._getAvailableAccounts().map((account) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccountOption(
            context: context,
            account: account,
            isSelected: selectedAccount?.id == account.id,
            isDisabled: account.id == excludeAccountId,
            onTap: () {
              if (account.id != excludeAccountId) {
                HapticFeedback.selectionClick();
                onAccountSelected(account);
              }
            },
          ),
        )),
        
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFFF3B30),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }

  List<PaymentCard> _getAvailableAccounts() {
    // Return all available accounts for transfer
    return [
      PaymentCard(
        id: 'cash',
        name: 'Nakit',
        type: CardType.debit,
        number: '0000000000000000',
        expiryDate: '',
        bankName: 'Qanta',
        color: const Color(0xFF34C759),
      ),
      PaymentCard(
        id: '1',
        name: 'Qanta Debit',
        type: CardType.debit,
        number: '4532123456789012',
        expiryDate: '12/26',
        bankName: 'Qanta Bank',
        color: const Color(0xFF10B981),
      ),
      PaymentCard(
        id: '2',
        name: 'Qanta Credit',
        type: CardType.credit,
        number: '4532123456789023',
        expiryDate: '10/25',
        bankName: 'Qanta Bank',
        color: const Color(0xFFFF9500),
      ),
      PaymentCard(
        id: '3',
        name: 'Qanta Savings',
        type: CardType.debit,
        number: '4532123456789034',
        expiryDate: '08/27',
        bankName: 'Qanta Bank',
        color: const Color(0xFF8B5CF6),
      ),
    ];
  }

  Widget _buildAccountOption({
    required BuildContext context,
    required PaymentCard account,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
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
              ? account.color.withOpacity(0.1)
              : (isDark 
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF8F8F8)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
              : isSelected
                ? account.color
                : (isDark 
                    ? const Color(0xFF38383A)
                    : const Color(0xFFE8E8E8)),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDisabled
                  ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
                  : isSelected 
                    ? account.color 
                    : account.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                account.id == 'cash' 
                  ? Icons.payments_rounded 
                  : Icons.credit_card_rounded,
                size: 24,
                color: isDisabled
                  ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                  : isSelected 
                    ? Colors.white 
                    : account.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.id == 'cash' ? l10n.cash : account.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                        ? (isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93))
                        : isSelected
                          ? account.color
                          : (isDark ? Colors.white : Colors.black),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.id == 'cash' 
                      ? l10n.digitalWallet
                      : '•••• ${account.lastFourDigits}',
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
                ],
              ),
            ),
            if (isSelected && !isDisabled)
              Icon(
                Icons.check_circle_rounded,
                color: account.color,
                size: 24,
              ),
            if (isDisabled)
              Icon(
                Icons.block_rounded,
                color: isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
} 