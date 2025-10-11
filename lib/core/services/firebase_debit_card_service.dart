import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/debit_card_model.dart';
import 'firebase_auth_service.dart';
import 'firebase_firestore_service.dart';

/// Firebase Debit Card Service
/// Handles all debit card operations for the Qanta app
class FirebaseDebitCardService {
  static const String _collectionName = 'debit_cards';

  /// Get all debit cards for current user
  static Future<List<DebitCardModel>> getDebitCards() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final snapshot = await FirebaseFirestoreService.getDocuments(
        collectionName: _collectionName,
        query: FirebaseFirestoreService.getCollection(_collectionName)
            .where('user_id', isEqualTo: userId)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DebitCardModel.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error fetching debit cards: $e');
      rethrow;
    }
  }

  /// Get debit card by ID
  static Future<DebitCardModel?> getDebitCardById(String cardId) async {
    try {
      final doc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _collectionName,
        docId: cardId,
      );

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return DebitCardModel.fromJson({'id': doc.id, ...data});
    } catch (e) {
      debugPrint('Error fetching debit card: $e');
      rethrow;
    }
  }

  /// Add new debit card
  static Future<String> addDebitCard(DebitCardModel card) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _collectionName,
        data: {...card.toJson(), 'user_id': userId},
      );
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update debit card
  static Future<void> updateDebitCard({
    required String cardId,
    required DebitCardModel card,
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

  /// Delete debit card (soft delete)
  static Future<void> deleteDebitCard(String cardId) async {
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

  /// Get debit cards stream for real-time updates
  static Stream<List<DebitCardModel>> getDebitCardsStream() {
    return FirebaseFirestoreService.getDocumentsStream(
      collectionName: _collectionName,
      query: FirebaseFirestoreService.getCollection(_collectionName)
          .where('user_id', isEqualTo: FirebaseAuthService.currentUserId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true),
    ).map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return DebitCardModel.fromJson({'id': doc.id, ...data});
      }).toList(),
    );
  }

  /// Update debit card balance
  static Future<void> updateBalance({
    required String cardId,
    required double newBalance,
  }) async {
    try {
      await FirebaseFirestoreService.updateDocument(
        collectionName: _collectionName,
        docId: cardId,
        data: {
          'balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get total debit card balance
  static Future<double> getTotalBalance() async {
    try {
      final cards = await getDebitCards();
      return cards.fold<double>(0.0, (sum, card) => sum + card.balance);
    } catch (e) {
      debugPrint('Error getting total debit card balance: $e');
      return 0.0;
    }
  }

  /// Add amount to debit card
  static Future<void> addAmount({
    required String cardId,
    required double amount,
  }) async {
    try {
      final card = await getDebitCardById(cardId);
      if (card == null) throw Exception('Debit card bulunamadı');

      final newBalance = card.balance + amount;
      await updateBalance(cardId: cardId, newBalance: newBalance);
    } catch (e) {
      debugPrint('Error adding amount to debit card: $e');
      rethrow;
    }
  }

  /// Subtract amount from debit card
  static Future<void> subtractAmount({
    required String cardId,
    required double amount,
  }) async {
    try {
      final card = await getDebitCardById(cardId);
      if (card == null) throw Exception('Debit card bulunamadı');

      if (card.balance < amount) {
        throw Exception('Yetersiz bakiye');
      }

      final newBalance = card.balance - amount;
      await updateBalance(cardId: cardId, newBalance: newBalance);
    } catch (e) {
      debugPrint('Error subtracting amount from debit card: $e');
      rethrow;
    }
  }
}
