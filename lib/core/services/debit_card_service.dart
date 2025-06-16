import '../constants/app_constants.dart';
import '../../shared/models/debit_card_model.dart';
import 'supabase_service.dart';

class DebitCardService {
  static final _supabase = SupabaseService.instance.client;

  // Kullanıcının tüm banka kartlarını getir
  static Future<List<DebitCardModel>> getUserDebitCards() async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase
          .from('debit_cards')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DebitCardModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Banka kartları yüklenirken hata oluştu: $e');
    }
  }

  // Yeni banka kartı ekle
  static Future<DebitCardModel> createDebitCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    double balance = 0.0,
  }) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Bank code'dan bank name'i al
      final bankName = AppConstants.getBankName(bankCode);

      // Kart numarası yoksa rastgele üret
      final finalLastFourDigits = lastFourDigits?.isNotEmpty == true 
          ? lastFourDigits!
          : DebitCardModel.generateRandomLastFourDigits();

      // Kart adı yoksa varsayılan kullan
      final finalCardName = cardName?.isNotEmpty == true 
          ? cardName!
          : 'Banka Kartı';

      final insertData = {
        'user_id': userId,
        'bank_name': bankName,
        'bank_code': bankCode,
        'card_name': finalCardName,
        'card_number_last_four': finalLastFourDigits,
        'current_balance': balance,
        'is_active': true,
      };

      final response = await _supabase
          .from('debit_cards')
          .insert(insertData)
          .select()
          .single();

      return DebitCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Banka kartı eklenirken hata oluştu: $e');
    }
  }

  // Banka kartı bakiyesini güncelle
  static Future<DebitCardModel> updateBalance({
    required String cardId,
    required double newBalance,
  }) async {
    try {
      final response = await _supabase
          .from('debit_cards')
          .update({'current_balance': newBalance})
          .eq('id', cardId)
          .select()
          .single();

      return DebitCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Bakiye güncellenirken hata oluştu: $e');
    }
  }

  // Banka kartını güncelle
  static Future<DebitCardModel> updateDebitCard({
    required String cardId,
    String? bankCode,
    String? cardName,
    String? lastFourDigits,
    double? balance,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (bankCode != null) updateData['bank_code'] = bankCode;
      if (cardName != null) updateData['card_name'] = cardName;
      if (lastFourDigits != null) updateData['card_number_last_four'] = lastFourDigits;
      if (balance != null) updateData['current_balance'] = balance;
      if (isActive != null) updateData['is_active'] = isActive;

      if (updateData.isEmpty) {
        throw Exception('Güncellenecek alan bulunamadı');
      }

      final response = await _supabase
          .from('debit_cards')
          .update(updateData)
          .eq('id', cardId)
          .select()
          .single();

      return DebitCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Banka kartı güncellenirken hata oluştu: $e');
    }
  }

  // Banka kartını sil (soft delete)
  static Future<void> deleteDebitCard(String cardId) async {
    try {
      await _supabase
          .from('debit_cards')
          .update({'is_active': false})
          .eq('id', cardId);
    } catch (e) {
      throw Exception('Banka kartı silinirken hata oluştu: $e');
    }
  }

  // Belirli bir banka kartını getir
  static Future<DebitCardModel?> getDebitCardById(String cardId) async {
    try {
      final response = await _supabase
          .from('debit_cards')
          .select()
          .eq('id', cardId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return DebitCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Banka kartı yüklenirken hata oluştu: $e');
    }
  }

  // Kullanıcının toplam banka kartı bakiyesi
  static Future<double> getTotalBalance() async {
    try {
      final cards = await getUserDebitCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.balance);
    } catch (e) {
      throw Exception('Toplam bakiye hesaplanırken hata oluştu: $e');
    }
  }

  // Banka kartı sayısını getir
  static Future<int> getDebitCardCount() async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('debit_cards')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Belirli bankaya ait kartları getir
  static Future<List<DebitCardModel>> getDebitCardsByBank(String bankCode) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _supabase
          .from('debit_cards')
          .select()
          .eq('user_id', userId)
          .eq('bank_code', bankCode)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DebitCardModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Banka kartları yüklenirken hata oluştu: $e');
    }
  }
} 