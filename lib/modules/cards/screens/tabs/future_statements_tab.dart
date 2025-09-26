import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../core/providers/statement_provider.dart';
import '../../../../shared/models/statement_summary.dart';
import '../../../../shared/widgets/statement_widgets.dart';
import '../../../../shared/models/transaction_model_v2.dart' as v2;

/// **Future Statements Tab - Refactored**
/// 
/// **Updated to use:**
/// - Shared StatementCard widget for consistency
/// - UnifiedProviderV2 for statement caching
/// - Standardized loading and error states
/// - Optimized data loading with cache
class FutureStatementsTab extends StatefulWidget {
  final List<StatementSummary> futureStatements;
  final String cardId;
  final int statementDay;

  const FutureStatementsTab({
    super.key,
    required this.futureStatements,
    required this.cardId,
    required this.statementDay,
  });

  @override
  State<FutureStatementsTab> createState() => _FutureStatementsTabState();
}

class _FutureStatementsTabState extends State<FutureStatementsTab> {
  @override
  void initState() {
    super.initState();
    // Future statements are loaded by StatementProvider
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer3<ThemeProvider, UnifiedProviderV2, StatementProvider>(
      builder: (context, themeProvider, unifiedProvider, statementProvider, child) {
        // Get future statements from StatementProvider (real-time updates)
        final futureStatements = statementProvider.futureStatements.isNotEmpty
            ? statementProvider.futureStatements
            : unifiedProvider.getFutureStatements(widget.cardId).isNotEmpty
                ? unifiedProvider.getFutureStatements(widget.cardId)
                : widget.futureStatements;
        
        // Check loading state
        final isLoading = unifiedProvider.isLoadingStatements(widget.cardId);
        
        if (isLoading && futureStatements.isEmpty) {
          return StatementLoadingState(
            isDark: isDark,
            message: 'Gelecek ekstreler yükleniyor...',
          );
        }
        
        if (futureStatements.isEmpty) {
          return _buildEmptyState(isDark);
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: futureStatements.length,
          itemBuilder: (context, index) {
            final statement = futureStatements[index];
            final isFirst = index == 0;
            
            // Get transactions and installments for this statement
            final transactions = _getStatementTransactions(statement);
            final installments = statement.upcomingInstallments;
            
            // Debug: Log installments for this statement
            print('🔍 Future Statement Debug:');
            print('   Period: ${statement.period.startDate} to ${statement.period.endDate}');
            print('   Total Amount: ${statement.totalAmount}');
            print('   Installments count: ${installments.length}');
            for (final installment in installments) {
              print('     - ${installment.description}: ${installment.amount} (${installment.installmentNumber}/${installment.totalInstallments})');
            }
            
            // Calculate previous month total for monthly change badge
            final previousMonthTotal = _getPreviousMonthTotal(futureStatements, index);
            
            return Column(
              children: [
                StatementCard(
                  statement: statement,
                  themeProvider: themeProvider,
                  isDark: isDark,
                  isNextStatement: isFirst,
                  transactions: transactions,
                  installments: installments,
                  previousMonthTotal: previousMonthTotal,
                  showMonthlyChange: true,
                  showTransactionCount: false,
                ),
                if (index < futureStatements.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  /// **Get transactions for this statement period**
  List<v2.TransactionWithDetailsV2> _getStatementTransactions(StatementSummary statement) {
    final provider = context.read<UnifiedProviderV2>();
    final allTransactions = provider.transactions;
    
    // For future statements, we typically don't have actual transactions yet
    // but we might have some planned or recurring transactions
    return allTransactions.where((transaction) {
      // Check if transaction is within statement period
      final isInPeriod = transaction.transactionDate.isAfter(statement.period.startDate) &&
                        transaction.transactionDate.isBefore(statement.period.endDate.add(const Duration(days: 1)));
      
      // Check if transaction is for this card
      final isForThisCard = transaction.sourceAccountId == widget.cardId;
      
      return isInPeriod && isForThisCard;
    }).toList();
  }

  /// **Get previous month total for monthly change calculation**
  double? _getPreviousMonthTotal(List<StatementSummary> statements, int currentIndex) {
    if (currentIndex >= statements.length - 1) return null;
    
    // Find the previous statement (statement after current in the list since list is chronological)
    try {
      final previousStatement = statements.firstWhere(
        (s) => s.period.dueDate.isBefore(statements[currentIndex].period.dueDate),
      );
      return previousStatement.totalWithInstallments;
    } catch (_) {
      return null;
    }
  }

  /// **Empty state widget**
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz gelecek ekstre bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Taksitli işlemler eklendikçe gelecek ekstreler burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Refresh button removed - real-time updates enabled
          ],
        ),
      ),
    );
  }
} 