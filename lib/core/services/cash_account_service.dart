import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/cash_account.dart';
import 'supabase_service.dart';

class CashAccountService {
  static final _supabase = SupabaseService.instance.client;
  static const String _tableName = 'cash_account';

  // Kullanıcının nakit hesabını getir (yoksa null)
  static Future<CashAccount?> getUserCashAccount() async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Tek kayıt olmalı

      if (response == null) return null;
      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı yüklenirken hata oluştu: $e');
    }
  }

  // Nakit hesabı oluştur (kullanıcı başına 1 adet)
  static Future<CashAccount> createCashAccount({
    required String name,
    required double balance,
    String? currency,
  }) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Önce mevcut hesap var mı kontrol et
      final existing = await getUserCashAccount();
      if (existing != null) {
        throw Exception('Kullanıcının zaten bir nakit hesabı var');
      }

      final insertData = {
        'user_id': userId,
        'name': name,
        'balance': balance,
        'currency': currency ?? 'TRY',
      };

      final response = await _supabase
          .from(_tableName)
          .insert(insertData)
          .select()
          .single();

      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı oluşturulurken hata oluştu: $e');
    }
  }

  // Nakit hesabı oluştur veya getir (yoksa oluştur)
  static Future<CashAccount> getOrCreateCashAccount({
    String? name,
    double? initialBalance,
    String? currency,
  }) async {
    try {
      // Önce mevcut hesabı kontrol et
      final existing = await getUserCashAccount();
      if (existing != null) return existing;

      // Yoksa oluştur
      return await createCashAccount(
        name: name ?? 'Nakit Param',
        balance: initialBalance ?? 0.0,
        currency: currency ?? 'TRY',
      );
    } catch (e) {
      throw Exception('Nakit hesabı alınırken/oluşturulurken hata oluştu: $e');
    }
  }

  // Nakit hesabı bakiyesini güncelle
  static Future<CashAccount> updateBalance(double newBalance) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final response = await _supabase
          .from(_tableName)
          .update({'balance': newBalance})
          .eq('user_id', userId)
          .select()
          .single();

      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı bakiyesi güncellenirken hata oluştu: $e');
    }
  }

  // Nakit hesabı adını güncelle
  static Future<CashAccount> updateName(String newName) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final response = await _supabase
          .from(_tableName)
          .update({'name': newName})
          .eq('user_id', userId)
          .select()
          .single();

      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı adı güncellenirken hata oluştu: $e');
    }
  }

  // Nakit hesabını güncelle
  static Future<CashAccount> updateCashAccount({
    String? name,
    double? balance,
    String? currency,
  }) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (balance != null) updateData['balance'] = balance;
      if (currency != null) updateData['currency'] = currency;

      if (updateData.isEmpty) {
        throw Exception('Güncellenecek alan bulunamadı');
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı güncellenirken hata oluştu: $e');
    }
  }

  // Nakit ekleme/çıkarma
  static Future<CashAccount> addCash(double amount, {String? description}) async {
    try {
      // Mevcut hesabı getir
      final currentAccount = await getUserCashAccount();
      if (currentAccount == null) {
        throw Exception('Nakit hesabı bulunamadı. Önce bir hesap oluşturun.');
      }

      // Yeni bakiyeyi hesapla
      final newBalance = currentAccount.balance + amount;
      
      // Negatif bakiye kontrolü
      if (newBalance < 0) {
        throw Exception('Yetersiz nakit bakiyesi');
      }
      
      // Bakiyeyi güncelle
      return await updateBalance(newBalance);
    } catch (e) {
      throw Exception('Nakit eklenirken hata oluştu: $e');
    }
  }

  // Nakit çıkarma (harcama)
  static Future<CashAccount> spendCash(double amount, {String? description}) async {
    return await addCash(-amount, description: description);
  }

  // Nakit hesabını sil
  static Future<void> deleteCashAccount(String accountId) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', accountId)
          .eq('user_id', userId); // Güvenlik için user_id kontrolü
    } catch (e) {
      throw Exception('Nakit hesabı silinirken hata oluştu: $e');
    }
  }

  // Belirli bir nakit hesabını getir
  static Future<CashAccount?> getCashAccountById(String accountId) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', accountId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return CashAccount.fromJson(response);
    } catch (e) {
      throw Exception('Nakit hesabı yüklenirken hata oluştu: $e');
    }
  }
} 