import 'package:flutter/foundation.dart';
import '../../shared/models/savings_goal.dart';
import '../../shared/models/savings_transaction.dart';
import '../../shared/models/savings_category.dart';
import '../services/savings_service.dart';
import '../events/savings_events.dart';

/// Tasarruf provider - State management
class SavingsProvider extends ChangeNotifier {
  // Singleton pattern
  static final SavingsProvider _instance = SavingsProvider._internal();
  factory SavingsProvider() => _instance;
  static SavingsProvider get instance => _instance;

  SavingsProvider._internal() {
    _setupEventListeners();
  }

  // State
  List<SavingsGoal> _goals = [];
  List<SavingsCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, List<SavingsTransaction>> _transactionsByGoal = {};

  // Getters
  List<SavingsGoal> get goals => _goals;
  List<SavingsGoal> get activeGoals => _goals.where((g) => g.isActive).toList();
  List<SavingsGoal> get archivedGoals => _goals.where((g) => g.isArchived).toList();
  List<SavingsGoal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  List<SavingsCategory> get categories => _categories;
  List<SavingsCategory> get activeCategories => _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasGoals => _goals.isNotEmpty;
  int get activeGoalsCount => activeGoals.length;

  /// Toplam tasarruf miktarı
  double get totalSavings => _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);

  /// Toplam hedef miktarı
  double get totalTarget => _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);

  /// Ortalama ilerleme yüzdesi
  double get averageProgress {
    if (_goals.isEmpty) return 0.0;
    final totalProgress = _goals.fold(0.0, (sum, goal) => sum + goal.completionPercentage);
    return totalProgress / _goals.length;
  }

  /// Bir hedefe ait işlemleri getir
  List<SavingsTransaction> getTransactions(String goalId) {
    return _transactionsByGoal[goalId] ?? [];
  }

  /// Tüm hedefleri yükle
  Future<void> loadGoals({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _goals = await SavingsService.getAllGoals(includeArchived: true);

      debugPrint('✅ Loaded ${_goals.length} savings goals in provider');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tüm kategorileri yükle
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await SavingsService.getAllCategories();

      debugPrint('✅ Loaded ${_categories.length} savings categories');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni kategori oluştur
  Future<SavingsCategory?> createCategory({
    required String name,
    String emoji = '💰',
    String color = '6D6D70',
  }) async {
    try {
      _error = null;
      notifyListeners();

      final category = await SavingsService.createCategory(
        name: name,
        emoji: emoji,
        color: color,
      );

      // Kategorileri yeniden yükle
      await loadCategories(forceRefresh: true);

      debugPrint('✅ Created category: $name');
      return category;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating category: $e');
      notifyListeners();
      return null;
    }
  }

  /// Kategori bul veya oluştur
  Future<SavingsCategory?> findOrCreateCategory({
    required String name,
    String emoji = '💰',
    String color = '6D6D70',
  }) async {
    try {
      final category = await SavingsService.findOrCreateCategory(
        name: name,
        emoji: emoji,
        color: color,
      );

      // Kategorileri yeniden yükle
      await loadCategories(forceRefresh: true);

      return category;
    } catch (e) {
      debugPrint('❌ Error finding or creating category: $e');
      return null;
    }
  }

  /// Belirli bir hedefe ait işlemleri yükle
  Future<void> loadTransactions(String goalId) async {
    try {
      final transactions = await SavingsService.getTransactions(goalId);
      _transactionsByGoal[goalId] = transactions;
      notifyListeners();

      debugPrint('✅ Loaded ${transactions.length} transactions for goal $goalId');
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
    }
  }

  /// Yeni hedef oluştur
  Future<String?> createGoal(SavingsGoal goal) async {
    try {
      _error = null;
      notifyListeners();

      final goalId = await SavingsService.createGoal(goal);
      
      // Event emit
      savingsEvents.emitSavingsGoalCreated(goal.copyWith(id: goalId));
      
      // Hedefleri yeniden yükle
      await loadGoals(forceRefresh: true);

      debugPrint('✅ Created goal: ${goal.name}');
      return goalId;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating goal: $e');
      notifyListeners();
      return null;
    }
  }

  /// Hedefi güncelle
  Future<bool> updateGoal(String goalId, SavingsGoal updatedGoal) async {
    try {
      _error = null;
      notifyListeners();

      // Eski hedefi bul
      final oldGoal = _goals.firstWhere((g) => g.id == goalId);

      final success = await SavingsService.updateGoal(goalId, updatedGoal);
      
      if (success) {
        // Event emit
        savingsEvents.emitSavingsGoalUpdated(oldGoal, updatedGoal);
        
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Hedefi arşivle
  Future<bool> archiveGoal(String goalId) async {
    try {
      _error = null;
      notifyListeners();

      final success = await SavingsService.archiveGoal(goalId);
      
      if (success) {
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hedefi arşivden çıkar
  Future<bool> unarchiveGoal(String goalId) async {
    try {
      _error = null;
      notifyListeners();

      final success = await SavingsService.unarchiveGoal(goalId);
      
      if (success) {
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hedefi aktif et (completed'dan aktif'e geri al)
  Future<bool> reactivateGoal(String goalId) async {
    try {
      _error = null;
      notifyListeners();

      final success = await SavingsService.reactivateGoal(goalId);
      
      if (success) {
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hedefi tamamla
  Future<bool> completeGoal(String goalId) async {
    try {
      _error = null;
      notifyListeners();

      // Get goal before completion
      final goal = _goals.firstWhere((g) => g.id == goalId);

      final success = await SavingsService.completeGoal(goalId);
      
      if (success) {
        // Emit completion event
        savingsEvents.emitSavingsGoalCompleted(goal);
        
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Hedefi sil
  Future<bool> deleteGoal(String goalId) async {
    try {
      _error = null;
      notifyListeners();

      // Silinen hedefi bul
      final deletedGoal = _goals.firstWhere((g) => g.id == goalId);

      final success = await SavingsService.deleteGoal(goalId);
      
      if (success) {
        // Event emit
        savingsEvents.emitSavingsGoalDeleted(goalId, deletedGoal);
        
        // Hedefleri yeniden yükle
        await loadGoals(forceRefresh: true);
        
        // İşlemleri temizle
        _transactionsByGoal.remove(goalId);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Para ekle
  Future<bool> deposit({
    required String goalId,
    required double amount,
    String? sourceAccountId,
    String? note,
  }) async {
    try {
      _error = null;
      notifyListeners();

      final success = await SavingsService.depositToGoal(
        goalId: goalId,
        amount: amount,
        sourceAccountId: sourceAccountId ?? 'manual', // Manual yatırma
        note: note,
      );

      if (success) {
        // Hedefleri ve işlemleri yeniden yükle
        await Future.wait([
          loadGoals(forceRefresh: true),
          loadTransactions(goalId),
        ]);

        // Milestone kontrolü
        final goal = _goals.firstWhere((g) => g.id == goalId);
        _checkMilestones(goal);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error depositing: $e');
      notifyListeners();
      return false;
    }
  }

  /// Para çek
  Future<bool> withdraw({
    required String goalId,
    required double amount,
    String? targetAccountId,
    String? note,
  }) async {
    try {
      _error = null;
      notifyListeners();

      final success = await SavingsService.withdrawFromGoal(
        goalId: goalId,
        amount: amount,
        targetAccountId: targetAccountId ?? 'manual', // Manual çekme
        note: note,
      );

      if (success) {
        // Hedefleri ve işlemleri yeniden yükle
        await Future.wait([
          loadGoals(forceRefresh: true),
          loadTransactions(goalId),
        ]);
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error withdrawing: $e');
      notifyListeners();
      return false;
    }
  }

  /// ID'ye göre hedef getir
  SavingsGoal? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((g) => g.id == goalId);
    } catch (e) {
      return null;
    }
  }

  /// Kategoriye göre hedefleri getir
  List<SavingsGoal> getGoalsByCategory(String category) {
    return _goals.where((g) => g.category == category && g.isActive).toList();
  }

  /// Event listener'larını kur
  void _setupEventListeners() {
    savingsEvents.listen<SavingsGoalCreated>((event) {
      debugPrint('📢 Goal created event received: ${event.goal.name}');
    });

    savingsEvents.listen<SavingsGoalUpdated>((event) {
      debugPrint('📢 Goal updated event received: ${event.newGoal.name}');
    });

    savingsEvents.listen<SavingsGoalDeleted>((event) {
      debugPrint('📢 Goal deleted event received: ${event.goalId}');
    });

    savingsEvents.listen<SavingsMilestoneAchieved>((event) {
      debugPrint('🎉 Milestone ${event.milestone.percentage}% achieved for ${event.goal.name}');
    });
  }

  /// Hata temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Milestone kontrolü ve event emit
  void _checkMilestones(SavingsGoal updatedGoal) {
    final milestones = [25, 50, 75, 100];
    
    for (final percentage in milestones) {
      // Hedefe ulaşıldı mı kontrol et
      if (updatedGoal.completionPercentage >= percentage) {
        // Bu milestone daha önce ulaşılmış mı?
        final alreadyAchieved = updatedGoal.achievedMilestones.any((m) => m.percentage == percentage);
        
        if (!alreadyAchieved) {
          // Yeni milestone!
          final milestoneData = Milestone(
            percentage: percentage,
            achievedAt: DateTime.now(),
            amount: updatedGoal.currentAmount,
          );
          
          // Event emit
          savingsEvents.emitSavingsMilestoneAchieved(updatedGoal, milestoneData);
          
          debugPrint('🎯 Milestone $percentage% achieved for ${updatedGoal.name}');
        }
      }
    }
  }

  @override
  void dispose() {
    // Provider cleanup
    super.dispose();
  }
}
