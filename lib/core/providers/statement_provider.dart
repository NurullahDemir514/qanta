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
  StatementSummary? currentStatement;
  StatementSummary? previousStatement;
  List<StatementSummary> futureStatements = [];
  List<StatementSummary> pastStatements = [];
  bool isLoading = false;
  String? error;
  
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
  }

  Future<void> loadStatements(String cardId, int statementDay, {int? dueDay}) async {
    print('🔍 StatementProvider.loadStatements called:');
    print('   CardId: $cardId');
    print('   StatementDay: $statementDay');
    print('   DueDay: $dueDay');
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Store current parameters for real-time updates
      _currentCardId = cardId;
      _currentStatementDay = statementDay;
      _currentDueDay = dueDay;
      
      // Get UnifiedProviderV2 from context
      if (_unifiedProvider == null) {
        print('🔍 ERROR: UnifiedProvider is NULL!');
        error = 'UnifiedProvider not available';
        return;
      }
      
      // Always use cache from UnifiedProviderV2 for consistency
      if (_unifiedProvider!.isDataLoaded) {
        print('🔍 Using existing cache');
        await _loadStatementsFromCache(cardId, statementDay, dueDay: dueDay);
      } else {
        print('🔍 Loading data first, then using cache');
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
  Future<void> _loadStatementsFromCache(String cardId, int statementDay, {int? dueDay}) async {
    print('🔍 _loadStatementsFromCache called:');
    print('   CardId: $cardId');
    print('   StatementDay: $statementDay');
    print('   DueDay: $dueDay');
    
    final currentPeriod = _calculateCurrentPeriod(statementDay, dueDay: dueDay);
    
    // Use cached transactions and installments from UnifiedProviderV2
    final transactions = _unifiedProvider!.transactions
        .where((t) => t.sourceAccountId == cardId)
        .toList();
    
    final installments = _unifiedProvider!.installments
        .where((i) => i.sourceAccountId == cardId)
        .toList();

    // Calculate current statement from cached data
    currentStatement = await _calculateStatementFromCache(
      cardId, 
      currentPeriod, 
      transactions, 
      installments
    );
    notifyListeners();

    // For past and future statements, calculate periods locally from cache
    final futurePeriods = _calculateFuturePeriods(statementDay, dueDay: dueDay);
    final pastPeriods = _calculatePastPeriods(statementDay, dueDay: dueDay);

    // Calculate past statements from cache
    final pastResults = <StatementSummary>[];
    for (final period in pastPeriods) {
      final pastStatement = await _calculateStatementFromCache(cardId, period, transactions, installments);
      
      // Filter out past statements with no transactions and no installments
      if (pastStatement.transactionCount == 0 && pastStatement.upcomingInstallments.isEmpty) {
        print('   ❌ Skipping empty past statement');
        continue;
      }
      
      pastResults.add(pastStatement);
    }
    
    // Calculate future statements from cache
    final futureResults = <StatementSummary>[];
    print('🔍 Calculating future statements: ${futurePeriods.length} periods');
    
    // Find the last installment due date to limit future statements
    DateTime? lastInstallmentDueDate;
    for (final installment in installments) {
      final installmentDueDate = installment.startDate.add(Duration(days: 30 * (installment.count - 1)));
      if (lastInstallmentDueDate == null || installmentDueDate.isAfter(lastInstallmentDueDate)) {
        lastInstallmentDueDate = installmentDueDate;
      }
    }
    
    for (final period in futurePeriods) {
      print('🔍 Processing future period: ${period.startDate} to ${period.endDate}');
      final futureStatement = await _calculateStatementFromCache(cardId, period, transactions, installments);
      
      // Filter out statements with no installments and no transactions
      if (futureStatement.upcomingInstallments.isEmpty && futureStatement.transactionCount == 0) {
        print('   ❌ Skipping empty statement');
        continue;
      }
      
      // Filter out statements after last installment due date
      if (lastInstallmentDueDate != null && period.startDate.isAfter(lastInstallmentDueDate)) {
        print('   ❌ Skipping statement after last installment');
        continue;
      }
      
      // Filter out overdue statements with 0 amount
      if (period.dueDate.isBefore(DateTime.now()) && futureStatement.totalAmount == 0) {
        print('   ❌ Skipping overdue statement with 0 amount');
        continue;
      }
      
      print('   ✅ Adding statement with amount: ${futureStatement.totalAmount}');
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
      print('🔄 Transaction change detected, reloading statements...');
      _reloadStatements();
    });
    
    // Also listen to installment_masters for installment changes
    FirebaseFirestore.instance
        .collection('installment_masters')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('source_account_id', isEqualTo: cardId)
        .snapshots()
        .listen((snapshot) {
      print('🔄 Installment change detected, reloading statements...');
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
      _loadStatementsFromCache(_currentCardId!, _currentStatementDay!, dueDay: _currentDueDay);
    }
  }

  /// Calculate current period locally from cache
  StatementPeriod _calculateCurrentPeriod(int statementDay, {int? dueDay}) {
    final now = DateTime.now();
    final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(statementDay, referenceDate: now);
    final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(statementDay, referenceDate: now);
    final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(statementDay, referenceDate: now, dueDay: dueDay);
    
    return StatementPeriod(
      startDate: startDate,
      endDate: endDate,
      dueDate: dueDate,
      statementDay: statementDay,
    );
  }

  /// Calculate future periods locally from cache
  List<StatementPeriod> _calculateFuturePeriods(int statementDay, {int? dueDay}) {
    final periods = <StatementPeriod>[];
    final now = DateTime.now();
    
    // Generate next 12 months of future periods
    for (int i = 1; i <= 12; i++) {
      final futureDate = DateTime(now.year, now.month + i, 1);
      final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(statementDay, referenceDate: futureDate);
      final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(statementDay, referenceDate: futureDate);
      final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(statementDay, referenceDate: futureDate, dueDay: dueDay);
      
      periods.add(StatementPeriod(
        startDate: startDate,
        endDate: endDate,
        dueDate: dueDate,
        statementDay: statementDay,
      ));
    }
    
    return periods;
  }

  /// Calculate past periods locally from cache
  List<StatementPeriod> _calculatePastPeriods(int statementDay, {int? dueDay}) {
    final periods = <StatementPeriod>[];
    final now = DateTime.now();
    
    // Generate last 12 months of past periods
    for (int i = 1; i <= 12; i++) {
      final pastDate = DateTime(now.year, now.month - i, 1);
      final startDate = QantaDateUtils.DateUtils.getStatementPeriodStart(statementDay, referenceDate: pastDate);
      final endDate = QantaDateUtils.DateUtils.getStatementPeriodEnd(statementDay, referenceDate: pastDate);
      final dueDate = QantaDateUtils.DateUtils.getStatementDueDate(statementDay, referenceDate: pastDate, dueDay: dueDay);
      
      periods.add(StatementPeriod(
        startDate: startDate,
        endDate: endDate,
        dueDate: dueDate,
        statementDay: statementDay,
      ));
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
    print('🔍 _calculateStatementFromCache called:');
    print('   Period: ${period.startDate} to ${period.endDate}');
    print('   Transactions count: ${transactions.length}');
    print('   Installments count: ${installments.length}');
    double totalAmount = 0.0;
    double paidAmount = 0.0;
    int transactionCount = 0;
    final upcomingInstallments = <UpcomingInstallment>[];

    // Calculate from transactions
    for (final transaction in transactions) {
      final transactionDate = transaction.transactionDate;
      
      if (transactionDate.isAfter(period.startDate) && transactionDate.isBefore(period.endDate)) {
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
      }
    }

    // Calculate from installments
    for (final installment in installments) {
      final startDate = installment.startDate;
      
        // Check if installment was created in current period (for first installments)
        if (startDate.isAfter(period.startDate) && startDate.isBefore(period.endDate)) {
          // Get first installment amount
          final firstInstallmentAmount = installment.totalAmount / installment.count;
          totalAmount += firstInstallmentAmount;
          
          // Create UpcomingInstallment for first installment
          final upcomingInstallment = UpcomingInstallment(
            id: '${installment.id}_1',
            description: installment.description,
            amount: firstInstallmentAmount,
            dueDate: installment.startDate.add(const Duration(days: 30)), // Approximate due date
            installmentNumber: 1,
            totalInstallments: installment.count,
            isPaid: false,
            categoryName: _getCategoryNameFromId(installment.categoryId),
            categoryIcon: _getCategoryIconFromId(installment.categoryId),
            categoryColor: _getCategoryColorFromId(installment.categoryId),
          );
          upcomingInstallments.add(upcomingInstallment);
        } else if (startDate.isBefore(period.startDate)) {
          // For future periods, check if any installment is due in this period
          final installmentAmount = installment.totalAmount / installment.count;
          
          // Calculate which installment should be due in this period
          // Use month-based calculation instead of day-based
          final startYear = startDate.year;
          final startMonth = startDate.month;
          final periodYear = period.startDate.year;
          final periodMonth = period.startDate.month;
          
          final monthsSinceStart = (periodYear - startYear) * 12 + (periodMonth - startMonth);
          final installmentNumber = (monthsSinceStart + 1).toInt();
          
          // Check if this installment number is valid and due in this period
          if (installmentNumber >= 1 && installmentNumber <= installment.count) {
            // Calculate due date as start of the period month
            final dueDate = DateTime(periodYear, periodMonth, startDate.day);
            
            // Check if due date falls within this period
            if (dueDate.isAfter(period.startDate) && dueDate.isBefore(period.endDate)) {
              totalAmount += installmentAmount;
              
              // Create UpcomingInstallment for this installment
              final upcomingInstallment = UpcomingInstallment(
                id: '${installment.id}_$installmentNumber',
                description: installment.description,
                amount: installmentAmount,
                dueDate: dueDate,
                installmentNumber: installmentNumber,
                totalInstallments: installment.count,
                isPaid: false,
                categoryName: _getCategoryNameFromId(installment.categoryId),
                categoryIcon: _getCategoryIconFromId(installment.categoryId),
                categoryColor: _getCategoryColorFromId(installment.categoryId),
              );
              upcomingInstallments.add(upcomingInstallment);
            }
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
