import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/unified_account_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../shared/models/savings_transaction.dart';
import '../../../shared/models/account_model.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/savings_deposit_form.dart';
import '../widgets/savings_withdraw_form.dart';
import '../widgets/edit_savings_goal_form.dart';
import '../../advertisement/services/google_ads_real_banner_service.dart';
import '../../advertisement/config/advertisement_config.dart' as config;
import '../../advertisement/models/advertisement_models.dart';

/// Tasarruf hedefi detay ekranı
class SavingsGoalDetailScreen extends StatefulWidget {
  final String goalId;

  const SavingsGoalDetailScreen({super.key, required this.goalId});

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late GoogleAdsRealBannerService _detailBannerService;

  @override
  void initState() {
    super.initState();
    
    // Banner servisini başlat
    _detailBannerService = GoogleAdsRealBannerService(
      adUnitId: config.AdvertisementConfig.savingsGoalDetailBanner.bannerAdUnitId,
      size: AdvertisementSize.banner320x50,
      isTestMode: false,
    );
    
    // Banner'ı yükle (2 saniye delay) - Sadece premium olmayanlar için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final premiumService = context.read<PremiumService>();
      if (!premiumService.isPremium && mounted) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _detailBannerService.loadAd();
          }
        });
      }
    });
    
    // İşlemleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savingsProvider = context.read<SavingsProvider>();
      savingsProvider.loadTransactions(widget.goalId);
    });
  }

  @override
  void dispose() {
    _detailBannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, child) {
        // Hedefi bul
        final goal = savingsProvider.goals.where((g) => g.id == widget.goalId).firstOrNull;
        
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.goalNotFound),
            ),
            body: Center(
              child: Text(l10n.goalNotFound),
            ),
          );
        }

        final transactions = savingsProvider.getTransactions(widget.goalId);
        final themeProvider = context.watch<ThemeProvider>();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: Text(
              goal.name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet kartı
                _buildSummaryCard(context, goal, themeProvider, isDark, l10n),
                
                const SizedBox(height: 20),
                
                // Action buttons
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.savingsCompleted,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      // İlk satır: Ekle ve Çek
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernActionButton(
                              context: context,
                              label: l10n.add,
                              subtitle: l10n.addSavings,
                              icon: Icons.add_circle,
                              gradientColors: [
                                Colors.green.shade500,
                                const Color(0xFF30D158),
                              ],
                              onTap: () => _showDepositForm(context, goal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernActionButton(
                              context: context,
                              label: l10n.withdraw,
                              subtitle: l10n.withdrawMoney,
                              icon: Icons.arrow_circle_up,
                              gradientColors: [
                                const Color(0xFFFF453A),
                                const Color(0xFFFF375F),
                              ],
                              onTap: () => _showWithdrawForm(context, goal),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // İkinci satır: Düzenle, Arşiv/Aktif, Sil
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernActionButton(
                              context: context,
                              label: l10n.edit,
                              subtitle: l10n.editGoal,
                              icon: Icons.edit,
                              gradientColors: [
                                const Color(0xFF007AFF),
                                const Color(0xFF0A84FF),
                              ],
                              onTap: () => _showEditForm(context, goal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernActionButton(
                              context: context,
                              label: goal.isArchived 
                                  ? l10n.unarchive
                                  : goal.isCompleted 
                                      ? l10n.activate
                                      : l10n.archive,
                              subtitle: goal.isArchived 
                                  ? l10n.activateGoal
                                  : goal.isCompleted 
                                      ? l10n.restartGoal
                                      : l10n.archiveGoal,
                              icon: goal.isArchived || goal.isCompleted
                                  ? Icons.unarchive
                                  : Icons.archive,
                              gradientColors: [
                                const Color(0xFFFF9500),
                                const Color(0xFFFF9F0A),
                              ],
                              onTap: () {
                                if (goal.isArchived) {
                                  _confirmUnarchive(context, goal);
                                } else if (goal.isCompleted) {
                                  _confirmReactivate(context, goal);
                                } else {
                                  _confirmArchive(context, goal);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernActionButton(
                              context: context,
                              label: l10n.delete,
                              subtitle: l10n.deleteGoal,
                              icon: Icons.delete,
                              gradientColors: [
                                const Color(0xFFFF3B30),
                                const Color(0xFFFF453A),
                              ],
                              onTap: () => _confirmDelete(context, goal),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // İşlem geçmişi başlığı
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    l10n.transactionHistory,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                // İşlem geçmişi
                if (transactions.isEmpty)
                  _buildNoTransactionsView(isDark, l10n)
                else
                  Column(
                    children: List.generate(
                      transactions.length,
                      (index) {
                        final transaction = transactions[index];
                        return Column(
                          children: [
                            _buildTransactionItem(
                              context,
                              transaction,
                              themeProvider,
                              isDark,
                              l10n,
                            ),
                            if (index < transactions.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark 
                                    ? const Color(0xFF38383A) 
                                    : const Color(0xFFE5E5EA),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                
                // Banner Reklam (Premium olmayanlara göster)
                const SizedBox(height: 20),
                Consumer<PremiumService>(
                  builder: (context, premiumService, child) {
                    if (!premiumService.isPremium && 
                        _detailBannerService.isLoaded && 
                        _detailBannerService.bannerWidget != null) {
                      return Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: _detailBannerService.bannerWidget!,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 80), // Safe area için boşluk
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    SavingsGoal goal,
    ThemeProvider themeProvider,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final progress = goal.progress.clamp(0.0, 1.0);
    final Color primaryColor = Color(int.parse('0x${goal.color}'));
    final completionPercent = goal.completionPercentage;
    final hasCategory = goal.category != null && goal.category!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Üst: Kategori + İlerleme Badge (sadece kategori varsa göster)
          if (hasCategory) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.category!.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${completionPercent.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          
          // Merkez: Büyük Tutar
          Text(
            themeProvider.formatAmount(goal.currentAmount),
            style: GoogleFonts.inter(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 18),
          
          // Estetik Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? Colors.white : Colors.black).withOpacity(0),
                  (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  (isDark ? Colors.white : Colors.black).withOpacity(0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // 3 Sütun: Hedef | İlerleme | Kalan
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.target,
                  value: themeProvider.formatAmount(goal.targetAmount),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.progress,
                  value: '${completionPercent.toStringAsFixed(1)}%',
                  isDark: isDark,
                  centered: true,
                ),
              ),
              Expanded(
                child: _buildCompactMetric(
                  label: l10n.remaining,
                  value: themeProvider.formatAmount(goal.remainingAmount),
                  isDark: isDark,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 2 Sütun: Kalan Gün | Aylık Hedef
          if (goal.targetDate != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.remainingDays,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.daysRemaining}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.monthlyRequiredSaving != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.monthlyTarget,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeProvider.formatAmount(goal.monthlyRequiredSaving!),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required String label,
    required String value,
    required bool isDark,
    bool centered = false,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: centered 
          ? CrossAxisAlignment.center 
          : (alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start),
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          textAlign: centered ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.2,
          ),
          textAlign: centered ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1C1C1E) 
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? const Color(0xFF38383A) 
                : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: gradientColors[0],
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTransactionsView(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: isDark 
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTransactionsYet,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark 
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.noTransactionsHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark 
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.25),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    SavingsTransaction transaction,
    ThemeProvider themeProvider,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final savingsProvider = context.read<SavingsProvider>();
    final goal = savingsProvider.getGoalById(widget.goalId);
    if (goal == null) return const SizedBox.shrink();
    
    final isDeposit = transaction.type == SavingsTransactionType.deposit;
    final color = isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFFF453A);
    
    // İşlemin hedefe etkisini hesapla
    final impactPercentage = (transaction.amount / goal.targetAmount * 100).clamp(0.0, 100.0);
    final percentageStr = impactPercentage.toStringAsFixed(1);
    final impactText = isDeposit
        ? l10n.savingsGoalImpactDeposit(percentageStr)
        : l10n.savingsGoalImpactWithdraw(percentageStr);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Renk çubuğu - Compact stock card style
          Container(
            width: 3,
            height: 38,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve tarih - her zaman yanyana
                Row(
                  children: [
                    Text(
                      isDeposit ? l10n.savingsAdded : l10n.moneyWithdrawn,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_formatTransactionDate(transaction.createdAt, l10n)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                // Not - varsa göster, yoksa "Açıklama yok"
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.note != null && transaction.note!.isNotEmpty
                        ? transaction.note!
                        : l10n.noDescription,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: transaction.note == null || transaction.note!.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: isDark ? const Color(0xFF98989F) : const Color(0xFF6B6B70),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount ve etki - sağ tarafta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tutar
              Text(
                '${isDeposit ? '+' : '-'}${themeProvider.formatAmount(transaction.amount)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              // Etki metni
              Text(
                impactText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTransactionDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(date.year, date.month, date.day);
    
    if (transactionDay == today) {
      return l10n.today;
    } else if (transactionDay == yesterday) {
      return l10n.yesterday;
    } else {
      final formatter = DateFormat('d MMM', 'tr_TR');
      return formatter.format(date);
    }
  }

  void _showEditForm(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditSavingsGoalForm(
          goal: goal,
          onSuccess: () async {
            setState(() {}); // Refresh
            final unifiedProvider = context.read<UnifiedProviderV2>();
            // Refresh account balances (in case goal amount changed)
            await unifiedProvider.loadAccounts(forceServerRead: true);
            // Refresh savings goals (anasayfa için)
            await unifiedProvider.loadSavingsGoals();
          },
        ),
      ),
    );
  }

  Future<void> _showDepositForm(BuildContext context, SavingsGoal goal) async {
    // Validate goal
    if (goal.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidGoal)),
      );
      return;
    }
    
    // Load accounts before showing form
    final accounts = await UnifiedAccountService.getAllAccounts();
    final filteredAccounts = accounts.where((account) => 
      account.type == AccountType.cash || 
      account.type == AccountType.debit
    ).toList();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SavingsDepositForm(
          goal: goal,
          accounts: filteredAccounts,
          onSuccess: () async {
            setState(() {}); // Refresh
            final unifiedProvider = context.read<UnifiedProviderV2>();
            // Refresh account balances
            await unifiedProvider.loadAccounts(forceServerRead: true);
            // Refresh savings goals (anasayfa için)
            await unifiedProvider.loadSavingsGoals();
          },
        ),
      ),
    );
  }

  Future<void> _showWithdrawForm(BuildContext context, SavingsGoal goal) async {
    // Validate goal
    if (goal.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidGoal)),
      );
      return;
    }
    
    // Load accounts before showing form
    final accounts = await UnifiedAccountService.getAllAccounts();
    final filteredAccounts = accounts.where((account) => 
      account.type == AccountType.cash || 
      account.type == AccountType.debit
    ).toList();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SavingsWithdrawForm(
          goal: goal,
          accounts: filteredAccounts,
          onSuccess: () async {
            setState(() {}); // Refresh
            final unifiedProvider = context.read<UnifiedProviderV2>();
            // Refresh account balances
            await unifiedProvider.loadAccounts(forceServerRead: true);
            // Refresh savings goals (anasayfa için)
            await unifiedProvider.loadSavingsGoals();
          },
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, SavingsGoal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: 20),
              
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF007AFF)),
                title: Text(
                  'Düzenle',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditForm(context, goal);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.archive, color: Color(0xFFFF9500)),
                title: Text(
                  'Arşivle',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmArchive(context, goal);
                },
              ),
              
              if (goal.completionPercentage >= 100 && !goal.isCompleted)
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green.shade500),
                  title: Text(
                    'Tamamlandı Olarak İşaretle',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmComplete(context, goal);
                  },
                ),
              
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFFF4C4C)),
                title: Text(
                  'Sil',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, goal);
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiveGoalDialogTitle),
        content: Text(l10n.archiveGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9500)),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.archiveGoal(goal.id);
      
      if (success && mounted) {
        // UnifiedProviderV2'yi güncelle (anasayfa için)
        final unifiedProvider = context.read<UnifiedProviderV2>();
        await unifiedProvider.loadSavingsGoals();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.goalArchived),
            backgroundColor: const Color(0xFFFF9500),
          ),
        );
        Navigator.of(context).pop(); // Detail screen'den çık
      }
    }
  }

  Future<void> _confirmUnarchive(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unarchiveGoalDialogTitle),
        content: Text(l10n.unarchiveGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green.shade500),
            child: Text(l10n.unarchive),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.unarchiveGoal(goal.id);
      
      if (success && mounted) {
        // UnifiedProviderV2'yi güncelle (anasayfa için)
        final unifiedProvider = context.read<UnifiedProviderV2>();
        await unifiedProvider.loadSavingsGoals();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.goalActivated),
            backgroundColor: Colors.green.shade500,
          ),
        );
        Navigator.of(context).pop(); // Detail screen'den çık
      }
    }
  }

  Future<void> _confirmReactivate(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.activateGoalDialogTitle),
        content: Text(l10n.activateGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF007AFF)),
            child: Text(l10n.activate),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.reactivateGoal(goal.id);
      
      if (success && mounted) {
        // UnifiedProviderV2'yi güncelle (anasayfa için)
        final unifiedProvider = context.read<UnifiedProviderV2>();
        await unifiedProvider.loadSavingsGoals();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.goalReactivated),
            backgroundColor: const Color(0xFF007AFF),
          ),
        );
        Navigator.of(context).pop(); // Detail screen'den çık
      }
    }
  }

  Future<void> _confirmComplete(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.completeGoalDialogTitle),
        content: Text(l10n.completeGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green.shade500),
            child: Text(l10n.completedButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.completeGoal(goal.id);
      
      if (success && mounted) {
        // UnifiedProviderV2'yi güncelle (anasayfa için)
        final unifiedProvider = context.read<UnifiedProviderV2>();
        await unifiedProvider.loadSavingsGoals();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.goalCompletedSuccess),
            backgroundColor: Colors.green.shade500,
          ),
        );
        Navigator.of(context).pop(); // Detail screen'den çık
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGoalDialogTitle),
        content: Text(l10n.deleteGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF4C4C)),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.deleteGoal(goal.id);
      
      if (success && mounted) {
        // UnifiedProviderV2'yi güncelle (anasayfa için)
        final unifiedProvider = context.read<UnifiedProviderV2>();
        await unifiedProvider.loadSavingsGoals();
        
        Navigator.of(context).pop(); // Detail screen'den çık
      }
    }
  }
}

