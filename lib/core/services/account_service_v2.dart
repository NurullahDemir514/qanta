import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../../shared/models/models_v2.dart';

/// Service for managing accounts (credit cards, debit cards, cash accounts)
class AccountServiceV2 {
  static SupabaseClient get _client => SupabaseManager.client;

  /// Get all accounts for the current user
  static Future<List<AccountModel>> getAllAccounts() async {
    try {
      final response = await _client
          .from('accounts')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      rethrow;
    }
  }

  /// Get accounts by type
  static Future<List<AccountModel>> getAccountsByType(AccountType type) async {
    try {
      final response = await _client
          .from('accounts')
          .select('*')
          .eq('type', type.value)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching accounts by type: $e');
      rethrow;
    }
  }

  /// Get account by ID
  static Future<AccountModel?> getAccountById(String accountId) async {
    try {
      final response = await _client
          .from('accounts')
          .select('*')
          .eq('id', accountId)
          .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching account by ID: $e');
      return null;
    }
  }

  /// Create a new account using RPC function
  static Future<String> createAccount({
    required AccountType type,
    required String name,
    String? bankName,
    double balance = 0.0,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
  }) async {
    try {
      final response = await _client.rpc('create_account', params: {
        'p_type': type.value,
        'p_name': name,
        'p_bank_name': bankName,
        'p_balance': balance,
        'p_credit_limit': creditLimit,
        'p_statement_day': statementDay,
        'p_due_day': dueDay,
      });

      return response as String;
    } catch (e) {
      debugPrint('Error creating account: $e');
      rethrow;
    }
  }

  /// Update account balance using RPC function
  static Future<bool> updateAccountBalance({
    required String accountId,
    required double amount,
    required String operation, // 'add' or 'subtract'
  }) async {
    try {
      final response = await _client.rpc('update_account_balance', params: {
        'p_account_id': accountId,
        'p_amount': amount,
        'p_operation': operation,
      });

      return response as bool;
    } catch (e) {
      debugPrint('Error updating account balance: $e');
      rethrow;
    }
  }

  /// Update account details
  static Future<AccountModel> updateAccount({
    required String accountId,
    String? name,
    String? bankName,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (bankName != null) updateData['bank_name'] = bankName;
      if (creditLimit != null) updateData['credit_limit'] = creditLimit;
      if (statementDay != null) updateData['statement_day'] = statementDay;
      if (dueDay != null) updateData['due_day'] = dueDay;
      if (isActive != null) updateData['is_active'] = isActive;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('accounts')
          .update(updateData)
          .eq('id', accountId)
          .select()
          .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }

  /// Hard delete account (permanently remove from database)
  /// This will also cascade delete all related installment transactions
  static Future<bool> deleteAccount(String accountId) async {
    try {
      debugPrint('🗑️ Starting account deletion process for: $accountId');
      
      // Step 1: Delete related installment transactions first
      debugPrint('🗑️ Deleting installment transactions for account: $accountId');
      await _client
          .from('installment_transactions')
          .delete()
          .eq('source_account_id', accountId);
      
      // Step 2: Delete regular transactions for this account
      debugPrint('🗑️ Deleting regular transactions for account: $accountId');
      await _client
          .from('transactions')
          .delete()
          .or('source_account_id.eq.$accountId,target_account_id.eq.$accountId');
      
      // Step 3: Now delete the account
      debugPrint('🗑️ Deleting account: $accountId');
      await _client
          .from('accounts')
          .delete()
          .eq('id', accountId);
          
      debugPrint('✅ Account deletion completed: $accountId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      return false;
    }
  }

  /// Get account balance summary using RPC function
  static Future<Map<String, double>> getAccountBalanceSummary() async {
    try {
      final response = await _client.rpc('get_account_balance_summary');
      
      return {
        'totalAssets': (response[0]['total_assets'] as num?)?.toDouble() ?? 0.0,
        'totalDebts': (response[0]['total_debts'] as num?)?.toDouble() ?? 0.0,
        'netWorth': (response[0]['net_worth'] as num?)?.toDouble() ?? 0.0,
        'availableCredit': (response[0]['available_credit'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error fetching balance summary: $e');
      return {
        'totalAssets': 0.0,
        'totalDebts': 0.0,
        'netWorth': 0.0,
        'availableCredit': 0.0,
      };
    }
  }

  /// Get credit cards only
  static Future<List<AccountModel>> getCreditCards() async {
    return getAccountsByType(AccountType.credit);
  }

  /// Get debit cards only
  static Future<List<AccountModel>> getDebitCards() async {
    return getAccountsByType(AccountType.debit);
  }

  /// Get cash accounts only
  static Future<List<AccountModel>> getCashAccounts() async {
    return getAccountsByType(AccountType.cash);
  }

  /// Check if account has sufficient balance for transaction
  static Future<bool> checkSufficientBalance({
    required String accountId,
    required double amount,
  }) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) return false;

      if (account.type == AccountType.credit) {
        // For credit cards, check available credit
        return account.availableAmount >= amount;
      } else {
        // For debit/cash, check actual balance
        return account.balance >= amount;
      }
    } catch (e) {
      debugPrint('Error checking balance: $e');
      return false;
    }
  }

  /// Get accounts suitable for a specific transaction type
  static Future<List<AccountModel>> getAccountsForTransactionType(TransactionType type) async {
    try {
      final accounts = await getAllAccounts();
      
      switch (type) {
        case TransactionType.income:
          // Income can go to any account
          return accounts;
        case TransactionType.expense:
          // Expenses can come from any account
          return accounts;
        case TransactionType.transfer:
          // Transfers can use any account
          return accounts;
      }
    } catch (e) {
      debugPrint('Error fetching accounts for transaction type: $e');
      return [];
    }
  }
} 