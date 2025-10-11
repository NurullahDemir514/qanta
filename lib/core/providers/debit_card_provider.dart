import 'package:flutter/foundation.dart';
import '../../shared/models/debit_card_model.dart';
import '../events/transaction_events.dart';
import 'dart:async';

class DebitCardProvider with ChangeNotifier {
  static DebitCardProvider? _instance;
  static DebitCardProvider get instance => _instance ??= DebitCardProvider._();

  DebitCardProvider._() {
    _initializeTransactionEventListeners();
  }

  List<DebitCardModel> _debitCards = [];
  bool _isLoading = false;
  String? _error;

  // Event subscription
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  // Getters
  List<DebitCardModel> get debitCards => _debitCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCards => _debitCards.isNotEmpty;
  int get cardCount => _debitCards.length;

  // Toplam bakiye
  double get totalBalance =>
      _debitCards.fold(0.0, (sum, card) => sum + card.balance);

  // Aktif kartlar
  List<DebitCardModel> get activeCards =>
      _debitCards.where((card) => card.isActive).toList();

  // Belirli bir kartı ID ile bul
  DebitCardModel? getCardById(String cardId) {
    try {
      return _debitCards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }

  // Belirli bankaya ait kartları getir
  List<DebitCardModel> getCardsByBank(String bankCode) {
    return _debitCards.where((card) => card.bankCode == bankCode).toList();
  }

  /// Transaction event listener'larını başlat
  void _initializeTransactionEventListeners() {
    _transactionEventSubscription = transactionEvents.stream.listen(
      _handleTransactionEvent,
    );
  }

  /// Transaction event'lerini handle et
  void _handleTransactionEvent(TransactionEvent event) {
    if (event is TransactionAdded ||
        event is TransactionDeleted ||
        event is TransactionUpdated) {
      // Banka kartı ile ilgili işlem varsa bakiyeyi güncelle
      if (mounted) {
        loadDebitCards();
      }
    }
  }

  bool get mounted => hasListeners;

  // Banka kartlarını yükle
  Future<void> loadDebitCards() async {
    _setLoading(true);
    _clearError();

    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _debitCards = [];
    } catch (e) {
      debugPrint('DebitCardProvider Error: Banka kartları yüklenemedi: $e');
      _setError('Banka kartları yüklenirken hata oluştu: $e');
      _debitCards = [];
    } finally {
      _setLoading(false);
    }
  }

  // Yeni banka kartı ekle
  Future<bool> addDebitCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    double balance = 0.0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Legacy functionality disabled
      throw Exception('Legacy debit card creation disabled - use v2 provider');
    } catch (e) {
      debugPrint('Banka kartı eklenirken hata: $e');
      _setError('Banka kartı eklenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Banka kartı bakiyesini güncelle
  Future<bool> updateCardBalance({
    required String cardId,
    required double newBalance,
  }) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      debugPrint('Bakiye güncellenirken hata: $e');
      _setError('Bakiye güncellenirken hata oluştu: $e');
      return false;
    }
  }

  // Banka kartını güncelle
  Future<bool> updateDebitCard({
    required String cardId,
    String? bankCode,
    String? cardName,
    String? lastFourDigits,
    double? balance,
    bool? isActive,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      debugPrint('Banka kartı güncellenirken hata: $e');
      _setError('Banka kartı güncellenirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Banka kartını sil
  Future<bool> deleteDebitCard(String cardId) async {
    _setLoading(true);
    _clearError();

    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      debugPrint('Banka kartı silinirken hata: $e');
      _setError('Banka kartı silinirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Kartları yenile
  Future<void> refreshCards() async {
    await loadDebitCards();
  }

  // Para harcama (bakiye azaltma)
  Future<bool> spendMoney({
    required String cardId,
    required double amount,
  }) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      _setError('Para harcama işlemi sırasında hata oluştu: $e');
      return false;
    }
  }

  // Para ekleme (bakiye artırma)
  Future<bool> addMoney({
    required String cardId,
    required double amount,
  }) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      _setError('Para ekleme işlemi sırasında hata oluştu: $e');
      return false;
    }
  }

  // Kartlar arası transfer
  Future<bool> transferBetweenCards({
    required String fromCardId,
    required String toCardId,
    required double amount,
  }) async {
    try {
      // Legacy functionality disabled
      return false;
    } catch (e) {
      _setError('Transfer sırasında hata oluştu: $e');
      return false;
    }
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

  // Provider'ı temizle
  void clear() {
    _debitCards.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    super.dispose();
  }
}
