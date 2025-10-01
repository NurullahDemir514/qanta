import '../../../shared/models/stock_models.dart';

/// Hisse işlem servisi interface'i - SOLID prensiplerine uygun
abstract class IStockTransactionService {
  /// Hisse alış işlemi gerçekleştir
  Future<void> executeBuyTransaction(StockTransaction transaction);
  
  /// Hisse satış işlemi gerçekleştir
  Future<void> executeSellTransaction(StockTransaction transaction);
  
  /// Kullanıcının hisse işlemlerini getir
  Future<List<StockTransaction>> getStockTransactions(String userId);
  
  /// Belirli bir hissenin pozisyonunu getir
  Future<StockPosition?> getStockPosition(String userId, String stockSymbol);
  
  /// Kullanıcının tüm hisse pozisyonlarını getir
  Future<List<StockPosition>> getAllStockPositions(String userId);
  
  /// Hisse pozisyonunu hesapla ve güncelle
  Future<StockPosition> calculateStockPosition(String userId, String stockSymbol);
  
  /// Hisse işlemi sil
  Future<void> deleteStockTransaction(String transactionId);
  
  /// Hisse işlemi güncelle
  Future<void> updateStockTransaction(StockTransaction transaction);
}
