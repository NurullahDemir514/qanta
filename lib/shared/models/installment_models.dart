import 'package:intl/intl.dart';

/// Ana taksitli işlem modeli (Master)
class InstallmentTransaction {
  final String id;
  final String userId;
  final String creditCardId;
  final double totalAmount;
  final int installmentCount;
  final String description;
  final String? category;
  final String? merchantName;
  final String? location;
  final String? notes;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // İlişkili veriler
  final List<InstallmentDetail>? installmentDetails;
  final String? cardName;
  final String? bankCode;

  const InstallmentTransaction({
    required this.id,
    required this.userId,
    required this.creditCardId,
    required this.totalAmount,
    required this.installmentCount,
    required this.description,
    this.category,
    this.merchantName,
    this.location,
    this.notes,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
    this.installmentDetails,
    this.cardName,
    this.bankCode,
  });

  /// JSON'dan model oluştur
  factory InstallmentTransaction.fromJson(Map<String, dynamic> json) {
    return InstallmentTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      creditCardId: json['credit_card_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      installmentCount: json['installment_count'] as int,
      description: json['description'] as String,
      category: json['category'] as String?,
      merchantName: json['merchant_name'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      cardName: json['card_name'] as String?,
      bankCode: json['bank_code'] as String?,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'credit_card_id': creditCardId,
      'total_amount': totalAmount,
      'installment_count': installmentCount,
      'description': description,
      'category': category,
      'merchant_name': merchantName,
      'location': location,
      'notes': notes,
      'purchase_date': purchaseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Aylık taksit tutarı
  double get monthlyAmount => totalAmount / installmentCount;

  /// Ödenen taksit sayısı
  int get paidInstallments {
    if (installmentDetails == null) return 0;
    return installmentDetails!.where((detail) => detail.isPaid).length;
  }

  /// Kalan taksit sayısı
  int get remainingInstallments => installmentCount - paidInstallments;

  /// Ödenen toplam tutar
  double get totalPaid {
    if (installmentDetails == null) return 0;
    return installmentDetails!
        .where((detail) => detail.isPaid)
        .fold(0, (sum, detail) => sum + (detail.paidAmount ?? 0));
  }

  /// Kalan toplam tutar
  double get totalRemaining => totalAmount - totalPaid;

  /// Sonraki ödeme tarihi
  DateTime? get nextDueDate {
    if (installmentDetails == null) return null;
    final unpaidDetails = installmentDetails!
        .where((detail) => !detail.isPaid)
        .toList();
    if (unpaidDetails.isEmpty) return null;
    unpaidDetails.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return unpaidDetails.first.dueDate;
  }

  /// Tamamlanma durumu
  bool get isCompleted => paidInstallments == installmentCount;

  /// İlerleme yüzdesi
  double get progressPercentage => (paidInstallments / installmentCount) * 100;

  /// Durum metni
  String get statusText {
    if (isCompleted) return 'Tamamlandı';
    return '$paidInstallments/$installmentCount Taksit Ödendi';
  }

  /// Kopya oluştur
  InstallmentTransaction copyWith({
    String? id,
    String? userId,
    String? creditCardId,
    double? totalAmount,
    int? installmentCount,
    String? description,
    String? category,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? purchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InstallmentDetail>? installmentDetails,
    String? cardName,
    String? bankCode,
  }) {
    return InstallmentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditCardId: creditCardId ?? this.creditCardId,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      description: description ?? this.description,
      category: category ?? this.category,
      merchantName: merchantName ?? this.merchantName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installmentDetails: installmentDetails ?? this.installmentDetails,
      cardName: cardName ?? this.cardName,
      bankCode: bankCode ?? this.bankCode,
    );
  }
}

/// Taksit detay modeli (Detail)
class InstallmentDetail {
  final String id;
  final String installmentTransactionId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final double? paidAmount;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentDetail({
    required this.id,
    required this.installmentTransactionId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.paidDate,
    this.paidAmount,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON'dan model oluştur
  factory InstallmentDetail.fromJson(Map<String, dynamic> json) {
    return InstallmentDetail(
      id: json['id'] as String,
      installmentTransactionId: json['installment_transaction_id'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      isPaid: json['is_paid'] as bool,
      paidDate: json['paid_date'] != null 
          ? DateTime.parse(json['paid_date'] as String).toLocal()
          : null,
      paidAmount: json['paid_amount'] != null 
          ? (json['paid_amount'] as num).toDouble() 
          : null,
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installment_transaction_id': installmentTransactionId,
      'installment_number': installmentNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'is_paid': isPaid,
      'paid_date': paidDate?.toIso8601String(),
      'paid_amount': paidAmount,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Vade durumu
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  /// Vadeye kalan gün sayısı
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Durum metni
  String get statusText {
    if (isPaid) return 'Ödendi';
    if (isOverdue) return 'Vadesi Geçti';
    if (daysUntilDue == 0) return 'Bugün Vadesi';
    if (daysUntilDue == 1) return 'Yarın Vadesi';
    if (daysUntilDue > 0) return '$daysUntilDue Gün Kaldı';
    return 'Vadesi Geçti';
  }

  /// Durum rengi
  String get statusColor {
    if (isPaid) return 'green';
    if (isOverdue) return 'red';
    if (daysUntilDue <= 3) return 'orange';
    return 'blue';
  }

  /// Formatlanmış vade tarihi
  String get formattedDueDate {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(dueDate);
  }

  /// Formatlanmış tutar
  String get formattedAmount {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Kopya oluştur
  InstallmentDetail copyWith({
    String? id,
    String? installmentTransactionId,
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidDate,
    double? paidAmount,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentDetail(
      id: id ?? this.id,
      installmentTransactionId: installmentTransactionId ?? this.installmentTransactionId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      paidAmount: paidAmount ?? this.paidAmount,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Taksit özeti modeli (View'dan gelen data için)
class InstallmentSummary {
  final String id;
  final String userId;
  final String creditCardId;
  final String? cardName;
  final String? bankCode;
  final double totalAmount;
  final int installmentCount;
  final String description;
  final String? category;
  final String? merchantName;
  final DateTime purchaseDate;
  final int paidInstallments;
  final int unpaidInstallments;
  final double totalPaid;
  final double totalRemaining;
  final DateTime? nextDueDate;

  const InstallmentSummary({
    required this.id,
    required this.userId,
    required this.creditCardId,
    this.cardName,
    this.bankCode,
    required this.totalAmount,
    required this.installmentCount,
    required this.description,
    this.category,
    this.merchantName,
    required this.purchaseDate,
    required this.paidInstallments,
    required this.unpaidInstallments,
    required this.totalPaid,
    required this.totalRemaining,
    this.nextDueDate,
  });

  /// JSON'dan model oluştur
  factory InstallmentSummary.fromJson(Map<String, dynamic> json) {
    return InstallmentSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      creditCardId: json['credit_card_id'] as String,
      cardName: json['card_name'] as String?,
      bankCode: json['bank_code'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      installmentCount: json['installment_count'] as int,
      description: json['description'] as String,
      category: json['category'] as String?,
      merchantName: json['merchant_name'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String).toLocal(),
      paidInstallments: json['paid_installments'] as int,
      unpaidInstallments: json['unpaid_installments'] as int,
      totalPaid: (json['total_paid'] as num).toDouble(),
      totalRemaining: (json['total_remaining'] as num).toDouble(),
      nextDueDate: json['next_due_date'] != null 
          ? DateTime.parse(json['next_due_date'] as String).toLocal()
          : null,
    );
  }

  /// Tamamlanma durumu
  bool get isCompleted => unpaidInstallments == 0;

  /// İlerleme yüzdesi
  double get progressPercentage => (paidInstallments / installmentCount) * 100;

  /// Aylık taksit tutarı
  double get monthlyAmount => totalAmount / installmentCount;
}

/// Yaklaşan taksit modeli
class UpcomingInstallment {
  final String installmentTransactionId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final String description;
  final String? cardName;
  final int daysUntilDue;

  const UpcomingInstallment({
    required this.installmentTransactionId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.description,
    this.cardName,
    required this.daysUntilDue,
  });

  /// JSON'dan model oluştur
  factory UpcomingInstallment.fromJson(Map<String, dynamic> json) {
    return UpcomingInstallment(
      installmentTransactionId: json['installment_transaction_id'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      description: json['description'] as String,
      cardName: json['card_name'] as String?,
      daysUntilDue: json['days_until_due'] as int,
    );
  }

  /// Formatlanmış tutar
  String get formattedAmount {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Formatlanmış vade tarihi
  String get formattedDueDate {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(dueDate);
  }

  /// Durum metni
  String get statusText {
    if (daysUntilDue == 0) return 'Bugün Vadesi';
    if (daysUntilDue == 1) return 'Yarın Vadesi';
    if (daysUntilDue > 0) return '$daysUntilDue Gün Kaldı';
    return 'Vadesi Geçti';
  }

  /// Aciliyet seviyesi
  String get urgencyLevel {
    if (daysUntilDue < 0) return 'overdue';
    if (daysUntilDue == 0) return 'today';
    if (daysUntilDue <= 3) return 'urgent';
    if (daysUntilDue <= 7) return 'warning';
    return 'normal';
  }
} 