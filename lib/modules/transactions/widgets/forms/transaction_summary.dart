import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';

class TransactionSummary extends StatelessWidget {
  final double amount;
  final String? category;
  final String? categoryName; // Backward compatibility
  final String? paymentMethod;
  final String? paymentMethodName; // Backward compatibility
  final DateTime date;
  final String? description;
  final String? transactionType;
  final bool? isIncome;

  const TransactionSummary({
    super.key,
    required this.amount,
    this.category,
    this.categoryName, // Deprecated, use category
    this.paymentMethod,
    this.paymentMethodName, // Deprecated, use paymentMethod
    required this.date,
    this.description,
    this.transactionType,
    this.isIncome,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'tr_TR');
    return formatter.format(date);
  }

  String get _categoryDisplay => category ?? categoryName ?? '';
  String get _paymentMethodDisplay => paymentMethod ?? paymentMethodName ?? '';
  String get _transactionTypeDisplay {
    if (transactionType != null) return transactionType!;
    if (isIncome == true) return 'Gelir';
    return 'İşlem';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Title
        Text(
          l10n.summary,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Amount (Main highlight)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _transactionTypeDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark 
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(amount),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Details
              if (_categoryDisplay.isNotEmpty) ...[
                _buildDetailRow(l10n.category, _categoryDisplay, isDark),
                const SizedBox(height: 12),
              ],
              if (_paymentMethodDisplay.isNotEmpty) ...[
                _buildDetailRow(l10n.payment, _paymentMethodDisplay, isDark),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(l10n.date, _formatDate(date), isDark),
              
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(l10n.description, description!, isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
} 