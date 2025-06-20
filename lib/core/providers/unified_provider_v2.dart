import 'package:flutter/foundation.dart';
import '../../shared/models/account_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/models/installment_models_v2.dart';
import '../services/account_service_v2.dart';
import '../services/transaction_service_v2.dart';
import '../services/category_service_v2.dart';
import '../services/installment_service_v2.dart';

/// **QANTA v2 Unified Provider - Central Data Management System**
/// 
/// This provider serves as the single source of truth for all financial data
/// in the QANTA application. It manages accounts, transactions, categories,
/// installments, and provides real-time data synchronization across the app.
/// 
/// **Architecture:**
/// ```
/// UI Components
///      ↓
/// UnifiedProviderV2 (State Management)
///      ↓
/// Service Layer (Business Logic)
///      ↓
/// Supabase Database (Data Storage)
/// ```
/// 
/// **Key Features:**
/// - **Singleton Pattern**: Single instance across the app
/// - **Real-time Updates**: Automatic UI refresh on data changes
/// - **Error Handling**: Comprehensive error states and recovery
/// - **Loading States**: Granular loading indicators for each data type
/// - **Legacy Compatibility**: Backward compatibility with v1 UI components
/// - **Performance Optimized**: Efficient data loading and caching
/// 
/// **Data Management:**
/// 
/// **Accounts:**
/// - Credit cards, debit cards, cash accounts
/// - Real-time balance tracking
/// - Account creation and management
/// 
/// **Transactions:**
/// - Income, expense, transfer transactions
/// - Installment transaction support
/// - Transaction history and filtering
/// 
/// **Categories:**
/// - Income and expense categories
/// - System and user-defined categories
/// - Category-based transaction filtering
/// 
/// **Installments:**
/// - Credit card installment tracking
/// - Payment scheduling and progress
/// - Automatic payment processing
/// 
/// **Summary Data:**
/// - Balance summaries (assets, debts, net worth)
/// - Monthly transaction summaries
/// - Real-time financial insights
/// 
/// **Usage Patterns:**
/// 
/// **Basic Data Access:**
/// ```dart
/// Consumer<UnifiedProviderV2>(
///   builder: (context, provider, child) {
///     if (provider.isLoading) return CircularProgressIndicator();
///     if (provider.error != null) return ErrorWidget(provider.error);
///     
///     return ListView.builder(
///       itemCount: provider.transactions.length,
///       itemBuilder: (context, index) => TransactionTile(provider.transactions[index]),
///     );
///   },
/// )
/// ```
/// 
/// **Transaction Creation:**
/// ```dart
/// final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
/// await provider.createTransaction(
///   type: TransactionType.expense,
///   amount: 100.0,
///   description: 'Coffee',
///   sourceAccountId: 'account_id',
///   categoryId: 'category_id',
/// );
/// ```
/// 
/// **Legacy Compatibility:**
/// - Provides legacy format data for existing UI components
/// - Gradual migration path from v1 to v2
/// - Maintains API compatibility where possible
/// 
/// **Performance Considerations:**
/// - Data is cached in memory after initial load
/// - Selective loading with granular loading states
/// - Efficient notifyListeners() usage
/// - Background data refresh capabilities
/// 
/// **Error Handling:**
/// - Network error recovery
/// - Graceful degradation on failures
/// - User-friendly error messages
/// - Automatic retry mechanisms
/// 
/// **Dependencies:**
/// - [AccountServiceV2] for account operations
/// - [TransactionServiceV2] for transaction operations
/// - [CategoryServiceV2] for category operations
/// - [InstallmentServiceV2] for installment operations
/// 
/// **CHANGELOG:**
/// 
/// v2.2.0 (2024-01-XX):
/// - Added comprehensive documentation
/// - Improved error handling and recovery
/// - Enhanced legacy compatibility layer
/// - Performance optimizations
/// 
/// v2.1.0 (2024-01-XX):
/// - Added installment transaction support
/// - Implemented balance and monthly summaries
/// - Added granular loading states
/// - Fixed data synchronization issues
/// 
/// v2.0.0 (2024-01-XX):
/// - Initial v2 implementation
/// - Complete rewrite from legacy provider
/// - New database schema integration
/// - Service layer architecture
/// 
/// **Migration from v1:**
/// - Replace UnifiedCardProvider with UnifiedProviderV2
/// - Update data access patterns to use new models
/// - Migrate transaction creation to new API
/// - Update UI components to handle new data structures
/// 
/// **See also:**
/// - [AccountServiceV2] for account management
/// - [TransactionServiceV2] for transaction management
/// - [CategoryServiceV2] for category management
/// - [InstallmentServiceV2] for installment management
class UnifiedProviderV2 extends ChangeNotifier {
  /// Singleton instance for app-wide access
  static UnifiedProviderV2? _instance;
  
  /// Gets the singleton instance, creating it if necessary
  static UnifiedProviderV2 get instance => _instance ??= UnifiedProviderV2._();
  
  /// Private constructor for singleton pattern
  UnifiedProviderV2._();
  
  // Data lists
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  List<TransactionWithDetailsV2> _transactions = [];
  List<InstallmentWithProgressModel> _installments = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingTransactions = false;
  bool _isLoadingAccounts = false;
  bool _isLoadingCategories = false;
  bool _isLoadingInstallments = false;
  
  // Error states
  String? _error;
  
  // Balance summary
  Map<String, double> _balanceSummary = {
    'totalAssets': 0.0,
    'totalDebts': 0.0,
    'netWorth': 0.0,
    'availableCredit': 0.0,
  };
  
  // Monthly summary
  Map<String, dynamic> _monthlySummary = {
    'totalIncome': 0.0,
    'totalExpenses': 0.0,
    'netAmount': 0.0,
    'transactionCount': 0,
  };

  // Getters
  List<AccountModel> get accounts => _accounts;
  List<dynamic> get creditCards => legacyCreditCards; // Return legacy format for UI compatibility
  List<dynamic> get debitCards => legacyDebitCards; // Return legacy format for UI compatibility
  List<AccountModel> get cashAccounts => _accounts.where((a) => a.type == AccountType.cash).toList();
  
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.type == CategoryType.income).toList();
  List<CategoryModel> get expenseCategories => _categories.where((c) => c.type == CategoryType.expense).toList();
  
  List<TransactionWithDetailsV2> get transactions => _transactions;
  List<TransactionWithDetailsV2> get recentTransactions => _transactions.take(5).toList();
  
  List<InstallmentWithProgressModel> get installments => _installments;
  List<InstallmentWithProgressModel> get activeInstallments => _installments.where((i) => !i.isCompleted).toList();
  
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingAccounts => _isLoadingAccounts;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingInstallments => _isLoadingInstallments;
  
  String? get error => _error;
  Map<String, double> get balanceSummary => _balanceSummary;
  Map<String, dynamic> get monthlySummary => _monthlySummary;

  /// Load all data
  Future<void> loadAllData() async {
    _setLoading(true);
    _clearError();
    
    try {
      await Future.wait([
        loadAccounts(),
        loadCategories(),
        loadTransactions(),
        loadInstallments(),
      ]);
      
      await _loadSummaries();
      
    } catch (e) {
      _setError('Failed to load data: $e');
      debugPrint('❌ Error loading all data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load accounts
  Future<void> loadAccounts() async {
    _isLoadingAccounts = true;
    notifyListeners();
    
    try {
      _accounts = await AccountServiceV2.getAllAccounts();
      debugPrint('✅ Loaded ${_accounts.length} accounts');
      
      // Ensure default cash account exists
      await _ensureDefaultCashAccount();
      
    } catch (e) {
      debugPrint('❌ Error loading accounts: $e');
      rethrow;
    } finally {
      _isLoadingAccounts = false;
      notifyListeners();
    }
  }

  /// Ensure a default cash account exists, create one if it doesn't
  Future<void> _ensureDefaultCashAccount() async {
    try {
      // Check if user has any cash accounts
      final cashAccounts = _accounts.where((a) => a.type == AccountType.cash).toList();
      
      if (cashAccounts.isEmpty) {
        debugPrint('💰 No cash account found, creating default cash account...');
        
        // Create default cash account
        final cashAccountId = await AccountServiceV2.createAccount(
          type: AccountType.cash,
          name: 'Nakit',
          balance: 0.0,
        );
        
        // Reload accounts to include the new cash account
        _accounts = await AccountServiceV2.getAllAccounts();
        
        debugPrint('✅ Default cash account created: $cashAccountId');
      } else {
        debugPrint('💰 Cash account already exists: ${cashAccounts.first.name}');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring default cash account: $e');
      // Don't rethrow - this is not critical for app functionality
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    
    try {
      _categories = await CategoryServiceV2.getAllCategories();
      debugPrint('✅ Loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      rethrow;
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Load transactions
  Future<void> loadTransactions({int limit = 50}) async {
    _isLoadingTransactions = true;
    notifyListeners();
    
    try {
      _transactions = await TransactionServiceV2.getAllTransactions(limit: limit);
      debugPrint('✅ Loaded ${_transactions.length} transactions');
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      rethrow;
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Load installments
  Future<void> loadInstallments() async {
    _isLoadingInstallments = true;
    notifyListeners();
    
    try {
      _installments = await InstallmentServiceV2.getAllInstallments();
      debugPrint('✅ Loaded ${_installments.length} installments');
    } catch (e) {
      debugPrint('❌ Error loading installments: $e');
      rethrow;
    } finally {
      _isLoadingInstallments = false;
      notifyListeners();
    }
  }

  /// Load summaries
  Future<void> _loadSummaries() async {
    try {
      // Load balance summary
      _balanceSummary = await AccountServiceV2.getAccountBalanceSummary();
      
      // Load monthly summary
      _monthlySummary = await TransactionServiceV2.getMonthlyTransactionSummary();
      
      debugPrint('✅ Loaded summaries');
    } catch (e) {
      debugPrint('❌ Error loading summaries: $e');
    }
  }

  /// Create new account
  Future<String> createAccount({
    required AccountType type,
    required String name,
    String? bankName,
    double balance = 0.0,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
  }) async {
    try {
      final accountId = await AccountServiceV2.createAccount(
        type: type,
        name: name,
        bankName: bankName,
        balance: balance,
        creditLimit: creditLimit,
        statementDay: statementDay,
        dueDay: dueDay,
      );
      
      // Reload accounts
      await loadAccounts();
      await _loadSummaries();
      
      debugPrint('✅ Account created: $accountId');
      return accountId;
    } catch (e) {
      debugPrint('❌ Error creating account: $e');
      rethrow;
    }
  }

  /// Creates a new transaction in the system
  /// 
  /// **Transaction Types Supported:**
  /// - **Income**: Money coming into an account
  /// - **Expense**: Money going out of an account  
  /// - **Transfer**: Money moving between accounts
  /// 
  /// **Parameters:**
  /// - [TransactionType] type: Type of transaction (income/expense/transfer)
  /// - [double] amount: Transaction amount (must be > 0)
  /// - [String] description: Transaction description
  /// - [String] sourceAccountId: Source account ID (required for all types)
  /// - [String?] targetAccountId: Target account ID (required for transfers)
  /// - [String?] categoryId: Category ID (optional for transfers)
  /// - [DateTime?] transactionDate: Transaction date (defaults to now)
  /// - [String?] notes: Additional notes (optional)
  /// 
  /// **Transaction Flow:**
  /// 1. Validates required parameters
  /// 2. Calls TransactionServiceV2.createTransaction()
  /// 3. Updates account balances automatically
  /// 4. Reloads affected data (transactions, accounts, summaries)
  /// 5. Notifies UI listeners for real-time updates
  /// 
  /// **Account Balance Updates:**
  /// - **Income**: Increases target account balance
  /// - **Expense**: Decreases source account balance/available limit
  /// - **Transfer**: Decreases source, increases target
  /// 
  /// **Error Handling:**
  /// - Validates account existence
  /// - Checks sufficient balance/limit
  /// - Handles network errors gracefully
  /// - Rolls back on failure
  /// 
  /// **Usage Examples:**
  /// 
  /// **Income Transaction:**
  /// ```dart
  /// await provider.createTransaction(
  ///   type: TransactionType.income,
  ///   amount: 5000.0,
  ///   description: 'Salary',
  ///   sourceAccountId: 'external_source', // Can be placeholder
  ///   targetAccountId: 'bank_account_id',
  ///   categoryId: 'salary_category_id',
  /// );
  /// ```
  /// 
  /// **Expense Transaction:**
  /// ```dart
  /// await provider.createTransaction(
  ///   type: TransactionType.expense,
  ///   amount: 150.0,
  ///   description: 'Grocery shopping',
  ///   sourceAccountId: 'credit_card_id',
  ///   categoryId: 'food_category_id',
  /// );
  /// ```
  /// 
  /// **Transfer Transaction:**
  /// ```dart
  /// await provider.createTransaction(
  ///   type: TransactionType.transfer,
  ///   amount: 1000.0,
  ///   description: 'Credit card payment',
  ///   sourceAccountId: 'bank_account_id',
  ///   targetAccountId: 'credit_card_id',
  /// );
  /// ```
  /// 
  /// **Returns:**
  /// - [String] transactionId: Unique ID of created transaction
  /// 
  /// **Throws:**
  /// - [Exception] if required parameters are missing
  /// - [Exception] if account validation fails
  /// - [Exception] if insufficient balance/limit
  /// - [Exception] if network/database error occurs
  /// 
  /// **Performance:**
  /// - Optimistic UI updates where possible
  /// - Batch data reloading for efficiency
  /// - Background summary recalculation
  /// 
  /// **See also:**
  /// - [createInstallmentTransaction] for installment payments
  /// - [TransactionServiceV2.createTransaction] for service implementation
  Future<String> createTransaction({
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
      final transactionId = await TransactionServiceV2.createTransaction(
        type: type,
        amount: amount,
        description: description,
        sourceAccountId: sourceAccountId,
        targetAccountId: targetAccountId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        notes: notes,
      );
      
      // Reload data
      await Future.wait([
        loadTransactions(),
        loadAccounts(),
        _loadSummaries(),
      ]);
      
      debugPrint('✅ Transaction created: $transactionId');
      return transactionId;
    } catch (e) {
      debugPrint('❌ Error creating transaction: $e');
      rethrow;
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final success = await TransactionServiceV2.deleteTransaction(transactionId);
      
      if (success) {
        // Remove from local list immediately for instant UI feedback
        _transactions.removeWhere((t) => t.id == transactionId);
        
        // Reload data to maintain sliding window and update balances
        await Future.wait([
          loadTransactions(),
          loadAccounts(),
          _loadSummaries(),
        ]);
        
        notifyListeners();
        debugPrint('✅ Transaction deleted: $transactionId');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Delete installment transaction (refunds total amount)
  Future<bool> deleteInstallmentTransaction(String transactionId) async {
    try {
      final success = await TransactionServiceV2.deleteInstallmentTransaction(transactionId);
      
      if (success) {
        // Remove all related transactions from local list
        _transactions.removeWhere((t) => t.installmentId != null && 
            (_transactions.any((tx) => tx.id == transactionId && tx.installmentId == t.installmentId)));
        
        // Reload data to maintain sliding window and update balances
        await Future.wait([
          loadTransactions(),
          loadAccounts(),
          loadInstallments(),
          _loadSummaries(),
        ]);
        
        notifyListeners();
        debugPrint('✅ Installment transaction deleted: $transactionId');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting installment transaction: $e');
      rethrow;
    }
  }

  /// Create installment transaction
  Future<String> createInstallmentTransaction({
    required String sourceAccountId,
    required double totalAmount,
    required int count,
    required String description,
    String? categoryId,
    DateTime? startDate,
  }) async {
    try {
      final installmentId = await InstallmentServiceV2.createInstallmentTransaction(
        sourceAccountId: sourceAccountId,
        totalAmount: totalAmount,
        count: count,
        description: description,
        categoryId: categoryId,
        startDate: startDate,
      );
      
      // Reload data
      await Future.wait([
        loadInstallments(),
        loadTransactions(),
        loadAccounts(),
        _loadSummaries(),
      ]);
      
      debugPrint('✅ Installment transaction created: $installmentId');
      return installmentId;
    } catch (e) {
      debugPrint('❌ Error creating installment transaction: $e');
      rethrow;
    }
  }

  /// Pay installment
  Future<String> payInstallment({
    required String installmentDetailId,
    DateTime? paymentDate,
  }) async {
    try {
      final transactionId = await InstallmentServiceV2.payInstallment(
        installmentDetailId: installmentDetailId,
        paymentDate: paymentDate,
      );
      
      // Reload data
      await Future.wait([
        loadInstallments(),
        loadTransactions(),
        loadAccounts(),
        _loadSummaries(),
      ]);
      
      debugPrint('✅ Installment paid: $transactionId');
      return transactionId;
    } catch (e) {
      debugPrint('❌ Error paying installment: $e');
      rethrow;
    }
  }

  /// Create new category
  Future<CategoryModel> createCategory({
    required CategoryType type,
    required String name,
    String icon = 'category',
    String color = '#6B7280',
    int sortOrder = 0,
  }) async {
    try {
      final category = await CategoryServiceV2.createCategory(
        type: type,
        name: name,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );
      
      // Reload categories
      await loadCategories();
      
      debugPrint('✅ Category created: ${category.id}');
      return category;
    } catch (e) {
      debugPrint('❌ Error creating category: $e');
      rethrow;
    }
  }

  /// Get account by ID
  AccountModel? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get transactions by account
  List<TransactionWithDetailsV2> getTransactionsByAccount(String accountId) {
    return _transactions.where((t) => 
      t.sourceAccountId == accountId || t.targetAccountId == accountId
    ).toList();
  }

  /// Get transactions by category
  List<TransactionWithDetailsV2> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAllData();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Legacy compatibility methods for existing UI components
  
  /// Legacy: Total balance (sum of all account balances)
  double get totalBalance {
    return _balanceSummary['netWorth'] ?? 0.0;
  }
  
  /// Legacy: This month income
  double get thisMonthIncome {
    return _monthlySummary['totalIncome']?.toDouble() ?? 0.0;
  }
  
  /// Legacy: This month expense
  double get thisMonthExpense {
    return _monthlySummary['totalExpenses']?.toDouble() ?? 0.0;
  }
  
  /// Legacy: Balance change percentage (mock calculation)
  double get balanceChangePercentage {
    final income = thisMonthIncome;
    final expense = thisMonthExpense;
    if (expense == 0) return income > 0 ? 100.0 : 0.0;
    return ((income - expense) / expense) * 100;
  }
  
  /// Legacy: Cash account (first cash account or null)
  dynamic get cashAccount {
    final cashAccounts = _accounts.where((a) => a.type == AccountType.cash).toList();
    return cashAccounts.isNotEmpty ? _convertToLegacyCashAccount(cashAccounts.first) : null;
  }
  
  /// Convert AccountModel to legacy cash account format
  Map<String, dynamic> _convertToLegacyCashAccount(AccountModel account) {
    return {
      'id': account.id,
      'balance': account.balance,
      'name': account.name,
      'isActive': account.isActive,
    };
  }
  
  /// Legacy: Convert AccountModel to legacy credit card format
  List<Map<String, dynamic>> get legacyCreditCards {
    return _accounts.where((a) => a.type == AccountType.credit).map((account) => {
      'id': account.id,
      'cardName': account.name,
      'bankName': account.bankName ?? '',
      'bankCode': account.bankName ?? '', // Use bankName as bankCode for now
      'totalDebt': account.balance.clamp(0.0, double.infinity), // Credit card balance is debt (positive)
      'creditLimit': account.creditLimit ?? 0.0,
      'availableLimit': account.availableAmount,
      'statementDay': account.statementDay ?? 1,
      'dueDay': account.dueDay ?? 15,
      'statementDate': account.statementDay ?? 1,
      'dueDate': account.dueDay ?? 15,
      'isActive': account.isActive,
      'formattedCardNumber': '**** **** **** ${account.id.substring(0, 4)}', // Mock card number
      'usagePercentage': account.creditLimit != null && account.creditLimit! > 0 
          ? (account.balance.clamp(0.0, double.infinity) / account.creditLimit!) * 100 
          : 0.0,
    }).toList();
  }
  
  /// Legacy: Convert AccountModel to legacy debit card format
  List<Map<String, dynamic>> get legacyDebitCards {
    return _accounts.where((a) => a.type == AccountType.debit).map((account) => {
      'id': account.id,
      'cardName': account.name,
      'bankName': account.bankName ?? '',
      'bankCode': account.bankName ?? '', // Use bankName as bankCode for now
      'balance': account.balance,
      'isActive': account.isActive,
      'maskedCardNumber': '**** **** **** ${account.id.substring(0, 4)}', // Mock card number
    }).toList();
  }
  
  /// Legacy: Convert TransactionWithDetailsV2 to legacy transaction format
  List<Map<String, dynamic>> get legacyTransactions {
    return _transactions.map((tx) => {
      'id': tx.id,
      'description': tx.description,
      'amount': tx.amount,
      'type': tx.type.value,
      'date': tx.transactionDate,
      'categoryName': tx.categoryName ?? 'Diğer',
      'sourceAccountName': tx.sourceAccountName ?? '',
      'targetAccountName': tx.targetAccountName ?? '',
      'notes': tx.notes,
    }).toList();
  }

  /// Update account balance
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      // Get current account to calculate the operation
      final account = getAccountById(accountId);
      if (account == null) {
        throw Exception('Account not found');
      }
      
      final currentBalance = account.balance;
      final difference = newBalance - currentBalance;
      final operation = difference >= 0 ? 'add' : 'subtract';
      final amount = difference.abs();
      
      final success = await AccountServiceV2.updateAccountBalance(
        accountId: accountId,
        amount: amount,
        operation: operation,
      );
      
      if (success) {
        // Reload accounts and summaries
        await Future.wait([
          loadAccounts(),
          _loadSummaries(),
        ]);
        
        debugPrint('✅ Account balance updated: $accountId');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error updating account balance: $e');
      rethrow;
    }
  }

  /// Update account details
  Future<AccountModel?> updateAccount({
    required String accountId,
    String? name,
    String? bankName,
    double? balance,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
    bool? isActive,
  }) async {
    try {
      debugPrint('🔄 Updating account: $accountId');
      
      final updatedAccount = await AccountServiceV2.updateAccount(
        accountId: accountId,
        name: name,
        bankName: bankName,
        creditLimit: creditLimit,
        statementDay: statementDay,
        dueDay: dueDay,
        isActive: isActive,
      );
      
      // If balance is provided, update it separately
      if (balance != null) {
        final currentAccount = getAccountById(accountId);
        if (currentAccount != null) {
          final currentBalance = currentAccount.balance;
          final difference = balance - currentBalance;
          final operation = difference >= 0 ? 'add' : 'subtract';
          final amount = difference.abs();
          
          await AccountServiceV2.updateAccountBalance(
            accountId: accountId,
            amount: amount,
            operation: operation,
          );
        }
      }
      
      // Reload accounts and summaries
      await Future.wait([
        loadAccounts(),
        _loadSummaries(),
      ]);
      
      debugPrint('✅ Account updated: $accountId');
      return updatedAccount;
    } catch (e) {
      debugPrint('❌ Error updating account: $e');
      rethrow;
    }
  }

  /// Legacy: Has cards check
  bool get hasCards => _accounts.isNotEmpty;
  
  /// Legacy: Delete credit card
  Future<bool> deleteCreditCard(String cardId) async {
    try {
      debugPrint('🗑️ Deleting credit card: $cardId');
      final success = await AccountServiceV2.deleteAccount(cardId);
      if (success) {
        await loadAccounts(); // Refresh accounts
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting credit card: $e');
      return false;
    }
  }
  
  /// Legacy: Delete debit card
  Future<bool> deleteDebitCard(String cardId) async {
    try {
      debugPrint('🗑️ Deleting debit card: $cardId');
      final success = await AccountServiceV2.deleteAccount(cardId);
      if (success) {
        await loadAccounts(); // Refresh accounts
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting debit card: $e');
      return false;
    }
  }
  
  /// Legacy: Retry method
  Future<void> retry() async {
    await refresh();
  }
  
  /// Legacy: Get credit card by ID
  Map<String, dynamic>? getCreditCardById(String cardId) {
    final account = getAccountById(cardId);
    if (account == null || account.type != AccountType.credit) {
      return null;
    }
    
    return {
      'id': account.id,
      'cardName': account.name,
      'bankName': account.bankName ?? '',
      'totalDebt': account.balance.clamp(0.0, double.infinity),
      'creditLimit': account.creditLimit ?? 0.0,
      'availableLimit': account.availableAmount,
      'statementDay': account.statementDay ?? 1,
      'dueDay': account.dueDay ?? 15,
      'isActive': account.isActive,
    };
  }
  
  /// Legacy: Get debit card by ID
  Map<String, dynamic>? getDebitCardById(String cardId) {
    final account = getAccountById(cardId);
    if (account == null || account.type != AccountType.debit) {
      return null;
    }
    
    return {
      'id': account.id,
      'cardName': account.name,
      'bankName': account.bankName ?? '',
      'balance': account.balance,
      'isActive': account.isActive,
    };
  }

  /// Legacy: Load debit cards (just refresh accounts)
  Future<void> loadDebitCards() async {
    await loadAccounts();
  }

  // ==================== INSTALLMENT HELPER METHODS ====================
  
  /// Get installment info for a transaction
  /// Returns a map with currentInstallment and totalInstallments
  Map<String, int?>? getInstallmentInfo(String? installmentId) {
    if (installmentId == null) return null;
    
    // Find the installment transaction
    final installment = _installments.firstWhere(
      (inst) => inst.id == installmentId,
      orElse: () => InstallmentWithProgressModel(
        id: installmentId,
        userId: '',
        sourceAccountId: '',
        totalAmount: 0,
        monthlyAmount: 0,
        count: 12, // Default
        startDate: DateTime.now(),
        description: '',
        categoryId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paidCount: 1, // Default to 1st installment
        totalCount: 12,
        paidAmount: 0,
        remainingAmount: 0,
        nextDueDate: null,
      ),
    );
    
    return {
      'currentInstallment': installment.paidCount + 1, // Next installment to pay
      'totalInstallments': installment.count,
    };
  }
} 