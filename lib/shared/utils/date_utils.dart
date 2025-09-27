import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// **Centralized Date Management System**
/// 
/// This utility provides consistent date handling across the entire app:
/// - Firebase Timestamp ↔ DateTime conversion
/// - ISO8601 string ↔ DateTime conversion
/// - Consistent date formatting
/// - Timezone handling
/// - Statement period calculations
/// 
/// **Key Features:**
/// - Safe conversion methods with fallbacks
/// - Consistent Firebase date storage format
/// - Statement-specific date calculations
/// - Performance-optimized formatters
/// - Null-safe operations
class DateUtils {
  // ===============================
  // FORMATTERS (CACHED FOR PERFORMANCE)
  // ===============================
  
  static final DateFormat _periodFormat = DateFormat('MMM yyyy', 'tr_TR');
  static final DateFormat _dueDateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
  static final DateFormat _shortDateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fullDateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  
  // ===============================
  // FIREBASE ↔ DATETIME CONVERSION
  // ===============================
  
  /// **Safe Firebase Timestamp to DateTime conversion**
  /// 
  /// Handles all possible Firebase date formats:
  /// - Firestore Timestamp objects
  /// - ISO8601 strings
  /// - DateTime objects (passthrough)
  /// - Null values (returns fallback)
  /// 
  /// **Usage:**
  /// ```dart
  /// DateTime date = DateUtils.fromFirebase(firestoreData['created_at']);
  /// ```
  static DateTime fromFirebase(dynamic value, {DateTime? fallback}) {
    fallback ??= DateTime.now();
    
    if (value == null) return fallback;
    
    // Already a DateTime object
    if (value is DateTime) return value;
    
    // Firestore Timestamp
    if (value is Timestamp) {
      try {
        return value.toDate();
      } catch (e) {
        return fallback;
      }
    }
    
    // ISO8601 String
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Try alternative formats
        try {
          return _isoFormat.parse(value);
        } catch (e2) {
          return fallback;
        }
      }
    }
    
    // Fallback for unknown types
    return fallback;
  }
  
  /// **DateTime to Firebase-compatible format**
  /// 
  /// Converts DateTime to Firestore Timestamp for consistent storage.
  /// Use this when saving dates to Firebase.
  /// 
  /// **Usage:**
  /// ```dart
  /// Map<String, dynamic> data = {
  ///   'created_at': DateUtils.toFirebase(DateTime.now()),
  /// };
  /// ```
  static Timestamp toFirebase(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
  
  /// **DateTime to ISO8601 string for JSON serialization**
  /// 
  /// Use this for API calls or when you need string representation.
  /// 
  /// **Usage:**
  /// ```dart
  /// Map<String, dynamic> json = {
  ///   'created_at': DateUtils.toIso8601(DateTime.now()),
  /// };
  /// ```
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
  
  // ===============================
  // STATEMENT PERIOD CALCULATIONS
  // ===============================
  
  /// **Calculate statement period start date**
  /// 
  /// Given a card's statement day (e.g., 15), calculates the start
  /// of the current statement period.
  /// 
  /// **Logic:**
  /// - If today is before statement day: period starts last month
  /// - If today is on/after statement day: period starts this month
  /// 
  /// **Example:**
  /// ```dart
  /// // Today: 2024-03-20, Statement day: 15
  /// // Returns: 2024-03-15 (this month)
  /// 
  /// // Today: 2024-03-10, Statement day: 15  
  /// // Returns: 2024-02-15 (last month)
  /// ```
  static DateTime getStatementPeriodStart(int statementDay, {DateTime? referenceDate}) {
    referenceDate ??= DateTime.now();
    
    // If today is before statement day: period starts last month
    // If today is on/after statement day: period starts this month
    if (referenceDate.day < statementDay) {
      // Previous month
      final prevMonth = referenceDate.month == 1 ? 12 : referenceDate.month - 1;
      final prevYear = referenceDate.month == 1 ? referenceDate.year - 1 : referenceDate.year;
      return DateTime(prevYear, prevMonth, statementDay);
    }
    // Current month
    return DateTime(referenceDate.year, referenceDate.month, statementDay);
  }
  
  /// **Calculate statement period end date**
  /// 
  /// Statement period ends one day before the next statement day.
  /// 
  /// **Example:**
  /// ```dart
  /// // Statement day: 15
  /// // Period start: 2024-03-15
  /// // Period end: 2024-04-14 (day before next statement)
  /// ```
  static DateTime getStatementPeriodEnd(int statementDay, {DateTime? referenceDate}) {
    final periodStart = getStatementPeriodStart(statementDay, referenceDate: referenceDate);
    final nextPeriodStart = DateTime(periodStart.year, periodStart.month + 1, statementDay);
    
    // End is one day before next period starts
    return nextPeriodStart.subtract(const Duration(days: 1));
  }
  
  /// **Calculate statement due date**
  /// 
  /// Due date is typically 20-25 days after the statement period ends.
  /// 
  /// **Example:**
  /// ```dart
  /// // Period end: 2024-04-14
  /// // Due date: 2024-05-09 (25 days later)
  /// ```
  static DateTime getStatementDueDate(int statementDay, {DateTime? referenceDate, int? dueDay}) {
    final periodEnd = getStatementPeriodEnd(statementDay, referenceDate: referenceDate);
    
    // If dueDay is provided, use it; otherwise use default 25 days
    if (dueDay != null) {
      // Calculate due date based on due day of the month
      final dueDate = DateTime(periodEnd.year, periodEnd.month, dueDay);
      
      // If due day is before period end, it's next month
      if (dueDate.isBefore(periodEnd)) {
        if (periodEnd.month == 12) {
          return DateTime(periodEnd.year + 1, 1, dueDay);
        } else {
          return DateTime(periodEnd.year, periodEnd.month + 1, dueDay);
        }
      }
      
      return dueDate;
    }
    
    // Fallback to 25 days after period end
    return periodEnd.add(const Duration(days: 25));
  }
  
  /// **Get statement period for a specific date**
  /// 
  /// Returns the statement period that contains the given date.
  /// Useful for categorizing transactions into statement periods.
  static DateTime getStatementPeriodForDate(DateTime transactionDate, int statementDay) {
    // If transaction is after statement day, it belongs to current period
    if (transactionDate.day >= statementDay) {
      return DateTime(transactionDate.year, transactionDate.month, statementDay);
    }
    
    // If transaction is before statement day, it belongs to previous period
    return DateTime(transactionDate.year, transactionDate.month - 1, statementDay);
  }
  
  /// **Calculate days until due date**
  /// 
  /// Returns positive number for future dates, negative for overdue.
  static int getDaysUntilDue(DateTime dueDate, {DateTime? referenceDate}) {
    referenceDate ??= DateTime.now();
    
    // Compare only dates, ignore time
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    return due.difference(today).inDays;
  }
  
  /// **Check if date is overdue**
  static bool isOverdue(DateTime dueDate, {DateTime? referenceDate}) {
    return getDaysUntilDue(dueDate, referenceDate: referenceDate) < 0;
  }
  
  /// **Check if date is due soon (within 7 days)**
  static bool isDueSoon(DateTime dueDate, {DateTime? referenceDate, int warningDays = 7}) {
    final daysUntilDue = getDaysUntilDue(dueDate, referenceDate: referenceDate);
    return daysUntilDue >= 0 && daysUntilDue <= warningDays;
  }
  
  // ===============================
  // DISPLAY FORMATTING
  // ===============================
  
  /// **Format period text for UI display**
  /// 
  /// **Examples:**
  /// - "Mar 2024"
  /// - "Eki 2023"
  static String formatPeriodText(DateTime periodStart) {
    return _periodFormat.format(periodStart);
  }
  
  /// **Format due date text for UI display**
  /// 
  /// **Examples:**
  /// - "15 Mar 2024"
  /// - "28 Eki 2023"
  static String formatDueDateText(DateTime dueDate) {
    try {
      return _dueDateFormat.format(dueDate);
    } catch (e) {
      // Fallback to simple format if localization fails
      return '${dueDate.day}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}';
    }
  }
  
  /// **Format short date for UI display**
  /// 
  /// **Examples:**
  /// - "15.03.2024"
  /// - "28.10.2023"
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
  
  /// **Format time for UI display**
  /// 
  /// **Examples:**
  /// - "14:30"
  /// - "09:15"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
  
  /// **Format full date and time for UI display**
  /// 
  /// **Examples:**
  /// - "15.03.2024 14:30"
  /// - "28.10.2023 09:15"
  static String formatFullDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }
  
  /// **Format month and year for UI display**
  /// 
  /// **Examples:**
  /// - "Mart 2024"
  /// - "Ekim 2023"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }
  
  /// **Format relative time (e.g., "2 days ago")**
  /// 
  /// Returns user-friendly relative time strings in Turkish.
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return '1 gün önce';
      if (difference.inDays < 7) return '${difference.inDays} gün önce';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} hafta önce';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} ay önce';
      return '${(difference.inDays / 365).floor()} yıl önce';
    }
    
    if (difference.inHours > 0) {
      if (difference.inHours == 1) return '1 hour ago';
      return '${difference.inHours} hours ago';
    }
    
    if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) return '1 minute ago';
      return '${difference.inMinutes} minutes ago';
    }
    
    return 'Now';
  }
  
  // ===============================
  // UTILITY METHODS
  // ===============================
  
  /// **Check if two dates are on the same day**
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  /// **Check if date is today**
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
  
  /// **Check if date is yesterday**
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
  
  /// **Check if date is in current month**
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  /// **Get start of day (00:00:00)**
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// **Get end of day (23:59:59.999)**
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// **Get start of month**
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// **Get end of month**
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
  
  /// **Add months to date (handles edge cases)**
  static DateTime addMonths(DateTime date, int months) {
    final newYear = date.year + (date.month + months - 1) ~/ 12;
    final newMonth = (date.month + months - 1) % 12 + 1;
    
    // Handle end-of-month edge cases (e.g., Jan 31 + 1 month = Feb 28/29)
    final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > daysInNewMonth ? daysInNewMonth : date.day;
    
    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second, date.millisecond);
  }
  
  /// **Subtract months from date (handles edge cases)**
  static DateTime subtractMonths(DateTime date, int months) {
    return addMonths(date, -months);
  }
  
  /// **Generate date range between two dates**
  static List<DateTime> generateDateRange(DateTime start, DateTime end, {Duration step = const Duration(days: 1)}) {
    final dates = <DateTime>[];
    DateTime current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(step);
    }
    
    return dates;
  }
  
  /// **Get business days between two dates (excludes weekends)**
  static int getBusinessDaysBetween(DateTime start, DateTime end) {
    int businessDays = 0;
    DateTime current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Monday = 1, Sunday = 7
      if (current.weekday < 6) {
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return businessDays;
  }
  
  /// **Validate if string is a valid date format**
  static bool isValidDateString(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// **Parse flexible date input (handles multiple formats)**
  static DateTime? parseFlexibleDate(String input) {
    if (input.isEmpty) return null;
    
    // Common formats to try
    final formats = [
      'yyyy-MM-dd',
      'dd.MM.yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd.MM.yyyy HH:mm',
    ];
    
    for (final format in formats) {
      try {
        final formatter = DateFormat(format);
        return formatter.parse(input);
      } catch (e) {
        continue;
      }
    }
    
    // Try default DateTime.parse as last resort
    try {
      return DateTime.parse(input);
    } catch (e) {
      return null;
    }
  }
}
