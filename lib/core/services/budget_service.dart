import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/budget_model.dart';

class BudgetService {
  static final _supabase = Supabase.instance.client;

  // Kullanıcının mevcut bütçelerini getir
  static Future<List<BudgetModel>> getUserBudgets(String userId, int month, int year) async {
    try {
      final response = await _supabase
          .from('budgets')
          .select('*')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year);

      return (response as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Bütçeler yüklenirken hata oluştu: $e');
    }
  }

  // Yeni bütçe oluştur veya güncelle
  static Future<BudgetModel> upsertBudget({
    required String userId,
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
    required int month,
    required int year,
  }) async {
    try {
      final now = DateTime.now();
      
      // Önce mevcut bütçe var mı kontrol et
      final existingBudget = await _supabase
          .from('budgets')
          .select('*')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existingBudget != null) {
        // Güncelle
        final response = await _supabase
            .from('budgets')
            .update({
              'monthly_limit': monthlyLimit,
              'category_name': categoryName,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', existingBudget['id'])
            .select()
            .single();

        return BudgetModel.fromJson(response);
      } else {
        // Yeni oluştur
        final response = await _supabase
            .from('budgets')
            .insert({
              'user_id': userId,
              'category_id': categoryId,
              'category_name': categoryName,
              'monthly_limit': monthlyLimit,
              'month': month,
              'year': year,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .select()
            .single();

        return BudgetModel.fromJson(response);
      }
    } catch (e) {
      throw Exception('Bütçe kaydedilirken hata oluştu: $e');
    }
  }

  // Bütçe sil
  static Future<void> deleteBudget(String budgetId) async {
    try {
      await _supabase
          .from('budgets')
          .delete()
          .eq('id', budgetId);
    } catch (e) {
      throw Exception('Bütçe silinirken hata oluştu: $e');
    }
  }

  /// Public category matching method
  static bool isCategoryMatch(String? txCategoryId, String? txCategoryName, String budgetCategoryId, String budgetCategoryName) {
    return _isCategoryMatch(txCategoryId, txCategoryName, budgetCategoryId, budgetCategoryName);
  }

  /// Category matching helper - flexible category matching
  static bool _isCategoryMatch(String? txCategoryId, String? txCategoryName, String budgetCategoryId, String budgetCategoryName) {
    // 1. Direct ID match (en kesin)
    if (txCategoryId != null && txCategoryId == budgetCategoryId) {
      return true;
    }
    
    // 2. Direct name match (case-insensitive)
    if (txCategoryName != null && txCategoryName.toLowerCase() == budgetCategoryName.toLowerCase()) {
      return true;
    }
    
    // 3. Generated ID match (budget ID'si name'den generate edilmişse)
    if (txCategoryId != null) {
      final generatedId = budgetCategoryName.toLowerCase().replaceAll(' ', '_');
      if (txCategoryId == generatedId) {
        return true;
      }
    }
    
    // 4. Name contains match (partial match)
    if (txCategoryName != null) {
      final txNameLower = txCategoryName.toLowerCase();
      final budgetNameLower = budgetCategoryName.toLowerCase();
      
      // İki yönlü contains kontrolü
      if (txNameLower.contains(budgetNameLower) || budgetNameLower.contains(txNameLower)) {
        return true;
      }
    }
    
    // 5. Generated ID reverse match (transaction'da name varsa ID'ye çevir)
    if (txCategoryName != null) {
      final generatedId = txCategoryName.toLowerCase().replaceAll(' ', '_');
      if (generatedId == budgetCategoryId) {
        return true;
      }
    }
    
    return false;
  }

  // Kategori için harcama verilerini getir ve bütçe istatistiklerini hesapla
  static Future<List<BudgetCategoryStats>> getBudgetStats(
    String userId,
    int month,
    int year,
    List<dynamic> transactions,
  ) async {
    try {
      // Kullanıcının bütçelerini getir
      final budgets = await getUserBudgets(userId, month, year);
      print('BudgetService: Found ${budgets.length} budgets for $month/$year');
      
      if (budgets.isEmpty) {
        print('BudgetService: No budgets found');
        return [];
      }

      final stats = <BudgetCategoryStats>[];

      for (final budget in budgets) {
        print('BudgetService: Processing budget for ${budget.categoryName} (ID: ${budget.categoryId})');
        
        // Bu kategori için bu aydaki harcamaları hesapla
        final categoryTransactions = transactions.where((tx) {
          final txDate = tx.transactionDate as DateTime;
          final txCategoryId = tx.categoryId as String?;
          final txCategoryName = tx.categoryName as String?;
          
          // Önce hızlı filtreleme (tarih ve tip)
          if (txDate.month != month || txDate.year != year) {
            return false;
          }
          
          // Transaction type kontrolü
          final isExpenseTransaction = tx.type == 'expense' || 
                                     (tx.amount != null && tx.amount < 0) ||
                                     (tx.signedAmount != null && tx.signedAmount < 0);
          
          if (!isExpenseTransaction) {
            return false;
          }
          
          // Kategori eşleştirmesi (sadece gerekli olanlar için)
          final isMatching = _isCategoryMatch(txCategoryId, txCategoryName, budget.categoryId, budget.categoryName);
          
          if (isMatching) {
            print('BudgetService: ✅ MATCHED transaction: $txCategoryName (${budget.categoryName}), Amount: ${tx.amount}');
          }
          
          return isMatching;
        }).toList();

        print('BudgetService: Found ${categoryTransactions.length} transactions for ${budget.categoryName}');

        final totalSpent = categoryTransactions.fold<double>(
          0.0,
          (sum, tx) => sum + (tx.amount as double).abs(),
        );

        print('BudgetService: Total spent: $totalSpent / ${budget.monthlyLimit}');

        final percentage = totalSpent / budget.monthlyLimit * 100;
        final isOverBudget = totalSpent > budget.monthlyLimit;

        stats.add(BudgetCategoryStats(
          categoryId: budget.categoryId,
          categoryName: budget.categoryName,
          monthlyLimit: budget.monthlyLimit,
          currentSpent: totalSpent,
          transactionCount: categoryTransactions.length,
          percentage: percentage,
          isOverBudget: isOverBudget,
        ));
      }

      // En çok harcanan kategoriler önce gelsin
      stats.sort((a, b) => b.currentSpent.compareTo(a.currentSpent));

      print('BudgetService: Returning ${stats.length} budget stats');
      return stats;
    } catch (e) {
      print('BudgetService: Error calculating budget stats: $e');
      throw Exception('Bütçe istatistikleri hesaplanırken hata oluştu: $e');
    }
  }

  /// Bütçe istatistiklerini hesapla (yeni method)
  static Future<List<BudgetCategoryStats>> calculateBudgetStats(
    List<BudgetModel> budgets,
    String userId,
    int month,
    int year,
  ) async {
    try {
      if (budgets.isEmpty) {
        return [];
      }

      // Transaction'ları provider'dan almak yerine direkt hesapla
      final stats = <BudgetCategoryStats>[];

      for (final budget in budgets) {
        // Başlangıçta sıfır harcama ile stats oluştur
        final percentage = 0.0;
        final isOverBudget = false;

        stats.add(BudgetCategoryStats(
          categoryId: budget.categoryId,
          categoryName: budget.categoryName,
          monthlyLimit: budget.monthlyLimit,
          currentSpent: 0.0,
          transactionCount: 0,
          percentage: percentage,
          isOverBudget: isOverBudget,
        ));
      }

      return stats;
    } catch (e) {
      throw Exception('Bütçe istatistikleri hesaplanırken hata oluştu: $e');
    }
  }


} 