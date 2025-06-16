import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/account_model.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/management_option.dart';
import '../../../shared/widgets/ios_dialog.dart';

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
            color: isDark 
              ? const Color(0xFF1C1C1E)
              : Colors.white,
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
                        _showUpdateBalanceDialog(context, cashBalance, onCashAdded);
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
    final controller = TextEditingController(text: currentBalance.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => IOSDialog(
        title: l10n.updateCashBalanceTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.updateCashBalanceMessage,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.newBalance,
                suffixText: '₺',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          IOSDialogAction(
            text: l10n.cancel,
            isDestructive: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          IOSDialogAction(
            text: l10n.update,
            isDestructive: false,
            onPressed: () async {
              final newBalance = double.tryParse(controller.text);
              if (newBalance != null && newBalance >= 0) {
                Navigator.of(context).pop();
                
                try {
                  // Use v2 provider to update cash account
                  final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
                  
                  // Get cash accounts
                  final cashAccounts = providerV2.accounts.where((a) => a.type == AccountType.cash).toList();
                  
                  if (cashAccounts.isNotEmpty) {
                    // Update existing cash account
                    final cashAccount = cashAccounts.first;
                    await providerV2.updateAccountBalance(cashAccount.id, newBalance);
                  } else {
                    // Create new cash account
                    await providerV2.createAccount(
                      type: AccountType.cash,
                      name: 'Nakit',
                      balance: newBalance,
                    );
                  }
                  
                  onBalanceUpdated(newBalance);
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.cashBalanceUpdated(
                          Provider.of<ThemeProvider>(context, listen: false).formatAmount(newBalance)
                        )),
                        backgroundColor: const Color(0xFF34C759),
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
          ),
        ],
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

// Binlik ayırıcı formatter
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Sadece rakam ve nokta kabul et
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Birden fazla nokta varsa sadece ilkini tut
    List<String> parts = newText.split('.');
    if (parts.length > 2) {
      newText = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    // Ondalık kısmı 2 hanede sınırla
    if (parts.length == 2 && parts[1].length > 2) {
      newText = '${parts[0]}.${parts[1].substring(0, 2)}';
    }
    
    // Binlik ayırıcı ekle
    if (parts.isNotEmpty) {
      String integerPart = parts[0];
      String formattedInteger = _addThousandsSeparator(integerPart);
      
      if (parts.length == 2) {
        newText = '$formattedInteger.${parts[1]}';
      } else {
        newText = formattedInteger;
      }
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
  
  String _addThousandsSeparator(String value) {
    if (value.length <= 3) return value;
    
    String result = '';
    int count = 0;
    
    for (int i = value.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = value[i] + result;
      count++;
    }
    
    return result;
  }
} 