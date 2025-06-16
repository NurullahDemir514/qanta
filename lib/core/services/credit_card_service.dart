import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/credit_card_model.dart';
import '../constants/app_constants.dart';

class CreditCardService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'credit_cards';

  // Tüm kredi kartlarını getir
  static Future<List<CreditCardModel>> getCreditCards() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CreditCardModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kredi kartları yüklenirken hata oluştu: $e');
    }
  }

  // Belirli bir kredi kartını getir
  static Future<CreditCardModel?> getCreditCard(String cardId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', cardId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return CreditCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Kredi kartı yüklenirken hata oluştu: $e');
    }
  }

  // Yeni kredi kartı ekle
  static Future<CreditCardModel> addCreditCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    required double creditLimit,
    double? availableLimit,
    double? totalDebt,
    required int statementDate,
    required int dueDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Bank code'dan bank name'i al
      final bankName = AppConstants.getBankName(bankCode);

      // Son 4 hane yoksa rastgele üret
      final finalLastFourDigits = lastFourDigits?.isNotEmpty == true 
          ? lastFourDigits! 
          : _generateRandomLastFourDigits();

      // Kullanılabilir limit hesapla
      final finalTotalDebt = totalDebt ?? 0.0;
      final finalAvailableLimit = availableLimit ?? (creditLimit - finalTotalDebt);

      final cardData = {
        'user_id': user.id,
        'bank_code': bankCode,
        'bank_name': bankName,
        'card_name': cardName ?? 'Kredi Kartı',
        'card_number_last_four': finalLastFourDigits,
        'credit_limit': creditLimit,
        'available_limit': finalAvailableLimit,
        'current_balance': finalTotalDebt,
        'statement_day': statementDate,
        'due_day': dueDate,
        'is_active': true,
      };

      final response = await _supabase
          .from(_tableName)
          .insert(cardData)
          .select()
          .single();

      return CreditCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Kredi kartı eklenirken hata oluştu: $e');
    }
  }

  // Kredi kartını güncelle
  static Future<CreditCardModel> updateCreditCard({
    required String cardId,
    String? cardName,
    double? creditLimit,
    double? totalDebt,
    int? statementDate,
    int? dueDate,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (cardName != null) updateData['card_name'] = cardName;
      if (creditLimit != null) updateData['credit_limit'] = creditLimit;
      if (totalDebt != null) {
        updateData['current_balance'] = totalDebt;
        // Kullanılabilir limiti yeniden hesapla
        final currentCard = await getCreditCard(cardId);
        if (currentCard != null) {
          final newCreditLimit = creditLimit ?? currentCard.creditLimit;
          updateData['available_limit'] = newCreditLimit - totalDebt;
        }
      }
      if (statementDate != null) updateData['statement_day'] = statementDate;
      if (dueDate != null) updateData['due_day'] = dueDate;
      if (isActive != null) updateData['is_active'] = isActive;

      if (updateData.isEmpty) {
        throw Exception('Güncellenecek alan bulunamadı');
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', cardId)
          .select()
          .single();

      return CreditCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Kredi kartı güncellenirken hata oluştu: $e');
    }
  }

  // Kredi kartı harcaması yap
  static Future<CreditCardModel> makePayment({
    required String cardId,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Harcama tutarı pozitif olmalıdır');
      }

      final card = await getCreditCard(cardId);
      if (card == null) {
        throw Exception('Kredi kartı bulunamadı');
      }

      if (amount > card.availableLimit) {
        throw Exception('Yetersiz kredi limiti');
      }

      final newTotalDebt = card.totalDebt + amount;
      final newAvailableLimit = card.creditLimit - newTotalDebt;

      final response = await _supabase
          .from(_tableName)
          .update({
            'current_balance': newTotalDebt,
            'available_limit': newAvailableLimit,
          })
          .eq('id', cardId)
          .select()
          .single();

      return CreditCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Ödeme işlemi sırasında hata oluştu: $e');
    }
  }

  // Kredi kartı ödemesi yap (borç azaltma)
  static Future<CreditCardModel> makePaymentToCard({
    required String cardId,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Ödeme tutarı pozitif olmalıdır');
      }

      final card = await getCreditCard(cardId);
      if (card == null) {
        throw Exception('Kredi kartı bulunamadı');
      }

      if (amount > card.totalDebt) {
        throw Exception('Ödeme tutarı toplam borçtan fazla olamaz');
      }

      final newTotalDebt = card.totalDebt - amount;
      final newAvailableLimit = card.creditLimit - newTotalDebt;

      final response = await _supabase
          .from(_tableName)
          .update({
            'current_balance': newTotalDebt,
            'available_limit': newAvailableLimit,
          })
          .eq('id', cardId)
          .select()
          .single();

      return CreditCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Ödeme işlemi sırasında hata oluştu: $e');
    }
  }

  // Kredi kartını sil (soft delete)
  static Future<void> deleteCreditCard(String cardId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_active': false})
          .eq('id', cardId);
    } catch (e) {
      throw Exception('Kredi kartı silinirken hata oluştu: $e');
    }
  }

  // Banka koduna göre kredi kartlarını getir
  static Future<List<CreditCardModel>> getCreditCardsByBank(String bankCode) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('bank_code', bankCode)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CreditCardModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Banka kredi kartları yüklenirken hata oluştu: $e');
    }
  }

  // Toplam kredi limiti hesapla
  static Future<double> getTotalCreditLimit() async {
    try {
      final cards = await getCreditCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.creditLimit);
    } catch (e) {
      throw Exception('Toplam kredi limiti hesaplanırken hata oluştu: $e');
    }
  }

  // Toplam kullanılabilir limit hesapla
  static Future<double> getTotalAvailableLimit() async {
    try {
      final cards = await getCreditCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.availableLimit);
    } catch (e) {
      throw Exception('Toplam kullanılabilir limit hesaplanırken hata oluştu: $e');
    }
  }

  // Toplam borç hesapla
  static Future<double> getTotalDebt() async {
    try {
      final cards = await getCreditCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.totalDebt);
    } catch (e) {
      throw Exception('Toplam borç hesaplanırken hata oluştu: $e');
    }
  }

  // Yaklaşan son ödeme tarihleri (30 gün içinde)
  static Future<List<CreditCardModel>> getUpcomingDueDates() async {
    try {
      final cards = await getCreditCards();
      final now = DateTime.now();
      
      return cards.where((card) {
        final daysUntilDue = card.daysUntilDue;
        return daysUntilDue >= 0 && daysUntilDue <= 30;
      }).toList()
        ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    } catch (e) {
      throw Exception('Yaklaşan ödemeler yüklenirken hata oluştu: $e');
    }
  }

  // Rastgele 4 haneli sayı üret
  static String _generateRandomLastFourDigits() {
    final random = Random();
    final digits = List.generate(4, (index) => random.nextInt(10));
    return digits.join();
  }
} 