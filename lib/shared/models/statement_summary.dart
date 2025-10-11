import 'statement_period.dart';
import '../utils/date_utils.dart';

/// Statement summary model for credit card statements
class StatementSummary {
  final String id;
  final String cardId;
  final StatementPeriod period;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int transactionCount;
  final List<UpcomingInstallment> upcomingInstallments;
  final bool isPaid;
  final DateTime? paidAt;

  StatementSummary({
    required this.id,
    required this.cardId,
    required this.period,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.transactionCount,
    required this.upcomingInstallments,
    this.isPaid = false,
    this.paidAt,
  });

  /// Create from JSON with safe date parsing
  ///
  /// **Updated:** Uses DateUtils for consistent Firebase date handling
  factory StatementSummary.fromJson(Map<String, dynamic> json) {
    return StatementSummary(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      period: StatementPeriod.fromJson(json['period'] as Map<String, dynamic>),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      upcomingInstallments: (json['upcoming_installments'] as List<dynamic>)
          .map(
            (item) =>
                UpcomingInstallment.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? DateUtils.fromFirebase(json['paid_at'])
          : null,
    );
  }

  /// Convert to JSON with consistent date formatting
  ///
  /// **Updated:** Uses DateUtils for consistent Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_id': cardId,
      'period': period.toJson(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'transaction_count': transactionCount,
      'upcoming_installments': upcomingInstallments
          .map((item) => item.toJson())
          .toList(),
      'is_paid': isPaid,
      'paid_at': paidAt != null ? DateUtils.toIso8601(paidAt!) : null,
    };
  }

  /// Check if this statement is overdue
  bool get isOverdue {
    return !isPaid && period.isOverdue;
  }

  /// Get days until due date
  int get daysUntilDue {
    return period.daysUntilDue;
  }

  /// Get days overdue
  int get daysOverdue {
    return period.daysOverdue;
  }

  /// Get payment status text
  String get paymentStatusText {
    if (isPaid) return 'Ödendi';
    if (isOverdue) return 'Gecikmiş';
    return 'Beklemede';
  }

  /// Get total spent amount (same as totalAmount)
  double get totalSpent => totalAmount;

  /// Get total with installments (includes upcoming installments)
  double get totalWithInstallments {
    final upcomingTotal = upcomingInstallments
        .where((installment) => !installment.isPaid)
        .fold<double>(0.0, (sum, installment) => sum + installment.amount);
    return totalAmount + upcomingTotal;
  }

  /// Get transactions list (empty for now)
  List<Map<String, dynamic>> get transactions => [];

  /// Copy with method
  StatementSummary copyWith({
    String? id,
    String? cardId,
    StatementPeriod? period,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    int? transactionCount,
    List<UpcomingInstallment>? upcomingInstallments,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return StatementSummary(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      period: period ?? this.period,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      transactionCount: transactionCount ?? this.transactionCount,
      upcomingInstallments: upcomingInstallments ?? this.upcomingInstallments,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  String toString() {
    return 'StatementSummary(id: $id, cardId: $cardId, totalAmount: $totalAmount, isPaid: $isPaid)';
  }
}

/// Upcoming installment model
class UpcomingInstallment {
  final String id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime? startDate; // Transaction date when it was made
  final int installmentNumber;
  final int totalInstallments;
  final bool isPaid;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  UpcomingInstallment({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.startDate, // Optional for backward compatibility
    required this.installmentNumber,
    required this.totalInstallments,
    this.isPaid = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  /// Create from JSON with safe date parsing
  ///
  /// **Updated:** Uses DateUtils for consistent Firebase date handling
  factory UpcomingInstallment.fromJson(Map<String, dynamic> json) {
    return UpcomingInstallment(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateUtils.fromFirebase(json['due_date']),
      startDate: json['start_date'] != null 
          ? DateUtils.fromFirebase(json['start_date'])
          : null,
      installmentNumber: json['installment_number'] as int,
      totalInstallments: json['total_installments'] as int,
      isPaid: json['is_paid'] as bool? ?? false,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
    );
  }

  /// Convert to JSON with consistent date formatting
  ///
  /// **Updated:** Uses DateUtils for consistent Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'due_date': DateUtils.toIso8601(dueDate),
      'start_date': startDate != null ? DateUtils.toIso8601(startDate!) : null,
      'installment_number': installmentNumber,
      'total_installments': totalInstallments,
      'is_paid': isPaid,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
    };
  }

  /// Get installment display text
  String get displayText {
    return '$installmentNumber/$totalInstallments Taksit';
  }

  /// Get localized installment display text
  String getLocalizedDisplayText(dynamic l10n) {
    return '$installmentNumber/$totalInstallments ${l10n.installment}';
  }

  /// Check if this installment is overdue
  ///
  /// **Updated:** Uses DateUtils for consistent date comparison
  bool get isOverdue {
    return !isPaid && DateUtils.isOverdue(dueDate);
  }

  /// Check if this installment is due soon
  ///
  /// **New:** Consistent with other date utilities
  bool get isDueSoon {
    return !isPaid && DateUtils.isDueSoon(dueDate);
  }

  /// Get days until due date
  ///
  /// **New:** Consistent date calculation
  int get daysUntilDue {
    return DateUtils.getDaysUntilDue(dueDate);
  }

  /// Get display title (use category name if available, otherwise description)
  String get displayTitle => categoryName ?? description;

  /// Get display subtitle
  String get displaySubtitle => '$installmentNumber/$totalInstallments Taksit';

  /// Get localized display subtitle
  String getLocalizedDisplaySubtitle(dynamic l10n) =>
      '$installmentNumber/$totalInstallments ${l10n.installment}';

  @override
  String toString() {
    return 'UpcomingInstallment(id: $id, description: $description, amount: $amount, dueDate: $dueDate)';
  }
}
