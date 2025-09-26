/// Exception thrown when there are insufficient funds for a transaction
class InsufficientFundsException implements Exception {
  final String message;
  final double requiredAmount;
  final double availableAmount;
  final String accountId;

  InsufficientFundsException({
    required this.message,
    required this.requiredAmount,
    required this.availableAmount,
    required this.accountId,
  });

  @override
  String toString() {
    return 'InsufficientFundsException: $message (Required: $requiredAmount, Available: $availableAmount)';
  }

  /// Get the shortfall amount
  double get shortfall => requiredAmount - availableAmount;

  /// Get a user-friendly error message
  String get userFriendlyMessage {
    return 'Yetersiz bakiye. Gerekli: ${requiredAmount.toStringAsFixed(2)}₺, Mevcut: ${availableAmount.toStringAsFixed(2)}₺';
  }

  /// Get card type (placeholder)
  String get cardType => 'credit';
}
