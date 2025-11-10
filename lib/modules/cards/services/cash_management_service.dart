import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/account_model.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/management_option.dart';
import '../../transactions/widgets/forms/calculator_input_field.dart';

class CashManagementService {
  static void showCashManagementBottomSheet(
    BuildContext context,
    bool isDark,
    double cashBalance,
    Function(double) onCashAdded,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF48484A)
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Title
                    Text(
                      l10n.cashManagement,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      '${l10n.cashBalance}: ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(cashBalance)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Cash Management Options
                    ManagementOption(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.updateCashBalance,
                      subtitle: l10n.updateCashBalanceDesc,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _showUpdateBalanceDialog(
                          context,
                          cashBalance,
                          onCashAdded,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    ManagementOption(
                      icon: Icons.history_outlined,
                      title: l10n.addCashHistory,
                      subtitle: l10n.addCashHistoryDesc,
                      color: const Color(0xFF007AFF),
                      isDark: isDark,
                      onTap: () => _showOption(context, l10n.addCashHistory),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showOption(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message ${l10n.opening}'),
        backgroundColor: const Color(0xFF8E8E93),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showUpdateBalanceDialog(
    BuildContext context,
    double currentBalance,
    Function(double) onBalanceUpdated,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: currentBalance.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                l10n.updateCashBalanceTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.updateCashBalanceMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Calculator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CalculatorInputField(
                            controller: controller,
                            onChanged: () {
                              // Hesap makinesi değişikliklerini dinle
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF3A3A3C)
                                          : const Color(0xFFD1D1D6),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancel,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final newBalance = double.tryParse(controller.text);
                                    if (newBalance != null && newBalance >= 0) {
                                      Navigator.of(context).pop();

                                      try {
                                        // Use v2 provider to update cash account
                                        final providerV2 = Provider.of<UnifiedProviderV2>(
                                          context,
                                          listen: false,
                                        );

                                        // Get cash accounts
                                        final cashAccounts = providerV2.accounts
                                            .where((a) => a.type == AccountType.cash)
                                            .toList();

                                        if (cashAccounts.isNotEmpty) {
                                          // Update existing cash account
                                          final cashAccount = cashAccounts.first;
                                          await providerV2.updateAccountBalance(
                                            cashAccount.id,
                                            newBalance,
                                          );
                                        } else {
                                          // This should not happen as _ensureDefaultCashAccount should create one
                                          // But if it does, create one manually
                                          debugPrint(
                                            'CashManagementService - No cash account found, creating one',
                                          );
                                          await providerV2.createAccount(
                                            type: AccountType.cash,
                                            name: 'CASH_WALLET', // Generic identifier
                                            balance: newBalance,
                                          );
                                        }

                                        onBalanceUpdated(newBalance);

                                        // Show success message
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.cashBalanceUpdated(
                                                  Provider.of<ThemeProvider>(
                                                    context,
                                                    listen: false,
                                                  ).formatAmount(newBalance),
                                                ),
                                              ),
                                              backgroundColor: Colors.green.shade500,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Hata: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Show error for invalid amount
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.enterValidAmount),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007AFF),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.update,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bottom padding for safe area
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Direkt güncelleme dialog'u açan fonksiyon
  static void showDirectUpdateDialog(
    BuildContext context,
    double currentBalance,
    Function(double) onBalanceUpdated,
  ) {
    _showUpdateBalanceDialog(context, currentBalance, onBalanceUpdated);
  }
}
