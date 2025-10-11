import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/statement_period.dart';
import '../../shared/models/statement_summary.dart';
import '../../shared/utils/date_utils.dart';

/// **Credit Card Statement Service**
///
/// Comprehensive service for managing credit card statements with Firebase integration.
///
/// **Key Features:**
/// - Period calculation using centralized DateUtils
/// - Firebase-backed statement summaries
/// - Optimistic updates for statement payments
/// - Real-time statement data synchronization
/// - Proper limit calculation for credit cards
///
/// **Updated:** Uses DateUtils for consistent date handling and calculation
class StatementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // PERIOD CALCULATIONS
  // ===============================

  /// **Get current statement period using centralized date calculations**
  ///
  /// **Updated:** Uses DateUtils for consistent and accurate period calculation
  static StatementPeriod getCurrentStatementPeriod(
    int statementDay, {
    int? dueDay,
  }) {
    final now = DateTime.now();

    // Use centralized date calculation
    final startDate = DateUtils.getStatementPeriodStart(
      statementDay,
      referenceDate: now,
    );
    final endDate = DateUtils.getStatementPeriodEnd(
      statementDay,
      referenceDate: now,
    );
    final dueDate = DateUtils.getStatementDueDate(
      statementDay,
      referenceDate: now,
      dueDay: dueDay,
    );

    return StatementPeriod(
      startDate: startDate,
      endDate: endDate,
      dueDate: dueDate,
      statementDay: statementDay,
    );
  }

  /// **Get statement period for a specific date**
  ///
  /// **Updated:** Uses DateUtils for consistent period calculation
  static StatementPeriod getStatementPeriodForDate(
    DateTime date,
    int statementDay,
  ) {
    final periodStart = DateUtils.getStatementPeriodForDate(date, statementDay);
    final startDate = DateUtils.getStatementPeriodStart(
      statementDay,
      referenceDate: date,
    );
    final endDate = DateUtils.getStatementPeriodEnd(
      statementDay,
      referenceDate: date,
    );
    final dueDate = DateUtils.getStatementDueDate(
      statementDay,
      referenceDate: date,
    );

    return StatementPeriod(
      startDate: startDate,
      endDate: endDate,
      dueDate: dueDate,
      statementDay: statementDay,
    );
  }

  /// **Get next statement period**
  ///
  /// **Updated:** Uses DateUtils for consistent calculation
  static StatementPeriod getNextStatementPeriod(int statementDay) {
    final currentPeriod = getCurrentStatementPeriod(statementDay);
    final nextMonthDate = DateUtils.addMonths(currentPeriod.startDate, 1);

    return getStatementPeriodForDate(nextMonthDate, statementDay);
  }

  /// **Generate future periods until last installment**
  ///
  /// Generates all future statement periods until the last installment
  /// payment is due for the given card.
  static Future<List<StatementPeriod>> getFuturePeriodsUntilLastInstallment(
    String cardId,
    int statementDay,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Get all active installments for this card
      final installmentsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('installment_transactions')
          .where('account_id', isEqualTo: cardId)
          .where('is_active', isEqualTo: true)
          .get();

      if (installmentsQuery.docs.isEmpty) {
        // No installments, return next 12 months
        return _generateFuturePeriods(statementDay, 12);
      }

      // Find the latest installment end date
      DateTime latestInstallmentDate = DateTime.now();

      for (final doc in installmentsQuery.docs) {
        final data = doc.data();
        final startDate = DateUtils.fromFirebase(data['start_date']);
        final installmentCount = data['installment_count'] as int? ?? 1;

        // Calculate when this installment series ends
        final endDate = DateUtils.addMonths(startDate, installmentCount);

        if (endDate.isAfter(latestInstallmentDate)) {
          latestInstallmentDate = endDate;
        }
      }

      // Generate periods until 3 months after the latest installment
      final currentPeriod = getCurrentStatementPeriod(statementDay);
      final monthsToGenerate =
          latestInstallmentDate.difference(currentPeriod.startDate).inDays ~/
              30 +
          3;

      return _generateFuturePeriods(
        statementDay,
        monthsToGenerate.clamp(1, 24),
      );
    } catch (e) {
      if (kDebugMode) {}
      // Fallback: return next 6 months
      return _generateFuturePeriods(statementDay, 6);
    }
  }

  /// **Generate multiple future periods**
  static List<StatementPeriod> _generateFuturePeriods(
    int statementDay,
    int monthCount,
  ) {
    final periods = <StatementPeriod>[];
    final currentPeriod = getCurrentStatementPeriod(statementDay);

    for (int i = 1; i <= monthCount; i++) {
      final periodDate = DateUtils.addMonths(currentPeriod.startDate, i);
      final period = getStatementPeriodForDate(periodDate, statementDay);
      periods.add(period);
    }

    return periods;
  }

  /// **Get all past statement periods**
  ///
  /// Returns past statement periods based on payment history
  static Future<List<StatementPeriod>> getAllPastStatementPeriods(
    String cardId,
    int statementDay, {
    int maxMonths = 24,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Get paid statements from Firebase
      final paymentsQuery = await _firestore
          .collection('statement_payments')
          .where('user_id', isEqualTo: userId)
          .where('card_id', isEqualTo: cardId)
          .where('is_paid', isEqualTo: true)
          .orderBy('period_end', descending: true)
          .limit(maxMonths)
          .get();

      final periods = <StatementPeriod>[];

      for (final doc in paymentsQuery.docs) {
        final data = doc.data();
        final period = StatementPeriod(
          startDate: DateUtils.fromFirebase(data['period_start']),
          endDate: DateUtils.fromFirebase(data['period_end']),
          dueDate: DateUtils.fromFirebase(data['due_date']),
          statementDay: statementDay,
          isPaid: true,
          paidAt: DateUtils.fromFirebase(data['paid_at']),
        );
        periods.add(period);
      }

      return periods;
    } catch (e) {
      if (kDebugMode) {}
      return [];
    }
  }

  // ===============================
  // STATEMENT CALCULATIONS
  // ===============================

  /// **Calculate statement summary for a period**
  ///
  /// **Updated:** Improved credit limit calculation logic
  static Future<StatementSummary> calculateStatementSummary(
    String cardId,
    StatementPeriod period, {
    bool useCache = true,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        // Check if this is current period
        final isCurrent = _isCurrentPeriod(period);
      }

      // Get transactions for this period
      // Note: transaction_date is stored as ISO8601 string, not Timestamp
      final startDateStr = DateUtils.toIso8601(period.startDate);
      final endDateStr = DateUtils.toIso8601(period.endDate);

      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('source_account_id', isEqualTo: cardId)
          .where('transaction_date', isGreaterThanOrEqualTo: startDateStr)
          .where('transaction_date', isLessThanOrEqualTo: endDateStr)
          .get();

      if (kDebugMode && transactionsQuery.docs.isNotEmpty) {}

      final transactions = <Map<String, dynamic>>[];
      double totalAmount = 0.0;
      int transactionCount = 0;

      for (final doc in transactionsQuery.docs) {
        final data = doc.data();
        final transactionType = data['type'] as String;
        final amount = (data['amount'] as num).toDouble();
        final isInstallment = data['is_installment'] as bool? ?? false;
        final description = data['description'] as String? ?? '';

        // Check if it's an installment transaction by description
        final isInstallmentByDescription =
            description.contains('taksit') || description.contains('Taksit');
        final transactionDate = data['transaction_date'];

        if (kDebugMode) {
          if (isInstallment) {}
        }

        // **CORRECTED STATEMENT CALCULATION LOGIC**
        // For installment transactions, we don't add the full amount here
        // because installment details will be added separately
        final isActuallyInstallment =
            isInstallment || isInstallmentByDescription;

        if (!isActuallyInstallment) {
          if (transactionType == 'expense') {
            totalAmount += amount.abs(); // Regular expenses increase debt
            transactionCount++;
          } else if (transactionType == 'income') {
            totalAmount -= amount.abs(); // Income/refunds reduce debt
            transactionCount++;
          }
        } else {
          // For installment transactions, just count them but don't add amount
          // The amount will be calculated from installment details
          transactionCount++;
        }
        // Note: Transfers don't affect credit card debt for statement purposes

        transactions.add({...data, 'id': doc.id});
      }

      if (kDebugMode && totalAmount > 0) {}

      // **NEW LOGIC: Get first installments for current period only**
      // For current period, we only want first installments of transactions created in this period
      final isCurrentPeriod = _isCurrentPeriod(period);
      final upcomingInstallments = <UpcomingInstallment>[];

      if (isCurrentPeriod) {
        // Get first installments of transactions created in this period
        final firstInstallments = await _getFirstInstallmentsForCurrentPeriod(
          cardId,
          period,
        );
        upcomingInstallments.addAll(firstInstallments);

        if (kDebugMode && firstInstallments.isNotEmpty) {}

        // First installments are already calculated in _getFirstInstallmentsForCurrentPeriod
        // No need to add amounts again here
      } else {
        // For future/past periods, use regular installment logic
        final regularInstallments = await _getUpcomingInstallmentsForPeriod(
          cardId,
          period,
        );
        upcomingInstallments.addAll(regularInstallments);

        if (kDebugMode && regularInstallments.isNotEmpty) {}

        // Add installment amounts to total
        for (final installment in regularInstallments) {
          totalAmount += installment.amount;
        }
      }

      // Statements are now for information only - no payment tracking
      final statementIsPaid = false;
      final paidAt = null;

      return StatementSummary(
        id: '${cardId}_${period.startDate.millisecondsSinceEpoch}',
        cardId: cardId,
        period: period.copyWith(isPaid: statementIsPaid, paidAt: paidAt),
        totalAmount: totalAmount,
        paidAmount: statementIsPaid ? totalAmount : 0.0,
        remainingAmount: statementIsPaid ? 0.0 : totalAmount,
        transactionCount: transactionCount,
        upcomingInstallments: upcomingInstallments,
        isPaid: statementIsPaid,
        paidAt: paidAt,
      );
    } catch (e) {
      if (kDebugMode) {}
      rethrow;
    }
  }

  /// **Get upcoming installments for a specific period**
  static Future<List<UpcomingInstallment>> _getUpcomingInstallmentsForPeriod(
    String cardId,
    StatementPeriod period,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Get all active installments for this card
      // Note: due_date is stored as ISO8601 string, not Timestamp
      final startDateStr = DateUtils.toIso8601(period.startDate);
      final endDateStr = DateUtils.toIso8601(period.endDate);

      final installmentsQuery = await _firestore
          .collection('installment_details')
          .where('user_id', isEqualTo: userId)
          .where('account_id', isEqualTo: cardId)
          .where('due_date', isGreaterThanOrEqualTo: startDateStr)
          .where('due_date', isLessThanOrEqualTo: endDateStr)
          .where('is_paid', isEqualTo: false)
          .get();

      if (kDebugMode && installmentsQuery.docs.isNotEmpty) {}

      final installments = <UpcomingInstallment>[];

      for (final doc in installmentsQuery.docs) {
        final data = doc.data();

        if (kDebugMode) {}

        final installment = UpcomingInstallment(
          id: doc.id,
          description: data['description'] as String,
          amount: (data['amount'] as num).toDouble(),
          dueDate: DateUtils.fromFirebase(data['due_date']),
          installmentNumber: data['installment_number'] as int,
          totalInstallments: data['total_installments'] as int,
          isPaid: data['is_paid'] as bool? ?? false,
          categoryName: _getCategoryNameFromId(data['category_id'] as String?),
          categoryIcon: _getCategoryIconFromId(data['category_id'] as String?),
          categoryColor: _getCategoryColorFromId(
            data['category_id'] as String?,
          ),
        );

        installments.add(installment);
      }

      if (kDebugMode && installments.isNotEmpty) {}

      return installments;
    } catch (e) {
      if (kDebugMode) {}
      return [];
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  /// Helper methods for category information
  static String? _getCategoryNameFromId(String? categoryId) {
    if (categoryId == null) return null;

    // For now, return a default category name
    // TODO: Implement proper category lookup from categoryId
    // Note: StatementService doesn't have access to UnifiedProviderV2
    // This should be handled by StatementProvider instead
    return 'Diğer';
  }

  static String? _getCategoryIconFromId(String? categoryId) {
    if (categoryId == null) return null;

    // For now, return a default category icon
    // TODO: Implement proper category lookup from categoryId
    return 'more_horiz_rounded';
  }

  static String? _getCategoryColorFromId(String? categoryId) {
    if (categoryId == null) return null;

    // For now, return a default category color
    // TODO: Implement proper category lookup from categoryId
    return '#6B7280';
  }

  /// **Check if period is current period**
  static bool _isCurrentPeriod(StatementPeriod period) {
    final now = DateTime.now();
    final currentPeriod = getCurrentStatementPeriod(
      1,
    ); // Use statement day 1 as reference

    if (kDebugMode) {}

    return period.startDate.year == currentPeriod.startDate.year &&
        period.startDate.month == currentPeriod.startDate.month;
  }

  /// **Get first installments for current period only**
  ///
  /// This method:
  /// 1. Finds installment_masters created in current period
  /// 2. Gets their first installment details
  static Future<List<UpcomingInstallment>>
  _getFirstInstallmentsForCurrentPeriod(
    String cardId,
    StatementPeriod period,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Step 1: Find installment masters created in current period
      final startDateStr = DateUtils.toIso8601(period.startDate);
      final endDateStr = DateUtils.toIso8601(period.endDate);

      // Simple query without complex filters to avoid index issues
      final mastersQuery = await _firestore
          .collection('installment_masters')
          .where('user_id', isEqualTo: userId)
          .where('source_account_id', isEqualTo: cardId)
          .get();

      if (mastersQuery.docs.isEmpty) {
        return [];
      }

      // Step 2: Filter by date and get first installment details
      final installments = <UpcomingInstallment>[];

      for (final masterDoc in mastersQuery.docs) {
        final masterData = masterDoc.data();
        final masterId = masterDoc.id;
        final createdAt = DateUtils.fromFirebase(masterData['created_at']);

        // Check if created in current period
        if (createdAt.isBefore(period.startDate) ||
            createdAt.isAfter(period.endDate)) {
          continue;
        }

        // Get first installment detail for this master
        final detailQuery = await _firestore
            .collection('installment_details')
            .where('user_id', isEqualTo: userId)
            .where('installment_id', isEqualTo: masterId)
            .where('installment_number', isEqualTo: 1)
            .where('is_paid', isEqualTo: false)
            .limit(1)
            .get();

        if (detailQuery.docs.isNotEmpty) {
          final detailData = detailQuery.docs.first.data();

          final installment = UpcomingInstallment(
            id: detailQuery.docs.first.id,
            description: detailData['description'] as String,
            amount: (detailData['amount'] as num).toDouble(),
            dueDate: DateUtils.fromFirebase(detailData['due_date']),
            installmentNumber: detailData['installment_number'] as int,
            totalInstallments: detailData['total_installments'] as int,
            isPaid: detailData['is_paid'] as bool? ?? false,
            categoryName: _getCategoryNameFromId(
              detailData['category_id'] as String?,
            ),
            categoryIcon: _getCategoryIconFromId(
              detailData['category_id'] as String?,
            ),
            categoryColor: _getCategoryColorFromId(
              detailData['category_id'] as String?,
            ),
          );

          installments.add(installment);
        }
      }

      return installments;
    } catch (e) {
      if (kDebugMode) {}
      return [];
    }
  }


  // ===============================
  // HELPER METHODS
  // ===============================

  /// **Get statement period ID for consistent referencing**
  static String getStatementPeriodId(String cardId, StatementPeriod period) {
    return '${cardId}_${period.startDate.millisecondsSinceEpoch}';
  }

  /// **Validate statement period**
  static bool isValidStatementPeriod(StatementPeriod period) {
    return period.startDate.isBefore(period.endDate) &&
        period.endDate.isBefore(period.dueDate) &&
        period.statementDay >= 1 &&
        period.statementDay <= 31;
  }

  /// **Get statement period from transaction date**
  static StatementPeriod getStatementPeriodFromTransactionDate(
    DateTime transactionDate,
    int statementDay,
  ) {
    return getStatementPeriodForDate(transactionDate, statementDay);
  }

  /// **Calculate days in statement period**
  static int getDaysInStatementPeriod(StatementPeriod period) {
    return period.endDate.difference(period.startDate).inDays + 1;
  }

  /// **Check if date is in statement period**
  static bool isDateInStatementPeriod(DateTime date, StatementPeriod period) {
    final dateOnly = DateUtils.startOfDay(date);
    final startOnly = DateUtils.startOfDay(period.startDate);
    final endOnly = DateUtils.startOfDay(period.endDate);

    return (dateOnly.isAtSameMomentAs(startOnly) ||
            dateOnly.isAfter(startOnly)) &&
        (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
  }

  /// **Get statement summary cache key**
  static String _getStatementSummaryCacheKey(
    String cardId,
    StatementPeriod period,
  ) {
    return 'statement_summary_${cardId}_${period.startDate.millisecondsSinceEpoch}';
  }

  /// **Mark statement as paid**
  ///
  /// Records the payment status of a statement period in Firebase
  static Future<bool> markStatementAsPaid(
    String cardId,
    StatementPeriod period,
    double paidAmount,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Create payment record
      final paymentData = {
        'user_id': userId,
        'card_id': cardId,
        'period_start': DateUtils.toFirebase(period.startDate),
        'period_end': DateUtils.toFirebase(period.endDate),
        'due_date': DateUtils.toFirebase(period.dueDate),
        'paid_amount': paidAmount,
        'is_paid': true,
        'paid_at': DateUtils.toFirebase(DateTime.now()),
        'created_at': DateUtils.toFirebase(DateTime.now()),
        'updated_at': DateUtils.toFirebase(DateTime.now()),
      };

      // Save to Firebase
      await _firestore
          .collection('statement_payments')
          .add(paymentData);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking statement as paid: $e');
      }
      return false;
    }
  }

  /// **Get payment history for a card**
  ///
  /// Returns all payment records for a specific card
  static Future<List<Map<String, dynamic>>> getPaymentHistory(
    String cardId,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final paymentsQuery = await _firestore
          .collection('statement_payments')
          .where('user_id', isEqualTo: userId)
          .where('card_id', isEqualTo: cardId)
          .orderBy('period_end', descending: true)
          .get();

      return paymentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting payment history: $e');
      }
      return [];
    }
  }

  /// **Clear statement cache (for testing/debugging)**
  static Future<void> clearStatementCache() async {
    // Implementation for clearing any cached statement data
    // This can be used for testing or when data needs to be refreshed
    if (kDebugMode) {}
  }
}
