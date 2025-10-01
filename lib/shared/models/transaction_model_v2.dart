import '../utils/date_utils.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

/// Installment information for display purposes
class InstallmentInfo {
  final int currentInstallment;
  final int totalInstallments;
  final double monthlyAmount;
  final double totalAmount;
  
  const InstallmentInfo({
    required this.currentInstallment,
    required this.totalInstallments,
    required this.monthlyAmount,
    required this.totalAmount,
  });
  
  /// Returns formatted installment text (e.g., "2/4 Taksit")
  String get displayText => '$currentInstallment/$totalInstallments Taksit';
  
  /// Returns progress as percentage (0.0 to 1.0)
  double get progress => currentInstallment / totalInstallments;
}

/// Transaction types supported by the system
enum TransactionType {
  income('income'),
  expense('expense'),
  transfer('transfer'),
  stock('stock');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.expense,
    );
  }

  /// Display name for UI
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case TransactionType.income:
        return l10n.income;
      case TransactionType.expense:
        return l10n.expense;
      case TransactionType.transfer:
        return l10n.transfer;
      case TransactionType.stock:
        return l10n.stocks;
    }
  }
}

/// Unified transaction model for all financial transactions
class TransactionModelV2 {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime transactionDate;
  
  // References
  final String? categoryId;
  final String sourceAccountId;
  final String? targetAccountId; // for transfers
  final String? installmentId;
  
  // Additional fields
  final bool isRecurring;
  final String? notes;
  final bool isPaid; // Payment status for statement tracking
  
  // Stock transaction specific fields
  final String? stockSymbol;
  final String? stockName;
  final double? stockQuantity;
  final double? stockPrice;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModelV2({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.categoryId,
    required this.sourceAccountId,
    this.targetAccountId,
    this.installmentId,
    this.isRecurring = false,
    this.notes,
    this.isPaid = false,
    this.stockSymbol,
    this.stockName,
    this.stockQuantity,
    this.stockPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this is an income transaction
  bool get isIncome => type == TransactionType.income;

  /// Whether this is an expense transaction
  bool get isExpense => type == TransactionType.expense;

  /// Whether this is a transfer transaction
  bool get isTransfer => type == TransactionType.transfer;

  /// Whether this is part of an installment
  bool get isInstallment => installmentId != null;

  /// Amount with sign (positive for income, negative for expense)
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return amount; // Neutral for transfers
      case TransactionType.stock:
        return amount; // Stock transactions can be positive or negative
    }
  }

  /// Display description with installment info if applicable
  String get displayDescription {
    if (notes != null && notes!.contains('installment')) {
      return description;
    }
    return description;
  }

  /// Create from JSON
  factory TransactionModelV2.fromJson(Map<String, dynamic> json) {
    return TransactionModelV2(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: _parseDateTime(json['transaction_date']),
      categoryId: json['category_id'] as String?,
      sourceAccountId: json['source_account_id'] as String,
      targetAccountId: json['target_account_id'] as String?,
      installmentId: json['installment_id'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      stockSymbol: json['stock_symbol'] as String?,
      stockName: json['stock_name'] as String?,
      stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toDouble() : null,
      stockPrice: json['stock_price'] != null ? (json['stock_price'] as num).toDouble() : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// **Updated:** Use centralized DateUtils for consistent date parsing
  static DateTime _parseDateTime(dynamic value) {
    return DateUtils.fromFirebase(value);
  }

  /// Convert to JSON with consistent date formatting
  /// 
  /// **Updated:** Uses DateUtils for consistent Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'transaction_date': DateUtils.toIso8601(transactionDate),
      'category_id': categoryId,
      'source_account_id': sourceAccountId,
      'target_account_id': targetAccountId,
      'installment_id': installmentId,
      'is_recurring': isRecurring,
      'notes': notes,
      'is_paid': isPaid,
      'stock_symbol': stockSymbol,
      'stock_name': stockName,
      'stock_quantity': stockQuantity,
      'stock_price': stockPrice,
      'created_at': DateUtils.toIso8601(createdAt),
      'updated_at': DateUtils.toIso8601(updatedAt),
    };
  }

  /// Create a copy with updated fields
  TransactionModelV2 copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
    String? categoryId,
    String? sourceAccountId,
    String? targetAccountId,
    String? installmentId,
    bool? isRecurring,
    String? notes,
    bool? isPaid,
    String? stockSymbol,
    String? stockName,
    double? stockQuantity,
    double? stockPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModelV2(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      categoryId: categoryId ?? this.categoryId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      installmentId: installmentId ?? this.installmentId,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      stockName: stockName ?? this.stockName,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockPrice: stockPrice ?? this.stockPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModelV2 && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModelV2(id: $id, type: ${type.value}, amount: $amount, description: $description)';
  }
}

/// Extended transaction model with joined data for display
class TransactionWithDetailsV2 extends TransactionModelV2 {
  final String? sourceAccountName;
  final String? sourceAccountType;
  final String? targetAccountName;
  final String? targetAccountType;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int? installmentCount;
  final bool isInstallment; // Flag to identify installment transactions
  
  // Stock transaction specific fields
  final String? stockSymbol;
  final String? stockName;
  final double? stockQuantity;
  final double? stockPrice;

  const TransactionWithDetailsV2({
    required super.id,
    required super.userId,
    required super.type,
    required super.amount,
    required super.description,
    required super.transactionDate,
    super.categoryId,
    required super.sourceAccountId,
    super.targetAccountId,
    super.installmentId,
    super.isRecurring = false,
    super.notes,
    super.isPaid = false,
    required super.createdAt,
    required super.updatedAt,
    this.sourceAccountName,
    this.sourceAccountType,
    this.targetAccountName,
    this.targetAccountType,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.installmentCount,
    this.isInstallment = false,
    this.stockSymbol,
    this.stockName,
    this.stockQuantity,
    this.stockPrice,
  });

  /// Create from JSON with joined data
  factory TransactionWithDetailsV2.fromJson(Map<String, dynamic> json) {
    return TransactionWithDetailsV2(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: TransactionModelV2._parseDateTime(json['transaction_date']),
      categoryId: json['category_id'] as String?,
      sourceAccountId: json['source_account_id'] as String,
      targetAccountId: json['target_account_id'] as String?,
      installmentId: json['installment_id'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      createdAt: TransactionModelV2._parseDateTime(json['created_at']),
      updatedAt: TransactionModelV2._parseDateTime(json['updated_at']),
      sourceAccountName: json['source_account_name'] as String?,
      sourceAccountType: json['source_account_type'] as String?,
      targetAccountName: json['target_account_name'] as String?,
      targetAccountType: json['target_account_type'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      installmentCount: json['installment_count'] as int?,
      isInstallment: json['is_installment'] as bool? ?? false,
      stockSymbol: json['stock_symbol'] as String?,
      stockName: json['stock_name'] as String?,
      stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toDouble() : null,
      stockPrice: json['stock_price'] != null ? (json['stock_price'] as num).toDouble() : null,
    );
  }

  /// Display name for the account involved
  String get accountDisplayName {
    if (isTransfer) {
      return '$sourceAccountName → $targetAccountName';
    }
    return sourceAccountName ?? 'Unknown Account';
  }

  /// Returns the original user-entered description without any system modifications
  /// This is the core business data that should be displayed to users
  String get originalDescription => description;
  
  /// Returns the transaction type as a localized string
  String get typeDisplayName {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.stock:
        return 'Stock';
    }
  }

  /// Display title for UI (formatted based on transaction type)
  String get displayTitle {
    switch (type) {
      case TransactionType.expense:
        // For expenses: show category name as title
        return categoryName ?? description;
      case TransactionType.income:
        // For income: show category name as title
        return categoryName ?? description;
      case TransactionType.transfer:
        // For transfers: show description as title
        return description;
      case TransactionType.stock:
        // For stocks: show simple stock transaction title
        if (stockSymbol != null) {
          final action = amount > 0 ? 'Satış' : 'Alış';
          return '$action $stockSymbol';
        }
        return description;
    }
  }

  /// Display subtitle for UI (formatted based on transaction type)
  String get displaySubtitle {
    switch (type) {
      case TransactionType.expense:
        // For expenses: show account name as subtitle
        return sourceAccountName ?? 'Account';
      case TransactionType.income:
        // For income: show account name as subtitle
        return sourceAccountName ?? 'Account';
      case TransactionType.transfer:
        // For transfers: show source → target as subtitle
        final sourceAccount = sourceAccountName ?? 'Account';
        final targetAccount = targetAccountName ?? 'Account';
        return '$sourceAccount → $targetAccount';
      case TransactionType.stock:
        // For stocks: show account name and stock details as subtitle
        final accountName = sourceAccountName ?? 'Account';
        if (stockQuantity != null && stockPrice != null) {
          return '$accountName • ${stockQuantity!.toStringAsFixed(0)} adet @ ${stockPrice!.toStringAsFixed(2)} ₺';
        }
        return accountName;
    }
  }
  
  /// Check if this is a stock transaction
  bool get isStockTransaction => type == TransactionType.stock;
  
  /// Returns installment information if this is an installment transaction
  /// This should be fetched from the installment relationship, not parsed from description
  InstallmentInfo? get installmentInfo {
    // TODO: Implement proper installment relationship lookup
    // This is a placeholder - in a proper implementation, this would
    // fetch installment details from the related InstallmentTransactionModel
    return null;
  }


  /// Returns a user-friendly installment display string
  String getInstallmentDisplayText() {
    if (installmentCount != null && installmentCount! > 1) {
      // x/y Taksit
      // currentInstallment description'dan veya null ise 1 olarak alınır
      final match = RegExp(r'(\d+)/(\d+)').firstMatch(description);
      final current = match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
      return '$current/$installmentCount Installment';
    } else if (installmentCount == 1) {
      return 'Cash';
    }
    return '';
  }

  /// Returns a user-friendly time display string
  String get displayTime {
    if (transactionDate == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDay = DateTime(transactionDate!.year, transactionDate!.month, transactionDate!.day);
    
    if (transactionDay == today) {
      return 'Today';
    } else if (transactionDay == yesterday) {
      return 'Yesterday';
    } else {
      // Simple date format: 8 Sep or 8/9 format
      try {
        final formatter = DateFormat('d MMM');
        return formatter.format(transactionDate!);
      } catch (e) {
        // Fallback: simple format
        return '${transactionDate!.day}/${transactionDate!.month}';
      }
    }
  }

  /// Convert to JSON with display fields
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'category_name': categoryName,
      'source_account_name': sourceAccountName,
      'source_account_type': sourceAccountType,
      'target_account_name': targetAccountName,
      'target_account_type': targetAccountType,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'installment_count': installmentCount,
      'is_installment': isInstallment,
    };
  }

} 