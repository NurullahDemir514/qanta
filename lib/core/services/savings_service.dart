import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/savings_goal.dart';
import '../../shared/models/savings_transaction.dart';
import '../../shared/models/savings_category.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';
import 'premium_service.dart';

/// Tasarruf servis exception
class SavingsServiceException implements Exception {
  final String message;
  final String? code;

  SavingsServiceException(this.message, [this.code]);

  @override
  String toString() => 'SavingsServiceException: $message${code != null ? ' ($code)' : ''}';
}

/// Tasarruf servisi - CRUD işlemleri
class SavingsService {
  static const String _goalsCollection = 'savings_goals';
  static const String _transactionsCollection = 'savings_transactions';
  static const String _categoriesCollection = 'savings_categories';
  static const int _freeUserMaxGoals = 3;

  /// Tüm aktif hedefleri getir
  static Future<List<SavingsGoal>> getAllGoals({bool includeArchived = false}) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      final querySnapshot = await FirebaseFirestoreService.getCollection(
        _goalsCollection,
      ).get();

      final goals = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure document ID is used as goal ID
        final goalData = {'id': doc.id, ...data};
        
        // Debug: Check if data has an empty id field
        if (data.containsKey('id') && data['id'] == '') {
          debugPrint('⚠️ Found goal with empty id field in Firestore, using doc.id: ${doc.id}');
        }
        
        return SavingsGoal.fromJson(goalData);
      }).where((goal) => includeArchived || !goal.isArchived).toList();

      // Tarihe göre sırala (en yeni en üstte)
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('📊 Loaded ${goals.length} savings goals');
      for (final goal in goals) {
        debugPrint('  ✓ "${goal.name}" - ID: ${goal.id}');
      }
      
      return goals;
    } catch (e) {
      debugPrint('❌ Error loading savings goals: $e');
      rethrow;
    }
  }

  /// Aktif hedef sayısını getir
  static Future<int> getActiveGoalsCount() async {
    try {
      final goals = await getAllGoals(includeArchived: false);
      return goals.where((g) => g.isActive).length;
    } catch (e) {
      debugPrint('❌ Error getting active goals count: $e');
      return 0;
    }
  }

  /// ID ile hedef getir
  static Future<SavingsGoal?> getGoalById(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _goalsCollection,
        docId: goalId,
      );

      if (!doc.exists) return null;

      return SavingsGoal.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    } catch (e) {
      debugPrint('❌ Error loading goal $goalId: $e');
      return null;
    }
  }

  /// Yeni hedef oluştur
  static Future<String> createGoal(SavingsGoal goal) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      // Premium kontrolü
      final premiumService = PremiumService();
      if (!premiumService.isPremium) {
        final activeCount = await getActiveGoalsCount();
        if (activeCount >= _freeUserMaxGoals) {
          throw SavingsServiceException(
            'Free users can have maximum $_freeUserMaxGoals active goals',
            'PREMIUM_REQUIRED',
          );
        }
      }

      // Validasyon
      if (goal.targetAmount <= 0) {
        throw SavingsServiceException('Target amount must be greater than 0', 'INVALID_AMOUNT');
      }

      if (goal.currentAmount < 0) {
        throw SavingsServiceException('Current amount cannot be negative', 'INVALID_AMOUNT');
      }

      // Firebase'e kaydet
      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _goalsCollection,
        data: goal.toJson(),
      );

      debugPrint('✅ Created savings goal: ${goal.name} (${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating savings goal: $e');
      rethrow;
    }
  }

  /// Hedefi güncelle
  static Future<bool> updateGoal(String goalId, SavingsGoal updatedGoal) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      // Validasyon
      if (updatedGoal.targetAmount <= 0) {
        throw SavingsServiceException('Target amount must be greater than 0', 'INVALID_AMOUNT');
      }

      if (updatedGoal.currentAmount < 0) {
        throw SavingsServiceException('Current amount cannot be negative', 'INVALID_AMOUNT');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _goalsCollection,
        docId: goalId,
        data: updatedGoal.toJson(),
      );

      debugPrint('✅ Updated savings goal: ${updatedGoal.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating savings goal: $e');
      return false;
    }
  }

  /// Hedefi arşivle
  static Future<bool> archiveGoal(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _goalsCollection,
        docId: goalId,
        data: {
          'is_archived': true,
          'archived_at': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('📦 Archived savings goal: $goalId');
      return true;
    } catch (e) {
      debugPrint('❌ Error archiving savings goal: $e');
      return false;
    }
  }

  /// Hedefi arşivden çıkar
  static Future<bool> unarchiveGoal(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _goalsCollection,
        docId: goalId,
        data: {
          'is_archived': false,
          'archived_at': null,
        },
      );

      debugPrint('📤 Unarchived savings goal: $goalId');
      return true;
    } catch (e) {
      debugPrint('❌ Error unarchiving savings goal: $e');
      return false;
    }
  }

  /// Hedefi tamamla
  static Future<bool> completeGoal(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _goalsCollection,
        docId: goalId,
        data: {
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Completed savings goal: $goalId');
      return true;
    } catch (e) {
      debugPrint('❌ Error completing savings goal: $e');
      return false;
    }
  }

  /// Hedefi aktif et (completed'dan aktif'e geri al)
  static Future<bool> reactivateGoal(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: _goalsCollection,
        docId: goalId,
        data: {
          'is_completed': false,
          'is_archived': false,
          'completed_at': null,
          'archived_at': null,
        },
      );

      debugPrint('🔄 Reactivated savings goal: $goalId');
      return true;
    } catch (e) {
      debugPrint('❌ Error reactivating savings goal: $e');
      return false;
    }
  }

  /// Hedefi sil
  static Future<bool> deleteGoal(String goalId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      // İlişkili işlemleri de sil
      final transactions = await getTransactions(goalId);
      for (final transaction in transactions) {
        await deleteTransaction(transaction.id);
      }

      // Hedefi sil
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _goalsCollection,
        docId: goalId,
      );

      debugPrint('✅ Deleted savings goal: $goalId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting savings goal: $e');
      return false;
    }
  }

  /// Para ekle
  static Future<bool> depositToGoal({
    required String goalId,
    required double amount,
    required String sourceAccountId,
    String? note,
    SavingsTransactionType type = SavingsTransactionType.deposit,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      if (amount <= 0) {
        throw SavingsServiceException('Amount must be greater than 0', 'INVALID_AMOUNT');
      }

      // Hedefi getir
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw SavingsServiceException('Goal not found', 'GOAL_NOT_FOUND');
      }

      // Check if deposit exceeds remaining goal amount
      final remainingAmount = goal.targetAmount - goal.currentAmount;
      if (amount > remainingAmount) {
        throw SavingsServiceException(
          'Amount exceeds goal remaining (remaining: $remainingAmount, requested: $amount)', 
          'EXCEEDS_GOAL_REMAINING'
        );
      }

      // Transaction oluştur
      final transaction = SavingsTransaction(
        id: FirebaseFirestore.instance.collection('temp').doc().id,
        savingsGoalId: goalId,
        userId: userId,
        amount: amount,
        type: type,
        sourceAccountId: sourceAccountId,
        note: note,
        createdAt: DateTime.now(),
      );

      // Batch operation - hem hesaptan çek, hem hedefe ekle, hem de işlemi kaydet
      await FirebaseFirestore.instance.runTransaction((txn) async {
        // 1. Kaynak hesaptan çek (manual değilse)
        if (sourceAccountId != 'manual') {
          final accountRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .doc(sourceAccountId);

          final accountSnapshot = await txn.get(accountRef);
          if (!accountSnapshot.exists) {
            throw SavingsServiceException('Source account not found', 'ACCOUNT_NOT_FOUND');
          }

          final currentBalance = (accountSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
          if (currentBalance < amount) {
            throw SavingsServiceException('Insufficient balance', 'INSUFFICIENT_BALANCE');
          }

          txn.update(accountRef, {
            'balance': FieldValue.increment(-amount),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        // 2. Tasarruf hedefine ekle
        final goalRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_goalsCollection)
            .doc(goalId);

        txn.update(goalRef, {
          'current_amount': FieldValue.increment(amount),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 3. İşlemi kaydet
        final txnRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_transactionsCollection)
            .doc(transaction.id);

        txn.set(txnRef, transaction.toJson());
      });

      // Milestone kontrolü
      await _checkAndAwardMilestones(goalId);

      // Check if goal is completed
      final updatedGoal = await getGoalById(goalId);
      if (updatedGoal != null && 
          updatedGoal.currentAmount >= updatedGoal.targetAmount && 
          !updatedGoal.isCompleted) {
        // Auto-complete the goal
        await completeGoal(goalId);
        debugPrint('🎯 Goal auto-completed: ${updatedGoal.name}');
      }

      debugPrint('✅ Deposited $amount to goal: ${goal.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error depositing to goal: $e');
      rethrow;
    }
  }

  /// Para çek
  static Future<bool> withdrawFromGoal({
    required String goalId,
    required double amount,
    required String targetAccountId,
    String? note,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      if (amount <= 0) {
        throw SavingsServiceException('Amount must be greater than 0', 'INVALID_AMOUNT');
      }

      // Hedefi getir
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw SavingsServiceException('Goal not found', 'GOAL_NOT_FOUND');
      }

      if (goal.currentAmount < amount) {
        throw SavingsServiceException('Insufficient savings', 'INSUFFICIENT_SAVINGS');
      }

      // Transaction oluştur
      final transaction = SavingsTransaction(
        id: FirebaseFirestore.instance.collection('temp').doc().id,
        savingsGoalId: goalId,
        userId: userId,
        amount: amount,
        type: SavingsTransactionType.withdraw,
        sourceAccountId: targetAccountId,
        note: note,
        createdAt: DateTime.now(),
      );

      // Batch operation
      await FirebaseFirestore.instance.runTransaction((txn) async {
        // IMPORTANT: All reads must happen before all writes in Firestore transactions
        
        // 1. READ: Hedef hesabı kontrol et (manual değilse)
        if (targetAccountId != 'manual') {
          final accountRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('accounts')
              .doc(targetAccountId);

          final accountSnapshot = await txn.get(accountRef);
          if (!accountSnapshot.exists) {
            throw SavingsServiceException('Target account not found', 'ACCOUNT_NOT_FOUND');
          }
          
          // WRITE: Hedef hesaba ekle
          txn.update(accountRef, {
            'balance': FieldValue.increment(amount),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        // 2. WRITE: Tasarruf hedefinden çıkar
        final goalRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_goalsCollection)
            .doc(goalId);

        txn.update(goalRef, {
          'current_amount': FieldValue.increment(-amount),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 3. WRITE: İşlemi kaydet
        final txnRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_transactionsCollection)
            .doc(transaction.id);

        txn.set(txnRef, transaction.toJson());
      });

      debugPrint('✅ Withdrew $amount from goal: ${goal.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error withdrawing from goal: $e');
      rethrow;
    }
  }

  /// Bir hedefe ait işlemleri getir
  static Future<List<SavingsTransaction>> getTransactions(String goalId,
      {int? limit}) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      Query query = FirebaseFirestoreService.getCollection(_transactionsCollection)
          .where('savings_goal_id', isEqualTo: goalId)
          .orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              SavingsTransaction.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      return [];
    }
  }

  /// İşlem sil
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _transactionsCollection,
        docId: transactionId,
      );

      debugPrint('✅ Deleted transaction: $transactionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
      return false;
    }
  }

  /// Milestone kontrolü ve ödüllendirme
  static Future<void> _checkAndAwardMilestones(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) return;

      final completionPercentage = goal.completionPercentage;
      final milestones = [25, 50, 75, 100];

      for (final percentage in milestones) {
        // Bu milestone'a ulaşıldı mı?
        if (completionPercentage >= percentage) {
          // Daha önce ödüllendirilmiş mi?
          final alreadyAchieved =
              goal.achievedMilestones.any((m) => m.percentage == percentage);

          if (!alreadyAchieved) {
            // Yeni milestone ekle
            final newMilestone = Milestone(
              percentage: percentage,
              achievedAt: DateTime.now(),
              amount: goal.currentAmount,
            );

            final updatedMilestones = [...goal.achievedMilestones, newMilestone];

            await updateGoal(
              goalId,
              goal.copyWith(
                achievedMilestones: updatedMilestones,
                updatedAt: DateTime.now(),
              ),
            );

            debugPrint('🎉 Milestone achieved: $percentage% for goal ${goal.name}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking milestones: $e');
    }
  }

  /// Toplam tasarruf miktarını getir
  static Future<double> getTotalSavings() async {
    try {
      final goals = await getAllGoals(includeArchived: false);
      return goals.fold<double>(0.0, (total, goal) => total + goal.currentAmount);
    } catch (e) {
      debugPrint('❌ Error getting total savings: $e');
      return 0.0;
    }
  }

  /// Round-up hesapla
  static double calculateRoundUp(double amount, RoundUpRule rule) {
    switch (rule) {
      case RoundUpRule.toNext1:
        return amount.ceil() - amount;
      case RoundUpRule.toNext5:
        return ((amount / 5).ceil() * 5) - amount;
      case RoundUpRule.toNext10:
        return ((amount / 10).ceil() * 10) - amount;
    }
  }

  // ========================================
  // KATEGORI CRUD OPERASYONLARI
  // ========================================

  /// Tüm kategorileri getir
  static Future<List<SavingsCategory>> getAllCategories() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      final querySnapshot = await FirebaseFirestoreService.getCollection(
        _categoriesCollection,
      ).where('is_active', isEqualTo: true).get();

      final categories = querySnapshot.docs
          .map((doc) => SavingsCategory.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      // İsme göre sırala
      categories.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('📊 Loaded ${categories.length} savings categories');
      return categories;
    } catch (e) {
      debugPrint('❌ Error loading savings categories: $e');
      rethrow;
    }
  }

  /// Kategori oluştur
  static Future<SavingsCategory> createCategory({
    required String name,
    required String emoji,
    required String color,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      // Aynı isimde kategori var mı kontrol et
      final existing = await getAllCategories();
      if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
        throw SavingsServiceException('Category already exists', 'DUPLICATE_CATEGORY');
      }

      final now = DateTime.now();
      final categoryId = FirebaseFirestoreService.getCollection(_categoriesCollection).doc().id;

      final category = SavingsCategory(
        id: categoryId,
        userId: userId,
        name: name,
        emoji: emoji,
        color: color,
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestoreService.getCollection(_categoriesCollection)
          .doc(categoryId)
          .set(category.toJson());

      debugPrint('✅ Created savings category: $name');
      return category;
    } catch (e) {
      debugPrint('❌ Error creating category: $e');
      rethrow;
    }
  }

  /// Kategoriyi sil (soft delete)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw SavingsServiceException('User not authenticated', 'AUTH_ERROR');
      }

      await FirebaseFirestoreService.getCollection(_categoriesCollection)
          .doc(categoryId)
          .update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Deleted savings category: $categoryId');
    } catch (e) {
      debugPrint('❌ Error deleting category: $e');
      rethrow;
    }
  }

  /// Kategori ismine göre kategori bul veya oluştur
  static Future<SavingsCategory> findOrCreateCategory({
    required String name,
    String emoji = '💰',
    String color = '6D6D70',
  }) async {
    try {
      // Önce var mı kontrol et
      final categories = await getAllCategories();
      final existing = categories.where(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      ).toList();

      if (existing.isNotEmpty) {
        return existing.first;
      }

      // Yoksa yeni oluştur
      return await createCategory(
        name: name,
        emoji: emoji,
        color: color,
      );
    } catch (e) {
      debugPrint('❌ Error finding or creating category: $e');
      rethrow;
    }
  }
}

