// QANTA v2 Services - Barrel Export File
// This file exports all the new service classes that work with our QANTA v2 database schema

// Core services - Temporarily disabled for Firebase migration
// export 'account_service_v2.dart';
// export 'transaction_service_v2.dart';
// export 'category_service_v2.dart';
// export 'installment_service_v2.dart';
// export 'income_service.dart';
// export 'transfer_service.dart';
// export 'budget_service.dart';

// Firebase services
export 'firebase_auth_service.dart';
export 'firebase_firestore_service.dart';
export 'firebase_transaction_service.dart';
export 'firebase_credit_card_service.dart';
export 'firebase_cash_account_service.dart';
export 'firebase_debit_card_service.dart';
export 'firebase_budget_service.dart';
export 'firebase_budget_service_v2.dart';
export 'profile_image_service.dart';

// Legacy services (for backward compatibility during migration)
// export 'supabase_service.dart'; // Temporarily disabled for Firebase migration
// export 'profile_image_service.dart'; // Temporarily disabled for Firebase migration

import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporarily disabled for Firebase migration
import 'dart:io';
// import '../supabase_client.dart'; // Temporarily disabled for Firebase migration
import '../../shared/models/models_v2.dart';

class QuickNoteService {
  static const String _tableName = 'quick_notes';

  /// Hızlı not ekle
  static Future<Map<String, dynamic>> addQuickNote({
    required String content,
    required String type,
    String? imagePath,
  }) async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.addQuickNote() - Firebase implementation needed');
      throw Exception('Not implemented yet');
    } catch (e) {
      debugPrint('Error adding quick note: $e');
      rethrow;
    }
  }

  /// Hızlı notları getir
  static Future<List<Map<String, dynamic>>> getQuickNotes() async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.getQuickNotes() - Firebase implementation needed');
      return [];
    } catch (e) {
      debugPrint('Error getting quick notes: $e');
      return [];
    }
  }

  /// Kullanıcının tüm hızlı notlarını getir
  static Future<List<Map<String, dynamic>>> getUserQuickNotes() async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.getUserQuickNotes() - Firebase implementation needed');
      return [];
    } catch (e) {
      debugPrint('Error getting user quick notes: $e');
      rethrow;
    }
  }

  /// İşlenmemiş (pending) notları getir
  static Future<List<Map<String, dynamic>>> getPendingNotes() async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.getPendingNotes() - Firebase implementation needed');
      return [];
    } catch (e) {
      debugPrint('Error getting pending notes: $e');
      rethrow;
    }
  }

  /// Notu işlendi olarak işaretle
  static Future<void> markNoteAsProcessed(String noteId) async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.markNoteAsProcessed() - Firebase implementation needed');
    } catch (e) {
      debugPrint('Error marking note as processed: $e');
      rethrow;
    }
  }

  /// Hızlı not güncelle
  static Future<void> updateQuickNote(Map<String, dynamic> note) async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.updateQuickNote() - Firebase implementation needed');
    } catch (e) {
      debugPrint('Error updating quick note: $e');
      rethrow;
    }
  }

  /// Hızlı not sil
  static Future<void> deleteQuickNote(String noteId) async {
    try {
      // TODO: Implement with Firebase
      debugPrint('QuickNoteService.deleteQuickNote() - Firebase implementation needed');
    } catch (e) {
      debugPrint('Error deleting quick note: $e');
      rethrow;
    }
  }
}