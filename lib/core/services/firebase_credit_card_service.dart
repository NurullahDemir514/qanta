import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/credit_card_model.dart';
import 'firebase_firestore_service.dart';

/// Firebase Credit Card Service
/// Handles all credit card operations for the Qanta app
class FirebaseCreditCardService {
  static const String _collectionName = 'credit_cards';

  /// Get all active credit cards
  static Future<List<CreditCardModel>> getCreditCards() async {
    try {
      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CreditCardModel.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching credit cards: $e');
      throw Exception('Kredi kartları yüklenirken hata oluştu: $e');
    }
  }

  /// Get credit card by ID
  static Future<CreditCardModel?> getCreditCardById(String cardId) async {
    try {
      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _collectionName,
        docId: cardId,
      );

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return CreditCardModel.fromJson({'id': doc.id, ...data});
    } catch (e) {
      debugPrint('Error fetching credit card: $e');
      rethrow;
    }
  }

  /// Add new credit card
  static Future<String> addCreditCard(CreditCardModel card) async {
    try {
      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: card.toJson(),
      );
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update credit card
  static Future<void> updateCreditCard({
    required String cardId,
    required CreditCardModel card,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: cardId,
        data: card.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete credit card (soft delete)
  static Future<void> deleteCreditCard(String cardId) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: cardId,
        data: {'is_active': false},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get credit card stream for real-time updates
  static Stream<List<CreditCardModel>> getCreditCardsStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return CreditCardModel.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Update credit card balance
  static Future<void> updateBalance({
    required String cardId,
    required double newBalance,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: cardId,
        data: {
          'current_balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get total credit limit
  static Future<double> getTotalCreditLimit() async {
    try {
      final cards = await getCreditCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.creditLimit);
    } catch (e) {
      debugPrint('Error getting total credit limit: $e');
      return 0.0;
    }
  }

  /// Get total current balance
  static Future<double> getTotalCurrentBalance() async {
    try {
      final cards = await getCreditCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.currentBalance);
    } catch (e) {
      debugPrint('Error getting total current balance: $e');
      return 0.0;
    }
  }

  /// Get available credit
  static Future<double> getAvailableCredit() async {
    try {
      final totalLimit = await getTotalCreditLimit();
      final totalBalance = await getTotalCurrentBalance();
      return totalLimit - totalBalance;
    } catch (e) {
      debugPrint('Error getting available credit: $e');
      return 0.0;
    }
  }

  /// Get credit utilization percentage
  static Future<double> getCreditUtilizationPercentage() async {
    try {
      final totalLimit = await getTotalCreditLimit();
      final totalBalance = await getTotalCurrentBalance();

      if (totalLimit == 0) return 0.0;
      return (totalBalance / totalLimit) * 100;
    } catch (e) {
      debugPrint('Error getting credit utilization percentage: $e');
      return 0.0;
    }
  }

  /// Get cards with high utilization (over 80%)
  static Future<List<CreditCardModel>> getHighUtilizationCards() async {
    try {
      final cards = await getCreditCards();
      return cards.where((card) {
        if (card.creditLimit == 0) return false;
        final utilization = (card.currentBalance / card.creditLimit) * 100;
        return utilization > 80;
      }).toList();
    } catch (e) {
      debugPrint('Error getting high utilization cards: $e');
      return [];
    }
  }

  /// Get upcoming payment dates (next 7 days)
  static Future<List<CreditCardModel>> getUpcomingPaymentCards() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final cards = await getCreditCards();
      return cards.where((card) {
        final paymentDate = card.paymentDate;
        return paymentDate.isAfter(now) && paymentDate.isBefore(nextWeek);
      }).toList();
    } catch (e) {
      debugPrint('Error getting upcoming payment cards: $e');
      return [];
    }
  }

  /// Get overdue cards
  static Future<List<CreditCardModel>> getOverdueCards() async {
    try {
      final now = DateTime.now();
      final cards = await getCreditCards();
      return cards.where((card) {
        return card.paymentDate.isBefore(now) && card.currentBalance > 0;
      }).toList();
    } catch (e) {
      debugPrint('Error getting overdue cards: $e');
      return [];
    }
  }
}
