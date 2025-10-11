import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/quick_note_model.dart';

/// Hızlı notlar için Firebase servisi
class QuickNoteService {
  static const String _collectionName = 'quick_notes';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hızlı not ekle
  static Future<QuickNote> addQuickNote({
    required String content,
    required String type,
    String? imagePath,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final note = QuickNote(
        id: '', // Firestore otomatik ID oluşturacak
        userId: user.uid,
        content: content.trim(),
        type: QuickNoteType.fromString(type),
        createdAt: DateTime.now(),
        imagePath: imagePath,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(note.toFirestore());

      // ID'yi güncelle
      final createdNote = note.copyWith(id: docRef.id);
      
      debugPrint('QuickNote eklendi: ${createdNote.id}');
      return createdNote;
    } catch (e) {
      debugPrint('Error adding quick note: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm hızlı notlarını getir
  static Future<List<QuickNote>> getUserQuickNotes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuickNote.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user quick notes: $e');
      rethrow;
    }
  }

  /// İşlenmemiş (pending) notları getir
  static Future<List<QuickNote>> getPendingNotes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('user_id', isEqualTo: user.uid)
          .where('is_processed', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuickNote.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending notes: $e');
      rethrow;
    }
  }

  /// İşlenmiş notları getir
  static Future<List<QuickNote>> getProcessedNotes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('user_id', isEqualTo: user.uid)
          .where('is_processed', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuickNote.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting processed notes: $e');
      rethrow;
    }
  }

  /// Notu işlendi olarak işaretle
  static Future<void> markNoteAsProcessed(String noteId, {String? transactionId}) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(noteId)
          .update({
        'is_processed': true,
        'processed_transaction_id': transactionId,
      });
      
      debugPrint('Not işlendi olarak işaretlendi: $noteId');
    } catch (e) {
      debugPrint('Error marking note as processed: $e');
      rethrow;
    }
  }

  /// Notu işlenmemiş olarak işaretle
  static Future<void> markNoteAsUnprocessed(String noteId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(noteId)
          .update({
        'is_processed': false,
        'processed_transaction_id': null,
      });
      
      debugPrint('Not işlenmemiş olarak işaretlendi: $noteId');
    } catch (e) {
      debugPrint('Error marking note as unprocessed: $e');
      rethrow;
    }
  }

  /// Hızlı not güncelle
  static Future<void> updateQuickNote(QuickNote note) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(note.id)
          .update(note.toFirestore());
      
      debugPrint('QuickNote güncellendi: ${note.id}');
    } catch (e) {
      debugPrint('Error updating quick note: $e');
      rethrow;
    }
  }

  /// Hızlı not sil
  static Future<void> deleteQuickNote(String noteId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(noteId)
          .delete();
      
      debugPrint('QuickNote silindi: $noteId');
    } catch (e) {
      debugPrint('Error deleting quick note: $e');
      rethrow;
    }
  }

  /// Belirli bir notu getir
  static Future<QuickNote?> getQuickNoteById(String noteId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(noteId)
          .get();

      if (doc.exists) {
        return QuickNote.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting quick note by id: $e');
      rethrow;
    }
  }

  /// Kullanıcının notlarını gerçek zamanlı dinle
  static Stream<List<QuickNote>> getUserQuickNotesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickNote.fromFirestore(doc))
            .toList());
  }

  /// İşlenmemiş notları gerçek zamanlı dinle
  static Stream<List<QuickNote>> getPendingNotesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('user_id', isEqualTo: user.uid)
        .where('is_processed', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickNote.fromFirestore(doc))
            .toList());
  }

  /// İşlenmiş notları gerçek zamanlı dinle
  static Stream<List<QuickNote>> getProcessedNotesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('user_id', isEqualTo: user.uid)
        .where('is_processed', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickNote.fromFirestore(doc))
            .toList());
  }
}
