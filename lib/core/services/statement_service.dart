import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/models_v2.dart';

class StatementService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Kredi kartının mevcut ekstre dönemini hesapla
  static StatementPeriod getCurrentStatementPeriod(int statementDay) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Bu ayın ekstre tarihi
    DateTime currentStatementDate = DateTime(currentYear, currentMonth, statementDay);
    
    // Bu ayın son ödeme tarihini hesapla
    DateTime currentDueDate = currentStatementDate.add(const Duration(days: 10));
    while (currentDueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      currentDueDate = currentDueDate.add(const Duration(days: 1));
    }
    
    // Eğer bu ayın son ödeme tarihi henüz geçmemişse, bu ayın ekstre dönemini göster
    if (currentDueDate.isAfter(now) || currentDueDate.isAtSameMomentAs(now)) {
      // Geçen ayın ekstre tarihi
      DateTime previousStatementDate;
      if (currentMonth == 1) {
        previousStatementDate = DateTime(currentYear - 1, 12, statementDay);
      } else {
        previousStatementDate = DateTime(currentYear, currentMonth - 1, statementDay);
      }
      
      return StatementPeriod(
        startDate: previousStatementDate.add(const Duration(days: 1)),
        endDate: currentStatementDate,
        statementDate: currentStatementDate,
        dueDate: currentDueDate,
      );
    } else {
      // Bu ayın son ödeme tarihi geçmişse, gelecek ayın ekstre dönemini göster
      DateTime nextStatementDate;
      if (currentMonth == 12) {
        nextStatementDate = DateTime(currentYear + 1, 1, statementDay);
      } else {
        nextStatementDate = DateTime(currentYear, currentMonth + 1, statementDay);
      }
      
      return StatementPeriod(
        startDate: currentStatementDate.add(const Duration(days: 1)),
        endDate: nextStatementDate,
        statementDate: nextStatementDate,
        dueDate: _calculateDueDate(nextStatementDate),
      );
    }
  }

  /// Önceki ekstre dönemini hesapla
  static StatementPeriod getPreviousStatementPeriod(int statementDay) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Bu ayın ekstre tarihi
    DateTime currentStatementDate = DateTime(currentYear, currentMonth, statementDay);
    
    // Geçen ayın ekstre tarihi
    DateTime previousStatementDate;
    if (currentMonth == 1) {
      previousStatementDate = DateTime(currentYear - 1, 12, statementDay);
    } else {
      previousStatementDate = DateTime(currentYear, currentMonth - 1, statementDay);
    }
    
    // Ondan önceki ayın ekstre tarihi
    DateTime beforePreviousStatementDate;
    if (previousStatementDate.month == 1) {
      beforePreviousStatementDate = DateTime(previousStatementDate.year - 1, 12, statementDay);
    } else {
      beforePreviousStatementDate = DateTime(previousStatementDate.year, previousStatementDate.month - 1, statementDay);
    }
    
    // Eğer bugün bu ayın ekstre tarihinden sonraysa, önceki dönem: geçen ayın ekstre tarihi
    // Eğer bugün bu ayın ekstre tarihinden önceyse, önceki dönem: ondan önceki ayın ekstre tarihi
    if (now.isAfter(currentStatementDate) || now.isAtSameMomentAs(currentStatementDate)) {
      return StatementPeriod(
        startDate: beforePreviousStatementDate.add(const Duration(days: 1)),
        endDate: previousStatementDate,
        statementDate: previousStatementDate,
        dueDate: _calculateDueDate(previousStatementDate),
      );
    } else {
      // Daha da önceki dönem
      DateTime beforeBeforePreviousStatementDate;
      if (beforePreviousStatementDate.month == 1) {
        beforeBeforePreviousStatementDate = DateTime(beforePreviousStatementDate.year - 1, 12, statementDay);
      } else {
        beforeBeforePreviousStatementDate = DateTime(beforePreviousStatementDate.year, beforePreviousStatementDate.month - 1, statementDay);
      }
      
      return StatementPeriod(
        startDate: beforeBeforePreviousStatementDate.add(const Duration(days: 1)),
        endDate: beforePreviousStatementDate,
        statementDate: beforePreviousStatementDate,
        dueDate: _calculateDueDate(beforePreviousStatementDate),
      );
    }
  }

  /// Gelecek ekstre dönemini hesapla
  static StatementPeriod getNextStatementPeriod(int statementDay) {
    final currentPeriod = getCurrentStatementPeriod(statementDay);
    final currentStatementDate = currentPeriod.statementDate;
    
    // Gelecek dönemin ekstre tarihi (mevcut ekstre tarihinden 1 ay sonra)
    DateTime nextStatementDate;
    if (currentStatementDate.month == 12) {
      nextStatementDate = DateTime(currentStatementDate.year + 1, 1, statementDay);
    } else {
      nextStatementDate = DateTime(currentStatementDate.year, currentStatementDate.month + 1, statementDay);
    }
    
    return StatementPeriod(
      startDate: currentStatementDate.add(const Duration(days: 1)),
      endDate: nextStatementDate,
      statementDate: nextStatementDate,
      dueDate: _calculateDueDate(nextStatementDate),
    );
  }

  /// Belirli sayıda gelecek dönem hesapla
  static List<StatementPeriod> getFutureStatementPeriods(int statementDay, int count) {
    final periods = <StatementPeriod>[];
    final currentPeriod = getCurrentStatementPeriod(statementDay);
    var lastStatementDate = currentPeriod.statementDate;
    
    for (int i = 0; i < count; i++) {
      // Bir sonraki ayın ekstre tarihi
      DateTime nextStatementDate;
      if (lastStatementDate.month == 12) {
        nextStatementDate = DateTime(lastStatementDate.year + 1, 1, statementDay);
      } else {
        nextStatementDate = DateTime(lastStatementDate.year, lastStatementDate.month + 1, statementDay);
      }
      
      final period = StatementPeriod(
        startDate: lastStatementDate.add(const Duration(days: 1)),
        endDate: nextStatementDate,
        statementDate: nextStatementDate,
        dueDate: _calculateDueDate(nextStatementDate),
      );
      
      periods.add(period);
      lastStatementDate = nextStatementDate;
    }
    
    return periods;
  }

  /// Aktif taksitlerin son ödeme tarihini bul
  static Future<DateTime?> getLastInstallmentDate(String cardId) async {
    try {
      final response = await _supabase
          .from('installment_details')
          .select('''
            due_date,
            installment_transactions!inner(source_account_id)
          ''')
          .eq('installment_transactions.source_account_id', cardId)
          .eq('is_paid', false)
          .order('due_date', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return DateTime.parse(response[0]['due_date']);
      }
      return null;
    } catch (e) {
      print('Error getting last installment date: $e');
      return null;
    }
  }

  /// Son taksit bitene kadar olan dönemleri hesapla
  static Future<List<StatementPeriod>> getFuturePeriodsUntilLastInstallment(String cardId, int statementDay) async {
    try {
      final lastInstallmentDate = await getLastInstallmentDate(cardId);
      
      if (lastInstallmentDate == null) {
        // Taksit yoksa sadece 3 ay göster
        return getFutureStatementPeriods(statementDay, 3);
      }
      
      final periods = <StatementPeriod>[];
      final currentPeriod = getCurrentStatementPeriod(statementDay);
      var lastStatementDate = currentPeriod.statementDate;
      
      // Son taksit tarihine kadar dönemleri hesapla
      while (lastStatementDate.isBefore(lastInstallmentDate)) {
        DateTime nextStatementDate;
        if (lastStatementDate.month == 12) {
          nextStatementDate = DateTime(lastStatementDate.year + 1, 1, statementDay);
        } else {
          nextStatementDate = DateTime(lastStatementDate.year, lastStatementDate.month + 1, statementDay);
        }
        
        final period = StatementPeriod(
          startDate: lastStatementDate.add(const Duration(days: 1)),
          endDate: nextStatementDate,
          statementDate: nextStatementDate,
          dueDate: _calculateDueDate(nextStatementDate),
        );
        
        periods.add(period);
        lastStatementDate = nextStatementDate;
        
        // Güvenlik için maksimum 24 ay sınırı
        if (periods.length >= 24) break;
      }
      
      // En az 1 dönem göster
      if (periods.isEmpty) {
        periods.addAll(getFutureStatementPeriods(statementDay, 1));
      }
      
      return periods;
    } catch (e) {
      print('Error calculating future periods: $e');
      // Hata durumunda varsayılan 3 ay döndür
      return getFutureStatementPeriods(statementDay, 3);
    }
  }

  /// Son ödeme tarihini hesapla (ekstre tarihinden 10 gün sonra, hafta içi)
  static DateTime _calculateDueDate(DateTime statementDate) {
    // Ekstre tarihinden 10 gün sonra
    DateTime tentativeDueDate = statementDate.add(const Duration(days: 10));
    
    // İlk hafta içi günü bul (Pazartesi=1, Salı=2, ..., Cuma=5)
    DateTime dueDate = tentativeDueDate;
    while (dueDate.weekday > 5) { // 6=Cumartesi, 7=Pazar
      dueDate = dueDate.add(const Duration(days: 1));
    }
    
    return dueDate;
  }

  /// Belirli dönemdeki kredi kartı işlemlerini getir
  static Future<List<TransactionWithDetailsV2>> getStatementTransactions(
    String cardId,
    StatementPeriod period,
  ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            id,
            user_id,
            type,
            amount,
            description,
            transaction_date,
            category_id,
            source_account_id,
            target_account_id,
            installment_id,
            is_recurring,
            notes,
            created_at,
            updated_at,
            categories(id, name, icon, color),
            source_account:accounts!source_account_id(id, name, type, bank_name),
            target_account:accounts!target_account_id(id, name, type, bank_name)
          ''')
          .eq('source_account_id', cardId)
          .gte('transaction_date', period.startDate.toIso8601String())
          .lte('transaction_date', period.endDate.toIso8601String())
          .order('transaction_date', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      // JSON'u TransactionWithDetailsV2 formatına dönüştür
      return response.map((data) {
        // Nested objelerden bilgileri çıkar
        final category = data['categories'] as Map<String, dynamic>?;
        final sourceAccount = data['source_account'] as Map<String, dynamic>?;
        final targetAccount = data['target_account'] as Map<String, dynamic>?;
        
        // Düzleştirilmiş JSON oluştur
        final flattenedData = Map<String, dynamic>.from(data);
        
        // Kategori bilgilerini ekle
        if (category != null) {
          flattenedData['category_name'] = category['name'];
          flattenedData['category_icon'] = category['icon'];
          flattenedData['category_color'] = category['color'];
        }
        
        // Hesap bilgilerini ekle
        if (sourceAccount != null) {
          flattenedData['source_account_name'] = sourceAccount['name'];
          flattenedData['source_account_type'] = sourceAccount['type'];
        }
        
        if (targetAccount != null) {
          flattenedData['target_account_name'] = targetAccount['name'];
          flattenedData['target_account_type'] = targetAccount['type'];
        }
        
        return TransactionWithDetailsV2.fromJson(flattenedData);
      }).toList();
    } catch (e) {
      print('Error fetching statement transactions: $e');
      return [];
    }
  }

  /// Gelecek dönemde vadesi gelecek taksitleri getir
  static Future<List<UpcomingInstallment>> getUpcomingInstallments(
    String cardId,
    StatementPeriod period,
  ) async {
    try {
      final response = await _supabase
          .from('installment_details')
          .select('''
            id,
            installment_number,
            due_date,
            amount,
            is_paid,
            installment_transactions!inner(
              id,
              description,
              source_account_id,
              total_amount,
              monthly_amount,
              count,
              categories(id, name, icon, color)
            )
          ''')
          .eq('installment_transactions.source_account_id', cardId)
          .eq('is_paid', false)
          .gte('due_date', period.startDate.toIso8601String())
          .lte('due_date', period.endDate.toIso8601String())
          .order('due_date', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => UpcomingInstallment.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching upcoming installments: $e');
      return [];
    }
  }

  /// Ekstre özetini hesapla
  static Future<StatementSummary> calculateStatementSummary(
    String cardId,
    StatementPeriod period,
  ) async {
    try {
      // Dönem içi işlemleri getir
      final transactions = await getStatementTransactions(cardId, period);
      
      // Gelecek taksitleri getir
      final upcomingInstallments = await getUpcomingInstallments(cardId, period);
      
      // Toplam harcama hesapla (sadece expense türü)
      double totalSpent = 0.0;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          totalSpent += transaction.amount;
        }
      }
      
      // Gelecek taksit tutarını ekle
      double upcomingInstallmentAmount = 0.0;
      for (final installment in upcomingInstallments) {
        upcomingInstallmentAmount += installment.amount;
      }
      
      // Kategori dağılımını hesapla
      final Map<String, double> categoryBreakdown = {};
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          final categoryName = transaction.categoryName ?? 'Diğer';
          categoryBreakdown[categoryName] = (categoryBreakdown[categoryName] ?? 0.0) + transaction.amount;
        }
      }
      
      // Ödeme durumunu kontrol et
      final isPaid = await isStatementPaid(cardId, period);
      final paidDate = isPaid ? await getStatementPaidDate(cardId, period) : null;
      
      return StatementSummary(
        period: period,
        totalSpent: totalSpent,
        upcomingInstallmentAmount: upcomingInstallmentAmount,
        transactionCount: transactions.length,
        categoryBreakdown: categoryBreakdown,
        transactions: transactions,
        upcomingInstallments: upcomingInstallments,
        isPaid: isPaid,
        paidDate: paidDate,
      );
    } catch (e) {
      print('Error calculating statement summary: $e');
      rethrow;
    }
  }

  /// Test amaçlı debug fonksiyonu
  static void debugStatementPeriods(int statementDay) {
    print('=== EKSTRE DÖNEM DEBUG ===');
    print('Ekstre günü: $statementDay');
    print('Bugün: ${DateTime.now()}');
    
    final current = getCurrentStatementPeriod(statementDay);
    print('AKTİF DÖNEM: ${current.startDate.day}/${current.startDate.month} - ${current.endDate.day}/${current.endDate.month}');
    print('Ekstre tarihi: ${current.statementDate.day}/${current.statementDate.month}');
    print('Son ödeme: ${current.dueDate.day}/${current.dueDate.month}');
    print('Kalan gün: ${current.daysUntilDue}');
    
    final previous = getPreviousStatementPeriod(statementDay);
    print('KESİLMİŞ DÖNEM: ${previous.startDate.day}/${previous.startDate.month} - ${previous.endDate.day}/${previous.endDate.month}');
    print('Ekstre tarihi: ${previous.statementDate.day}/${previous.statementDate.month}');
    
    final next = getNextStatementPeriod(statementDay);
    print('GELECEK DÖNEM: ${next.startDate.day}/${next.startDate.month} - ${next.endDate.day}/${next.endDate.month}');
    print('========================');
  }

  /// Veritabanındaki giderleri kontrol et (test amaçlı)
  static Future<void> debugDatabaseTransactions(String? cardId) async {
    try {
      print('=== VERİTABANI GİDER DEBUG ===');
      
      // Tüm giderleri kategori ile getir
      final allExpenses = await _supabase
          .from('transactions')
          .select('''
            id, type, amount, description, transaction_date, source_account_id,
            categories(name)
          ''')
          .eq('type', 'expense')
          .limit(10)
          .order('transaction_date', ascending: false);
      
      print('Toplam gider sayısı: ${allExpenses.length}');
      for (final expense in allExpenses) {
        final categoryName = expense['categories']?['name'] ?? 'Kategori Yok';
        print('- ${expense['description']}: ${expense['amount']} TL (${expense['transaction_date']})');
        print('  Kategori: $categoryName, Hesap: ${expense['source_account_id']}');
      }
      
      // Belirli karta ait giderler
      if (cardId != null) {
        print('\n=== KART GİDERLERİ ($cardId) ===');
        final cardExpenses = await _supabase
            .from('transactions')
            .select('''
              id, type, amount, description, transaction_date,
              categories(name)
            ''')
            .eq('type', 'expense')
            .eq('source_account_id', cardId)
            .limit(10)
            .order('transaction_date', ascending: false);
        
        print('Kart gider sayısı: ${cardExpenses.length}');
        for (final expense in cardExpenses) {
          final categoryName = expense['categories']?['name'] ?? 'Kategori Yok';
          print('- ${expense['description']}: ${expense['amount']} TL (${expense['transaction_date']})');
          print('  Kategori: $categoryName');
        }
      }
      
      // Hesapları listele
      print('\n=== HESAPLAR ===');
      final accounts = await _supabase
          .from('accounts')
          .select('id, name, type, bank_name')
          .eq('type', 'credit')
          .limit(5);
      
      print('Kredi kartı sayısı: ${accounts.length}');
      for (final account in accounts) {
        print('- ${account['name']} (${account['bank_name']}): ${account['id']}');
      }
      
      print('==============================');
    } catch (e) {
      print('Veritabanı debug hatası: $e');
    }
  }

  /// Ekstre ödeme durumunu kontrol et (Local Storage)
  static Future<bool> isStatementPaid(String cardId, StatementPeriod period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'statement_paid_${cardId}_${period.statementDate.toIso8601String()}';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('Error checking statement payment: $e');
      return false;
    }
  }

  /// Ekstre ödeme tarihini al (Local Storage)
  static Future<DateTime?> getStatementPaidDate(String cardId, StatementPeriod period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'statement_paid_date_${cardId}_${period.statementDate.toIso8601String()}';
      final dateString = prefs.getString(key);
      
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      print('Error getting statement paid date: $e');
      return null;
    }
  }

  /// Ekstreyi ödendi olarak işaretle (Local Storage)
  static Future<bool> markStatementAsPaid(String cardId, StatementPeriod period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paidKey = 'statement_paid_${cardId}_${period.statementDate.toIso8601String()}';
      final dateKey = 'statement_paid_date_${cardId}_${period.statementDate.toIso8601String()}';
      
      await prefs.setBool(paidKey, true);
      await prefs.setString(dateKey, DateTime.now().toIso8601String());
      
      return true;
    } catch (e) {
      print('Error marking statement as paid: $e');
      return false;
    }
  }

  /// Ekstre ödeme işaretini kaldır (Local Storage)
  static Future<bool> unmarkStatementAsPaid(String cardId, StatementPeriod period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paidKey = 'statement_paid_${cardId}_${period.statementDate.toIso8601String()}';
      final dateKey = 'statement_paid_date_${cardId}_${period.statementDate.toIso8601String()}';
      
      await prefs.remove(paidKey);
      await prefs.remove(dateKey);
      
      return true;
    } catch (e) {
      print('Error unmarking statement as paid: $e');
      return false;
    }
  }
}

/// Ekstre dönemi modeli
class StatementPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime statementDate;
  final DateTime dueDate;

  StatementPeriod({
    required this.startDate,
    required this.endDate,
    required this.statementDate,
    required this.dueDate,
  });

  String get periodText {
    final startDay = startDate.day;
    final startMonth = _getMonthName(startDate.month);
    final endDay = endDate.day;
    final endMonth = _getMonthName(endDate.month);
    
    if (startDate.year == endDate.year) {
      return '$startDay $startMonth - $endDay $endMonth ${endDate.year}';
    } else {
      return '$startDay $startMonth ${startDate.year} - $endDay $endMonth ${endDate.year}';
    }
  }

  String get dueDateText {
    final day = dueDate.day;
    final month = _getMonthName(dueDate.month);
    final year = dueDate.year;
    return '$day $month $year';
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return months[month];
  }
}

/// Gelecek taksit modeli
class UpcomingInstallment {
  final String id;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String description;
  final int totalInstallments;
  final String? categoryIcon;
  final String? categoryColor;

  UpcomingInstallment({
    required this.id,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.description,
    required this.totalInstallments,
    this.categoryIcon,
    this.categoryColor,
  });

  factory UpcomingInstallment.fromJson(Map<String, dynamic> json) {
    final installmentTransaction = json['installment_transactions'];
    final category = installmentTransaction?['categories'];
    
    return UpcomingInstallment(
      id: json['id'],
      installmentNumber: json['installment_number'],
      dueDate: DateTime.parse(json['due_date']),
      amount: (json['amount'] as num).toDouble(),
      description: installmentTransaction?['description'] ?? '',
      totalInstallments: installmentTransaction?['count'] ?? 1,
      categoryIcon: category?['icon'],
      categoryColor: category?['color'],
    );
  }

  String get installmentText {
    return '$installmentNumber/$totalInstallments Taksit';
  }
}

/// Ekstre özeti modeli
class StatementSummary {
  final StatementPeriod period;
  final double totalSpent;
  final double upcomingInstallmentAmount;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final List<TransactionWithDetailsV2> transactions;
  final List<UpcomingInstallment> upcomingInstallments;
  final bool isPaid;
  final DateTime? paidDate;

  StatementSummary({
    required this.period,
    required this.totalSpent,
    required this.upcomingInstallmentAmount,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.transactions,
    required this.upcomingInstallments,
    this.isPaid = false,
    this.paidDate,
  });

  double get totalWithInstallments => totalSpent + upcomingInstallmentAmount;
  
  List<CategoryBreakdownItem> get sortedCategoryBreakdown {
    final items = categoryBreakdown.entries
        .map((entry) => CategoryBreakdownItem(
              name: entry.key,
              amount: entry.value,
              percentage: totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0,
            ))
        .toList();
    
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}

/// Kategori dağılım öğesi
class CategoryBreakdownItem {
  final String name;
  final double amount;
  final double percentage;

  CategoryBreakdownItem({
    required this.name,
    required this.amount,
    required this.percentage,
  });
} 