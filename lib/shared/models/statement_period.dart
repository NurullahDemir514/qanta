import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as QantaDateUtils;

/// Statement period model for credit card statements
///
/// **Updated with centralized date handling:**
/// - Uses QantaDateUtils.DateUtils for consistent Firebase date parsing
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
  /// **Updated:** Uses QantaDateUtils.DateUtils.fromFirebase for consistent date handling
  /// across all Firebase data sources.
  factory StatementPeriod.fromJson(Map<String, dynamic> json) {
    return StatementPeriod(
      startDate: QantaDateUtils.DateUtils.fromFirebase(json['start_date']),
      endDate: QantaDateUtils.DateUtils.fromFirebase(json['end_date']),
      dueDate: QantaDateUtils.DateUtils.fromFirebase(json['due_date']),
      statementDay: json['statement_day'] as int,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? QantaDateUtils.DateUtils.fromFirebase(json['paid_at'])
          : null,
    );
  }

  /// Convert to JSON with consistent date formatting
  ///
  /// **Updated:** Uses QantaDateUtils.DateUtils.toIso8601 for consistent Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'start_date': QantaDateUtils.DateUtils.toIso8601(startDate),
      'end_date': QantaDateUtils.DateUtils.toIso8601(endDate),
      'due_date': QantaDateUtils.DateUtils.toIso8601(dueDate),
      'statement_day': statementDay,
      'is_paid': isPaid,
      'paid_at': paidAt != null
          ? QantaDateUtils.DateUtils.toIso8601(paidAt!)
          : null,
    };
  }

  /// Check if this period is overdue
  ///
  /// **Updated:** Uses QantaDateUtils.DateUtils for consistent date comparison
  bool get isOverdue {
    return !isPaid && QantaDateUtils.DateUtils.isOverdue(dueDate);
  }

  /// Get days until due date
  ///
  /// **Updated:** Uses QantaDateUtils.DateUtils for consistent calculation
  int get daysUntilDue {
    return QantaDateUtils.DateUtils.getDaysUntilDue(dueDate);
  }

  /// Get days overdue
  ///
  /// **Updated:** Uses centralized date calculation
  int get daysOverdue {
    if (!isOverdue) return 0;
    return -QantaDateUtils.DateUtils.getDaysUntilDue(dueDate);
  }

  /// Check if this period is due soon (within warning period)
  ///
  /// **New:** Consistent with other date utilities
  bool get isDueSoon {
    return QantaDateUtils.DateUtils.isDueSoon(dueDate);
  }

  /// Get statement date (same as endDate)
  DateTime get statementDate => endDate;

  /// Get period text for display
  ///
  /// **Updated:** Uses QantaDateUtils.DateUtils for consistent formatting
  String get periodText {
    return QantaDateUtils.DateUtils.formatPeriodText(startDate);
  }

  /// Get period text for display with context
  ///
  /// **New:** Localized period text
  String getPeriodText(BuildContext context) {
    return QantaDateUtils.DateUtils.formatPeriodText(
      startDate,
      context: context,
    );
  }

  /// Get due date text for display
  ///
  /// **Updated:** Uses QantaDateUtils.DateUtils for consistent formatting
  String get dueDateText {
    return QantaDateUtils.DateUtils.formatDueDateText(dueDate);
  }

  /// Get due date text for display with context
  ///
  /// **New:** Localized due date text
  String getDueDateText(BuildContext context) {
    return QantaDateUtils.DateUtils.formatDueDateText(
      dueDate,
      context: context,
    );
  }

  /// Get end date (cut date) text for display
  ///
  /// **New:** For statement cut date display
  String get endDateText {
    return QantaDateUtils.DateUtils.formatDueDateText(endDate);
  }

  /// Get end date (cut date) text for display with context
  ///
  /// **New:** Localized cut date text
  String getEndDateText(BuildContext context) {
    return QantaDateUtils.DateUtils.formatDueDateText(
      endDate,
      context: context,
    );
  }

  /// Get formatted period range text
  ///
  /// **New:** For detailed period display
  String get periodRangeText {
    final start = QantaDateUtils.DateUtils.formatShortDate(startDate);
    final end = QantaDateUtils.DateUtils.formatShortDate(endDate);
    return '$start - $end';
  }

  /// Get payment status text
  ///
  /// **New:** Consistent status display across the app
  String get paymentStatusText {
    if (isPaid) return 'Ödendi';
    if (isOverdue) return 'Gecikmiş ($daysOverdue gün)';
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
