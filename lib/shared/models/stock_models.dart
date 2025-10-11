import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/currency_utils.dart';

/// Hisse senedi modeli
class Stock {
  final String symbol;           // AAPL, SASA.IS
  final String name;            // Apple Inc., Sabancı Holding
  final String exchange;        // NASDAQ, BIST
  final String currency;        // USD, TRY
  final double currentPrice;
  final double changeAmount;
  final double changePercent;
  final DateTime lastUpdated;
  final String sector;          // Technology, Finance
  final String country;         // US, TR
  final double? dayHigh;        // Günün en yüksek fiyatı
  final double? dayLow;         // Günün en düşük fiyatı
  final double? volume;         // İşlem hacmi
  final double? openPrice;      // Günün açılış fiyatı
  final double? previousClose;  // Önceki gün kapanış fiyatı
  final List<double>? historicalData; // Geçmiş veri (mini grafik için)
  
  const Stock({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.currency,
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.lastUpdated,
    required this.sector,
    required this.country,
    this.dayHigh,
    this.dayLow,
    this.volume,
    this.openPrice,
    this.previousClose,
    this.historicalData,
  });
  
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'] ?? '',
      currency: json['currency'] ?? 'TRY',
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0.0).toDouble(),
      changePercent: (json['changePercent'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      sector: json['sector'] ?? '',
      country: json['country'] ?? '',
      dayHigh: json['dayHigh'] != null ? (json['dayHigh'] as num).toDouble() : null,
      dayLow: json['dayLow'] != null ? (json['dayLow'] as num).toDouble() : null,
      volume: json['volume'] != null ? (json['volume'] as num).toDouble() : null,
      openPrice: json['openPrice'] != null ? (json['openPrice'] as num).toDouble() : null,
      previousClose: json['previousClose'] != null ? (json['previousClose'] as num).toDouble() : null,
      historicalData: json['historicalData'] != null 
          ? List<double>.from(json['historicalData'].map((x) => (x as num).toDouble()))
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'currency': currency,
      'currentPrice': currentPrice,
      'changeAmount': changeAmount,
      'changePercent': changePercent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sector': sector,
      'country': country,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'volume': volume,
      'openPrice': openPrice,
      'previousClose': previousClose,
      'historicalData': historicalData,
    };
  }
  
  factory Stock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Stock.fromJson(data);
  }
  
  Map<String, dynamic> toFirestore() {
    return toJson();
  }
  
  // Helper getters
  bool get isPositive => changePercent >= 0;
  bool get isBist => exchange == 'BIST';
  bool get isUs => exchange == 'NASDAQ' || exchange == 'NYSE';
  
  String get displayPrice {
    final currencyEnum = Currency.fromCode(currency);
    return '${currencyEnum.symbol}${_formatNumber(currentPrice, isUSD: currency == 'USD')}';
  }
  
  String get displayChange => 
    '${changeAmount >= 0 ? '+' : ''}${_formatNumber(changeAmount, isUSD: currency == 'USD')}';
  
  String get displayChangePercent => 
    '${changePercent >= 0 ? '+' : ''}${_formatNumber(changePercent, isUSD: currency == 'USD')}%';
  
  // Currency'ye göre sayı formatlaması
  String _formatNumber(double number, {required bool isUSD}) {
    final currency = isUSD ? Currency.USD : Currency.TRY;
    return CurrencyUtils.formatAmountWithoutSymbol(number, currency);
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Stock && other.symbol == symbol;
  }
  
  @override
  int get hashCode => symbol.hashCode;
  
  @override
  String toString() => 'Stock(symbol: $symbol, name: $name, price: $displayPrice)';
}

/// Hisse fiyat geçmişi modeli
class StockPrice {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  const StockPrice({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  
  factory StockPrice.fromJson(Map<String, dynamic> json) {
    return StockPrice(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      open: (json['open'] ?? 0.0).toDouble(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      close: (json['close'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
  
  double get change => close - open;
  double get changePercent => open != 0 ? (change / open) * 100 : 0.0;
}

/// Hisse işlem türü enum
enum StockTransactionType {
  buy,
  sell;
  
  String get displayName {
    switch (this) {
      case StockTransactionType.buy:
        return 'Hisse Alış';
      case StockTransactionType.sell:
        return 'Hisse Satış';
    }
  }
  
  String get shortName {
    switch (this) {
      case StockTransactionType.buy:
        return 'Alış';
      case StockTransactionType.sell:
        return 'Satış';
    }
  }
}

/// Hisse işlem modeli
class StockTransaction {
  final String id;
  final String stockSymbol;
  final String stockName;
  final StockTransactionType type;
  final double quantity;
  final double price;
  final double totalAmount;
  final double commission;
  final DateTime transactionDate;
  final String? notes;
  final String userId;
  final String? accountId;
  
  const StockTransaction({
    required this.id,
    required this.stockSymbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.commission,
    required this.transactionDate,
    this.notes,
    required this.userId,
    this.accountId,
  });
  
  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] ?? '',
      stockSymbol: json['stockSymbol'] ?? '',
      stockName: json['stockName'] ?? '',
      type: StockTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StockTransactionType.buy,
      ),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      price: (json['price'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      notes: json['notes'],
      userId: json['userId'] ?? '',
      accountId: json['accountId'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stockSymbol': stockSymbol,
      'stockName': stockName,
      'type': type.name,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'commission': commission,
      'transactionDate': transactionDate.toIso8601String(),
      'notes': notes,
      'userId': userId,
      'accountId': accountId,
    };
  }
  
  factory StockTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockTransaction.fromJson(data);
  }
  
  Map<String, dynamic> toFirestore() {
    return toJson();
  }
  
  String get displayPrice => 
    '\$${price.toStringAsFixed(2)}';
  
  String get displayTotalAmount => 
    '\$${totalAmount.toStringAsFixed(2)}';
  
  String get displayQuantity => 
    quantity.toStringAsFixed(2);
  
  @override
  String toString() => 
    'StockTransaction(${type.shortName} $displayQuantity $stockSymbol @ $displayPrice)';
}

/// Hisse pozisyon modeli (portföydeki hisse durumu)
class StockPosition {
  final String stockSymbol;
  final String stockName;
  final double totalQuantity;
  final double averagePrice;
  final double totalCost;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercent;
  final DateTime lastUpdated;
  final String? currency;
  final List<double>? historicalData;
  
  const StockPosition({
    required this.stockSymbol,
    required this.stockName,
    required this.totalQuantity,
    required this.averagePrice,
    required this.totalCost,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
    required this.lastUpdated,
    this.currency,
    this.historicalData,
  });
  
  factory StockPosition.fromJson(Map<String, dynamic> json) {
    return StockPosition(
      stockSymbol: json['stockSymbol'] ?? '',
      stockName: json['stockName'] ?? '',
      totalQuantity: (json['totalQuantity'] ?? 0.0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0.0).toDouble(),
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      profitLoss: (json['profitLoss'] ?? 0.0).toDouble(),
      profitLossPercent: (json['profitLossPercent'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      currency: json['currency'] ?? 'TRY',
      historicalData: json['historicalData'] != null 
          ? List<double>.from(json['historicalData'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'stockSymbol': stockSymbol,
      'stockName': stockName,
      'totalQuantity': totalQuantity,
      'averagePrice': averagePrice,
      'totalCost': totalCost,
      'currentValue': currentValue,
      'profitLoss': profitLoss,
      'profitLossPercent': profitLossPercent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'currency': currency,
      'historicalData': historicalData,
    };
  }
  
  bool get isPositive => profitLoss >= 0;
  
  String get displayCurrentValue {
    final currencyCode = currency ?? 'TRY';
    final currencyEnum = Currency.fromCode(currencyCode);
    return '${currencyEnum.symbol}${_formatNumber(currentValue, isUSD: currencyCode == 'USD')}';
  }
  
  String get displayProfitLoss {
    final currencyCode = currency ?? 'TRY';
    final currencyEnum = Currency.fromCode(currencyCode);
    return '${profitLoss >= 0 ? '+' : ''}${currencyEnum.symbol}${_formatNumber(profitLoss, isUSD: currencyCode == 'USD')}';
  }
  
  String get displayProfitLossPercent {
    final currencyCode = currency ?? 'TRY';
    return '${profitLossPercent >= 0 ? '+' : ''}${_formatNumber(profitLossPercent, isUSD: currencyCode == 'USD')}%';
  }
  
  String get displayAveragePrice {
    final currencyCode = currency ?? 'TRY';
    final currencyEnum = Currency.fromCode(currencyCode);
    return '${currencyEnum.symbol}${_formatNumber(averagePrice, isUSD: currencyCode == 'USD')}';
  }
  
  String get displayQuantity {
    final currencyCode = currency ?? 'TRY';
    return _formatNumber(totalQuantity, isUSD: currencyCode == 'USD');
  }
  
  // Currency'ye göre sayı formatlaması
  String _formatNumber(double number, {required bool isUSD}) {
    final currency = isUSD ? Currency.USD : Currency.TRY;
    return CurrencyUtils.formatAmountWithoutSymbol(number, currency);
  }
  
  // Unrealized profit/loss (current value - total cost)
  double get unrealizedProfitLoss => currentValue - totalCost;
}
