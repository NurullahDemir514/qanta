import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class AddCardButton extends StatelessWidget {
  final bool isDark;
  final String? cardType;

  const AddCardButton({
    super.key,
    required this.isDark, 
    this.cardType
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E)
          : Colors.white,
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
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addNewCard(context, cardType),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF007AFF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cardType != null ? l10n.addNewCard : l10n.addNewCard,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewCard(BuildContext context, String? cardType) {
    final l10n = AppLocalizations.of(context)!;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addNewCardFeature),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 