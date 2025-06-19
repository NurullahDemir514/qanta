import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/services/budget_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/unified_category_service.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/services/category_icon_service.dart';
import '../../../l10n/app_localizations.dart';

class BudgetOverviewCard extends StatefulWidget {
  const BudgetOverviewCard({super.key});

  @override
  State<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<BudgetOverviewCard> {
  List<BudgetCategoryStats> _budgetStats = [];
  bool _isLoading = true;
  bool _isFirstLoad = true;
  
  // Uyarı bildirimi cooldown sistemi
  final Map<String, DateTime> _lastAlertTimes = {};
  static const Duration _alertCooldown = Duration(minutes: 5); // 5 dakika cooldown

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        debugPrint('User null - giriş yapılmamış');
        return;
      }

      final now = DateTime.now();
      
      // Kullanıcının bütçelerini getir
      final budgets = await BudgetService.getUserBudgets(user.id, now.month, now.year);
      
      if (budgets.isEmpty) {
        if (mounted) {
          setState(() {
            _budgetStats = [];
            _isLoading = false;
            _isFirstLoad = false;
          });
        }
        return;
      }

      // Her bütçe için istatistikleri hesapla
      final stats = await BudgetService.calculateBudgetStats(budgets, user.id, now.month, now.year);

      if (mounted) {
        setState(() {
          _budgetStats = stats;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Budget yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  void _updateBudgetStatsFromTransactions(List<dynamic> transactions) {
    if (_isFirstLoad || _budgetStats.isEmpty) return;

    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      // Her bütçe için yeniden hesapla
      final updatedStats = <BudgetCategoryStats>[];
      
      for (final budgetStat in _budgetStats) {
        // Bu kategori için transaction'ları filtrele
        final categoryTransactions = transactions.where((tx) {
          final txDate = tx.transactionDate as DateTime;
          final txCategoryId = tx.categoryId as String?;
          final txCategoryName = tx.categoryName as String?;
          
          // Hızlı filtreleme
          if (txDate.month != now.month || txDate.year != now.year) {
            return false;
          }
          
          // Transaction type kontrolü
          final isExpenseTransaction = tx.type == 'expense' || 
                                     (tx.amount != null && tx.amount < 0) ||
                                     (tx.signedAmount != null && tx.signedAmount < 0);
          
          if (!isExpenseTransaction) {
            return false;
          }
          
          // Kategori eşleştirmesi
          return BudgetService.isCategoryMatch(txCategoryId, txCategoryName, budgetStat.categoryId, budgetStat.categoryName);
        }).toList();

        // Toplam harcamayı hesapla
        final totalSpent = categoryTransactions.fold<double>(0.0, (sum, tx) {
          final amount = (tx.amount as double?) ?? 0.0;
          return sum + amount.abs(); // Pozitif değer olarak hesapla
        });

        // Yeni stats oluştur
        final percentage = totalSpent / budgetStat.monthlyLimit * 100;
        final isOverBudget = totalSpent > budgetStat.monthlyLimit;
        
        final newStat = BudgetCategoryStats(
          categoryId: budgetStat.categoryId,
          categoryName: budgetStat.categoryName,
          monthlyLimit: budgetStat.monthlyLimit,
          currentSpent: totalSpent,
          transactionCount: categoryTransactions.length,
          percentage: percentage,
          isOverBudget: isOverBudget,
        );

        updatedStats.add(newStat);
      }

      // Değişiklik var mı kontrol et
      if (_hasStatsChanged(updatedStats)) {
        setState(() {
          _budgetStats = updatedStats;
        });

        // Bütçe aşımı kontrolü
        _checkBudgetAlerts(updatedStats);
      }
    } catch (e) {
      debugPrint('Budget stats güncellenirken hata: $e');
    }
  }

  bool _hasStatsChanged(List<BudgetCategoryStats> newStats) {
    if (newStats.length != _budgetStats.length) return true;

    for (int i = 0; i < newStats.length; i++) {
      final oldStat = _budgetStats[i];
      final newStat = newStats[i];
      
      if (oldStat.currentSpent != newStat.currentSpent ||
          oldStat.transactionCount != newStat.transactionCount) {
        return true;
      }
    }
    
    return false;
  }

  void _checkBudgetAlerts(List<BudgetCategoryStats> stats) {
    final now = DateTime.now();
    
    for (final stat in stats) {
      final progress = stat.progressPercentage;
      final categoryKey = stat.categoryId;
      
      // Cooldown kontrolü
      if (_lastAlertTimes.containsKey(categoryKey)) {
        final lastAlert = _lastAlertTimes[categoryKey]!;
        if (now.difference(lastAlert) < _alertCooldown) {
          continue; // Bu kategori için henüz cooldown süresi dolmamış
        }
      }
      
      bool shouldShowAlert = false;
      String alertMessage = '';
      Color alertColor = Colors.red;
      
      if (stat.isOverBudget) {
        // Bütçe aşıldı
        shouldShowAlert = true;
        alertMessage = '${stat.categoryName} bütçesi aşıldı! (${(progress * 100).toStringAsFixed(0)}%)';
        alertColor = const Color(0xFFFF3B30);
      } else if (progress > 0.8) {
        // %80 uyarısı
        shouldShowAlert = true;
        alertMessage = '${stat.categoryName} bütçesinin %${(progress * 100).toStringAsFixed(0)}\'i kullanıldı!';
        alertColor = const Color(0xFFFF9500);
      }
      
      if (shouldShowAlert) {
        // Uyarı zamanını kaydet
        _lastAlertTimes[categoryKey] = now;
        
        // Uyarıyı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alertMessage),
            backgroundColor: alertColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<UnifiedProviderV2>(
      builder: (context, provider, child) {
        // Real-time transaction güncellemelerini dinle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isFirstLoad && provider.transactions.isNotEmpty) {
            _updateBudgetStatsFromTransactions(provider.transactions);
          }
        });

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bütçe Takibi',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showBudgetManagement(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Yönet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
                                      // Horizontal scroll cards
              SizedBox(
                height: () {
                  double cardHeight;
                  if (screenHeight < 700) {
                    cardHeight = 90.0; // Küçük ekranlar
                  } else if (screenHeight < 800) {
                    cardHeight = 95.0; // Orta ekranlar
                  } else {
                    cardHeight = 100.0; // Büyük ekranlar
                  }
                  
                  return cardHeight;
                }(),
                child: _isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: 2,
                      itemBuilder: (context, index) => _buildLoadingCard(isDark),
                    )
                  : _budgetStats.isEmpty
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        children: [_buildNoBudgetCard(isDark)],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: _budgetStats.length,
                        itemBuilder: (context, index) => _buildBudgetCard(_budgetStats[index], isDark, index),
                      ),
              ),
            ],
        );
      },
    );
  }

  Widget _buildNoBudgetCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;
    
    return GestureDetector(
      onTap: () => _showBudgetManagement(context),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(left: 16, right: 8),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 22,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bütçe Belirle',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                'Harcamalarınızı kontrol edin.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBudgetCard(BudgetCategoryStats budgetStat, bool isDark, int index) {
    final progress = budgetStat.progressPercentage;
    final isOverBudget = budgetStat.isOverBudget;
    final progressColor = isOverBudget 
        ? const Color(0xFFFF3B30)
        : progress > 0.8 
            ? const Color(0xFFFF9500)
            : const Color(0xFF34C759);
    
    final numberFormat = NumberFormat('#,##0', 'tr_TR');
    
    // Kategori ikonunu al
    final categoryIcon = CategoryIconService.getIcon(budgetStat.categoryName.toLowerCase());
    final categoryColor = CategoryIconService.getColorFromMap(budgetStat.categoryName.toLowerCase());

    // Biraz daha geniş card width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;

    return GestureDetector(
      onTap: () => _showBudgetManagement(context),
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(
          left: index == 0 ? 16 : 8,
          right: 8,
        ),
        decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), // Alt padding azaltıldı
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and category name
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 14,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    budgetStat.categoryName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Progress bar with animation
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                builder: (context, animatedProgress, child) {
                  return LinearProgressIndicator(
                    value: animatedProgress,
                    backgroundColor: isDark 
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Spent/Budget amount with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: budgetStat.currentSpent),
              builder: (context, animatedSpent, child) {
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₺${numberFormat.format(animatedSpent)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                          letterSpacing: -0.3,
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: ' / ₺${numberFormat.format(budgetStat.monthlyLimit)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                          letterSpacing: -0.3,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Remaining or over budget amount
            Text(
              isOverBudget 
                ? '₺${numberFormat.format(budgetStat.overBudgetAmount)} aşıldı'
                : '₺${numberFormat.format(budgetStat.remainingAmount)} kaldı',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOverBudget 
                  ? const Color(0xFFFF3B30)
                  : isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 200.0;
    
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yükleniyor...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetManagement(BuildContext context) {
    context.push('/budget-management').then((_) {
      // Budget sayfasından döndüğünde ana sayfayı yenile
      _loadBudgetData();
    });
  }
} 