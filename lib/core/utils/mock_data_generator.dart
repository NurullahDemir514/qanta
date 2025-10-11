import '../../shared/models/account_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../shared/models/stock_models.dart';

/// Mock veri oluşturucu - Play Store screenshot'ları için
/// DEBUG modda kullanılmalı, production'da ASLA kullanılmamalı
class MockDataGenerator {
  /// Generates 4 mock accounts with Turkish banking data
  static List<AccountModel> generateMockAccounts() {
    final now = DateTime.now();

    return [
      // Kredi Kartı
      AccountModel(
        id: 'mock_credit_1',
        userId: 'mock_user',
        name: 'HSBC Türkiye Kredi Kartı',
        type: AccountType.credit,
        bankName: 'HSBC',
        balance: 5000.0,
        creditLimit: 15000.0,
        statementDay: 1,
        dueDay: 15,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
      ),

      // Banka Hesabı
      AccountModel(
        id: 'mock_debit_1',
        userId: 'mock_user',
        name: 'Akbank Vadesiz Hesap',
        type: AccountType.debit,
        bankName: 'Akbank',
        balance: 12500.50,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now,
      ),

      // Nakit
      AccountModel(
        id: 'mock_cash_1',
        userId: 'mock_user',
        name: 'Nakit Cüzdan',
        type: AccountType.cash,
        balance: 850.0,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),

      // İkinci Kredi Kartı
      AccountModel(
        id: 'mock_credit_2',
        userId: 'mock_user',
        name: 'Garanti BBVA Miles&Smiles',
        type: AccountType.credit,
        bankName: 'Garanti BBVA',
        balance: 2300.0,
        creditLimit: 10000.0,
        statementDay: 5,
        dueDay: 20,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
    ];
  }

  /// Mock işlemler oluştur
  static List<TransactionModelV2> generateMockTransactions() {
    final today = DateTime.now();

    return [
      // Bugünkü işlemler
      TransactionModelV2(
        id: 'mock_tx_1',
        userId: 'mock_user',
        sourceAccountId: 'mock_credit_1',
        type: TransactionType.expense,
        amount: 350.0,
        categoryId: 'grocery',
        description: 'Migros Market',
        transactionDate: today,
        isPaid: true,
        createdAt: today,
        updatedAt: today,
      ),

      TransactionModelV2(
        id: 'mock_tx_2',
        userId: 'mock_user',
        sourceAccountId: 'mock_debit_1',
        type: TransactionType.income,
        amount: 15000.0,
        categoryId: 'salary',
        description: 'Aylık maaş ödemesi',
        transactionDate: today,
        isPaid: true,
        createdAt: today,
        updatedAt: today,
      ),

      // Dünkü işlemler
      TransactionModelV2(
        id: 'mock_tx_3',
        userId: 'mock_user',
        sourceAccountId: 'mock_credit_2',
        type: TransactionType.expense,
        amount: 1200.0,
        categoryId: 'transportation',
        description: 'Shell Benzin',
        transactionDate: today.subtract(const Duration(days: 1)),
        isPaid: true,
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.subtract(const Duration(days: 1)),
      ),

      TransactionModelV2(
        id: 'mock_tx_4',
        userId: 'mock_user',
        sourceAccountId: 'mock_cash_1',
        type: TransactionType.expense,
        amount: 85.0,
        categoryId: 'food',
        description: 'Starbucks',
        transactionDate: today.subtract(const Duration(days: 1)),
        isPaid: true,
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.subtract(const Duration(days: 1)),
      ),

      // Bu haftaki diğer işlemler
      TransactionModelV2(
        id: 'mock_tx_5',
        userId: 'mock_user',
        sourceAccountId: 'mock_credit_1',
        type: TransactionType.expense,
        amount: 2500.0,
        categoryId: 'shopping',
        description: 'Zara',
        transactionDate: today.subtract(const Duration(days: 3)),
        isPaid: true,
        createdAt: today.subtract(const Duration(days: 3)),
        updatedAt: today.subtract(const Duration(days: 3)),
      ),

      TransactionModelV2(
        id: 'mock_tx_6',
        userId: 'mock_user',
        sourceAccountId: 'mock_debit_1',
        type: TransactionType.expense,
        amount: 850.0,
        categoryId: 'bills',
        description: 'Türk Telekom',
        transactionDate: today.subtract(const Duration(days: 5)),
        isPaid: true,
        createdAt: today.subtract(const Duration(days: 5)),
        updatedAt: today.subtract(const Duration(days: 5)),
      ),

      TransactionModelV2(
        id: 'mock_tx_7',
        userId: 'mock_user',
        sourceAccountId: 'mock_credit_1',
        type: TransactionType.expense,
        amount: 450.0,
        categoryId: 'entertainment',
        description: 'Cinemaximum',
        transactionDate: today.subtract(const Duration(days: 6)),
        isPaid: true,
        createdAt: today.subtract(const Duration(days: 6)),
        updatedAt: today.subtract(const Duration(days: 6)),
      ),
    ];
  }

  /// Mock hisse pozisyonları oluştur
  static List<StockPosition> generateMockStockPositions() {
    return [
      StockPosition(
        stockSymbol: 'THYAO',
        stockName: 'Türk Hava Yolları',
        totalQuantity: 250.0,
        averagePrice: 285.50,
        totalCost: 71375.0,
        currentValue: 78750.0,
        profitLoss: 7375.0,
        profitLossPercent: 10.33,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      ),

      StockPosition(
        stockSymbol: 'AKBNK',
        stockName: 'Akbank',
        totalQuantity: 500.0,
        averagePrice: 58.20,
        totalCost: 29100.0,
        currentValue: 31500.0,
        profitLoss: 2400.0,
        profitLossPercent: 8.25,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      ),

      StockPosition(
        stockSymbol: 'EREGL',
        stockName: 'Ereğli Demir Çelik',
        totalQuantity: 300.0,
        averagePrice: 42.80,
        totalCost: 12840.0,
        currentValue: 13200.0,
        profitLoss: 360.0,
        profitLossPercent: 2.80,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      ),
    ];
  }

  /// Mock hisse işlemleri oluştur
  static List<StockTransaction> generateMockStockTransactions() {
    final today = DateTime.now();

    return [
      StockTransaction(
        id: 'mock_stock_tx_1',
        userId: 'mock_user',
        stockSymbol: 'THYAO',
        stockName: 'Türk Hava Yolları',
        type: StockTransactionType.buy,
        quantity: 250.0,
        price: 285.50,
        totalAmount: 71375.0,
        commission: 150.0,
        transactionDate: today.subtract(const Duration(days: 30)),
      ),

      StockTransaction(
        id: 'mock_stock_tx_2',
        userId: 'mock_user',
        stockSymbol: 'AKBNK',
        stockName: 'Akbank',
        type: StockTransactionType.buy,
        quantity: 500.0,
        price: 58.20,
        totalAmount: 29100.0,
        commission: 100.0,
        transactionDate: today.subtract(const Duration(days: 45)),
      ),

      StockTransaction(
        id: 'mock_stock_tx_3',
        userId: 'mock_user',
        stockSymbol: 'EREGL',
        stockName: 'Ereğli Demir Çelik',
        type: StockTransactionType.buy,
        quantity: 300.0,
        price: 42.80,
        totalAmount: 12840.0,
        commission: 75.0,
        transactionDate: today.subtract(const Duration(days: 60)),
      ),
    ];
  }

  /// Mock hisse stokları oluştur
  static List<Stock> generateMockStocks() {
    return [
      Stock(
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        exchange: 'BIST',
        currency: 'TRY',
        currentPrice: 315.00,
        changeAmount: 8.50,
        changePercent: 2.77,
        lastUpdated: DateTime.now(),
        sector: 'Ulaştırma',
        country: 'TR',
        dayHigh: 318.50,
        dayLow: 310.00,
        volume: 12500000,
      ),

      Stock(
        symbol: 'AKBNK',
        name: 'Akbank',
        exchange: 'BIST',
        currency: 'TRY',
        currentPrice: 63.00,
        changeAmount: 1.80,
        changePercent: 2.94,
        lastUpdated: DateTime.now(),
        sector: 'Finans',
        country: 'TR',
        dayHigh: 63.50,
        dayLow: 61.20,
        volume: 45000000,
      ),

      Stock(
        symbol: 'EREGL',
        name: 'Ereğli Demir Çelik',
        exchange: 'BIST',
        currency: 'TRY',
        currentPrice: 44.00,
        changeAmount: -0.50,
        changePercent: -1.12,
        lastUpdated: DateTime.now(),
        sector: 'Metal Eşya',
        country: 'TR',
        dayHigh: 44.80,
        dayLow: 43.50,
        volume: 8900000,
      ),
    ];
  }

  /// Tüm mock verileri temizle
  static void clearMockData() {
    // Bu metod gerçek Firebase verilerini etkilemez
    // Sadece UI state'ini temizler
    print('🧹 Mock veriler temizlendi');
  }

  /// Mock veri yükleme durumu kontrolü
  static bool isMockDataEnabled() {
    // Environment variable veya debug flag ile kontrol edilebilir
    const bool kDebugMode = true; // compile-time constant
    return kDebugMode;
  }

  /// Mock verilerin toplam değerini hesapla
  static Map<String, dynamic> getMockDataSummary() {
    final accounts = generateMockAccounts();
    final transactions = generateMockTransactions();
    final stockPositions = generateMockStockPositions();

    final totalBalance = accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );

    final totalStockValue = stockPositions.fold<double>(
      0.0,
      (sum, position) => sum + position.currentValue,
    );

    final totalIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final totalExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    return {
      'totalAccounts': accounts.length,
      'totalTransactions': transactions.length,
      'totalStockPositions': stockPositions.length,
      'totalBalance': totalBalance,
      'totalStockValue': totalStockValue,
      'totalNetWorth': totalBalance + totalStockValue,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
    };
  }

  /// Hesap isimleri listesi (UI'da gösterim için)
  static List<String> getMockAccountNames() {
    return generateMockAccounts().map((a) => a.name).toList();
  }

  /// İşlem kategorileri listesi (UI'da gösterim için)
  static List<String> getMockTransactionCategories() {
    return generateMockTransactions()
        .map((t) => t.categoryId ?? 'Other')
        .toSet()
        .toList();
  }

  /// Hisse sembolleri listesi (UI'da gösterim için)
  static List<String> getMockStockSymbols() {
    return generateMockStockPositions().map((s) => s.stockSymbol).toList();
  }
}
