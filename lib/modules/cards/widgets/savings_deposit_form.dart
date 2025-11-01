import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/savings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/unified_account_service.dart';
import '../../../core/events/savings_events.dart';
import '../../../shared/models/savings_goal.dart';
import '../../../shared/models/account_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/thousands_separator_input_formatter.dart';
import 'milestone_celebration_dialog.dart';
import 'goal_completed_dialog.dart';
import '../screens/savings_goal_detail_screen.dart';
import 'add_savings_goal_form.dart';

// Kart ismini temizle ve localize et (Transaction formdaki gibi)
String _getLocalizedAccountName(AccountModel account, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final localizedCardType = account.type == AccountType.credit 
      ? (l10n.creditCard ?? 'Kredi Kartı')
      : account.type == AccountType.debit 
          ? (l10n.debitCard ?? 'Banka Kartı')
          : (l10n.cashWallet ?? 'Nakit Hesap');
  
  // Special handling for cash accounts
  if (account.type == AccountType.cash) {
    if (account.name.toUpperCase().contains('CASH') || 
        account.name.toUpperCase().contains('WALLET')) {
      return localizedCardType;
    }
  }
  
  // If name is empty, use bank name + card type
  if (account.name.isEmpty) {
    return '${account.bankName ?? ''} $localizedCardType';
  }
  
  // Remove card type phrases from name
  String cleanName = account.name
      .replaceAll(RegExp(r'\s*(Credit Card|Kredi Kartı|Debit Card|Banka Kartı)\s*$', caseSensitive: false), '')
      .trim();
  
  // If nothing left after cleaning, use bank name
  if (cleanName.isEmpty && account.bankName != null) {
    return '${account.bankName} $localizedCardType';
  }
  
  // If still empty, return just card type
  if (cleanName.isEmpty) {
    return localizedCardType;
  }
  
  // Return cleaned name + localized card type
  return '$cleanName $localizedCardType';
}

/// Para yatırma formu
class SavingsDepositForm extends StatefulWidget {
  final SavingsGoal goal;
  final List<AccountModel> accounts;
  final VoidCallback? onSuccess;

  const SavingsDepositForm({
    super.key,
    required this.goal,
    required this.accounts,
    this.onSuccess,
  });

  @override
  State<SavingsDepositForm> createState() => _SavingsDepositFormState();
}

class _SavingsDepositFormState extends State<SavingsDepositForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  AccountModel? _selectedAccount;
  VoidCallback? _milestoneUnsubscribe;
  VoidCallback? _completionUnsubscribe;
  String? _amountError; // Real-time validation error

  @override
  void initState() {
    super.initState();
    
    // İlk hesabı otomatik seç
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts.first;
    }
    
    // Amount controller listener for real-time validation
    _amountController.addListener(_validateAmount);
    
    // Milestone event'ini dinle
    _milestoneUnsubscribe = savingsEvents.listen<SavingsMilestoneAchieved>((event) {
      if (event.goal.id == widget.goal.id && mounted) {
        // Celebration dialog'unu göster
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => MilestoneCelebrationDialog(
                goalName: event.goal.name,
                milestonePercentage: event.milestone.percentage,
                currentAmount: event.goal.currentAmount,
                targetAmount: event.goal.targetAmount,
              ),
            );
          }
        });
      }
    });
    
    // Goal completion event'ini dinle
    _completionUnsubscribe = savingsEvents.listen<SavingsGoalCompleted>((event) {
      if (event.goal.id == widget.goal.id && mounted) {
        // Completion dialog'unu göster
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => GoalCompletedDialog(
                goal: event.goal,
                onArchive: () => _handleArchive(context, event.goal),
                onKeepActive: () => _handleKeepActive(context),
                onNewGoal: () => _handleNewGoal(context),
              ),
            );
          }
        });
      }
    });
  }
  
  void _validateAmount() {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final locale = themeProvider.currency.locale;
    
    setState(() {
      if (_amountController.text.isEmpty) {
        _amountError = null;
        return;
      }
      
      try {
        final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
          _amountController.text,
          locale,
        );
        
        final remainingAmount = widget.goal.targetAmount - widget.goal.currentAmount;
        
        if (amount <= 0) {
          _amountError = l10n.amountMustBeGreaterThanZero;
        } else if (amount > remainingAmount) {
          _amountError = l10n.amountExceedsGoalRemaining;
        } else if (_selectedAccount != null && amount > _selectedAccount!.balance) {
          _amountError = l10n.amountExceedsBalance;
        } else {
          _amountError = null;
        }
      } catch (e) {
        _amountError = null;
      }
    });
  }
  
  void _setMaxAmount() {
    if (_selectedAccount == null) return;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final locale = themeProvider.currency.locale;
    final decimalSeparator = locale.startsWith('tr') ? ',' : '.';
    
    // Max amount should be minimum of account balance and remaining goal amount
    final remainingAmount = widget.goal.targetAmount - widget.goal.currentAmount;
    final maxAmount = _selectedAccount!.balance < remainingAmount 
        ? _selectedAccount!.balance 
        : remainingAmount;
    
    // Format the number with locale-specific decimal separator
    final formattedAmount = maxAmount.toStringAsFixed(2).replaceAll('.', decimalSeparator);
    _amountController.text = formattedAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _milestoneUnsubscribe?.call();
    _completionUnsubscribe?.call();
    super.dispose();
  }
  
  Future<void> _handleArchive(BuildContext context, SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final savingsProvider = context.read<SavingsProvider>();
    
    final success = await savingsProvider.archiveGoal(goal.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.goalArchivedSuccess),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
      // Close form and detail screen
      if (mounted) {
        Navigator.of(context).pop(); // Close form
        Navigator.of(context).pop(); // Close detail screen
      }
    }
  }
  
  void _handleKeepActive(BuildContext context) {
    // Just close the dialog, goal remains active and completed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.goalCompletedTitle),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
  
  void _handleNewGoal(BuildContext context) {
    // Close current form and show new goal form
    Navigator.of(context).pop(); // Close deposit form
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSavingsGoalForm(),
    );
  }

  Future<void> _deposit() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }
    
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedAccount == null) {
      debugPrint('❌ No account selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.pleaseSelectAccount,
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFFF4C4C),
        ),
      );
      return;
    }

    debugPrint('💰 Depositing to savings goal...');
    debugPrint('   Goal: ${widget.goal.name}');
    debugPrint('   Amount: ${_amountController.text}');
    debugPrint('   Source Account: ${_selectedAccount!.name}');
    
    setState(() => _isLoading = true);

    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final locale = themeProvider.currency.locale;
      final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
        _amountController.text,
        locale,
      );
      final note = _noteController.text.trim();

      final savingsProvider = context.read<SavingsProvider>();
      final success = await savingsProvider.deposit(
        goalId: widget.goal.id,
        amount: amount,
        note: note.isEmpty ? null : note,
        sourceAccountId: _selectedAccount!.id,
      );

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Deposit successful!');
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else {
        debugPrint('❌ Deposit failed (success = false)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.transactionFailed,
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Deposit error: $e');
      if (!mounted) return;
      
      // Parse error message
      String errorMessage = l10n.transactionFailed;
      if (e.toString().contains('INSUFFICIENT_BALANCE')) {
        errorMessage = l10n.insufficientBalanceDetail;
      } else if (e.toString().contains('EXCEEDS_GOAL_REMAINING')) {
        errorMessage = l10n.amountExceedsGoalRemaining;
      } else if (e.toString().contains('INVALID_AMOUNT')) {
        errorMessage = l10n.amountMustBeGreaterThanZero;
      } else if (e.toString().contains('ACCOUNT_NOT_FOUND')) {
        errorMessage = l10n.pleaseSelectAccount;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF4C4C),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInfoColumn({
    required String label,
    required String amount,
    required bool isDark,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addSavingsTitle,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.goal.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white60
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Mevcut durum
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Progress ve yüzde
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.progress,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: widget.goal.completionPercentage / 100,
                                      minHeight: 6,
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF34C759),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '%${widget.goal.completionPercentage.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Mevcut, Hedef, Kalan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn(
                              label: l10n.current,
                              amount: themeProvider.formatAmount(widget.goal.currentAmount),
                              isDark: isDark,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                            _buildInfoColumn(
                              label: l10n.remaining,
                              amount: themeProvider.formatAmount(
                                widget.goal.targetAmount - widget.goal.currentAmount
                              ),
                              isDark: isDark,
                              color: const Color(0xFFFF9500),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                            _buildInfoColumn(
                              label: l10n.target,
                              amount: themeProvider.formatAmount(widget.goal.targetAmount),
                              isDark: isDark,
                              color: const Color(0xFF34C759),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Kaynak Hesap Seçimi
                  Text(
                    l10n.fromWhichAccount,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.accounts.length,
                      itemBuilder: (context, index) {
                        final account = widget.accounts[index];
                        final isSelected = _selectedAccount?.id == account.id;
                        final accentColor = account.type == AccountType.cash
                            ? const Color(0xFF34C759)
                            : account.type == AccountType.debit
                                ? const Color(0xFF007AFF)
                                : const Color(0xFFFF9500);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAccount = account;
                              _validateAmount(); // Re-validate when account changes
                            });
                          },
                          child: Container(
                            width: 135,
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 6,
                              right: index == widget.accounts.length - 1 ? 0 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withOpacity(0.12)
                                  : isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getLocalizedAccountName(account, context),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  themeProvider.formatAmount(account.balance),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Miktar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.amount,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (_selectedAccount != null)
                        Builder(
                          builder: (context) {
                            final remainingAmount = widget.goal.targetAmount - widget.goal.currentAmount;
                            final maxDeposit = _selectedAccount!.balance < remainingAmount 
                                ? _selectedAccount!.balance 
                                : remainingAmount;
                            return Text(
                              l10n.availableBalance(themeProvider.formatAmount(maxDeposit)),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF98989F) : const Color(0xFF6B6B70),
                              ),
                            );
                          }
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      ThousandsSeparatorInputFormatter(
                        locale: Provider.of<ThemeProvider>(context, listen: false).currency.locale,
                      ),
                    ],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.inter(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _amountError != null 
                            ? const BorderSide(color: Color(0xFFFF4C4C), width: 1.5)
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _amountError != null 
                            ? const BorderSide(color: Color(0xFFFF4C4C), width: 1.5)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _amountError != null 
                              ? const Color(0xFFFF4C4C) 
                              : const Color(0xFF007AFF),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: Builder(
                        builder: (context) {
                          if (_selectedAccount == null) return const SizedBox.shrink();
                          
                          final remainingAmount = widget.goal.targetAmount - widget.goal.currentAmount;
                          final maxDeposit = _selectedAccount!.balance < remainingAmount 
                              ? _selectedAccount!.balance 
                              : remainingAmount;
                          
                          // Show max button only if there's something to deposit
                          if (maxDeposit <= 0) return const SizedBox.shrink();
                          
                          return TextButton(
                            onPressed: _setMaxAmount,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.maxAmount,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF007AFF),
                              ),
                            ),
                          );
                        }
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterAmount;
                      }
                      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                      final locale = themeProvider.currency.locale;
                      final amount = ThousandsSeparatorInputFormatter.parseLocaleDouble(
                        value,
                        locale,
                      );
                      if (amount == null || amount <= 0) {
                        return l10n.pleaseEnterValidAmount;
                      }
                      final remainingAmount = widget.goal.targetAmount - widget.goal.currentAmount;
                      if (amount > remainingAmount) {
                        return l10n.amountExceedsGoalRemaining;
                      }
                      return null;
                    },
                  ),
                  // Inline error message
                  if (_amountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Color(0xFFFF4C4C),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _amountError!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFF4C4C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Not (Opsiyonel)
                  Text(
                    'Not (${l10n.optional})',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.depositNoteHint,
                      hintStyle: GoogleFonts.inter(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading || _amountError != null ? null : _deposit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            disabledBackgroundColor: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFE5E5EA),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  l10n.add,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

