// QANTA v2 Services - Barrel Export File
// This file exports all the new service classes that work with our QANTA v2 database schema

// Core services
export 'account_service_v2.dart';
export 'transaction_service_v2.dart';
export 'category_service_v2.dart';
export 'installment_service_v2.dart';
export 'income_service.dart';
export 'transfer_service.dart';
export 'budget_service.dart';

// Legacy services (for backward compatibility during migration)
export 'supabase_service.dart';
export 'profile_image_service.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../supabase_client.dart';
import '../../shared/models/models_v2.dart';

class QuickNoteService {
  static const String _tableName = 'quick_notes';
  
  /// Hızlı not ekle
  static Future<QuickNote> addQuickNote({
    required String content,
    required QuickNoteType type,
    String? imagePath,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      print('🔧 QuickNoteService.addQuickNote - Type: $type, ImagePath: $imagePath');

      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      final note = QuickNote(
        id: noteId,
        userId: user.id,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        imagePath: imagePath, // Local dosya yolu saklanıyor
      );

      print('🔧 Note object created - ImagePath: ${note.imagePath}');
      print('🔧 Note toJson: ${note.toJson()}');

      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(note.toJson())
          .select()
          .single();

      print('✅ Hızlı not eklendi: ${note.content}');
      return QuickNote.fromJson(response);
    } catch (e) {
      print('❌ Hızlı not ekleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının hızlı notlarını getir
  static Future<List<QuickNote>> getUserQuickNotes({
    bool? isProcessed,
    int limit = 50,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      List<dynamic> response;
      
      if (isProcessed != null) {
        response = await Supabase.instance.client
            .from(_tableName)
            .select()
            .eq('user_id', user.id)
            .eq('is_processed', isProcessed)
            .order('created_at', ascending: false)
            .limit(limit);
      } else {
        response = await Supabase.instance.client
            .from(_tableName)
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      final notes = response
          .map((json) => QuickNote.fromJson(json))
          .toList();

      print('📝 ${notes.length} hızlı not getirildi');
      return notes;
    } catch (e) {
      print('❌ Hızlı notları getirme hatası: $e');
      return [];
    }
  }

  /// Hızlı notu işleme dönüştürüldü olarak işaretle
  static Future<void> markNoteAsProcessed({
    required String noteId,
    required String transactionId,
  }) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .update({
            'is_processed': true,
            'processed_transaction_id': transactionId,
          })
          .eq('id', noteId);

      print('✅ Not işleme dönüştürüldü: $noteId -> $transactionId');
    } catch (e) {
      print('❌ Not güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Hızlı notu sil
  static Future<void> deleteQuickNote(String noteId) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', noteId);

      print('🗑️ Hızlı not silindi: $noteId');
    } catch (e) {
      print('❌ Hızlı not silme hatası: $e');
      rethrow;
    }
  }

  /// İşlenmemiş notları getir
  static Future<List<QuickNote>> getPendingNotes() async {
    return getUserQuickNotes(isProcessed: false);
  }

  /// Hızlı notu işlenmiş olarak işaretle (basit versiyon)
  static Future<void> markAsProcessed(String noteId) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .update({
            'is_processed': true,
          })
          .eq('id', noteId);

      print('✅ Not işlenmiş olarak işaretlendi: $noteId');
    } catch (e) {
      print('❌ Not güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Hızlı notu güncelle
  static Future<void> updateQuickNote(
    String noteId, {
    String? content,
    bool? isProcessed,
    String? imagePath,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (content != null) updateData['content'] = content;
      if (isProcessed != null) updateData['is_processed'] = isProcessed;
      if (imagePath != null) updateData['image_path'] = imagePath;
      
      if (updateData.isEmpty) {
        print('⚠️ Güncelleme için veri yok');
        return;
      }

      await Supabase.instance.client
          .from(_tableName)
          .update(updateData)
          .eq('id', noteId);

      print('✅ Not güncellendi: $noteId');
    } catch (e) {
      print('❌ Not güncelleme hatası: $e');
      rethrow;
    }
  }
} 