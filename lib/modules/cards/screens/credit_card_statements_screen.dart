import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/services/statement_service.dart';
import '../../../core/services/transaction_service_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/statement_summary.dart';
import 'tabs/active_statement_tab.dart';
import 'tabs/past_statements_tab.dart';
import 'tabs/future_statements_tab.dart';
import '../../../core/providers/statement_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';

class CreditCardStatementsScreen extends StatefulWidget {
  final String cardId;
  final String cardName;
  final String bankName;
  final int statementDay;
  final int? dueDay;

  const CreditCardStatementsScreen({
    super.key,
    required this.cardId,
    required this.cardName,
    required this.bankName,
    required this.statementDay,
    this.dueDay,
  });

  @override
  State<CreditCardStatementsScreen> createState() => _CreditCardStatementsScreenState();
}

class _CreditCardStatementsScreenState extends State<CreditCardStatementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _transactionSubscription;
  late final ValueNotifier<bool?> optimisticPaidNotifier;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    optimisticPaidNotifier = ValueNotifier<bool?>(null);
    Future.microtask(() {
      final statementProvider = Provider.of<StatementProvider>(context, listen: false);
      final unifiedProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Set UnifiedProviderV2 reference
      statementProvider.setUnifiedProvider(unifiedProvider);
      
      // Load statements
      statementProvider.loadStatements(widget.cardId, widget.statementDay, dueDay: widget.dueDay);
    });
    _setupTransactionListener();
  }

  void _setupTransactionListener() {
    // Real-time updates are now handled by StatementProvider
    // No need for additional listeners here
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transactionSubscription?.cancel();
    optimisticPaidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statementProvider = Provider.of<StatementProvider>(context);
    final isLoading = statementProvider.isLoading;
    final error = statementProvider.error;
    final currentStatement = statementProvider.currentStatement;
    final previousStatement = statementProvider.previousStatement;
    final futureStatements = statementProvider.futureStatements;
    final paid = optimisticPaidNotifier.value ?? currentStatement?.isPaid ?? false;
    final hasAnyData = currentStatement != null || previousStatement != null || futureStatements.isNotEmpty;
    final isInitialLoading = !hasAnyData && error == null;
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
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const BoxDecoration(),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
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
                Tab(text: 'Dönem İçi'),
                Tab(text: 'Son Ekstre'),
                Tab(text: 'Bekleyen Ekstre'),
              ],
            ),
          ),
          body: error != null
              ? _buildErrorState(error)
              : TabBarView(
                      controller: _tabController,
                      children: [
                        ActiveStatementTab(
                          currentStatement: currentStatement,
                          cardId: widget.cardId,
                          statementDay: widget.statementDay,
                        ),
                        PastStatementsTab(
                          pastStatements: Provider.of<StatementProvider>(context).pastStatements,
                          cardId: widget.cardId,
                          statementDay: widget.statementDay,
                          onStatementTap: (StatementSummary statement) {
                            _showStatementDetail(statement);
                          },
                        ),
                        FutureStatementsTab(
                          futureStatements: futureStatements,
                          cardId: widget.cardId,
                          statementDay: widget.statementDay,
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildErrorState(String? error) {
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
              error ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<StatementProvider>(context, listen: false)
                    .loadStatements(widget.cardId, widget.statementDay);
              },
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatementDetail(StatementSummary statement) {
    debugPrint('[STATEMENT] _showStatementDetail: $statement');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${statement.period.periodText} ekstre detayı')),
    );
  }
} 