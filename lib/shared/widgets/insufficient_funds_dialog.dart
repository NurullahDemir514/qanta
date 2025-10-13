import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/insufficient_funds_exception.dart';
import 'ios_dialog.dart';

class InsufficientFundsDialog extends StatelessWidget {
  final InsufficientFundsException exception;

  const InsufficientFundsDialog({super.key, required this.exception});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Kart türüne göre icon ve renk belirle
    IconData icon;
    Color iconColor;
    Color iconBackgroundColor;
    String title;
    String cleanMessage;

    switch (exception.cardType) {
      case 'credit':
        icon = Icons.credit_card_off;
        iconColor = const Color(0xFFFF6B6B);
        iconBackgroundColor = const Color(0xFFFF6B6B);
        title = l10n.creditCardLimitInsufficientTitle;
        cleanMessage = l10n.creditCardLimitInsufficientMessage;
        break;
      case 'debit':
        icon = Icons.account_balance_wallet_outlined;
        iconColor = const Color(0xFFFF9500);
        iconBackgroundColor = const Color(0xFFFF9500);
        title = l10n.debitCardBalanceInsufficientTitle;
        cleanMessage = l10n.debitCardBalanceInsufficientMessage;
        break;
      case 'cash':
        icon = Icons.wallet_outlined;
        iconColor = const Color(0xFFFF3B30);
        iconBackgroundColor = const Color(0xFFFF3B30);
        title = l10n.cashBalanceInsufficientTitle;
        cleanMessage = l10n.cashBalanceInsufficientMessage;
        break;
      default:
        icon = Icons.error_outline;
        iconColor = const Color(0xFFFF3B30);
        iconBackgroundColor = const Color(0xFFFF3B30);
        title = l10n.insufficientBalanceTitle;
        cleanMessage = exception.message;
    }

    return IOSDialog(
      title: title,
      message: cleanMessage,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      actions: [
        IOSDialogAction(
          text: 'Tamam',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Show insufficient funds dialog
  static Future<void> show(
    BuildContext context,
    InsufficientFundsException exception,
  ) {
    // Kart türüne göre icon ve renk belirle
    IconData icon;
    Color iconColor;
    Color iconBackgroundColor;
    String title;
    String cleanMessage;

    switch (exception.cardType) {
      case 'credit':
        icon = Icons.credit_card_off;
        iconColor = const Color(0xFFFF6B6B);
        iconBackgroundColor = const Color(0xFFFF6B6B);
        title = 'Kredi Kartı Limiti Yetersiz';
        cleanMessage =
            'Kredi kartı limitiniz bu işlem için yeterli değil. Lütfen daha düşük bir tutar girin veya kartınızın borcunu ödeyin.';
        break;
      case 'debit':
        icon = Icons.account_balance_wallet_outlined;
        iconColor = const Color(0xFFFF9500);
        iconBackgroundColor = const Color(0xFFFF9500);
        title = 'Banka Kartı Bakiyesi Yetersiz';
        cleanMessage =
            'Banka kartı bakiyeniz bu işlem için yeterli değil. Lütfen daha düşük bir tutar girin veya kartınıza para yatırın.';
        break;
      case 'cash':
        icon = Icons.wallet_outlined;
        iconColor = const Color(0xFFFF3B30);
        iconBackgroundColor = const Color(0xFFFF3B30);
        title = 'Nakit Bakiyesi Yetersiz';
        cleanMessage =
            'Nakit bakiyeniz bu işlem için yeterli değil. Lütfen daha düşük bir tutar girin.';
        break;
      default:
        icon = Icons.error_outline;
        iconColor = const Color(0xFFFF3B30);
        iconBackgroundColor = const Color(0xFFFF3B30);
        title = 'Yetersiz Bakiye';
        cleanMessage = exception.message;
    }

    return IOSDialog.show(
      context,
      title: title,
      message: cleanMessage,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      actions: [
        IOSDialogAction(
          text: 'Tamam',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
