import '../../../shared/models/stock_models.dart';

/// Hisse repository interface'i - SOLID prensiplerine uygun
abstract class IStockRepository {
  /// Kullanıcının takip ettiği hisseleri getir
  Future<List<Stock>> getWatchedStocks(String userId);
  
  /// Kullanıcının takip listesine hisse ekle
  Future<void> addWatchedStock(String userId, Stock stock);
  
  /// Kullanıcının takip listesinden hisse çıkar
  Future<void> removeWatchedStock(String userId, String stockSymbol);
  
  /// Hisse takip ediliyor mu kontrol et
  Future<bool> isStockWatched(String userId, String stockSymbol);
  
  /// Kullanıcının tüm hisse işlemlerini getir
  Future<List<StockTransaction>> getStockTransactions(String userId);
  
  /// Hisse işlemi ekle
  Future<void> addStockTransaction(StockTransaction transaction);
  
  /// Kullanıcının hisse pozisyonlarını getir
  Future<List<StockPosition>> getStockPositions(String userId);
  
  /// Hisse pozisyonunu güncelle
  Future<void> updateStockPosition(String userId, StockPosition position);
}
