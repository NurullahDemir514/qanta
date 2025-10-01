import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../contracts/stock_transaction_contract.dart';
import '../exceptions/stock_exceptions.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/services/unified_account_service.dart';

/// Hisse işlem servisi implementasyonu
class StockTransactionService implements IStockTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<void> executeBuyTransaction(StockTransaction transaction) async {
    try {
      // 1. Bakiye kontrolü
      await _checkSufficientBalance(transaction.userId, transaction.totalAmount);
      
      // 2. İşlemi kaydet
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
      
      // 3. Hisse pozisyonunu güncelle
      await _updateStockPositionAfterBuy(transaction);
      
      // 4. Kullanıcı bakiyesini güncelle (mevcut transaction sistemine entegre)
      if (transaction.accountId != null) {
        await _updateUserBalance(transaction.accountId!, -transaction.totalAmount);
      }
      
      // 5. Recent transactions'a ekle (mevcut sistemle entegre)
      await _addToRecentTransactions(transaction);
      
    } catch (e) {
      if (e is StockTransactionException) rethrow;
      throw StockTransactionException('Failed to execute buy transaction: $e', 'EXECUTE_BUY');
    }
  }
  
  @override
  Future<void> executeSellTransaction(StockTransaction transaction) async {
    try {
      // 1. Yeterli hisse miktarı kontrolü
      final currentPosition = await getStockPosition(transaction.userId, transaction.stockSymbol);
      if (currentPosition == null || currentPosition.totalQuantity < transaction.quantity) {
        throw InsufficientStockQuantityException(
          transaction.stockSymbol,
          transaction.quantity,
          currentPosition?.totalQuantity ?? 0.0,
        );
      }
      
      // 2. İşlemi kaydet
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
      
      // 3. Hisse pozisyonunu güncelle
      await _updateStockPositionAfterSell(transaction);
      
      // 4. Kullanıcı bakiyesini güncelle
      if (transaction.accountId != null) {
        await _updateUserBalance(transaction.accountId!, transaction.totalAmount);
      }
      
      // 5. Recent transactions'a ekle
      await _addToRecentTransactions(transaction);
      
    } catch (e) {
      if (e is StockTransactionException) rethrow;
      throw StockTransactionException('Failed to execute sell transaction: $e', 'EXECUTE_SELL');
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
        }
      }
      
      return transactions;
    } catch (e) {
      throw StockTransactionException('Failed to get stock transactions: $e', 'GET_TRANSACTIONS');
    }
  }
  
  @override
  Future<StockPosition?> getStockPosition(String userId, String stockSymbol) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_positions')
          .doc(stockSymbol)
          .get();
      
      if (!doc.exists) return null;
      
      return StockPosition.fromJson(doc.data()!);
    } catch (e) {
      throw StockTransactionException('Failed to get stock position: $e', 'GET_POSITION');
    }
  }
  
  @override
  Future<List<StockPosition>> getAllStockPositions(String userId) async {
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
        }
      }
      
      return positions;
    } catch (e) {
      throw StockTransactionException('Failed to get all stock positions: $e', 'GET_ALL_POSITIONS');
    }
  }
  
  @override
  Future<StockPosition> calculateStockPosition(String userId, String stockSymbol) async {
    try {
      // Tüm işlemleri getir
      final transactions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_transactions')
          .where('stockSymbol', isEqualTo: stockSymbol)
          .orderBy('transactionDate')
          .get();
      
      double totalQuantity = 0.0;
      double totalCost = 0.0;
      double weightedAveragePrice = 0.0;
      String stockName = '';
      
      for (var doc in transactions.docs) {
        final transaction = StockTransaction.fromFirestore(doc);
        stockName = transaction.stockName;
        
        if (transaction.type == StockTransactionType.buy) {
          // Alış işlemi: Ağırlıklı ortalama fiyat hesapla
          final newTotalQuantity = totalQuantity + transaction.quantity;
          final newTotalCost = totalCost + transaction.totalAmount;
          
          // Ağırlıklı ortalama fiyat = (eski_toplam_maliyet + yeni_işlem_maliyeti) / (eski_adet + yeni_adet)
          weightedAveragePrice = newTotalCost / newTotalQuantity;
          
          totalQuantity = newTotalQuantity;
          totalCost = newTotalCost;
        } else {
          // Satış işlemi: Sadece adet azalt, ortalama fiyat değişmez
          totalQuantity -= transaction.quantity;
          // Satış işleminde maliyet azaltma - ağırlıklı ortalama fiyat ile
          totalCost -= weightedAveragePrice * transaction.quantity;
        }
      }
      
      if (totalQuantity <= 0) {
        // Pozisyon yok, sil
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('stock_positions')
            .doc(stockSymbol)
            .delete();
        
        return StockPosition(
          stockSymbol: stockSymbol,
          stockName: stockName,
          totalQuantity: 0.0,
          averagePrice: 0.0,
          totalCost: 0.0,
          currentValue: 0.0,
          profitLoss: 0.0,
          profitLossPercent: 0.0,
          lastUpdated: DateTime.now(),
          currency: 'TRY',
        );
      }
      
      // Ağırlıklı ortalama alış fiyatı (maliyet)
      final averagePrice = totalQuantity > 0 ? weightedAveragePrice : 0.0;
      // Gerçek zamanlı fiyat alınması gerekiyor, şimdilik average price kullanıyoruz
      final currentValue = totalQuantity * averagePrice;
      final profitLoss = currentValue - totalCost;
      final profitLossPercent = totalCost != 0 ? (profitLoss / totalCost) * 100 : 0.0;
      
      final position = StockPosition(
        stockSymbol: stockSymbol,
        stockName: stockName,
        totalQuantity: totalQuantity,
        averagePrice: averagePrice,
        totalCost: totalCost,
        currentValue: currentValue,
        profitLoss: profitLoss,
        profitLossPercent: profitLossPercent,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      );
      
      // Pozisyonu kaydet
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_positions')
          .doc(stockSymbol)
          .set(position.toJson());
      
      return position;
    } catch (e) {
      throw StockTransactionException('Failed to calculate stock position: $e', 'CALCULATE_POSITION');
    }
  }
  
  @override
  Future<void> deleteStockTransaction(String transactionId) async {
    try {
      // User ID'yi al
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw StockTransactionException('User not authenticated', 'USER_NOT_AUTHENTICATED');
      }
      
      // Transaction'ı bul ve sil - doğrudan path kullan
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stock_transactions')
          .doc(transactionId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        throw StockTransactionException('Transaction not found: $transactionId', 'TRANSACTION_NOT_FOUND');
      }
      
      final transaction = StockTransaction.fromFirestore(doc);
      
      // 1. Stock transaction'ı sil
      await docRef.delete();
      
      // 2. Recent transaction'dan da sil
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
      
      // 3. Hesap bakiyesini geri al
      if (transaction.accountId != null && transaction.accountId!.isNotEmpty) {
        final balanceChange = transaction.type == StockTransactionType.buy 
            ? transaction.totalAmount  // Alış işlemi silinirse para geri ver
            : -transaction.totalAmount; // Satış işlemi silinirse para geri al
        
        
        await _updateUserBalance(transaction.accountId!, balanceChange);
      } else {
      }
      
      // 4. Pozisyonu yeniden hesapla
      await calculateStockPosition(transaction.userId, transaction.stockSymbol);
      
      // 5. Tüm işlemleri geri çek (mikro refresh)
      await _refreshAllTransactions(transaction.userId);
      
    } catch (e) {
      if (e is StockTransactionException) rethrow;
      throw StockTransactionException('Failed to delete stock transaction: $e', 'DELETE_TRANSACTION');
    }
  }
  
  @override
  Future<void> updateStockTransaction(StockTransaction transaction) async {
    try {
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_transactions')
          .doc(transaction.id)
          .update(transaction.toFirestore());
      
      // Pozisyonu yeniden hesapla
      await calculateStockPosition(transaction.userId, transaction.stockSymbol);
      
    } catch (e) {
      throw StockTransactionException('Failed to update stock transaction: $e', 'UPDATE_TRANSACTION');
    }
  }
  
  // Private helper methods
  Future<void> _checkSufficientBalance(String userId, double requiredAmount) async {
    // Mevcut bakiye sistemini kullan
    // Bu kısım mevcut UnifiedProviderV2 ile entegre edilecek
    // Şimdilik basit bir kontrol
    if (requiredAmount <= 0) {
      throw StockValidationException('Invalid amount: $requiredAmount');
    }
  }
  
  Future<void> _updateStockPositionAfterBuy(StockTransaction transaction) async {
    final currentPosition = await getStockPosition(transaction.userId, transaction.stockSymbol);
    
    if (currentPosition == null) {
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
        currency: 'TRY',
      );
      
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_positions')
          .doc(transaction.stockSymbol)
          .set(newPosition.toJson());
    } else {
      // Mevcut pozisyonu güncelle
      final newTotalQuantity = currentPosition.totalQuantity + transaction.quantity;
      final newTotalCost = currentPosition.totalCost + transaction.totalAmount;
      final newAveragePrice = newTotalCost / newTotalQuantity;
      
      final updatedPosition = StockPosition(
        stockSymbol: transaction.stockSymbol,
        stockName: transaction.stockName,
        totalQuantity: newTotalQuantity,
        averagePrice: newAveragePrice,
        totalCost: newTotalCost,
        currentValue: newTotalCost, // Gerçek zamanlı fiyat güncellenmeli
        profitLoss: 0.0,
        profitLossPercent: 0.0,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      );
      
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_positions')
          .doc(transaction.stockSymbol)
          .set(updatedPosition.toJson());
    }
  }
  
  Future<void> _updateStockPositionAfterSell(StockTransaction transaction) async {
    final currentPosition = await getStockPosition(transaction.userId, transaction.stockSymbol);
    
    if (currentPosition == null) {
      throw StockTransactionException('No position found for sell transaction', 'NO_POSITION');
    }
    
    final newTotalQuantity = currentPosition.totalQuantity - transaction.quantity;
    
    if (newTotalQuantity <= 0) {
      // Pozisyonu sil
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_positions')
          .doc(transaction.stockSymbol)
          .delete();
    } else {
      // Pozisyonu güncelle
      final newTotalCost = currentPosition.totalCost - (currentPosition.averagePrice * transaction.quantity);
      
      final updatedPosition = StockPosition(
        stockSymbol: transaction.stockSymbol,
        stockName: transaction.stockName,
        totalQuantity: newTotalQuantity,
        averagePrice: currentPosition.averagePrice,
        totalCost: newTotalCost,
        currentValue: newTotalCost, // Gerçek zamanlı fiyat güncellenmeli
        profitLoss: 0.0,
        profitLossPercent: 0.0,
        lastUpdated: DateTime.now(),
        currency: 'TRY',
      );
      
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('stock_positions')
          .doc(transaction.stockSymbol)
          .set(updatedPosition.toJson());
    }
  }
  
  Future<void> _updateUserBalance(String accountId, double amount) async {
    try {
      
      // Hesap detaylarını al
      final account = await UnifiedAccountService.getAccountById(accountId);
      if (account != null) {
      }
      
      // UnifiedAccountService kullanarak hesap bakiyesini güncelle
      await UnifiedAccountService.addToBalance(
        accountId: accountId,
        amount: amount,
      );
      
      
      // Güncellenmiş hesap detaylarını kontrol et
      final updatedAccount = await UnifiedAccountService.getAccountById(accountId);
      if (updatedAccount != null) {
      }
      
    } catch (e) {
      rethrow;
    }
  }

  /// Tüm işlemleri geri çek (mikro refresh)
  Future<void> _refreshAllTransactions(String userId) async {
    try {
      // UnifiedProviderV2'yi tetikle
      // Bu method provider'ları yeniden yükleyecek
      
      // Provider'ları yeniden yükle
      // Bu işlem UI'yi otomatik olarak güncelleyecek
      
    } catch (e) {
      // Hata olsa bile devam et, kritik değil
    }
  }
  
  Future<void> _addToRecentTransactions(StockTransaction transaction) async {
    try {
      // Hesap adını al
      String? sourceAccountName;
      if (transaction.accountId != null) {
        try {
          final account = await UnifiedAccountService.getAccountById(transaction.accountId!);
          sourceAccountName = account?.name;
        } catch (e) {
          sourceAccountName = 'Hesap';
        }
      } else {
        sourceAccountName = 'Hesap';
      }

      // Hisse işlemini mevcut transaction sistemine ekle
      final transactionModel = TransactionModelV2(
        id: transaction.id,
        userId: transaction.userId,
        type: TransactionType.stock,
        amount: transaction.type == StockTransactionType.buy 
            ? -transaction.totalAmount  // Alış için negatif (para çıkışı)
            : transaction.totalAmount,  // Satış için pozitif (para girişi)
        description: '${transaction.type.shortName} ${transaction.stockSymbol}',
        transactionDate: transaction.transactionDate,
        sourceAccountId: transaction.accountId ?? 'default_account', // Seçilen hesap ID'si
        notes: transaction.notes,
        isRecurring: false,
        stockSymbol: transaction.stockSymbol,
        stockName: _cleanStockName(transaction.stockName),
        stockQuantity: transaction.quantity,
        stockPrice: transaction.price,
        createdAt: transaction.transactionDate,
        updatedAt: transaction.transactionDate,
      );
      
      // Firestore'a kaydet - sourceAccountName ile birlikte
      final transactionData = {
        ...transactionModel.toJson(),
        'source_account_name': sourceAccountName,
      };
      
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id)
          .set(transactionData);
          
    } catch (e) {
    }
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
}
