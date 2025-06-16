import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/payment_method.dart';
import '../../models/card.dart';
import '../../../../l10n/app_localizations.dart';

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedPaymentMethod;
  final String? errorText;
  final Function(PaymentMethod) onPaymentMethodSelected;
  final VoidCallback? onAutoAdvance;

  const PaymentMethodSelector({
    super.key,
    required this.selectedPaymentMethod,
    this.errorText,
    required this.onPaymentMethodSelected,
    this.onAutoAdvance,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  // Mock cards data
  final List<PaymentCard> _mockCards = [
    PaymentCard(
      id: '1',
      name: 'İş Bankası Kredi',
      number: '**** **** **** 1234',
      expiryDate: '12/26',
      bankName: 'İş Bankası',
      type: CardType.credit,
      color: const Color(0xFF1E40AF),
    ),
    PaymentCard(
      id: '2',
      name: 'Garanti BBVA',
      number: '**** **** **** 5678',
      expiryDate: '08/25',
      bankName: 'Garanti BBVA',
      type: CardType.credit,
      color: const Color(0xFF059669),
    ),
    PaymentCard(
      id: '3',
      name: 'Akbank Banka Kartı',
      number: '**** **** **** 9012',
      expiryDate: '03/27',
      bankName: 'Akbank',
      type: CardType.debit,
      color: const Color(0xFFDC2626),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.errorText != null) ...[
          Text(
            widget.errorText!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFFF3B30),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Cash Option
        _PaymentOptionCard(
          icon: Icons.payments_rounded,
          title: l10n.cash,
          subtitle: '',
          isSelected: widget.selectedPaymentMethod?.isCash == true,
          isDark: isDark,
          onTap: () {
            final cashMethod = PaymentMethod(
              type: PaymentMethodType.cash,
              card: null,
              installments: 1,
            );
            widget.onPaymentMethodSelected(cashMethod);
            Future.delayed(const Duration(milliseconds: 300), () {
              widget.onAutoAdvance?.call();
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Cards Section
        Text(
          l10n.myCards,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Cards List
        ...(_mockCards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CardOptionCard(
            card: card,
            isSelected: widget.selectedPaymentMethod?.card?.id == card.id,
            isDark: isDark,
            l10n: l10n,
            onTap: () => _showInstallmentOptions(card),
          ),
        ))),
      ],
    );
  }

  void _showInstallmentOptions(PaymentCard card) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.installmentOptions,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Installment options
                  if (card.type == CardType.credit) ...[
                    // Credit card installment options
                    ...[1, 2, 3, 6, 9, 12].map((installments) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InstallmentOption(
                        installments: installments,
                        cardName: card.name,
                        isDark: isDark,
                        l10n: l10n,
                        onTap: () {
                          final method = PaymentMethod(
                            type: PaymentMethodType.card,
                            card: card,
                            installments: installments,
                          );
                          widget.onPaymentMethodSelected(method);
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            widget.onAutoAdvance?.call();
                          });
                        },
                      ),
                    )),
                  ] else ...[
                    // Debit card - only cash payment
                    _InstallmentOption(
                      installments: 1,
                      cardName: card.name,
                      isDark: isDark,
                      l10n: l10n,
                      onTap: () {
                        final method = PaymentMethod(
                          type: PaymentMethodType.card,
                          card: card,
                          installments: 1,
                        );
                        widget.onPaymentMethodSelected(method);
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onAutoAdvance?.call();
                        });
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? const Color(0xFF10B981).withValues(alpha: 0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white : Colors.black),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardOptionCard extends StatelessWidget {
  final PaymentCard card;
  final bool isSelected;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _CardOptionCard({
    required this.card,
    required this.isSelected,
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? const Color(0xFF10B981).withValues(alpha: 0.1)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
          width: isSelected ? 1.5 : 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: card.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white : Colors.black),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.number,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallmentOption extends StatelessWidget {
  final int installments;
  final String cardName;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _InstallmentOption({
    required this.installments,
    required this.cardName,
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = installments == 1 ? l10n.cashPayment : l10n.installments(installments);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
          width: 0.33,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$cardName ($displayText)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 