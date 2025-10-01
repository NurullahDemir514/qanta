/// Hisse modülü için özel exception sınıfları

/// Hisse repository exception'ı
class StockRepositoryException implements Exception {
  final String message;
  final String? code;
  
  const StockRepositoryException(this.message, [this.code]);
  
  @override
  String toString() => 'StockRepositoryException: $message';
}

/// Hisse API exception'ı
class StockApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  
  const StockApiException(this.message, [this.code, this.statusCode]);
  
  @override
  String toString() => 'StockApiException: $message';
}

/// Hisse işlem exception'ı
class StockTransactionException implements Exception {
  final String message;
  final String? code;
  
  const StockTransactionException(this.message, [this.code]);
  
  @override
  String toString() => 'StockTransactionException: $message';
}

/// Hisse validasyon exception'ı
class StockValidationException implements Exception {
  final String message;
  final String? field;
  
  const StockValidationException(this.message, [this.field]);
  
  @override
  String toString() => 'StockValidationException: $message';
}

/// Hisse bulunamadı exception'ı
class StockNotFoundException implements Exception {
  final String symbol;
  
  const StockNotFoundException(this.symbol);
  
  @override
  String toString() => 'StockNotFoundException: Stock with symbol $symbol not found';
}

/// Yetersiz bakiye exception'ı
class InsufficientBalanceException implements Exception {
  final double requiredAmount;
  final double availableAmount;
  
  const InsufficientBalanceException(this.requiredAmount, this.availableAmount);
  
  @override
  String toString() => 
    'InsufficientBalanceException: Required $requiredAmount, available $availableAmount';
}

/// Yetersiz hisse miktarı exception'ı
class InsufficientStockQuantityException implements Exception {
  final String symbol;
  final double requiredQuantity;
  final double availableQuantity;
  
  const InsufficientStockQuantityException(
    this.symbol, 
    this.requiredQuantity, 
    this.availableQuantity,
  );
  
  @override
  String toString() => 
    'InsufficientStockQuantityException: Required $requiredQuantity $symbol, available $availableQuantity';
}
