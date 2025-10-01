import 'package:flutter/foundation.dart';
import '../contracts/stock_repository_contract.dart';
import '../contracts/stock_api_contract.dart';
import '../contracts/stock_transaction_contract.dart';
import '../exceptions/stock_exceptions.dart';
import '../../../shared/models/stock_models.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/providers/unified_provider_v2.dart';

/// Hisse modülü için ana provider - SOLID prensiplerine uygun
class StockProvider extends ChangeNotifier {
  final IStockRepository _stockRepository;
  final IStockApiService _stockApiService;
  final IStockTransactionService _transactionService;
  
  // State
  List<Stock> _watchedStocks = [];
  List<StockTransaction> _stockTransactions = [];
  List<StockPosition> _stockPositions = [];
  bool _isLoading = false;
  bool _isUpdatingPrices = false;
  String? _error;
  Map<String, List<double>> _historicalData = {}; // Symbol -> Historical data
  
  StockProvider({
    required IStockRepository stockRepository,
    required IStockApiService stockApiService,
    required IStockTransactionService transactionService,
  }) : _stockRepository = stockRepository,
       _stockApiService = stockApiService,
       _transactionService = transactionService;
  
  // Getters
  List<Stock> get watchedStocks => _watchedStocks;
  List<StockTransaction> get stockTransactions => _stockTransactions;
  List<StockPosition> get stockPositions => _stockPositions;
  bool get isLoading => _isLoading;
  bool get isUpdatingPrices => _isUpdatingPrices;
  String? get error => _error;
  
  // Optimistic UI Updates
  void addWatchedStockOptimistically(Stock stock) {
    if (!_watchedStocks.any((s) => s.symbol == stock.symbol)) {
      _watchedStocks.add(stock);
      notifyListeners();
      
      // Yeni eklenen hisse için hemen geçmiş veri çek
      loadHistoricalData(stock.symbol, days: 30);
    }
  }

  void removeWatchedStockOptimistically(String stockSymbol) {
    _watchedStocks.removeWhere((s) => s.symbol == stockSymbol);
    
    // Kaldırılan hisse için geçmiş veriyi temizle
    _historicalData.remove(stockSymbol);
    
    notifyListeners();
  }

  // Hisse takip işlemleri
  Future<void> loadWatchedStocks(String userId) async {
    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma
    
    _setLoading(true);
    try {
      _watchedStocks = await _stockRepository.getWatchedStocks(userId);
      // Mevcut hisse isimlerini temizle
      _watchedStocks = _watchedStocks.map((stock) => Stock(
        symbol: stock.symbol,
        name: _cleanStockName(stock.name),
        exchange: stock.exchange,
        currency: stock.currency,
        currentPrice: stock.currentPrice,
        changeAmount: stock.changeAmount,
        changePercent: stock.changePercent,
        lastUpdated: stock.lastUpdated,
        sector: stock.sector,
        country: stock.country,
      )).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> addWatchedStock(String userId, Stock stock) async {
    try {
      // 1. ÖNCE detaylı hisse bilgilerini API'den çek
      final detailedStock = await _stockApiService.getStockDetails(stock.symbol);
      
      if (detailedStock != null) {
        // Hisse ismini temizle ve detaylı bilgileri kullan
        final cleanedStock = Stock(
          symbol: detailedStock.symbol,
          name: _cleanStockName(detailedStock.name),
          exchange: detailedStock.exchange,
          currency: detailedStock.currency,
          currentPrice: detailedStock.currentPrice,
          changeAmount: detailedStock.changeAmount,
          changePercent: detailedStock.changePercent,
          lastUpdated: detailedStock.lastUpdated,
          sector: detailedStock.sector,
          country: detailedStock.country,
          dayHigh: detailedStock.dayHigh,
          dayLow: detailedStock.dayLow,
          volume: detailedStock.volume,
        );
        
        // 2. OPTIMISTIC UI UPDATE - Önce UI'ye ekle (hızlı)
        addWatchedStockOptimistically(cleanedStock);
        
        // 3. Backend'e kaydet (arka planda)
        await _stockRepository.addWatchedStock(userId, cleanedStock);
        
      } else {
        // API'den detay alınamazsa temel bilgilerle ekle
        final cleanedStock = Stock(
          symbol: stock.symbol,
          name: _cleanStockName(stock.name),
          exchange: stock.exchange,
          currency: stock.currency,
          currentPrice: stock.currentPrice,
          changeAmount: stock.changeAmount,
          changePercent: stock.changePercent,
          lastUpdated: stock.lastUpdated,
          sector: stock.sector,
          country: stock.country,
        );
        
        // 2. OPTIMISTIC UI UPDATE - Önce UI'ye ekle (hızlı)
        addWatchedStockOptimistically(cleanedStock);
        
        // 3. Backend'e kaydet (arka planda)
        await _stockRepository.addWatchedStock(userId, cleanedStock);
        
        // 4. Hisse eklendikten sonra fiyatları güncelle
        _updateStockPrices();
      }
    } catch (e) {
      // Hata durumunda UI'yi geri yükle
      await loadWatchedStocks(userId);
      
      _error = e.toString();
      if (kDebugMode) {
      }
    }
  }
  
  Future<void> removeWatchedStock(String userId, String stockSymbol) async {
    try {
      // 1. OPTIMISTIC UI UPDATE - Anında UI'den kaldır
      removeWatchedStockOptimistically(stockSymbol);
      
      // 2. Backend'den kaldır
      await _stockRepository.removeWatchedStock(userId, stockSymbol);
      
      // 3. Başarılı olursa zaten UI güncellenmiş, hata olursa geri yükle
    } catch (e) {
      // Hata durumunda UI'yi geri yükle
      await loadWatchedStocks(userId);
      
      _error = e.toString();
      if (kDebugMode) {
      }
    }
  }
  
  Future<bool> isStockWatched(String userId, String stockSymbol) async {
    try {
      return await _stockRepository.isStockWatched(userId, stockSymbol);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        // Debug log kaldırıldı
      }
      return false;
    }
  }
  
  // Gerçek zamanlı fiyat güncellemesi
  Future<void> updateRealTimePrices() async {
    
    if (_isUpdatingPrices || _watchedStocks.isEmpty) {
      return;
    }
    
    _setUpdatingPrices(true);
    
    try {
      // .IS uzantısını ekleyerek API'ye gönder
      final symbols = _watchedStocks.map((stock) {
        // Türk hisseleri için .IS uzantısı ekle (BIST, IST, veya Türk hissesi olan)
        if ((stock.exchange == 'BIST' || stock.exchange == 'IST' || stock.currency == 'TRY') && !stock.symbol.endsWith('.IS')) {
          return '${stock.symbol}.IS';
        }
        return stock.symbol;
      }).toList();
      
      // API çağrısına timeout ekle (5 saniye)
      final updatedStocks = await _stockApiService.getRealTimePrices(symbols).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout durumunda boş liste döndür
          return <Stock>[];
        },
      );
      
      // Mevcut hisseleri güncelle
      for (final updatedStock in updatedStocks) {
        // Sembol eşleştirmesi için .IS uzantısını kaldır
        final cleanSymbol = updatedStock.symbol.replaceAll('.IS', '');
        final index = _watchedStocks.indexWhere((stock) => stock.symbol == cleanSymbol);
        if (index != -1) {
          
          // Detaylı bilgileri de güncelle - orijinal sembolü ve historicalData'yı koru
          _watchedStocks[index] = Stock(
            symbol: _watchedStocks[index].symbol, // Orijinal sembolü koru
            name: _cleanStockName(updatedStock.name),
            exchange: updatedStock.exchange,
            currency: updatedStock.currency,
            currentPrice: updatedStock.currentPrice,
            changeAmount: updatedStock.changeAmount,
            changePercent: updatedStock.changePercent,
            lastUpdated: updatedStock.lastUpdated,
            sector: updatedStock.sector,
            country: updatedStock.country,
            dayHigh: updatedStock.dayHigh,
            dayLow: updatedStock.dayLow,
            volume: updatedStock.volume,
            historicalData: _watchedStocks[index].historicalData, // Mevcut historicalData'yı koru
          );
        }
      }
      
      // Pozisyonları da güncelle
      await _updatePositionsWithCurrentPrices();
      
      // Grafik verilerini de güncelle (her 20 saniyede bir)
      await _updateHistoricalDataForWatchedStocks();
      
      notifyListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUpdatingPrices(false);
    }
  }
  
  /// İzlenen hisselerin grafik verilerini güncelle
  Future<void> _updateHistoricalDataForWatchedStocks() async {
    try {
      // Her 20 saniyede bir grafik verilerini güncelle
      for (final stock in _watchedStocks) {
        // Sadece grafik verisi yoksa veya eskiyse güncelle
        if (stock.historicalData == null || stock.historicalData!.isEmpty) {
          await loadHistoricalData(stock.symbol, days: 30, forceReload: true);
        }
      }
    } catch (e) {
      // Hata olsa bile devam et
    }
  }
  
  // Pozisyonları güncel fiyatlarla güncelle - ATOMIK GÜNCELLEME
  Future<void> _updatePositionsWithCurrentPrices() async {
    
    // Mevcut pozisyonları yedekle
    final List<StockPosition> oldPositions = List.from(_stockPositions);
    
    // Önce yeni pozisyonları hesapla (sıfırlamadan)
    final List<StockPosition> newPositions = [];
    bool hasChanges = false;
    bool hasValidData = true;
    
    for (int i = 0; i < _stockPositions.length; i++) {
      final position = _stockPositions[i];
      final currentStock = _watchedStocks.firstWhere(
        (stock) => stock.symbol == position.stockSymbol,
        orElse: () => Stock(
          symbol: position.stockSymbol,
          name: position.stockName,
          exchange: '',
          currency: 'TRY',
          currentPrice: position.averagePrice, // Fallback
          changeAmount: 0,
          changePercent: 0,
          lastUpdated: DateTime.now(),
          sector: '',
          country: '',
        ),
      );
      
      final newCurrentValue = position.totalQuantity * currentStock.currentPrice;
      final newProfitLoss = newCurrentValue - position.totalCost;
      final newProfitLossPercent = position.totalCost > 0 ? ((newProfitLoss / position.totalCost) * 100).toDouble() : 0.0;
      
      // Geçerli veri kontrolü
      if (newCurrentValue < 0 || newProfitLoss.isNaN || newProfitLossPercent.isNaN) {
        hasValidData = false;
        break;
      }
      
      // Değişiklik var mı kontrol et
      if ((position.currentValue - newCurrentValue).abs() > 0.01 || 
          (position.profitLoss - newProfitLoss).abs() > 0.01) {
        hasChanges = true;
      }
      
      newPositions.add(StockPosition(
        stockSymbol: position.stockSymbol,
        stockName: position.stockName,
        totalQuantity: position.totalQuantity,
        averagePrice: position.averagePrice,
        totalCost: position.totalCost,
        currentValue: newCurrentValue,
        profitLoss: newProfitLoss,
        profitLossPercent: newProfitLossPercent,
        lastUpdated: DateTime.now(),
        currency: position.currency,
        historicalData: position.historicalData, // Geçmiş veriyi koru
      ));
    }
    
    // ATOMIK GÜNCELLEME: Sadece geçerli veriler ve değişiklik varsa güncelle
    if (hasValidData && hasChanges) {
      _stockPositions = newPositions;
      notifyListeners();
    } else if (!hasValidData) {
      // Geçersiz veri varsa eski pozisyonları koru
      _stockPositions = oldPositions;
    }
  }
  
  // Arka planda fiyat güncelleme
  Future<void> _updateStockPrices() async {
    if (_watchedStocks.isEmpty) return;
    
    try {
      _setUpdatingPrices(true);
      
      // Her hisse için detaylı bilgileri çek
      for (int i = 0; i < _watchedStocks.length; i++) {
        final stock = _watchedStocks[i];
        final detailedStock = await _stockApiService.getStockDetails(stock.symbol);
        
        if (detailedStock != null) {
          // Detaylı bilgileri güncelle (historicalData'yı koru)
          _watchedStocks[i] = Stock(
            symbol: detailedStock.symbol,
            name: _cleanStockName(detailedStock.name),
            exchange: detailedStock.exchange,
            currency: detailedStock.currency,
            currentPrice: detailedStock.currentPrice,
            changeAmount: detailedStock.changeAmount,
            changePercent: detailedStock.changePercent,
            lastUpdated: detailedStock.lastUpdated,
            sector: detailedStock.sector,
            country: detailedStock.country,
            dayHigh: detailedStock.dayHigh,
            dayLow: detailedStock.dayLow,
            volume: detailedStock.volume,
            historicalData: stock.historicalData, // Mevcut historicalData'yı koru
          );
        }
      }
      
      notifyListeners();
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      _setUpdatingPrices(false);
    }
  }
  
  // Hisse arama işlemleri
  Future<List<Stock>> searchStocks(String query) async {
    try {
      _setLoading(true);
      final results = await _stockApiService.searchStocks(query);
      _error = null;
      return results;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        // Debug log kaldırıldı
      }
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  Future<Stock?> getStockDetails(String symbol) async {
    try {
      return await _stockApiService.getStockDetails(symbol);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        // Debug log kaldırıldı
      }
      return null;
    }
  }
  
  Future<List<Stock>> getRealTimePrices(List<String> symbols) async {
    try {
      _setLoading(true);
      final prices = await _stockApiService.getRealTimePrices(symbols);
      _error = null;
      return prices;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        // Debug log kaldırıldı
      }
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  Future<List<Stock>> getPopularStocks() async {
    try {
      return await _stockApiService.getPopularStocks();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
      return [];
    }
  }
  
  Future<List<Stock>> getBistStocks() async {
    try {
      return await _stockApiService.getBistStocks();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
      return [];
    }
  }
  
  // Hisse işlem işlemleri
  Future<void> executeStockTransaction(StockTransaction transaction) async {
    try {
      _setLoading(true);
      
      if (transaction.type == StockTransactionType.buy) {
        await _transactionService.executeBuyTransaction(transaction);
      } else {
        await _transactionService.executeSellTransaction(transaction);
      }
      
      // İşlemler ve pozisyonları yenile
      await loadStockTransactions(transaction.userId);
      await loadStockPositions(transaction.userId);
      
      // Watched stocks'ları da yenile (pozisyon değişiklikleri için)
      await loadWatchedStocks(transaction.userId);
      
      // UnifiedProviderV2'yi güncelle (home screen için)
      try {
        final unifiedProvider = UnifiedProviderV2.instance;
        
        // Hisse pozisyonlarını güncelle
        final stockPositions = _stockPositions.map((position) => {
          'symbol': position.stockSymbol,
          'quantity': position.totalQuantity,
          'currentValue': position.currentValue,
          'totalValue': position.currentValue, // currentValue zaten toplam değer
          'totalCost': position.totalCost, // Toplam maliyet
        }).toList();
        unifiedProvider.updateStockPositions(stockPositions);
        
        await unifiedProvider.refresh();
      } catch (e) {
        // UnifiedProviderV2 güncelleme hatası kritik değil
        if (kDebugMode) {
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadStockTransactions(String userId) async {
    try {
      _stockTransactions = await _transactionService.getStockTransactions(userId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
    }
  }
  
  Future<void> loadStockPositions(String userId) async {
    try {
      final firebasePositions = await _transactionService.getAllStockPositions(userId);
      
      // Mevcut pozisyonları koruyarak güncelle
      if (_stockPositions.isNotEmpty) {
        // Mevcut pozisyonları koru, sadece eksik olanları ekle
        for (final firebasePosition in firebasePositions) {
          final existingIndex = _stockPositions.indexWhere(
            (pos) => pos.stockSymbol == firebasePosition.stockSymbol
          );
          
          if (existingIndex != -1) {
            // Mevcut pozisyonu güncelle (sadece temel bilgileri)
            _stockPositions[existingIndex] = StockPosition(
              stockSymbol: firebasePosition.stockSymbol,
              stockName: firebasePosition.stockName,
              totalQuantity: firebasePosition.totalQuantity,
              averagePrice: firebasePosition.averagePrice,
              totalCost: firebasePosition.totalCost,
              currentValue: _stockPositions[existingIndex].currentValue, // Güncel değeri koru
              profitLoss: _stockPositions[existingIndex].profitLoss, // Güncel kar/zararı koru
              profitLossPercent: _stockPositions[existingIndex].profitLossPercent, // Güncel yüzdeyi koru
              lastUpdated: _stockPositions[existingIndex].lastUpdated, // Güncel tarihi koru
              currency: firebasePosition.currency,
              historicalData: _stockPositions[existingIndex].historicalData, // Geçmiş veriyi koru
            );
          } else {
            // Yeni pozisyon ekle
            _stockPositions.add(firebasePosition);
          }
        }
      } else {
        // İlk yükleme
        _stockPositions = firebasePositions;
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
    }
  }
  
  Future<StockPosition?> getStockPosition(String userId, String stockSymbol) async {
    try {
      return await _transactionService.getStockPosition(userId, stockSymbol);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
      return null;
    }
  }
  
  Future<void> deleteStockTransaction(String transactionId) async {
    try {
      // 1. OPTIMISTIC UI UPDATE - Önce UI'yi anında güncelle
      _removeTransactionFromUI(transactionId);
      
      // 2. Backend işlemini yap
      await _transactionService.deleteStockTransaction(transactionId);
      
      // 3. User ID'yi al
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // 4. Arka planda verileri yenile (UI zaten güncellenmiş)
      _refreshAllDataInBackground(userId);
      
    } catch (e) {
      _error = e.toString();
      
      // Hata durumunda UI'yi geri yükle
      _refreshAllDataInBackground(FirebaseAuthService.currentUserId ?? '');
      
      if (kDebugMode) {
      }
    }
  }

  /// UI'den transaction'ı anında kaldır (optimistic update)
  void _removeTransactionFromUI(String transactionId) {
    try {
      // Stock transaction'ları ayrı bir liste olarak yönetiliyor
      // Bu yüzden sadece state'i güncelle ve arka planda yenile
      notifyListeners();
      
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Arka planda verileri yenile (UI zaten güncellenmiş)
  void _refreshAllDataInBackground(String userId) {
    // Arka planda çalıştır, UI'yi bloklamasın
    Future.microtask(() async {
      try {
        await loadWatchedStocks(userId);
        await loadStockPositions(userId); // Pozisyon bilgilerini de yenile
        await updateRealTimePrices();
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    });
  }

  /// Tüm verileri yenile (mikro refresh)
  Future<void> _refreshAllData(String userId) async {
    try {
      // Watched stocks'ları yenile
      await loadWatchedStocks(userId);
      
      // Stock positions'ları yenile
      await loadStockPositions(userId);
      
      // Real-time prices'ları güncelle
      await updateRealTimePrices();
      
    } catch (e) {
      // Hata olsa bile devam et
    }
  }
  
  // Tarihsel veri işlemleri
  Future<List<StockPrice>> getHistoricalPrices(
    String symbol, 
    String interval, 
    String range,
  ) async {
    try {
      return await _stockApiService.getHistoricalPrices(symbol, interval, range);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
      }
      return [];
    }
  }
  
  // Portföy hesaplamaları
  double get totalPortfolioValue {
    return _stockPositions.fold(0.0, (sum, position) => sum + position.currentValue);
  }
  
  double get totalPortfolioCost {
    return _stockPositions.fold(0.0, (sum, position) => sum + position.totalCost);
  }
  
  double get totalProfitLoss {
    return _stockPositions.fold(0.0, (sum, position) => sum + position.profitLoss);
  }
  
  double get totalProfitLossPercent {
    if (totalPortfolioCost == 0) return 0.0;
    return (totalProfitLoss / totalPortfolioCost) * 100;
  }
  
  // Utility methods
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setUpdatingPrices(bool updating) {
    _isUpdatingPrices = updating;
    notifyListeners();
  }
  
  String _cleanStockName(String name) {
    // .IS, .COM, .NET gibi ekleri kaldır
    return name
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.NET$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.ORG$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.CO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TR$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.US$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.L$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.PA$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.DE$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.HK$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.T$', caseSensitive: false), '')
        .trim();
  }

  /// Geçmiş veri çekme (mini grafik için)
  Future<void> loadHistoricalData(String symbol, {int days = 30, bool forceReload = false}) async {
    try {
      if (_historicalData.containsKey(symbol) && !forceReload) {
        return; // Zaten yüklü
      }
      
      final historicalData = await _stockApiService.getHistoricalData(symbol, days: days);
      _historicalData[symbol] = historicalData;
      
      // İlgili hisseyi güncelle
      final index = _watchedStocks.indexWhere((s) => s.symbol == symbol);
      if (index != -1) {
        final stock = _watchedStocks[index];
        _watchedStocks[index] = Stock(
          symbol: stock.symbol,
          name: stock.name,
          exchange: stock.exchange,
          currency: stock.currency,
          currentPrice: stock.currentPrice,
          changeAmount: stock.changeAmount,
          changePercent: stock.changePercent,
          lastUpdated: stock.lastUpdated,
          sector: stock.sector,
          country: stock.country,
          dayHigh: stock.dayHigh,
          dayLow: stock.dayLow,
          volume: stock.volume,
          historicalData: historicalData,
        );
        
        // Stock positions'ı da güncelle
        _updatePositionsWithHistoricalData(symbol, historicalData);
        
        notifyListeners();
      }
    } catch (e) {
    }
  }
  
  /// Stock positions'ı geçmiş veri ile güncelle
  void _updatePositionsWithHistoricalData(String symbol, List<double> historicalData) {
    final positionIndex = _stockPositions.indexWhere((p) => p.stockSymbol == symbol);
    
    if (positionIndex != -1) {
      final position = _stockPositions[positionIndex];
      _stockPositions[positionIndex] = StockPosition(
        stockSymbol: position.stockSymbol,
        stockName: position.stockName,
        totalQuantity: position.totalQuantity,
        averagePrice: position.averagePrice,
        totalCost: position.totalCost,
        currentValue: position.currentValue,
        profitLoss: position.profitLoss,
        profitLossPercent: position.profitLossPercent,
        lastUpdated: position.lastUpdated,
        currency: position.currency,
        historicalData: historicalData,
      );
    } else {
    }
  }
  
  /// Tüm izlenen hisseler için geçmiş veri yükle
  Future<void> loadAllHistoricalData({int days = 30}) async {
    final futures = _watchedStocks.map((stock) => 
      loadHistoricalData(stock.symbol, days: days)
    ).toList();
    
    await Future.wait(futures);
  }
  
  /// Belirli bir hisse için geçmiş veri getir
  List<double>? getHistoricalData(String symbol) {
    return _historicalData[symbol];
  }

  @override
  void dispose() {
    super.dispose();
  }
}
