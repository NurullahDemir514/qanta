import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design_system/transaction_design_system.dart';
import '../../../shared/models/transaction_model_v2.dart' as v2;
import 'package:google_fonts/google_fonts.dart';

class CardTransactionSection extends StatefulWidget {
  final String cardId;
  final String cardName;

  const CardTransactionSection({
    super.key,
    required this.cardId,
    required this.cardName,
  });

  @override
  State<CardTransactionSection> createState() => _CardTransactionSectionState();
}

class _CardTransactionSectionState extends State<CardTransactionSection> {
  @override
  void initState() {
    super.initState();
    // V2 provider handles all data loading automatically
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        debugPrint('🎯 CardTransactionSection using V2 provider for card: ${widget.cardName}');
        
        // Use v2 provider data - filter transactions by account
        final account = providerV2.getAccountById(widget.cardId);
        if (account == null) {
          return _buildEmptyState(isDark);
        }
        
        final v2Transactions = providerV2.getTransactionsByAccount(widget.cardId);
        final isLoadingV2 = providerV2.isLoadingTransactions;
        
        // V2 Content
        if (isLoadingV2 && v2Transactions.isEmpty) {
          return TransactionDesignSystem.buildLoadingSkeleton(
            isDark: isDark,
            itemCount: 3,
          );
        } else if (v2Transactions.isEmpty) {
          return _buildEmptyState(isDark);
        } else {
          // Use TransactionDesignSystem.buildTransactionList for consistent design
          final transactionWidgets = v2Transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            
            return _buildV2TransactionWidget(
              context,
              transaction, 
              isDark,
              isFirst: index == 0,
              isLast: index == v2Transactions.length - 1,
            );
          }).toList();
          
          return TransactionDesignSystem.buildTransactionList(
            transactions: transactionWidgets,
            isDark: isDark,
            emptyTitle: 'Henüz işlem yok',
            emptyDescription: 'Bu kart için henüz işlem bulunmuyor',
            emptyIcon: Icons.receipt_long_outlined,
          );
        }
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz işlem yok',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kart için henüz işlem bulunmuyor',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build individual transaction widget for V2 provider
  Widget _buildV2TransactionWidget(
    BuildContext context,
    v2.TransactionWithDetailsV2 transaction, 
    bool isDark, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Convert V2 transaction type to design system type
    TransactionType transactionType;
    switch (transaction.type) {
      case v2.TransactionType.income:
        transactionType = TransactionType.income;
        break;
      case v2.TransactionType.expense:
        transactionType = TransactionType.expense;
        break;
      case v2.TransactionType.transfer:
        transactionType = TransactionType.transfer;
        break;
    }

    // Get category info from provider
    final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
    final category = transaction.categoryId != null 
        ? providerV2.getCategoryById(transaction.categoryId!)
        : null;

    // Build title - sadece description göster (kategori adı gereksiz)
    String title = transaction.categoryName ?? transaction.description;

    // Format amount
    final amount = TransactionDesignSystem.formatAmount(transaction.amount, transactionType);

    // Format time
    final time = TransactionDesignSystem.formatTime(transaction.transactionDate);

    return TransactionDesignSystem.buildTransactionItem(
      title: title,
      subtitle: widget.cardName,
      amount: amount,
      time: time,
      type: transactionType,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      isDark: isDark,
      isFirst: isFirst,
      isLast: isLast,
      onLongPress: () {
        print('🔍 Long press detected on v2 card transaction: ${transaction.description}');
        HapticFeedback.mediumImpact();
        _showV2DeleteActionSheet(context, transaction);
      },
    );
  }

  /// Show delete action sheet for V2 transactions
  void _showV2DeleteActionSheet(BuildContext context, v2.TransactionWithDetailsV2 transaction) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'İşlemi Sil',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          '${transaction.description} işlemini silmek istediğinizden emin misiniz?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteV2Transaction(context, transaction);
            },
            child: Text(
              'Sil',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'İptal',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Delete V2 transaction
  Future<void> _deleteV2Transaction(BuildContext context, v2.TransactionWithDetailsV2 transaction) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      await providerV2.deleteTransaction(transaction.id);
      
      // Başarı mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silindi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Hata mesajı göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 