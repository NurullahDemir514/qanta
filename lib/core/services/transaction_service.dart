import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/transaction_model.dart';
import '../events/transaction_events.dart';

// Özel exception sınıfları
class InsufficientFundsException implements Exception {
  final String message;
  final String cardType;
  final double availableAmount;
  final double requestedAmount;
  
  InsufficientFundsException({
    required this.message,
    required this.cardType,
    required this.availableAmount,
    required this.requestedAmount,
  });
  
  @override
  String toString() => message;
}

class TransactionService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'transactions';

  // Kullanıcının işlemlerini getir
  static Future<List<TransactionModel>> getUserTransactions({
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      dynamic query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', currentUser.id);

      // Filtreler
      if (type != null) {
        query = query.eq('type', type.name.toLowerCase());
      }
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      // Sıralama
      query = query.order('transaction_date', ascending: false);
      
      // Sayfalama
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      
      return (response as List).map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('İşlemler yüklenirken hata oluştu: $e');
    }
  }

  // Belirli bir kartın işlemlerini getir
  static Future<List<TransactionModel>> getCardTransactions({
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
      
      // Kart tipine göre sütun adını belirle
      String cardColumn;
      switch (cardType) {
        case CardType.credit:
          cardColumn = 'credit_card_id';
          break;
        case CardType.debit:
          cardColumn = 'debit_card_id';
          break;
        case CardType.cash:
          cardColumn = 'cash_account_id';
          break;
      }

      dynamic query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', currentUser.id)
          .eq(cardColumn, cardId)
          .order('transaction_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      
      return (response as List).map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Kart işlemleri yüklenirken hata oluştu: $e');
    }
  }

  // Yeni işlem oluştur
  static Future<TransactionModel> createTransaction({
    required TransactionType type,
    required double amount,
    required String description,
    String? category,
    String? creditCardId,
    String? debitCardId,
    String? cashAccountId,
    String? targetCreditCardId,
    String? targetDebitCardId,
    String? targetCashAccountId,
    int installmentCount = 1,
    int currentInstallment = 1,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? transactionDate,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      final userId = currentUser.id;
      final transactionDateTime = transactionDate ?? DateTime.now();
      final typeValue = type.name.toLowerCase();

      print('🔍 Creating transaction with type: $typeValue (from ${type.name})');
      print('🔍 User ID: $userId');

      // RPC fonksiyonunu kullanarak işlem oluştur ve bakiye güncelle
      try {
        // RPC fonksiyonunu kullanarak işlem oluştur ve bakiye güncelle
        final response = await _supabase.rpc('create_transaction_with_balance_update', params: {
          'p_user_id': userId,
          'p_type': typeValue,
          'p_amount': amount,
          'p_description': description,
          'p_category': category,
          'p_credit_card_id': creditCardId,
          'p_debit_card_id': debitCardId,
          'p_cash_account_id': cashAccountId,
          'p_target_credit_card_id': targetCreditCardId,
          'p_target_debit_card_id': targetDebitCardId,
          'p_target_cash_account_id': targetCashAccountId,
          'p_installment_count': installmentCount,
          'p_current_installment': currentInstallment,
          'p_merchant_name': merchantName,
          'p_location': location,
          'p_notes': notes,
          'p_transaction_date': transactionDateTime.toUtc().toIso8601String(),
        });

        print('🔍 RPC response: $response');

        if (response == null) {
          throw Exception('İşlem oluşturulamadı - RPC response null');
        }

        // RPC response'u kontrol et ve transaction'ı al
        TransactionModel transaction;
        
        if (response is String) {
          // RPC sadece transaction ID döndürdü, transaction'ı fetch et
          print('🔍 RPC returned transaction ID: $response');
          final fetchedTransaction = await getTransactionById(response);
          if (fetchedTransaction == null) {
            throw Exception('Oluşturulan işlem bulunamadı: $response');
          }
          transaction = fetchedTransaction;
          print('✅ Transaction fetched successfully: ${transaction.description}');
        } else if (response is Map<String, dynamic>) {
          // RPC tam transaction data döndürdü
          print('🔍 RPC returned full transaction data');
          transaction = TransactionModel.fromJson(response);
        } else {
          throw Exception('Beklenmeyen RPC response tipi: ${response.runtimeType}');
        }
        
        print('✅ Transaction created with balance update successfully');
        print('🔍 Final transaction details:');
        print('   - ID: ${transaction.id}');
        print('   - Description: ${transaction.description}');
        print('   - Amount: ${transaction.amount}');
        print('   - Type: ${transaction.type}');
        print('   - Credit Card ID: ${transaction.creditCardId}');
        print('   - Debit Card ID: ${transaction.debitCardId}');
        print('   - Cash Account ID: ${transaction.cashAccountId}');
        
        // 🔔 Event emit et - Transaction eklendi
        emitTransactionAdded(transaction);
        
        return transaction;
      
      } on PostgrestException catch (e) {
        print('❌ RPC PostgrestException: $e');
        
        // PostgrestException'ı özel olarak handle et
        if (e.code == 'P0001') {
          // 🔥 Tüm P0001 hatalarını InsufficientFundsException olarak fırlat
          // Hangi kart türü olduğunu belirlemek için parametreleri kontrol et
          String cardType = 'unknown';
          
          if (creditCardId != null) {
            cardType = 'credit';
          } else if (debitCardId != null) {
            cardType = 'debit';
          } else if (cashAccountId != null) {
            cardType = 'cash';
          }
          
          throw InsufficientFundsException(
            message: e.message, // Direkt RPC'den gelen mesajı kullan
            cardType: cardType,
            availableAmount: 0,
            requestedAmount: amount,
          );
        } else {
          // Diğer PostgrestException'lar için genel mesaj
          throw Exception('İşlem gerçekleştirilemedi: ${e.message}');
        }
      } catch (e) {
        print('❌ RPC error details: $e');
        
        // Diğer hatalar için de InsufficientFundsException fırlat
        String cardType = 'unknown';
        
        if (creditCardId != null) {
          cardType = 'credit';
        } else if (debitCardId != null) {
          cardType = 'debit';
        } else if (cashAccountId != null) {
          cardType = 'cash';
        }
        
        // Hata mesajında "yetersiz" veya "limit" geçiyorsa InsufficientFundsException fırlat
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('yetersiz') || 
            errorString.contains('limit') || 
            errorString.contains('bakiye') ||
            errorString.contains('insufficient')) {
          throw InsufficientFundsException(
            message: e.toString(),
            cardType: cardType,
            availableAmount: 0,
            requestedAmount: amount,
          );
        }
        
        // RPC başarısız olursa fallback olarak eski yöntemi kullan
        print('🔄 Falling back to direct insert...');
        
        // 🔥 FALLBACK İÇİN BAKİYE KONTROLÜ EKLE
        // Banka kartı bakiye kontrolü
        if (debitCardId != null && type == TransactionType.expense) {
          try {
            final debitCardResponse = await _supabase
                .from('debit_cards')
                .select('current_balance')
                .eq('id', debitCardId)
                .single();
            
            final currentBalance = (debitCardResponse['current_balance'] as num).toDouble();
            if (currentBalance < amount) {
              throw InsufficientFundsException(
                message: 'Banka kartı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınıza para yatırın.',
                cardType: 'debit',
                availableAmount: currentBalance,
                requestedAmount: amount,
              );
            }
          } catch (e) {
            if (e is InsufficientFundsException) rethrow;
            print('⚠️ Debit card balance check failed: $e');
            // Bakiye kontrolü başarısız olursa devam et
          }
        }
        
        // Nakit hesabı bakiye kontrolü
        if (cashAccountId != null && type == TransactionType.expense) {
          try {
            final cashAccountResponse = await _supabase
                .from('cash_account')
                .select('current_balance')
                .eq('id', cashAccountId)
                .single();
            
            final currentBalance = (cashAccountResponse['current_balance'] as num).toDouble();
            if (currentBalance < amount) {
              throw InsufficientFundsException(
                message: 'Nakit hesabı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin.',
                cardType: 'cash',
                availableAmount: currentBalance,
                requestedAmount: amount,
              );
            }
          } catch (e) {
            if (e is InsufficientFundsException) rethrow;
            print('⚠️ Cash account balance check failed: $e');
            // Bakiye kontrolü başarısız olursa devam et
          }
        }
        
        // Kredi kartı limit kontrolü
        if (creditCardId != null && type == TransactionType.expense) {
          try {
            print('🔍 Checking credit card limit for card: $creditCardId');
            final creditCardResponse = await _supabase
                .from('credit_cards')
                .select('credit_limit, current_balance')
                .eq('id', creditCardId)
                .single();
            
            final creditLimit = (creditCardResponse['credit_limit'] as num).toDouble();
            final currentBalance = (creditCardResponse['current_balance'] as num).toDouble();
            final availableLimit = creditLimit - currentBalance;
            
            print('🔍 Credit limit: $creditLimit, Current balance: $currentBalance, Available: $availableLimit, Requested: $amount');
            
            if (availableLimit < amount) {
              print('🔍 Throwing InsufficientFundsException for credit card');
              throw InsufficientFundsException(
                message: 'Kredi kartı limitiniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınızın borcunu ödeyin.',
                cardType: 'credit',
                availableAmount: availableLimit,
                requestedAmount: amount,
              );
            }
          } catch (e) {
            print('🔍 Credit card limit check exception: $e (type: ${e.runtimeType})');
            if (e is InsufficientFundsException) rethrow;
            print('⚠️ Credit card limit check failed: $e');
            // Limit kontrolü başarısız olursa devam et
          }
        }
        
        // Transfer işlemleri için kaynak hesap bakiye kontrolü
        if (type == TransactionType.transfer) {
          // Kaynak banka kartı kontrolü
          if (debitCardId != null) {
            try {
              final debitCardResponse = await _supabase
                  .from('debit_cards')
                  .select('current_balance')
                  .eq('id', debitCardId)
                  .single();
              
              final currentBalance = (debitCardResponse['current_balance'] as num).toDouble();
              if (currentBalance < amount) {
                throw InsufficientFundsException(
                  message: 'Transfer için bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin.',
                  cardType: 'debit',
                  availableAmount: currentBalance,
                  requestedAmount: amount,
                );
              }
            } catch (e) {
              if (e is InsufficientFundsException) rethrow;
              print('⚠️ Transfer debit card balance check failed: $e');
              // Bakiye kontrolü başarısız olursa devam et
            }
          }
          
          // Kaynak nakit hesabı kontrolü
          if (cashAccountId != null) {
            try {
              final cashAccountResponse = await _supabase
                  .from('cash_account')
                  .select('current_balance')
                  .eq('id', cashAccountId)
                  .single();
              
              final currentBalance = (cashAccountResponse['current_balance'] as num).toDouble();
              if (currentBalance < amount) {
                throw InsufficientFundsException(
                  message: 'Transfer için nakit bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin.',
                  cardType: 'cash',
                  availableAmount: currentBalance,
                  requestedAmount: amount,
                );
              }
            } catch (e) {
              if (e is InsufficientFundsException) rethrow;
              print('⚠️ Transfer cash account balance check failed: $e');
              // Bakiye kontrolü başarısız olursa devam et
            }
          }
        }
        
        final transactionData = {
          'user_id': userId,
          'type': typeValue,
          'amount': amount,
          'description': description,
          'category': category,
          'credit_card_id': creditCardId,
          'debit_card_id': debitCardId,
          'cash_account_id': cashAccountId,
          'target_credit_card_id': targetCreditCardId,
          'target_debit_card_id': targetDebitCardId,
          'target_cash_account_id': targetCashAccountId,
          'installment_count': installmentCount,
          'current_installment': currentInstallment,
          'merchant_name': merchantName,
          'location': location,
          'notes': notes,
          'transaction_date': transactionDateTime.toUtc().toIso8601String(),
        };

        final response = await _supabase
            .from(_tableName)
            .insert(transactionData)
            .select()
            .maybeSingle();

        if (response == null) {
          throw Exception('İşlem kaydedildi ancak bulunamadı');
        }

        final transaction = TransactionModel.fromJson(response);
        
        print('⚠️ Transaction created without balance update (fallback)');
        
        // 🔔 Event emit et - Transaction eklendi (fallback)
        emitTransactionAdded(transaction);
        
        // 🔔 Bakiye güncellemesi event'i emit et
        _emitBalanceUpdateEvents(transaction, type, amount);
        
        return transaction;
      }
    } on InsufficientFundsException {
      // InsufficientFundsException'ı rethrow et - wrap etme
      rethrow;
    } catch (e) {
      print('❌ Transaction creation error: $e');
      // InsufficientFundsException'ı wrap etme
      if (e is InsufficientFundsException) {
        rethrow;
      }
      throw Exception('İşlem oluşturulurken hata oluştu: $e');
    }
  }

  // İşlem güncelle
  static Future<TransactionModel> updateTransaction({
    required String transactionId,
    TransactionType? type,
    double? amount,
    String? description,
    String? category,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? transactionDate,
  }) async {
    try {
      // Önce eski transaction'ı al
      final oldTransaction = await getTransactionById(transactionId);
      if (oldTransaction == null) {
        throw Exception('Güncellenecek işlem bulunamadı');
      }

      final updateData = <String, dynamic>{};
      
      if (type != null) updateData['type'] = type.name.toLowerCase();
      if (amount != null) updateData['amount'] = amount;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (merchantName != null) updateData['merchant_name'] = merchantName;
      if (location != null) updateData['location'] = location;
      if (notes != null) updateData['notes'] = notes;
      if (transactionDate != null) updateData['transaction_date'] = transactionDate.toUtc().toIso8601String();

      if (updateData.isEmpty) {
        throw Exception('Güncellenecek alan bulunamadı');
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', transactionId)
          .select()
          .single();

      final newTransaction = TransactionModel.fromJson(response);
      
      // 🔔 Event emit et - Transaction güncellendi
      transactionEvents.emitTransactionUpdated(
        oldTransaction: oldTransaction,
        newTransaction: newTransaction,
      );

      return newTransaction;
    } catch (e) {
      throw Exception('İşlem güncellenirken hata oluştu: $e');
    }
  }

  // İşlem sil
  static Future<void> deleteTransaction(String transactionId) async {
    try {
      print('🔍 Starting transaction deletion: $transactionId');
      print('🔍 Current time: ${DateTime.now()}');
      
      // Önce işlem bilgilerini al (event için gerekli)
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) {
        throw Exception('Silinecek işlem bulunamadı');
      }
      
      print('🔍 Transaction to delete: ${transaction.description}, Amount: ${transaction.amount}, Type: ${transaction.type}');
      print('🔍 Source card: ${transaction.sourceCardType} - ${transaction.sourceCardId}');

      // Taksitli işlem kontrolü
      if (transaction.installmentCount > 1) {
        print('🔍 Installment transaction detected, searching for installment data...');
        
        // Taksitli işlemler için credit card ID zorunlu
        if (transaction.creditCardId == null) {
          print('❌ Installment transaction missing credit card ID');
          throw Exception('Taksitli işlem için kredi kartı bilgisi bulunamadı');
        }
        
        try {
          // 🔥 YENİ STRATEJI: installment_details tablosu üzerinden ara
          // transactions tablosundaki kayıt ile installment_details'i eşleştir
          final installmentDetailsResponse = await _supabase
              .from('installment_details')
              .select('''
                installment_transaction_id,
                installment_transactions!inner(
                  id,
                  total_amount,
                  credit_card_id
                )
              ''')
              .eq('installment_number', 1)
              .eq('installment_transactions.credit_card_id', transaction.creditCardId!)
              .gte('installment_transactions.purchase_date', 
                   transaction.transactionDate.subtract(const Duration(hours: 24)).toIso8601String())
              .lte('installment_transactions.purchase_date', 
                   transaction.transactionDate.add(const Duration(hours: 24)).toIso8601String());
          
          print('🔍 Installment details search result: $installmentDetailsResponse');
          
          if (installmentDetailsResponse.isNotEmpty) {
            // En yakın tarihli taksitli işlemi bul
            final matchingDetail = installmentDetailsResponse.first;
            final installmentTransaction = matchingDetail['installment_transactions'];
            final installmentTransactionId = installmentTransaction['id'];
            final totalAmount = (installmentTransaction['total_amount'] as num).toDouble();
            
            print('🔍 Found matching installment transaction ID: $installmentTransactionId');
            print('🔍 Total amount from installment_transactions: $totalAmount');
            
            // Taksitli işlem silme - RPC ile bakiye güncellemesi yaparak
            try {
              print('🔍 Deleting installment transaction with balance rollback...');
              print('🔍 Calling delete_installment_transaction_with_balance_rollback RPC...');
              
              final result = await _supabase.rpc('delete_installment_transaction_with_balance_rollback', params: {
                'p_transaction_id': transactionId,
              });
              
              print('✅ RPC delete_installment_transaction_with_balance_rollback completed: $result');
              print('🔄 RPC completed - balance already updated in database');
              
              // 🔔 Event emit et - Taksitli işlem silindi
              print('🔔 Emitting TransactionDeleted event...');
              print('🔔 Event details: transactionId=$transactionId, cardId=${transaction.sourceCardId}, cardType=${transaction.sourceCardType}');
              emitTransactionDeleted(
                transactionId: transactionId,
                deletedTransaction: transaction,
                cardId: transaction.sourceCardId,
                cardType: transaction.sourceCardType,
                amount: transaction.amount,
                type: transaction.type,
              );
              print('🔔 TransactionDeleted event emitted successfully!');
              
              // 🔔 RPC başarılı olduğunda da bakiye güncellemesi event'i emit et
              // RPC veritabanında bakiye güncellemesi yaptı, UI'ı da güncellememiz gerekiyor
              print('🔔 Emitting BalanceUpdated event (RPC successful - UI needs update)...');
              _emitBalanceUpdateEventsForDeletion(transaction);
              print('✅ Installment transaction deletion completed - RPC handled balance updates, UI events emitted');
              return; // Early return for installment transactions
              
            } catch (e) {
              print('❌ RPC delete failed, falling back to direct delete: $e');
              // RPC başarısız olursa fallback olarak direkt silme
              await _supabase
                  .from(_tableName)
                  .delete()
                  .eq('id', transactionId);
              
              print('⚠️ Installment transaction deleted without balance rollback (fallback)');
              
              // 🔔 Event emit et - Fallback silme
              print('🔔 Emitting TransactionDeleted event (fallback)...');
              emitTransactionDeleted(
                transactionId: transactionId,
                deletedTransaction: transaction,
                cardId: transaction.sourceCardId,
                cardType: transaction.sourceCardType,
                amount: transaction.amount,
                type: transaction.type,
              );
              
              // 🔔 Bakiye güncellemesi event'i emit et (sadece fallback durumunda)
              print('🔔 Emitting BalanceUpdated event (fallback - manual balance update needed)...');
              _emitBalanceUpdateEventsForDeletion(transaction);
              return; // Early return for fallback
            }
          } else {
            print('⚠️ No matching installment transaction found via installment_details, proceeding with normal delete');
          }
        } catch (e) {
          // Hata durumunda normal silme işlemine devam etme, hatayı fırlat
          print('❌ Installment search error: $e');
          throw Exception('Taksitli işlem silinirken hata oluştu: $e');
        }
      }

      // Normal işlem silme - RPC ile bakiye güncellemesi yaparak
      try {
        print('🔍 Deleting normal transaction with balance rollback...');
        print('🔍 Calling delete_transaction_with_balance_rollback RPC...');
        
        final result = await _supabase.rpc('delete_transaction_with_balance_rollback', params: {
          'p_transaction_id': transactionId,
        });
        
        print('✅ RPC delete_transaction_with_balance_rollback completed: $result');
        print('🔄 RPC completed - balance already updated in database');
        
        // 🔔 Event emit et - Normal işlem silindi
        print('🔔 Emitting TransactionDeleted event...');
        print('🔔 Event details: transactionId=$transactionId, cardId=${transaction.sourceCardId}, cardType=${transaction.sourceCardType}');
        emitTransactionDeleted(
          transactionId: transactionId,
          deletedTransaction: transaction,
          cardId: transaction.sourceCardId,
          cardType: transaction.sourceCardType,
          amount: transaction.amount,
          type: transaction.type,
        );
        print('🔔 TransactionDeleted event emitted successfully!');
        
        // 🔔 RPC başarılı olduğunda da bakiye güncellemesi event'i emit et
        // RPC veritabanında bakiye güncellemesi yaptı, UI'ı da güncellememiz gerekiyor
        print('🔔 Emitting BalanceUpdated event (RPC successful - UI needs update)...');
        _emitBalanceUpdateEventsForDeletion(transaction);
        print('✅ Transaction deletion completed (normal) - RPC handled balance updates, UI events emitted');
        
      } catch (e) {
        print('❌ RPC delete failed, falling back to direct delete: $e');
        // RPC başarısız olursa fallback olarak direkt silme
        await _supabase
            .from(_tableName)
            .delete()
            .eq('id', transactionId);
        
        print('⚠️ Transaction deleted without balance rollback (fallback)');
        
        // 🔔 Event emit et - Fallback silme
        print('🔔 Emitting TransactionDeleted event (fallback)...');
        print('🔔 Event details: transactionId=$transactionId, cardId=${transaction.sourceCardId}, cardType=${transaction.sourceCardType}');
        emitTransactionDeleted(
          transactionId: transactionId,
          deletedTransaction: transaction,
          cardId: transaction.sourceCardId,
          cardType: transaction.sourceCardType,
          amount: transaction.amount,
          type: transaction.type,
        );
        print('🔔 TransactionDeleted event emitted successfully (fallback)!');
        
        // 🔔 Bakiye güncellemesi event'i emit et (sadece fallback durumunda)
        print('🔔 Emitting BalanceUpdated event (fallback - manual balance update needed)...');
        _emitBalanceUpdateEventsForDeletion(transaction);
      }
      
      print('✅ Transaction deletion process completed for: $transactionId');
    } catch (e) {
      print('❌ Delete transaction error: $e');
      throw Exception('İşlem silinirken hata oluştu: $e');
    }
  }

  // Belirli bir işlemi getir
  static Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', transactionId)
          .maybeSingle();

      if (response == null) return null;
      return TransactionModel.fromJson(response);
    } catch (e) {
      throw Exception('İşlem yüklenirken hata oluştu: $e');
    }
  }

  // İşlem istatistikleri
  static Future<Map<String, double>> getTransactionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      dynamic query = _supabase
          .from(_tableName)
          .select('type, amount')
          .eq('user_id', currentUser.id);

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      final response = await query;
      
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (final transaction in response) {
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['type'] as String;
        
        if (type == 'income') {
          totalIncome += amount;
        } else if (type == 'expense') {
          totalExpense += amount;
        }
      }
      
      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('İstatistikler hesaplanırken hata oluştu: $e');
    }
  }

  // Kategori bazlı harcamalar
  static Future<Map<String, double>> getCategoryExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Kullanıcı oturum kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      dynamic query = _supabase
          .from(_tableName)
          .select('category, amount')
          .eq('user_id', currentUser.id)
          .eq('type', 'expense');

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      final response = await query;
      
      final Map<String, double> categoryExpenses = {};
      
      for (final transaction in response) {
        final amount = (transaction['amount'] as num).toDouble();
        final category = transaction['category'] as String? ?? 'Diğer';
        
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
      }
      
      return categoryExpenses;
    } catch (e) {
      throw Exception('Kategori harcamaları hesaplanırken hata oluştu: $e');
    }
  }

  // Bakiye güncelleme event'lerini emit et
  static void _emitBalanceUpdateEvents(
    TransactionModel transaction, 
    TransactionType type, 
    double amount
  ) {
    print('🔔 Emitting balance update events for creation...');
    print('🔔 Transaction details:');
    print('   - Credit Card ID: ${transaction.creditCardId}');
    print('   - Debit Card ID: ${transaction.debitCardId}');
    print('   - Cash Account ID: ${transaction.cashAccountId}');
    print('   - Transaction Type: $type');
    print('   - Amount: $amount');
    
    // Kaynak kart için bakiye güncellemesi
    // SADECE gerçekten kullanılan kart türü için event emit et
    if (transaction.creditCardId != null) {
      // Kredi kartı için - gider ise borç artar, gelir ise borç azalır
      final balanceChange = type == TransactionType.expense ? amount : -amount;
      print('🔔 Emitting BalanceUpdated for CREDIT card: ${transaction.creditCardId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.creditCardId!,
        cardType: CardType.credit,
        oldBalance: 0, // RPC'den önceki bakiye bilgisi yok
        newBalance: 0, // RPC'den sonraki bakiye bilgisi yok
        changeAmount: balanceChange,
      );
    } else if (transaction.debitCardId != null) {
      // Banka kartı için - gider ise bakiye azalır, gelir ise bakiye artar
      final balanceChange = type == TransactionType.expense ? -amount : amount;
      print('🔔 Emitting BalanceUpdated for DEBIT card: ${transaction.debitCardId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.debitCardId!,
        cardType: CardType.debit,
        oldBalance: 0,
        newBalance: 0,
        changeAmount: balanceChange,
      );
    } else if (transaction.cashAccountId != null) {
      // Nakit hesabı için - gider ise bakiye azalır, gelir ise bakiye artar
      final balanceChange = type == TransactionType.expense ? -amount : amount;
      print('🔔 Emitting BalanceUpdated for CASH account: ${transaction.cashAccountId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.cashAccountId!,
        cardType: CardType.cash,
        oldBalance: 0,
        newBalance: 0,
        changeAmount: balanceChange,
      );
    }
    
    // Transfer işlemi için hedef kart
    if (type == TransactionType.transfer) {
      if (transaction.targetCreditCardId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET CREDIT card: ${transaction.targetCreditCardId}');
        emitBalanceUpdated(
          cardId: transaction.targetCreditCardId!,
          cardType: CardType.credit,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: -amount, // Transfer geldiğinde borç azalır
        );
      } else if (transaction.targetDebitCardId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET DEBIT card: ${transaction.targetDebitCardId}');
        emitBalanceUpdated(
          cardId: transaction.targetDebitCardId!,
          cardType: CardType.debit,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: amount, // Transfer geldiğinde bakiye artar
        );
      } else if (transaction.targetCashAccountId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET CASH account: ${transaction.targetCashAccountId}');
        emitBalanceUpdated(
          cardId: transaction.targetCashAccountId!,
          cardType: CardType.cash,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: amount, // Transfer geldiğinde bakiye artar
        );
      }
    }
    
    print('✅ Balance update events emitted for creation');
  }

  // Bakiye güncelleme event'lerini emit et (silme için ters işlem)
  static void _emitBalanceUpdateEventsForDeletion(TransactionModel transaction) {
    print('🔔 Emitting balance update events for deletion...');
    print('🔔 Transaction details:');
    print('   - Credit Card ID: ${transaction.creditCardId}');
    print('   - Debit Card ID: ${transaction.debitCardId}');
    print('   - Cash Account ID: ${transaction.cashAccountId}');
    print('   - Transaction Type: ${transaction.type}');
    print('   - Amount: ${transaction.amount}');
    
    // Kaynak kart için bakiye güncellemesi (silme işleminde ters yönde)
    // SADECE gerçekten kullanılan kart türü için event emit et
    if (transaction.creditCardId != null) {
      // Kredi kartı için - gider silme ise borç azalır, gelir silme ise borç artar
      final balanceChange = transaction.type == TransactionType.expense ? -transaction.amount : transaction.amount;
      print('🔔 Emitting BalanceUpdated for CREDIT card: ${transaction.creditCardId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.creditCardId!,
        cardType: CardType.credit,
        oldBalance: 0,
        newBalance: 0,
        changeAmount: balanceChange,
      );
    } else if (transaction.debitCardId != null) {
      // Banka kartı için - gider silme ise bakiye artar, gelir silme ise bakiye azalır
      final balanceChange = transaction.type == TransactionType.expense ? transaction.amount : -transaction.amount;
      print('🔔 Emitting BalanceUpdated for DEBIT card: ${transaction.debitCardId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.debitCardId!,
        cardType: CardType.debit,
        oldBalance: 0,
        newBalance: 0,
        changeAmount: balanceChange,
      );
    } else if (transaction.cashAccountId != null) {
      // Nakit hesabı için - gider silme ise bakiye artar, gelir silme ise bakiye azalır
      final balanceChange = transaction.type == TransactionType.expense ? transaction.amount : -transaction.amount;
      print('🔔 Emitting BalanceUpdated for CASH account: ${transaction.cashAccountId}');
      print('   - Balance change: $balanceChange');
      emitBalanceUpdated(
        cardId: transaction.cashAccountId!,
        cardType: CardType.cash,
        oldBalance: 0,
        newBalance: 0,
        changeAmount: balanceChange,
      );
    }
    
    // Transfer işlemi için hedef kart (silme işleminde ters yönde)
    if (transaction.type == TransactionType.transfer) {
      if (transaction.targetCreditCardId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET CREDIT card: ${transaction.targetCreditCardId}');
        emitBalanceUpdated(
          cardId: transaction.targetCreditCardId!,
          cardType: CardType.credit,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: transaction.amount, // Transfer silme ise borç artar
        );
      } else if (transaction.targetDebitCardId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET DEBIT card: ${transaction.targetDebitCardId}');
        emitBalanceUpdated(
          cardId: transaction.targetDebitCardId!,
          cardType: CardType.debit,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: -transaction.amount, // Transfer silme ise bakiye azalır
        );
      } else if (transaction.targetCashAccountId != null) {
        print('🔔 Emitting BalanceUpdated for TARGET CASH account: ${transaction.targetCashAccountId}');
        emitBalanceUpdated(
          cardId: transaction.targetCashAccountId!,
          cardType: CardType.cash,
          oldBalance: 0,
          newBalance: 0,
          changeAmount: -transaction.amount, // Transfer silme ise bakiye azalır
        );
      }
    }
    
    print('✅ Balance update events emitted for deletion');
  }
} 