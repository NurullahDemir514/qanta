import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/statement_service.dart';
import '../../../core/services/transaction_service_v2.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';

/// Ana sayfada bildirimler bölümü
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  List<Map<String, dynamic>> _pendingReminders = [];
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
    debugPrint('🔔 _loadPendingReminders called!');
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
      final now = DateTime.now();
      final upcomingNotifications = <Map<String, dynamic>>[];
       
       // Önce raw account verilerini kontrol et
       final rawCreditCards = provider.accounts.where((a) => a.type.toString() == 'AccountType.credit').toList();
       debugPrint('🔔 Raw credit cards count: ${rawCreditCards.length}');
       for (final card in rawCreditCards) {
         debugPrint('🔔 Raw card: ${card.name}, balance: ${card.balance}, creditLimit: ${card.creditLimit}, available: ${card.availableAmount}');
       }
       
       // Tüm kredi kartlarını kontrol et
       for (final creditCard in provider.creditCards) {
         final cardId = creditCard['id'] as String;
         final cardName = creditCard['cardName'] as String? ?? creditCard['bankName'] as String? ?? 'Kredi Kartı';
         final statementDay = creditCard['statementDay'] as int? ?? 1;
         final totalDebt = creditCard['totalDebt'] as double? ?? 0.0;
         final creditLimit = creditCard['creditLimit'] as double? ?? 0.0;
         final availableLimit = creditCard['availableLimit'] as double? ?? 0.0;
         
         // Mevcut dönem için son ödeme tarihini hesapla
         final currentPeriod = StatementService.getCurrentStatementPeriod(statementDay);
         
         // Bu dönem borcunu hesapla (mevcut ekstre dönemindeki harcamalar)
         final debtAmount = await _calculateCurrentPeriodDebt(cardId, currentPeriod);
         
         debugPrint('🔔 Credit card data: cardId=$cardId, currentPeriodDebt=$debtAmount');
         
         final daysUntilDue = currentPeriod.dueDate.difference(now).inDays;
         
         debugPrint('🔔 Checking card: $cardName, dueDate: ${currentPeriod.dueDate}, daysUntil: $daysUntilDue, debt: $debtAmount, totalDebt: $totalDebt, creditLimit: $creditLimit');
        
        // 7 gün içinde vadesi dolacak kartları bildirim olarak ekle
        if (daysUntilDue >= 0 && daysUntilDue <= 7) {
          String type;
          String shortMessage;
          int urgencyLevel;
          
          if (daysUntilDue == 0) {
            type = 'due_date';
            shortMessage = 'Bugün son ödeme tarihi';
            urgencyLevel = 3;
          } else if (daysUntilDue == 1) {
            type = '1_day_before';
            shortMessage = 'Yarın son ödeme';
            urgencyLevel = 2;
          } else if (daysUntilDue <= 3) {
            type = '3_days_before';
            shortMessage = '$daysUntilDue gün sonra vade';
            urgencyLevel = 1;
          } else {
            type = '7_days_before';
            shortMessage = '$daysUntilDue gün sonra vade';
            urgencyLevel = 1;
          }
          
                     upcomingNotifications.add({
             'key': 'upcoming_${cardId}_${currentPeriod.statementDate.toIso8601String()}',
             'data': {
               'cardId': cardId,
               'cardName': cardName,
               'type': type,
               'dueDate': currentPeriod.dueDate.toIso8601String(),
               'dueDateText': currentPeriod.dueDateText,
               'urgencyLevel': urgencyLevel,
               'shortMessage': shortMessage,
               'debtAmount': debtAmount,
             },
             'message': _getNotificationMessage(type, cardName, daysUntilDue),
           });
          
          debugPrint('🔔 Added upcoming notification: $cardName - $type ($daysUntilDue days)');
        }
      }
      
      // Urgency level'a göre sırala (en acil önce)
      upcomingNotifications.sort((a, b) {
        final aUrgency = a['data']['urgencyLevel'] as int;
        final bUrgency = b['data']['urgencyLevel'] as int;
        return bUrgency.compareTo(aUrgency); // Descending order
      });
      
      debugPrint('🔔 Total upcoming notifications: ${upcomingNotifications.length}');
      
      if (mounted) {
        setState(() {
          _pendingReminders = upcomingNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading upcoming notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      // TransactionServiceV2 kullanarak bu kartın tüm işlemlerini çek
      final allTransactions = await TransactionServiceV2.getTransactionsByAccount(
        accountId: cardId,
        limit: 1000,
      );
      
      // Bu dönemdeki işlemleri filtrele
      final periodTransactions = allTransactions.where((transaction) {
        final transactionDate = transaction.transactionDate;
        return transactionDate.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(period.endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Sadece expense işlemlerini topla (gider)
      double totalExpenses = 0.0;
      for (final transaction in periodTransactions) {
        if (transaction.type.toString() == 'TransactionType.expense') {
          totalExpenses += transaction.amount;
        }
      }
      
             debugPrint('🔔 Period debt calculation: cardId=$cardId, allTransactions=${allTransactions.length}, periodTransactions=${periodTransactions.length}, totalExpenses=$totalExpenses');
       debugPrint('🔔 Period: ${period.startDate} to ${period.endDate}');
       
       // Debug: period transactions details
       for (final transaction in periodTransactions) {
         debugPrint('🔔 Period transaction: ${transaction.description}, amount: ${transaction.amount}, type: ${transaction.type}, date: ${transaction.transactionDate}');
       }
      return totalExpenses;
    } catch (e) {
      debugPrint('🔔 Error calculating period debt: $e');
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
    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        if (_isLoading) {
          return const SizedBox.shrink();
        }
        
        // Debug: bildirim durumunu kontrol et
        debugPrint('🔔 NotificationsSection build - isLoading: $_isLoading, reminders count: ${_pendingReminders.length}');
        
        // Eğer bildirim yoksa gizle
        if (_pendingReminders.isEmpty) {
          debugPrint('🔔 NotificationsSection hidden - no reminders');
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
              'Bildirimler',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            GestureDetector(
              onTap: _showAllNotifications,
              child: Text(
                'Tümü',
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
      },
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
              'Bildirim yok',
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

  Widget _buildNotificationCard(Map<String, dynamic> reminder, bool isDark, int index) {
    final data = reminder['data'] as Map<String, dynamic>? ?? {};
    final cardId = data['cardId'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    final cardName = data['cardName'] as String? ?? 'Kredi Kartı';
    final urgencyLevel = data['urgencyLevel'] as int? ?? 1;
    final shortMessage = data['shortMessage'] as String? ?? 'Ekstre hatırlatıcısı';
    final debtAmount = data['debtAmount'] as double? ?? 0.0;
    
    // Debug: veri içeriğini kontrol et
    debugPrint('🔔 Card ID: $cardId, Card name: $cardName, Type: $type, Urgency: $urgencyLevel, Debt: $debtAmount');
    
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                      urgencyLevel == 3 ? 'Acil' : urgencyLevel == 2 ? 'Önemli' : 'Bilgi',
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
              Text(
                'Ekstre Borcu: ₺${debtAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF453A), // Red color for debt
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Short message
              Flexible(
                child: Text(
                  shortMessage,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> reminder) {
    final data = reminder['data'] as Map<String, dynamic>? ?? {};
    final message = reminder['message'] as String? ?? '';
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
                      if (debtAmount > 0) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF453A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 16,
                                color: Color(0xFFFF453A),
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
                                    'Borç: ${debtAmount.toStringAsFixed(0)} TL',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFF453A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (dueDate != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],
                      ],
                      
                      if (dueDate != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
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

  Widget _buildDetailedNotificationItem(Map<String, dynamic> reminder, bool isDark) {
    final data = reminder['data'] as Map<String, dynamic>? ?? {};
    final urgencyLevel = data['urgencyLevel'] as int? ?? 1;
    final cardName = data['cardName'] as String? ?? 'Kredi Kartı';
    final message = reminder['message'] as String? ?? '';
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