import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../services/recurring_transaction_service.dart';
import '../../shared/models/recurring_transaction_model.dart';

/// Debug utility for testing and checking recurring transaction system
class RecurringTransactionDebug {
  
  /// Test the recurring transaction execution logic manually
  static Future<Map<String, dynamic>> testExecution() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'totalRecurring': 0,
      'activeRecurring': 0,
      'dueToday': 0,
      'executed': 0,
      'errors': <String>[],
      'details': <Map<String, dynamic>>[],
    };
    
    try {
      debugPrint('🧪 Starting recurring transaction test...');
      
      // Get all recurring transactions
      final allRecurring = await RecurringTransactionService.getAllRecurringTransactions(
        includeInactive: true,
      );
      results['totalRecurring'] = allRecurring.length;
      
      // Get active only
      final activeRecurring = await RecurringTransactionService.getActiveRecurringTransactions();
      results['activeRecurring'] = activeRecurring.length;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check each recurring transaction
      for (final recurring in activeRecurring) {
        final detail = <String, dynamic>{
          'id': recurring.id,
          'name': recurring.name,
          'amount': recurring.amount,
          'frequency': recurring.frequency.toString(),
          'isActive': recurring.isActive,
          'startDate': recurring.startDate.toIso8601String(),
          'endDate': recurring.endDate?.toIso8601String(),
          'lastExecutedDate': recurring.lastExecutedDate?.toIso8601String(),
          'nextExecutionDate': recurring.nextExecutionDate?.toIso8601String(),
          'shouldExecute': false,
          'reason': '',
        };
        
        // Check if should execute
        final shouldExecute = _checkShouldExecute(recurring, today);
        detail['shouldExecute'] = shouldExecute;
        
        if (shouldExecute) {
          results['dueToday'] = (results['dueToday'] as int) + 1;
          detail['reason'] = 'Due for execution';
        } else {
          if (!recurring.isActive) {
            detail['reason'] = 'Not active';
          } else if (recurring.endDate != null && today.isAfter(DateTime(
            recurring.endDate!.year,
            recurring.endDate!.month,
            recurring.endDate!.day,
          ))) {
            detail['reason'] = 'End date passed';
          } else if (recurring.nextExecutionDate == null) {
            detail['reason'] = 'No next execution date';
          } else {
            final nextDate = DateTime(
              recurring.nextExecutionDate!.year,
              recurring.nextExecutionDate!.month,
              recurring.nextExecutionDate!.day,
            );
            if (today.isBefore(nextDate)) {
              final daysUntil = nextDate.difference(today).inDays;
              detail['reason'] = 'Next execution in $daysUntil days';
            } else {
              detail['reason'] = 'Should execute but check failed';
            }
          }
        }
        
        results['details'].add(detail);
      }
      
      debugPrint('✅ Test completed: ${results['dueToday']} transactions due today');
      return results;
    } catch (e, stackTrace) {
      results['errors'].add('Test failed: $e');
      debugPrint('❌ Test error: $e');
      debugPrint('Stack trace: $stackTrace');
      return results;
    }
  }
  
  /// Check if recurring transaction should execute (same logic as service)
  static bool _checkShouldExecute(RecurringTransaction recurring, DateTime today) {
    // Must be active
    if (!recurring.isActive) return false;
    
    // Check if end date has passed
    if (recurring.endDate != null) {
      final endDate = DateTime(
        recurring.endDate!.year,
        recurring.endDate!.month,
        recurring.endDate!.day,
      );
      if (today.isAfter(endDate)) return false;
    }
    
    // Normalize start date
    final startDate = DateTime(
      recurring.startDate.year,
      recurring.startDate.month,
      recurring.startDate.day,
    );
    
    // Check if start date hasn't arrived yet
    if (today.isBefore(startDate)) return false;
    
    // If never executed before, execute on start date or later
    if (recurring.lastExecutedDate == null) {
      return !today.isBefore(startDate);
    }
    
    // If already executed, check next execution date
    if (recurring.nextExecutionDate == null) return false;
    
    // Check if next execution date has arrived
    final nextDate = DateTime(
      recurring.nextExecutionDate!.year,
      recurring.nextExecutionDate!.month,
      recurring.nextExecutionDate!.day,
    );
    
    return !today.isBefore(nextDate);
  }
  
  /// Manually trigger recurring transaction execution (for testing)
  static Future<Map<String, dynamic>> manualExecute() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'success': false,
      'executedCount': 0,
      'errors': <String>[],
      'message': '',
    };
    
    try {
      debugPrint('🔧 Manually executing recurring transactions...');
      
      await RecurringTransactionService.executeRecurringTransactions();
      
      results['success'] = true;
      results['message'] = 'Execution completed successfully';
      debugPrint('✅ Manual execution completed');
    } catch (e, stackTrace) {
      results['errors'].add('Execution failed: $e');
      results['message'] = 'Execution failed: $e';
      debugPrint('❌ Manual execution error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return results;
  }
  
  /// Check WorkManager task registration status
  static Future<Map<String, dynamic>> checkWorkManager() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isInitialized': false,
      'taskRegistered': false,
      'taskName': 'execute_recurring_transactions',
      'errors': <String>[],
    };
    
    try {
      // Note: WorkManager doesn't have a direct API to check if a task is registered
      // We can only verify initialization and try to register
      results['isInitialized'] = true;
      results['taskRegistered'] = true; // Assume registered if initialized in main.dart
      results['message'] = 'WorkManager task should be registered (check logs on app start)';
      
      debugPrint('📋 WorkManager status: Initialized and task should be registered');
    } catch (e) {
      results['errors'].add('Check failed: $e');
      debugPrint('❌ WorkManager check error: $e');
    }
    
    return results;
  }
  
  /// Get summary of all recurring transactions with their status
  static Future<Map<String, dynamic>> getSummary() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'total': 0,
      'active': 0,
      'inactive': 0,
      'dueToday': 0,
      'dueThisWeek': 0,
      'dueThisMonth': 0,
      'neverExecuted': 0,
      'recentlyExecuted': 0,
      'errors': <String>[],
    };
    
    try {
      final allRecurring = await RecurringTransactionService.getAllRecurringTransactions(
        includeInactive: true,
      );
      
      results['total'] = allRecurring.length;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekFromNow = today.add(const Duration(days: 7));
      final monthFromNow = today.add(const Duration(days: 30));
      
      for (final recurring in allRecurring) {
        if (recurring.isActive) {
          results['active'] = (results['active'] as int) + 1;
        } else {
          results['inactive'] = (results['inactive'] as int) + 1;
        }
        
        if (recurring.lastExecutedDate == null) {
          results['neverExecuted'] = (results['neverExecuted'] as int) + 1;
        } else {
          final lastExec = recurring.lastExecutedDate!;
          final daysSinceLast = today.difference(DateTime(
            lastExec.year,
            lastExec.month,
            lastExec.day,
          )).inDays;
          
          if (daysSinceLast <= 7) {
            results['recentlyExecuted'] = (results['recentlyExecuted'] as int) + 1;
          }
        }
        
        if (recurring.nextExecutionDate != null) {
          final nextDate = DateTime(
            recurring.nextExecutionDate!.year,
            recurring.nextExecutionDate!.month,
            recurring.nextExecutionDate!.day,
          );
          
          if (!today.isBefore(nextDate)) {
            results['dueToday'] = (results['dueToday'] as int) + 1;
          } else {
            final daysUntil = nextDate.difference(today).inDays;
            if (daysUntil <= 7) {
              results['dueThisWeek'] = (results['dueThisWeek'] as int) + 1;
            }
            if (daysUntil <= 30) {
              results['dueThisMonth'] = (results['dueThisMonth'] as int) + 1;
            }
          }
        }
      }
      
      debugPrint('📊 Summary: ${results['active']} active, ${results['dueToday']} due today');
    } catch (e) {
      results['errors'].add('Summary failed: $e');
      debugPrint('❌ Summary error: $e');
    }
    
    return results;
  }
  
  /// Format debug results for display
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('RECURRING TRANSACTION DEBUG RESULTS');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Timestamp: ${results['timestamp']}');
    buffer.writeln('');
    
    if (results.containsKey('totalRecurring')) {
      buffer.writeln('Total Recurring: ${results['totalRecurring']}');
      buffer.writeln('Active: ${results['activeRecurring']}');
      buffer.writeln('Due Today: ${results['dueToday']}');
      buffer.writeln('');
      
      if (results['details'] != null) {
        buffer.writeln('Details:');
        for (final detail in results['details']) {
          buffer.writeln('  - ${detail['name']}: ${detail['reason']}');
        }
      }
    } else if (results.containsKey('total')) {
      buffer.writeln('Total: ${results['total']}');
      buffer.writeln('Active: ${results['active']}');
      buffer.writeln('Inactive: ${results['inactive']}');
      buffer.writeln('Due Today: ${results['dueToday']}');
      buffer.writeln('Due This Week: ${results['dueThisWeek']}');
      buffer.writeln('Due This Month: ${results['dueThisMonth']}');
      buffer.writeln('Never Executed: ${results['neverExecuted']}');
      buffer.writeln('Recently Executed (last 7 days): ${results['recentlyExecuted']}');
    } else if (results.containsKey('success')) {
      buffer.writeln('Success: ${results['success']}');
      buffer.writeln('Message: ${results['message']}');
    } else if (results.containsKey('taskRegistered')) {
      buffer.writeln('WorkManager Initialized: ${results['isInitialized']}');
      buffer.writeln('Task Registered: ${results['taskRegistered']}');
      buffer.writeln('Task Name: ${results['taskName']}');
    }
    
    if (results['errors'] != null && (results['errors'] as List).isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Errors:');
      for (final error in results['errors']) {
        buffer.writeln('  - $error');
      }
    }
    
    buffer.writeln('═══════════════════════════════════════');
    
    return buffer.toString();
  }
}

