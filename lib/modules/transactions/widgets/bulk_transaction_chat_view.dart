import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/unified_category_model.dart';

/// WhatsApp tarzı interaktif bulk transaction görünümü
/// SOLID: Single Responsibility - Chat-style transaction confirmation
class BulkTransactionChatView extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final String? preSelectedAccountId;
  final VoidCallback onClose;
  final Function(int) onSaved;

  const BulkTransactionChatView({
    super.key,
    required this.transactions,
    this.preSelectedAccountId,
    required this.onClose,
    required this.onSaved,
  });

  @override
  State<BulkTransactionChatView> createState() => _BulkTransactionChatViewState();
}

class _BulkTransactionChatViewState extends State<BulkTransactionChatView> {
  late List<_TransactionItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.transactions.map((txn) {
      return _TransactionItem(
        type: txn['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        amount: (txn['amount'] as num?)?.toDouble() ?? 0.0,
        category: txn['category'] as String? ?? '',
        description: txn['description'] as String? ?? '',
        date: _parseDate(txn['date']),
        accountId: widget.preSelectedAccountId, // Önceden seçilen hesap
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

  Future<void> _saveAll() async {
    if (_items.isEmpty) {
      widget.onClose();
      return;
    }

    // Validation
    for (final item in _items) {
      if (item.accountId == null || item.accountId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectAccount),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<UnifiedProviderV2>();

      for (final item in _items) {
        // Kategori ID
        String categoryId;
        final existingCategory = provider.categories.where(
          (cat) => cat.name.toLowerCase() == item.category.toLowerCase(),
        ).firstOrNull;

        if (existingCategory != null) {
          categoryId = existingCategory.id;
        } else {
          final newCategory = await provider.createCategory(
            type: item.type == TransactionType.income
                ? CategoryType.income
                : CategoryType.expense,
            name: item.category,
          );
          categoryId = newCategory.id;
        }

        await provider.createTransaction(
          type: item.type,
          amount: item.amount,
          description: item.description,
          sourceAccountId: item.accountId!,
          categoryId: categoryId,
          transactionDate: item.date,
        );
      }

      if (mounted) {
        widget.onSaved(_items.length);
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Minimal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D6D70).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF6D6D70),
                  size: 18,
                ),
              ),
                const SizedBox(width: 12),
                Text(
                  '${_items.length} işlem bulundu',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Transaction Cards (Chat Bubbles)
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _TransactionChatBubble(
              item: item,
              onEdit: () => _showEditDialog(index),
              onDelete: () {
                setState(() {
                  _items.removeAt(index);
                });
              },
            );
          }),

          // Save All Button (iOS Style)
          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${_items.length} İşlemi Kaydet',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving ? null : widget.onClose,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final item = _items[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTransactionSheet(
        item: item,
        onSave: (updated) {
          setState(() {
            _items[index] = updated;
          });
        },
      ),
    );
  }
}

/// Transaction Item Data
class _TransactionItem {
  TransactionType type;
  double amount;
  String category;
  String description;
  DateTime date;
  String? accountId;

  _TransactionItem({
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.accountId,
  });
}

/// Chat Bubble for Transaction
class _TransactionChatBubble extends StatelessWidget {
  final _TransactionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionChatBubble({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  String _getAccountName(BuildContext context, String accountId) {
    final provider = context.read<UnifiedProviderV2>();
    final account = provider.accounts.where((a) => a.id == accountId).firstOrNull;
    return account?.name ?? 'Hesap';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = item.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Amount + Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Expanded(
                    child: Text(
                      '₺${item.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isIncome 
                            ? const Color(0xFF059669) 
                            : const Color(0xFFDC2626),
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                  // Type Badge (Simple Pill)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFF059669).withOpacity(0.1)
                          : const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIncome ? 'Gelir' : 'Gider',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isIncome 
                            ? const Color(0xFF059669) 
                            : const Color(0xFFDC2626),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Category
              Text(
                item.category,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              
              // Simple Divider
              Container(
                height: 0.5,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
              const SizedBox(height: 10),
              
              // Bottom Row: Date, Account, Actions
              Row(
                children: [
                  // Date
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final locale = Localizations.localeOf(context);
                      final languageCode = locale.languageCode;
                      
                      String localeString;
                      switch (languageCode) {
                        case 'en':
                          localeString = 'en_US';
                          break;
                        case 'de':
                          localeString = 'de_DE';
                          break;
                        case 'tr':
                        default:
                          localeString = 'tr_TR';
                          break;
                      }
                      
                      return Text(
                        DateFormat('d MMM', localeString).format(item.date),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  
                  // Account
                  if (item.accountId != null) ...[
                    Icon(
                      Icons.wallet_rounded,
                      size: 12,
                      color: const Color(0xFF6D6D70),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _getAccountName(context, item.accountId!),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6D6D70),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Actions (Minimal)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit Transaction Bottom Sheet
class _EditTransactionSheet extends StatefulWidget {
  final _TransactionItem item;
  final Function(_TransactionItem) onSave;

  const _EditTransactionSheet({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  late TransactionType _selectedType;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.item.amount.toString());
    _categoryController = TextEditingController(text: widget.item.category);
    _selectedDate = widget.item.date;
    _selectedType = widget.item.type;
    _selectedAccountId = widget.item.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _getAccountName(BuildContext context, String accountId) {
    final provider = context.read<UnifiedProviderV2>();
    final account = provider.accounts.where((a) => a.id == accountId).firstOrNull;
    return account?.name ?? 'Hesap';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Type Toggle (iOS Segmented Control)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = TransactionType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.expense
                              ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: _selectedType == TransactionType.expense
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          l10n.expense,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedType == TransactionType.expense
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedType == TransactionType.expense
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = TransactionType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.income
                              ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: _selectedType == TransactionType.income
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          l10n.income,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedType == TransactionType.income
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedType == TransactionType.income
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount (Prominent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '₺',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _selectedType == TransactionType.income
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 18,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.category,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Account (Read-only)
            if (_selectedAccountId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wallet_rounded,
                      size: 18,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getAccountName(context, _selectedAccountId!),
                        style: GoogleFonts.inter(fontSize: 15),
                      ),
                    ),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Date Picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF6D6D70),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (context) {
                        final locale = Localizations.localeOf(context);
                        final languageCode = locale.languageCode;
                        
                        String localeString;
                        switch (languageCode) {
                          case 'en':
                            localeString = 'en_US';
                            break;
                          case 'de':
                            localeString = 'de_DE';
                            break;
                          case 'tr':
                          default:
                            localeString = 'tr_TR';
                            break;
                        }
                        
                        return Expanded(
                          child: Text(
                            DateFormat('d MMMM yyyy', localeString).format(_selectedDate),
                            style: GoogleFonts.inter(fontSize: 15),
                          ),
                        );
                      },
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_TransactionItem(
                    type: _selectedType,
                    amount: double.tryParse(_amountController.text) ?? widget.item.amount,
                    category: _categoryController.text,
                    description: '',
                    date: _selectedDate,
                    accountId: _selectedAccountId,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D6D70),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kaydet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Account Picker Field
class _AccountPickerField extends StatelessWidget {
  final String? selectedAccountId;
  final Function(String) onSelected;

  const _AccountPickerField({
    required this.selectedAccountId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<UnifiedProviderV2>();
    final accounts = provider.accounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedAccount = accounts.where((a) => a.id == selectedAccountId).firstOrNull;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.selectAccount,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ...accounts.map((account) => ListTile(
                      leading: const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF6D6D70)),
                      title: Text(account.name, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      trailing: selectedAccountId == account.id
                          ? const Icon(Icons.check_circle, color: Color(0xFF6D6D70))
                          : null,
                      onTap: () {
                        onSelected(account.id);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6D6D70)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedAccount?.name ?? l10n.selectAccount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selectedAccount == null
                      ? (isDark ? Colors.white54 : Colors.black45)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: isDark ? Colors.white54 : Colors.black45),
          ],
        ),
      ),
    );
  }
}

