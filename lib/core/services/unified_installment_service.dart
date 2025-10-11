import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_firestore_service.dart';
import 'firebase_auth_service.dart';

/// Unified installment service for Firebase operations
///
/// Handles installment master records and installment details
/// with proper balance management for credit cards
class UnifiedInstallmentService {
  static const String _installmentCollection = 'installment_transactions';
  static const String _installmentDetailCollection = 'installment_details';

  /// Create installment master record
  static Future<String> createInstallmentMaster({
    required double totalAmount,
    required double monthlyAmount,
    required int count,
    required String description,
    required String sourceAccountId,
    String? categoryId,
    DateTime? startDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final installmentData = {
        'user_id': userId,
        'source_account_id': sourceAccountId,
        'total_amount': totalAmount,
        'monthly_amount': monthlyAmount,
        'count': count,
        'description': description,
        'category_id': categoryId,
        'start_date': startDate ?? DateTime.now(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestoreService.addDocument(
        collectionName: _installmentCollection,
        data: installmentData,
      );

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Create installment details for all installments
  static Future<void> createInstallmentDetails({
    required String installmentId,
    required int count,
    required double monthlyAmount,
    DateTime? startDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final baseDate = startDate ?? DateTime.now();
      final details = <Map<String, dynamic>>[];

      for (int i = 1; i <= count; i++) {
        final dueDate = DateTime(
          baseDate.year,
          baseDate.month + i - 1,
          baseDate.day,
        );

        details.add({
          'user_id': userId,
          'installment_transaction_id': installmentId,
          'installment_number': i,
          'amount': monthlyAmount,
          'due_date': dueDate,
          'is_paid': false,
          'paid_date': null,
          'transaction_id': null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Batch write all installment details
      final batch = FirebaseFirestore.instance.batch();
      for (final detail in details) {
        final docRef = FirebaseFirestoreService.getCollection(
          _installmentDetailCollection,
        ).doc();
        batch.set(docRef, detail);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Get installment details by installment ID
  static Future<List<Map<String, dynamic>>> getInstallmentDetails(
    String installmentId,
  ) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Try the indexed query first
      try {
        final snapshot = await FirebaseFirestoreService.getDocuments(
          collectionName: _installmentDetailCollection,
          query:
              FirebaseFirestoreService.getCollection(
                    _installmentDetailCollection,
                  )
                  .where('user_id', isEqualTo: userId)
                  .where('installment_transaction_id', isEqualTo: installmentId)
                  .orderBy('installment_number', descending: false),
        );

        final results = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
            'due_date': _parseDateTime(data['due_date']),
            'paid_date': _parseDateTime(data['paid_date']),
            'created_at': _parseDateTime(data['created_at']),
            'updated_at': _parseDateTime(data['updated_at']),
          };
        }).toList();

        for (final detail in results) {}

        if (results.isEmpty) {}

        return results;
      } catch (e) {
        // Fallback: Get all installment details for user and filter in memory
        final snapshot = await FirebaseFirestoreService.getDocuments(
          collectionName: _installmentDetailCollection,
          query: FirebaseFirestoreService.getCollection(
            _installmentDetailCollection,
          ).where('user_id', isEqualTo: userId),
        );

        final allDetails = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
            'due_date': _parseDateTime(data['due_date']),
            'paid_date': _parseDateTime(data['paid_date']),
            'created_at': _parseDateTime(data['created_at']),
            'updated_at': _parseDateTime(data['updated_at']),
          };
        }).toList();

        for (final detail in allDetails) {}

        // Filter by installment_transaction_id in memory
        final filteredDetails = allDetails
            .where(
              (detail) => detail['installment_transaction_id'] == installmentId,
            )
            .toList();

        for (final detail in filteredDetails) {}

        // Sort by installment_number
        filteredDetails.sort(
          (a, b) => (a['installment_number'] as int).compareTo(
            b['installment_number'] as int,
          ),
        );

        return filteredDetails;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Pay an installment
  static Future<String> payInstallment({
    required String installmentDetailId,
    DateTime? paymentDate,
  }) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final paymentDateTime = paymentDate ?? DateTime.now();

      // Get installment detail
      final detailDoc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _installmentDetailCollection,
        docId: installmentDetailId,
      );

      final detailData = detailDoc.data() as Map<String, dynamic>;

      if (detailData['is_paid'] == true) {
        throw Exception('Bu taksit zaten ödenmiş');
      }

      // Get installment master for account info
      final installmentId = detailData['installment_transaction_id'] as String;
      final installmentDoc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _installmentCollection,
        docId: installmentId,
      );

      final installmentData = installmentDoc.data() as Map<String, dynamic>;

      // Create payment transaction
      final transactionData = {
        'user_id': userId,
        'type': 'expense',
        'amount': detailData['amount'],
        'description':
            '${installmentData['description']} (${detailData['installment_number']}/${installmentData['count']})',
        'source_account_id': installmentData['source_account_id'],
        'category_id': installmentData['category_id'],
        'installment_id': installmentId,
        'notes': 'Taksit ödemesi',
        'transaction_date': paymentDateTime,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final transactionDocRef = await FirebaseFirestoreService.addDocument(
        collectionName: 'transactions',
        data: transactionData,
      );

      // Update installment detail as paid
      await FirebaseFirestoreService.updateDocument(
        collectionName: _installmentDetailCollection,
        docId: installmentDetailId,
        data: {
          'is_paid': true,
          'paid_date': paymentDateTime,
          'transaction_id': transactionDocRef.id,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );

      // Update account balance (subtract payment from debt)
      await _updateAccountBalance(
        accountId: installmentData['source_account_id'] as String,
        amount: detailData['amount'] as double,
        operation: 'subtract',
      );

      return transactionDocRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update account balance
  static Future<void> _updateAccountBalance({
    required String accountId,
    required double amount,
    required String operation,
  }) async {
    try {
      final accountDoc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: 'accounts',
        docId: accountId,
      );

      final accountData = accountDoc.data() as Map<String, dynamic>;
      final currentBalance =
          (accountData['balance'] as num?)?.toDouble() ?? 0.0;

      double newBalance;
      if (operation == 'add') {
        newBalance = currentBalance + amount;
      } else if (operation == 'subtract') {
        newBalance = currentBalance - amount;
      } else {
        throw Exception('Geçersiz operasyon: $operation');
      }

      await FirebaseFirestoreService.updateDocument(
        collectionName: 'accounts',
        docId: accountId,
        data: {
          'balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete installment transaction (refunds total amount)
  static Future<bool> deleteInstallmentTransaction(String installmentId) async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Get installment master
      final installmentDoc = await FirebaseFirestoreService.getDocumentSnapshot(
        collectionName: _installmentCollection,
        docId: installmentId,
      );

      final installmentData = installmentDoc.data();
      if (installmentData == null)
        throw Exception('Taksit master verisi bulunamadı');

      // Get all installment details using fallback method
      List<Map<String, dynamic>> details;
      try {
        details = await getInstallmentDetails(installmentId);
      } catch (e) {
        // Fallback: Get all installment details for user and filter in memory
        final snapshot = await FirebaseFirestoreService.getDocuments(
          collectionName: _installmentDetailCollection,
          query: FirebaseFirestoreService.getCollection(
            _installmentDetailCollection,
          ).where('user_id', isEqualTo: userId),
        );

        details = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
        }).toList();

        // Filter by installment_transaction_id in memory
        details = details
            .where(
              (detail) => detail['installment_transaction_id'] == installmentId,
            )
            .toList();
      }

      // Check if any installments are paid
      final paidInstallments = details
          .where((d) => d['is_paid'] == true)
          .toList();
      if (paidInstallments.isNotEmpty) {
        throw Exception('Ödenmiş taksitler var, silinemez');
      }

      // Delete installment details
      final batch = FirebaseFirestore.instance.batch();
      for (final detail in details) {
        final docRef = FirebaseFirestoreService.getCollection(
          _installmentDetailCollection,
        ).doc(detail['id']);
        batch.delete(docRef);
      }
      await batch.commit();

      // Delete installment master
      await FirebaseFirestoreService.deleteDocument(
        collectionName: _installmentCollection,
        docId: installmentId,
      );

      // ✅ REMOVED: Firebase bakiye güncellemesi kaldırıldı
      // Bakiye güncellemesi artık sadece UnifiedProviderV2'de optimistic update ile yapılıyor
      // await _updateAccountBalance(
      //   accountId: (installmentData as Map<String, dynamic>)['source_account_id'] as String,
      //   amount: (installmentData)['total_amount'] as double,
      //   operation: 'subtract',
      // );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all installment masters for current user
  static Future<List<Map<String, dynamic>>> getAllInstallmentMasters() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Try indexed query first
      try {
        final snapshot = await FirebaseFirestoreService.getDocuments(
          collectionName: _installmentCollection,
          query: FirebaseFirestoreService.getCollection(_installmentCollection)
              .where('user_id', isEqualTo: userId)
              .orderBy('created_at', descending: true),
        );

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
            'start_date': _parseDateTime(data['start_date']),
            'created_at': _parseDateTime(data['created_at']),
            'updated_at': _parseDateTime(data['updated_at']),
          };
        }).toList();
      } catch (e) {
        // Fallback: Get all installment masters for user and filter in memory
        debugPrint('⚠️ Index query failed, using memory fallback: $e');

        final snapshot = await FirebaseFirestoreService.getDocuments(
          collectionName: _installmentCollection,
          query: FirebaseFirestoreService.getCollection(
            _installmentCollection,
          ).where('user_id', isEqualTo: userId),
        );

        final results = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
            'start_date': _parseDateTime(data['start_date']),
            'created_at': _parseDateTime(data['created_at']),
            'updated_at': _parseDateTime(data['updated_at']),
          };
        }).toList();

        // Sort by created_at in memory
        results.sort((a, b) {
          final aDate = a['created_at'] as DateTime? ?? DateTime(1970);
          final bDate = b['created_at'] as DateTime? ?? DateTime(1970);
          return bDate.compareTo(aDate); // Descending order
        });

        return results;
      }
    } catch (e) {
      debugPrint('❌ Error getting installment masters: $e');
      rethrow;
    }
  }

  /// Parse DateTime from Firestore Timestamp or String
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    } else if (value.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}
