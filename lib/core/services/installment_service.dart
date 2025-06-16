import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/installment_models.dart';
import '../../shared/models/transaction_model.dart';
import 'transaction_service.dart';

class InstallmentService {
  static final _supabase = Supabase.instance.client;

  /// Taksitli işlem oluştur (2+ taksit için)
  static Future<String> createInstallmentTransaction({
    required String creditCardId,
    required double totalAmount,
    required int installmentCount,
    required String description,
    String? category,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? purchaseDate,
  }) async {
    try {
      // Validasyonlar
      if (installmentCount < 2) {
        throw Exception('Taksit sayısı en az 2 olmalıdır');
      }
      
      if (totalAmount <= 0) {
        throw Exception('Tutar pozitif olmalıdır');
      }

      // Supabase fonksiyonunu çağır
      final response = await _supabase.rpc('create_installment_transaction', params: {
        'p_credit_card_id': creditCardId,
        'p_total_amount': totalAmount,
        'p_installment_count': installmentCount,
        'p_description': description,
        'p_category': category,
        'p_merchant_name': merchantName,
        'p_location': location,
        'p_notes': notes,
        'p_purchase_date': (purchaseDate ?? DateTime.now()).toUtc().toIso8601String(),
      });

      if (response == null) {
        throw Exception('Taksitli işlem oluşturulamadı - response null');
      }

      return response as String;
    } on PostgrestException catch (e) {
      // PostgrestException'ı özel olarak handle et
      if (e.code == 'P0001') {
        if (e.message.contains('Kredi kartı limiti aşıldı')) {
          // Kredi kartı limit aşımı
          throw InsufficientFundsException(
            message: 'Kredi kartı limitiniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınızın borcunu ödeyin.',
            cardType: 'credit',
            availableAmount: 0,
            requestedAmount: totalAmount,
          );
        } else if (e.message.contains('Banka kartı bakiyesi negatif olamaz')) {
          // Banka kartı bakiye yetersizliği
          throw InsufficientFundsException(
            message: 'Banka kartı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınıza para yatırın.',
            cardType: 'debit',
            availableAmount: 0,
            requestedAmount: totalAmount,
          );
        } else if (e.message.contains('Nakit hesabı bakiyesi negatif olamaz')) {
          // Nakit hesabı bakiye yetersizliği
          throw InsufficientFundsException(
            message: 'Nakit hesabı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin.',
            cardType: 'cash',
            availableAmount: 0,
            requestedAmount: totalAmount,
          );
        } else {
          // Diğer P0001 hataları
          throw Exception('İşlem gerçekleştirilemedi: ${e.message}');
        }
      } else {
        // Diğer PostgrestException'lar için genel mesaj
        throw Exception('İşlem gerçekleştirilemedi: ${e.message}');
      }
    } catch (e) {
      // Diğer hatalar için mevcut handling
      final errorString = e.toString();
      if (errorString.contains('Kredi kartı limiti aşıldı')) {
        throw InsufficientFundsException(
          message: 'Kredi kartı limitiniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınızın borcunu ödeyin.',
          cardType: 'credit',
          availableAmount: 0,
          requestedAmount: totalAmount,
        );
      } else if (errorString.contains('Banka kartı bakiyesi negatif olamaz')) {
        throw InsufficientFundsException(
          message: 'Banka kartı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin veya kartınıza para yatırın.',
          cardType: 'debit',
          availableAmount: 0,
          requestedAmount: totalAmount,
        );
      } else if (errorString.contains('Nakit hesabı bakiyesi negatif olamaz')) {
        throw InsufficientFundsException(
          message: 'Nakit hesabı bakiyeniz yetersiz. Lütfen daha düşük bir tutar girin.',
          cardType: 'cash',
          availableAmount: 0,
          requestedAmount: totalAmount,
        );
      }
      throw Exception('Taksitli işlem oluşturulurken hata: $e');
    }
  }

  /// Kullanıcının taksitli işlemlerini getir
  static Future<List<InstallmentTransaction>> getUserInstallmentTransactions({
    int? limit,
    int? offset,
    String? creditCardId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      dynamic query = _supabase
          .from('installment_transactions')
          .select('''
            *,
            credit_cards!inner(card_name, bank_code),
            installment_details(*)
          ''');

      // Filtreler
      if (creditCardId != null) {
        query = query.eq('credit_card_id', creditCardId);
      }
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      if (startDate != null) {
        query = query.gte('purchase_date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('purchase_date', endDate.toIso8601String());
      }

      // Sıralama ve sayfalama
      query = query.order('purchase_date', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      
      return (response as List).map((json) {
        // İlişkili verileri düzenle
        final creditCard = json['credit_cards'];
        final installmentDetails = (json['installment_details'] as List?)
            ?.map((detail) => InstallmentDetail.fromJson(detail))
            .toList();

        return InstallmentTransaction.fromJson({
          ...json,
          'card_name': creditCard?['card_name'],
          'bank_code': creditCard?['bank_code'],
        }).copyWith(installmentDetails: installmentDetails);
      }).toList();
    } catch (e) {
      throw Exception('Taksitli işlemler getirilirken hata: $e');
    }
  }

  /// Taksitli işlem özetlerini getir (performanslı)
  static Future<List<InstallmentSummary>> getInstallmentSummaries({
    int? limit,
    int? offset,
    String? creditCardId,
  }) async {
    try {
      dynamic query = _supabase.from('installment_summary').select('*');

      if (creditCardId != null) {
        query = query.eq('credit_card_id', creditCardId);
      }

      query = query.order('purchase_date', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      
      return (response as List)
          .map((json) => InstallmentSummary.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Taksit özetleri getirilirken hata: $e');
    }
  }

  /// Yaklaşan taksitleri getir
  static Future<List<UpcomingInstallment>> getUpcomingInstallments({
    int daysAhead = 30,
  }) async {
    try {
      final response = await _supabase.rpc('get_upcoming_installments', params: {
        'p_days_ahead': daysAhead,
      });

      return (response as List)
          .map((json) => UpcomingInstallment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Yaklaşan taksitler getirilirken hata: $e');
    }
  }

  /// Taksit öde
  static Future<String> payInstallment({
    required String installmentTransactionId,
    required int installmentNumber,
  }) async {
    try {
      final response = await _supabase.rpc('pay_installment', params: {
        'p_installment_transaction_id': installmentTransactionId,
        'p_installment_number': installmentNumber,
      });

      if (response == null) {
        throw Exception('Taksit ödemesi yapılamadı');
      }

      return response as String;
    } catch (e) {
      throw Exception('Taksit ödenirken hata: $e');
    }
  }

  /// Taksitli işlem detaylarını getir
  static Future<InstallmentTransaction?> getInstallmentTransaction(String id) async {
    try {
      final response = await _supabase
          .from('installment_transactions')
          .select('''
            *,
            credit_cards!inner(card_name, bank_code),
            installment_details(*)
          ''')
          .eq('id', id)
          .single();

      final creditCard = response['credit_cards'];
      final installmentDetails = (response['installment_details'] as List?)
          ?.map((detail) => InstallmentDetail.fromJson(detail))
          .toList();

      return InstallmentTransaction.fromJson({
        ...response,
        'card_name': creditCard?['card_name'],
        'bank_code': creditCard?['bank_code'],
      }).copyWith(installmentDetails: installmentDetails);
    } catch (e) {
      throw Exception('Taksitli işlem detayı getirilirken hata: $e');
    }
  }

  /// Taksit detaylarını getir
  static Future<List<InstallmentDetail>> getInstallmentDetails(String installmentTransactionId) async {
    try {
      final response = await _supabase
          .from('installment_details')
          .select('*')
          .eq('installment_transaction_id', installmentTransactionId)
          .order('installment_number');

      return (response as List)
          .map((json) => InstallmentDetail.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Taksit detayları getirilirken hata: $e');
    }
  }

  /// Taksitli işlem güncelle
  static Future<void> updateInstallmentTransaction({
    required String id,
    String? description,
    String? category,
    String? merchantName,
    String? location,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (merchantName != null) updateData['merchant_name'] = merchantName;
      if (location != null) updateData['location'] = location;
      if (notes != null) updateData['notes'] = notes;
      
      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
        
        await _supabase
            .from('installment_transactions')
            .update(updateData)
            .eq('id', id);
      }
    } catch (e) {
      throw Exception('Taksitli işlem güncellenirken hata: $e');
    }
  }

  /// Taksitli işlem sil
  static Future<void> deleteInstallmentTransaction(String id) async {
    try {
      await _supabase
          .from('installment_transactions')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Taksitli işlem silinirken hata: $e');
    }
  }

  /// Kredi kartının taksitli işlemlerini getir
  static Future<List<InstallmentSummary>> getCreditCardInstallments(String creditCardId) async {
    try {
      final response = await _supabase
          .from('installment_summary')
          .select('*')
          .eq('credit_card_id', creditCardId)
          .order('purchase_date', ascending: false);

      return (response as List)
          .map((json) => InstallmentSummary.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kredi kartı taksitleri getirilirken hata: $e');
    }
  }

  /// Aylık taksit ödemelerini getir
  static Future<double> getMonthlyInstallmentPayments({
    required int year,
    required int month,
    String? creditCardId,
  }) async {
    try {
      dynamic query = _supabase
          .from('installment_details')
          .select('amount, installment_transactions!inner(credit_card_id)')
          .eq('is_paid', false)
          .gte('due_date', DateTime(year, month, 1).toIso8601String())
          .lt('due_date', DateTime(year, month + 1, 1).toIso8601String());

      if (creditCardId != null) {
        query = query.eq('installment_transactions.credit_card_id', creditCardId);
      }

      final response = await query;
      
      return (response as List).fold<double>(0.0, (double sum, item) => sum + (item['amount'] as num).toDouble());
    } catch (e) {
      throw Exception('Aylık taksit ödemeleri hesaplanırken hata: $e');
    }
  }

  /// Toplam taksit borcu
  static Future<double> getTotalInstallmentDebt({String? creditCardId}) async {
    try {
      dynamic query = _supabase
          .from('installment_details')
          .select('amount, installment_transactions!inner(credit_card_id)')
          .eq('is_paid', false);

      if (creditCardId != null) {
        query = query.eq('installment_transactions.credit_card_id', creditCardId);
      }

      final response = await query;
      
      return (response as List).fold<double>(0.0, (double sum, item) => sum + (item['amount'] as num).toDouble());
    } catch (e) {
      throw Exception('Toplam taksit borcu hesaplanırken hata: $e');
    }
  }
}

/// Entegre Transaction Service - Mevcut sistemi bozmadan çalışır
class IntegratedTransactionService {
  /// İşlem oluştur - Taksit sayısına göre uygun servisi kullan
  static Future<String> createTransaction({
    required TransactionType type,
    required double amount,
    required String description,
    String? category,
    String? creditCardId,
    String? debitCardId,
    String? cashAccountId,
    String? merchantName,
    String? location,
    DateTime? transactionDate,
    int? installmentCount,
  }) async {
    try {
      // Taksit kontrolü
      if (installmentCount != null && installmentCount > 1 && creditCardId != null && type == TransactionType.expense) {
        // Yeni taksit sistemi kullan
        return await InstallmentService.createInstallmentTransaction(
          creditCardId: creditCardId,
          totalAmount: amount,
          installmentCount: installmentCount,
          description: description,
          category: category,
          merchantName: merchantName,
          location: location,
          purchaseDate: transactionDate,
        );
      } else {
        // Mevcut sistem kullan
        final transaction = await TransactionService.createTransaction(
          type: type,
          amount: amount,
          description: description,
          category: category,
          creditCardId: creditCardId,
          debitCardId: debitCardId,
          cashAccountId: cashAccountId,
          installmentCount: installmentCount ?? 1,
          merchantName: merchantName,
          location: location,
          transactionDate: transactionDate,
        );
        return transaction.id;
      }
    } catch (e) {
      throw Exception('İşlem oluşturulurken hata: $e');
    }
  }

  /// Birleşik işlem listesi getir (hem normal hem taksitli)
  static Future<List<dynamic>> getAllTransactions({
    int? limit,
    int? offset,
    String? cardId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Normal işlemleri getir
      final normalTransactions = await TransactionService.getUserTransactions(
        limit: limit,
        offset: offset,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );

      // Taksitli işlemleri getir
      final installmentTransactions = await InstallmentService.getUserInstallmentTransactions(
        limit: limit,
        offset: offset,
        creditCardId: cardId,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );

      // Birleştir ve tarihe göre sırala
      final allTransactions = <dynamic>[
        ...normalTransactions,
        ...installmentTransactions,
      ];

      allTransactions.sort((a, b) {
        final dateA = a is TransactionModel ? a.transactionDate : (a as InstallmentTransaction).purchaseDate;
        final dateB = b is TransactionModel ? b.transactionDate : (b as InstallmentTransaction).purchaseDate;
        return dateB.compareTo(dateA);
      });

      return allTransactions;
    } catch (e) {
      throw Exception('Tüm işlemler getirilirken hata: $e');
    }
  }

  /// Kart için birleşik işlem listesi
  static Future<List<dynamic>> getCardTransactions({
    required String cardId,
    int? limit,
    int? offset,
  }) async {
    try {
      // Normal işlemleri getir
      final normalTransactions = await TransactionService.getCardTransactions(
        cardId: cardId,
        cardType: CardType.credit,
        limit: limit,
        offset: offset,
      );

      // Taksitli işlemleri getir
      final installmentTransactions = await InstallmentService.getUserInstallmentTransactions(
        creditCardId: cardId,
        limit: limit,
        offset: offset,
      );

      // Birleştir ve tarihe göre sırala
      final allTransactions = <dynamic>[
        ...normalTransactions,
        ...installmentTransactions,
      ];

      allTransactions.sort((a, b) {
        final dateA = a is TransactionModel ? a.transactionDate : (a as InstallmentTransaction).purchaseDate;
        final dateB = b is TransactionModel ? b.transactionDate : (b as InstallmentTransaction).purchaseDate;
        return dateB.compareTo(dateA);
      });

      return allTransactions;
    } catch (e) {
      throw Exception('Kart işlemleri getirilirken hata: $e');
    }
  }
} 