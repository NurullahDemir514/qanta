import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/statement_service.dart';
import '../../../core/services/transaction_service_v2.dart';
import '../../../core/services/unified_transaction_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/statement_period.dart';
import '../../../shared/models/transaction_model_v2.dart';

/// Pending notification data model
class PendingNotification {
  final String key;
  final Map<String, dynamic> data;
  final String message;

  PendingNotification({
    required this.key,
    required this.data,
    required this.message,
  });
}

/// Ana sayfada bildirimler bölümü
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  List<PendingNotification> _pendingReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReminders();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider değiştiğinde yeniden yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingReminders();
    });
  }

  Future<void> _loadPendingReminders() async {
    try {
      final upcomingNotifications = <PendingNotification>[];
      final now = DateTime.now();
      
      // Get all credit cards from provider
      final providerV2 = UnifiedProviderV2.instance;
      final creditCards = providerV2.creditCards;
      
      // Check each credit card for upcoming due dates
      for (final creditCard in creditCards) {
        final cardId = creditCard['id'] as String;
        final cardName = creditCard['cardName'] as String? ?? creditCard['bankName'] as String? ?? 'Kredi Kartı';
        final statementDay = creditCard['statementDay'] as int? ?? 1;
        
        // Calculate current period due date
        final currentPeriod = StatementService.getCurrentStatementPeriod(statementDay);
        
        // Calculate current period debt
        final debtAmount = await _calculateCurrentPeriodDebt(cardId, currentPeriod);
        
        // Calculate days until due date
        final today = DateTime(now.year, now.month, now.day);
        final dueDate = DateTime(currentPeriod.dueDate.year, currentPeriod.dueDate.month, currentPeriod.dueDate.day);
        final daysUntilDue = dueDate.difference(today).inDays;
        
        // Add notifications for cards with due dates within 7 days
        if (daysUntilDue >= 0 && daysUntilDue <= 7) {
          String type;
          int urgencyLevel;
          
          if (daysUntilDue == 0) {
            type = 'due_date';
            urgencyLevel = 3;
          } else if (daysUntilDue == 1) {
            type = '1_day_before';
            urgencyLevel = 2;
          } else if (daysUntilDue <= 3) {
            type = '3_days_before';
            urgencyLevel = 1;
          } else {
            type = '7_days_before';
            urgencyLevel = 1;
          }
          
          upcomingNotifications.add(PendingNotification(
            key: 'upcoming_${cardId}_${currentPeriod.statementDate.toIso8601String()}',
            data: {
              'cardId': cardId,
              'cardName': cardName,
              'type': type,
              'dueDate': currentPeriod.dueDate.toIso8601String(),
              'dueDateText': currentPeriod.dueDateText,
              'urgencyLevel': urgencyLevel,
              'debtAmount': debtAmount,
              'daysUntilDue': daysUntilDue,
            },
            message: _getNotificationMessage(type, cardName, daysUntilDue),
          ));
        }
      }
      
      // Sort by urgency level (most urgent first)
      upcomingNotifications.sort((a, b) {
        final aUrgency = a.data['urgencyLevel'] as int;
        final bUrgency = b.data['urgencyLevel'] as int;
        return bUrgency.compareTo(aUrgency);
      });
      
      setState(() {
        _pendingReminders = upcomingNotifications;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getNotificationMessage(String type, String cardName, int daysUntil) {
    switch (type) {
      case 'due_date':
        return '🚨 SON GÜN! $cardName kredi kartınızın ekstre ödemesi bugün vadesi doluyor!';
      case '1_day_before':
        return '$cardName kredi kartınızın ekstre ödemesi yarın vadesi doluyor!';
      case '3_days_before':
        return '$cardName kredi kartınızın ekstre ödemesi $daysUntil gün sonra vadesi doluyor.';
      case '7_days_before':
        return '$cardName kredi kartınızın ekstre ödemesi $daysUntil gün sonra vadesi doluyor.';
      default:
        return '$cardName kredi kartı ekstre ödemesi hatırlatıcısı';
    }
  }
  
  /// Mevcut ekstre dönemindeki harcamaları hesapla
  Future<double> _calculateCurrentPeriodDebt(String cardId, StatementPeriod period) async {
    try {
      // UnifiedTransactionService kullanarak bu kartın tüm işlemlerini çek
      final allTransactions = await UnifiedTransactionService.getTransactionsByAccount(
        accountId: cardId,
      );
      
      // Bu dönemdeki işlemleri filtrele
      final periodTransactions = allTransactions.where((transaction) {
        return transaction.transactionDate.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
               transaction.transactionDate.isBefore(period.endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Sadece expense işlemlerini topla (gider)
      double totalExpenses = 0.0;
      for (final transaction in periodTransactions) {
        if (transaction.type == TransactionType.expense) {
          totalExpenses += transaction.amount;
        }
      }
      
      return totalExpenses;
    } catch (e) {
      return 0.0;
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return monthNames[month];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    if (_pendingReminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - diğer section'larla aynı tasarım (padding olmadan)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)?.notifications ?? 'Notifications',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            GestureDetector(
              onTap: _showAllNotifications,
              child: Text(
                AppLocalizations.of(context)?.all ?? 'All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 10),
        
        // Horizontal scrollable notifications
        SizedBox(
          height: 110, // 3 satır için yükseklik artırıldı
          child: _pendingReminders.isEmpty 
            ? _buildNoNotificationsCard(isDark)
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: _pendingReminders.length,
                itemBuilder: (context, index) => _buildNotificationCard(
                  _pendingReminders[index], 
                  isDark, 
                  index,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildNoNotificationsCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;
    
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E)
          : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A).withValues(alpha: 0.3),
              width: 0.5,
            )
          : null,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF007AFF),
                size: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)?.noNotifications ?? 'No notifications',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(PendingNotification reminder, bool isDark, int index) {
    final data = reminder.data;
    final cardId = data['cardId'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    final cardName = data['cardName'] as String? ?? 'Kredi Kartı';
    final urgencyLevel = data['urgencyLevel'] as int? ?? 1;
    final debtAmount = data['debtAmount'] as double? ?? 0.0;
    final daysUntilDue = data['daysUntilDue'] as int? ?? 0;
    
    // Urgency rengini belirle
    Color urgencyColor;
    IconData urgencyIcon;
    
    switch (urgencyLevel) {
      case 3: // Critical - due date
        urgencyColor = const Color(0xFFFF3B30);
        urgencyIcon = Icons.error_outline;
        break;
      case 2: // High - 1 day before
        urgencyColor = const Color(0xFFFF9500);
        urgencyIcon = Icons.warning_outlined;
        break;
      default: // Normal - 3-7 days before
        urgencyColor = const Color(0xFF007AFF);
        urgencyIcon = Icons.info_outline;
        break;
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;
    
    return GestureDetector(
      onTap: () => _showNotificationDetail(reminder),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(
          right: index == (_pendingReminders.length - 1) ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: isDark 
            ? const Color(0xFF1C1C1E)
            : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDark 
            ? Border.all(
                color: const Color(0xFF38383A).withValues(alpha: 0.3),
                width: 0.5,
              )
            : null,
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and urgency indicator
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      urgencyIcon,
                      color: urgencyColor,
                      size: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                                             daysUntilDue == 0 ? 'Bugün' : 'Son $daysUntilDue Gün',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Card name
              Text(
                cardName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Debt amount
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    debtAmount > 0 ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                    size: 16,
                    color: debtAmount > 0 ? Color(0xFFFF453A) : Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 6),
              Text(
                    debtAmount > 0
                        ? 'Ekstre Borcu: ${Provider.of<ThemeProvider>(context, listen: false).formatAmount(debtAmount)}'
                        : 'Borç yok',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                      color: debtAmount > 0 ? const Color(0xFFFF453A) : const Color(0xFF4CAF50),
                ),
                  ),
                ],
              ),
              ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(PendingNotification reminder) {
    final data = reminder.data;
    final message = reminder.message;
    final cardId = data['cardId'] as String? ?? '';
    final cardName = data['cardName'] as String? ?? 'Kredi Kartı';
    final dueDateString = data['dueDate'] as String? ?? '';
    final dueDate = dueDateString.isNotEmpty ? DateTime.tryParse(dueDateString) : null;
    final type = data['type'] as String? ?? '';
    final urgencyLevel = data['urgencyLevel'] as int? ?? 1;
    final debtAmount = data['debtAmount'] as double? ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Urgency rengini belirle
    Color urgencyColor;
    IconData urgencyIcon;
    String urgencyText;
    
    switch (urgencyLevel) {
      case 3: // Critical - due date
        urgencyColor = const Color(0xFFFF3B30);
        urgencyIcon = Icons.error_outline;
        urgencyText = 'Acil';
        break;
      case 2: // High - 1 day before
        urgencyColor = const Color(0xFFFF9500);
        urgencyIcon = Icons.warning_outlined;
        urgencyText = 'Önemli';
        break;
      default: // Normal - 3-7 days before
        urgencyColor = const Color(0xFF007AFF);
        urgencyIcon = Icons.info_outline;
        urgencyText = 'Bilgi';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Urgency indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: urgencyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      urgencyIcon,
                      size: 16,
                      color: urgencyColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      urgencyText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: urgencyColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card name
              Text(
                cardName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Info cards
              if (debtAmount > 0 || dueDate != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                              color: (debtAmount > 0 ? const Color(0xFFFF453A) : const Color(0xFF4CAF50)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            child: Icon(
                              debtAmount > 0 ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                                size: 16,
                              color: debtAmount > 0 ? const Color(0xFFFF453A) : const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ekstre Borcu',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark 
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70),
                                    ),
                                  ),
                                  Text(
                                  debtAmount > 0
                                      ? 'Borç: ${debtAmount.toStringAsFixed(0)} TL'
                                      : 'Borç yok',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    color: debtAmount > 0 ? const Color(0xFFFF453A) : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (debtAmount > 0 && dueDate != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],
                      if (dueDate != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule_outlined,
                                size: 16,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Son Ödeme Tarihi',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark 
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70),
                                    ),
                                  ),
                                  Text(
                                    '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF007AFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _showAllNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Tüm Bildirimler',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Kapat',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _pendingReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _pendingReminders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDetailedNotificationItem(reminder, isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailedNotificationItem(PendingNotification reminder, bool isDark) {
    final data = reminder.data;
    final urgencyLevel = data['urgencyLevel'] as int? ?? 1;
    final cardName = data['cardName'] as String? ?? 'Kredi Kartı';
    final message = reminder.message;
    final dueDateString = data['dueDate'] as String? ?? '';
    final dueDate = dueDateString.isNotEmpty ? DateTime.tryParse(dueDateString) : null;
    final debtAmount = data['debtAmount'] as double? ?? 0.0;
    
    // Urgency rengini belirle
    Color urgencyColor;
    IconData urgencyIcon;
    String urgencyText;
    
    switch (urgencyLevel) {
      case 3: // Critical - due date
        urgencyColor = const Color(0xFFFF3B30);
        urgencyIcon = Icons.error_outline;
        urgencyText = 'Acil';
        break;
      case 2: // High - 1 day before
        urgencyColor = const Color(0xFFFF9500);
        urgencyIcon = Icons.warning_outlined;
        urgencyText = 'Önemli';
        break;
      default: // Normal - 3-7 days before
        urgencyColor = const Color(0xFF007AFF);
        urgencyIcon = Icons.info_outline;
        urgencyText = 'Bilgi';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  urgencyIcon,
                  color: urgencyColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cardName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            urgencyText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Son ödeme: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 