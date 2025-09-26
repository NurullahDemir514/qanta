import '../utils/date_utils.dart';

/// Statement period model for credit card statements
/// 
/// **Updated with centralized date handling:**
/// - Uses DateUtils for consistent Firebase date parsing
/// - Standardized date formatting across the app
/// - Improved null safety and error handling
class StatementPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final int statementDay;
  final bool isPaid;
  final DateTime? paidAt;

  StatementPeriod({
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.statementDay,
    this.isPaid = false,
    this.paidAt,
  });

  /// Create from JSON with safe date parsing
  /// 
  /// **Updated:** Uses DateUtils.fromFirebase for consistent date handling
  /// across all Firebase data sources.
  factory StatementPeriod.fromJson(Map<String, dynamic> json) {
    return StatementPeriod(
      startDate: DateUtils.fromFirebase(json['start_date']),
      endDate: DateUtils.fromFirebase(json['end_date']),
      dueDate: DateUtils.fromFirebase(json['due_date']),
      statementDay: json['statement_day'] as int,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null ? DateUtils.fromFirebase(json['paid_at']) : null,
    );
  }

  /// Convert to JSON with consistent date formatting
  /// 
  /// **Updated:** Uses DateUtils.toIso8601 for consistent Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'start_date': DateUtils.toIso8601(startDate),
      'end_date': DateUtils.toIso8601(endDate),
      'due_date': DateUtils.toIso8601(dueDate),
      'statement_day': statementDay,
      'is_paid': isPaid,
      'paid_at': paidAt != null ? DateUtils.toIso8601(paidAt!) : null,
    };
  }

  /// Check if this period is overdue
  /// 
  /// **Updated:** Uses DateUtils for consistent date comparison
  bool get isOverdue {
    return !isPaid && DateUtils.isOverdue(dueDate);
  }

  /// Get days until due date
  /// 
  /// **Updated:** Uses DateUtils for consistent calculation
  int get daysUntilDue {
    return DateUtils.getDaysUntilDue(dueDate);
  }

  /// Get days overdue
  /// 
  /// **Updated:** Uses centralized date calculation
  int get daysOverdue {
    if (!isOverdue) return 0;
    return -DateUtils.getDaysUntilDue(dueDate);
  }

  /// Check if this period is due soon (within warning period)
  /// 
  /// **New:** Consistent with other date utilities
  bool get isDueSoon {
    return DateUtils.isDueSoon(dueDate);
  }

  /// Get statement date (same as endDate)
  DateTime get statementDate => endDate;

  /// Get period text for display
  /// 
  /// **Updated:** Uses DateUtils for consistent formatting
  String get periodText {
    return DateUtils.formatPeriodText(startDate);
  }

  /// Get due date text for display
  /// 
  /// **Updated:** Uses DateUtils for consistent formatting
  String get dueDateText {
    return DateUtils.formatDueDateText(dueDate);
  }

  /// Get formatted period range text
  /// 
  /// **New:** For detailed period display
  String get periodRangeText {
    final start = DateUtils.formatShortDate(startDate);
    final end = DateUtils.formatShortDate(endDate);
    return '$start - $end';
  }

  /// Get payment status text
  /// 
  /// **New:** Consistent status display across the app
  String get paymentStatusText {
    if (isPaid) return 'Ödendi';
    if (isOverdue) return 'Gecikmiş (${daysOverdue} gün)';
    if (isDueSoon) return '$daysUntilDue gün kaldı';
    return '$daysUntilDue gün kaldı';
  }

  /// Copy with method for creating modified instances
  StatementPeriod copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    int? statementDay,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return StatementPeriod(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDate: dueDate ?? this.dueDate,
      statementDay: statementDay ?? this.statementDay,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  String toString() {
    return 'StatementPeriod(startDate: $startDate, endDate: $endDate, dueDate: $dueDate)';
  }
}
