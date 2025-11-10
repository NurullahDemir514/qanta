import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_client.dart';

/// Referral Service
/// Handles referral code processing and tracking
class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get user's referral code
  /// Referral code is first 8 characters of user ID (uppercase)
  String? getReferralCode() {
    final userId = _currentUserId;
    if (userId == null) return null;
    return userId.substring(0, 8).toUpperCase();
  }

  /// Process referral code after user registration
  /// This should be called after user signs up
  /// 
  /// Returns:
  /// - true if referral code was processed successfully
  /// - false if referral code was invalid or user was already referred
  Future<bool> processReferralCode(String referralCode, {int maxRetries = 3, int retryDelaySeconds = 2}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('❌ ReferralService: User not authenticated');
        return false;
      }

      if (referralCode.isEmpty) {
        debugPrint('❌ ReferralService: Referral code is empty');
        return false;
      }

      debugPrint('🔄 ReferralService: Processing referral code: $referralCode');

      // Try processing referral code with retry mechanism
      // User document might not be created yet in Firestore
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // Wait before retry (except first attempt)
          if (attempt > 1) {
            debugPrint('🔄 ReferralService: Retry attempt $attempt/$maxRetries...');
            await Future.delayed(Duration(seconds: retryDelaySeconds * attempt));
          }

      // Call Cloud Function to process referral code
      final callable = _functions.httpsCallable('processReferralCode');
      final result = await callable.call({
        'referralCode': referralCode.toUpperCase().trim(),
      });

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        debugPrint('✅ ReferralService: Referral code processed successfully');
        debugPrint('   Points awarded: ${data['pointsAwarded']}');
        debugPrint('   New referral count: ${data['newReferralCount']}');
        return true;
      } else {
            final message = data['message'] as String? ?? 'Unknown error';
            debugPrint('⚠️ ReferralService: Referral code processing failed: $message');
            
            // Don't retry if it's a validation error (invalid code, already referred, etc.)
            if (message.contains('invalid') || 
                message.contains('already') || 
                message.contains('not found') && !message.contains('User document')) {
              return false;
            }
            
            // Continue to retry if it's a "User document not found" error
            if (message.contains('User document not found') && attempt < maxRetries) {
              continue;
            }
            
            return false;
          }
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          debugPrint('❌ ReferralService: Error processing referral code (attempt $attempt/$maxRetries): $e');
          
          // Check if it's a "Referral code not found" error - don't retry for this
          if (errorString.contains('referral code') && errorString.contains('not found')) {
            debugPrint('⚠️ ReferralService: Referral code not found, not retrying');
            return false;
          }
          
          // Check if it's a "User document not found" error
          // Cloud Function now creates user document if it doesn't exist, so this should be rare
          if (errorString.contains('user document not found') &&
              !errorString.contains('referral code') &&
              !errorString.contains('invalid referral code')) {
            if (attempt < maxRetries) {
              debugPrint('🔄 ReferralService: User document issue, will retry...');
              continue;
            } else {
              debugPrint('⚠️ ReferralService: User document issue after $maxRetries attempts');
              return false;
            }
          }
          
          // For other errors (invalid code, already referred, etc.), don't retry
        return false;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ ReferralService: Error processing referral code: $e');
      return false;
    }
  }

  /// Get referral count for current user
  /// Returns the number of successful referrals
  Future<int> getReferralCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('❌ ReferralService: User not authenticated');
        return 0;
      }

      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referral_stats')
          .doc('stats')
          .get();

      if (!statsDoc.exists) {
        return 0;
      }

      final data = statsDoc.data();
      return data?['referral_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting referral count: $e');
      return 0;
    }
  }

  /// Get referral stats stream (real-time updates)
  /// Returns a stream of referral count
  Stream<int> getReferralCountStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return Stream.value(0);
      }

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('referral_stats')
          .doc('stats')
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return 0;
        }
        final data = snapshot.data();
        return data?['referral_count'] as int? ?? 0;
      });
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting referral count stream: $e');
      return Stream.value(0);
    }
  }

  /// Get total points earned from referrals
  Future<int> getTotalPointsEarned() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return 0;
      }

      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referral_stats')
          .doc('stats')
          .get();

      if (!statsDoc.exists) {
        return 0;
      }

      final data = statsDoc.data();
      return data?['total_points_earned'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting total points earned: $e');
      return 0;
    }
  }

  /// Get referral list (referred users)
  /// Returns a list of referred users
  Future<List<Map<String, dynamic>>> getReferralList() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return [];
      }

      final referralsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referrals')
          .orderBy('referred_at', descending: true)
          .get();

      return referralsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'referred_user_id': data['referred_user_id'],
          'referred_user_email': data['referred_user_email'],
          'referred_user_name': data['referred_user_name'],
          'points_awarded': data['points_awarded'],
          'referred_at': data['referred_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting referral list: $e');
      return [];
    }
  }

  /// Check if user was referred by someone
  /// Returns the referrer's user ID if user was referred, null otherwise
  Future<String?> getReferrerId() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data();
      return data?['referred_by'] as String?;
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting referrer ID: $e');
      return null;
    }
  }

  /// Store referral code in user's document (before registration)
  /// This is used when user provides referral code during registration
  /// The code will be processed after user registration
  Future<void> storeReferralCodeForProcessing(String referralCode) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('❌ ReferralService: User not authenticated');
        return;
      }

      // Store referral code in user document
      // This will be processed after user registration
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
        'referred_by_code': referralCode.toUpperCase().trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ ReferralService: Referral code stored for processing: $referralCode');
    } catch (e) {
      debugPrint('❌ ReferralService: Error storing referral code: $e');
    }
  }

  /// Check if user has already entered a referral code
  /// Returns true if user was referred by someone (referred_by field exists)
  /// Returns false if user hasn't entered a referral code yet
  Future<bool> hasEnteredReferralCode() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('❌ ReferralService: User not authenticated');
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data();
      final referredBy = data?['referred_by'] as String?;
      
      // If referred_by exists, user has already entered a referral code
      return referredBy != null && referredBy.isNotEmpty;
    } catch (e) {
      debugPrint('❌ ReferralService: Error checking referral code status: $e');
      return false;
    }
  }

  /// Get stream to listen to referral code status changes
  /// Returns true if user was referred by someone
  Stream<bool> hasEnteredReferralCodeStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return Stream.value(false);
      }

      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return false;
        }
        final data = snapshot.data();
        final referredBy = data?['referred_by'] as String?;
        return referredBy != null && referredBy.isNotEmpty;
      });
    } catch (e) {
      debugPrint('❌ ReferralService: Error getting referral code status stream: $e');
      return Stream.value(false);
    }
  }
}

