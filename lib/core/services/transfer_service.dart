import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/transactions/models/transfer_model.dart';
import '../../shared/models/transaction_model.dart';
import 'transaction_service.dart';

class TransferService {
  static final _supabase = Supabase.instance.client;

  /// Transfer işlemi oluştur
  static Future<TransferModel> createTransfer({
    required double amount,
    required String description,
    String? notes,
    // Kaynak kart bilgileri (sadece biri dolu olmalı)
    String? sourceCreditCardId,
    String? sourceDebitCardId,
    String? sourceCashAccountId,
    // Hedef kart bilgileri (sadece biri dolu olmalı)
    String? targetCreditCardId,
    String? targetDebitCardId,
    String? targetCashAccountId,
    DateTime? transactionDate,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }

      // Validasyon kontrolleri
      _validateTransferInputs(
        sourceCreditCardId: sourceCreditCardId,
        sourceDebitCardId: sourceDebitCardId,
        sourceCashAccountId: sourceCashAccountId,
        targetCreditCardId: targetCreditCardId,
        targetDebitCardId: targetDebitCardId,
        targetCashAccountId: targetCashAccountId,
        amount: amount,
      );

      // TransactionService kullanarak transfer işlemi oluştur
      final transaction = await TransactionService.createTransaction(
        type: TransactionType.transfer,
        amount: amount,
        description: description,
        category: 'transfer',
        creditCardId: sourceCreditCardId,
        debitCardId: sourceDebitCardId,
        cashAccountId: sourceCashAccountId,
        targetCreditCardId: targetCreditCardId,
        targetDebitCardId: targetDebitCardId,
        targetCashAccountId: targetCashAccountId,
        notes: notes,
        transactionDate: transactionDate,
      );

      // TransactionModel'i TransferModel'e dönüştür
      return TransferModel.fromTransactionModel(transaction);
    } catch (e) {
      throw Exception('Transfer işlemi oluşturulurken hata oluştu: $e');
    }
  }

  /// Kullanıcının transfer işlemlerini getir
  static Future<List<TransferModel>> getUserTransfers({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // TransactionService kullanarak transfer işlemlerini getir
      final transactions = await TransactionService.getUserTransactions(
        type: TransactionType.transfer,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );

      // TransactionModel'leri TransferModel'e dönüştür
      return transactions
          .map((transaction) => TransferModel.fromTransactionModel(transaction))
          .toList();
    } catch (e) {
      throw Exception('Transfer işlemleri yüklenirken hata oluştu: $e');
    }
  }

  /// Belirli bir kartın transfer işlemlerini getir (kaynak veya hedef olarak)
  static Future<List<TransferModel>> getCardTransfers({
    required String cardId,
    required CardType cardType,
    int? limit,
    int? offset,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }

      // Kart tipine göre sütun adlarını belirle
      String sourceColumn, targetColumn;
      switch (cardType) {
        case CardType.credit:
          sourceColumn = 'credit_card_id';
          targetColumn = 'target_credit_card_id';
          break;
        case CardType.debit:
          sourceColumn = 'debit_card_id';
          targetColumn = 'target_debit_card_id';
          break;
        case CardType.cash:
          sourceColumn = 'cash_account_id';
          targetColumn = 'target_cash_account_id';
          break;
      }

      // Kartın kaynak veya hedef olduğu transfer işlemlerini getir
      dynamic query = _supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUser.id)
          .eq('type', 'transfer')
          .or('$sourceColumn.eq.$cardId,$targetColumn.eq.$cardId')
          .order('transaction_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      // Response'u TransactionModel'e dönüştür, sonra TransferModel'e
      final transactions = (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      return transactions
          .map((transaction) => TransferModel.fromTransactionModel(transaction))
          .toList();
    } catch (e) {
      throw Exception('Kart transfer işlemleri yüklenirken hata oluştu: $e');
    }
  }

  /// Transfer işlemini sil
  static Future<void> deleteTransfer(String transferId) async {
    try {
      // TransactionService kullanarak işlemi sil
      await TransactionService.deleteTransaction(transferId);
    } catch (e) {
      throw Exception('Transfer işlemi silinirken hata oluştu: $e');
    }
  }

  /// Transfer işlemini güncelle
  static Future<TransferModel> updateTransfer({
    required String transferId,
    double? amount,
    String? description,
    String? notes,
    DateTime? transactionDate,
  }) async {
    try {
      // TransactionService kullanarak işlemi güncelle
      final updatedTransaction = await TransactionService.updateTransaction(
        transactionId: transferId,
        amount: amount,
        description: description,
        notes: notes,
        transactionDate: transactionDate,
      );

      return TransferModel.fromTransactionModel(updatedTransaction);
    } catch (e) {
      throw Exception('Transfer işlemi güncellenirken hata oluştu: $e');
    }
  }

  /// Transfer geçmişi özeti
  static Future<Map<String, dynamic>> getTransferSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transfers = await getUserTransfers(
        startDate: startDate,
        endDate: endDate,
      );

      double totalAmount = 0;
      int totalCount = transfers.length;
      Map<TransferType, int> transferTypeCount = {};
      Map<TransferType, double> transferTypeAmount = {};

      for (final transfer in transfers) {
        totalAmount += transfer.amount;
        
        // Transfer tipine göre sayım
        transferTypeCount[transfer.transferType] = 
            (transferTypeCount[transfer.transferType] ?? 0) + 1;
        
        // Transfer tipine göre tutar
        transferTypeAmount[transfer.transferType] = 
            (transferTypeAmount[transfer.transferType] ?? 0) + transfer.amount;
      }

      return {
        'totalCount': totalCount,
        'totalAmount': totalAmount,
        'averageAmount': totalCount > 0 ? totalAmount / totalCount : 0,
        'transferTypeCount': transferTypeCount,
        'transferTypeAmount': transferTypeAmount,
        'transfers': transfers,
      };
    } catch (e) {
      throw Exception('Transfer özeti yüklenirken hata oluştu: $e');
    }
  }

  /// Transfer validasyon kontrolleri
  static void _validateTransferInputs({
    String? sourceCreditCardId,
    String? sourceDebitCardId,
    String? sourceCashAccountId,
    String? targetCreditCardId,
    String? targetDebitCardId,
    String? targetCashAccountId,
    required double amount,
  }) {
    // Tutar kontrolü
    if (amount <= 0) {
      throw ArgumentError('Transfer tutarı 0\'dan büyük olmalıdır');
    }

    // Kaynak kart kontrolü
    final sourceCards = [
      sourceCreditCardId,
      sourceDebitCardId,
      sourceCashAccountId,
    ].where((id) => id != null).toList();

    if (sourceCards.isEmpty) {
      throw ArgumentError('Kaynak kart seçilmelidir');
    }

    if (sourceCards.length > 1) {
      throw ArgumentError('Sadece bir kaynak kart seçilmelidir');
    }

    // Hedef kart kontrolü
    final targetCards = [
      targetCreditCardId,
      targetDebitCardId,
      targetCashAccountId,
    ].where((id) => id != null).toList();

    if (targetCards.isEmpty) {
      throw ArgumentError('Hedef kart seçilmelidir');
    }

    if (targetCards.length > 1) {
      throw ArgumentError('Sadece bir hedef kart seçilmelidir');
    }

    // Kaynak ve hedef aynı olamaz
    if (sourceCards.first == targetCards.first) {
      throw ArgumentError('Kaynak ve hedef kart aynı olamaz');
    }
  }

  /// Kart bakiyesi kontrolü (transfer öncesi)
  static Future<bool> checkTransferAvailability({
    required String sourceCardId,
    required CardType sourceCardType,
    required double amount,
  }) async {
    try {
      switch (sourceCardType) {
        case CardType.credit:
          // Kredi kartı için kullanılabilir limit kontrolü
          final response = await _supabase
              .from('credit_cards')
              .select('available_limit')
              .eq('id', sourceCardId)
              .single();
          
          final availableLimit = response['available_limit'] as double;
          return availableLimit >= amount;

        case CardType.debit:
          // Banka kartı için bakiye kontrolü
          final response = await _supabase
              .from('debit_cards')
              .select('current_balance')
              .eq('id', sourceCardId)
              .single();
          
          final balance = response['current_balance'] as double;
          return balance >= amount;

        case CardType.cash:
          // Nakit hesap için bakiye kontrolü
          final response = await _supabase
              .from('cash_account')
              .select('current_balance')
              .eq('id', sourceCardId)
              .single();
          
          final balance = response['current_balance'] as double;
          return balance >= amount;
      }
    } catch (e) {
      throw Exception('Bakiye kontrolü yapılırken hata oluştu: $e');
    }
  }
} 