import 'package:flutter/foundation.dart';
import '../../shared/models/cash_account.dart';
import '../../shared/models/transaction_model.dart';
import '../services/cash_account_service.dart';
import '../events/card_events.dart';
import '../events/transaction_events.dart';
import 'dart:async';

class CashAccountProvider extends ChangeNotifier {
  static CashAccountProvider? _instance;
  static CashAccountProvider get instance => _instance ??= CashAccountProvider._();
  
  CashAccountProvider._() {
    _initializeTransactionEventListeners();
  }

  CashAccount? _cashAccount;
  bool _isLoading = false;
  String? _error;
  
  // Event subscription
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  // Getters
  CashAccount? get cashAccount => _cashAccount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get balance => _cashAccount?.balance ?? 0.0;
  String get accountName => _cashAccount?.name ?? 'Nakit Param';
  bool get hasAccount => _cashAccount != null;

  /// Transaction event listener'larını başlat
  void _initializeTransactionEventListeners() {
    _transactionEventSubscription = transactionEvents.stream.listen(_handleTransactionEvent);
  }

  /// Transaction event'lerini handle et
  void _handleTransactionEvent(TransactionEvent event) {
    if (event is TransactionAdded || event is TransactionDeleted || event is TransactionUpdated) {
      // Nakit hesabı ile ilgili işlem varsa bakiyeyi güncelle
      // Bu basit bir yaklaşım - gerçek uygulamada daha detaylı kontrol yapılabilir
      if (mounted) {
        loadCashAccount();
      }
    }
  }

  bool get mounted => hasListeners;

  /// Nakit hesabını yükle
  Future<void> loadCashAccount() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _cashAccount = null;
    } catch (e) {
      debugPrint('CashAccountProvider Error: Nakit hesabı yüklenemedi: $e');
      _setError('Nakit hesabı yüklenemedi: $e');
      _cashAccount = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Nakit hesabı oluştur
  Future<void> createCashAccount({
    String name = 'Nakit Param',
    double balance = 0.0,
    String currency = 'TRY',
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Legacy functionality disabled - use v2 provider instead
      throw Exception('Legacy cash account creation disabled - use v2 provider');
    } catch (e) {
      _setError('Nakit hesabı oluşturulurken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Bakiye güncelle
  Future<void> updateBalance(double newBalance) async {
    if (_cashAccount == null) return;
    
    try {
      // Legacy functionality disabled
    } catch (e) {
      debugPrint('Bakiye güncellenirken hata: $e');
      _setError('Bakiye güncellenirken hata oluştu: $e');
    }
  }

  /// Para ekle
  Future<void> addMoney(double amount, {String? description}) async {
    if (_cashAccount == null) return;
    
    try {
      // Legacy functionality disabled
    } catch (e) {
      debugPrint('Para eklenirken hata: $e');
      _setError('Para eklenirken hata oluştu: $e');
    }
  }

  /// Para çıkar
  Future<void> withdrawMoney(double amount, {String? description}) async {
    if (_cashAccount == null) return;
    
    try {
      // Legacy functionality disabled
    } catch (e) {
      debugPrint('Para çıkarılırken hata: $e');
      _setError('Para çıkarılırken hata oluştu: $e');
    }
  }

  /// Nakit hesabını sil
  Future<void> deleteCashAccount() async {
    if (_cashAccount == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Legacy functionality disabled
    } catch (e) {
      debugPrint('Nakit hesabı silinirken hata: $e');
      _setError('Nakit hesabı silinirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Provider'ı temizle
  void clear() {
    _cashAccount = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Kullanıcı çıkış yaptığında çağır
  void signOut() {
    clear();
    _transactionEventSubscription?.cancel();
    _transactionEventSubscription = null;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    super.dispose();
  }

  /// Bakiye güncelle (legacy compatibility)
  Future<bool> updateCashBalance(double difference, {String? description}) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      debugPrint('Bakiye güncellenirken hata: $e');
      _setError('Bakiye güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Yeniden dene (legacy compatibility)
  Future<void> retry() async {
    await loadCashAccount();
  }

  /// Hesap adını güncelle (legacy compatibility)
  Future<bool> updateAccountName(String newName) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      debugPrint('Hesap adı güncellenirken hata: $e');
      _setError('Hesap adı güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Nakit hesabı oluştur veya getir (legacy compatibility)
  Future<void> initializeCashAccount({
    String? name,
    double? initialBalance,
    String? currency,
  }) async {
    await createCashAccount(
      name: name ?? 'Nakit Param',
      balance: initialBalance ?? 0.0,
      currency: currency ?? 'TRY',
    );
  }

  /// Hesabı sıfırla (legacy compatibility)
  void clearAccount() {
    clear();
  }
} 