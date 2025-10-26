import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/unified_category_model.dart';
import 'package:intl/intl.dart';

/// Toplu işlem onay ekranı
/// SOLID: Single Responsibility - Sadece bulk transaction onayı
class BulkTransactionConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const BulkTransactionConfirmationScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<BulkTransactionConfirmationScreen> createState() =>
      _BulkTransactionConfirmationScreenState();
}

class _BulkTransactionConfirmationScreenState
    extends State<BulkTransactionConfirmationScreen> {
  late List<_EditableTransaction> _editableTransactions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Her transaction için editable wrapper oluştur
    _editableTransactions = widget.transactions.map((txn) {
      return _EditableTransaction(
        type: txn['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        amount: (txn['amount'] as num?)?.toDouble() ?? 0.0,
        category: txn['category'] as String? ?? '',
        description: txn['description'] as String? ?? '',
        date: _parseDate(txn['date']),
        accountId: null, // Kullanıcı seçecek
      );
    }).toList();
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        final parsed = DateTime.parse(dateValue);
        // Prevent UTC conversion
        return DateTime(parsed.year, parsed.month, parsed.day, 
                       parsed.hour, parsed.minute, parsed.second);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Future<void> _saveSelectedTransactions() async {
    // Validation: Hesap seçilmiş mi?
    final invalidTransactions = _editableTransactions
        .where((t) => t.accountId == null || t.accountId!.isEmpty)
        .toList();
    if (invalidTransactions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectAccount),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<UnifiedProviderV2>();

      // Her transaction'ı kaydet
      for (final txn in _editableTransactions) {
        // Kategori ID'sini bul veya yeni kategori oluştur
        String categoryId;
        
        // Önce mevcut kategorilerde ara (case-insensitive)
        final existingCategory = provider.categories.where(
          (cat) => cat.name.toLowerCase() == txn.category.toLowerCase(),
        ).firstOrNull;
        
        if (existingCategory != null) {
          categoryId = existingCategory.id;
        } else {
          // Kategori yoksa yeni oluştur
          debugPrint('📋 Creating new category: ${txn.category}');
          final newCategory = await provider.createCategory(
            type: txn.type == TransactionType.income
                ? CategoryType.income
                : CategoryType.expense,
            name: txn.category,
          );
          categoryId = newCategory.id;
        }

        await provider.createTransaction(
          type: txn.type,
          amount: txn.amount,
          description: txn.description,
          sourceAccountId: txn.accountId!,
          categoryId: categoryId,
          transactionDate: txn.date,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Başarılı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_editableTransactions.length} ${AppLocalizations.of(context)!.transactionsSaved}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingTransactions),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = _editableTransactions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.confirmTransactions,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header: Toplam işlem sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF007AFF).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF007AFF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$totalCount ${l10n.transactionsSelected}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Transaction list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _editableTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _EditableTransactionCard(
                  transaction: _editableTransactions[index],
                  onChanged: (updated) {
                    setState(() {
                      _editableTransactions[index] = updated;
                    });
                  },
                );
              },
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSelectedTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.saveSelected,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable Transaction Data Class
class _EditableTransaction {
  TransactionType type;
  double amount;
  String category;
  String description;
  DateTime date;
  String? accountId;

  _EditableTransaction({
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.accountId,
  });
}

/// Editable Transaction Card Widget
/// SOLID: Single Responsibility - Sadece tek bir transaction'ı düzenle
class _EditableTransactionCard extends StatefulWidget {
  final _EditableTransaction transaction;
  final ValueChanged<_EditableTransaction> onChanged;

  const _EditableTransactionCard({
    required this.transaction,
    required this.onChanged,
  });

  @override
  State<_EditableTransactionCard> createState() =>
      _EditableTransactionCardState();
}

class _EditableTransactionCardState extends State<_EditableTransactionCard> {
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _categoryController =
        TextEditingController(text: widget.transaction.category);
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateTransaction() {
    widget.onChanged(_EditableTransaction(
      type: widget.transaction.type,
      amount: double.tryParse(_amountController.text) ??
          widget.transaction.amount,
      category: _categoryController.text,
      description: _descriptionController.text,
      date: widget.transaction.date,
      accountId: widget.transaction.accountId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850]!.withOpacity(0.3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + Amount
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.transaction.type == TransactionType.income
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.transaction.type == TransactionType.income
                      ? l10n.income
                      : l10n.expense,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.transaction.type ==
                            TransactionType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateTransaction(),
                  decoration: InputDecoration(
                    hintText: l10n.amount,
                    border: InputBorder.none,
                    prefixText: '₺ ',
                    isDense: true,
                  ),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Category (Autocomplete) - Kompakt
          _CategoryAutocompleteField(
            controller: _categoryController,
            onChanged: (_) => _updateTransaction(),
          ),

          const SizedBox(height: 8),

          // Description
          TextField(
            controller: _descriptionController,
            onChanged: (_) => _updateTransaction(),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: l10n.description,
              border: InputBorder.none,
              isDense: true,
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),

          const Divider(height: 16),

          // Account picker + Date (yan yana)
          Row(
            children: [
              // Account
              Expanded(
                flex: 3,
                child: _AccountPickerField(
                  selectedAccountId: widget.transaction.accountId,
                  onAccountSelected: (accountId) {
                    setState(() {
                      widget.transaction.accountId = accountId;
                    });
                    _updateTransaction();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Date Picker
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: widget.transaction.date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        widget.transaction.date = picked;
                      });
                      _updateTransaction();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14,
                            color: const Color(0xFF007AFF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat('d MMM').format(widget.transaction.date),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Category Autocomplete Field
/// SOLID: Single Responsibility - Sadece kategori seçimi
class _CategoryAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _CategoryAutocompleteField({
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<UnifiedProviderV2>();
    
    // Kategori isimlerini al
    final categories = provider.categories.map((cat) => cat.name).toList();

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return categories;
        }
        return categories.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
        onChanged?.call(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Controller'ı senkronize et
        fieldTextEditingController.text = controller.text;
        fieldTextEditingController.addListener(() {
          controller.text = fieldTextEditingController.text;
          onChanged?.call(fieldTextEditingController.text);
        });

        return TextField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: l10n.category,
            border: InputBorder.none,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
            isDense: true,
            prefixIcon: const Icon(Icons.category_outlined, size: 18),
          ),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        );
      },
    );
  }
}

/// Account Picker Field
/// SOLID: Single Responsibility - Sadece hesap seçimi
class _AccountPickerField extends StatelessWidget {
  final String? selectedAccountId;
  final ValueChanged<String> onAccountSelected;

  const _AccountPickerField({
    required this.selectedAccountId,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<UnifiedProviderV2>();
    final accounts = provider.accounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedAccount = accounts.firstWhere(
      (acc) => acc.id == selectedAccountId,
      orElse: () => accounts.isNotEmpty
          ? accounts.first
          : throw Exception('No accounts available'),
    );

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.selectAccount,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...accounts.map((account) {
                    return ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF007AFF),
                      ),
                      title: Text(
                        account.name,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        account.type.toString().split('.').last,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: selectedAccountId == account.id
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF007AFF))
                          : null,
                      onTap: () {
                        onAccountSelected(account.id);
                        Navigator.of(context).pop();
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                size: 16, color: Color(0xFF007AFF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedAccountId == null
                    ? l10n.selectAccount
                    : selectedAccount.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedAccountId == null
                      ? (isDark ? Colors.white54 : Colors.black45)
                      : (isDark ? Colors.white : Colors.black87),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: isDark ? Colors.white54 : Colors.black45),
          ],
        ),
      ),
    );
  }
}

