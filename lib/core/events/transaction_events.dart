import 'dart:async';
import '../../shared/models/transaction_model.dart';

/// Transaction olayları için base class
abstract class TransactionEvent {
  final DateTime timestamp;
  
  TransactionEvent() : timestamp = DateTime.now();
}

/// İşlem eklendiğinde tetiklenen event
class TransactionAdded extends TransactionEvent {
  final TransactionModel transaction;
  
  TransactionAdded(this.transaction);
  
  @override
  String toString() => 'TransactionAdded(${transaction.description}, ${transaction.amount}₺)';
}

/// İşlem silindiğinde tetiklenen event
class TransactionDeleted extends TransactionEvent {
  final String transactionId;
  final TransactionModel? deletedTransaction; // Rollback için
  final String? cardId;
  final CardType? cardType;
  final double? amount;
  final TransactionType? type;
  
  TransactionDeleted({
    required this.transactionId,
    this.deletedTransaction,
    this.cardId,
    this.cardType,
    this.amount,
    this.type,
  });
  
  @override
  String toString() => 'TransactionDeleted($transactionId)';
}

/// İşlem güncellendiğinde tetiklenen event
class TransactionUpdated extends TransactionEvent {
  final TransactionModel oldTransaction;
  final TransactionModel newTransaction;
  
  TransactionUpdated({
    required this.oldTransaction,
    required this.newTransaction,
  });
  
  @override
  String toString() => 'TransactionUpdated(${newTransaction.id})';
}

/// Bakiye güncellendiğinde tetiklenen event
class BalanceUpdated extends TransactionEvent {
  final String cardId;
  final CardType cardType;
  final double oldBalance;
  final double newBalance;
  final double changeAmount;
  
  BalanceUpdated({
    required this.cardId,
    required this.cardType,
    required this.oldBalance,
    required this.newBalance,
    required this.changeAmount,
  });
  
  @override
  String toString() => 'BalanceUpdated($cardId: $oldBalance → $newBalance)';
}

/// Taksitli işlem olayları
class InstallmentTransactionAdded extends TransactionEvent {
  final String installmentTransactionId;
  final String creditCardId;
  final double totalAmount;
  final int installmentCount;
  final String description;
  
  InstallmentTransactionAdded({
    required this.installmentTransactionId,
    required this.creditCardId,
    required this.totalAmount,
    required this.installmentCount,
    required this.description,
  });
  
  @override
  String toString() => 'InstallmentTransactionAdded($description, $installmentCount taksit)';
}

/// Merkezi Transaction Event Manager
class TransactionEventManager {
  static final TransactionEventManager _instance = TransactionEventManager._internal();
  factory TransactionEventManager() => _instance;
  TransactionEventManager._internal();
  
  // Event stream controller
  final StreamController<TransactionEvent> _controller = 
      StreamController<TransactionEvent>.broadcast();
  
  // Public stream
  Stream<TransactionEvent> get stream => _controller.stream;
  
  // Event listeners by type
  final Map<Type, List<Function(TransactionEvent)>> _listeners = {};
  
  // Event history (debugging için)
  final List<TransactionEvent> _eventHistory = [];
  static const int _maxHistorySize = 100;
  
  /// Event emit et
  void emit(TransactionEvent event) {
    
    // Stream'e gönder
    if (!_controller.isClosed) {
    _controller.add(event);
    } else {
    }
    
    // History'e ekle
    _addToHistory(event);
    
    // Type-specific listeners'ı çağır
    _notifyTypeListeners(event);
  }
  
  /// Belirli event tipini dinle
  StreamSubscription<T> listen<T extends TransactionEvent>(
    void Function(T event) onEvent,
  ) {
    return stream
        .where((event) => event is T)
        .cast<T>()
        .listen(onEvent);
  }
  
  /// Transaction ekleme eventi
  void emitTransactionAdded(TransactionModel transaction) {
    emit(TransactionAdded(transaction));
  }
  
  /// Transaction silme eventi
  void emitTransactionDeleted({
    required String transactionId,
    TransactionModel? deletedTransaction,
    String? cardId,
    CardType? cardType,
    double? amount,
    TransactionType? type,
  }) {
    emit(TransactionDeleted(
      transactionId: transactionId,
      deletedTransaction: deletedTransaction,
      cardId: cardId,
      cardType: cardType,
      amount: amount,
      type: type,
    ));
  }
  
  /// Transaction güncelleme eventi
  void emitTransactionUpdated({
    required TransactionModel oldTransaction,
    required TransactionModel newTransaction,
  }) {
    emit(TransactionUpdated(
      oldTransaction: oldTransaction,
      newTransaction: newTransaction,
    ));
  }
  
  /// Bakiye güncelleme eventi
  void emitBalanceUpdated({
    required String cardId,
    required CardType cardType,
    required double oldBalance,
    required double newBalance,
    required double changeAmount,
  }) {
    emit(BalanceUpdated(
      cardId: cardId,
      cardType: cardType,
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeAmount: changeAmount,
    ));
  }
  
  /// Taksitli işlem ekleme eventi
  void emitInstallmentTransactionAdded({
    required String installmentTransactionId,
    required String creditCardId,
    required double totalAmount,
    required int installmentCount,
    required String description,
  }) {
    emit(InstallmentTransactionAdded(
      installmentTransactionId: installmentTransactionId,
      creditCardId: creditCardId,
      totalAmount: totalAmount,
      installmentCount: installmentCount,
      description: description,
    ));
  }
  
  /// Type-specific listener ekle
  void addListener<T extends TransactionEvent>(
    void Function(T event) listener,
  ) {
    final type = T;
    _listeners[type] ??= [];
    _listeners[type]!.add((event) {
      if (event is T) listener(event);
    });
  }
  
  /// Type-specific listener kaldır
  void removeListener<T extends TransactionEvent>(
    void Function(T event) listener,
  ) {
    final type = T;
    _listeners[type]?.remove(listener);
  }
  
  /// Event history'sini al
  List<TransactionEvent> getEventHistory() {
    return List.unmodifiable(_eventHistory);
  }
  
  /// Event history'sini temizle
  void clearEventHistory() {
    _eventHistory.clear();
  }
  
  /// Event istatistikleri
  Map<String, int> getEventStats() {
    final stats = <String, int>{};
    for (final event in _eventHistory) {
      final type = event.runtimeType.toString();
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }
  
  /// Debug: Event system durumunu yazdır
  void printDebugInfo() {
    final recentEvents = _eventHistory.length > 5 
        ? _eventHistory.sublist(_eventHistory.length - 5)
        : _eventHistory;
    for (final event in recentEvents) {
    }
  }
  
  // Private methods
  void _addToHistory(TransactionEvent event) {
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }
  }
  
  void _notifyTypeListeners(TransactionEvent event) {
    final type = event.runtimeType;
    _listeners[type]?.forEach((listener) {
      try {
        listener(event);
      } catch (e) {
      }
    });
  }
  
  /// Cleanup
  void dispose() {
    _controller.close();
    _listeners.clear();
    _eventHistory.clear();
  }
}

/// Global instance
final transactionEvents = TransactionEventManager();

/// Convenience methods
void emitTransactionAdded(TransactionModel transaction) {
  transactionEvents.emitTransactionAdded(transaction);
}

void emitTransactionDeleted({
  required String transactionId,
  TransactionModel? deletedTransaction,
  String? cardId,
  CardType? cardType,
  double? amount,
  TransactionType? type,
}) {
  transactionEvents.emitTransactionDeleted(
    transactionId: transactionId,
    deletedTransaction: deletedTransaction,
    cardId: cardId,
    cardType: cardType,
    amount: amount,
    type: type,
  );
}

void emitBalanceUpdated({
  required String cardId,
  required CardType cardType,
  required double oldBalance,
  required double newBalance,
  required double changeAmount,
}) {
  transactionEvents.emitBalanceUpdated(
    cardId: cardId,
    cardType: cardType,
    oldBalance: oldBalance,
    newBalance: newBalance,
    changeAmount: changeAmount,
  );
} 