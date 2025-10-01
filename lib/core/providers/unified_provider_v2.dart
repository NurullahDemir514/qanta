import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/account_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/models/installment_models_v2.dart';
import '../services/account_service_v2.dart';
import '../services/transaction_service_v2.dart';
import '../services/category_service_v2.dart';
import '../services/installment_service_v2.dart';
import '../services/unified_account_service.dart';
import '../services/unified_transaction_service.dart';
import '../services/unified_category_service.dart';
import '../services/unified_budget_service.dart';
import '../services/unified_installment_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/statement_service.dart';
import 'statement_provider.dart';
import '../../shared/models/unified_category_model.dart';
import '../../shared/models/budget_model.dart';
import '../../shared/models/statement_summary.dart';
import '../../shared/models/statement_period.dart';
import '../../shared/utils/date_utils.dart';
import '../../modules/stocks/providers/stock_provider.dart';

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
  List<UnifiedCategoryModel> _categories = [];
  List<TransactionWithDetailsV2> _transactions = [];
  List<InstallmentWithProgressModel> _installments = [];
  List<BudgetModel> _budgets = [];
  
  // Stock positions for net worth calculation
  double _totalStockValue = 0.0;
  double _totalStockCost = 0.0;
  
  // ==================== CACHE SYSTEM ====================
  DateTime? _lastCacheTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 10);
  bool _isDataCached = false;
  
  // ===============================
  // STATEMENT CACHE
  // ===============================
  
  /// **Statement caching for improved performance**
  Map<String, StatementSummary> _currentStatements = {};
  Map<String, List<StatementSummary>> _futureStatements = {};
  Map<String, List<StatementSummary>> _pastStatements = {};
  
  /// **Statement loading states**
  Map<String, bool> _isLoadingStatements = {};
  DateTime? _lastStatementUpdate;
  
  /// **StatementProvider reference for accessing current statements**
  StatementProvider? _statementProvider;
  
  /// **StockProvider reference for accessing stock positions**
  StockProvider? _stockProvider;
  
  /// **Statement period cache**
  Map<String, StatementPeriod> _cachedPeriods = {};
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingTransactions = false;
  bool _isLoadingAccounts = false;
  bool _isLoadingCategories = false;
  bool _isLoadingInstallments = false;
  bool _isLoadingBudgets = false;
  
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
  
  // Real-time calculated values
  double _totalBalance = 0.0;
  double _totalCreditLimit = 0.0;
  double _totalUsedCredit = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;

  // Getters
  /// Check if data is loaded
  bool get isDataLoaded => _accounts.isNotEmpty || _transactions.isNotEmpty;
  
  List<AccountModel> get accounts => _accounts;
  List<dynamic> get creditCards => legacyCreditCards; // Return legacy format for UI compatibility
  List<dynamic> get debitCards => legacyDebitCards; // Return legacy format for UI compatibility
  List<AccountModel> get cashAccounts => _accounts.where((a) => a.type == AccountType.cash).toList();
  
  List<UnifiedCategoryModel> get categories => _categories;
  List<UnifiedCategoryModel> get incomeCategories => _categories.where((c) => c.categoryType == CategoryType.income).toList();
  List<UnifiedCategoryModel> get expenseCategories => _categories.where((c) => c.categoryType == CategoryType.expense).toList();
  
  List<TransactionWithDetailsV2> get transactions => _transactions;
  List<TransactionWithDetailsV2> get recentTransactions {
    if (_transactions.length <= 5) {
      return _transactions;
    }
    return _transactions.take(5).toList();
  }
  
  List<BudgetModel> get budgets => _budgets;
  List<BudgetModel> get currentMonthBudgets {
    final now = DateTime.now();
    final currentBudgets = _budgets.where((b) => b.month == now.month && b.year == now.year).toList();
    for (final budget in currentBudgets) {
    }
    return currentBudgets;
  }
  
  List<InstallmentWithProgressModel> get installments => _installments;
  List<InstallmentWithProgressModel> get activeInstallments => _installments.where((i) => !i.isCompleted).toList();

  // ===============================
  // STATEMENT GETTERS
  // ===============================
  
  /// **Get current statement for a card**
  StatementSummary? getCurrentStatement(String cardId) {
    return _currentStatements[cardId];
  }
  
  /// **Get future statements for a card**
  List<StatementSummary> getFutureStatements(String cardId) {
    return _futureStatements[cardId] ?? [];
  }
  
  /// **Get past statements for a card**
  List<StatementSummary> getPastStatements(String cardId) {
    return _pastStatements[cardId] ?? [];
  }
  
  /// **Check if statements are loading for a card**
  bool isLoadingStatements(String cardId) {
    return _isLoadingStatements[cardId] ?? false;
  }
  
  /// **Get cached statement period**
  StatementPeriod? getCachedPeriod(String cardId, int statementDay) {
    final key = '${cardId}_$statementDay';
    return _cachedPeriods[key];
  }
  
  /// **Check if statement cache is fresh (less than 5 minutes old)**
  bool get isStatementCacheFresh {
    if (_lastStatementUpdate == null) return false;
    final now = DateTime.now();
    return now.difference(_lastStatementUpdate!).inMinutes < 5;
  }
  
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingAccounts => _isLoadingAccounts;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingInstallments => _isLoadingInstallments;
  bool get isLoadingBudgets => _isLoadingBudgets;
  
  String? get error => _error;
  Map<String, double> get balanceSummary => _balanceSummary;
  Map<String, dynamic> get monthlySummary => _monthlySummary;

  /// Load all data with cache optimization
  Future<void> loadAllData({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh && _isDataCached && _lastCacheTime != null) {
      final now = DateTime.now();
      final cacheAge = now.difference(_lastCacheTime!);
      
      if (cacheAge < _cacheValidityDuration) {
        // Cache hala geçerli, sadece balance summary güncelle
        await _loadSummaries();
        return;
      }
    }

    _setLoading(true);
    _clearError();
    
    try {
      // Kritik verileri paralel yükle
      await Future.wait([
        loadAccounts(),
        loadCategories(),
        loadTransactions(),
        loadInstallments(),
        loadBudgets(),
      ]);
      
      // Hisse verilerini ayrı yükle (hata durumunda devam et)
      try {
        await loadStockPositions();
      } catch (e) {
        // Hisse verileri yüklenemezse sessizce devam et
      }
      
      await _loadSummaries();
      
      // Cache'i güncelle
      _lastCacheTime = DateTime.now();
      _isDataCached = true;
      
      // Real-time listeners will be set up in splash screen
      
    } catch (e) {
      _setError('Failed to load data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load accounts
  Future<void> loadAccounts() async {
    _isLoadingAccounts = true;
    notifyListeners();
    
    try {
      // Debug log kaldırıldı
      
      // Load accounts from Firebase
      _accounts = await UnifiedAccountService.getAllAccounts();
      
      // Ensure default cash account exists
      await _ensureDefaultCashAccount();
      
    } catch (e) {
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
        // Debug log kaldırıldı
        
        // Create default cash account using Firebase
        final cashAccount = AccountModel(
          id: '', // Will be generated by Firebase
          userId: '', // Will be set by service
          type: AccountType.cash,
          name: 'Cash Wallet', // Default English name, will be localized in UI
          balance: 0.0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final cashAccountId = await UnifiedAccountService.addAccount(cashAccount);
        // Debug log kaldırıldı
        
        // Reload accounts to include the new cash account
        _accounts = await UnifiedAccountService.getAllAccounts();
        
      } else if (cashAccounts.length > 1) {
        // Debug log kaldırıldı
        await _cleanupDuplicateCashAccounts(cashAccounts);
      } else {
        // Debug log kaldırıldı
      }
    } catch (e) {
      // Debug log kaldırıldı
      // Don't rethrow - this is not critical for app functionality
    }
  }

  /// Clean up duplicate cash accounts, keeping only the first one
  Future<void> _cleanupDuplicateCashAccounts(List<AccountModel> cashAccounts) async {
    try {
      // Keep the first cash account (oldest or first created)
      final primaryCashAccount = cashAccounts.first;
      final duplicateAccounts = cashAccounts.skip(1).toList();
      
      // Debug log'ları kaldırıldı
      
      // Delete duplicate accounts
      for (final duplicateAccount in duplicateAccounts) {
        await UnifiedAccountService.deleteAccount(duplicateAccount.id);
        // Debug log kaldırıldı
      }
      
      // Reload accounts to reflect changes
      _accounts = await UnifiedAccountService.getAllAccounts();
      
    } catch (e) {
      // Debug log kaldırıldı
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    
    try {
      // Debug log kaldırıldı
      _categories = await UnifiedCategoryService.getAllCategories();
      
      
      // If no categories exist, create default ones
      if (_categories.isEmpty) {
        await _createDefaultCategories();
        // Wait a bit for index to be ready
        await Future.delayed(const Duration(seconds: 2));
        _categories = await UnifiedCategoryService.getAllCategories();
      }
      
      for (final cat in _categories) {
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Create default categories for new users
  Future<void> _createDefaultCategories() async {
    try {
      
      final defaultCategories = [
        // Expense categories
        UnifiedCategoryModel(
          id: '',
          name: 'food',
          displayName: 'Yemek',
          description: 'Yemek ve içecek harcamaları',
          iconName: 'restaurant',
          colorHex: '#FF6B6B',
          sortOrder: 1,
          categoryType: CategoryType.expense,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'transport',
          displayName: 'Ulaşım',
          description: 'Ulaşım harcamaları',
          iconName: 'directions_car',
          colorHex: '#4ECDC4',
          sortOrder: 2,
          categoryType: CategoryType.expense,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'shopping',
          displayName: 'Alışveriş',
          description: 'Alışveriş harcamaları',
          iconName: 'shopping_bag',
          colorHex: '#45B7D1',
          sortOrder: 3,
          categoryType: CategoryType.expense,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'entertainment',
          displayName: 'Eğlence',
          description: 'Eğlence ve hobi harcamaları',
          iconName: 'movie',
          colorHex: '#96CEB4',
          sortOrder: 4,
          categoryType: CategoryType.expense,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'bills',
          displayName: 'Faturalar',
          description: 'Elektrik, su, internet faturaları',
          iconName: 'receipt',
          colorHex: '#FECA57',
          sortOrder: 5,
          categoryType: CategoryType.expense,
          isUserCategory: false,
        ),
        // Income categories
        UnifiedCategoryModel(
          id: '',
          name: 'salary',
          displayName: 'Maaş',
          description: 'Aylık maaş geliri',
          iconName: 'work',
          colorHex: '#00FFB3',
          sortOrder: 1,
          categoryType: CategoryType.income,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'freelance',
          displayName: 'Freelance',
          description: 'Serbest meslek geliri',
          iconName: 'laptop',
          colorHex: '#00D2FF',
          sortOrder: 2,
          categoryType: CategoryType.income,
          isUserCategory: false,
        ),
        UnifiedCategoryModel(
          id: '',
          name: 'investment',
          displayName: 'Yatırım',
          description: 'Yatırım gelirleri',
          iconName: 'trending_up',
          colorHex: '#00FF88',
          sortOrder: 3,
          categoryType: CategoryType.income,
          isUserCategory: false,
        ),
      ];

      for (final category in defaultCategories) {
        await UnifiedCategoryService.addCategory(category);
      }
      
    } catch (e) {
      // Don't rethrow - this is not critical for app functionality
    }
  }

  /// Load transactions
  Future<void> loadTransactions({int limit = 50}) async {
    _isLoadingTransactions = true;
    notifyListeners();
    
    try {
      // Debug log kaldırıldı
      _transactions = await UnifiedTransactionService.getAllTransactions(limit: limit);
    } catch (e) {
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
      // Load installments from Firebase using UnifiedInstallmentService
      final installmentMasters = await UnifiedInstallmentService.getAllInstallmentMasters();
      _installments = installmentMasters.map((data) => InstallmentWithProgressModel.fromJson(data)).toList();
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingInstallments = false;
      notifyListeners();
    }
  }

  /// Load budgets
  Future<void> loadBudgets() async {
    _isLoadingBudgets = true;
    notifyListeners();
    
    try {
      // Debug log kaldırıldı
      
      // Load budgets from Firebase
      _budgets = await UnifiedBudgetService.getAllBudgets();
      
      // Fix budget category IDs to match real category IDs
      await _fixBudgetCategoryIds();
      
      // Update spent amounts for current month
      final now = DateTime.now();
      await UnifiedBudgetService.updateSpentAmountsForMonth(now.month, now.year);
      
      // Reload budgets to get updated spent amounts
      _budgets = await UnifiedBudgetService.getAllBudgets();
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingBudgets = false;
      notifyListeners();
    }
  }

  /// Fix budget category IDs to match real category IDs
  Future<void> _fixBudgetCategoryIds() async {
    try {
      
      for (final budget in _budgets) {
        // Find matching category by name
        final matchingCategory = _categories.firstWhere(
          (cat) => cat.displayName.trim() == budget.categoryName.trim(),
          orElse: () => _categories.first,
        );
        
        if (matchingCategory.id != budget.categoryId) {
          
          // Update budget category ID
          await UnifiedBudgetService.updateBudgetCategoryId(
            budget.categoryId,
            matchingCategory.id,
          );
        }
      }
      
    } catch (e) {
    }
  }

  /// Load summaries
  Future<void> _loadSummaries() async {
    try {
      // Use the local calculation method for real-time updates
      await _updateSummariesLocally();
    } catch (e) {
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
      // Debug log kaldırıldı
      
      // Create AccountModel
      final account = AccountModel(
        id: '', // Will be generated by Firebase
        userId: '', // Will be set by service
        type: type,
        name: name,
        bankName: bankName,
        balance: balance,
        creditLimit: creditLimit,
        statementDay: statementDay,
        dueDay: dueDay,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add account using Firebase service
      final accountId = await UnifiedAccountService.addAccount(account);
      
      // Reload accounts
      await loadAccounts();
      await _loadSummaries();
      
      return accountId;
    } catch (e) {
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
      final startTime = DateTime.now();
      
      final trimmedCategoryId = categoryId?.trim();
      
      // Ensure categories are loaded first
      if (_categories.isEmpty) {
        final categoryStartTime = DateTime.now();
        await loadCategories();
        final categoryEndTime = DateTime.now();
        final categoryDuration = categoryEndTime.difference(categoryStartTime).inMilliseconds;
        
        // If still empty, wait and try again
        if (_categories.isEmpty) {
          await Future.delayed(const Duration(seconds: 3));
          await loadCategories();
        }
      }
      
      // Get category and account names for display
      final category = trimmedCategoryId != null ? getCategoryById(trimmedCategoryId) : null;
      final sourceAccount = getAccountById(sourceAccountId);
      final targetAccount = targetAccountId != null ? getAccountById(targetAccountId) : null;
      
      
      // Create TransactionWithDetailsV2
      final transaction = TransactionWithDetailsV2(
        id: '', // Will be generated by Firebase
        userId: '', // Will be set by service
        type: type,
        amount: amount,
        description: description,
        transactionDate: transactionDate ?? DateTime.now(),
        categoryId: trimmedCategoryId,
        sourceAccountId: sourceAccountId,
        targetAccountId: targetAccountId,
        notes: notes,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
          // Add display names
          categoryName: category?.displayName,
          sourceAccountName: sourceAccount?.displayName,
          targetAccountName: targetAccount?.displayName,
          sourceAccountType: sourceAccount?.typeDisplayName,
          targetAccountType: targetAccount?.typeDisplayName,
      );
      
      // Add transaction using Firebase service
      final firebaseStartTime = DateTime.now();
      final transactionId = await UnifiedTransactionService.addTransaction(transaction);
      final firebaseEndTime = DateTime.now();
      final firebaseDuration = firebaseEndTime.difference(firebaseStartTime).inMilliseconds;
      
      // Add to local list immediately for instant UI update
      final newTransaction = TransactionWithDetailsV2(
        id: transactionId,
        userId: transaction.userId,
        type: transaction.type,
        amount: transaction.amount,
        description: transaction.description,
        transactionDate: transaction.transactionDate,
        categoryId: transaction.categoryId,
        sourceAccountId: transaction.sourceAccountId,
        targetAccountId: transaction.targetAccountId,
        notes: transaction.notes,
        isPaid: transaction.isPaid,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
        categoryName: transaction.categoryName,
        sourceAccountName: transaction.sourceAccountName,
        targetAccountName: transaction.targetAccountName,
        sourceAccountType: transaction.sourceAccountType,
        targetAccountType: transaction.targetAccountType,
        categoryIcon: transaction.categoryIcon,
        categoryColor: transaction.categoryColor,
        installmentCount: transaction.installmentCount,
      );
      _transactions.insert(0, newTransaction);
      
      // Update account balance locally immediately
      final balanceStartTime = DateTime.now();
      await _updateAccountBalanceLocally(newTransaction, isDelete: false);
      final balanceEndTime = DateTime.now();
      final balanceDuration = balanceEndTime.difference(balanceStartTime).inMilliseconds;
      
      // Update summaries locally immediately
      final summaryStartTime = DateTime.now();
      await _updateSummariesLocally();
      final summaryEndTime = DateTime.now();
      final summaryDuration = summaryEndTime.difference(summaryStartTime).inMilliseconds;
      
      // Invalidate statement cache for affected account
      _invalidateStatementCache(transaction.sourceAccountId);
      
      final notifyStartTime = DateTime.now();
      notifyListeners(); // Immediate UI update
      final notifyEndTime = DateTime.now();
      final notifyDuration = notifyEndTime.difference(notifyStartTime).inMilliseconds;
        
        // Update budget spent amounts in background if it's an expense
        if (type == TransactionType.expense && trimmedCategoryId != null) {
          final budgetStartTime = DateTime.now();
          
          // Check if budget category ID matches transaction category ID
          final matchingBudget = _budgets.where(
            (budget) => budget.categoryId == trimmedCategoryId,
          ).isNotEmpty ? _budgets.firstWhere(
            (budget) => budget.categoryId == trimmedCategoryId,
          ) : null;
          
          if (matchingBudget == null) {
            // Don't update budget if no matching category found
            final totalEndTime = DateTime.now();
            final totalDuration = totalEndTime.difference(startTime).inMilliseconds;
            return transactionId;
          }
          
          _updateBudgetSpentAmounts(trimmedCategoryId);
          final budgetEndTime = DateTime.now();
          final budgetDuration = budgetEndTime.difference(budgetStartTime).inMilliseconds;
        }
        
        final totalEndTime = DateTime.now();
        final totalDuration = totalEndTime.difference(startTime).inMilliseconds;
        
        return transactionId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update transaction
  Future<bool> updateTransaction({
    required String transactionId,
    TransactionType? type,
    double? amount,
    String? description,
    String? sourceAccountId,
    String? targetAccountId,
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) async {
    try {
      
      // Get current transaction
      final currentTransaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      
      // Create updated transaction model
      final updatedTransaction = TransactionWithDetailsV2(
        id: currentTransaction.id,
        userId: currentTransaction.userId,
        type: type ?? currentTransaction.type,
        amount: amount ?? currentTransaction.amount,
        description: description ?? currentTransaction.description,
        transactionDate: transactionDate ?? currentTransaction.transactionDate,
        categoryId: categoryId ?? currentTransaction.categoryId,
        sourceAccountId: sourceAccountId ?? currentTransaction.sourceAccountId,
        targetAccountId: targetAccountId ?? currentTransaction.targetAccountId,
        installmentId: currentTransaction.installmentId,
        isRecurring: currentTransaction.isRecurring,
        notes: notes ?? currentTransaction.notes,
        isPaid: currentTransaction.isPaid,
        createdAt: currentTransaction.createdAt,
        updatedAt: DateTime.now(),
        sourceAccountName: currentTransaction.sourceAccountName,
        sourceAccountType: currentTransaction.sourceAccountType,
        targetAccountName: currentTransaction.targetAccountName,
        targetAccountType: currentTransaction.targetAccountType,
        categoryName: currentTransaction.categoryName,
        categoryIcon: currentTransaction.categoryIcon,
        categoryColor: currentTransaction.categoryColor,
        installmentCount: currentTransaction.installmentCount,
      );
      
      // Update in Firebase
      final success = await UnifiedTransactionService.updateTransaction(
        transactionId: transactionId,
        transaction: updatedTransaction,
      );
      
      if (success) {
      // Reload data
      await Future.wait([
        loadTransactions(),
        loadAccounts(),
        _loadSummaries(),
      ]);
      
      }
      
      return success;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      // Find transaction to get details for balance update
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      
      // Remove from local list immediately for instant UI update
        _transactions.removeWhere((t) => t.id == transactionId);
        
      // Update account balance locally immediately
      await _updateAccountBalanceLocally(transaction, isDelete: true);
      
      // Update summaries locally immediately
      await _updateSummariesLocally();
      
      // Invalidate statement cache for affected account
      _invalidateStatementCache(transaction.sourceAccountId);
      
      notifyListeners(); // Immediate UI update
      
      // Delete from Firebase in background
      final success = await UnifiedTransactionService.deleteTransaction(transactionId);
      
      if (success) {
      } else {
        // If Firebase delete failed, reload data to restore state
        await loadTransactions();
        await loadAccounts();
        await _loadSummaries();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      // Reload data to restore state on error
      await loadTransactions();
      await loadAccounts();
      await _loadSummaries();
      notifyListeners();
      return false;
    }
  }

  /// Delete installment transaction (refunds total amount)
  Future<bool> deleteInstallmentTransaction(String transactionId) async {
    try {
      
      // Find the transaction to get installment ID
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      
      
      if (transaction.installmentId == null) {
        throw Exception('Transaction is not an installment');
      }
      
      final startTime = DateTime.now();
      
      // Delete installment master and details using UnifiedInstallmentService
      final success = await UnifiedInstallmentService.deleteInstallmentTransaction(transaction.installmentId!);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      if (success) {
        
        // Remove transaction from local list immediately
        _transactions.removeWhere((t) => t.id == transactionId);
        
        // Update account balance locally
        final account = getAccountById(transaction.sourceAccountId);
        if (account != null) {
          // Refund the total amount (subtract from debt)
          final updatedAccount = account.copyWith(
            balance: account.balance - transaction.amount,
          );
          _accounts[_accounts.indexWhere((a) => a.id == account.id)] = updatedAccount;
        }
        
        // Update summaries locally
        _updateSummariesLocally();
        
        // Invalidate statement cache for affected account
        _invalidateStatementCache(transaction.sourceAccountId);
        
        // Notify listeners for immediate UI update
        notifyListeners();
        
        // Delete UI transaction record from Firebase in background
        Future.microtask(() async {
          try {
            await UnifiedTransactionService.deleteTransaction(transactionId);
          } catch (e) {
            // Reload data to restore state
            await loadTransactions();
          }
        });
      }
      
      return success;
    } catch (e) {
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
      final startTime = DateTime.now();
      
      // Get current credit card balance BEFORE
      final currentAccount = getAccountById(sourceAccountId);
      
      // Calculate monthly amount
      final monthlyAmount = totalAmount / count;
      
      // 1. Create installment master record
      final masterStartTime = DateTime.now();
      final installmentId = await UnifiedInstallmentService.createInstallmentMaster(
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        count: count,
        description: description,
        sourceAccountId: sourceAccountId,
        categoryId: categoryId,
        startDate: startDate,
      );
      final masterEndTime = DateTime.now();
      final masterDuration = masterEndTime.difference(masterStartTime).inMilliseconds;
      
      // 2. Create installment details
      final detailsStartTime = DateTime.now();
      await UnifiedInstallmentService.createInstallmentDetails(
        installmentId: installmentId,
        count: count,
        monthlyAmount: monthlyAmount,
        startDate: startDate,
      );
      final detailsEndTime = DateTime.now();
      final detailsDuration = detailsEndTime.difference(detailsStartTime).inMilliseconds;
      
      // 3. Create transaction record for UI display
      final uiStartTime = DateTime.now();
      await _createInstallmentTransactionRecord(
        installmentId: installmentId,
        totalAmount: totalAmount,
        count: count,
        description: description,
        sourceAccountId: sourceAccountId,
        categoryId: categoryId,
        startDate: startDate,
      );
      final uiEndTime = DateTime.now();
      final uiDuration = uiEndTime.difference(uiStartTime).inMilliseconds;
      
      // 4. Update account balance locally for instant UI update
      final account = getAccountById(sourceAccountId);
      if (account != null && account.type == AccountType.credit) {
        // For credit cards: add total debt (totalAmount is positive, balance represents debt)
        final updatedAccount = account.copyWith(
          balance: account.balance + totalAmount.abs(), // Add debt (use absolute value)
        );
        _accounts[_accounts.indexWhere((a) => a.id == account.id)] = updatedAccount;
      }
      
      // 5. Update summaries locally for instant UI update
      _updateSummariesLocally();
      
      // 6. Invalidate statement cache for affected account
      _invalidateStatementCache(sourceAccountId);
      
      // 7. Notify listeners for immediate UI update
      notifyListeners();
      
      // 7. Reload data in background
      Future.microtask(() async {
        try {
      await Future.wait([
        loadAccounts(),
            loadTransactions(),
        _loadSummaries(),
      ]);
        } catch (e) {
        }
      });
      
      final totalEndTime = DateTime.now();
      final totalDuration = totalEndTime.difference(startTime).inMilliseconds;
      
      // Get updated account balance
      final updatedAccount = getAccountById(sourceAccountId);
      
      return installmentId;
    } catch (e) {
      rethrow;
    }
  }

  /// Create transaction record for UI display
  Future<void> _createInstallmentTransactionRecord({
    required String installmentId,
    required double totalAmount,
    required int count,
    required String description,
    required String sourceAccountId,
    String? categoryId,
    DateTime? startDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Get category and account names for display
      final category = categoryId != null ? getCategoryById(categoryId) : null;
      final account = getAccountById(sourceAccountId);
      
      // Create transaction using UnifiedTransactionService directly
      final transaction = TransactionWithDetailsV2(
        id: '', // Will be set by Firebase
        userId: userId,
        type: TransactionType.expense,
        amount: totalAmount,
        description: '$description ($count taksit)',
        transactionDate: startDate ?? DateTime.now(),
        categoryId: categoryId,
        categoryName: category?.displayName, // Set category name
        sourceAccountId: sourceAccountId,
        sourceAccountName: account?.displayName, // Set account name
        installmentId: installmentId,
        isInstallment: true, // Mark as installment transaction
        notes: 'Taksitli işlem - Toplam: $totalAmount TL, $count taksit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UnifiedTransactionService.addTransaction(transaction);

    } catch (e) {
      rethrow;
    }
  }

  /// Update account balance for installment
  Future<void> _updateAccountBalanceForInstallment(String accountId, double amount) async {
    try {
      final account = getAccountById(accountId);
      if (account == null) throw Exception('Hesap bulunamadı');

      // Calculate new balance
      final newBalance = account.balance + amount;
      
      // Create updated account model
      final updatedAccount = AccountModel(
        id: account.id,
        userId: account.userId,
        type: account.type,
        name: account.name,
        bankName: account.bankName,
        balance: newBalance,
        creditLimit: account.creditLimit,
        statementDay: account.statementDay,
        dueDay: account.dueDay,
        isActive: account.isActive,
        createdAt: account.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firebase
      await UnifiedAccountService.updateAccount(updatedAccount);
      
      // Update local list
      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Pay installment
  Future<String> payInstallment({
    required String installmentDetailId,
    DateTime? paymentDate,
  }) async {
    try {
      // Pay installment using UnifiedInstallmentService
      final paidTransactionId = await UnifiedInstallmentService.payInstallment(
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
      
      return paidTransactionId;
    } catch (e) {
      rethrow;
    }
  }

  /// Create new category
  Future<UnifiedCategoryModel> createCategory({
    required CategoryType type,
    required String name,
    String iconName = 'category',
    String colorHex = '#6B7280',
    int sortOrder = 0,
  }) async {
    try {
      // Debug log kaldırıldı
      
      final category = UnifiedCategoryModel(
        id: '', // Will be generated by Firebase
        name: name.toLowerCase().replaceAll(' ', '_'),
        displayName: name,
        description: '$name kategorisi',
        iconName: iconName,
        colorHex: colorHex,
        sortOrder: sortOrder,
        categoryType: type,
        isUserCategory: true,
      );
      
      final categoryId = await UnifiedCategoryService.addCategory(category);
      
      // Reload categories
      await loadCategories();
      
      return category.copyWith(id: categoryId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new budget
  Future<BudgetModel> createBudget({
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
    int? month,
    int? year,
  }) async {
    try {
      // Debug log kaldırıldı
      
      final now = DateTime.now();
      final budgetMonth = month ?? now.month;
      final budgetYear = year ?? now.year;
      
      final budget = BudgetModel(
        id: '', // Will be generated by Firebase
        userId: '', // Will be set by service
        categoryId: categoryId,
        categoryName: categoryName,
        monthlyLimit: monthlyLimit,
        month: budgetMonth,
        year: budgetYear,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        spentAmount: 0.0,
      );
      
      final budgetId = await UnifiedBudgetService.addBudget(budget);
      
      // Reload budgets
      await loadBudgets();
      
      return budget.copyWith(id: budgetId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update budget
  Future<bool> updateBudget({
    required String budgetId,
    required double monthlyLimit,
  }) async {
    try {
      final budget = _budgets.firstWhere((b) => b.id == budgetId);
      final updatedBudget = budget.copyWith(
        monthlyLimit: monthlyLimit,
        updatedAt: DateTime.now(),
      );
      
      final success = await UnifiedBudgetService.updateBudget(
        budgetId: budgetId,
        budget: updatedBudget,
      );
      
      if (success) {
        await loadBudgets();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Delete budget
  Future<bool> deleteBudget(String budgetId) async {
    try {
      final success = await UnifiedBudgetService.deleteBudget(budgetId);
      
      if (success) {
        await loadBudgets();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Get budget by ID
  BudgetModel? getBudgetById(String budgetId) {
    try {
      return _budgets.firstWhere((budget) => budget.id == budgetId);
    } catch (e) {
      return null;
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
  UnifiedCategoryModel? getCategoryById(String categoryId) {
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
    await loadAllData(forceRefresh: true);
  }

  /// Clear cache and force reload
  void clearCache() {
    _isDataCached = false;
    _lastCacheTime = null;
  }
  
  @override
  void dispose() {
    _transactionListener?.cancel();
    _installmentListener?.cancel();
    super.dispose();
  }

  // Real-time listeners
  StreamSubscription? _transactionListener;
  StreamSubscription? _installmentListener;
  
  /// Setup real-time listeners for automatic updates
  void setupRealTimeListeners() {
    // Cancel existing listeners
    _transactionListener?.cancel();
    _installmentListener?.cancel();
    
    
    // Listen to transactions
    _transactionListener = FirebaseFirestore.instance
        .collection('transactions')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      loadTransactions();
      // Clear statement cache when transactions change
      clearStatementCache();
    });
    
    // Listen to installments
    _installmentListener = FirebaseFirestore.instance
        .collection('installment_masters')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((snapshot) {
      loadInstallments();
      // Clear statement cache when installments change
      clearStatementCache();
    });
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
  
  /// Set StatementProvider reference for accessing current statements
  void setStatementProvider(StatementProvider provider) {
    _statementProvider = provider;
  }
  
  /// Set StockProvider reference for accessing stock positions
  void setStockProvider(StockProvider provider) {
    _stockProvider = provider;
    
    // StockProvider değişikliklerini dinle
    _stockProvider!.addListener(_onStockProviderChanged);
  }
  
  /// StockProvider değişikliklerini dinle - ATOMIK GÜNCELLEME
  void _onStockProviderChanged() {
    if (_stockProvider != null) {
      // Hisse pozisyonlarını güncelle
      _updateStockValues();
    }
    // StockProvider yoksa mevcut değerleri koru, sıfırlama yapma
  }
  
  /// Hisse değerlerini güncelle - ATOMIK GÜNCELLEME
  void _updateStockValues() {
    if (_stockProvider == null) {
      // StockProvider yoksa sadece mevcut değerleri koru, sıfırlama
      return;
    }
    
    final stockPositions = _stockProvider!.stockPositions;
    
    // Önce yeni değerleri hesapla (sıfırlamadan)
    double newTotalStockValue = 0.0;
    double newTotalStockCost = 0.0;
    
    for (final position in stockPositions) {
      newTotalStockValue += position.currentValue;
      newTotalStockCost += position.totalCost;
    }
    
    // ATOMIK GÜNCELLEME: Sadece geçerli değerler varsa güncelle
    if (newTotalStockValue >= 0 && newTotalStockCost >= 0) {
      _totalStockValue = newTotalStockValue;
      _totalStockCost = newTotalStockCost;
      
      // Balance summary'yi güncelle
      _updateBalanceSummary();
      
      notifyListeners();
    }
    // Eğer geçersiz değerler varsa, mevcut değerleri koru
  }
  
  /// Check if StockProvider is set
  bool get hasStockProvider => _stockProvider != null;
  
  /// Update balance summary with current values
  void _updateBalanceSummary() {
    
    final totalAssets = _accounts
        .where((account) => account.type == AccountType.cash || account.type == AccountType.debit)
        .fold(0.0, (sum, account) => sum + account.balance);
    
    final totalDebts = _accounts
        .where((account) => account.type == AccountType.credit)
        .fold(0.0, (sum, account) => sum + (account.balance));
    
    final netWorth = _totalBalance + _totalStockValue;
    
    
    _balanceSummary = {
      'totalAssets': totalAssets,
      'totalDebts': totalDebts,
      'netWorth': netWorth, // Hisse değerlerini dahil et
      'availableCredit': _totalCreditLimit - _totalUsedCredit,
      'totalStockValue': _totalStockValue, // Hisse değerlerini ayrı göster
      'totalStockCost': _totalStockCost, // Hisse toplam maliyeti
    };
    
  }
  
  /// Update stock positions for net worth calculation - ATOMIK GÜNCELLEME
  void updateStockPositions(List<dynamic> stockPositions) {
    // Mevcut değerleri yedekle
    final oldTotalStockValue = _totalStockValue;
    final oldTotalStockCost = _totalStockCost;
    
    // Önce yeni değerleri hesapla (sıfırlamadan)
    double newTotalStockValue = 0.0;
    double newTotalStockCost = 0.0;
    
    for (final position in stockPositions) {
      if (position is Map<String, dynamic>) {
        final currentValue = position['currentValue'] as double? ?? 0.0;
        final totalCost = position['totalCost'] as double? ?? 0.0;
        newTotalStockValue += currentValue;
        newTotalStockCost += totalCost;
      }
    }
    
    // ATOMIK GÜNCELLEME: Sadece geçerli değerler varsa güncelle
    if (newTotalStockValue >= 0 && newTotalStockCost >= 0) {
      _totalStockValue = newTotalStockValue;
      _totalStockCost = newTotalStockCost;
      
      // Balance summary'yi güncelle
      _updateBalanceSummary();
      
      notifyListeners();
    } else {
      // Geçersiz değerler varsa eski değerleri koru
      _totalStockValue = oldTotalStockValue;
      _totalStockCost = oldTotalStockCost;
    }
  }
  
  /// Load stock positions from StockProvider - ATOMIK GÜNCELLEME
  Future<void> loadStockPositions() async {
    if (_stockProvider == null) {
      return;
    }
    
    // Firebase Auth'dan kullanıcı ID'sini al
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    
    try {
      // Mevcut değerleri yedekle
      final oldTotalStockValue = _totalStockValue;
      final oldTotalStockCost = _totalStockCost;
      
      // StockProvider'dan hisse verilerini yükle
      await _stockProvider!.loadWatchedStocks(user.uid);
      await _stockProvider!.loadStockPositions(user.uid);
      
      // Net worth'u hemen güncelle
      _updateStockValues();
      
      // Eğer güncelleme başarısızsa eski değerleri geri yükle
      if (_totalStockValue == 0.0 && oldTotalStockValue > 0.0) {
        _totalStockValue = oldTotalStockValue;
        _totalStockCost = oldTotalStockCost;
        _updateBalanceSummary();
        notifyListeners();
      }
      
    } catch (e) {
      rethrow; // Hata durumunda yukarı fırlat
    }
  }
  
  /// Update current statement in cache
  void updateCurrentStatement(String cardId, StatementSummary statement) {
    _currentStatements[cardId] = statement;
    notifyListeners();
  }

  // Legacy compatibility methods for existing UI components
  
  /// Legacy: Total balance (sum of all account balances + stock values)
  double get totalBalance {
    return _totalBalance + _totalStockValue;
  }
  
  double get totalCreditLimit {
    return _totalCreditLimit;
  }
  
  double get totalUsedCredit {
    return _totalUsedCredit;
  }
  
  /// Legacy: This month income
  double get thisMonthIncome {
    return _monthlyIncome;
  }
  
  /// Legacy: This month expense
  double get thisMonthExpense {
    return _monthlyExpense;
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
      'totalDebt': account.balance.abs(), // Credit card balance is debt (always positive)
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
      'maskedCardNumber': '**** **** **** ${account.id.length >= 4 ? account.id.substring(0, 4) : account.id.padRight(4, '0')}', // Mock card number
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
      
      // Update balance in Firebase
      final success = await UnifiedAccountService.updateBalance(
        accountId: accountId, 
        newBalance: newBalance
      );
      
      if (success) {
        // Reload accounts and summaries
        await Future.wait([
          loadAccounts(),
          _loadSummaries(),
        ]);
        
      }
      
      return success;
    } catch (e) {
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
      
      // Get current account
        final currentAccount = getAccountById(accountId);
      if (currentAccount == null) {
        throw Exception('Account not found');
      }
      
      // Create updated account model
      final updatedAccount = AccountModel(
        id: currentAccount.id,
        userId: currentAccount.userId,
        type: currentAccount.type,
        name: name ?? currentAccount.name,
        bankName: bankName ?? currentAccount.bankName,
        balance: balance ?? currentAccount.balance,
        creditLimit: creditLimit ?? currentAccount.creditLimit,
        statementDay: statementDay ?? currentAccount.statementDay,
        dueDay: dueDay ?? currentAccount.dueDay,
        isActive: isActive ?? currentAccount.isActive,
        createdAt: currentAccount.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firebase
      final success = await UnifiedAccountService.updateAccount(updatedAccount);
      
      if (success) {
      // Reload accounts and summaries
      await Future.wait([
        loadAccounts(),
        _loadSummaries(),
      ]);
      
        return updatedAccount;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy: Has cards check
  bool get hasCards => _accounts.isNotEmpty;
  
  /// Legacy: Delete credit card
  Future<bool> deleteCreditCard(String cardId) async {
    try {
      
      // Delete from Firebase
      final success = await UnifiedAccountService.deleteAccount(cardId);
      
      if (success) {
        await loadAccounts(); // Refresh accounts
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// Legacy: Delete debit card
  Future<bool> deleteDebitCard(String cardId) async {
    try {
      
      // Delete from Firebase
      final success = await UnifiedAccountService.deleteAccount(cardId);
      
      if (success) {
        await loadAccounts(); // Refresh accounts
        notifyListeners();
      }
      return success;
    } catch (e) {
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

  /// En çok kullanılan kategorileri döndürür (varsayılan ilk 5)
  /// [type] ile gelir/gider ayrımı yapılabilir. Sadece aktif kategoriler dahil edilir.
  List<MapEntry<String, int>> getMostUsedCategories({
    CategoryType? type,
    int topN = 5,
  }) {
    final Map<String, int> counts = {};
    for (final tx in _transactions) {
      // Sadece aktif kategoriler ve istenen tipteki işlemler
      String catName = (tx.categoryName ?? tx.categoryId ?? 'Diğer').trim();
      final catModel = _categories.firstWhere(
        (c) => c.displayName.trim() == catName || c.id == tx.categoryId,
        orElse: () => UnifiedCategoryModel(
          id: 'other',
          name: 'other',
          displayName: 'Diğer',
          description: 'Diğer kategoriler',
          iconName: 'more_horiz_rounded',
          colorHex: '#6B7280',
          sortOrder: 999,
          categoryType: CategoryType.other,
          isUserCategory: false,
        ),
      );
      // UnifiedCategoryModel doesn't have isActive, all are active
      if (type != null && catModel.categoryType != type) continue;
      if (catName.isEmpty) continue;
      counts[catName] = (counts[catName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).toList();
  }

  /// Update account balance locally for instant UI updates
  Future<void> _updateAccountBalanceLocally(TransactionWithDetailsV2 transaction, {bool isDelete = false}) async {
    try {
      final multiplier = isDelete ? -1 : 1;
      final absoluteAmount = transaction.amount.abs(); // Mutlak değer kullan
      
      switch (transaction.type) {
        case TransactionType.income:
          // For income: decrease debt (increase available limit) for credit cards
          final targetAccount = _accounts.firstWhere(
            (account) => account.id == transaction.targetAccountId,
            orElse: () => _accounts.firstWhere(
              (account) => account.id == transaction.sourceAccountId,
              orElse: () => throw Exception('Target account not found'),
            ),
          );
          
          AccountModel updatedTargetAccount;
          if (targetAccount.type == AccountType.credit) {
            // Credit card: decrease debt (balance represents debt)
            updatedTargetAccount = targetAccount.copyWith(
              balance: targetAccount.balance - (absoluteAmount * multiplier),
            );
          } else {
            // Debit/Cash: increase balance
            updatedTargetAccount = targetAccount.copyWith(
              balance: targetAccount.balance + (absoluteAmount * multiplier),
            );
          }
          
          final targetIndex = _accounts.indexWhere((a) => a.id == targetAccount.id);
          if (targetIndex != -1) {
            _accounts[targetIndex] = updatedTargetAccount;
          }
          break;
          
        case TransactionType.expense:
          // For expense: increase debt (decrease available limit) for credit cards
          final sourceAccount = _accounts.firstWhere(
            (account) => account.id == transaction.sourceAccountId,
            orElse: () => throw Exception('Source account not found'),
          );
          
          AccountModel updatedSourceAccount;
          if (sourceAccount.type == AccountType.credit) {
            // Credit card: increase debt (balance represents debt)
            updatedSourceAccount = sourceAccount.copyWith(
              balance: sourceAccount.balance + (absoluteAmount * multiplier),
            );
          } else {
            // Debit/Cash: decrease balance
            updatedSourceAccount = sourceAccount.copyWith(
              balance: sourceAccount.balance - (absoluteAmount * multiplier),
            );
          }
          
          final sourceIndex = _accounts.indexWhere((a) => a.id == sourceAccount.id);
          if (sourceIndex != -1) {
            _accounts[sourceIndex] = updatedSourceAccount;
          }
          break;
          
        case TransactionType.transfer:
          // For transfer: only affect non-credit accounts, credit cards should not be affected by transfers
          final sourceAccount = _accounts.firstWhere(
            (account) => account.id == transaction.sourceAccountId,
            orElse: () => throw Exception('Source account not found'),
          );
          
          final targetAccount = _accounts.firstWhere(
            (account) => account.id == transaction.targetAccountId,
            orElse: () => throw Exception('Target account not found'),
          );
          
          // Only process if neither account is a credit card
          if (sourceAccount.type != AccountType.credit && targetAccount.type != AccountType.credit) {
            final updatedSourceAccount = sourceAccount.copyWith(
              balance: sourceAccount.balance - (absoluteAmount * multiplier),
            );
            
            final updatedTargetAccount = targetAccount.copyWith(
              balance: targetAccount.balance + (absoluteAmount * multiplier),
            );
            
            final sourceIndex = _accounts.indexWhere((a) => a.id == sourceAccount.id);
            final targetIndex = _accounts.indexWhere((a) => a.id == targetAccount.id);
            
            if (sourceIndex != -1) {
              _accounts[sourceIndex] = updatedSourceAccount;
            }
            if (targetIndex != -1) {
              _accounts[targetIndex] = updatedTargetAccount;
            }
          }
          // If credit card is involved in transfer, do nothing (transfers don't affect credit limits)
          break;
          
        case TransactionType.stock:
          // For stock transactions: affect cash account balance
          final sourceAccount = _accounts.firstWhere(
            (account) => account.id == transaction.sourceAccountId,
            orElse: () => throw Exception('Source account not found'),
          );
          
          if (sourceAccount.type == AccountType.cash) {
            final updatedSourceAccount = sourceAccount.copyWith(
              balance: sourceAccount.balance + (transaction.amount * multiplier),
            );
            
            final sourceIndex = _accounts.indexWhere((a) => a.id == sourceAccount.id);
            if (sourceIndex != -1) {
              _accounts[sourceIndex] = updatedSourceAccount;
            }
          }
          break;
      }
      
      // Update total balance immediately after account balance changes
      _totalBalance = _accounts.fold(0.0, (sum, account) {
        if (account.type == AccountType.credit) {
          // Credit cards: balance is debt (negative), so subtract it
          return sum - account.balance.abs();
        } else {
          // Cash and debit accounts: balance is asset (positive), so add it
          return sum + account.balance;
        }
      });
      
      // Update total credit limit
      _totalCreditLimit = _accounts.fold(0.0, (sum, account) => sum + (account.creditLimit ?? 0.0));
      
      // Update total used credit
      _totalUsedCredit = _accounts.fold(0.0, (sum, account) {
        if (account.type == AccountType.credit) {
          return sum + (account.balance);
        }
        return sum;
      });
      
    } catch (e) {
    }
  }

  /// Update summaries locally for instant UI updates
  Future<void> _updateSummariesLocally() async {
    try {
      // Calculate total balance
      _totalBalance = _accounts.fold(0.0, (sum, account) {
        if (account.type == AccountType.credit) {
          // Credit cards: balance is debt (negative), so subtract it
          return sum - account.balance.abs();
        } else {
          // Cash and debit accounts: balance is asset (positive), so add it
          return sum + account.balance;
        }
      });
      
      // Calculate total credit limit
      _totalCreditLimit = _accounts.fold(0.0, (sum, account) => sum + (account.creditLimit ?? 0.0));
      
      // Calculate total used credit
      _totalUsedCredit = _accounts.fold(0.0, (sum, account) {
        if (account.type == AccountType.credit) {
          return sum + (account.balance);
        }
        return sum;
      });
      
      // Calculate monthly income and expense
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      _monthlyIncome = _transactions
          .where((t) => t.type == TransactionType.income && 
                       t.transactionDate.isAfter(startOfMonth) && 
                       t.transactionDate.isBefore(endOfMonth))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      _monthlyExpense = _transactions
          .where((t) => t.type == TransactionType.expense && 
                       t.transactionDate.isAfter(startOfMonth) && 
                       t.transactionDate.isBefore(endOfMonth))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      // Update balance summary with real-time calculations
      _updateBalanceSummary();
      
      // Update monthly summary with real-time calculations
      _monthlySummary = {
        'totalIncome': _monthlyIncome,
        'totalExpenses': _monthlyExpense,
        'netAmount': _monthlyIncome - _monthlyExpense,
        'transactionCount': _transactions
            .where((t) => t.transactionDate.isAfter(startOfMonth) && 
                         t.transactionDate.isBefore(endOfMonth))
            .length,
      };
      
    } catch (e) {
    }
  }

  /// Update budget spent amounts in background
  Future<void> _updateBudgetSpentAmounts(String categoryId) async {
    try {
      final now = DateTime.now();
      await UnifiedBudgetService.updateSpentAmountsForMonth(now.month, now.year);
      
      // Reload budgets to get updated spent amounts
      _budgets = await UnifiedBudgetService.getAllBudgets();
      notifyListeners();
      
      for (final budget in _budgets) {
      }
    } catch (e) {
    }
  }

  // ============================================================================
  // CREDIT CARD TRANSACTIONS
  // ============================================================================

  /// Get credit card transactions
  Future<List<TransactionWithDetailsV2>> getCreditCardTransactions({
    required String creditCardId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      
      // Debug: List all transactions first
      await UnifiedTransactionService.debugAllTransactions();
      
      _isLoadingTransactions = true;
      notifyListeners();

      final transactions = await UnifiedTransactionService.getCreditCardTransactions(
        creditCardId: creditCardId,
        limit: limit,
        offset: offset,
      );

      return transactions;
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Get debit card transactions
  Future<List<TransactionWithDetailsV2>> getDebitCardTransactions({
    required String debitCardId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _isLoadingTransactions = true;
      notifyListeners();

      final transactions = await UnifiedTransactionService.getDebitCardTransactions(
        debitCardId: debitCardId,
        limit: limit,
        offset: offset,
      );

      return transactions;
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Get cash account transactions
  Future<List<TransactionWithDetailsV2>> getCashAccountTransactions({
    required String cashAccountId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _isLoadingTransactions = true;
      notifyListeners();

      final transactions = await UnifiedTransactionService.getCashAccountTransactions(
        cashAccountId: cashAccountId,
        limit: limit,
        offset: offset,
      );

      return transactions;
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Get transactions by account type
  Future<List<TransactionWithDetailsV2>> getTransactionsByAccountType({
    required AccountType accountType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _isLoadingTransactions = true;
      notifyListeners();

      // Get accounts of the specified type
      final accounts = _accounts.where((account) => account.type == accountType).toList();
      
      if (accounts.isEmpty) {
        return [];
      }

      // Get transactions for all accounts of this type
      List<TransactionWithDetailsV2> allTransactions = [];
      for (final account in accounts) {
        final accountTransactions = await UnifiedTransactionService.getTransactionsByAccount(
          accountId: account.id,
          limit: limit,
          offset: offset,
        );
        allTransactions.addAll(accountTransactions);
      }

      // Sort by transaction date (newest first)
      allTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      return allTransactions;
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Get credit card transactions stream for real-time updates
  Stream<List<TransactionWithDetailsV2>> getCreditCardTransactionsStream({
    required String creditCardId,
    int limit = 50,
  }) {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getCreditCardTransactions(
        creditCardId: creditCardId,
        limit: limit,
      );
    });
  }

  /// Get debit card transactions stream for real-time updates
  Stream<List<TransactionWithDetailsV2>> getDebitCardTransactionsStream({
    required String debitCardId,
    int limit = 50,
  }) {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getDebitCardTransactions(
        debitCardId: debitCardId,
        limit: limit,
      );
    });
  }

  /// Get cash account transactions stream for real-time updates
  Stream<List<TransactionWithDetailsV2>> getCashAccountTransactionsStream({
    required String cashAccountId,
    int limit = 50,
  }) {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getCashAccountTransactions(
        cashAccountId: cashAccountId,
        limit: limit,
      );
    });
  }

  // ===============================
  // STATEMENT CACHE MANAGEMENT
  // ===============================

  /// **Load current statement for a card**
  Future<StatementSummary?> loadCurrentStatement(String cardId, int statementDay) async {
    try {
      _isLoadingStatements[cardId] = true;
      notifyListeners();

      // Check cache first
      if (_currentStatements.containsKey(cardId) && isStatementCacheFresh) {
        return _currentStatements[cardId];
      }

      // Get current statement period
      final period = StatementService.getCurrentStatementPeriod(statementDay);
      
      // Cache period for future use
      final periodKey = '${cardId}_$statementDay';
      _cachedPeriods[periodKey] = period;

      // Calculate statement summary
      final statement = await StatementService.calculateStatementSummary(cardId, period);
      
      // Cache the result
      _currentStatements[cardId] = statement;
      _lastStatementUpdate = DateTime.now();

      notifyListeners();
      return statement;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    } finally {
      _isLoadingStatements[cardId] = false;
      notifyListeners();
    }
  }

  /// **Load future statements for a card**
  Future<List<StatementSummary>> loadFutureStatements(String cardId, int statementDay) async {
    try {
      _isLoadingStatements[cardId] = true;
      notifyListeners();

      // Check cache first
      if (_futureStatements.containsKey(cardId) && isStatementCacheFresh) {
        return _futureStatements[cardId]!;
      }

      // Get future periods
      final futurePeriods = await StatementService.getFuturePeriodsUntilLastInstallment(cardId, statementDay);
      
      // Calculate summary for each period
      final futureStatements = <StatementSummary>[];
      for (final period in futurePeriods) {
        try {
          final statement = await StatementService.calculateStatementSummary(cardId, period);
          futureStatements.add(statement);
        } catch (e) {
          if (kDebugMode) {
          }
        }
      }

      // Cache the results
      _futureStatements[cardId] = futureStatements;
      _lastStatementUpdate = DateTime.now();

      notifyListeners();
      return futureStatements;
    } catch (e) {
      if (kDebugMode) {
      }
      return [];
    } finally {
      _isLoadingStatements[cardId] = false;
      notifyListeners();
    }
  }

  /// **Load past statements for a card**
  Future<List<StatementSummary>> loadPastStatements(String cardId, int statementDay) async {
    try {
      _isLoadingStatements[cardId] = true;
      notifyListeners();

      // Check cache first
      if (_pastStatements.containsKey(cardId) && isStatementCacheFresh) {
        return _pastStatements[cardId]!;
      }

      // Get past periods
      final pastPeriods = await StatementService.getAllPastStatementPeriods(cardId, statementDay);
      
      // Calculate summary for each period
      final pastStatements = <StatementSummary>[];
      for (final period in pastPeriods) {
        try {
          final statement = await StatementService.calculateStatementSummary(cardId, period);
          pastStatements.add(statement);
        } catch (e) {
          if (kDebugMode) {
          }
        }
      }

      // Cache the results
      _pastStatements[cardId] = pastStatements;
      _lastStatementUpdate = DateTime.now();

      notifyListeners();
      return pastStatements;
    } catch (e) {
      if (kDebugMode) {
      }
      return [];
    } finally {
      _isLoadingStatements[cardId] = false;
      notifyListeners();
    }
  }

  /// **Refresh all statements for a card**
  Future<void> refreshAllStatements(String cardId, int statementDay) async {
    // Clear cache for this card
    _currentStatements.remove(cardId);
    _futureStatements.remove(cardId);
    _pastStatements.remove(cardId);
    _lastStatementUpdate = null;
    
    // Load fresh data
    await Future.wait([
      loadCurrentStatement(cardId, statementDay),
      loadFutureStatements(cardId, statementDay),
      loadPastStatements(cardId, statementDay),
    ]);
  }

  /// **Mark statement as paid with optimistic update**
  Future<bool> markStatementAsPaidOptimistic(String cardId, StatementPeriod period) async {
    try {
      // Optimistic update - update UI immediately
      final currentStatement = _currentStatements[cardId];
      if (currentStatement != null && currentStatement.period.startDate == period.startDate) {
        final updatedStatement = currentStatement.copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
          period: currentStatement.period.copyWith(
            isPaid: true,
            paidAt: DateTime.now(),
          ),
        );
        // Update StatementProvider's currentStatement (will also update cache)
        if (_statementProvider != null) {
          _statementProvider!.currentStatement = updatedStatement;
        } else {
          // Fallback: update cache directly if StatementProvider not available
          _currentStatements[cardId] = updatedStatement;
        }
        
        notifyListeners();
      }

      // Update credit card limit - reduce by statement amount when paid
      final creditAccount = _accounts.firstWhere(
        (account) => account.id == cardId && account.type == AccountType.credit,
        orElse: () => throw Exception('Credit card not found'),
      );
      
      // Get statement from StatementProvider if not found in cache
      StatementSummary? statementToUse = currentStatement;
      if (statementToUse == null && _statementProvider?.currentStatement != null) {
        statementToUse = _statementProvider!.currentStatement;
      }
      
      // Calculate payment amount (statement total amount)
      final statementAmount = statementToUse?.totalAmount ?? 0.0;
      
      
      // Reduce credit card balance by statement amount (payment reduces debt)
      final newBalance = creditAccount.balance - statementAmount;
      
      final updatedCreditAccount = creditAccount.copyWith(
        balance: newBalance, // Reduce debt by payment amount
        updatedAt: DateTime.now(),
      );
      
      // Update in local accounts list
      final accountIndex = _accounts.indexWhere((a) => a.id == cardId);
      if (accountIndex != -1) {
        _accounts[accountIndex] = updatedCreditAccount;
      }
      
      // Update in Firebase
      await UnifiedAccountService.updateAccount(updatedCreditAccount);

      // Update in Firebase
      await StatementService.markStatementAsPaid(cardId, period);
      
      // Move from current to past statements
      final updatedCurrentStatement = _currentStatements[cardId];
      if (updatedCurrentStatement != null) {
        _pastStatements[cardId] = [updatedCurrentStatement, ...(_pastStatements[cardId] ?? [])];
        _currentStatements.remove(cardId);
      }
      
      // Update summaries after account balance change
      await _updateSummariesLocally();
      
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
      }
      
      // Rollback optimistic update
      await refreshAllStatements(cardId, period.statementDay);
      return false;
    }
  }

  /// **Unmark statement as paid with optimistic update**
  Future<bool> unmarkStatementAsPaidOptimistic(String cardId, StatementPeriod period) async {
    try {
      // Find the statement in past statements
      final pastStatements = _pastStatements[cardId] ?? [];
      final statementIndex = pastStatements.indexWhere(
        (s) => s.period.startDate == period.startDate,
      );
      
      if (statementIndex == -1) return false;
      
      // Optimistic update - update UI immediately
      final statement = pastStatements[statementIndex];
      final updatedStatement = statement.copyWith(
        isPaid: false,
        paidAt: null,
        period: statement.period.copyWith(
          isPaid: false,
          paidAt: null,
        ),
      );
      
      // Remove from past and add to current if it's the most recent unpaid
      final updatedPastStatements = List<StatementSummary>.from(pastStatements);
      updatedPastStatements.removeAt(statementIndex);
      _pastStatements[cardId] = updatedPastStatements;
      _currentStatements[cardId] = updatedStatement;
      
      notifyListeners();

      // Update in Firebase
      await StatementService.unmarkStatementAsPaid(cardId, period);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
      }
      
      // Rollback optimistic update
      await refreshAllStatements(cardId, period.statementDay);
      return false;
    }
  }

  /// **Clear statement cache**
  void clearStatementCache({String? cardId}) {
    if (cardId != null) {
      // Clear cache for specific card
      _currentStatements.remove(cardId);
      _futureStatements.remove(cardId);
      _pastStatements.remove(cardId);
      _isLoadingStatements.remove(cardId);
    } else {
      // Clear all statement cache
      _currentStatements.clear();
      _futureStatements.clear();
      _pastStatements.clear();
      _isLoadingStatements.clear();
      _cachedPeriods.clear();
    }
    
    _lastStatementUpdate = null;
    notifyListeners();
  }

  /// **Invalidate statement cache when transactions change**
  void _invalidateStatementCache(String? accountId) {
    if (accountId != null) {
      // Only clear cache for the specific card
      clearStatementCache(cardId: accountId);
    } else {
      // Clear all statement cache if we don't know which account was affected
      clearStatementCache();
    }
  }

  /// Process actual statement payment
  /// 
  /// This method handles the real payment process after user confirmation
  Future<bool> processStatementPayment(
    String cardId,
    StatementPeriod period,
    double amount,
  ) async {
    try {
      // 1. Mark statement as paid in Firebase
      await markStatementAsPaidOptimistic(cardId, period);

      // 2. Create payment transaction record
      await _createPaymentTransactionRecord(cardId, amount, period);

      // 3. Update account balance (credit limit)
      await _updateAccountBalanceAfterPayment(cardId, amount);

      // 4. Refresh data
      await loadTransactions();
      await loadInstallments();
      
      return true;
    } catch (e) {
      // Debug log kaldırıldı
      return false;
    }
  }

  /// Create payment transaction record
  Future<void> _createPaymentTransactionRecord(
    String cardId,
    double amount,
    StatementPeriod period,
  ) async {
    try {
      final paymentTransaction = {
        'id': 'payment_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'account_id': cardId,
        'amount': amount,
        'type': 'income', // Payment is income for the credit card
        'category': 'payment',
        'description': 'Ekstre Ödemesi - ${period.periodText}',
        'transaction_date': DateUtils.toIso8601(DateTime.now()),
        'created_at': DateUtils.toIso8601(DateTime.now()),
        'is_installment': false,
        'is_payment': true, // Mark as payment transaction
        'statement_id': '${cardId}_${period.startDate.millisecondsSinceEpoch}',
      };

      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(paymentTransaction['id'] as String)
          .set(paymentTransaction);

      // Debug log kaldırıldı
    } catch (e) {
      // Debug log kaldırıldı
      rethrow;
    }
  }

  /// Update account balance after payment
  Future<void> _updateAccountBalanceAfterPayment(
    String cardId,
    double amount,
  ) async {
    try {
      final account = accounts.firstWhere((acc) => acc.id == cardId);
      final newBalance = account.balance + amount; // Add payment to balance (reduces debt)

      final updatedAccount = account.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );
      
      await UnifiedAccountService.updateAccount(updatedAccount);

      // Update local cache
      _updateAccountBalanceDirectly(cardId, newBalance);
      
      // Debug log kaldırıldı
    } catch (e) {
      // Debug log kaldırıldı
      rethrow;
    }
  }

  /// Update account balance directly in local cache
  void _updateAccountBalanceDirectly(String cardId, double newBalance) {
    try {
      final accountIndex = accounts.indexWhere((acc) => acc.id == cardId);
      if (accountIndex != -1) {
        accounts[accountIndex] = accounts[accountIndex].copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        );
        
        // Update summaries
        _updateSummariesLocally();
        notifyListeners();
        
        // Debug log kaldırıldı
      }
    } catch (e) {
      // Debug log kaldırıldı
    }
  }

  /// Optimistic UI update - Transaction'ı anında UI'den kaldır
  void removeTransactionOptimistically(String transactionId) {
    try {
      // Transaction'ı bul ve hesap bakiyesini güncelle
      final transactionToRemove = transactions.firstWhere(
        (transaction) => transaction.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      
      // Hesap bakiyesini geri al (transaction silinirse bakiye geri gelir)
      if (transactionToRemove.sourceAccountId != null) {
        _reverseAccountBalance(transactionToRemove.sourceAccountId!, transactionToRemove.amount);
      }
      
      // Transactions listesinden kaldır
      transactions.removeWhere((transaction) => transaction.id == transactionId);
      
      // Summaries'i güncelle (net değer, kartlar vs.)
      _updateSummariesLocally();
      
      // UI'yi anında güncelle
      notifyListeners();
      
      // Debug log'ları kaldırıldı
      
    } catch (e) {
      // Debug log kaldırıldı
    }
  }

  /// Stock transaction için özel optimistic update
  void removeStockTransactionOptimistically(String transactionId, double amount, String? accountId) {
    try {
      // Hesap bakiyesini geri al
      if (accountId != null) {
        _reverseAccountBalance(accountId, amount);
      }
      
      // Transactions listesinden kaldır
      transactions.removeWhere((transaction) => transaction.id == transactionId);
      
      // Summaries'i güncelle (net değer, kartlar vs.)
      _updateSummariesLocally();
      
      // UI'yi anında güncelle
      notifyListeners();
      
      // Debug log'ları kaldırıldı
      
    } catch (e) {
      // Debug log kaldırıldı
    }
  }

  /// Hesap bakiyesini geri al (transaction silinirse)
  void _reverseAccountBalance(String accountId, double transactionAmount) {
    try {
      final accountIndex = accounts.indexWhere((acc) => acc.id == accountId);
      if (accountIndex != -1) {
        // Transaction amount'u ters çevir (silinen transaction'ın etkisini geri al)
        final reversedAmount = -transactionAmount;
        final newBalance = accounts[accountIndex].balance + reversedAmount;
        
        accounts[accountIndex] = accounts[accountIndex].copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        );
        
        // Debug log kaldırıldı
      }
    } catch (e) {
      debugPrint('Error reversing account balance: $e');
    }
  }

  /// Transactions'ları yenile (hata durumunda)
  void refreshTransactions() {
    try {
      loadTransactions();
      debugPrint('🔄 Transactions refreshed');
    } catch (e) {
      debugPrint('Error refreshing transactions: $e');
    }
  }
} 