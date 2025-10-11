import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/models_v2.dart';
import '../../shared/models/statement_summary.dart';
import '../../shared/models/statement_period.dart';
import '../../shared/utils/date_utils.dart' as QantaDateUtils;
import '../../shared/services/category_icon_service.dart';
import 'unified_provider_v2.dart';

import '../services/statement_service.dart';

class StatementProvider extends ChangeNotifier {
  /// Singleton instance
  static StatementProvider? _instance;

  /// Get singleton instance
  static StatementProvider get instance => _instance ??= StatementProvider._();

  /// Private constructor for singleton
  StatementProvider._();

  StatementSummary? _currentStatement;
  StatementSummary? previousStatement;
  List<StatementSummary> futureStatements = [];
  List<StatementSummary> pastStatements = [];
  bool isLoading = false;
  String? error;

  /// Get current statement
  StatementSummary? get currentStatement => _currentStatement;

  /// Set current statement and notify listeners
  set currentStatement(StatementSummary? value) {
    _currentStatement = value;

    // Also update UnifiedProviderV2 cache if available
    if (_unifiedProvider != null && value != null) {
      _unifiedProvider!.updateCurrentStatement(value.cardId, value);
    }

    notifyListeners();
  }

  // UnifiedProviderV2 referansı
  UnifiedProviderV2? _unifiedProvider;

  // Real-time listener
  StreamSubscription? _transactionSubscription;
  String? _currentCardId;
  int? _currentStatementDay;
  int? _currentDueDay;

  /// Set UnifiedProviderV2 reference
  void setUnifiedProvider(UnifiedProviderV2 provider) {
    _unifiedProvider = provider;
    // Also set this StatementProvider in UnifiedProviderV2
    provider.setStatementProvider(this);
  }

  Future<void> loadStatements(
    String cardId,
    int statementDay, {
    int? dueDay,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Store current parameters for real-time updates
      _currentCardId = cardId;
      _currentStatementDay = statementDay;
      _currentDueDay = dueDay;

      // Only clear current statement if it's a different card or forced reload
      if (_currentStatement?.cardId != cardId) {
        _currentStatement = null;
      }

      // Get UnifiedProviderV2 from context
      if (_unifiedProvider == null) {
        error = 'UnifiedProvider not available';
        return;
      }

      // Always use cache from UnifiedProviderV2 for consistency
      if (_unifiedProvider!.isDataLoaded) {
        await _loadStatementsFromCache(cardId, statementDay, dueDay: dueDay);
      } else {
        // If cache not available, load data first then use cache
        await _unifiedProvider!.loadAllData();
        await _loadStatementsFromCache(cardId, statementDay, dueDay: dueDay);
      }

      // Setup real-time listener for this card
      _setupRealTimeListener(cardId);
    } catch (e) {
      error = e.toString();
      debugPrint('Error loading statements: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load statements from UnifiedProviderV2 cache
  Future<void> _loadStatementsFromCache(
    String cardId,
    int statementDay, {
    int? dueDay,
  }) async {
    final currentPeriod = _calculateCurrentPeriod(statementDay, dueDay: dueDay);

    // Use cached transactions and installments from UnifiedProviderV2
    final transactions = _unifiedProvider!.transactions
        .where((t) => t.sourceAccountId == cardId)
        .toList();

    final installments = _unifiedProvider!.installments
        .where((i) => i.sourceAccountId == cardId)
        .toList();

    // Calculate current statement from cached data
    final newStatement = await _calculateStatementFromCache(
      cardId,
      currentPeriod,
      transactions,
      installments,
    );

    // Preserve isPaid status if current statement exists and is paid
    if (_currentStatement != null &&
        _currentStatement!.isPaid &&
        newStatement.id == _currentStatement!.id) {
      currentStatement = newStatement.copyWith(
        isPaid: true,
        paidAt: _currentStatement!.paidAt,
        period: newStatement.period.copyWith(
          isPaid: true,
          paidAt: _currentStatement!.paidAt,
        ),
      );
    } else {
      currentStatement = newStatement;
    }

    notifyListeners();

    // For past and future statements, calculate periods locally from cache
    final futurePeriods = _calculateFuturePeriods(
      statementDay,
      dueDay: dueDay,
      cardId: cardId,
    );
    final pastPeriods = await _calculatePastPeriodsWithFirebase(
      cardId,
      statementDay,
      dueDay: dueDay,
    );

    // Calculate past statements from cache
    final pastResults = <StatementSummary>[];
    for (final period in pastPeriods) {
      final pastStatement = await _calculateStatementFromCache(
        cardId,
        period,
        transactions,
        installments,
      );

      // Filter out past statements with no transactions and no installments
      if (pastStatement.transactionCount == 0 &&
          pastStatement.upcomingInstallments.isEmpty) {
        continue;
      }

      pastResults.add(pastStatement);
    }

    // Calculate future statements from cache
    final futureResults = <StatementSummary>[];

    // Find the last installment due date to limit future statements
    // Only consider installments for this specific card
    DateTime? lastInstallmentDueDate;
    final cardInstallments = installments
        .where((installment) => installment.sourceAccountId == cardId)
        .toList();

    for (final installment in cardInstallments) {
      // Calculate last installment due date more accurately
      final lastInstallmentMonth =
          installment.startDate.month + (installment.count - 1);
      final lastInstallmentYear =
          installment.startDate.year + (lastInstallmentMonth ~/ 12);
      final lastInstallmentMonthAdjusted = lastInstallmentMonth % 12;
      final installmentDueDate = DateTime(
        lastInstallmentYear,
        lastInstallmentMonthAdjusted == 0 ? 12 : lastInstallmentMonthAdjusted,
        installment.startDate.day,
      );

      if (lastInstallmentDueDate == null ||
          installmentDueDate.isAfter(lastInstallmentDueDate)) {
        lastInstallmentDueDate = installmentDueDate;
      }
    }

    // No buffer needed - use exact last installment date

    debugPrint(
      '[FUTURE_STATEMENT] Processing ${futurePeriods.length} future periods',
    );
    debugPrint(
      '[FUTURE_STATEMENT] Last installment due date: $lastInstallmentDueDate',
    );

    for (final period in futurePeriods) {
      final futureStatement = await _calculateStatementFromCache(
        cardId,
        period,
        transactions,
        installments,
      );

      debugPrint(
        '[FUTURE_STATEMENT] Period: ${period.startDate} - ${period.endDate}',
      );
      debugPrint(
        '[FUTURE_STATEMENT] Total amount: ${futureStatement.totalAmount}',
      );
      debugPrint(
        '[FUTURE_STATEMENT] Installments: ${futureStatement.upcomingInstallments.length}',
      );
      debugPrint(
        '[FUTURE_STATEMENT] Transactions: ${futureStatement.transactionCount}',
      );

      // Filter out statements that start on or before current statement day
      final currentStatementDay = DateTime(DateTime.now().year, DateTime.now().month, statementDay);
      if (period.startDate.isAtSameMomentAs(currentStatementDay) || 
          period.startDate.isBefore(currentStatementDay)) {
        debugPrint(
          '[FUTURE_STATEMENT] Skipping current period statement for ${period.startDate}',
        );
        continue;
      }

      // Filter out statements after last installment due date
      if (lastInstallmentDueDate != null &&
          period.startDate.isAfter(lastInstallmentDueDate)) {
        debugPrint(
          '[FUTURE_STATEMENT] Skipping statement after last installment due date',
        );
        continue;
      }

      // Filter out overdue statements with 0 amount
      if (period.dueDate.isBefore(DateTime.now()) &&
          futureStatement.totalAmount == 0) {
        debugPrint(
          '[FUTURE_STATEMENT] Skipping overdue statement with 0 amount',
        );
        continue;
      }

      debugPrint(
        '[FUTURE_STATEMENT] Adding future statement for ${period.startDate}',
      );
      futureResults.add(futureStatement);
    }

    pastStatements = pastResults;
    futureStatements = futureResults;

    // Notify listeners after all statements are calculated
    notifyListeners();
  }

  // _loadStatementsFromFirebase method removed - now using only cache-based calculation

  /// Setup real-time listener for transaction and installment changes
  void _setupRealTimeListener(String cardId) {
    // Cancel existing listeners
    _transactionSubscription?.cancel();

    // Listen to both transactions and installments for real-time updates
    _transactionSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('source_account_id', isEqualTo: cardId)
        .snapshots()
        .listen((snapshot) {
          _reloadStatements();
        });

    // Also listen to installment_masters for installment changes
    FirebaseFirestore.instance
        .collection('installment_masters')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('source_account_id', isEqualTo: cardId)
        .snapshots()
        .listen((snapshot) {
          _reloadStatements();
        });
  }

  /// Reload statements from cache
  void _reloadStatements() {
    if (_currentCardId != null && _currentStatementDay != null) {
      // Reload data from UnifiedProviderV2 first to get latest data
      _unifiedProvider?.loadTransactions();
      _unifiedProvider?.loadInstallments();

      // Then recalculate statements from updated cache
      _loadStatementsFromCache(
        _currentCardId!,
        _currentStatementDay!,
        dueDay: _currentDueDay,
      );
    }
  }

  /// Calculate current period locally from cache
  StatementPeriod _calculateCurrentPeriod(int statementDay, {int? dueDay}) {
    final now = DateTime.now();
    final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(
      statementDay,
      referenceDate: now,
    );
    final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(
      statementDay,
      referenceDate: now,
    );
    final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(
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

  /// Calculate future periods locally from cache
  List<StatementPeriod> _calculateFuturePeriods(
    int statementDay, {
    int? dueDay,
    String? cardId,
  }) {
    final periods = <StatementPeriod>[];
    final now = DateTime.now();

    // Calculate how many months we need to cover all installments
    int maxMonthsNeeded = 6; // Default minimum

    // Check only installments for this specific card to find the latest due date
    if (_unifiedProvider != null && cardId != null) {
      final installments = _unifiedProvider!.installments
          .where((installment) => installment.sourceAccountId == cardId)
          .toList();

      debugPrint(
        '[FUTURE_STATEMENT] Found ${installments.length} installments for card $cardId',
      );

      for (final installment in installments) {
        // Calculate when this installment will end
        final lastInstallmentMonth =
            installment.startDate.month + (installment.count - 1);
        final lastInstallmentYear =
            installment.startDate.year + (lastInstallmentMonth ~/ 12);
        final lastInstallmentMonthAdjusted = lastInstallmentMonth % 12;
        final lastInstallmentDate = DateTime(
          lastInstallmentYear,
          lastInstallmentMonthAdjusted == 0 ? 12 : lastInstallmentMonthAdjusted,
          installment.startDate.day,
        );

        // Calculate months from now to last installment
        final monthsFromNow =
            (lastInstallmentDate.year - now.year) * 12 +
            (lastInstallmentDate.month - now.month);

        debugPrint(
          '[FUTURE_STATEMENT] Installment ${installment.id}: ${installment.count} installments, ends on $lastInstallmentDate, months from now: $monthsFromNow',
        );

        if (monthsFromNow > maxMonthsNeeded) {
          maxMonthsNeeded = monthsFromNow + 1; // Add 1 month buffer
          debugPrint(
            '[FUTURE_STATEMENT] Updated maxMonthsNeeded to $maxMonthsNeeded based on installment ${installment.id}',
          );
        }
      }
    }

    debugPrint(
      '[FUTURE_STATEMENT] Generating $maxMonthsNeeded months of future periods',
    );

    // Generate future periods until last installment
    // Start from next month to avoid including current period
    for (int i = 1; i <= maxMonthsNeeded; i++) {
      final futureDate = DateTime(now.year, now.month + i, 1);
      final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(
        statementDay,
        referenceDate: futureDate,
      );
      final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(
        statementDay,
        referenceDate: futureDate,
      );
      final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(
        statementDay,
        referenceDate: futureDate,
        dueDay: dueDay,
      );

      // Filter out periods that start before or on the current statement day
      // Only include periods that start AFTER the current statement day
      final currentStatementDay = DateTime(now.year, now.month, statementDay);
      if (startDate.isAfter(currentStatementDay)) {
        periods.add(
          StatementPeriod(
            startDate: startDate,
            endDate: endDate,
            dueDate: dueDate,
            statementDay: statementDay,
          ),
        );
      }
    }

    return periods;
  }

  /// Calculate past periods with Firebase integration for payment status
  Future<List<StatementPeriod>> _calculatePastPeriodsWithFirebase(
    String cardId,
    int statementDay, {
    int? dueDay,
  }) async {
    try {
      // First try to get paid statements from Firebase
      final paidPeriods = await StatementService.getAllPastStatementPeriods(
        cardId,
        statementDay,
        maxMonths: 24,
      );

      if (paidPeriods.isNotEmpty) {
        return paidPeriods;
      }

      // Fallback to local calculation if no Firebase data
      return _calculatePastPeriodsLocally(statementDay, dueDay: dueDay);
    } catch (e) {
      debugPrint('Error loading past periods from Firebase: $e');
      // Fallback to local calculation on error
      return _calculatePastPeriodsLocally(statementDay, dueDay: dueDay);
    }
  }

  /// Calculate past periods locally from cache (fallback method)
  List<StatementPeriod> _calculatePastPeriodsLocally(int statementDay, {int? dueDay}) {
    final periods = <StatementPeriod>[];
    final now = DateTime.now();

    // Generate last 12 months of past periods
    for (int i = 1; i <= 12; i++) {
      final pastDate = DateTime(now.year, now.month - i, 1);
      final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(
        statementDay,
        referenceDate: pastDate,
      );
      final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(
        statementDay,
        referenceDate: pastDate,
      );
      final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(
        statementDay,
        referenceDate: pastDate,
        dueDay: dueDay,
      );

      periods.add(
        StatementPeriod(
          startDate: startDate,
          endDate: endDate,
          dueDate: dueDate,
          statementDay: statementDay,
        ),
      );
    }

    return periods;
  }

  /// Calculate statement from cached data
  Future<StatementSummary> _calculateStatementFromCache(
    String cardId,
    StatementPeriod period,
    List<dynamic> transactions,
    List<dynamic> installments,
  ) async {
    double totalAmount = 0.0;
    double paidAmount = 0.0;
    int transactionCount = 0;
    final upcomingInstallments = <UpcomingInstallment>[];

    // Calculate from transactions
    for (final transaction in transactions) {
      final transactionDate = transaction.transactionDate;

      // Include transactions that fall within the period (inclusive of end date)
      if ((transactionDate.isAfter(period.startDate) || transactionDate.isAtSameMomentAs(period.startDate)) &&
          (transactionDate.isBefore(period.endDate) || transactionDate.isAtSameMomentAs(period.endDate))) {
        final amount = transaction.amount;
        final type = transaction.type.toString().split('.').last;
        final isInstallment = transaction.isInstallment ?? false;

        if (!isInstallment) {
          if (type == 'expense') {
            totalAmount += amount.abs();
          } else if (type == 'income') {
            paidAmount += amount.abs();
          }
          transactionCount++;
        } else {
          transactionCount++;
        }
      } else {}
    }

    // Calculate from installments
    for (final installment in installments) {
      final startDate = installment.startDate;

      // Check if installment was created in current period (for first installments)
      if ((startDate.isAfter(period.startDate) || startDate.isAtSameMomentAs(period.startDate)) &&
          (startDate.isBefore(period.endDate.add(const Duration(days: 1))) || startDate.isAtSameMomentAs(period.endDate))) {
        // This installment started in current period - show first installment
        final firstInstallmentAmount =
            installment.totalAmount / installment.count;
        totalAmount += firstInstallmentAmount;

        // Calculate proper due date - use statement day of next month
        final nextMonth = period.startDate.month == 12 
            ? DateTime(period.startDate.year + 1, 1, period.statementDay)
            : DateTime(period.startDate.year, period.startDate.month + 1, period.statementDay);

        // Create UpcomingInstallment for first installment
        final upcomingInstallment = UpcomingInstallment(
          id: '${installment.id}_1',
          description: installment.description,
          amount: firstInstallmentAmount,
          dueDate: nextMonth, // Proper due date calculation
          startDate: installment.startDate, // Add transaction date
          installmentNumber: 1,
          totalInstallments: installment.count,
          isPaid: false,
          categoryName: _getCategoryNameFromId(installment.categoryId),
          categoryIcon: _getCategoryIconFromId(installment.categoryId),
          categoryColor: _getCategoryColorFromId(installment.categoryId),
        );
        upcomingInstallments.add(upcomingInstallment);

        debugPrint(
          '[STATEMENT] ✅ Added first installment (1/${installment.count}) for period ${period.startDate}, due: $nextMonth',
        );
      } else if (startDate.isBefore(period.startDate)) {
        // For installments that started before current period
        // Calculate which installment should be due in this period
        final installmentAmount = installment.totalAmount / installment.count;

        // Calculate which installment should be due in this period
        final startYear = startDate.year;
        final startMonth = startDate.month;
        final periodYear = period.startDate.year;
        final periodMonth = period.startDate.month;

        // Calculate months difference
        final monthsSinceStart =
            (periodYear - startYear) * 12 + (periodMonth - startMonth);
        final installmentNumber = (monthsSinceStart + 1).toInt();

        debugPrint(
          '[STATEMENT] Installment: ${installment.id}, Start: $startDate, Period: ${period.startDate}',
        );
        debugPrint(
          '[STATEMENT] Months since start: $monthsSinceStart, Installment #: $installmentNumber',
        );

        // Check if this installment number is valid and due in this period
        if (installmentNumber >= 1 && installmentNumber <= installment.count) {
          // Calculate due date - use statement day of the SAME month as period end
          // For future statements, installment is due at the end of the period
          final dueDate = DateTime(periodYear, periodMonth, period.statementDay);

          // Check if due date falls within this statement period
          // For future statements, installment due date should be within the period
          final isDueInPeriod = (dueDate.isAfter(period.startDate) || dueDate.isAtSameMomentAs(period.startDate)) && 
                                (dueDate.isBefore(period.endDate) || dueDate.isAtSameMomentAs(period.endDate));

          debugPrint(
            '[STATEMENT] Due date: $dueDate, Period: ${period.startDate} - ${period.endDate}',
          );
          debugPrint('[STATEMENT] Is due in period: $isDueInPeriod');

          if (isDueInPeriod) {
            totalAmount += installmentAmount;

            // Create UpcomingInstallment for this installment
            final upcomingInstallment = UpcomingInstallment(
              id: '${installment.id}_$installmentNumber',
              description: installment.description,
              amount: installmentAmount,
              dueDate: dueDate,
              startDate: installment.startDate, // Add transaction date
              installmentNumber: installmentNumber,
              totalInstallments: installment.count,
              isPaid: false,
              categoryName: _getCategoryNameFromId(installment.categoryId),
              categoryIcon: _getCategoryIconFromId(installment.categoryId),
              categoryColor: _getCategoryColorFromId(installment.categoryId),
            );
            upcomingInstallments.add(upcomingInstallment);

            debugPrint(
              '[STATEMENT] ✅ Added installment #$installmentNumber/${installment.count} (${installmentAmount}₺) for period ${period.startDate}',
            );
          } else {
            debugPrint(
              '[STATEMENT] ❌ Skipped installment #$installmentNumber - due date $dueDate not in period ${period.startDate} - ${period.endDate}',
            );
          }
        } else {
          debugPrint(
            '[STATEMENT] ❌ Invalid installment number: $installmentNumber (max: ${installment.count})',
          );
        }
      }
    }

    final remainingAmount = totalAmount - paidAmount;

    return StatementSummary(
      id: '${cardId}_${period.startDate.millisecondsSinceEpoch}',
      cardId: cardId,
      period: period,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      transactionCount: transactionCount,
      upcomingInstallments: upcomingInstallments,
    );
  }

  // Helper methods for category information
  String? _getCategoryNameFromId(String? categoryId) {
    if (categoryId == null) return null;

    // Try to find category in UnifiedProviderV2
    if (_unifiedProvider != null) {
      final category = _unifiedProvider!.categories
          .where((cat) => cat.id == categoryId)
          .firstOrNull;
      if (category != null) {
        return category.displayName;
      }
    }

    // Fallback to default
    return 'Diğer';
  }

  String? _getCategoryIconFromId(String? categoryId) {
    if (categoryId == null) return null;

    // Try to find category in UnifiedProviderV2
    if (_unifiedProvider != null) {
      final category = _unifiedProvider!.categories
          .where((cat) => cat.id == categoryId)
          .firstOrNull;
      if (category != null) {
        return category.iconName;
      }
    }

    // Fallback to default
    return 'more_horiz_rounded';
  }

  String? _getCategoryColorFromId(String? categoryId) {
    if (categoryId == null) return null;

    // Try to find category in UnifiedProviderV2
    if (_unifiedProvider != null) {
      final category = _unifiedProvider!.categories
          .where((cat) => cat.id == categoryId)
          .firstOrNull;
      if (category != null) {
        return category.colorHex;
      }
    }

    // Fallback to default
    return '#6B7280';
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
