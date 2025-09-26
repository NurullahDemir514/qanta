import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../core/providers/statement_provider.dart';
import '../../../../core/services/statement_service.dart';
import '../../../../shared/models/models_v2.dart';
import '../../../../shared/models/statement_summary.dart';
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
  bool _isMarkingPaid = false;

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

  Future<void> _markStatementAsPaid() async {
    if (widget.currentStatement == null || _isMarkingPaid) return;

    setState(() {
      _isMarkingPaid = true;
    });

    try {
      final provider = context.read<UnifiedProviderV2>();
      final success = await provider.markStatementAsPaidOptimistic(
        widget.cardId,
        widget.currentStatement!.period,
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ekstre ödendi olarak işaretlendi',
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
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ekstre işaretlenirken hata oluştu',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFFFF453A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bir hata oluştu: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFFF453A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingPaid = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer3<ThemeProvider, UnifiedProviderV2, StatementProvider>(
      builder: (context, themeProvider, unifiedProvider, statementProvider, child) {
        // Get current statement from StatementProvider (real-time updates)
        final currentStatement = statementProvider.currentStatement ?? 
                                 unifiedProvider.getCurrentStatement(widget.cardId) ?? 
                                 widget.currentStatement;

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
          
          // Mark as paid button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isMarkingPaid ? null : _markStatementAsPaid,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isMarkingPaid
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Ödendi Olarak İşaretle',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
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