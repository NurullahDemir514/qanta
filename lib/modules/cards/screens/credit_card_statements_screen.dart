import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/services/statement_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/services/category_icon_service.dart';

class CreditCardStatementsScreen extends StatefulWidget {
  final String cardId;
  final String cardName;
  final String bankName;
  final int statementDay;

  const CreditCardStatementsScreen({
    super.key,
    required this.cardId,
    required this.cardName,
    required this.bankName,
    required this.statementDay,
  });

  @override
  State<CreditCardStatementsScreen> createState() => _CreditCardStatementsScreenState();
}

class _CreditCardStatementsScreenState extends State<CreditCardStatementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  StatementSummary? _currentStatement;
  StatementSummary? _previousStatement;
  List<StatementSummary> _futureStatements = [];
  
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Debug: Dönem hesaplamalarını kontrol et
      StatementService.debugStatementPeriods(widget.statementDay);
      
      // Debug: Veritabanı giderlerini kontrol et
      await StatementService.debugDatabaseTransactions(widget.cardId);
      
      // Dönemleri hesapla
      final currentPeriod = StatementService.getCurrentStatementPeriod(widget.statementDay);
      final previousPeriod = StatementService.getPreviousStatementPeriod(widget.statementDay);
      final futurePeriods = await StatementService.getFuturePeriodsUntilLastInstallment(widget.cardId, widget.statementDay);

      // Paralel olarak mevcut ve geçmiş ekstreleri yükle
      final currentAndPreviousResults = await Future.wait([
        StatementService.calculateStatementSummary(widget.cardId, currentPeriod),
        StatementService.calculateStatementSummary(widget.cardId, previousPeriod),
      ]);

      // Gelecek dönemler için ekstreleri hesapla
      final futureResults = await Future.wait(
        futurePeriods.map((period) => StatementService.calculateStatementSummary(widget.cardId, period))
      );

      setState(() {
        _currentStatement = currentAndPreviousResults[0];
        _previousStatement = currentAndPreviousResults[1];
        _futureStatements = futureResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ekstreler',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  widget.cardName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const BoxDecoration(), // Çizgiyi tamamen kaldır
              indicatorColor: Colors.transparent, // Çizgi rengini şeffaf yap
              dividerColor: Colors.transparent, // Alt çizgiyi kaldır
              labelColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
              unselectedLabelColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              labelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Bu Dönem'),
                Tab(text: 'Kesilmiş'),
                Tab(text: 'Gelecek'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveStatementTab(themeProvider, isDark),
                        _buildIssuedStatementTab(themeProvider, isDark),
                        _buildFutureStatementTab(themeProvider, isDark),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ekstre bilgileri yüklenirken hata oluştu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStatements,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatementTab(ThemeProvider themeProvider, bool isDark) {
    if (_currentStatement == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final statement = _currentStatement!;
    
    return RefreshIndicator(
      onRefresh: _loadStatements,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bu dönem ekstre özeti
            _buildStatementSummaryCard(
              title: 'Bu Dönem Harcamaları',
              period: statement.period.periodText,
              totalSpent: statement.totalSpent,
              dueDate: statement.period.dueDateText,
              status: statement.isPaid 
                  ? 'Ödendi'
                  : statement.period.daysUntilDue > 0 
                      ? '${statement.period.daysUntilDue} gün kaldı'
                      : 'Vadesi geçti',
              statusColor: statement.isPaid
                  ? const Color(0xFF34D399)
                  : statement.period.daysUntilDue > 7 
                      ? const Color(0xFF007AFF)
                      : statement.period.daysUntilDue > 0
                          ? const Color(0xFFFF9500)
                          : const Color(0xFFFF453A),
              themeProvider: themeProvider,
              isDark: isDark,
            ),
            
            const SizedBox(height: 16),
            
            // Hızlı aksiyonlar
            _buildQuickActionsCard(themeProvider, isDark),
            
            const SizedBox(height: 16),
            
            // İşlemler listesi
            _buildTransactionsList(statement.transactions, themeProvider, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuedStatementTab(ThemeProvider themeProvider, bool isDark) {
    if (_previousStatement == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Şimdilik sadece önceki ekstre gösteriyoruz
    // Gelecekte birden fazla geçmiş ekstre için ListView.builder kullanılabilir
    return RefreshIndicator(
      onRefresh: _loadStatements,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPastStatementCard(
              period: _previousStatement!.period.periodText,
              totalSpent: _previousStatement!.totalSpent,
              status: _previousStatement!.isPaid ? 'Ödendi' : 'Ödeme Bekliyor',
              themeProvider: themeProvider,
              isDark: isDark,
              onTap: () => _showStatementDetail(_previousStatement!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureStatementTab(ThemeProvider themeProvider, bool isDark) {
    if (_futureStatements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadStatements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _futureStatements.length,
        itemBuilder: (context, index) {
          final statement = _futureStatements[index];
          final isFirst = index == 0;
          
          return Column(
            children: [
              _buildFutureStatementCard(
                statement: statement,
                themeProvider: themeProvider,
                isDark: isDark,
                isNext: isFirst,
              ),
              if (index < _futureStatements.length - 1)
                const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatementSummaryCard({
    required String title,
    required String period,
    required double totalSpent,
    required String dueDate,
    required String status,
    required Color statusColor,
    required ThemeProvider themeProvider,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Dönem: $period',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Harcama',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CurrencyUtils.buildCurrencyText(
                      themeProvider.formatAmount(totalSpent),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                      currency: themeProvider.currency,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Son Ödeme',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueDate,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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

  Widget _buildQuickActionsCard(ThemeProvider themeProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: _currentStatement?.isPaid == true 
                  ? Icons.check_circle_outline 
                  : Icons.credit_card_outlined,
              title: _currentStatement?.isPaid == true 
                  ? 'Ödeme İptal' 
                  : 'Ödendi İşaretle',
              color: _currentStatement?.isPaid == true 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF34D399),
              onTap: _togglePaymentStatus,
              isDark: isDark,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<TransactionWithDetailsV2> transactions,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu dönemde işlem bulunmuyor',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Harcamalar (${transactions.length})',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
          
          // TransactionDesignSystem kullanarak işlemleri göster
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            final isFirst = index == 0;
            final isLast = index == transactions.length - 1;
            
            // Kategori ikonu ve rengini al
            final categoryIcon = CategoryIconService.getIcon(transaction.categoryName ?? 'other');
            final categoryColor = CategoryIconService.getColorFromMap(transaction.categoryName ?? 'other');
            
            return Column(
              children: [
                TransactionDesignSystem.buildTransactionItemWithIcon(
                  title: transaction.description,
                  subtitle: transaction.categoryName != null 
                      ? '${transaction.categoryName} • ${_formatDate(transaction.transactionDate)}'
                      : _formatDate(transaction.transactionDate),
                  amount: '-${themeProvider.formatAmount(transaction.amount)}',
                  time: '',
                  isDark: isDark,
                  specificIcon: categoryIcon,
                  specificIconColor: categoryColor,
                  specificBackgroundColor: categoryColor.withValues(alpha: 0.1),
                  specificAmountColor: const Color(0xFFFF453A),
                  onTap: () {},
                  isFirst: isFirst,
                  isLast: isLast,
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Container(
                      height: 0.5,
                      color: isDark 
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE5E5EA),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFutureStatementCard({
    required StatementSummary statement,
    required ThemeProvider themeProvider,
    required bool isDark,
    required bool isNext,
  }) {
    final hasInstallments = statement.upcomingInstallments.isNotEmpty;
    final totalAmount = statement.totalWithInstallments;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isNext ? Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.3),
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve durum
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNext ? 'Gelecek Dönem' : statement.period.periodText,
                      style: GoogleFonts.inter(
                        fontSize: isNext ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(height: 4),
                      Text(
                        statement.period.periodText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${statement.period.daysUntilDue} gün kaldı',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tutar bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tahmini Toplam:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
              CurrencyUtils.buildCurrencyText(
                themeProvider.formatAmount(totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                currency: themeProvider.currency,
              ),
            ],
          ),
          
          if (hasInstallments) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taksit Tutarı:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
                CurrencyUtils.buildCurrencyText(
                  themeProvider.formatAmount(statement.upcomingInstallmentAmount),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                  currency: themeProvider.currency,
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Son ödeme tarihi
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              const SizedBox(width: 8),
              Text(
                'Son ödeme: ${statement.period.dueDateText}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
          
          // Taksit detayları
          if (hasInstallments) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu dönemde vadesi gelen taksitler (${statement.upcomingInstallments.length}):',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...statement.upcomingInstallments.take(3).map((installment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '• ${installment.description}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          installment.installmentText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (statement.upcomingInstallments.length > 3)
                    Text(
                      '+ ${statement.upcomingInstallments.length - 3} taksit daha',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingInstallmentsCard(
    List<UpcomingInstallment> installments,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gelecek Taksitler (${installments.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...installments.map((installment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installment.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${installment.installmentText} • ${_formatDate(installment.dueDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
                  ),
                ),
                CurrencyUtils.buildCurrencyText(
                  themeProvider.formatAmount(installment.amount),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                  currency: themeProvider.currency,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPastStatementCard({
    required String period,
    required double totalSpent,
    required String status,
    required ThemeProvider themeProvider,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CurrencyUtils.buildCurrencyText(
                  themeProvider.formatAmount(totalSpent),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                  currency: themeProvider.currency,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF34D399),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month]}';
  }

  void _showStatementDetail(StatementSummary statement) {
    // TODO: Implement detailed statement view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${statement.period.periodText} ekstre detayı')),
    );
  }

  void _togglePaymentStatus() async {
    if (_currentStatement == null) return;
    
    final statement = _currentStatement!;
    
    try {
      bool success;
      String message;
      
      if (statement.isPaid) {
        // Ödeme işaretini kaldır
        success = await StatementService.unmarkStatementAsPaid(widget.cardId, statement.period);
        message = success ? 'Ödeme işareti kaldırıldı' : 'İşlem başarısız';
      } else {
        // Ödendi olarak işaretle
        success = await StatementService.markStatementAsPaid(widget.cardId, statement.period);
        message = success ? 'Ekstre ödendi olarak işaretlendi' : 'İşlem başarısız';
      }
      
      if (success) {
        // Ekstreleri yeniden yükle
        await _loadStatements();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF34D399),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFFF453A),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFFF453A),
          ),
        );
      }
    }
  }


} 