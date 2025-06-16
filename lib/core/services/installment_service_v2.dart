import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../../shared/models/models_v2.dart';

/// Service for managing installment transactions
class InstallmentServiceV2 {
  static SupabaseClient get _client => SupabaseManager.client;

  /// Get all installment transactions with progress
  static Future<List<InstallmentWithProgressModel>> getAllInstallments() async {
    try {
      final response = await _client
          .from('installment_summary')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallmentWithProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching installments: $e');
      rethrow;
    }
  }

  /// Get installment transaction by ID
  static Future<InstallmentTransactionModel?> getInstallmentById(String installmentId) async {
    try {
      final response = await _client
          .from('installment_transactions')
          .select('*')
          .eq('id', installmentId)
          .single();

      return InstallmentTransactionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching installment by ID: $e');
      return null;
    }
  }

  /// Get installment details for a specific installment transaction
  static Future<List<InstallmentDetailModel>> getInstallmentDetails(String installmentTransactionId) async {
    try {
      final response = await _client
          .from('installment_details')
          .select('*')
          .eq('installment_transaction_id', installmentTransactionId)
          .order('installment_number');

      return (response as List)
          .map((json) => InstallmentDetailModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching installment details: $e');
      rethrow;
    }
  }

  /// Create a new installment transaction using RPC function
  static Future<String> createInstallmentTransaction({
    required String sourceAccountId,
    required double totalAmount,
    required int count,
    required String description,
    String? categoryId,
    DateTime? startDate,
  }) async {
    try {
      final response = await _client.rpc('create_installment_transaction', params: {
        'p_source_account_id': sourceAccountId,
        'p_total_amount': totalAmount,
        'p_count': count,
        'p_description': description,
        'p_category_id': categoryId,
        'p_start_date': (startDate ?? DateTime.now()).toIso8601String(),
      });

      return response as String;
    } catch (e) {
      debugPrint('Error creating installment transaction: $e');
      rethrow;
    }
  }

  /// Pay an installment using RPC function
  static Future<String> payInstallment({
    required String installmentDetailId,
    DateTime? paymentDate,
  }) async {
    try {
      final response = await _client.rpc('pay_installment', params: {
        'p_installment_detail_id': installmentDetailId,
        'p_payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
      });

      return response as String;
    } catch (e) {
      debugPrint('Error paying installment: $e');
      rethrow;
    }
  }

  /// Get upcoming installments using RPC function
  static Future<List<Map<String, dynamic>>> getUpcomingInstallments({
    int daysAhead = 30,
  }) async {
    try {
      final response = await _client.rpc('get_upcoming_installments', params: {
        'p_days_ahead': daysAhead,
      });

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching upcoming installments: $e');
      rethrow;
    }
  }

  /// Get overdue installments
  static Future<List<InstallmentDetailModel>> getOverdueInstallments() async {
    try {
      final response = await _client
          .from('installment_details')
          .select('*')
          .eq('is_paid', false)
          .lt('due_date', DateTime.now().toIso8601String().split('T')[0])
          .order('due_date');

      return (response as List)
          .map((json) => InstallmentDetailModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching overdue installments: $e');
      rethrow;
    }
  }

  /// Get installments due soon (within 7 days)
  static Future<List<InstallmentDetailModel>> getInstallmentsDueSoon() async {
    try {
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      final response = await _client
          .from('installment_details')
          .select('*')
          .eq('is_paid', false)
          .gte('due_date', now.toIso8601String().split('T')[0])
          .lte('due_date', weekFromNow.toIso8601String().split('T')[0])
          .order('due_date');

      return (response as List)
          .map((json) => InstallmentDetailModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching installments due soon: $e');
      rethrow;
    }
  }

  /// Get installments by account
  static Future<List<InstallmentWithProgressModel>> getInstallmentsByAccount(String accountId) async {
    try {
      final response = await _client
          .from('installment_summary')
          .select('*')
          .eq('source_account_id', accountId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallmentWithProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching installments by account: $e');
      rethrow;
    }
  }

  /// Get active installments (not completed)
  static Future<List<InstallmentWithProgressModel>> getActiveInstallments() async {
    try {
      final allInstallments = await getAllInstallments();
      return allInstallments.where((installment) => !installment.isCompleted).toList();
    } catch (e) {
      debugPrint('Error fetching active installments: $e');
      rethrow;
    }
  }

  /// Get completed installments
  static Future<List<InstallmentWithProgressModel>> getCompletedInstallments() async {
    try {
      final allInstallments = await getAllInstallments();
      return allInstallments.where((installment) => installment.isCompleted).toList();
    } catch (e) {
      debugPrint('Error fetching completed installments: $e');
      rethrow;
    }
  }

  /// Update installment transaction details
  static Future<InstallmentTransactionModel> updateInstallmentTransaction({
    required String installmentId,
    String? description,
    String? categoryId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (description != null) updateData['description'] = description;
      if (categoryId != null) updateData['category_id'] = categoryId;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('installment_transactions')
          .update(updateData)
          .eq('id', installmentId)
          .select()
          .single();

      return InstallmentTransactionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating installment transaction: $e');
      rethrow;
    }
  }

  /// Cancel unpaid installments (mark as cancelled)
  static Future<void> cancelInstallmentTransaction(String installmentId) async {
    try {
      // Get unpaid installment details
      final details = await getInstallmentDetails(installmentId);
      final unpaidDetails = details.where((detail) => !detail.isPaid).toList();

      // Delete unpaid installment details
      for (final detail in unpaidDetails) {
        await _client
            .from('installment_details')
            .delete()
            .eq('id', detail.id);
      }

      // Update installment transaction as cancelled (you might want to add a status field)
      await _client
          .from('installment_transactions')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', installmentId);
    } catch (e) {
      debugPrint('Error cancelling installment transaction: $e');
      rethrow;
    }
  }

  /// Get installment statistics
  static Future<Map<String, dynamic>> getInstallmentStatistics() async {
    try {
      final allInstallments = await getAllInstallments();
      
      final totalInstallments = allInstallments.length;
      final activeInstallments = allInstallments.where((i) => !i.isCompleted).length;
      final completedInstallments = allInstallments.where((i) => i.isCompleted).length;
      final overdueInstallments = allInstallments.where((i) => i.hasOverduePayments).length;
      
      final totalAmount = allInstallments.fold<double>(0.0, (sum, i) => sum + i.totalAmount);
      final remainingAmount = allInstallments.fold<double>(0.0, (sum, i) => sum + i.remainingAmount);
      final paidAmount = totalAmount - remainingAmount;

      return {
        'totalInstallments': totalInstallments,
        'activeInstallments': activeInstallments,
        'completedInstallments': completedInstallments,
        'overdueInstallments': overdueInstallments,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'completionPercentage': totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0,
      };
    } catch (e) {
      debugPrint('Error fetching installment statistics: $e');
      return {
        'totalInstallments': 0,
        'activeInstallments': 0,
        'completedInstallments': 0,
        'overdueInstallments': 0,
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'remainingAmount': 0.0,
        'completionPercentage': 0.0,
      };
    }
  }

  /// Search installments by description
  static Future<List<InstallmentWithProgressModel>> searchInstallments({
    required String query,
  }) async {
    try {
      final response = await _client
          .from('installment_summary')
          .select('*')
          .ilike('description', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InstallmentWithProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching installments: $e');
      rethrow;
    }
  }
} 