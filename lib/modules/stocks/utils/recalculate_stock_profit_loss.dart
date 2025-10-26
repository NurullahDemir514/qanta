import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/stock_models.dart';

/// Tüm satış transaction'larının profitLoss değerlerini FIFO mantığıyla yeniden hesaplar
Future<void> recalculateAllStockProfitLoss() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ User not authenticated');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    
    // Tüm transaction'ları tarihe göre sıralı olarak al
    final transactionsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('stock_transactions')
        .orderBy('transactionDate')
        .get();

    // Her hisse için ayrı ayrı işle
    final Map<String, List<StockTransaction>> stockTransactionsMap = {};
    
    for (var doc in transactionsSnapshot.docs) {
      final transaction = StockTransaction.fromFirestore(doc);
      if (!stockTransactionsMap.containsKey(transaction.stockSymbol)) {
        stockTransactionsMap[transaction.stockSymbol] = [];
      }
      stockTransactionsMap[transaction.stockSymbol]!.add(transaction);
    }

    print('📊 Processing ${stockTransactionsMap.length} stocks...');

    // Her hisse için FIFO hesapla
    for (var entry in stockTransactionsMap.entries) {
      final stockSymbol = entry.key;
      final transactions = entry.value;
      
      double runningQuantity = 0.0;
      double runningCost = 0.0;
      double runningAveragePrice = 0.0;

      print('\n🔍 Processing $stockSymbol (${transactions.length} transactions)');

      for (var transaction in transactions) {
        if (transaction.type == StockTransactionType.buy) {
          // Alış işlemi: Ortalama fiyatı güncelle
          final newQuantity = runningQuantity + transaction.quantity;
          final newCost = runningCost + transaction.totalAmount;
          runningAveragePrice = newCost / newQuantity;
          runningQuantity = newQuantity;
          runningCost = newCost;

          // Alış için profitLoss = 0
          if (transaction.profitLoss != 0.0 || transaction.profitLossPercent != 0.0) {
            await firestore
                .collection('users')
                .doc(userId)
                .collection('stock_transactions')
                .doc(transaction.id)
                .update({
              'profitLoss': 0.0,
              'profitLossPercent': 0.0,
            });
            print('  ✅ Buy: ${transaction.id} - Reset to 0');
          }
        } else {
          // Satış işlemi: FIFO kar/zarar hesapla
          final realizedProfitLoss = (transaction.price - runningAveragePrice) * transaction.quantity;
          final realizedProfitLossPercent = runningAveragePrice > 0
              ? (realizedProfitLoss / (runningAveragePrice * transaction.quantity)) * 100
              : 0.0;

          // Pozisyonu güncelle
          runningQuantity -= transaction.quantity;
          runningCost -= runningAveragePrice * transaction.quantity;

          // Firestore'da güncelle
          if (transaction.profitLoss != realizedProfitLoss || 
              transaction.profitLossPercent != realizedProfitLossPercent) {
            await firestore
                .collection('users')
                .doc(userId)
                .collection('stock_transactions')
                .doc(transaction.id)
                .update({
              'profitLoss': realizedProfitLoss,
              'profitLossPercent': realizedProfitLossPercent,
            });
            print('  ✅ Sell: ${transaction.id} - P/L: ${realizedProfitLoss.toStringAsFixed(2)} (${realizedProfitLossPercent.toStringAsFixed(2)}%)');
          }
        }
      }
    }

    print('\n✅ All stock transactions recalculated!');
  } catch (e, stackTrace) {
    // Silently handle recalculation errors
    debugPrint('Error recalculating stock profit/loss: $e');
  }
}

