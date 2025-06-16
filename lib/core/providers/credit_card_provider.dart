import 'package:flutter/foundation.dart';
import '../../shared/models/credit_card_model.dart';
import '../../shared/models/transaction_model.dart';
import '../services/credit_card_service.dart';
import '../events/card_events.dart';
import '../events/transaction_events.dart';
import 'dart:async';

class CreditCardProvider extends ChangeNotifier {
  static CreditCardProvider? _instance;
  static CreditCardProvider get instance => _instance ??= CreditCardProvider._();
  
  CreditCardProvider._() {
    _initializeTransactionEventListeners();
  }

  List<CreditCardModel> _creditCards = [];
  bool _isLoading = false;
  String? _error;
  
  // Event subscription
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  // Getters
  List<CreditCardModel> get creditCards => _creditCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCards => _creditCards.isNotEmpty;
  int get cardCount => _creditCards.length;

  // Toplam borç
  double get totalDebt => _creditCards.fold(0.0, (sum, card) => sum + card.totalDebt);

  // Toplam limit
  double get totalLimit => _creditCards.fold(0.0, (sum, card) => sum + card.creditLimit);

  // Toplam kullanılabilir limit
  double get totalAvailableLimit => _creditCards.fold(0.0, (sum, card) => sum + card.availableLimit);

  // Aktif kartlar
  List<CreditCardModel> get activeCards => _creditCards.where((card) => card.isActive).toList();

  // Yaklaşan ödeme tarihleri
  List<CreditCardModel> get upcomingPayments {
    final now = DateTime.now();
    return _creditCards.where((card) {
      final daysUntilDue = card.daysUntilDue;
      return daysUntilDue >= 0 && daysUntilDue <= 30;
    }).toList()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
  }

  // Kredi kartlarını yükle
  Future<void> loadCreditCards() async {
    _setLoading(true);
    _setError(null);

    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _creditCards = [];
      debugPrint('💳 Legacy credit card provider: No data (using v2 provider)');
    } catch (e) {
      debugPrint('CreditCardProvider Error: Kredi kartları yüklenemedi: $e');
      _setError(e.toString());
      _creditCards = [];
    } finally {
      _setLoading(false);
    }
  }

  // Yeni kredi kartı ekle
  Future<bool> addCreditCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    required double creditLimit,
    double? availableLimit,
    double? totalDebt,
    required int statementDate,
    required int dueDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy credit card creation disabled - use v2 provider');
      throw Exception('Legacy credit card creation disabled - use v2 provider');
    } catch (e) {
      debugPrint('Kredi kartı eklenirken hata: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Kredi kartını güncelle
  Future<bool> updateCreditCard({
    required String cardId,
    String? cardName,
    double? creditLimit,
    double? totalDebt,
    int? statementDate,
    int? dueDate,
    bool? isActive,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy credit card update disabled - use v2 provider');
      return false;
    } catch (e) {
      debugPrint('Kredi kartı güncellenirken hata: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Kredi kartını sil
  Future<bool> deleteCreditCard(String cardId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy credit card deletion disabled - use v2 provider');
      return false;
    } catch (e) {
      debugPrint('Kredi kartı silinirken hata: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Belirli bir kredi kartını getir
  CreditCardModel? getCreditCard(String cardId) {
    try {
      return _creditCards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }

  // Kredi kartı harcaması yap
  Future<bool> makePayment({
    required String cardId,
    required double amount,
  }) async {
    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy payment disabled - use v2 provider');
      return false;
    } catch (e) {
      debugPrint('Ödeme işlemi sırasında hata: $e');
      _setError(e.toString());
      return false;
    }
  }

  // Kredi kartı ödemesi yap (borç azaltma)
  Future<bool> payDebt({
    required String cardId,
    required double amount,
  }) async {
    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy debt payment disabled - use v2 provider');
      return false;
    } catch (e) {
      debugPrint('Borç ödeme işlemi sırasında hata: $e');
      _setError(e.toString());
      return false;
    }
  }

  // Banka koduna göre kredi kartlarını getir
  List<CreditCardModel> getCreditCardsByBank(String bankCode) {
    return _creditCards.where((card) => card.bankCode == bankCode).toList();
  }

  // Kredi kartı bakiyesini güncelle (hızlı güncelleme için)
  Future<bool> updateCardBalance({
    required String cardId,
    required double newTotalDebt,
  }) async {
    try {
      // Legacy functionality disabled
      debugPrint('💳 Legacy balance update disabled - use v2 provider');
      return false;
    } catch (e) {
      debugPrint('Bakiye güncellenirken hata: $e');
      _setError(e.toString());
      return false;
    }
  }

  // Kartları yenile (pull-to-refresh için)
  Future<void> refreshCreditCards() async {
    await loadCreditCards();
  }

  // Hata durumunda yeniden dene
  Future<void> retry() async {
    await loadCreditCards();
  }

  // Hata temizle
  void clearError() {
    _setError(null);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Provider'ı temizle
  void clear() {
    _creditCards.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    super.dispose();
  }

  /// Transaction event listener'larını başlat
  void _initializeTransactionEventListeners() {
    _transactionEventSubscription = transactionEvents.stream.listen(_handleTransactionEvent);
  }

  /// Transaction event'lerini handle et
  void _handleTransactionEvent(TransactionEvent event) {
    if (event is TransactionAdded || event is TransactionDeleted || event is TransactionUpdated) {
      // Kredi kartı ile ilgili işlem varsa bakiyeyi güncelle
      if (mounted) {
        loadCreditCards();
      }
    }
  }

  bool get mounted => hasListeners;
} 