import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modules/transactions/models/recurring_frequency.dart';
import '../utils/date_utils.dart' as date_utils;

/// Recurring Transaction (Otomatik Tekrarlayan İşlem) Model
/// 
/// Abonelikler, faturalar, kira ödemeleri gibi tekrarlayan işlemler için kullanılır.
class RecurringTransaction {
  final String id;
  final String userId;
  final String name; // Abonelik adı (örn: "Netflix Premium")
  final RecurringCategory category; // Kategori (subscription, utilities, etc.)
  final double amount; // Tutar
  final RecurringFrequency frequency; // Sıklık (weekly, monthly, quarterly, yearly)
  final String accountId; // Ödeme hesabı
  final String? categoryId; // İşlem kategorisi (opsiyonel)
  final DateTime startDate; // Başlangıç tarihi
  final DateTime? endDate; // Bitiş tarihi (opsiyonel, null ise sınırsız)
  final bool isActive; // Aktif/Pasif durumu
  final DateTime? lastExecutedDate; // Son çalıştırılma tarihi
  final DateTime? nextExecutionDate; // Sonraki çalıştırılma tarihi
  final String? description; // Açıklama
  final String? notes; // Notlar
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringTransaction({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.accountId,
    this.categoryId,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.lastExecutedDate,
    this.nextExecutionDate,
    this.description,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore'dan oluştur
  factory RecurringTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringTransaction.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  /// JSON'dan oluştur
  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: RecurringCategory.values.firstWhere(
        (cat) => cat.name == (json['category'] as String? ?? 'other'),
        orElse: () => RecurringCategory.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      frequency: RecurringFrequency.values.firstWhere(
        (freq) => freq.name == (json['frequency'] as String? ?? 'monthly'),
        orElse: () => RecurringFrequency.monthly,
      ),
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      startDate: date_utils.DateUtils.fromFirebase(json['start_date']),
      endDate: json['end_date'] != null
          ? date_utils.DateUtils.fromFirebase(json['end_date'])
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastExecutedDate: json['last_executed_date'] != null
          ? date_utils.DateUtils.fromFirebase(json['last_executed_date'])
          : null,
      nextExecutionDate: json['next_execution_date'] != null
          ? date_utils.DateUtils.fromFirebase(json['next_execution_date'])
          : null,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      createdAt: date_utils.DateUtils.fromFirebase(json['created_at']),
      updatedAt: date_utils.DateUtils.fromFirebase(json['updated_at']),
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      // NOT: 'id' field'ı dahil etmiyoruz çünkü Firestore document ID olarak saklanıyor
      'user_id': userId,
      'name': name,
      'category': category.name,
      'amount': amount,
      'frequency': frequency.name,
      'account_id': accountId,
      'category_id': categoryId,
      'start_date': date_utils.DateUtils.toIso8601(startDate),
      'end_date': endDate != null
          ? date_utils.DateUtils.toIso8601(endDate!)
          : null,
      'is_active': isActive,
      'last_executed_date': lastExecutedDate != null
          ? date_utils.DateUtils.toIso8601(lastExecutedDate!)
          : null,
      'next_execution_date': nextExecutionDate != null
          ? date_utils.DateUtils.toIso8601(nextExecutionDate!)
          : null,
      'description': description,
      'notes': notes,
      'created_at': date_utils.DateUtils.toIso8601(createdAt),
      'updated_at': date_utils.DateUtils.toIso8601(updatedAt),
    };
  }

  /// Kopyalama metodu
  RecurringTransaction copyWith({
    String? id,
    String? userId,
    String? name,
    RecurringCategory? category,
    double? amount,
    RecurringFrequency? frequency,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? lastExecutedDate,
    DateTime? nextExecutionDate,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Aktif mi? (isActive && endDate kontrolü)
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    return true;
  }

  /// Sonraki ödeme tarihini hesapla
  /// 
  /// Mantık:
  /// - Her zaman startDate'deki günü baz alarak hesapla
  /// - lastExecutedDate olsa bile, startDate'deki günü kullan
  /// - Bu sayede kullanıcı ayın 1'ini seçtiğinde, sonraki kesim tarihi de ayın 1'i olur
  /// 
  /// Örnek:
  /// - Start date: 1 Ocak 2024, Frequency: Monthly
  /// - lastExecutedDate: 15 Ocak 2024 (bugün oluşturuldu)
  /// - nextExecutionDate: 1 Şubat 2024 (start date'deki günü kullan)
  DateTime calculateNextExecutionDate() {
    // Her zaman startDate'deki günü baz al
    // lastExecutedDate'in tarihi değil, startDate'in günü önemli
    final baseDay = startDate.day;
    final baseMonth = startDate.month;
    final baseYear = startDate.year;
    
    // Hangi tarihten itibaren hesaplayacağız?
    DateTime referenceDate;

    if (lastExecutedDate != null) {
      // Son çalıştırma tarihi varsa, ondan sonraki startDate gününü bul
      // Örnek: lastExecutedDate = 15 Ocak, startDate günü = 1
      // → Sonraki 1'i bul: 1 Şubat
      referenceDate = lastExecutedDate!;
    } else {
      // İlk çalıştırmada, startDate'den itibaren hesapla
      referenceDate = startDate;
    }

    switch (frequency) {
      case RecurringFrequency.weekly:
        // Start date'den 7 gün sonra
        return referenceDate.add(const Duration(days: 7));
        
      case RecurringFrequency.monthly:
        // Start date'deki günü kullanarak sonraki ayı hesapla
        // Örnek: Start date = 1 Ocak, lastExecutedDate = 15 Ocak
        // → Sonraki ayın 1'i = 1 Şubat
        var nextYear = referenceDate.year;
        var nextMonth = referenceDate.month + 1;
        
        // Ay taşması kontrolü
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        
        // Günü startDate'den al (ayın son günü kontrolü)
        var nextDay = baseDay;
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > daysInMonth) {
          nextDay = daysInMonth; // Ayın son günü
        }
        
        return DateTime(nextYear, nextMonth, nextDay);
        
      case RecurringFrequency.quarterly:
        // Start date'deki günü kullanarak 3 ay sonrasını hesapla
        var nextYear = referenceDate.year;
        var nextMonth = referenceDate.month + 3;
        
        // Ay taşması kontrolü
        while (nextMonth > 12) {
          nextMonth -= 12;
          nextYear++;
        }
        
        // Günü startDate'den al
        var nextDay = baseDay;
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > daysInMonth) {
          nextDay = daysInMonth;
        }
        
        return DateTime(nextYear, nextMonth, nextDay);
        
      case RecurringFrequency.yearly:
        // Start date'deki günü kullanarak 1 yıl sonrasını hesapla
        var nextYear = referenceDate.year + 1;
        var nextMonth = baseMonth;
        var nextDay = baseDay;
        
        // Şubat 29 kontrolü
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > daysInMonth) {
          nextDay = daysInMonth;
        }
        
        return DateTime(nextYear, nextMonth, nextDay);
    }
  }

  /// Aylık tutarı hesapla (farklı frequency'ler için normalize edilmiş)
  double get monthlyAmount {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return amount * 4.33; // Ortalama hafta sayısı
      case RecurringFrequency.monthly:
        return amount;
      case RecurringFrequency.quarterly:
        return amount / 3;
      case RecurringFrequency.yearly:
        return amount / 12;
    }
  }

  /// Yıllık tutarı hesapla
  double get yearlyAmount {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return amount * 52;
      case RecurringFrequency.monthly:
        return amount * 12;
      case RecurringFrequency.quarterly:
        return amount * 4;
      case RecurringFrequency.yearly:
        return amount;
    }
  }

  @override
  String toString() => 'RecurringTransaction($name, ${frequency.name}, $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

