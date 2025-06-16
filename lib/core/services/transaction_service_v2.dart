import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../../shared/models/models_v2.dart';

/// Service for managing transactions (income, expense, transfer)
class TransactionServiceV2 {
  static SupabaseClient get _client => SupabaseManager.client;

  /// Get all transactions for the current user
  static Future<List<TransactionWithDetailsV2>> getAllTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Get transactions by type
  static Future<List<TransactionWithDetailsV2>> getTransactionsByType({
    required TransactionType type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .eq('type', type.value)
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions by type: $e');
      rethrow;
    }
  }

  /// Get transactions for a specific account
  static Future<List<TransactionWithDetailsV2>> getTransactionsByAccount({
    required String accountId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .or('source_account_id.eq.$accountId,target_account_id.eq.$accountId')
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions by account: $e');
      rethrow;
    }
  }

  /// Get transactions by date range
  static Future<List<TransactionWithDetailsV2>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .gte('transaction_date', startDate.toIso8601String())
          .lte('transaction_date', endDate.toIso8601String())
          .order('transaction_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions by date range: $e');
      rethrow;
    }
  }

  /// Create a new transaction using RPC function
  static Future<String> createTransaction({
    required TransactionType type,
    required double amount,
    required String description,
    required String sourceAccountId,
    String? targetAccountId,
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc('create_transaction', params: {
        'p_type': type.value,
        'p_amount': amount,
        'p_description': description,
        'p_source_account_id': sourceAccountId,
        'p_target_account_id': targetAccountId,
        'p_category_id': categoryId,
        'p_transaction_date': (transactionDate ?? DateTime.now()).toIso8601String(),
        'p_notes': notes,
      });

      return response as String;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }
  }

  /// Delete transaction
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      // Use the database function that handles installment logic
      final result = await _client.rpc('delete_transaction', params: {
        'p_transaction_id': transactionId,
      });
      
      debugPrint('✅ Transaction deleted successfully: $transactionId');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
        return false;
      }
  }

  /// Delete installment transaction (refunds total amount)
  static Future<bool> deleteInstallmentTransaction(String transactionId) async {
    try {
      // Use the enhanced database function for installment deletion
      final result = await _client.rpc('delete_installment_transaction', params: {
        'p_transaction_id': transactionId,
      });

      debugPrint('✅ Installment transaction deleted successfully: $transactionId');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Error deleting installment transaction: $e');
      return false;
    }
  }

  /// Update account balances after transaction deletion
  static Future<void> _updateAccountBalancesAfterDelete(TransactionWithDetailsV2 transaction) async {
    try {
      switch (transaction.type) {
        case TransactionType.income:
          // Reverse income: subtract from source account
          await _client.rpc('update_account_balance', params: {
            'p_account_id': transaction.sourceAccountId,
            'p_amount': transaction.amount,
            'p_operation': 'subtract',
          });
          break;
          
        case TransactionType.expense:
          // Reverse expense: add back to source account
          await _client.rpc('update_account_balance', params: {
            'p_account_id': transaction.sourceAccountId,
            'p_amount': transaction.amount,
            'p_operation': 'add',
          });
          break;
          
        case TransactionType.transfer:
          if (transaction.targetAccountId != null) {
            // Reverse transfer: add back to source, subtract from target
            await _client.rpc('update_account_balance', params: {
              'p_account_id': transaction.sourceAccountId,
              'p_amount': transaction.amount,
              'p_operation': 'add',
            });
            await _client.rpc('update_account_balance', params: {
              'p_account_id': transaction.targetAccountId!,
              'p_amount': transaction.amount,
              'p_operation': 'subtract',
            });
          }
          break;
      }
    } catch (e) {
      debugPrint('Error updating account balances after delete: $e');
      // Don't rethrow - transaction is already deleted
    }
  }

  /// Update transaction details
  static Future<TransactionModelV2> updateTransaction({
    required String transactionId,
    String? description,
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (description != null) updateData['description'] = description;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (transactionDate != null) updateData['transaction_date'] = transactionDate.toIso8601String();
      if (notes != null) updateData['notes'] = notes;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('transactions')
          .update(updateData)
          .eq('id', transactionId)
          .select()
          .single();

      return TransactionModelV2.fromJson(response);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  /// Get transaction by ID
  static Future<TransactionWithDetailsV2?> getTransactionById(String transactionId) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .eq('id', transactionId)
          .single();

      return TransactionWithDetailsV2.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching transaction by ID: $e');
      return null;
    }
  }

  /// Get monthly transaction summary using RPC function
  static Future<Map<String, dynamic>> getMonthlyTransactionSummary({
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      final response = await _client.rpc('get_monthly_transaction_summary', params: {
        'p_year': targetYear,
        'p_month': targetMonth,
      });

      final data = response[0] as Map<String, dynamic>;
      return {
        'totalIncome': (data['total_income'] as num?)?.toDouble() ?? 0.0,
        'totalExpenses': (data['total_expenses'] as num?)?.toDouble() ?? 0.0,
        'netAmount': (data['net_amount'] as num?)?.toDouble() ?? 0.0,
        'transactionCount': data['transaction_count'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching monthly summary: $e');
      return {
        'totalIncome': 0.0,
        'totalExpenses': 0.0,
        'netAmount': 0.0,
        'transactionCount': 0,
      };
    }
  }

  /// Get transactions by category
  static Future<List<TransactionWithDetailsV2>> getTransactionsByCategory({
    required String categoryId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .eq('category_id', categoryId)
          .order('transaction_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching transactions by category: $e');
      rethrow;
    }
  }

  /// Search transactions by description
  static Future<List<TransactionWithDetailsV2>> searchTransactions({
    required String query,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .ilike('description', '%$query%')
          .order('transaction_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching transactions: $e');
      rethrow;
    }
  }

  /// Get recent transactions (last 10)
  static Future<List<TransactionWithDetailsV2>> getRecentTransactions() async {
    return getAllTransactions(limit: 10, offset: 0);
  }

  /// Get income transactions only
  static Future<List<TransactionWithDetailsV2>> getIncomeTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    return getTransactionsByType(
      type: TransactionType.income,
      limit: limit,
      offset: offset,
    );
  }

  /// Get expense transactions only
  static Future<List<TransactionWithDetailsV2>> getExpenseTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    return getTransactionsByType(
      type: TransactionType.expense,
      limit: limit,
      offset: offset,
    );
  }

  /// Get transfer transactions only
  static Future<List<TransactionWithDetailsV2>> getTransferTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    return getTransactionsByType(
      type: TransactionType.transfer,
      limit: limit,
      offset: offset,
    );
  }

  /// Get installment transactions only
  static Future<List<TransactionWithDetailsV2>> getInstallmentTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('transaction_summary')
          .select('*')
          .not('installment_id', 'is', null)
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TransactionWithDetailsV2.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching installment transactions: $e');
      rethrow;
    }
  }
} 