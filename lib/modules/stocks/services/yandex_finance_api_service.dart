import 'dart:convert';
import 'package:http/http.dart' as http;
import '../contracts/stock_api_contract.dart';
import '../exceptions/stock_exceptions.dart';
import '../../../shared/models/stock_models.dart';

/// Yandex Finance API servisi implementasyonu
class YandexFinanceApiService implements IStockApiService {
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const String _searchUrl = 'https://query1.finance.yahoo.com/v1/finance/search';
  static const String _quoteUrl = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary';
  
  @override
  Future<List<Stock>> searchStocks(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}&quotesCount=20'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSearchResults(data);
      } else {
        throw StockApiException(
          'Search request failed with status: ${response.statusCode}',
          'SEARCH_FAILED',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StockApiException) rethrow;
      throw StockApiException('Search request failed: $e', 'SEARCH_ERROR');
    }
  }
  
  @override
  Future<Stock?> getStockDetails(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseStockData(symbol, data);
      } else if (response.statusCode == 404) {
        return null; // Hisse bulunamadı
      } else {
        throw StockApiException(
          'Failed to get stock details: ${response.statusCode}',
          'DETAILS_FAILED',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StockApiException) rethrow;
      throw StockApiException('Failed to get stock details: $e', 'DETAILS_ERROR');
    }
  }
  
  @override
  Future<List<Stock>> getRealTimePrices(List<String> symbols) async {
    if (symbols.isEmpty) return [];
    
    
    // Türk hisseleri için doğru sembolleri kullan
    final correctedSymbols = symbols.map((symbol) => _getCorrectTurkishSymbol(symbol)).toList();
    
    // Tüm hisseleri paralel olarak çek
    final futures = correctedSymbols.map((symbol) => _fetchStockWithErrorHandling(symbol));
    
    // Tüm istekleri aynı anda başlat ve sonuçları bekle
    final results = await Future.wait(futures, eagerError: false);
    
    // Null olmayan sonuçları filtrele
    final stocks = results.where((stock) => stock != null).cast<Stock>().toList();
    
    
    return stocks;
  }
  
  /// Tek hisse çekme işlemini hata yönetimi ile sarmalayıp paralel çalıştırma için hazırla
  Future<Stock?> _fetchStockWithErrorHandling(String symbol) async {
    try {
      final stock = await getStockDetails(symbol);
      if (stock != null) {
      } else {
      }
      return stock;
    } catch (e) {
      return null; // Hata durumunda null döndür, diğer hisseleri etkilemesin
    }
  }
  
  @override
  Future<List<StockPrice>> getHistoricalPrices(
    String symbol, 
    String interval, 
    String range,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$symbol?interval=$interval&range=$range'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseStockPrices(data);
      } else {
        throw StockApiException(
          'Failed to get historical data: ${response.statusCode}',
          'HISTORICAL_FAILED',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StockApiException) rethrow;
      throw StockApiException('Failed to get historical data: $e', 'HISTORICAL_ERROR');
    }
  }
  
  @override
  Future<List<Stock>> getPopularStocks() async {
    // Popüler hisseler listesi
    final List<String> popularSymbols = [
      'AAPL',   // Apple
      'MSFT',   // Microsoft
      'GOOGL',  // Google
      'AMZN',   // Amazon
      'TSLA',   // Tesla
      'META',   // Meta
      'NVDA',   // NVIDIA
      'NFLX',   // Netflix
      'AMD',    // AMD
      'INTC',   // Intel
    ];
    
    return getRealTimePrices(popularSymbols);
  }
  
  @override
  Future<List<Stock>> getBistStocks() async {
    final List<String> bistSymbols = [
      'SASA.IS',    // Sabancı Holding
      'THYAO.IS',   // Türk Hava Yolları
      'EREGL.IS',   // Eregli Demir Çelik
      'TUPRS.IS',   // Tüpraş
      'AKBNK.IS',   // Akbank
      'GARAN.IS',   // Garanti BBVA
      'ISCTR.IS',   // İş Bankası
      'KRDMD.IS',   // Kardemir
      'KOZAL.IS',   // Koza Altın
      'PETKM.IS',   // Petkim
      'SAHOL.IS',   // Sabancı Holding
      'SISE.IS',    // Şişe Cam
      'TCELL.IS',   // Turkcell
      'VAKBN.IS',   // VakıfBank
      'YKBNK.IS',   // Yapı Kredi
    ];
    
    return getRealTimePrices(bistSymbols);
  }
  
  @override
  Future<List<Stock>> getUsStocks() async {
    return getPopularStocks();
  }
  
  // Private parsing methods
  List<Stock> _parseSearchResults(Map<String, dynamic> data) {
    final List<Stock> stocks = [];
    
    try {
      final quotes = data['quotes'] as List?;
      if (quotes == null) return stocks;
      
      for (var quote in quotes) {
        final symbol = quote['symbol'] as String?;
        if (symbol == null) continue;
        
        // Exchange bilgisini düzelt
        String exchange = quote['exchange'] ?? '';
        String currency = quote['currency'] ?? 'USD';
        
        // Türk hisseleri için exchange ve currency düzelt
        if (_isTurkishStock(symbol, quote)) {
          exchange = 'BIST';
          currency = 'TRY';
        }
        
        final stock = Stock(
          symbol: _cleanStockName(symbol),
          name: _cleanStockName(quote['longname'] ?? quote['shortname'] ?? symbol),
          exchange: exchange,
          currency: currency,
          currentPrice: 0.0, // Arama sonuçlarında fiyat yok
          changeAmount: 0.0,
          changePercent: 0.0,
          lastUpdated: DateTime.now(),
          sector: quote['sector'] ?? '',
          country: quote['country'] ?? '',
        );
        
        stocks.add(stock);
      }
    } catch (e) {
    }
    
    return stocks;
  }
  
  Stock? _parseStockData(String symbol, Map<String, dynamic> data) {
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return null;
      
      final meta = result['meta'];
      if (meta == null) return null;
      
      final currentPrice = meta['regularMarketPrice']?.toDouble() ?? 0.0;
      final previousClose = meta['previousClose']?.toDouble() ?? 0.0;
      final change = meta['regularMarketChange']?.toDouble() ?? (currentPrice - previousClose);
      
      // changePercent hesaplama - API'den gelen değeri kullan veya hesapla
      double changePercent = 0.0;
      if (meta['regularMarketChangePercent'] != null) {
        // API'den gelen yüzde değerini kullan
        changePercent = meta['regularMarketChangePercent'].toDouble();
      } else if (previousClose != 0) {
        // previousClose varsa hesapla
        changePercent = (change / previousClose) * 100;
      } else if (currentPrice != 0) {
        // currentPrice'dan tahmin et (yaklaşık %1-2 değişim varsayımı)
        changePercent = (change / currentPrice) * 100;
      }
      
      // Debug: changePercent hesaplamasını kontrol et
      
      // Günün en yüksek/düşük ve işlem hacmi
      final dayHigh = meta['regularMarketDayHigh']?.toDouble();
      final dayLow = meta['regularMarketDayLow']?.toDouble();
      final volume = meta['regularMarketVolume']?.toDouble();
      
      // Exchange ve currency bilgisini düzelt
      String exchange = meta['exchangeName'] ?? '';
      String currency = meta['currency'] ?? 'USD';
      
      // Türk hisseleri için exchange ve currency düzelt
      if (symbol.endsWith('.IS') || (meta['country'] == 'Turkey' || meta['country'] == 'TR')) {
        exchange = 'BIST';
        currency = 'TRY';
      }
      
      return Stock(
        symbol: _cleanStockName(symbol),
        name: _cleanStockName(meta['longName'] ?? symbol),
        exchange: exchange,
        currency: currency,
        currentPrice: currentPrice,
        changeAmount: change,
        changePercent: changePercent,
        lastUpdated: DateTime.now(),
        sector: meta['sector'] ?? '',
        country: meta['country'] ?? '',
        dayHigh: dayHigh,
        dayLow: dayLow,
        volume: volume,
      );
        } catch (e) {
          return null;
        }
  }
  
  List<StockPrice> _parseStockPrices(Map<String, dynamic> data) {
    final List<StockPrice> prices = [];
    
    try {
      final result = data['chart']?['result']?[0];
      if (result == null) return prices;
      
      final timestamps = result['timestamp'] as List?;
      final quote = result['indicators']?['quote']?[0];
      
      if (timestamps == null || quote == null) return prices;
      
      final opens = quote['open'] as List?;
      final highs = quote['high'] as List?;
      final lows = quote['low'] as List?;
      final closes = quote['close'] as List?;
      final volumes = quote['volume'] as List?;
      
      for (int i = 0; i < timestamps.length; i++) {
        if (closes?[i] == null) continue;
        
        final price = StockPrice(
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          open: opens?[i]?.toDouble() ?? 0.0,
          high: highs?[i]?.toDouble() ?? 0.0,
          low: lows?[i]?.toDouble() ?? 0.0,
          close: closes?[i]?.toDouble() ?? 0.0,
          volume: volumes?[i]?.toDouble() ?? 0.0,
        );
        
        prices.add(price);
      }
    } catch (e) {
    }
    
    return prices;
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
  
  /// Türk hisselerini akıllı tanımla
  bool _isTurkishStock(String symbol, Map<String, dynamic> quote) {
    // 1. .IS uzantısı kontrolü
    if (symbol.endsWith('.IS')) return true;
    
    // 2. Country bilgisi kontrolü
    final country = quote['country']?.toString().toLowerCase();
    if (country == 'turkey' || country == 'tr' || country == 'türkiye') return true;
    
    // 3. Exchange bilgisi kontrolü
    final exchange = quote['exchange']?.toString().toLowerCase();
    if (exchange == 'ist' || exchange == 'bist' || exchange == 'istanbul') return true;
    
    // 4. Currency bilgisi kontrolü
    final currency = quote['currency']?.toString().toUpperCase();
    if (currency == 'TRY' || currency == 'TL') return true;
    
    // 5. Şirket adında Türkçe karakter kontrolü
    final longName = quote['longname']?.toString().toLowerCase() ?? '';
    final shortName = quote['shortname']?.toString().toLowerCase() ?? '';
    final fullName = '$longName $shortName';
    
    if (fullName.contains('a.ş') || 
        fullName.contains('a.s') ||
        fullName.contains('sanayi') ||
        fullName.contains('ticaret') ||
        fullName.contains('bankası') ||
        fullName.contains('enerji') ||
        fullName.contains('demir') ||
        fullName.contains('çelik') ||
        fullName.contains('çimento') ||
        fullName.contains('elektronik') ||
        fullName.contains('mağaza') ||
        fullName.contains('fabrika')) {
      return true;
    }
    
    // 6. Bilinen Türk hisse sembolleri (son çare)
    final knownTurkishStocks = [
      'GUBRF', 'ASELS', 'AKSA', 'BIMAS', 'EREGL', 'IZFAS', 'ALBRK', 
      'AKSEN', 'MPARK', 'TUPRS', 'SELEC', 'CIMSA', 'ENJSA', 'VESTL',
      'THYAO', 'KRDMD', 'SAHOL', 'TCELL', 'KOZAL', 'KOZAA', 'SASA', 
      'TOASO', 'ARCLK', 'BAGFS', 'EKGYO', 'FROTO', 'GARAN', 'HALKB', 
      'ISCTR', 'KCHOL', 'PETKM', 'PGSUS', 'SISE', 'VAKBN', 'YKBNK',
      'AKBNK', 'ARCLK', 'BAGFS', 'EKGYO', 'FROTO', 'GARAN', 'HALKB',
      'ISCTR', 'KCHOL', 'PETKM', 'PGSUS', 'SISE', 'VAKBN', 'YKBNK'
    ];
    
    return knownTurkishStocks.contains(symbol.toUpperCase());
  }
  
  /// Türk hisseleri için doğru sembolü döndür
  String _getCorrectTurkishSymbol(String symbol) {
    final symbolMap = {
      'GUBRF': 'GUBRF.IS',
      'ASELS': 'ASELS.IS', 
      'AKSA': 'AKSA.IS',
      'BIMAS': 'BIMAS.IS',
      'EREGL': 'EREGL.IS',
      'IZFAS': 'IZFAS.IS',
      'ALBRK': 'ALBRK.IS',
      'AKSEN': 'AKSEN.IS',
      'MPARK': 'MPARK.IS',
      'TUPRS': 'TUPRS.IS',
      'SELEC': 'SELEC.IS',
      'CIMSA': 'CIMSA.IS',
      'ENJSA': 'ENJSA.IS',
      'VESTL': 'VESTL.IS',
    };
    
    return symbolMap[symbol.toUpperCase()] ?? symbol;
  }
  
  
  /// Geçmiş veri çekme (mini grafik için)
  Future<List<double>> getHistoricalData(String symbol, {int days = 30}) async {
    try {
      // Yandex Finance API için symbol dönüşümü
      final yandexSymbol = _convertToYandexSymbol(symbol);
      // Yahoo Finance API endpoint'i
      final response = await http.get(
        Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$yandexSymbol?interval=1d&range=${days}d'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = _parseHistoricalData(data);
        return result;
      } else {
        throw StockApiException(
          'Historical data request failed with status: ${response.statusCode}',
          'HISTORICAL_FAILED',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StockApiException) rethrow;
      throw StockApiException('Historical data request failed: $e', 'HISTORICAL_ERROR');
    }
  }
  
  /// Yandex Finance API için symbol dönüşümü
  String _convertToYandexSymbol(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    
    // Özel durumlar için manuel mapping
    final specialCases = {
      'VESTL': 'VESTL.IS', // VESTL özel durum
    };
    
    if (specialCases.containsKey(upperSymbol)) {
      return specialCases[upperSymbol]!;
    }
    
    // Türk hisseleri için otomatik .IS uzantısı ekle
    // Eğer zaten .IS uzantısı yoksa ekle
    if (!upperSymbol.endsWith('.IS') && !upperSymbol.endsWith('.TR')) {
      return '$upperSymbol.IS';
    }
    
    return upperSymbol;
  }
  
  List<double> _parseHistoricalData(Map<String, dynamic> data) {
    try {
      final chart = data['chart'];
      if (chart == null) return [];
      
      final result = chart['result'] as List?;
      if (result == null || result.isEmpty) return [];
      
      final indicators = result[0]['indicators'];
      if (indicators == null) return [];
      
      final quote = indicators['quote'] as List?;
      if (quote == null || quote.isEmpty) return [];
      
      final closes = quote[0]['close'] as List?;
      if (closes == null) return [];
      
      return closes
          .where((price) => price != null)
          .map((price) => (price as num).toDouble())
          .toList();
    } catch (e) {
      return [];
    }
  }
}
