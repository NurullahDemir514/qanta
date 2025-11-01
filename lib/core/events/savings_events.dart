import 'package:flutter/foundation.dart';
import '../../shared/models/savings_goal.dart';
import '../../shared/models/savings_transaction.dart';

/// Tasarruf hedefi event'leri
abstract class SavingsEvent {}

/// Yeni tasarruf hedefi oluşturuldu
class SavingsGoalCreated extends SavingsEvent {
  final SavingsGoal goal;

  SavingsGoalCreated(this.goal);
}

/// Tasarruf hedefi güncellendi
class SavingsGoalUpdated extends SavingsEvent {
  final SavingsGoal oldGoal;
  final SavingsGoal newGoal;

  SavingsGoalUpdated(this.oldGoal, this.newGoal);
}

/// Tasarruf hedefi silindi
class SavingsGoalDeleted extends SavingsEvent {
  final String goalId;
  final SavingsGoal? deletedGoal;

  SavingsGoalDeleted(this.goalId, this.deletedGoal);
}

/// Tasarruf hedefi tamamlandı
class SavingsGoalCompleted extends SavingsEvent {
  final SavingsGoal goal;

  SavingsGoalCompleted(this.goal);
}

/// Tasarruf hedefine para eklendi
class SavingsDeposit extends SavingsEvent {
  final String goalId;
  final double amount;
  final SavingsTransaction transaction;

  SavingsDeposit(this.goalId, this.amount, this.transaction);
}

/// Tasarruf hedefinden para çekildi
class SavingsWithdraw extends SavingsEvent {
  final String goalId;
  final double amount;
  final SavingsTransaction transaction;

  SavingsWithdraw(this.goalId, this.amount, this.transaction);
}

/// Milestone başarıldı
class SavingsMilestoneAchieved extends SavingsEvent {
  final SavingsGoal goal;
  final Milestone milestone;

  SavingsMilestoneAchieved(this.goal, this.milestone);
}

/// Otomatik transfer gerçekleşti
class SavingsAutoTransfer extends SavingsEvent {
  final String goalId;
  final double amount;
  final SavingsTransaction transaction;

  SavingsAutoTransfer(this.goalId, this.amount, this.transaction);
}

/// Round-up işlemi gerçekleşti
class SavingsRoundUp extends SavingsEvent {
  final String goalId;
  final double amount;
  final SavingsTransaction transaction;

  SavingsRoundUp(this.goalId, this.amount, this.transaction);
}

/// Event yöneticisi - Singleton pattern
class SavingsEvents {
  static final SavingsEvents _instance = SavingsEvents._internal();
  factory SavingsEvents() => _instance;
  SavingsEvents._internal();

  final List<void Function(SavingsEvent)> _listeners = [];

  /// Event dinleyici ekle - Removal callback döndürür
  VoidCallback listen<T extends SavingsEvent>(void Function(T) callback) {
    void listener(SavingsEvent event) {
      if (event is T) {
        callback(event);
      }
    }
    
    _listeners.add(listener);
    
    // Unsubscribe callback'i döndür
    return () => _listeners.remove(listener);
  }

  /// Event emit et
  void emit(SavingsEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  /// Hedef oluşturuldu event'i
  void emitSavingsGoalCreated(SavingsGoal goal) {
    emit(SavingsGoalCreated(goal));
  }

  /// Hedef güncellendi event'i
  void emitSavingsGoalUpdated(SavingsGoal oldGoal, SavingsGoal newGoal) {
    emit(SavingsGoalUpdated(oldGoal, newGoal));
  }

  /// Hedef silindi event'i
  void emitSavingsGoalDeleted(String goalId, SavingsGoal? deletedGoal) {
    emit(SavingsGoalDeleted(goalId, deletedGoal));
  }

  /// Hedef tamamlandı event'i
  void emitSavingsGoalCompleted(SavingsGoal goal) {
    emit(SavingsGoalCompleted(goal));
  }

  /// Para eklendi event'i
  void emitSavingsDeposit(String goalId, double amount, SavingsTransaction transaction) {
    emit(SavingsDeposit(goalId, amount, transaction));
  }

  /// Para çekildi event'i
  void emitSavingsWithdraw(String goalId, double amount, SavingsTransaction transaction) {
    emit(SavingsWithdraw(goalId, amount, transaction));
  }

  /// Milestone event'i
  void emitSavingsMilestoneAchieved(SavingsGoal goal, Milestone milestone) {
    emit(SavingsMilestoneAchieved(goal, milestone));
  }

  /// Otomatik transfer event'i
  void emitSavingsAutoTransfer(String goalId, double amount, SavingsTransaction transaction) {
    emit(SavingsAutoTransfer(goalId, amount, transaction));
  }

  /// Round-up event'i
  void emitSavingsRoundUp(String goalId, double amount, SavingsTransaction transaction) {
    emit(SavingsRoundUp(goalId, amount, transaction));
  }

  /// Tüm dinleyicileri temizle
  void clearListeners() {
    _listeners.clear();
  }
}

/// Global event instance
final savingsEvents = SavingsEvents();

