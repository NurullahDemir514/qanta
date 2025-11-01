import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/theme_provider.dart';
import '../models/payment_card_model.dart';
import '../utils/currency_utils.dart';
import '../design_system/transaction_design_system.dart';

class TransactionDetailModal extends StatelessWidget {
  final CardTransactionModel transaction;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, CardTransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailModal(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(0xFF48484A)
                : const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Transaction icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: transaction.transactionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.transactionIcon,
                    color: transaction.transactionColor,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Transaction title and amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(transaction.amount, context),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: transaction.transactionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Transaction details section
                  _buildSection(
                    isDark: isDark,
                    title: l10n.transactionDetails,
                    children: [
                      _buildDetailRow(
                        isDark: isDark,
                        label: l10n.date,
                        value: _formatDate(transaction.date),
                      ),
                      _buildDetailRow(
                        isDark: isDark,
                        label: l10n.time,
                        value: _formatDate(transaction.date),
                      ),
                      _buildDetailRow(
                        isDark: isDark,
                        label: l10n.transactionType,
                        value: transaction.transactionTypeDescription,
                      ),
                      if (transaction.merchantName != null)
                        _buildDetailRow(
                          isDark: isDark,
                          label: l10n.merchant,
                          value: transaction.merchantName!,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Card details section
                  _buildSection(
                    isDark: isDark,
                    title: l10n.cardDetails,
                    children: [
                      _buildCardRow(isDark: isDark),
                      if (transaction.card.cardType == CardType.credit && 
                          transaction.installmentInfo != null)
                        _buildDetailRow(
                          isDark: isDark,
                          label: l10n.installmentInfo(transaction.currentInstallment ?? 1, transaction.installmentCount ?? 1),
                          value: transaction.installmentInfo!,
                        ),
                      if (transaction.card.cardType == CardType.credit)
                        _buildDetailRow(
                          isDark: isDark,
                          label: l10n.availableLimit,
                          value: _formatCurrency(transaction.card.availableCredit ?? 0.0, context),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Orijinal kart tasarımı - küçük boyutta
          Container(
            width: 60,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  transaction.card.primaryColor,
                  transaction.card.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Kart üzerindeki detaylar
                if (transaction.card.cardType != CardType.cash) ...[
                  Positioned(
                    top: 6,
                    left: 8,
                    child: Text(
                      transaction.card.bankName,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Icon(
                      Icons.credit_card,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 12,
                    ),
                  ),
                ] else ...[
                  // Nakit için özel ikon
                  Center(
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Card info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.card.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                if (transaction.card.cardType != CardType.cash)
                  Text(
                    transaction.card.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark 
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount, BuildContext context) {
    final absAmount = amount.abs();
    final formattedAmount = _formatCurrency(absAmount, context);
    
    if (transaction.isIncome) {
      return '+$formattedAmount';
    } else {
      return '-$formattedAmount';
    }
  }

  // Para birimi miktarı için widget oluşturur
  Widget _buildAmountWidget(double amount, TextStyle style, BuildContext context) {
    final absAmount = amount.abs();
    final formattedAmount = _formatCurrency(absAmount, context);
    final displayAmount = transaction.isIncome ? '+$formattedAmount' : '-$formattedAmount';
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    
    return CurrencyUtils.buildCurrencyText(
      displayAmount,
      style: style,
      currency: currency,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }


  String _formatCurrency(double amount, BuildContext context) {
    // Use CurrencyUtils for proper formatting with correct locale
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    return CurrencyUtils.formatAmountWithoutSymbol(amount, currency) + currency.symbol;
  }

  // Para birimi için güvenli formatlama
  Widget _buildCurrencyText(double amount, TextStyle style, BuildContext context) {
    final formattedAmount = _formatCurrency(amount, context);
    final currency = Provider.of<ThemeProvider>(context, listen: false).currency;
    return CurrencyUtils.buildCurrencyText(
      formattedAmount,
      style: style,
      currency: currency,
    );
  }
} 