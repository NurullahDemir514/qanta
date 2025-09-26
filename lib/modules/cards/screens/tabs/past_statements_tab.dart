import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/unified_provider_v2.dart';
import '../../../../core/providers/statement_provider.dart';
import '../../../../shared/models/statement_summary.dart';
import '../../../../shared/widgets/statement_widgets.dart';
import '../../../../shared/models/transaction_model_v2.dart' as v2;

/// **Past Statements Tab - Refactored**
/// 
/// **Updated to use:**
/// - Shared StatementCard widget for consistency
/// - UnifiedProviderV2 for statement caching
/// - Optimistic UI updates for unmark payment
/// - Standardized loading and error states
/// - PDF export functionality (placeholder)
class PastStatementsTab extends StatefulWidget {
  final List<StatementSummary> pastStatements;
  final String cardId;
  final int statementDay;
  final Function(StatementSummary) onStatementTap;

  const PastStatementsTab({
    super.key,
    required this.pastStatements,
    required this.cardId,
    required this.statementDay,
    required this.onStatementTap,
  });

  @override
  State<PastStatementsTab> createState() => _PastStatementsTabState();
}

class _PastStatementsTabState extends State<PastStatementsTab> {
  final Set<String> _unmarkingStatements = {};

  @override
  void initState() {
    super.initState();
    // Past statements are loaded by StatementProvider
  }

  Future<void> _unmarkStatementAsPaid(StatementSummary statement) async {
    if (_unmarkingStatements.contains(statement.id)) return;

    setState(() {
      _unmarkingStatements.add(statement.id);
    });

    try {
      final provider = context.read<UnifiedProviderV2>();
      final success = await provider.unmarkStatementAsPaidOptimistic(
        widget.cardId,
        statement.period,
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ekstre ödenmedi olarak işaretlendi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF007AFF),
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
          _unmarkingStatements.remove(statement.id);
        });
      }
    }
  }

  void _showStatementActions(StatementSummary statement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Ekstre İşlemleri',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                
                // Actions
                _buildActionTile(
                  icon: Icons.download_outlined,
                  title: 'PDF İndir',
                  subtitle: 'Ekstreyi PDF olarak indir',
                  onTap: () {
                    Navigator.pop(context);
                    _exportToPdf(statement);
                  },
                  isDark: isDark,
                ),
                
                _buildActionTile(
                  icon: Icons.share_outlined,
                  title: 'Paylaş',
                  subtitle: 'Ekstreyi paylaş',
                  onTap: () {
                    Navigator.pop(context);
                    _shareStatement(statement);
                  },
                  isDark: isDark,
                ),
                
                _buildActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Ödenmedi Olarak İşaretle',
                  subtitle: 'Bu ekstrenin ödeme durumunu değiştir',
                  onTap: () {
                    Navigator.pop(context);
                    _unmarkStatementAsPaid(statement);
                  },
                  isDark: isDark,
                  isDestructive: true,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF453A) : (isDark ? Colors.white : const Color(0xFF1C1C1E));
    final subtitleColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);
    
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: subtitleColor,
        ),
      ),
      onTap: onTap,
    );
  }

  void _exportToPdf(StatementSummary statement) {
    // TODO: Implement PDF export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF export özelliği yakında eklenecek',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _shareStatement(StatementSummary statement) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paylaşma özelliği yakında eklenecek',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer3<ThemeProvider, UnifiedProviderV2, StatementProvider>(
      builder: (context, themeProvider, unifiedProvider, statementProvider, child) {
        // Get past statements from StatementProvider (real-time updates)
        final pastStatements = statementProvider.pastStatements.isNotEmpty
            ? statementProvider.pastStatements
            : unifiedProvider.getPastStatements(widget.cardId).isNotEmpty
                ? unifiedProvider.getPastStatements(widget.cardId)
                : widget.pastStatements;
        
        // Check loading state
        final isLoading = unifiedProvider.isLoadingStatements(widget.cardId);
        
        if (isLoading && pastStatements.isEmpty) {
          return StatementLoadingState(
            isDark: isDark,
            message: 'Geçmiş ekstreler yükleniyor...',
          );
        }
        
        if (pastStatements.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pastStatements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final statement = pastStatements[index];
            
            // Get transactions for this statement
            final transactions = _getStatementTransactions(statement);
            
            return StatementCard(
              statement: statement,
              themeProvider: themeProvider,
              isDark: isDark,
              isNextStatement: false,
              transactions: transactions,
              installments: statement.upcomingInstallments,
              showMonthlyChange: false,
              showTransactionCount: true,
              onTap: () => _showStatementActions(statement),
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

  /// **Empty state widget**
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz geçmiş ekstre bulunmuyor',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ekstre ödendikten sonra burada görünecek',
              style: GoogleFonts.inter(
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