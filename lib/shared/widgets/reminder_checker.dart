import 'package:flutter/material.dart';
import '../../core/services/reminder_service.dart';

/// Hatırlatıcıları kontrol eden ve gösteren widget
/// Ana ekranda görünmez şekilde çalışır
class ReminderChecker extends StatefulWidget {
  const ReminderChecker({super.key});

  @override
  State<ReminderChecker> createState() => _ReminderCheckerState();
}

class _ReminderCheckerState extends State<ReminderChecker> {
  @override
  void initState() {
    super.initState();
    // Dialog'lar devre dışı - ana sayfada notifications section kullanılıyor
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkReminders();
    // });
  }

  /// Bekleyen hatırlatıcıları kontrol et ve göster
  Future<void> _checkReminders() async {
    if (!mounted) return;
    
    try {
      final pendingReminders = await ReminderService.checkPendingReminders();
      
      if (pendingReminders.isNotEmpty && mounted) {
        // İlk hatırlatıcıyı göster (bir seferde bir tane)
        final reminder = pendingReminders.first;
        _showReminderDialog(reminder);
      }
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  /// Hatırlatıcı dialog'unu göster
  void _showReminderDialog(Map<String, dynamic> reminder) {
    final data = reminder['data'];
    final message = reminder['message'];
    final key = reminder['key'];
    
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getReminderColor(data['type']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getReminderIcon(data['type']),
                color: _getReminderColor(data['type']),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getReminderTitle(data['type']),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['cardName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Son ödeme: ${data['dueDateText']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markReminderAsShown(key);
            },
            child: const Text('Tamam'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markReminderAsShown(key);
              // Ekstre sayfasına git (opsiyonel)
              // context.push('/cards/${data['cardId']}/statements');
            },
            child: const Text('Ekstreleri Gör'),
          ),
        ],
      ),
    );
  }

  /// Hatırlatıcıyı gösterildi olarak işaretle
  Future<void> _markReminderAsShown(String key) async {
    await ReminderService.markReminderAsShown(key);
    
    // Diğer bekleyen hatırlatıcıları kontrol et
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkReminders();
      });
    }
  }

  /// Hatırlatıcı tipine göre başlık
  String _getReminderTitle(String type) {
    switch (type) {
      case '7_days_before':
        return 'Ekstre Hatırlatıcısı';
      case '3_days_before':
        return 'Ekstre Hatırlatıcısı';
      case '1_day_before':
        return 'Ekstre Hatırlatıcısı';
      case 'due_date':
        return '🚨 SON GÜN!';
      default:
        return 'Hatırlatıcı';
    }
  }

  /// Hatırlatıcı tipine göre ikon
  IconData _getReminderIcon(String type) {
    switch (type) {
      case '7_days_before':
        return Icons.schedule;
      case '3_days_before':
        return Icons.schedule;
      case '1_day_before':
        return Icons.notification_important;
      case 'due_date':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  /// Hatırlatıcı tipine göre renk
  Color _getReminderColor(String type) {
    switch (type) {
      case '7_days_before':
        return const Color(0xFF007AFF); // iOS Blue
      case '3_days_before':
        return const Color(0xFF007AFF); // iOS Blue
      case '1_day_before':
        return const Color(0xFFFFC300); // Warning Amber
      case 'due_date':
        return const Color(0xFFFF453A); // Error Red
      default:
        return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bu widget görünmez - sadece arka planda çalışır
    return const SizedBox.shrink();
  }
} 