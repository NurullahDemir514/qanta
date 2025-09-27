import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../core/providers/statement_provider.dart';
import '../../../../core/services/statement_service.dart';
import '../../../../shared/models/models_v2.dart';
import '../../../../shared/models/statement_summary.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/statement_widgets.dart';
import '../../../../shared/models/transaction_model_v2.dart' as v2;

/// **Active Statement Tab - Refactored**
/// 
/// **Updated to use:**
/// - Shared StatementCard widget for consistency
/// - UnifiedProviderV2 for statement caching
/// - Optimistic UI updates for payments
/// - Standardized loading and error states
class ActiveStatementTab extends StatefulWidget {
  final StatementSummary? currentStatement;
  final String cardId;
  final int statementDay;

  const ActiveStatementTab({
    super.key,
    required this.currentStatement,
    required this.cardId,
    required this.statementDay,
  });

  @override
  State<ActiveStatementTab> createState() => _ActiveStatementTabState();
}

class _ActiveStatementTabState extends State<ActiveStatementTab> {

  @override
  void initState() {
    super.initState();
    // Load current statement if not provided
    if (widget.currentStatement == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentStatement();
      });
    }
  }

  Future<void> _loadCurrentStatement() async {
    final provider = context.read<UnifiedProviderV2>();
    await provider.loadCurrentStatement(widget.cardId, widget.statementDay);
  }

  void _markStatementAsPaid() {
    if (widget.currentStatement == null) return;
    
    // Just show the payment confirmation bottom sheet
    _showPaymentSuccessBottomSheet();
  }

  /// Check if payment is allowed for current statement
  bool _isPaymentAllowed(StatementSummary statement) {
    final now = DateTime.now().toUtc();
    final periodEnd = statement.period.endDate.toUtc();
    final dueDate = statement.period.dueDate.toUtc();
    
    // Payment is allowed between period end and due date (inclusive)
    return now.isAfter(periodEnd) && now.isBefore(dueDate.add(const Duration(days: 1)));
  }

  /// Check if statement is overdue
  bool _isStatementOverdue(StatementSummary statement) {
    final now = DateTime.now().toUtc();
    final dueDate = statement.period.dueDate.toUtc();
    
    return now.isAfter(dueDate);
  }

  /// Check if statement is in grace period (after due date but within grace period)
  bool _isInGracePeriod(StatementSummary statement) {
    final now = DateTime.now().toUtc();
    final dueDate = statement.period.dueDate.toUtc();
    final gracePeriodEnd = dueDate.add(const Duration(days: 5)); // 5 days grace period
    
    return now.isAfter(dueDate) && now.isBefore(gracePeriodEnd);
  }

  /// Show payment success bottom sheet with installment details
  void _showPaymentSuccessBottomSheet() {
    final statementProvider = StatementProvider.instance;
    final currentStatement = statementProvider.currentStatement;
    
    if (currentStatement == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentSuccessSheet(currentStatement),
    );
  }

  /// Build payment success bottom sheet
  Widget _buildPaymentSuccessSheet(StatementSummary statement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 32,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Success title
            Text(
              'Ekstre Ödendi!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Success message
            Text(
              AppLocalizations.of(context)?.statementSuccessfullyPaid ?? 'Statement successfully marked as paid',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Payment details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Total amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ödenen Tutar',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      Text(
                        Provider.of<ThemeProvider>(context, listen: false).formatAmount(statement.totalAmount),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Payment date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ödeme Tarihi',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Installment details if any
            if (statement.upcomingInstallments.isNotEmpty) ...[
              const SizedBox(height: 20),
              
              // Installment section title
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gelecek Taksitler',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Installment list
              ...statement.upcomingInstallments.take(3).map((installment) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Installment number
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${installment.installmentNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Installment details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              installment.displaySubtitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy', 'tr_TR').format(installment.dueDate),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Text(
                        Provider.of<ThemeProvider>(context, listen: false).formatAmount(installment.amount),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
              
              if (statement.upcomingInstallments.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '+${statement.upcomingInstallments.length - 3} taksit daha',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: 24),
            
            // Payment confirmation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmPayment(statement),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Ödemeyi Onayla',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm payment and process the actual payment
  Future<void> _confirmPayment(StatementSummary statement) async {
    // Close bottom sheet first
    Navigator.of(context).pop();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
        ),
      ),
    );

    try {
      // Process the actual payment
      final provider = context.read<UnifiedProviderV2>();
      final success = await provider.processStatementPayment(
        statement.cardId,
        statement.period,
        statement.totalAmount,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ödeme başarıyla gerçekleştirildi!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } 
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ödeme işlemi sırasında hata oluştu',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFFF4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<ThemeProvider, UnifiedProviderV2>(
      builder: (context, themeProvider, unifiedProvider, child) {
        // Get current statement from StatementProvider singleton (real-time updates)
        final statementProvider = StatementProvider.instance;
        final currentStatement = statementProvider.currentStatement;
        

        if (currentStatement == null) {
          return const SizedBox.shrink(); // Hide if no data
        }

        // Get transactions and installments
        final transactions = _getStatementTransactions(currentStatement);
        final installments = currentStatement.upcomingInstallments;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statement Card
              StatementCard(
                statement: currentStatement,
                themeProvider: themeProvider,
                isDark: isDark,
                isNextStatement: false,
                transactions: transactions,
                installments: installments,
                showMonthlyChange: false,
                showTransactionCount: true,
              ),
              
              const SizedBox(height: 24),
              
              // Payment Actions
              if (!currentStatement.isPaid) ...[
                _buildPaymentSection(currentStatement, themeProvider, isDark),
                const SizedBox(height: 16),
              ],
              
              // Statement Details
              _buildStatementDetails(currentStatement, themeProvider, isDark),
            ],
          ),
        );
      },
    );
  }

  /// **Get transactions for this statement period**
  List<v2.TransactionWithDetailsV2> _getStatementTransactions(StatementSummary statement) {
    final provider = context.read<UnifiedProviderV2>();
    final allTransactions = provider.transactions;
    
    // Filter transactions for this statement period
    return allTransactions.where((transaction) {
      // Check if transaction is within statement period
      final isInPeriod = transaction.transactionDate.isAfter(statement.period.startDate) &&
                        transaction.transactionDate.isBefore(statement.period.endDate.add(const Duration(days: 1)));
      
      // Check if transaction is for this card
      final isForThisCard = transaction.sourceAccountId == widget.cardId;
      
      return isInPeriod && isForThisCard;
    }).toList();
  }

  /// **Payment section widget**
  Widget _buildPaymentSection(StatementSummary statement, ThemeProvider themeProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ödeme İşlemleri',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ödenecek Tutar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
              Text(
                themeProvider.formatAmount(statement.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF453A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payment buttons and messages based on statement status
          if (!StatementProvider.instance.currentStatement!.isPaid) ...[
            // Normal payment period
            if (_isPaymentAllowed(StatementProvider.instance.currentStatement!))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markStatementAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ödendi Olarak İşaretle',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            // Grace period payment
            else if (_isInGracePeriod(StatementProvider.instance.currentStatement!))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markStatementAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Gecikmiş Ödeme Yap',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            // Overdue payment
            else if (_isStatementOverdue(StatementProvider.instance.currentStatement!))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markStatementAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4C4C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Gecikmiş Ödeme Yap',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            // Payment not allowed message
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ödeme yapabilmek için ekstre kesim tarihini beklemeniz gerekiyor',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
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

  /// **Statement details section**
  Widget _buildStatementDetails(StatementSummary statement, ThemeProvider themeProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ekstre Detayları',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          
          // Statement period
          _buildDetailRow(
            'Ekstre Dönemi',
            statement.period.periodRangeText,
            isDark,
          ),
          
          // Due date
          _buildDetailRow(
            'Son Ödeme Tarihi',
            statement.period.dueDateText,
            isDark,
          ),
          
          // Days until due
          _buildDetailRow(
            'Kalan Gün',
            statement.period.daysUntilDue > 0 
                ? '${statement.period.daysUntilDue} gün'
                : statement.period.isOverdue 
                    ? '${statement.period.daysOverdue} gün gecikme'
                    : 'Bugün',
            isDark,
          ),
          
          // Transaction count
          _buildDetailRow(
            'İşlem Sayısı',
            '${statement.transactionCount} işlem',
            isDark,
          ),
          
          // Installment count
          if (statement.upcomingInstallments.isNotEmpty)
            _buildDetailRow(
              'Taksit Sayısı',
              '${statement.upcomingInstallments.length} taksit',
              isDark,
            ),
        ],
      ),
    );
  }

  /// **Detail row widget**
  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}