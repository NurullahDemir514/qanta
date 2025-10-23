import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/providers/statement_provider.dart';
import '../../../shared/models/statement_summary.dart';
import '../../../shared/widgets/statement_widgets.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import '../../../l10n/app_localizations.dart';

/// **Unified Statements Widget**
///
/// Combines all statement types (current, past, future) into a single scrollable view
/// with section headers for better organization and user experience.
class UnifiedStatementsWidget extends StatefulWidget {
  final String cardId;
  final int statementDay;
  final int? dueDay;

  const UnifiedStatementsWidget({
    super.key,
    required this.cardId,
    required this.statementDay,
    this.dueDay,
  });

  @override
  State<UnifiedStatementsWidget> createState() =>
      _UnifiedStatementsWidgetState();
}

class _UnifiedStatementsWidgetState extends State<UnifiedStatementsWidget> {
  final Set<String> _unmarkingStatements = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<ThemeProvider, UnifiedProviderV2, StatementProvider>(
      builder:
          (context, themeProvider, unifiedProvider, statementProvider, child) {
            // Get all statements from StatementProvider (real-time updates)
            final currentStatement = statementProvider.currentStatement;
            final pastStatements = statementProvider.pastStatements;
            final futureStatements = statementProvider.futureStatements;

            // Check loading state
            final isLoading = statementProvider.isLoading;

            if (isLoading &&
                currentStatement == null &&
                pastStatements.isEmpty &&
                futureStatements.isEmpty) {
              return StatementLoadingState(
                isDark: isDark,
                message: AppLocalizations.of(context)!.loadingStatements,
              );
            }

            if (currentStatement == null &&
                pastStatements.isEmpty &&
                futureStatements.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Past Statements Section - Moved to top
                  if (pastStatements.isNotEmpty) ...[
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.pastStatements,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildPastStatementsHorizontalView(pastStatements, themeProvider, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Current Statement Section
                  if (currentStatement != null) ...[
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.currentStatement,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildCurrentStatementCard(
                      currentStatement,
                      pastStatements,
                      themeProvider,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Future Statements Section
                  if (futureStatements.isNotEmpty) ...[
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.futureStatements,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    ...futureStatements.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final statement = entry.value;
                        
                        // Bir önceki ay: index 0 ise current statement, değilse bir önceki future statement
                        double? previousMonthTotal;
                        if (index == 0) {
                          previousMonthTotal = currentStatement?.remainingAmount;
                        } else {
                          previousMonthTotal = futureStatements[index - 1].remainingAmount;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFutureStatementCard(
                            statement,
                            previousMonthTotal,
                            themeProvider,
                            isDark,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }

  /// **Section Header Widget**
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
      ),
    );
  }

  /// **Current Statement Card**
  Widget _buildCurrentStatementCard(
    StatementSummary statement,
    List<StatementSummary> pastStatements,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final installments = statement.upcomingInstallments;
    
    // Bir önceki ayın toplam tutarını al (en son past statement)
    final previousMonthTotal = pastStatements.isNotEmpty 
        ? pastStatements.first.remainingAmount 
        : null;

    return StatementCard(
      statement: statement,
      themeProvider: themeProvider,
      isDark: isDark,
      isNextStatement: false,
      transactions: const [],
      installments: installments,
      previousMonthTotal: previousMonthTotal,
      showMonthlyChange: true,
      showTransactionCount: true,
    );
  }

  /// **Past Statement Card**
  Widget _buildPastStatementCard(
    StatementSummary statement,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final installments = statement.upcomingInstallments;

    return StatementCard(
      statement: statement,
      themeProvider: themeProvider,
      isDark: isDark,
      isNextStatement: false,
      transactions: const [],
      installments: installments,
      showMonthlyChange: false,
      showTransactionCount: true,
    );
  }

  /// **Future Statement Card**
  Widget _buildFutureStatementCard(
    StatementSummary statement,
    double? previousMonthTotal,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final installments = statement.upcomingInstallments;

    return StatementCard(
      statement: statement,
      themeProvider: themeProvider,
      isDark: isDark,
      isNextStatement: true,
      transactions: const [],
      installments: installments,
      previousMonthTotal: previousMonthTotal,
      showMonthlyChange: true,
      showTransactionCount: true,
    );
  }





  /// **Build horizontal past statements view**
  Widget _buildPastStatementsHorizontalView(
    List<StatementSummary> pastStatements,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pastStatements.asMap().entries.map((entry) {
          final index = entry.key;
          final statement = entry.value;
          final transactions = _getStatementTransactions(statement);
          
          // Bir önceki ayın toplam tutarını al (bir sonraki index, çünkü liste ters sırada)
          final previousMonthTotal = index < pastStatements.length - 1
              ? pastStatements[index + 1].remainingAmount
              : null;
          
          return Container(
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            margin: const EdgeInsets.only(right: 16),
            child: StatementCard(
              statement: statement,
              themeProvider: themeProvider,
              isDark: isDark,
              isNextStatement: false,
              transactions: transactions,
              installments: statement.upcomingInstallments,
              previousMonthTotal: previousMonthTotal,
              showMonthlyChange: true,
              showTransactionCount: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// **Get transactions for this statement period**
  List<v2.TransactionWithDetailsV2> _getStatementTransactions(
    StatementSummary statement,
  ) {
    final provider = context.read<UnifiedProviderV2>();
    final allTransactions = provider.transactions;

    // Filter transactions for this statement period
    return allTransactions.where((transaction) {
      // Check if transaction is within statement period
      final isInPeriod =
          transaction.transactionDate.isAfter(statement.period.startDate) &&
          transaction.transactionDate.isBefore(
            statement.period.endDate.add(const Duration(days: 1)),
          );

      // Check if transaction is for this card
      final isForThisCard = transaction.sourceAccountId == widget.cardId;

      return isInPeriod && isForThisCard;
    }).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
              Icons.receipt_long_outlined,
                size: 40,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noStatementsYet,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz ekstre bulunmuyor. İşlemleriniz burada görünecek.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}