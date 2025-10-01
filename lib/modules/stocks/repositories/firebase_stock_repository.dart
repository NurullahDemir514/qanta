import 'package:cloud_firestore/cloud_firestore.dart';
import '../contracts/stock_repository_contract.dart';
import '../exceptions/stock_exceptions.dart';
import '../../../shared/models/stock_models.dart';

/// Firebase hisse repository implementasyonu
class FirebaseStockRepository implements IStockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<List<Stock>> getWatchedStocks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('watched_stocks')
          .get();
      
      final List<Stock> stocks = [];
      for (var doc in snapshot.docs) {
        try {
          final stock = Stock.fromFirestore(doc);
          stocks.add(stock);
        } catch (e) {
          // Hatalı veriyi atla, devam et
        }
      }
      
      return stocks;
    } catch (e) {
      throw StockRepositoryException('Failed to get watched stocks: $e', 'GET_WATCHED_STOCKS');
    }
  }
  
  @override
  Future<void> addWatchedStock(String userId, Stock stock) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('watched_stocks')
          .doc(stock.symbol)
          .set(stock.toFirestore());
    } catch (e) {
      throw StockRepositoryException('Failed to add watched stock: $e', 'ADD_WATCHED_STOCK');
    }
  }
  
  @override
  Future<void> removeWatchedStock(String userId, String stockSymbol) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('watched_stocks')
          .doc(stockSymbol)
          .delete();
    } catch (e) {
      throw StockRepositoryException('Failed to remove watched stock: $e', 'REMOVE_WATCHED_STOCK');
    }
  }
  
  @override
  Future<bool> isStockWatched(String userId, String stockSymbol) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('watched_stocks')
          .doc(stockSymbol)
          .get();
      
      return doc.exists;
    } catch (e) {
      throw StockRepositoryException('Failed to check if stock is watched: $e', 'IS_STOCK_WATCHED');
    }
  }
  
  @override
  Future<List<StockTransaction>> getStockTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_transactions')
          .orderBy('transactionDate', descending: true)
          .get();
      
      final List<StockTransaction> transactions = [];
      for (var doc in snapshot.docs) {
        try {
          final transaction = StockTransaction.fromFirestore(doc);
          transactions.add(transaction);
        } catch (e) {
          // Hatalı veriyi atla, devam et
        }
      }
      
      return transactions;
    } catch (e) {
      throw StockRepositoryException('Failed to get stock transactions: $e', 'GET_STOCK_TRANSACTIONS');
    }
  }
  
  @override
  Future<void> addStockTransaction(StockTransaction transaction) async {
    try {
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
    } catch (e) {
      throw StockRepositoryException('Failed to add stock transaction: $e', 'ADD_STOCK_TRANSACTION');
    }
  }
  
  @override
  Future<List<StockPosition>> getStockPositions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_positions')
          .get();
      
      final List<StockPosition> positions = [];
      for (var doc in snapshot.docs) {
        try {
          final position = StockPosition.fromJson(doc.data());
          positions.add(position);
        } catch (e) {
          // Hatalı veriyi atla, devam et
        }
      }
      
      return positions;
    } catch (e) {
      throw StockRepositoryException('Failed to get stock positions: $e', 'GET_STOCK_POSITIONS');
    }
  }
  
  @override
  Future<void> updateStockPosition(String userId, StockPosition position) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_positions')
          .doc(position.stockSymbol)
          .set(position.toJson());
    } catch (e) {
      throw StockRepositoryException('Failed to update stock position: $e', 'UPDATE_STOCK_POSITION');
    }
  }
}
