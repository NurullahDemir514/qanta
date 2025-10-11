import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../shared/models/credit_card_model.dart';
import '../../shared/models/debit_card_model.dart';
import '../../shared/models/cash_account.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/models/insufficient_funds_exception.dart';
import '../services/credit_card_service.dart';
import '../services/debit_card_service.dart';
import '../services/cash_account_service.dart';
import '../services/transaction_service.dart';
import '../services/unified_cache_manager.dart';
import '../services/cache_strategy_config.dart';
import '../events/transaction_events.dart';
import 'dart:async';

class UnifiedCardProvider extends ChangeNotifier {
  // Kart listeleri
  List<CreditCardModel> _creditCards = [];
  List<DebitCardModel> _debitCards = [];
  CashAccount? _cashAccount;

  // İşlem listesi
  List<TransactionModel> _transactions = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingTransactions = false;

  // Error states
  String? _error;

  // Unified Cache System
  late UnifiedCacheManager _cacheManager;

  // Event subscription
  StreamSubscription<TransactionEvent>? _eventSubscription;

  // Cache keys
  static const String _cacheKeyCreditCards = 'cached_credit_cards';
  static const String _cacheKeyDebitCards = 'cached_debit_cards';
  static const String _cacheKeyCashAccount = 'cached_cash_account';
  static const String _cacheKeyTransactions = 'cached_transactions';
  static const String _cacheKeyLastUpdate = 'cache_last_update';

  // Getters
  List<CreditCardModel> get creditCards => _creditCards;
  List<DebitCardModel> get debitCards => _debitCards;
  CashAccount? get cashAccount => _cashAccount;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String? get error => _error;

  UnifiedCardProvider() {
    _initializeCacheManager();
    _initializeEventListeners();
  }

  /// Initialize cache manager
  Future<void> _initializeCacheManager() async {
    _cacheManager = UnifiedCacheManager.instance;
    await _cacheManager.initialize();
  }

  /// Event listener'ları başlat
  void _initializeEventListeners() {
    _eventSubscription = transactionEvents.stream.listen(
      _handleTransactionEvent,
    );
  }

  /// Transaction event'lerini handle et
  void _handleTransactionEvent(TransactionEvent event) {
    switch (event.runtimeType) {
      case TransactionAdded:
        _handleTransactionAdded(event as TransactionAdded);
        break;
      case TransactionDeleted:
        _handleTransactionDeleted(event as TransactionDeleted);
        break;
      case TransactionUpdated:
        _handleTransactionUpdated(event as TransactionUpdated);
        break;
      case BalanceUpdated:
        _handleBalanceUpdated(event as BalanceUpdated);
        break;
      case InstallmentTransactionAdded:
        _handleInstallmentTransactionAdded(
          event as InstallmentTransactionAdded,
        );
        break;
    }
  }

  /// Transaction ekleme event'ini handle et
  void _handleTransactionAdded(TransactionAdded event) {
    // Transaction listesinin başına ekle
    _transactions.insert(0, event.transaction);

    // Limit kontrolü (son 50 işlem)
    if (_transactions.length > 50) {
      _transactions = _transactions.take(50).toList();
    }

    notifyListeners();
  }

  /// Transaction silme event'ini handle et
  void _handleTransactionDeleted(TransactionDeleted event) {
    // Transaction'ı listeden kaldır
    _transactions.removeWhere((t) => t.id == event.transactionId);

    // ✅ BalanceUpdated event'leri bakiyeleri güncelleyecek, refresh'e gerek yok
    notifyListeners();
  }

  /// Transaction güncelleme event'ini handle et
  void _handleTransactionUpdated(TransactionUpdated event) {
    final index = _transactions.indexWhere(
      (t) => t.id == event.newTransaction.id,
    );
    if (index != -1) {
      _transactions[index] = event.newTransaction;
      notifyListeners();
    }
  }

  /// Bakiye güncelleme event'ini handle et
  void _handleBalanceUpdated(BalanceUpdated event) {
    switch (event.cardType) {
      case CardType.credit:
        _updateCreditCardBalance(event.cardId, event.changeAmount);
        break;
      case CardType.debit:
        _updateDebitCardBalance(event.cardId, event.changeAmount);
        break;
      case CardType.cash:
        _updateCashAccountBalance(event.changeAmount);
        break;
    }
    notifyListeners();
  }

  /// Taksitli işlem ekleme event'ini handle et
  void _handleInstallmentTransactionAdded(InstallmentTransactionAdded event) {
    // İlk taksit otomatik ödenir, bu transaction'ı listeye ekle
    // Bu event'ten sonra TransactionAdded event'i de gelecek

    // 🔥 YENİ: Taksitli işlem için bakiye güncellemesi
    // Toplam tutarı kredi kartı borcuna ekle (RPC zaten yapmış olabilir ama emin olmak için)
    _updateCreditCardBalance(event.creditCardId, event.totalAmount);
    notifyListeners();
  }

  // Bakiye güncelleme helper metodları
  void _updateCreditCardBalance(String cardId, double changeAmount) {
    final index = _creditCards.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      final currentCard = _creditCards[index];
      // Kredi kartı limit aşımına izin ver - sadece negatif borcu engelle
      final newTotalDebt = (currentCard.totalDebt + changeAmount).clamp(
        0.0,
        double.infinity,
      );

      // Yeni kullanılabilir limiti hesapla
      final newAvailableLimit = (currentCard.creditLimit - newTotalDebt).clamp(
        0.0,
        currentCard.creditLimit,
      );

      _creditCards[index] = currentCard.copyWith(
        totalDebt: newTotalDebt,
        availableLimit: newAvailableLimit,
      );

      // Limit aşımı uyarısı
      if (newTotalDebt > currentCard.creditLimit) {}
    }
  }

  void _updateDebitCardBalance(String cardId, double changeAmount) {
    final index = _debitCards.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      final currentCard = _debitCards[index];

      final newBalance = (currentCard.balance + changeAmount).clamp(
        0.0,
        double.infinity,
      );

      _debitCards[index] = currentCard.copyWith(balance: newBalance);
    } else {}
  }

  void _updateCashAccountBalance(double changeAmount) {
    if (_cashAccount != null) {
      final currentBalance = _cashAccount!.balance;
      final newBalance = (currentBalance + changeAmount).clamp(
        0.0,
        double.infinity,
      );
      _cashAccount = _cashAccount!.copyWith(balance: newBalance);
    }
  }

  // Tüm kartları birleşik liste olarak al
  List<Map<String, dynamic>> get allCards {
    final List<Map<String, dynamic>> cards = [];

    // Kredi kartları
    for (final card in _creditCards) {
      cards.add({
        'id': card.id,
        'type': CardType.credit,
        'name': card.cardName,
        'subtitle': card.bankName,
        'lastFourDigits': card.lastFourDigits,
        'balance': card.availableLimit,
        'totalDebt': card.totalDebt,
        'creditLimit': card.creditLimit,
        // IncomePaymentMethodSelector için gerekli alanlar
        'number': '**** **** **** ${card.lastFourDigits}',
        'expiry_date': '',
        'bank_name': card.bankName,
        'color': '#007AFF', // Kredi kartı için mavi
      });
    }

    // Banka kartları
    for (final card in _debitCards) {
      cards.add({
        'id': card.id,
        'type': CardType.debit,
        'name': card.cardName,
        'subtitle': card.bankName,
        'lastFourDigits': card.lastFourDigits,
        'balance': card.balance,
        // IncomePaymentMethodSelector için gerekli alanlar
        'number': '**** **** **** ${card.lastFourDigits}',
        'expiry_date': '',
        'bank_name': card.bankName,
        'color': '#34C759', // Banka kartı için yeşil
      });
    }

    // Nakit hesabı
    if (_cashAccount != null) {
      cards.add({
        'id': _cashAccount!.id,
        'type': CardType.cash,
        'name': _cashAccount!.name,
        'subtitle': 'Qanta',
        'lastFourDigits': '',
        'balance': _cashAccount!.balance,
        // IncomePaymentMethodSelector için gerekli alanlar
        'number': 'Nakit',
        'expiry_date': '',
        'bank_name': 'Qanta',
        'color': '#FF9500', // Nakit için turuncu
      });
    }

    return cards;
  }

  // Tüm verileri yükle - OPTIMIZE EDİLDİ
  Future<void> loadAllData() async {
    _setLoading(true);
    _setError(null);

    final stopwatch = Stopwatch()..start();

    try {
      // ⚡ PHASE 1: Kritik veriler (kartlar) - Paralel yükleme
      final cardLoadingFutures = [
        loadCreditCards(),
        loadDebitCards(),
        loadCashAccount(),
      ];

      // ⚡ PHASE 2: İşlemler - Kartlarla paralel başlat
      final transactionFuture = loadRecentTransactions(
        limit: 20,
      ); // Daha az işlem

      // Tüm işlemleri paralel çalıştır
      await Future.wait([...cardLoadingFutures, transactionFuture]);

      // Verileri cache'e kaydet
      await saveToCache();

      stopwatch.stop();
    } catch (e) {
      stopwatch.stop();
      _setError('Veriler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Hızlı başlangıç için minimal veri yükle
  Future<void> loadEssentialData() async {
    _setLoading(true);
    _setError(null);

    final stopwatch = Stopwatch()..start();

    try {
      // Sadece kartları yükle, işlemleri sonra lazy load et
      await Future.wait([
        loadCreditCards(),
        loadDebitCards(),
        loadCashAccount(),
      ]);

      stopwatch.stop();

      // İşlemleri arka planda yükle
      _loadTransactionsInBackground();
    } catch (e) {
      stopwatch.stop();
      _setError('Temel veriler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Arka planda işlemleri yükle
  Future<void> _loadTransactionsInBackground() async {
    try {
      await loadRecentTransactions(limit: 50);
    } catch (e) {}
  }

  // Kredi kartlarını yükle
  Future<void> loadCreditCards() async {
    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _creditCards = [];
    } catch (e) {
      debugPrint('Kredi kartları yüklenirken hata: $e');
      _creditCards = [];
    }
  }

  // Banka kartlarını yükle
  Future<void> loadDebitCards() async {
    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _debitCards = [];
    } catch (e) {
      debugPrint('Banka kartları yüklenirken hata: $e');
      _debitCards = [];
    }
  }

  // Nakit hesabını yükle
  Future<void> loadCashAccount() async {
    try {
      // Legacy table doesn't exist anymore, gracefully handle
      _cashAccount = null;
    } catch (e) {
      debugPrint('Nakit hesabı yüklenirken hata: $e');
      _cashAccount = null;
    }
  }

  // Son işlemleri yükle
  Future<void> loadRecentTransactions({int limit = 50}) async {
    _setLoadingTransactions(true);

    try {
      _transactions = await TransactionService.getUserTransactions(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _setError('İşlemler yüklenirken hata oluştu: $e');
    } finally {
      _setLoadingTransactions(false);
    }
  }

  // Belirli bir kartın işlemlerini yükle
  Future<List<TransactionModel>> getCardTransactions(
    String cardId,
    CardType cardType,
  ) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'TransactionService.getCardTransactions() - Firebase implementation needed',
      );
      return <TransactionModel>[];
    } catch (e) {
      throw Exception('Kart işlemleri yüklenirken hata oluştu: $e');
    }
  }

  // Yeni işlem ekle - Entegre sistem kullanır
  Future<void> addTransaction({
    required TransactionType type,
    required double amount,
    required String description,
    String? category,
    String? cardId,
    CardType? cardType,
    String? targetCardId,
    CardType? targetCardType,
    int installmentCount = 1,
    String? merchantName,
    String? location,
    String? notes,
    DateTime? transactionDate,
  }) async {
    try {
      // Kart ID'lerini türlerine göre ayır
      String? creditCardId;
      String? debitCardId;
      String? cashAccountId;
      String? targetCreditCardId;
      String? targetDebitCardId;
      String? targetCashAccountId;

      // Kaynak kart
      if (cardId != null && cardType != null) {
        switch (cardType) {
          case CardType.credit:
            creditCardId = cardId;
            break;
          case CardType.debit:
            debitCardId = cardId;
            break;
          case CardType.cash:
            cashAccountId = cardId;
            break;
        }
      }

      // Hedef kart (transfer için)
      if (targetCardId != null && targetCardType != null) {
        switch (targetCardType) {
          case CardType.credit:
            targetCreditCardId = targetCardId;
            break;
          case CardType.debit:
            targetDebitCardId = targetCardId;
            break;
          case CardType.cash:
            targetCashAccountId = targetCardId;
            break;
        }
      }

      TransactionModel? createdTransaction;

      // 🔄 ENTEGRASYON: Taksit kontrolü ile uygun servisi kullan
      if (installmentCount > 1 &&
          creditCardId != null &&
          type == TransactionType.expense) {
        // Yeni taksit sistemi kullan
        // TODO: Implement with Firebase
        debugPrint(
          'InstallmentService.createInstallmentTransaction() - Firebase implementation needed',
        );
        final installmentTransactionId =
            'temp_${DateTime.now().millisecondsSinceEpoch}';

        // Taksitli işlem event'i emit et
        transactionEvents.emitInstallmentTransactionAdded(
          installmentTransactionId: installmentTransactionId,
          creditCardId: creditCardId,
          totalAmount: amount,
          installmentCount: installmentCount,
          description: description,
        );

        // 🔥 YENİ: İlk taksit için normal transaction da oluştur
        // Bu sayede işlem listesinde hemen görünür
        final monthlyAmount = amount / installmentCount;
        // TODO: Implement with Firebase
        debugPrint(
          'TransactionService.createTransaction() - Firebase implementation needed',
        );
        final firstInstallmentTransaction =
            'temp_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Mevcut sistem kullan
        // TODO: Implement with Firebase
        debugPrint(
          'TransactionService.createTransaction() - Firebase implementation needed',
        );
        createdTransaction = null; // Placeholder

        // ✅ Event emit etmeye gerek yok - TransactionService.createTransaction() zaten ediyor
      }

      // ✅ ARTIK loadAllData() çağırmıyoruz - event system otomatik günceller
    } on InsufficientFundsException {
      // InsufficientFundsException'ı rethrow et ki UI katmanında dialog gösterilebilsin
      rethrow;
    } catch (e) {
      // InsufficientFundsException'ı wrap etme
      if (e is InsufficientFundsException) {
        rethrow;
      }
      throw Exception('İşlem eklenirken hata oluştu: $e');
    }
  }

  // Kredi kartı ekle
  Future<void> addCreditCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    required double creditLimit,
    required int statementDate,
    required int dueDate,
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'CreditCardService.addCreditCard() - Firebase implementation needed',
      );
      // await CreditCardService.addCreditCard(...);

      await loadCreditCards();
    } catch (e) {
      debugPrint('Kredi kartı eklenirken hata: $e');
      throw Exception('Kredi kartı eklenirken hata oluştu: $e');
    }
  }

  // Banka kartı ekle
  Future<void> addDebitCard({
    required String bankCode,
    String? cardName,
    String? lastFourDigits,
    double balance = 0.0,
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'DebitCardService.createDebitCard() - Firebase implementation needed',
      );
      // await DebitCardService.createDebitCard(...);

      await loadDebitCards();
    } catch (e) {
      debugPrint('Banka kartı eklenirken hata: $e');
      throw Exception('Banka kartı eklenirken hata oluştu: $e');
    }
  }

  // Nakit hesabı oluştur
  Future<void> createCashAccount({
    String name = 'Nakit Param',
    double balance = 0.0,
    String currency = 'TRY',
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'CashAccountService.createCashAccount() - Firebase implementation needed',
      );
      // await CashAccountService.createCashAccount(...);

      await loadCashAccount();
    } catch (e) {
      throw Exception('Nakit hesabı oluşturulurken hata oluştu: $e');
    }
  }

  // Kart sil
  Future<void> deleteCard(String cardId, CardType cardType) async {
    try {
      switch (cardType) {
        case CardType.credit:
          await CreditCardService.deleteCreditCard(cardId);
          await loadCreditCards();
          break;
        case CardType.debit:
          await DebitCardService.deleteDebitCard(cardId);
          await loadDebitCards();
          break;
        case CardType.cash:
          await CashAccountService.deleteCashAccount(cardId);
          await loadCashAccount();
          break;
      }
    } catch (e) {
      debugPrint('Kart silinirken hata: $e');
      throw Exception('Kart silinirken hata oluştu: $e');
    }
  }

  // İşlem sil - Event sistemi ile
  Future<void> deleteTransaction(String transactionId) async {
    try {
      // Silme işlemini gerçekleştir - TransactionService zaten event emit eder
      await TransactionService.deleteTransaction(transactionId);

      // ✅ Event emit etmeye gerek yok - TransactionService.deleteTransaction() zaten ediyor
      // ✅ loadAllData() çağırmıyoruz - event system otomatik günceller
    } catch (e) {
      throw Exception('İşlem silinirken hata oluştu: $e');
    }
  }

  // İşlem istatistikleri al
  Future<Map<String, double>> getTransactionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'TransactionService.getTransactionStats() - Firebase implementation needed',
      );
      return <String, double>{};
    } catch (e) {
      throw Exception('İstatistikler alınırken hata oluştu: $e');
    }
  }

  // Kategori bazlı harcamalar
  Future<Map<String, double>> getCategoryExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint(
        'TransactionService.getCategoryExpenses() - Firebase implementation needed',
      );
      return <String, double>{};
    } catch (e) {
      debugPrint('Kategori harcamaları alınırken hata: $e');
      throw Exception('Kategori harcamaları alınırken hata oluştu: $e');
    }
  }

  // Son işlemleri getir
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      return await TransactionService.getUserTransactions(limit: limit);
    } catch (e) {
      throw Exception('Son işlemler alınırken hata oluştu: $e');
    }
  }

  Future<List<dynamic>> getAllCards() async {
    final List<dynamic> cards = [];

    // Kredi kartları
    for (final card in _creditCards) {
      cards.add(card);
    }

    // Banka kartları
    for (final card in _debitCards) {
      cards.add(card);
    }

    // Nakit hesabı
    if (_cashAccount != null) {
      cards.add(_cashAccount!);
    }

    return cards;
  }

  // Belirli bir kartı ID ile bul
  Map<String, dynamic>? findCardById(String cardId) {
    return allCards.firstWhere(
      (card) => card['id'] == cardId,
      orElse: () => {},
    );
  }

  // Kart türüne göre kartları filtrele
  List<Map<String, dynamic>> getCardsByType(CardType type) {
    return allCards.where((card) => card['type'] == type).toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingTransactions(bool loading) {
    _isLoadingTransactions = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Provider'ı temizle
  void clear() {
    _creditCards.clear();
    _debitCards.clear();
    _cashAccount = null;
    _transactions.clear();
    _isLoading = false;
    _isLoadingTransactions = false;
    _error = null;
    notifyListeners();
  }

  // Kullanıcı çıkış yaptığında çağır
  void signOut() {
    clear();
  }

  // Toplam bakiye hesapla
  double get totalBalance {
    double total = 0.0;

    // Banka kartları bakiyesi (pozitif)
    for (final card in _debitCards) {
      total += card.balance;
    }

    // Nakit hesabı bakiyesi (pozitif)
    if (_cashAccount != null) {
      total += _cashAccount!.balance;
    }

    // Kredi kartları borcu (negatif)
    for (final card in _creditCards) {
      total -= card.totalDebt;
    }

    return total;
  }

  // Bu ay gelir hesapla
  double get thisMonthIncome {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income &&
              transaction.transactionDate.isAfter(startOfMonth) &&
              transaction.transactionDate.isBefore(endOfMonth),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Bu ay gider hesapla
  double get thisMonthExpense {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.transactionDate.isAfter(startOfMonth) &&
              transaction.transactionDate.isBefore(endOfMonth),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Geçen ay ile karşılaştırma yüzdesi hesapla
  double get balanceChangePercentage {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    // Bu ay net değişim (gelir - gider)
    final thisMonthNet = thisMonthIncome - thisMonthExpense;

    // Geçen ay net değişim
    final lastMonthIncome = _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income &&
              transaction.transactionDate.isAfter(lastMonthStart) &&
              transaction.transactionDate.isBefore(lastMonthEnd),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final lastMonthExpense = _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.transactionDate.isAfter(lastMonthStart) &&
              transaction.transactionDate.isBefore(lastMonthEnd),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final lastMonthNet = lastMonthIncome - lastMonthExpense;

    // Yüzde hesapla
    if (lastMonthNet == 0) {
      return thisMonthNet > 0 ? 100.0 : 0.0;
    }

    return ((thisMonthNet - lastMonthNet) / lastMonthNet.abs()) * 100;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // 💾 CACHE METHODS

  // Cache'den verileri yükle (unified cache system)
  Future<bool> loadFromCache() async {
    try {
      // Credit cards cache
      final cachedCreditCards = await _cacheManager.get<List<CreditCardModel>>(
        CacheStrategyConfig.getCacheKeyForType('credit_cards'),
        type: CacheStrategyConfig.getPolicy('credit_cards').type,
      );
      
      if (cachedCreditCards != null) {
        _creditCards = cachedCreditCards;
      }

      // Debit cards cache
      final cachedDebitCards = await _cacheManager.get<List<DebitCardModel>>(
        CacheStrategyConfig.getCacheKeyForType('debit_cards'),
        type: CacheStrategyConfig.getPolicy('debit_cards').type,
      );
      
      if (cachedDebitCards != null) {
        _debitCards = cachedDebitCards;
      }

      // Cash account cache
      final cachedCashAccount = await _cacheManager.get<CashAccount>(
        CacheStrategyConfig.getCacheKeyForType('cash_account'),
        type: CacheStrategyConfig.getPolicy('cash_account').type,
      );
      
      if (cachedCashAccount != null) {
        _cashAccount = cachedCashAccount;
      }

      // Transactions cache
      final cachedTransactions = await _cacheManager.get<List<TransactionModel>>(
        CacheStrategyConfig.getCacheKeyForType('card_transactions'),
        type: CacheStrategyConfig.getPolicy('card_transactions').type,
      );
      
      if (cachedTransactions != null) {
        _transactions = cachedTransactions;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error loading from unified cache: $e');
      return false;
    }
  }

  // Verileri unified cache'e kaydet
  Future<void> saveToCache() async {
    try {
      // Credit cards cache
      await _cacheManager.set(
        CacheStrategyConfig.getCacheKeyForType('credit_cards'),
        _creditCards,
        ttl: CacheStrategyConfig.getPolicy('credit_cards').ttl,
        type: CacheStrategyConfig.getPolicy('credit_cards').type,
        compress: CacheStrategyConfig.getPolicy('credit_cards').compress,
      );

      // Debit cards cache
      await _cacheManager.set(
        CacheStrategyConfig.getCacheKeyForType('debit_cards'),
        _debitCards,
        ttl: CacheStrategyConfig.getPolicy('debit_cards').ttl,
        type: CacheStrategyConfig.getPolicy('debit_cards').type,
        compress: CacheStrategyConfig.getPolicy('debit_cards').compress,
      );

      // Cash account cache
      if (_cashAccount != null) {
        await _cacheManager.set(
          CacheStrategyConfig.getCacheKeyForType('cash_account'),
          _cashAccount!,
          ttl: CacheStrategyConfig.getPolicy('cash_account').ttl,
          type: CacheStrategyConfig.getPolicy('cash_account').type,
          compress: CacheStrategyConfig.getPolicy('cash_account').compress,
        );
      }

      // Transactions cache
      await _cacheManager.set(
        CacheStrategyConfig.getCacheKeyForType('card_transactions'),
        _transactions,
        ttl: CacheStrategyConfig.getPolicy('card_transactions').ttl,
        type: CacheStrategyConfig.getPolicy('card_transactions').type,
        compress: CacheStrategyConfig.getPolicy('card_transactions').compress,
      );

      debugPrint('✅ Card data saved to unified cache system');
    } catch (e) {
      debugPrint('❌ Error saving card data to cache: $e');
    }
  }

  // Cache'i temizle
  Future<void> clearCache() async {
    try {
      await _cacheManager.clearAll();
      debugPrint('✅ Card cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing card cache: $e');
    }
  }

  // Hızlı başlangıç: Cache + Background refresh
  Future<void> loadWithCacheStrategy() async {
    final stopwatch = Stopwatch()..start();

    // 1. Önce cache'den yükle (instant)
    final cacheLoaded = await loadFromCache();

    if (cacheLoaded) {
      stopwatch.stop();

      // 2. Arka planda fresh data yükle
      _refreshDataInBackground();
    } else {
      // 3. Cache yoksa normal yükleme
      await loadEssentialData();
    }
  }

  // Arka planda fresh data yükle
  Future<void> _refreshDataInBackground() async {
    try {
      // Fresh data yükle
      await Future.wait([
        loadCreditCards(),
        loadDebitCards(),
        loadCashAccount(),
      ]);

      await loadRecentTransactions(limit: 50);

      // Yeni veriyi cache'e kaydet
      await saveToCache();
    } catch (e) {}
  }
}
