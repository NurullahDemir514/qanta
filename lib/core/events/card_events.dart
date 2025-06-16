import 'dart:async';
import '../../shared/models/credit_card_model.dart';
import '../../shared/models/debit_card_model.dart';

/// Card olayları için base class
abstract class CardEvent {
  final DateTime timestamp;
  
  CardEvent() : timestamp = DateTime.now();
}

// MARK: - Credit Card Events

/// Kredi kartı eklendiğinde tetiklenen event
class CreditCardAdded extends CardEvent {
  final CreditCardModel creditCard;
  
  CreditCardAdded(this.creditCard);
  
  @override
  String toString() => 'CreditCardAdded(${creditCard.cardName})';
}

/// Kredi kartı güncellendiğinde tetiklenen event
class CreditCardUpdated extends CardEvent {
  final CreditCardModel oldCard;
  final CreditCardModel newCard;
  
  CreditCardUpdated({
    required this.oldCard,
    required this.newCard,
  });
  
  @override
  String toString() => 'CreditCardUpdated(${newCard.cardName})';
}

/// Kredi kartı silindiğinde tetiklenen event
class CreditCardDeleted extends CardEvent {
  final String cardId;
  final CreditCardModel? deletedCard; // Rollback için
  
  CreditCardDeleted({
    required this.cardId,
    this.deletedCard,
  });
  
  @override
  String toString() => 'CreditCardDeleted($cardId)';
}

/// Kredi kartı bakiyesi güncellendiğinde tetiklenen event
class CreditCardBalanceUpdated extends CardEvent {
  final String cardId;
  final double oldDebt;
  final double newDebt;
  final double oldAvailableLimit;
  final double newAvailableLimit;
  final double changeAmount;
  
  CreditCardBalanceUpdated({
    required this.cardId,
    required this.oldDebt,
    required this.newDebt,
    required this.oldAvailableLimit,
    required this.newAvailableLimit,
    required this.changeAmount,
  });
  
  @override
  String toString() => 'CreditCardBalanceUpdated($cardId: debt $oldDebt → $newDebt)';
}

// MARK: - Debit Card Events

/// Banka kartı eklendiğinde tetiklenen event
class DebitCardAdded extends CardEvent {
  final DebitCardModel debitCard;
  
  DebitCardAdded(this.debitCard);
  
  @override
  String toString() => 'DebitCardAdded(${debitCard.cardName})';
}

/// Banka kartı güncellendiğinde tetiklenen event
class DebitCardUpdated extends CardEvent {
  final DebitCardModel oldCard;
  final DebitCardModel newCard;
  
  DebitCardUpdated({
    required this.oldCard,
    required this.newCard,
  });
  
  @override
  String toString() => 'DebitCardUpdated(${newCard.cardName})';
}

/// Banka kartı silindiğinde tetiklenen event
class DebitCardDeleted extends CardEvent {
  final String cardId;
  final DebitCardModel? deletedCard; // Rollback için
  
  DebitCardDeleted({
    required this.cardId,
    this.deletedCard,
  });
  
  @override
  String toString() => 'DebitCardDeleted($cardId)';
}

/// Banka kartı bakiyesi güncellendiğinde tetiklenen event
class DebitCardBalanceUpdated extends CardEvent {
  final String cardId;
  final double oldBalance;
  final double newBalance;
  final double changeAmount;
  
  DebitCardBalanceUpdated({
    required this.cardId,
    required this.oldBalance,
    required this.newBalance,
    required this.changeAmount,
  });
  
  @override
  String toString() => 'DebitCardBalanceUpdated($cardId: $oldBalance → $newBalance)';
}

// MARK: - Cash Account Events

/// Nakit hesabı güncellendiğinde tetiklenen event
class CashAccountUpdated extends CardEvent {
  final String accountId;
  final double oldBalance;
  final double newBalance;
  final double changeAmount;
  
  CashAccountUpdated({
    required this.accountId,
    required this.oldBalance,
    required this.newBalance,
    required this.changeAmount,
  });
  
  @override
  String toString() => 'CashAccountUpdated($accountId: $oldBalance → $newBalance)';
}

// MARK: - Card Event Manager

/// Merkezi Card Event Manager
class CardEventManager {
  static final CardEventManager _instance = CardEventManager._internal();
  factory CardEventManager() => _instance;
  CardEventManager._internal();
  
  // Event stream controller
  final StreamController<CardEvent> _controller = 
      StreamController<CardEvent>.broadcast();
  
  // Public stream
  Stream<CardEvent> get stream => _controller.stream;
  
  // Event history (debugging için)
  final List<CardEvent> _eventHistory = [];
  static const int _maxHistorySize = 100;
  
  /// Event emit et
  void emit(CardEvent event) {
    // Stream'e gönder
    _controller.add(event);
    
    // History'e ekle
    _addToHistory(event);
  }
  
  /// Belirli event tipini dinle
  StreamSubscription<T> listen<T extends CardEvent>(
    void Function(T event) onEvent,
  ) {
    return stream
        .where((event) => event is T)
        .cast<T>()
        .listen(onEvent);
  }
  
  // MARK: - Credit Card Events
  
  /// Kredi kartı ekleme eventi
  void emitCreditCardAdded(CreditCardModel creditCard) {
    emit(CreditCardAdded(creditCard));
  }
  
  /// Kredi kartı güncelleme eventi
  void emitCreditCardUpdated({
    required CreditCardModel oldCard,
    required CreditCardModel newCard,
  }) {
    emit(CreditCardUpdated(
      oldCard: oldCard,
      newCard: newCard,
    ));
  }
  
  /// Kredi kartı silme eventi
  void emitCreditCardDeleted({
    required String cardId,
    CreditCardModel? deletedCard,
  }) {
    emit(CreditCardDeleted(
      cardId: cardId,
      deletedCard: deletedCard,
    ));
  }
  
  /// Kredi kartı bakiye güncelleme eventi
  void emitCreditCardBalanceUpdated({
    required String cardId,
    required double oldDebt,
    required double newDebt,
    required double oldAvailableLimit,
    required double newAvailableLimit,
    required double changeAmount,
  }) {
    emit(CreditCardBalanceUpdated(
      cardId: cardId,
      oldDebt: oldDebt,
      newDebt: newDebt,
      oldAvailableLimit: oldAvailableLimit,
      newAvailableLimit: newAvailableLimit,
      changeAmount: changeAmount,
    ));
  }
  
  // MARK: - Debit Card Events
  
  /// Banka kartı ekleme eventi
  void emitDebitCardAdded(DebitCardModel debitCard) {
    emit(DebitCardAdded(debitCard));
  }
  
  /// Banka kartı güncelleme eventi
  void emitDebitCardUpdated({
    required DebitCardModel oldCard,
    required DebitCardModel newCard,
  }) {
    emit(DebitCardUpdated(
      oldCard: oldCard,
      newCard: newCard,
    ));
  }
  
  /// Banka kartı silme eventi
  void emitDebitCardDeleted({
    required String cardId,
    DebitCardModel? deletedCard,
  }) {
    emit(DebitCardDeleted(
      cardId: cardId,
      deletedCard: deletedCard,
    ));
  }
  
  /// Banka kartı bakiye güncelleme eventi
  void emitDebitCardBalanceUpdated({
    required String cardId,
    required double oldBalance,
    required double newBalance,
    required double changeAmount,
  }) {
    emit(DebitCardBalanceUpdated(
      cardId: cardId,
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeAmount: changeAmount,
    ));
  }
  
  // MARK: - Cash Account Events
  
  /// Nakit hesabı güncelleme eventi
  void emitCashAccountUpdated({
    required String accountId,
    required double oldBalance,
    required double newBalance,
    required double changeAmount,
  }) {
    emit(CashAccountUpdated(
      accountId: accountId,
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeAmount: changeAmount,
    ));
  }
  
  /// Event history'e ekle
  void _addToHistory(CardEvent event) {
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }
  }
  
  /// Event history'i getir (debugging için)
  List<CardEvent> get eventHistory => List.unmodifiable(_eventHistory);
  
  /// Event history'i temizle
  void clearHistory() {
    _eventHistory.clear();
  }
  
  /// Stream'i kapat
  void dispose() {
    _controller.close();
  }
}

// Global instance
final cardEvents = CardEventManager(); 