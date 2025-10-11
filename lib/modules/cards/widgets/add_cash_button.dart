import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class AddCashButton extends StatelessWidget {
  final bool isDark;
  final Function(double) onCashAdded;

  const AddCashButton({
    super.key,
    required this.isDark,
    required this.onCashAdded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUpdateBalanceDialog(context, onCashAdded),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF8E8E93).withValues(alpha: 0.2)
                      : const Color(0xFF6D6D70).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.updateCashBalance,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateBalanceDialog(
    BuildContext context,
    Function(double) onCashAdded,
  ) {
    // Bu butonu kaldıracağız çünkü bottom sheet'te zaten var
    // Şimdilik boş bırakıyoruz
  }
}
