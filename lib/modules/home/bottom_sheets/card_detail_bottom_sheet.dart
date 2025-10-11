import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

class CardDetailBottomSheet {
  static void show(
    BuildContext context,
    String cardType,
    String cardTypeLabel,
    String cardNumber,
    double balance,
    List<Color> gradientColors,
    Color accentColor,
    ThemeProvider themeProvider,
    bool isDark, {
    // Kredi kartı özel parametreleri
    String? expiryDate,
    double? totalDebt,
    double? creditLimit,
    double? usagePercentage,
    int? statementDate,
    int? dueDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CardDetailContent(
          scrollController: scrollController,
          cardType: cardType,
          cardTypeLabel: cardTypeLabel,
          cardNumber: cardNumber,
          balance: balance,
          gradientColors: gradientColors,
          accentColor: accentColor,
          themeProvider: themeProvider,
          isDark: isDark,
          totalDebt: totalDebt,
          creditLimit: creditLimit,
          usagePercentage: usagePercentage,
          statementDate: statementDate,
          dueDate: dueDate,
          expiryDate: expiryDate,
        ),
      ),
    );
  }
}

class _CardDetailContent extends StatelessWidget {
  final ScrollController scrollController;
  final String cardType;
  final String cardTypeLabel;
  final String cardNumber;
  final double balance;
  final List<Color> gradientColors;
  final Color accentColor;
  final ThemeProvider themeProvider;
  final bool isDark;
  final double? totalDebt;
  final double? creditLimit;
  final double? usagePercentage;
  final int? statementDate;
  final int? dueDate;
  final String? expiryDate;

  const _CardDetailContent({
    required this.scrollController,
    required this.cardType,
    required this.cardTypeLabel,
    required this.cardNumber,
    required this.balance,
    required this.gradientColors,
    required this.accentColor,
    required this.themeProvider,
    required this.isDark,
    this.totalDebt,
    this.creditLimit,
    this.usagePercentage,
    this.statementDate,
    this.dueDate,
    this.expiryDate,
  });

  // Son ödeme tarihini dinamik olarak formatlar (örn: "18 Haziran")
  String _formatDueDate(int dueDay, BuildContext context) {
    return '18 June';
  }

  bool get _isCreditCard => totalDebt != null && creditLimit != null;

  Color _getUsageColor(double percentage) {
    if (percentage < 50) {
      return const Color(0xFF34C759); // Green
    } else if (percentage < 80) {
      return const Color(0xFFFF9500); // Orange
    } else {
      return const Color(0xFFFF3B30); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuthService.currentUser;
    final userName = user?.displayName ?? l10n.defaultUserName;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Mini Card Preview
                Center(
                  child: Container(
                    width: AppConstants.miniCardWidth,
                    height: AppConstants.miniCardHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Holographic effect
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                  accentColor.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Chip and Card Type
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // EMV Chip
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.credit_card,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                  // Card Type
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      cardTypeLabel.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Card Number
                              Text(
                                cardNumber,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Cardholder and Expiry
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.cardHolder,
                                          style: GoogleFonts.inter(
                                            fontSize: 6,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          userName.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        l10n.expiryDate,
                                        style: GoogleFonts.inter(
                                          fontSize: 6,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        expiryDate ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Balance and Contactless
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    themeProvider.formatAmount(balance),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    Icons.contactless,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 12,
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

                const SizedBox(height: 24),

                // Card Info
                _InfoSection(
                  title: l10n.cardInfo,
                  isDark: isDark,
                  children: [
                    _InfoRow(l10n.cardType, cardTypeLabel, isDark),
                    _InfoRow(l10n.cardNumber, cardNumber, isDark),
                    _InfoRow(l10n.expiryDateShort, expiryDate ?? '', isDark),
                    // Kredi kartı özel bilgileri
                    if (_isCreditCard && statementDate != null)
                      _InfoRow(
                        (AppLocalizations.of(context)?.statementDay ??
                                'Statement Day')
                            .toString(),
                        '$statementDate',
                        isDark,
                      ),
                    if (_isCreditCard && dueDate != null)
                      _InfoRow(
                        (AppLocalizations.of(context)?.lastPayment ??
                                'Last Payment')
                            .toString(),
                        _formatDueDate(dueDate!, context),
                        isDark,
                        valueColor: const Color(0xFFFF9500),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Balance Info
                _InfoSection(
                  title: _isCreditCard
                      ? (AppLocalizations.of(context)?.creditCardInfo ??
                            'Credit Card Info')
                      : l10n.balanceInfo,
                  isDark: isDark,
                  children: [
                    if (_isCreditCard) ...[
                      _InfoRow(
                        AppLocalizations.of(context)?.creditLimit ??
                            'Credit Limit',
                        themeProvider.formatAmount(creditLimit!),
                        isDark,
                      ),
                      _InfoRow(
                        AppLocalizations.of(context)?.availableLimit ??
                            'Available Limit',
                        themeProvider.formatAmount(balance),
                        isDark,
                        valueColor: const Color(0xFF34C759),
                      ),
                      _InfoRow(
                        AppLocalizations.of(context)?.totalDebt ?? 'Total Debt',
                        themeProvider.formatAmount(totalDebt!),
                        isDark,
                        valueColor: totalDebt! > 0
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                      ),
                      _InfoRow(
                        AppLocalizations.of(context)?.usageRate ?? 'Usage Rate',
                        '${usagePercentage?.toStringAsFixed(1) ?? '0.0'}%',
                        isDark,
                        valueColor: _getUsageColor(usagePercentage ?? 0),
                      ),
                    ] else ...[
                      _InfoRow(
                        l10n.availableBalance,
                        themeProvider.formatAmount(balance),
                        isDark,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, this.isDark, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFF2F2F7),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
