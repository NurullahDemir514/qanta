import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

/// Horizontal taksit seçim chip'leri - Input üzerinde
/// SOLID: Single Responsibility - Sadece taksit seçimi
class InstallmentSelectionMessage extends StatelessWidget {
  final Function(int installmentCount) onInstallmentSelected;
  final bool isCreditCard;
  final String? aiMessage;

  const InstallmentSelectionMessage({
    super.key,
    required this.onInstallmentSelected,
    this.isCreditCard = true,
    this.aiMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Taksit seçenekleri
    final installmentOptions = [
      {'count': 1, 'label': l10n.singlePayment},
      {'count': 3, 'label': '3 ${l10n.installment_summary}'},
      {'count': 6, 'label': '6 ${l10n.installment_summary}'},
      {'count': 9, 'label': '9 ${l10n.installment_summary}'},
      {'count': 12, 'label': '12 ${l10n.installment_summary}'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.howManyInstallments,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal chip'ler
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: installmentOptions.map((option) {
                final count = option['count'] as int;
                final label = option['label'] as String;
                final isPesin = count == 1;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onInstallmentSelected(count),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

