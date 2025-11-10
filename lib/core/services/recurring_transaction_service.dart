import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/recurring_transaction_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/models/account_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';
import 'unified_transaction_service.dart';
import 'unified_account_service.dart';
import 'notification_service.dart';

/// Recurring Transaction Service Exception
class RecurringTransactionServiceException implements Exception {
  final String message;
  final String? code;

  RecurringTransactionServiceException(this.message, [this.code]);

  @override
  String toString() => 'RecurringTransactionServiceException: $message${code != null ? ' ($code)' : ''}';
}

/// Recurring Transaction Service - CRUD operations
class RecurringTransactionService {
  static const String _collection = 'recurring_transactions';

  /// Get all recurring transactions for current user
  static Future<List<RecurringTransaction>> getAllRecurringTransactions({
    bool includeInactive = false,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw RecurringTransactionServiceException(
          'User not authenticated',
          'AUTH_ERROR',
        );
      }

      Query query = FirebaseFirestoreService.getCollection(_collection)
          .where('user_id', isEqualTo: userId);

      if (!includeInactive) {
        query = query.where('is_active', isEqualTo: true);
      }

      final querySnapshot = await query.orderBy('created_at', descending: true).get();

      final transactions = querySnapshot.docs.map((doc) {
        return RecurringTransaction.fromFirestore(doc);
      }).toList();

      debugPrint('📊 Loaded ${transactions.length} recurring transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error loading recurring transactions: $e');
      rethrow;
    }
  }

  /// Get active recurring transactions only
  static Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    return getAllRecurringTransactions(includeInactive: false);
  }

  /// Get recurring transaction by ID
  static Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw RecurringTransactionServiceException(
          'User not authenticated',
          'AUTH_ERROR',
        );
      }

      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _collection,
        docId: id,
      );

      if (!doc.exists) return null;

      return RecurringTransaction.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error loading recurring transaction $id: $e');
      return null;
    }
  }

  /// Create new recurring transaction
  static Future<String> createRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw RecurringTransactionServiceException(
          'User not authenticated',
          'AUTH_ERROR',
        );
      }

      // Validation
      if (transaction.amount <= 0) {
        throw RecurringTransactionServiceException(
          'Amount must be greater than 0',
          'INVALID_AMOUNT',
        );
      }

      if (transaction.name.isEmpty) {
        throw RecurringTransactionServiceException(
          'Name cannot be empty',
          'INVALID_NAME',
        );
      }

      // Calculate next execution date if not provided
      final transactionWithNextDate = transaction.copyWith(
        nextExecutionDate: transaction.nextExecutionDate ?? 
            transaction.calculateNextExecutionDate(),
      );

      // Save to Firestore
      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collection,
        data: transactionWithNextDate.toJson(),
      );

      debugPrint('✅ Created recurring transaction: ${transaction.name} (${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating recurring transaction: $e');
      rethrow;
    }
  }

  /// Update recurring transaction
  static Future<bool> updateRecurringTransaction(
    String id,
    RecurringTransaction updatedTransaction,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw RecurringTransactionServiceException(
          'User not authenticated',
          'AUTH_ERROR',
        );
      }

      // Calculate next execution date if needed
      final transactionWithNextDate = updatedTransaction.copyWith(
        nextExecutionDate: updatedTransaction.nextExecutionDate ?? 
            updatedTransaction.calculateNextExecutionDate(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestoreService.updateDocument(
        collectionName: _collection,
        docId: id,
        data: transactionWithNextDate.toJson(),
      );

      debugPrint('✅ Updated recurring transaction: ${updatedTransaction.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating recurring transaction: $e');
      return false;
    }
  }

  /// Delete recurring transaction
  static Future<bool> deleteRecurringTransaction(String id) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw RecurringTransactionServiceException(
          'User not authenticated',
          'AUTH_ERROR',
        );
      }

      await FirebaseFirestoreService.deleteDocument(
        collectionName: _collection,
        docId: id,
      );

      debugPrint('✅ Deleted recurring transaction: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting recurring transaction: $e');
      return false;
    }
  }

  /// Toggle active status
  static Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      final transaction = await getRecurringTransactionById(id);
      if (transaction == null) {
        throw RecurringTransactionServiceException('Transaction not found');
      }

      return updateRecurringTransaction(
        id,
        transaction.copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error toggling active status: $e');
      return false;
    }
  }

  /// Update last executed date (for background task)
  static Future<bool> updateLastExecutedDate(String id, DateTime executedDate) async {
    try {
      final transaction = await getRecurringTransactionById(id);
      if (transaction == null) {
        throw RecurringTransactionServiceException('Transaction not found');
      }

      final nextExecution = transaction.calculateNextExecutionDate();

      return updateRecurringTransaction(
        id,
        transaction.copyWith(
          lastExecutedDate: executedDate,
          nextExecutionDate: nextExecution,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error updating last executed date: $e');
      return false;
    }
  }

  /// Execute recurring transactions that are due (called by background task)
  /// 
  /// This method:
  /// 1. Finds all active recurring transactions
  /// 2. Checks if nextExecutionDate has arrived
  /// 3. Creates transactions for due subscriptions
  /// 4. Updates lastExecutedDate and nextExecutionDate
  /// 5. Sends notifications
  static Future<void> executeRecurringTransactions() async {
    try {
      debugPrint('🔄 Starting recurring transaction execution...');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all active recurring transactions
      final recurringTransactions = await getActiveRecurringTransactions();
      debugPrint('📊 Found ${recurringTransactions.length} active recurring transactions');
      
      int executedCount = 0;
      int errorCount = 0;
      
      for (final recurring in recurringTransactions) {
        try {
          // Check if transaction should be executed
          if (!_shouldExecute(recurring, today)) {
            continue;
          }
          
          debugPrint('✅ Executing recurring transaction: ${recurring.name}');
          
          // Create transaction from recurring transaction
          await _createTransactionFromRecurring(recurring, now);
          
          // Update last executed date and next execution date
          await updateLastExecutedDate(recurring.id, now);
          
          executedCount++;
          
          // Send notification (optional, batch notifications)
          debugPrint('📱 Transaction created for: ${recurring.name}');
        } catch (e) {
          debugPrint('❌ Error executing recurring transaction ${recurring.name}: $e');
          errorCount++;
        }
      }
      
      // Send batch notification if any transactions were executed
      if (executedCount > 0) {
        await _sendBatchNotification(executedCount);
      }
      
      debugPrint('✅ Recurring transaction execution completed: $executedCount executed, $errorCount errors');
    } catch (e) {
      debugPrint('❌ Error in executeRecurringTransactions: $e');
      rethrow;
    }
  }

  /// Check if recurring transaction should be executed
  static bool _shouldExecute(RecurringTransaction recurring, DateTime today) {
    // Must be active
    if (!recurring.isActive) {
      debugPrint('   ⏭️ ${recurring.name}: Not active, skipping');
      return false;
    }
    
    // Check if end date has passed
    if (recurring.endDate != null) {
      final endDate = DateTime(
        recurring.endDate!.year,
        recurring.endDate!.month,
        recurring.endDate!.day,
      );
      if (today.isAfter(endDate)) {
        debugPrint('   ⏭️ ${recurring.name}: End date passed (${endDate}), skipping');
        return false;
      }
    }
    
    // Normalize start date (remove time component)
    final startDate = DateTime(
      recurring.startDate.year,
      recurring.startDate.month,
      recurring.startDate.day,
    );
    
    // Check if start date hasn't arrived yet
    if (today.isBefore(startDate)) {
      debugPrint('   ⏭️ ${recurring.name}: Start date not reached (${startDate}), skipping');
      return false;
    }
    
    // If never executed before, execute on start date or later
    if (recurring.lastExecutedDate == null) {
      // First execution: execute if start date is today or earlier
      final shouldExecuteFirst = !today.isBefore(startDate);
      if (shouldExecuteFirst) {
        debugPrint('   ✅ ${recurring.name}: First execution (start: ${startDate})');
      } else {
        debugPrint('   ⏭️ ${recurring.name}: Waiting for start date (${startDate})');
      }
      return shouldExecuteFirst;
    }
    
    // If already executed, check next execution date
    if (recurring.nextExecutionDate == null) {
      debugPrint('   ⚠️ ${recurring.name}: No next execution date, skipping');
      return false;
    }
    
    // Check if next execution date has arrived
    final nextDate = DateTime(
      recurring.nextExecutionDate!.year,
      recurring.nextExecutionDate!.month,
      recurring.nextExecutionDate!.day,
    );
    
    // Execute if next execution date is today or earlier
    final shouldExecute = !today.isBefore(nextDate);
    if (shouldExecute) {
      debugPrint('   ✅ ${recurring.name}: Next execution date reached (${nextDate})');
    } else {
      debugPrint('   ⏭️ ${recurring.name}: Next execution date not reached (${nextDate})');
    }
    return shouldExecute;
  }

  /// Create transaction from recurring transaction
  static Future<String> _createTransactionFromRecurring(
    RecurringTransaction recurring,
    DateTime executionDate,
  ) async {
    try {
      // Get account information
      final account = await UnifiedAccountService.getAccountById(
        recurring.accountId,
        forceServerRead: true,
      );
      
      if (account == null) {
        throw RecurringTransactionServiceException(
          'Account not found: ${recurring.accountId}',
          'ACCOUNT_NOT_FOUND',
        );
      }
      
      // Create transaction description with subscription name
      // Note: Background task doesn't have access to localization
      // The "(Automatic)" suffix will be localized in UI if needed
      // For now, we include category name which will be displayed separately
      final description = recurring.name;
      
      // Get account display name
      // For cash accounts, use 'CASH_WALLET' identifier so UI can localize it properly
      // For other accounts, use the account name as is
      String accountDisplayName = account.type == AccountType.cash 
          ? 'CASH_WALLET' 
          : account.name;
      
      // Create TransactionWithDetailsV2 with account information
      final transaction = TransactionWithDetailsV2(
        id: '', // Will be generated by Firebase
        userId: '', // Will be set by service
        type: TransactionType.expense, // Subscriptions are expenses
        amount: recurring.amount,
        description: description,
        transactionDate: executionDate,
        categoryId: recurring.categoryId,
        sourceAccountId: recurring.accountId,
        isRecurring: true, // Mark as recurring transaction
        notes: 'AUTO_CREATED_SUBSCRIPTION', // Localization marker
        isPaid: true, // Mark as paid (since it's automatic)
        createdAt: executionDate,
        updatedAt: executionDate,
        // Add account display information
        sourceAccountName: accountDisplayName,
        sourceAccountType: account.typeDisplayName,
        // Add category name (from Step 2 category selection)
        categoryName: recurring.name,
      );
      
      // Add transaction using UnifiedTransactionService
      final result = await UnifiedTransactionService.addTransaction(transaction);
      final transactionId = result['transactionId'] as String;
      
      debugPrint('✅ Created transaction $transactionId for subscription ${recurring.name} (Account: ${accountDisplayName})');
      return transactionId;
    } catch (e) {
      debugPrint('❌ Error creating transaction from recurring: $e');
      rethrow;
    }
  }

  /// Send batch notification for executed transactions
  static Future<void> _sendBatchNotification(int count) async {
    try {
      // Get localized notification messages
      final messages = await _getNotificationMessages();
      
      final title = count == 1 
          ? messages['title_single']!
          : messages['title_multiple']!.replaceAll('{count}', count.toString());
      
      final body = count == 1
          ? messages['body_single']!
          : messages['body_multiple']!.replaceAll('{count}', count.toString());
      
      await NotificationService.showNotification(
        title: title,
        body: body,
        payload: 'subscriptions',
      );
      
      debugPrint('📱 Sent batch notification for $count transactions');
    } catch (e) {
      debugPrint('❌ Error sending batch notification: $e');
      // Don't throw - notification failure shouldn't fail the execution
    }
  }
  
  /// Get localized notification messages for recurring transactions
  static Future<Map<String, String>> _getNotificationMessages() async {
    try {
      // Get user's language preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString('locale') ?? 'tr';
      
      // Fallback to system locale if not found
      final languageCode = localeCode.isNotEmpty 
          ? localeCode 
          : _getSystemLocale();
      
      // Return localized messages based on language
      return _getLocalizedMessages(languageCode);
    } catch (e) {
      debugPrint('❌ Error getting notification messages: $e');
      // Fallback to Turkish
      return _getLocalizedMessages('tr');
    }
  }
  
  /// Get system locale from platform
  static String _getSystemLocale() {
    try {
      // Try to get from PlatformDispatcher
      return PlatformDispatcher.instance.locale.languageCode;
    } catch (e) {
      return 'tr'; // Default to Turkish
    }
  }
  
  /// Get localized messages based on language code
  static Map<String, String> _getLocalizedMessages(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          'title_single': 'Subscription Payment',
          'title_multiple': '{count} Subscription Payments',
          'body_single': 'Automatic payment created',
          'body_multiple': '{count} automatic payments created',
        };
      case 'de':
        return {
          'title_single': 'Abonnementzahlung',
          'title_multiple': '{count} Abonnementzahlungen',
          'body_single': 'Automatische Zahlung erstellt',
          'body_multiple': '{count} automatische Zahlungen erstellt',
        };
      case 'tr':
      default:
        return {
          'title_single': 'Abonelik Ödemesi',
          'title_multiple': '{count} Abonelik Ödemesi',
          'body_single': 'Otomatik ödeme işlemi oluşturuldu',
          'body_multiple': '{count} otomatik ödeme işlemi oluşturuldu',
        };
    }
  }
}

