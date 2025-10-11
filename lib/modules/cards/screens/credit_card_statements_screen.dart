import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import 'unified_statements_widget.dart';
import '../../../core/providers/statement_provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';

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
  State<CreditCardStatementsScreen> createState() =>
      _CreditCardStatementsScreenState();
}

class _CreditCardStatementsScreenState
    extends State<CreditCardStatementsScreen> {
  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final statementProvider = StatementProvider.instance;
      final unifiedProvider = Provider.of<UnifiedProviderV2>(
        context,
        listen: false,
      );

      // Set UnifiedProviderV2 reference
      statementProvider.setUnifiedProvider(unifiedProvider);

      // Load statements
      statementProvider.loadStatements(
        widget.cardId,
        widget.statementDay,
        dueDay: widget.dueDay,
      );
    });
    _setupTransactionListener();
  }

  void _setupTransactionListener() {
    // Real-time updates are now handled by StatementProvider
    // No need for additional listeners here
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statementProvider = StatementProvider.instance;
    final error = statementProvider.error;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF000000)
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: isDark
                ? const Color(0xFF000000)
                : const Color(0xFFF8F9FA),
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
                  AppLocalizations.of(context)!.statements,
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
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
          ),
          body: error != null
              ? _buildErrorState(error)
              : UnifiedStatementsWidget(
                  cardId: widget.cardId,
                  statementDay: widget.statementDay,
                  dueDay: widget.dueDay,
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                StatementProvider.instance.loadStatements(
                  widget.cardId,
                  widget.statementDay,
                );
              },
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
