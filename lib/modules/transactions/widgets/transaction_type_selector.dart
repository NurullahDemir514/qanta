import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/transaction_model.dart';
import 'transaction_type_card.dart';

class TransactionTypeSelector extends StatelessWidget {
  final ScrollController scrollController;
  final Function(TransactionType) onTransactionTypeSelected;

  const TransactionTypeSelector({
    super.key,
    required this.scrollController,
    required this.onTransactionTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E)
          : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF48484A)
                : const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              children: [
                // Title
                Text(
                  l10n.selectTransactionType,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  AppLocalizations.of(context)?.selectTransactionType ?? 'Select the type of transaction you want to make',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Transaction Type Cards
                ...TransactionType.values.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final transactionType = entry.value;
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == TransactionType.values.length - 1 ? 0 : 16,
                      ),
                      child: TransactionTypeCard(
                        transactionType: transactionType,
                        isDark: isDark,
                        onTap: () => onTransactionTypeSelected(transactionType),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 