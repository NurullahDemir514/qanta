import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_client.dart';

/// Firebase Firestore Service
/// Handles all database operations for the Qanta app
class FirebaseFirestoreService {
  static FirebaseFirestore get _firestore => FirebaseManager.firestore;

  /// Get current user ID
  static String? get _currentUserId => FirebaseManager.currentUserId;

  /// Get collection reference with user-specific path
  static CollectionReference<Map<String, dynamic>> getCollection(String collectionName) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to access Firestore');
    }
    return _firestore.collection('users').doc(userId).collection(collectionName);
  }

  /// Get document reference with user-specific path
  static DocumentReference getDocument(String collectionName, String docId) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to access Firestore');
    }
    return _firestore.collection('users').doc(userId).collection(collectionName).doc(docId);
  }

  /// Get document reference with user-specific path (private method)
  static DocumentReference _getUserDocument(String collectionName, String docId) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to access Firestore');
    }
    return _firestore.collection('users').doc(userId).collection(collectionName).doc(docId);
  }

  /// Add document to user-specific collection
  static Future<DocumentReference> addDocument({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await getCollection(collectionName).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
    } catch (e) {
      rethrow;
    }
  }

  /// Set document in user-specific collection
  static Future<void> setDocument({
    required String collectionName,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await getDocument(collectionName, docId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: merge));
    } catch (e) {
      rethrow;
    }
  }

  /// Update document in user-specific collection
  static Future<void> updateDocument({
    required String collectionName,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await getDocument(collectionName, docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete document from user-specific collection
  static Future<void> deleteDocument({
    required String collectionName,
    required String docId,
  }) async {
    try {
      await getDocument(collectionName, docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get document from user-specific collection
  static Future<DocumentSnapshot> getDocumentSnapshot({
    required String collectionName,
    required String docId,
  }) async {
    try {
      final doc = await getDocument(collectionName, docId).get();
      return doc;
    } catch (e) {
      rethrow;
    }
  }

  /// Get documents from user-specific collection
  static Future<QuerySnapshot<Map<String, dynamic>>> getDocuments({
    required String collectionName,
    Query<Map<String, dynamic>>? query,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> baseQuery = getCollection(collectionName);
      
      if (query != null) {
        baseQuery = query;
      }
      
      if (limit != null) {
        baseQuery = baseQuery.limit(limit);
      }
      
      if (startAfter != null) {
        baseQuery = baseQuery.startAfterDocument(startAfter);
      }
      
      final snapshot = await baseQuery.get();
      return snapshot;
    } catch (e) {
      rethrow;
    }
  }

  /// Get real-time stream of documents from user-specific collection
  static Stream<QuerySnapshot<Map<String, dynamic>>> getDocumentsStream({
    required String collectionName,
    Query<Map<String, dynamic>>? query,
    int? limit,
  }) {
    try {
      Query<Map<String, dynamic>> baseQuery = getCollection(collectionName);
      
      if (query != null) {
        baseQuery = query;
      }
      
      if (limit != null) {
        baseQuery = baseQuery.limit(limit);
      }
      
      return baseQuery.snapshots();
    } catch (e) {
      rethrow;
    }
  }

  /// Get real-time stream of single document
  static Stream<DocumentSnapshot> getDocumentStream({
    required String collectionName,
    required String docId,
  }) {
    try {
      return _getUserDocument(collectionName, docId).snapshots();
    } catch (e) {
      rethrow;
    }
  }

  /// Batch write operations
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      
      for (final operation in operations) {
        final type = operation['type'] as String;
        final collectionName = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>?;
        
        switch (type) {
          case 'set':
            if (docId != null && data != null) {
              batch.set(_getUserDocument(collectionName, docId), {
                ...data,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            break;
          case 'update':
            if (docId != null && data != null) {
              batch.update(_getUserDocument(collectionName, docId), {
                ...data,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            break;
          case 'delete':
            if (docId != null) {
              batch.delete(_getUserDocument(collectionName, docId));
            }
            break;
        }
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Run transaction
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      rethrow;
    }
  }
}
