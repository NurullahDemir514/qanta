import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/models/account_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';
import 'unified_account_service.dart';
import 'point_service.dart';
import '../../modules/profile/providers/point_provider.dart';
import 'amazon_reward_service.dart';
import '../../modules/profile/providers/amazon_reward_provider.dart';

/// Unified Transaction Service
/// Handles all transaction operations in a single service
class UnifiedTransactionService {
  static const String _collectionName = 'transactions';
  static const String _transactionCountKey = 'transaction_count_for_interstitial';

  /// Debug: List all transactions with their source_account_id
  static Future<void> debugAllTransactions() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) return;

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .orderBy('transaction_date', descending: true)
            .limit(10),
      );

      // Debug output removed for production
    } catch (e) {
      if (kDebugMode) debugPrint('Error in debugAllTransactions: $e');
    }
  }

  /// Get all transactions for current user
  static Future<List<TransactionWithDetailsV2>> getAllTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');


      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );


      return snapshot.docs.map((doc) {
        final data = doc.data();
        final transactionData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };

        // Add joined data if available
        if (data['category_name'] != null) {
          transactionData['category_name'] = data['category_name'];
        }
        if (data['source_account_name'] != null) {
          transactionData['source_account_name'] = data['source_account_name'];
        }
        if (data['target_account_name'] != null) {
          transactionData['target_account_name'] = data['target_account_name'];
        }
        if (data['source_account_type'] != null) {
          transactionData['source_account_type'] = data['source_account_type'];
        }
        if (data['target_account_type'] != null) {
          transactionData['target_account_type'] = data['target_account_type'];
        }

        return TransactionWithDetailsV2.fromJson(transactionData);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching transactions: $e');
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
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('type', isEqualTo: type.value)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching transactions by type: $e');
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
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('source_account_id', isEqualTo: accountId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching transactions by account: $e');
      rethrow;
    }
  }

  /// Get transactions by date range
  static Future<List<TransactionWithDetailsV2>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('transaction_date', isGreaterThanOrEqualTo: startDate)
            .where('transaction_date', isLessThanOrEqualTo: endDate)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching transactions by date range: $e');
      rethrow;
    }
  }

  /// Add new transaction
  /// Add transaction
  /// Returns: Map with 'transactionId' and optionally 'amazonRewardEarned'
  static Future<Map<String, dynamic>> addTransaction(
    TransactionWithDetailsV2 transaction,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final transactionData = {
        ...transaction.toJson(),
        'user_id': userId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Debug output removed for production

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: transactionData,
      );

      // Update account balance
      await _updateAccountBalance(transaction);

      // NEW: Add points from transaction (only for expenses/income)
      int pointsEarned = 0;
      if (transaction.type == TransactionType.expense ||
          transaction.type == TransactionType.income) {
        try {
          final pointService = PointService();
          pointsEarned = await pointService.earnPointsFromTransaction(
            userId,
            docRef.id,
          );
          if (pointsEarned > 0) {
            // Refresh PointProvider to update UI immediately
            try {
              final pointProvider = PointProvider();
              await pointProvider.refresh();
            } catch (e) {
              if (kDebugMode) debugPrint('⚠️ UnifiedTransactionService: Failed to refresh PointProvider: $e');
            }
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('⚠️ UnifiedTransactionService: Point reward error: $e');
          debugPrint('⚠️ Stack trace: $stackTrace');
          }
          // Don't fail transaction if point reward fails
        }
        
        // NEW: Add Amazon reward credit from transaction
        try {
          final amazonRewardService = AmazonRewardService();
          final amazonRewardEarned = await amazonRewardService.earnRewardFromTransaction(
            userId,
            docRef.id,
          );
          if (amazonRewardEarned) {
            // Refresh AmazonRewardProvider to update UI immediately
            try {
              final amazonRewardProvider = AmazonRewardProvider();
              await amazonRewardProvider.loadCredits();
            } catch (e) {
              if (kDebugMode) debugPrint('⚠️ UnifiedTransactionService: Failed to refresh AmazonRewardProvider: $e');
            }
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('⚠️ UnifiedTransactionService: Amazon reward error: $e');
            debugPrint('⚠️ Stack trace: $stackTrace');
          }
          // Don't fail transaction if Amazon reward fails
        }
      }

      // Check if we should show interstitial ad (every 3 transactions)
      bool shouldShowInterstitial = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentCount = prefs.getInt(_transactionCountKey) ?? 0;
        final newCount = currentCount + 1;
        await prefs.setInt(_transactionCountKey, newCount);
        
        // Show interstitial ad every 3 transactions
        if (newCount % 3 == 0) {
          shouldShowInterstitial = true;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ UnifiedTransactionService: Failed to track transaction count: $e');
      }

      // Return transaction ID, points earned, and interstitial ad flag
      return {
        'transactionId': docRef.id,
        'pointsEarned': pointsEarned,
        'shouldShowInterstitial': shouldShowInterstitial,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Update transaction
  static Future<bool> updateTransaction({
    required String transactionId,
    required TransactionWithDetailsV2 transaction,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Get old transaction to reverse balance changes
      final oldTransaction = await getTransactionById(transactionId);
      if (oldTransaction != null) {
        await _reverseAccountBalance(oldTransaction);
      }

      final transactionData = {
        ...transaction.toJson(),
        'user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: transactionId,
        data: transactionData,
      );

      // Update account balance with new transaction
      await _updateAccountBalance(transaction);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete transaction
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      // Get transaction to reverse balance changes
      final transaction = await getTransactionById(transactionId);
      if (transaction != null) {
        await _reverseAccountBalance(transaction);
      }

      await FirebaseFirestoreService.deleteDocument(
        collectionName: _collectionName,
        docId: transactionId,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get transaction by ID
  static Future<TransactionWithDetailsV2?> getTransactionById(
    String transactionId,
  ) async {
    try {
      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _collectionName,
        docId: transactionId,
      );

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching transaction: $e');
      rethrow;
    }
  }

  /// Get real-time transaction updates stream
  static Stream<List<TransactionWithDetailsV2>> getTransactionStream({
    int limit = 50,
  }) {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(
        _collectionName,
      ).orderBy('transaction_date', descending: true).limit(limit),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Get transactions by account stream
  static Stream<List<TransactionWithDetailsV2>> getTransactionStreamByAccount({
    required String accountId,
    int limit = 50,
  }) {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('account_id', isEqualTo: accountId)
          .orderBy('transaction_date', descending: true)
          .limit(limit),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionWithDetailsV2.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Get total income for date range
  static Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      Query query = FirebaseFirestoreService.getCollection(
        _collectionName,
      ).where('type', isEqualTo: TransactionType.income.value);

      if (startDate != null) {
        query = query.where(
          'transaction_date',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where('transaction_date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  /// Get total expense for date range
  static Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      Query query = FirebaseFirestoreService.getCollection(
        _collectionName,
      ).where('type', isEqualTo: TransactionType.expense.value);

      if (startDate != null) {
        query = query.where(
          'transaction_date',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where('transaction_date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  /// Update account balance based on transaction
  static Future<void> _updateAccountBalance(
    TransactionWithDetailsV2 transaction,
  ) async {
    try {
      final account = await UnifiedAccountService.getAccountById(
        transaction.sourceAccountId,
      );
      if (account == null) return;

      double balanceChange = 0.0;
      final absoluteAmount = transaction.amount.abs(); // Mutlak değer kullan

      switch (transaction.type) {
        case TransactionType.income:
          if (account.type == AccountType.credit) {
            // Credit card: decrease debt (increase available limit)
            balanceChange = -absoluteAmount;
          } else {
            // Debit/Cash: increase balance
            balanceChange = absoluteAmount;
          }
          break;
        case TransactionType.expense:
          if (account.type == AccountType.credit) {
            // Credit card: increase debt (decrease available limit)
            balanceChange = absoluteAmount;
          } else {
            // Debit/Cash: decrease balance
            balanceChange = -absoluteAmount;
          }
          break;
        case TransactionType.transfer:
          // Transfer: affect source account
          if (account.type != AccountType.credit) {
            balanceChange = -absoluteAmount;
          }

          // Update source account
          if (balanceChange != 0.0) {
            await UnifiedAccountService.incrementBalance(
              accountId: transaction.sourceAccountId,
              amount: balanceChange,
            );
          }

          // Also update target account for transfers
          if (transaction.targetAccountId != null) {
            final targetAccount = await UnifiedAccountService.getAccountById(
              transaction.targetAccountId!,
            );
            if (targetAccount != null) {
              double targetBalanceChange = 0.0;

              if (targetAccount.type == AccountType.credit) {
                // Credit card: decrease debt (payment to credit card)
                targetBalanceChange = -absoluteAmount;
              } else {
                // Debit/Cash: increase balance
                targetBalanceChange = absoluteAmount;
              }

              if (targetBalanceChange != 0.0) {
                await UnifiedAccountService.incrementBalance(
                  accountId: transaction.targetAccountId!,
                  amount: targetBalanceChange,
                );
              }
            }
          }
          return; // Early return after handling transfer
        case TransactionType.stock:
          // Stock transactions affect cash accounts
          if (account.type == AccountType.cash) {
            balanceChange = transaction.amount;
          }
          break;
      }

      // Only update if there's a change (for non-transfer transactions)
      if (balanceChange != 0.0) {
        await UnifiedAccountService.incrementBalance(
          accountId: transaction.sourceAccountId,
          amount: balanceChange,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reverse account balance changes
  static Future<void> _reverseAccountBalance(
    TransactionWithDetailsV2 transaction,
  ) async {
    try {
      // Debug output removed for production

      // Force server read to avoid stale cache
      final account = await UnifiedAccountService.getAccountById(
        transaction.sourceAccountId,
        forceServerRead: true,
      );
      if (account == null) {
        debugPrint('   ⚠️ Account bulunamadı: ${transaction.sourceAccountId}');
        return;
      }

      debugPrint('   Account: ${account.name} (${account.type.value})');
      debugPrint('   Mevcut Balance: ${account.balance}');

      double balanceChange = 0.0;
      final absoluteAmount = transaction.amount.abs(); // Mutlak değer kullan

      switch (transaction.type) {
        case TransactionType.income:
          if (account.type == AccountType.credit) {
            // Credit card: increase debt (reverse income effect)
            balanceChange = absoluteAmount;
          } else {
            // Debit/Cash: decrease balance (reverse income effect)
            balanceChange = -absoluteAmount;
          }
          break;
        case TransactionType.expense:
          if (account.type == AccountType.credit) {
            // Credit card: decrease debt (reverse expense effect)
            balanceChange = -absoluteAmount;
            debugPrint('   💳 Credit Card Expense Reversal');
            debugPrint('   Balance Change: $balanceChange');
          } else {
            // Debit/Cash: increase balance (reverse expense effect)
            balanceChange = absoluteAmount;
          }
          break;
        case TransactionType.transfer:
          // Transfer: reverse source account
          if (account.type != AccountType.credit) {
            balanceChange = absoluteAmount;
          }

          // Reverse source account
          if (balanceChange != 0.0) {
            await UnifiedAccountService.incrementBalance(
              accountId: transaction.sourceAccountId,
              amount: balanceChange,
            );
          }

          // Also reverse target account for transfers
          if (transaction.targetAccountId != null) {
            // Force server read to avoid stale cache
            final targetAccount = await UnifiedAccountService.getAccountById(
              transaction.targetAccountId!,
              forceServerRead: true,
            );
            if (targetAccount != null) {
              double targetBalanceChange = 0.0;

              if (targetAccount.type == AccountType.credit) {
                // Credit card: increase debt (reverse payment)
                targetBalanceChange = absoluteAmount;
              } else {
                // Debit/Cash: decrease balance (reverse transfer)
                targetBalanceChange = -absoluteAmount;
              }

              if (targetBalanceChange != 0.0) {
                await UnifiedAccountService.incrementBalance(
                  accountId: transaction.targetAccountId!,
                  amount: targetBalanceChange,
                );
              }
            }
          }
          return; // Early return after handling transfer reversal
        case TransactionType.stock:
          // Stock transactions affect cash accounts (reverse the amount)
          if (account.type == AccountType.cash) {
            balanceChange = -transaction.amount;
          }
          break;
      }

      // Only update if there's a change (for non-transfer transactions)
      if (balanceChange != 0.0) {
        await UnifiedAccountService.incrementBalance(
          accountId: transaction.sourceAccountId,
          amount: balanceChange,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get credit card transactions
  static Future<List<TransactionWithDetailsV2>> getCreditCardTransactions({
    required String creditCardId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      debugPrint('   Credit Card ID: $creditCardId');
      debugPrint('   User ID: $userId');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('source_account_id', isEqualTo: creditCardId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      // Debug output removed for production

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final transactionData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };

        // Add joined data if available
        if (data['category_name'] != null) {
          transactionData['category_name'] = data['category_name'];
        }
        if (data['source_account_name'] != null) {
          transactionData['source_account_name'] = data['source_account_name'];
        }
        if (data['target_account_name'] != null) {
          transactionData['target_account_name'] = data['target_account_name'];
        }
        if (data['source_account_type'] != null) {
          transactionData['source_account_type'] = data['source_account_type'];
        }
        if (data['target_account_type'] != null) {
          transactionData['target_account_type'] = data['target_account_type'];
        }

        return TransactionWithDetailsV2.fromJson(transactionData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting credit card transactions: $e');
      rethrow;
    }
  }

  /// Get debit card transactions
  static Future<List<TransactionWithDetailsV2>> getDebitCardTransactions({
    required String debitCardId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('source_account_id', isEqualTo: debitCardId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final transactionData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };

        // Add joined data if available
        if (data['category_name'] != null) {
          transactionData['category_name'] = data['category_name'];
        }
        if (data['source_account_name'] != null) {
          transactionData['source_account_name'] = data['source_account_name'];
        }
        if (data['target_account_name'] != null) {
          transactionData['target_account_name'] = data['target_account_name'];
        }
        if (data['source_account_type'] != null) {
          transactionData['source_account_type'] = data['source_account_type'];
        }
        if (data['target_account_type'] != null) {
          transactionData['target_account_type'] = data['target_account_type'];
        }

        return TransactionWithDetailsV2.fromJson(transactionData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting debit card transactions: $e');
      rethrow;
    }
  }

  /// Get cash account transactions
  static Future<List<TransactionWithDetailsV2>> getCashAccountTransactions({
    required String cashAccountId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('source_account_id', isEqualTo: cashAccountId)
            .orderBy('transaction_date', descending: true)
            .limit(limit),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final transactionData = {
          ...data,
          'id': doc.id, // Override any existing id with doc.id
        };

        // Add joined data if available
        if (data['category_name'] != null) {
          transactionData['category_name'] = data['category_name'];
        }
        if (data['source_account_name'] != null) {
          transactionData['source_account_name'] = data['source_account_name'];
        }
        if (data['target_account_name'] != null) {
          transactionData['target_account_name'] = data['target_account_name'];
        }
        if (data['source_account_type'] != null) {
          transactionData['source_account_type'] = data['source_account_type'];
        }
        if (data['target_account_type'] != null) {
          transactionData['target_account_type'] = data['target_account_type'];
        }

        return TransactionWithDetailsV2.fromJson(transactionData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting cash account transactions: $e');
      rethrow;
    }
  }
}
