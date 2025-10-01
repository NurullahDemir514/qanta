import '../../../shared/models/stock_models.dart';

/// Hisse API servisi interface'i - SOLID prensiplerine uygun
abstract class IStockApiService {
  /// Hisse arama
  Future<List<Stock>> searchStocks(String query);
  
  /// Hisse detayları getir
  Future<Stock?> getStockDetails(String symbol);
  
  /// Gerçek zamanlı fiyatlar getir
  Future<List<Stock>> getRealTimePrices(List<String> symbols);
  
  /// Tarihsel fiyat verileri getir
  Future<List<StockPrice>> getHistoricalPrices(
    String symbol, 
    String interval, // 1m, 5m, 15m, 1h, 1d
    String range,    // 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max
  );
  
  /// Popüler hisseleri getir
  Future<List<Stock>> getPopularStocks();
  
  /// BIST hisselerini getir
  Future<List<Stock>> getBistStocks();
  
  /// ABD hisselerini getir
  Future<List<Stock>> getUsStocks();
  
  /// Geçmiş veri çekme (mini grafik için)
  Future<List<double>> getHistoricalData(String symbol, {int days = 30});
}
