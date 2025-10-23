import 'dart:math' as math;
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
  Map<String, double> _stockChangesToday = {}; // Symbol -> today change %
  Map<String, double> _stockChanges7Days = {}; // Symbol -> 7-day change %
  Map<String, double> _stockChanges30Days = {}; // Symbol -> 30-day change %
  bool _isMockDataMode = false; // Mock data mode flag for screenshots

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
  bool get isMockDataMode => _isMockDataMode;
  Map<String, double> get stockChangesToday => _stockChangesToday;
  Map<String, double> get stockChanges7Days => _stockChanges7Days;
  Map<String, double> get stockChanges30Days => _stockChanges30Days;

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
    // Mock data modunda Firebase'den yükleme yapma
    if (_isMockDataMode) {
      debugPrint('🎬 Skipping Firebase load - Mock data mode active');
      return;
    }

    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma

    _setLoading(true);
    try {
      // ✅ ATOMIK SET: Geçici değişkende hazırla, sonra tek seferde ata
      final newStocks = await _stockRepository.getWatchedStocks(userId);
      
      // Mevcut hisse isimlerini temizle
      final cleanedStocks = newStocks
          .map(
            (stock) => Stock(
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
            ),
          )
          .toList();
      
      // ✅ TEK NOTIFY: Atomik atama - geçici boş durum yok
      _watchedStocks = cleanedStocks;
      _error = null;
      
      debugPrint('📈 loadWatchedStocks: ${cleanedStocks.length} stocks loaded atomically');
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    } finally {
      _setLoading(false);
    }
  }

  // Silent version - UI render olmadan hisse yükle
  Future<void> loadWatchedStocksSilently(String userId) async {
    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma

    _setLoading(true);
    try {
      // ✅ ATOMIK SET: Silent versiyonda da aynı kural
      final newStocks = await _stockRepository.getWatchedStocks(userId);
      
      // Mevcut hisse isimlerini temizle
      final cleanedStocks = newStocks
          .map(
            (stock) => Stock(
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
            ),
          )
          .toList();
      
      // ✅ TEK NOTIFY: Atomik atama - SİLENT versiyonda notifyListeners() yok
      _watchedStocks = cleanedStocks;
      _error = null;
      
      debugPrint('📈 loadWatchedStocksSilently: ${cleanedStocks.length} stocks loaded atomically');
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addWatchedStock(String userId, Stock stock) async {
    try {
      // 1. ÖNCE detaylı hisse bilgilerini API'den çek
      final detailedStock = await _stockApiService.getStockDetails(
        stock.symbol,
      );

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
      if (kDebugMode) {}
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
      if (kDebugMode) {}
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

  // Gerçek zamanlı fiyat güncellemesi (UI render ile)
  Future<void> updateRealTimePrices({bool forceRefresh = false}) async {
    if (_isUpdatingPrices || _watchedStocks.isEmpty) {
      return;
    }

    _setUpdatingPrices(true);

    try {
      // Force refresh ise cache'i bypass et
      if (forceRefresh) {
        debugPrint('🔄 Force refresh: Hisse fiyatlari API\'den guncelleniyor...');
      }

      // .IS uzantısını ekleyerek API'ye gönder
      final symbols = _watchedStocks.map((stock) {
        // Türk hisseleri için .IS uzantısı ekle (BIST, IST, veya Türk hissesi olan)
        if ((stock.exchange == 'BIST' ||
                stock.exchange == 'IST' ||
                stock.currency == 'TRY') &&
            !stock.symbol.endsWith('.IS')) {
          return '${stock.symbol}.IS';
        }
        return stock.symbol;
      }).toList();

      // API çağrısına timeout ekle (10 saniye - splash screen için yeterli süre)
      final updatedStocks = await _stockApiService
          .getRealTimePrices(symbols)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Timeout durumunda boş liste döndür
              return <Stock>[];
            },
          );

      // Mevcut hisseleri güncelle
      for (final updatedStock in updatedStocks) {
        // Sembol eşleştirmesi için .IS uzantısını kaldır
        final cleanSymbol = updatedStock.symbol.replaceAll('.IS', '');
        final index = _watchedStocks.indexWhere(
          (stock) => stock.symbol == cleanSymbol,
        );
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
            // PARTIAL PAYLOAD KORUMA - Mevcut değerleri koru, sadece geçerli olanları güncelle
            openPrice:
                updatedStock.openPrice ?? _watchedStocks[index].openPrice,
            previousClose:
                updatedStock.previousClose ??
                _watchedStocks[index].previousClose,
            historicalData: _watchedStocks[index]
                .historicalData, // Mevcut historicalData'yı koru
          );
        }
      }

      // Pozisyonları da güncelle
      await _updatePositionsWithCurrentPrices();

      // Grafik verilerini de güncelle (daha sık)
      await _updateHistoricalDataForWatchedStocks();

      // Hisse değişimlerini de güncelle (7 ve 30 günlük)
      await _updateStockChangesSilently();

      notifyListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUpdatingPrices(false);
    }
  }

  // Gerçek zamanlı fiyat güncellemesi (UI render olmadan - timer için)
  Future<void> updateRealTimePricesSilently({bool forceRefresh = false}) async {
    if (_isUpdatingPrices || _watchedStocks.isEmpty) {
      return;
    }

    // SİLENT - _setUpdatingPrices() çağırma, notifyListeners() tetikleme
    _isUpdatingPrices = true;

    try {
      // Force refresh ise cache'i bypass et
      if (forceRefresh) {
        debugPrint('🔄 Force refresh (silent): Hisse fiyatlari API\'den guncelleniyor...');
      }

      // .IS uzantısını ekleyerek API'ye gönder
      final symbols = _watchedStocks.map((stock) {
        // Türk hisseleri için .IS uzantısı ekle (BIST, IST, veya Türk hissesi olan)
        if ((stock.exchange == 'BIST' ||
                stock.exchange == 'IST' ||
                stock.currency == 'TRY') &&
            !stock.symbol.endsWith('.IS')) {
          return '${stock.symbol}.IS';
        }
        return stock.symbol;
      }).toList();

      // API çağrısına timeout ekle (3 saniye - daha hızlı)
      final updatedStocks = await _stockApiService
          .getRealTimePrices(symbols)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              // Timeout durumunda boş liste döndür
              return <Stock>[];
            },
          );

      // Mevcut hisseleri güncelle
      for (final updatedStock in updatedStocks) {
        // Sembol eşleştirmesi için .IS uzantısını kaldır
        final cleanSymbol = updatedStock.symbol.replaceAll('.IS', '');
        final index = _watchedStocks.indexWhere(
          (stock) => stock.symbol == cleanSymbol,
        );
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
            // PARTIAL PAYLOAD KORUMA - Mevcut değerleri koru, sadece geçerli olanları güncelle
            openPrice:
                updatedStock.openPrice ?? _watchedStocks[index].openPrice,
            previousClose:
                updatedStock.previousClose ??
                _watchedStocks[index].previousClose,
            historicalData: _watchedStocks[index]
                .historicalData, // Mevcut historicalData'yı koru
          );
        }
      }

      // Pozisyonları da güncelle
      await _updatePositionsWithCurrentPrices();

      // Grafik verilerini de güncelle (daha sık)
      await _updateHistoricalDataForWatchedStocks();

      // Hisse değişimlerini de güncelle (7 ve 30 günlük)
      await _updateStockChangesSilently();

      // SİLENT UPDATE - notifyListeners() çağırma, UI render etme
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      // SİLENT - _setUpdatingPrices() çağırma, notifyListeners() tetikleme
      _isUpdatingPrices = false;
    }
  }

  /// İzlenen hisselerin grafik verilerini güncelle
  Future<void> _updateHistoricalDataForWatchedStocks() async {
    try {
      // Daha sık grafik verilerini güncelle
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

  /// Hisse değişimlerini sessizce güncelle (gerçek zamanlı)
  Future<void> _updateStockChangesSilently() async {
    try {
      if (_watchedStocks.isEmpty) return;
      
      // Dinamik hesaplama kullan
      await _updateDynamicStockChanges();
      
      debugPrint('🔄 Dynamic stock changes updated silently: 7d=${_stockChanges7Days.length}, 30d=${_stockChanges30Days.length}');
    } catch (e) {
      debugPrint('❌ Error updating stock changes silently: $e');
    }
  }

  /// Dinamik hisse değişimlerini güncelle
  Future<void> _updateDynamicStockChanges() async {
    try {
      if (_watchedStocks.isEmpty) {
        debugPrint('🔍 No watched stocks for dynamic changes');
        return;
      }
      
      // Stock transactions'ları yükle (eğer yüklenmemişse)
      if (_stockTransactions.isEmpty) {
        debugPrint('🔄 Loading stock transactions for dynamic changes...');
        final userId = FirebaseAuthService.currentUserId;
        if (userId != null) {
          await loadStockTransactionsSilently(userId);
        }
      }
      
      _stockChangesToday.clear();
      _stockChanges7Days.clear();
      _stockChanges30Days.clear();
      
      for (final stock in _watchedStocks) {
        // Bu hisse için ilk işlem tarihini bul
        final firstTransactionDate = _getFirstTransactionDate(stock.symbol);
        if (firstTransactionDate == null) {
          continue;
        }
        
        final daysSinceFirst = DateTime.now().difference(firstTransactionDate).inDays;
        
        // Bugünkü değişim - her zaman hesapla (piyasa kapalıysa da)
        final changeToday = await _calculateTodayChange(stock.symbol);
        _stockChangesToday[stock.symbol] = changeToday;
        
        if (daysSinceFirst >= 0) {
          // Bugün veya daha önce eklendi - son 7 günlük değişim
          final change7d = await _calculateDynamicChange(stock.symbol, 7, daysSinceFirst);
          _stockChanges7Days[stock.symbol] = change7d;
        }
        
        if (daysSinceFirst >= 0) {
          // Bugün veya daha önce eklendi - son 30 günlük değişim
          final change30d = await _calculateDynamicChange(stock.symbol, 30, daysSinceFirst);
          _stockChanges30Days[stock.symbol] = change30d;
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating dynamic stock changes: $e');
    }
  }

  /// Belirli bir hisse için ilk işlem tarihini bul
  DateTime? _getFirstTransactionDate(String stockSymbol) {
    try {
      // Bu hisse ile ilgili tüm işlemleri filtrele
      final stockTransactions = _stockTransactions
          .where((txn) => txn.stockSymbol == stockSymbol)
          .toList();
      
      if (stockTransactions.isEmpty) {
        return null;
      }
      
      // En eski işlem tarihini bul
      stockTransactions.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      final firstDate = stockTransactions.first.transactionDate;
      
      return firstDate;
    } catch (e) {
      debugPrint('❌ Error getting first transaction date for $stockSymbol: $e');
      return null;
    }
  }

  /// Bugünkü değişim hesapla (hisse modelindeki mevcut değişim verisini kullan)
  Future<double> _calculateTodayChange(String symbol) async {
    try {
      // Hisse modelindeki mevcut değişim yüzdesini al
      final stock = _watchedStocks.firstWhere(
        (s) => s.symbol == symbol,
        orElse: () => throw Exception('Stock not found'),
      );
      
      // Daily performance değişim yüzdesi (zaten hesaplanmış)
      final changePercent = stock.changePercent ?? 0.0;
      
      return changePercent;
    } catch (e) {
      debugPrint('❌ Error calculating today change for $symbol: $e');
      return 0.0;
    }
  }

  /// Dinamik değişim hesapla (gerçek fiyat farkları ile)
  Future<double> _calculateDynamicChange(String symbol, int targetDays, int availableDays) async {
    try {
      // Mevcut gün sayısı ile hedef gün sayısı arasından küçük olanı kullan
      final actualDays = math.min(targetDays, availableDays);
      
      // İlk işlem tarihini bul
      final firstTransactionDate = _getFirstTransactionDate(symbol);
      if (firstTransactionDate == null) return 0.0;
      
      // Başlangıç tarihini hesapla (bugünden geriye doğru)
      final startDate = DateTime.now().subtract(Duration(days: actualDays));
      
      // Başlangıç tarihi ilk işlem tarihinden önceyse, ilk işlem tarihini kullan
      final effectiveStartDate = startDate.isBefore(firstTransactionDate) 
          ? firstTransactionDate 
          : startDate;
      
      // Gerçek gün sayısını hesapla
      final realDays = DateTime.now().difference(effectiveStartDate).inDays;
      
      // Bugün eklenen hisseler için özel mantık
      if (realDays == 0) {
        // Bugün eklenen hisse - bugünkü değişimi hesapla
        final currentPrice = await _getCurrentPrice(symbol);
        final openPrice = await _getTodayOpenPrice(symbol);
        
        if (currentPrice == null || openPrice == null || openPrice <= 0) {
          debugPrint('❌ Cannot calculate change for $symbol: currentPrice=$currentPrice, openPrice=$openPrice');
          return 0.0;
        }
        
        final changePercent = ((currentPrice - openPrice) / openPrice) * 100;
        debugPrint('📊 Today change for $symbol: ${openPrice.toStringAsFixed(2)} → ${currentPrice.toStringAsFixed(2)} = ${changePercent.toStringAsFixed(2)}%');
        return changePercent;
      }
      
      if (realDays < 0) return 0.0;
      
      // Güncel fiyatı al (canlı fiyat - piyasa açıksa bugünkü değişim dahil)
      final currentPrice = await _getCurrentPrice(symbol);
      if (currentPrice == null) return 0.0;
      
      // Başlangıç fiyatını al
      double? startPrice;
      
      // Eğer bugün işlem yapıldıysa ve piyasa açıksa, bugünkü açılış fiyatını kullan
      if (effectiveStartDate.day == DateTime.now().day && 
          effectiveStartDate.month == DateTime.now().month &&
          effectiveStartDate.year == DateTime.now().year) {
        startPrice = await _getTodayOpenPrice(symbol);
      }
      
      // Eğer bugünkü açılış fiyatı bulunamazsa, geçmiş fiyatı kullan
      startPrice ??= await _getHistoricalPrice(symbol, effectiveStartDate);
      
      if (startPrice == null || startPrice <= 0) {
        return 0.0;
      }
      
      // Gerçek değişim yüzdesini hesapla
      final changePercent = ((currentPrice - startPrice) / startPrice) * 100;
      
      final isMarketOpen = _isMarketOpen();
      final marketStatus = isMarketOpen ? 'AÇIK' : 'KAPALI';
      
      debugPrint('📊 Dynamic change for $symbol: ${realDays} days, ${startPrice.toStringAsFixed(2)} → ${currentPrice.toStringAsFixed(2)} = ${changePercent.toStringAsFixed(2)}% (Piyasa: $marketStatus)');
      
      return changePercent;
    } catch (e) {
      debugPrint('❌ Error calculating dynamic change for $symbol: $e');
      return 0.0;
    }
  }

  /// Bugünkü açılış fiyatını al
  Future<double?> _getTodayOpenPrice(String symbol) async {
    try {
      final stock = _watchedStocks.firstWhere(
        (s) => s.symbol == symbol,
        orElse: () => throw Exception('Stock not found'),
      );
      return stock.openPrice;
    } catch (e) {
      debugPrint('❌ Error getting today open price for $symbol: $e');
      return null;
    }
  }

  /// Piyasa açık mı kontrol et (basit kontrol)
  bool _isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    
    // Hafta sonu değilse ve 09:00-18:00 arasındaysa piyasa açık
    return weekday >= 1 && weekday <= 5 && hour >= 9 && hour < 18;
  }

  /// Güncel fiyatı al
  Future<double?> _getCurrentPrice(String symbol) async {
    try {
      final stock = _watchedStocks.firstWhere(
        (s) => s.symbol == symbol,
        orElse: () => throw Exception('Stock not found'),
      );
      return stock.currentPrice;
    } catch (e) {
      debugPrint('❌ Error getting current price for $symbol: $e');
      return null;
    }
  }

  /// Belirli bir tarihteki fiyatı al
  Future<double?> _getHistoricalPrice(String symbol, DateTime date) async {
    try {
      // API'den o tarihteki fiyatı al
      final historicalData = await _stockApiService.getHistoricalPrices(
        symbol,
        '1d',
        '30d', // 30 günlük veri al, içinden istediğimizi seçeriz
      );
      
      if (historicalData.isEmpty) return null;
      
      // Tarihe en yakın fiyatı bul
      double? closestPrice;
      DateTime? closestDate;
      
      for (final priceData in historicalData) {
        final priceDate = priceData.timestamp; // timestamp kullan
        final daysDiff = date.difference(priceDate).inDays.abs();
        
        if (closestDate == null || 
            daysDiff < date.difference(closestDate).inDays.abs()) {
          closestPrice = priceData.close;
          closestDate = priceDate;
        }
      }
      
      return closestPrice;
    } catch (e) {
      debugPrint('❌ Error getting historical price for $symbol on ${date.toIso8601String()}: $e');
      return null;
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
      // STATE RESET KORUMA - Mevcut stock verilerini koru
      final currentStock = _watchedStocks.firstWhere(
        (stock) => stock.symbol == position.stockSymbol,
        orElse: () {
          // Mevcut stock verilerini koru, sadece gerekli alanları güncelle
          final existingStock =
              _watchedStocks
                  .where((s) => s.symbol == position.stockSymbol)
                  .isNotEmpty
              ? _watchedStocks.firstWhere(
                  (s) => s.symbol == position.stockSymbol,
                )
              : null;

          return existingStock ??
              Stock(
                symbol: position.stockSymbol,
                name: position.stockName,
                exchange: '',
                currency: 'TRY',
                currentPrice: position.averagePrice,
                changeAmount: 0,
                changePercent: 0,
                lastUpdated: DateTime.now(),
                sector: '',
                country: '',
              );
        },
      );

      final newCurrentValue =
          position.totalQuantity * currentStock.currentPrice;
      final newProfitLoss = newCurrentValue - position.totalCost;
      final newProfitLossPercent = position.totalCost > 0
          ? ((newProfitLoss / position.totalCost) * 100).toDouble()
          : 0.0;

      // Geçerli veri kontrolü
      if (newCurrentValue < 0 ||
          newProfitLoss.isNaN ||
          newProfitLossPercent.isNaN) {
        hasValidData = false;
        break;
      }

      // Değişiklik var mı kontrol et
      if ((position.currentValue - newCurrentValue).abs() > 0.01 ||
          (position.profitLoss - newProfitLoss).abs() > 0.01) {
        hasChanges = true;
      }

      newPositions.add(
        StockPosition(
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
        ),
      );
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
        final detailedStock = await _stockApiService.getStockDetails(
          stock.symbol,
        );

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
            historicalData:
                stock.historicalData, // Mevcut historicalData'yı koru
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
      if (kDebugMode) {}
      return [];
    }
  }

  Future<List<Stock>> getBistStocks() async {
    try {
      return await _stockApiService.getBistStocks();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
      return [];
    }
  }

  // Hisse işlem işlemleri - Silent loading ile anında UI güncelleme
  Future<void> executeStockTransaction(StockTransaction transaction) async {
    try {
      // ✅ OPTIMISTIC UI UPDATE: Önce UI'yi güncelle
      _updateUIOptimistically(transaction);
      
      // ✅ SILENT BACKGROUND EXECUTION: Arka planda işlemi yap
      Future.microtask(() async {
        try {
          if (transaction.type == StockTransactionType.buy) {
            await _transactionService.executeBuyTransaction(transaction);
          } else {
            await _transactionService.executeSellTransaction(transaction);
          }

          // İşlemler ve pozisyonları yenile (silent)
          await loadStockTransactionsSilently(transaction.userId);
          await loadStockPositionsSilently(transaction.userId);

          // UnifiedProviderV2'yi güncelle (home screen için)
          try {
            final unifiedProvider = UnifiedProviderV2.instance;

            // Hisse pozisyonlarını güncelle
            final stockPositions = _stockPositions
                .map(
                  (position) => {
                    'symbol': position.stockSymbol,
                    'quantity': position.totalQuantity,
                    'currentValue': position.currentValue,
                    'totalValue': position.currentValue,
                    'totalCost': position.totalCost,
                  },
                )
                .toList();
            unifiedProvider.updateStockPositions(stockPositions);

            await unifiedProvider.refresh();
          } catch (e) {
            // UnifiedProviderV2 güncelleme hatası kritik değil
            if (kDebugMode) {}
          }

          _error = null;
        } catch (e) {
          // ✅ HATA DURUMUNDA GERİ YÜKLE: Optimistic update'i geri al
          _revertOptimisticUpdate(transaction);
          _error = e.toString();
          notifyListeners();
        }
      });

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadStockTransactions(String userId) async {
    try {
      _stockTransactions = await _transactionService.getStockTransactions(
        userId,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    }
  }

  // Silent version - UI render olmadan transaction yükle
  Future<void> loadStockTransactionsSilently(String userId) async {
    try {
      _stockTransactions = await _transactionService.getStockTransactions(
        userId,
      );
      _error = null;
      // Silent - notifyListeners() yok
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    }
  }

  Future<void> loadStockPositions(String userId) async {
    try {
      final firebasePositions = await _transactionService.getAllStockPositions(
        userId,
      );

      // Sıfır adetli pozisyonları filtrele
      final validPositions = firebasePositions
          .where((pos) => pos.totalQuantity > 0)
          .toList();

      // ✅ ATOMIK SET: Geçici değişkende hazırla, sonra tek seferde ata
      final newPositions = <StockPosition>[];

      // Mevcut pozisyonları koruyarak güncelle
      if (_stockPositions.isNotEmpty) {
        // Mevcut pozisyonları koru, sadece eksik olanları ekle
        for (final firebasePosition in validPositions) {
          final existingIndex = _stockPositions.indexWhere(
            (pos) => pos.stockSymbol == firebasePosition.stockSymbol,
          );

          if (existingIndex != -1) {
            // Mevcut pozisyonu güncelle (sadece temel bilgileri)
            newPositions.add(StockPosition(
              stockSymbol: firebasePosition.stockSymbol,
              stockName: firebasePosition.stockName,
              totalQuantity: firebasePosition.totalQuantity,
              averagePrice: firebasePosition.averagePrice,
              totalCost: firebasePosition.totalCost,
              currentValue: _stockPositions[existingIndex]
                  .currentValue, // Güncel değeri koru
              profitLoss: _stockPositions[existingIndex]
                  .profitLoss, // Güncel kar/zararı koru
              profitLossPercent: _stockPositions[existingIndex]
                  .profitLossPercent, // Güncel yüzdeyi koru
              lastUpdated: _stockPositions[existingIndex]
                  .lastUpdated, // Güncel tarihi koru
              currency: firebasePosition.currency,
              historicalData: _stockPositions[existingIndex]
                  .historicalData, // Geçmiş veriyi koru
            ));
          } else {
            // Yeni pozisyon ekle
            newPositions.add(firebasePosition);
          }
        }

        // Sıfır adetli pozisyonları UI'dan kaldır
        newPositions.removeWhere((pos) => pos.totalQuantity <= 0);
      } else {
        // İlk yükleme - sadece geçerli pozisyonları yükle
        newPositions.addAll(validPositions);
      }

      // ✅ TEK NOTIFY: Atomik atama - geçici boş durum yok
      _stockPositions = newPositions;
      _error = null;
      
      debugPrint('💼 loadStockPositions: ${newPositions.length} positions loaded atomically');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    }
  }

  // Silent version - UI render olmadan pozisyon yükle
  Future<void> loadStockPositionsSilently(String userId) async {
    try {
      final firebasePositions = await _transactionService.getAllStockPositions(
        userId,
      );

      // Sıfır adetli pozisyonları filtrele
      final validPositions = firebasePositions
          .where((pos) => pos.totalQuantity > 0)
          .toList();

      // Mevcut pozisyonları koruyarak güncelle
      if (_stockPositions.isNotEmpty) {
        // Mevcut pozisyonları koru, sadece eksik olanları ekle
        for (final firebasePosition in validPositions) {
          final existingIndex = _stockPositions.indexWhere(
            (pos) => pos.stockSymbol == firebasePosition.stockSymbol,
          );

          if (existingIndex != -1) {
            // Mevcut pozisyonu güncelle (sadece temel bilgileri)
            _stockPositions[existingIndex] = StockPosition(
              stockSymbol: firebasePosition.stockSymbol,
              stockName: firebasePosition.stockName,
              totalQuantity: firebasePosition.totalQuantity,
              averagePrice: firebasePosition.averagePrice,
              totalCost: firebasePosition.totalCost,
              currentValue: _stockPositions[existingIndex]
                  .currentValue, // Mevcut değeri koru
              profitLoss: _stockPositions[existingIndex]
                  .profitLoss, // Mevcut kar/zararı koru
              profitLossPercent: _stockPositions[existingIndex]
                  .profitLossPercent, // Mevcut yüzdeyi koru
              lastUpdated: _stockPositions[existingIndex]
                  .lastUpdated, // Güncel tarihi koru
              currency: firebasePosition.currency,
              historicalData: _stockPositions[existingIndex]
                  .historicalData, // Geçmiş veriyi koru
            );
          } else {
            // Yeni pozisyon ekle
            _stockPositions.add(firebasePosition);
          }
        }

        // Sıfır adetli pozisyonları UI'dan kaldır
        _stockPositions.removeWhere((pos) => pos.totalQuantity <= 0);
      } else {
        // İlk yükleme - sadece geçerli pozisyonları yükle
        _stockPositions = validPositions;
      }

      _error = null;
      // SİLENT - notifyListeners() çağırma
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
    }
  }

  Future<StockPosition?> getStockPosition(
    String userId,
    String stockSymbol,
  ) async {
    try {
      return await _transactionService.getStockPosition(userId, stockSymbol);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
      return null;
    }
  }

  /// Pozisyonları sıfırlayan ve watched listten kaldıran metod
  Future<void> clearZeroPositionsAndRemoveFromWatchedList(String userId) async {
    try {
      // 1. Sıfır adetli pozisyonları bul
      final zeroPositions = _stockPositions.where((pos) => pos.totalQuantity <= 0).toList();
      
      if (zeroPositions.isEmpty) return;
      
      // 2. Bu pozisyonları watched listten kaldır
      for (final position in zeroPositions) {
        await removeWatchedStock(userId, position.stockSymbol);
      }
      
      // 3. Pozisyonları güncelle
      await loadStockPositions(userId);
      
      debugPrint('🧹 Cleared ${zeroPositions.length} zero positions and removed from watched list');
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('Error clearing zero positions: $e');
      }
    }
  }

  /// Tüm pozisyonları sıfırla ve watched listten kaldır
  Future<void> clearAllPositionsAndRemoveFromWatchedList(String userId) async {
    try {
      // 1. Tüm pozisyonları watched listten kaldır
      for (final position in _stockPositions) {
        await removeWatchedStock(userId, position.stockSymbol);
      }
      
      // 2. Pozisyonları temizle
      _stockPositions.clear();
      
      // 3. UI'yi güncelle
      notifyListeners();
      
      debugPrint('🧹 Cleared all positions and removed from watched list');
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('Error clearing all positions: $e');
      }
    }
  }

  /// Check if stock transaction can be deleted (when lot count is 0)
  bool canDeleteStockTransaction(String stockSymbol) {
    try {
      final position = _stockPositions.firstWhere(
        (pos) => pos.stockSymbol == stockSymbol,
      );
      return position.totalQuantity <= 0;
    } catch (e) {
      // Stock not found in positions, can delete
      return true;
    }
  }

  Future<void> deleteStockTransaction(String transactionId) async {
    try {
      // 1. Find transaction to get stock symbol
      final transaction = _stockTransactions.firstWhere(
        (t) => t.id == transactionId,
      );
      
      // 2. Check if deletion is allowed (lot count must be 0)
      if (!canDeleteStockTransaction(transaction.stockSymbol)) {
        throw Exception('Hisse pozisyonu mevcut olduğu için işlem silinemez');
      }

      // 3. OPTIMISTIC UI UPDATE - Önce UI'yi anında güncelle
      _removeTransactionFromUI(transactionId);
      
      // 4. UnifiedProviderV2'yi hemen güncelle (home screen için)
      _updateUnifiedProvider();

      // 5. Backend işlemini yap
      await _transactionService.deleteStockTransaction(transactionId);

      // 6. User ID'yi al
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // 7. Arka planda verileri yenile (UI zaten güncellenmiş)
      _refreshAllDataInBackground(userId);
    } catch (e) {
      _error = e.toString();

      // Hata durumunda UI'yi geri yükle
      _refreshAllDataInBackground(FirebaseAuthService.currentUserId ?? '');

      if (kDebugMode) {
        debugPrint('Error deleting stock transaction: $e');
      }
      rethrow; // Re-throw to show error to user
    }
  }

  /// UI'den transaction'ı anında kaldır (optimistic update)
  void _removeTransactionFromUI(String transactionId) {
    try {
      // 1. Stock transactions listesinden kaldır
      _stockTransactions.removeWhere((transaction) => transaction.id == transactionId);
      
      // 2. UI'yi güncelle
      notifyListeners();
      
      debugPrint('✅ Stock transaction $transactionId removed from UI (optimistic update)');
    } catch (e) {
      debugPrint('❌ Error removing transaction from UI: $e');
    }
  }

  /// UnifiedProviderV2'yi güncelle (home screen için)
  void _updateUnifiedProvider() {
    try {
      final unifiedProvider = UnifiedProviderV2.instance;
      
      // Hisse pozisyonlarını güncelle
      final stockPositions = _stockPositions
          .map(
            (position) => {
              'symbol': position.stockSymbol,
              'quantity': position.totalQuantity,
              'currentValue': position.currentValue,
              'totalValue': position.currentValue,
              'totalCost': position.totalCost,
            },
          )
          .toList();
      unifiedProvider.updateStockPositions(stockPositions);
      
      // UnifiedProviderV2'yi refresh et
      unifiedProvider.refresh();
      
      debugPrint('✅ UnifiedProviderV2 updated after stock transaction deletion');
    } catch (e) {
      debugPrint('⚠️ Error updating UnifiedProviderV2: $e');
    }
  }

  /// Arka planda verileri yenile (UI zaten güncellenmiş)
  void _refreshAllDataInBackground(String userId) {
    // ✅ VERİ KORUMA: Mevcut veriyi koru, hata durumunda geri yükle
    final currentStocks = List<Stock>.from(_watchedStocks);
    final currentPositions = List<StockPosition>.from(_stockPositions);
    final currentTransactions = List<StockTransaction>.from(_stockTransactions);
    
    // Arka planda çalıştır, UI'yi bloklamasın
    Future.microtask(() async {
      try {
        // ✅ SILENT REFRESH: UI'yi boşaltmadan yenile
        await loadWatchedStocksSilently(userId);
        await loadStockPositions(userId); // Pozisyon bilgilerini de yenile
        await loadStockTransactions(userId); // Stock transactions'ları da yenile
        await updateRealTimePricesSilently();
        
        // Hisse değişimlerini de güncelle
        await _updateStockChangesSilently();
        
        debugPrint('🔄 Background refresh completed successfully');
      } catch (e) {
        // ✅ HATA DURUMUNDA GERİ YÜKLE: Mevcut veriyi koru
        _watchedStocks = currentStocks;
        _stockPositions = currentPositions;
        _stockTransactions = currentTransactions;
        debugPrint('⚠️ Background refresh failed, restored previous data: $e');
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

      // Real-time prices'ları güncelle - BUNU YAPMAYALIM, zaten splash'te yapıldı
      // await updateRealTimePricesSilently();
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
      return await _stockApiService.getHistoricalPrices(
        symbol,
        interval,
        range,
      );
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {}
      return [];
    }
  }

  // Portföy hesaplamaları
  double get totalPortfolioValue {
    return _stockPositions.fold(
      0.0,
      (sum, position) => sum + position.currentValue,
    );
  }

  double get totalPortfolioCost {
    return _stockPositions.fold(
      0.0,
      (sum, position) => sum + position.totalCost,
    );
  }

  double get totalProfitLoss {
    return _stockPositions.fold(
      0.0,
      (sum, position) => sum + position.profitLoss,
    );
  }

  double get totalProfitLossPercent {
    if (totalPortfolioCost == 0) return 0.0;
    return (totalProfitLoss / totalPortfolioCost) * 100;
  }

  // Optimistic UI Update Methods
  void _updateUIOptimistically(StockTransaction transaction) {
    if (transaction.type == StockTransactionType.buy) {
      _updateBuyOptimistically(transaction);
    } else {
      _updateSellOptimistically(transaction);
    }
    notifyListeners();
  }

  void _updateBuyOptimistically(StockTransaction transaction) {
    final existingIndex = _stockPositions.indexWhere(
      (pos) => pos.stockSymbol == transaction.stockSymbol,
    );

    if (existingIndex != -1) {
      // Mevcut pozisyonu güncelle
      final currentPosition = _stockPositions[existingIndex];
      final newTotalQuantity = currentPosition.totalQuantity + transaction.quantity;
      final newTotalCost = currentPosition.totalCost + transaction.totalAmount;
      final newAveragePrice = newTotalCost / newTotalQuantity;

      _stockPositions[existingIndex] = StockPosition(
        stockSymbol: transaction.stockSymbol,
        stockName: transaction.stockName,
        totalQuantity: newTotalQuantity,
        averagePrice: newAveragePrice,
        totalCost: newTotalCost,
        currentValue: newTotalQuantity * transaction.price,
        profitLoss: (newTotalQuantity * transaction.price) - newTotalCost,
        profitLossPercent: newTotalCost > 0 
            ? (((newTotalQuantity * transaction.price) - newTotalCost) / newTotalCost) * 100
            : 0.0,
        lastUpdated: DateTime.now(),
        currency: 'TRY', // Default currency for stock transactions
        historicalData: currentPosition.historicalData,
      );
    } else {
      // Yeni pozisyon oluştur
      final newPosition = StockPosition(
        stockSymbol: transaction.stockSymbol,
        stockName: transaction.stockName,
        totalQuantity: transaction.quantity,
        averagePrice: transaction.price,
        totalCost: transaction.totalAmount,
        currentValue: transaction.totalAmount,
        profitLoss: 0.0,
        profitLossPercent: 0.0,
        lastUpdated: DateTime.now(),
        currency: 'TRY', // Default currency for stock transactions
        historicalData: [],
      );
      _stockPositions.add(newPosition);
    }
  }

  void _updateSellOptimistically(StockTransaction transaction) {
    final existingIndex = _stockPositions.indexWhere(
      (pos) => pos.stockSymbol == transaction.stockSymbol,
    );

    if (existingIndex != -1) {
      final currentPosition = _stockPositions[existingIndex];
      final newTotalQuantity = currentPosition.totalQuantity - transaction.quantity;

      if (newTotalQuantity <= 0) {
        // Pozisyonu kaldır
        _stockPositions.removeAt(existingIndex);
      } else {
        // Pozisyonu güncelle
        final newTotalCost = currentPosition.totalCost - 
            (currentPosition.averagePrice * transaction.quantity);

        _stockPositions[existingIndex] = StockPosition(
          stockSymbol: transaction.stockSymbol,
          stockName: transaction.stockName,
          totalQuantity: newTotalQuantity,
          averagePrice: currentPosition.averagePrice,
          totalCost: newTotalCost,
          currentValue: newTotalQuantity * transaction.price,
          profitLoss: (newTotalQuantity * transaction.price) - newTotalCost,
          profitLossPercent: newTotalCost > 0 
              ? (((newTotalQuantity * transaction.price) - newTotalCost) / newTotalCost) * 100
              : 0.0,
          lastUpdated: DateTime.now(),
          currency: 'TRY', // Default currency for stock transactions
          historicalData: currentPosition.historicalData,
        );
      }
    }
  }

  void _revertOptimisticUpdate(StockTransaction transaction) {
    // Optimistic update'i geri almak için pozisyonları yeniden yükle
    final userId = FirebaseAuthService.currentUserId;
    if (userId != null) {
      loadStockPositions(userId);
    }
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
  Future<void> loadHistoricalData(
    String symbol, {
    int days = 30,
    bool forceReload = false,
  }) async {
    try {
      if (_historicalData.containsKey(symbol) && !forceReload) {
        return; // Zaten yüklü
      }

      final historicalData = await _stockApiService.getHistoricalData(
        symbol,
        days: days,
      );
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
    } catch (e) {}
  }

  /// Stock positions'ı geçmiş veri ile güncelle
  void _updatePositionsWithHistoricalData(
    String symbol,
    List<double> historicalData,
  ) {
    final positionIndex = _stockPositions.indexWhere(
      (p) => p.stockSymbol == symbol,
    );

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
    } else {}
  }

  /// Tüm izlenen hisseler için geçmiş veri yükle
  Future<void> loadAllHistoricalData({int days = 30}) async {
    final futures = _watchedStocks
        .map((stock) => loadHistoricalData(stock.symbol, days: days))
        .toList();

    await Future.wait(futures);
  }

  /// Belirli bir hisse için geçmiş veri getir
  List<double>? getHistoricalData(String symbol) {
    return _historicalData[symbol];
  }

  // ==================== MOCK DATA METHODS ====================
  // For Play Store screenshots only - DO NOT USE IN PRODUCTION

  /// Load mock stock data for screenshots
  void loadMockStockData(
    List<Stock> mockStocks,
    List<StockPosition> mockPositions,
    List<StockTransaction> mockTransactions,
  ) {
    debugPrint('📸 Loading mock stock data for screenshots...');

    _isMockDataMode = true; // Enable mock data mode
    _watchedStocks = mockStocks;
    _stockPositions = mockPositions;
    _stockTransactions = mockTransactions;

    // Generate some historical data for visual effect
    _historicalData = {};
    for (var stock in mockStocks) {
      _historicalData[stock.symbol] = _generateMockHistoricalData(
        stock.currentPrice,
        stock.changePercent,
      );
    }

    _isLoading = false;
    _error = null;

    notifyListeners();

    debugPrint('✅ Mock stock data loaded!');
    debugPrint('   📊 Watched Stocks: ${_watchedStocks.length}');
    debugPrint('   💼 Positions: ${_stockPositions.length}');
    debugPrint('   📝 Transactions: ${_stockTransactions.length}');
  }

  /// Generate mock historical data for graphs
  List<double> _generateMockHistoricalData(
    double currentPrice,
    double changePercent,
  ) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final points = 30;
    final data = <double>[];

    // Calculate starting price based on change percent
    final priceRange = currentPrice * (changePercent.abs() / 100);
    var price = currentPrice - priceRange;

    for (var i = 0; i < points; i++) {
      // Add some variance
      final variance = (random + i) % 5 - 2; // -2 to +2
      price += variance;
      data.add(price.clamp(currentPrice * 0.8, currentPrice * 1.2));
    }

    // Make sure last point is current price
    data[points - 1] = currentPrice;

    return data;
  }

  /// Clear mock data and reset
  void clearMockStockData() {
    debugPrint('🧹 Clearing mock stock data...');

    _isMockDataMode = false; // Disable mock data mode
    _watchedStocks.clear();
    _stockPositions.clear();
    _stockTransactions.clear();
    _historicalData.clear();

    _isLoading = false;
    _error = null;

    notifyListeners();

    debugPrint('✅ Mock stock data cleared');
  }

  /// Son 7 günlük değişimleri yükle (dinamik)
  Future<void> loadStockChanges7Days() async {
    try {
      if (_watchedStocks.isEmpty) return;
      
      // Dinamik hesaplama kullan
      await _updateDynamicStockChanges();
      notifyListeners();
      
      debugPrint('✅ Dynamic 7-day stock changes loaded: ${_stockChanges7Days.length} stocks');
    } catch (e) {
      debugPrint('❌ Error loading dynamic 7-day changes: $e');
    }
  }

  /// Son 30 günlük değişimleri yükle (dinamik)
  Future<void> loadStockChanges30Days() async {
    try {
      if (_watchedStocks.isEmpty) return;
      
      // Dinamik hesaplama kullan
      await _updateDynamicStockChanges();
      notifyListeners();
      
      debugPrint('✅ Dynamic 30-day stock changes loaded: ${_stockChanges30Days.length} stocks');
    } catch (e) {
      debugPrint('❌ Error loading dynamic 30-day changes: $e');
    }
  }

  /// Belirli bir hisse için bugünkü değişim al
  double getStockChangeToday(String symbol) {
    return _stockChangesToday[symbol] ?? 0.0;
  }

  /// Belirli bir hisse için 7 günlük değişim al
  double getStockChange7Days(String symbol) {
    return _stockChanges7Days[symbol] ?? 0.0;
  }

  /// Belirli bir hisse için 30 günlük değişim al
  double getStockChange30Days(String symbol) {
    return _stockChanges30Days[symbol] ?? 0.0;
  }

  /// Clear all data (logout)
  Future<void> clearAllData() async {
    try {
      debugPrint('🧹 Clearing all stock data...');
      
      _watchedStocks.clear();
      _stockPositions.clear();
      _stockTransactions.clear();
      _historicalData.clear();
      _stockChangesToday.clear();
      _stockChanges7Days.clear();
      _stockChanges30Days.clear();
      _isLoading = false;
      _isUpdatingPrices = false;
      _error = null;
      _isMockDataMode = false;
      
      notifyListeners();
      
      debugPrint('✅ All stock data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing stock data: $e');
    }
  }
}
