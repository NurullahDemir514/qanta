import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/analytics_consent_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import 'analytics_consent_service.dart';

/// Anonim veri toplama servisi
/// Single Responsibility: Sadece anonim veri toplar ve Firebase'e gönderir
class AnonymousAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'anonymous_analytics';
  static const Uuid _uuid = Uuid();
  
  /// Anonim kullanıcı ID'si oluştur veya al
  static String _getAnonymousId() {
    // Her kullanıcı için unique ama anonim bir ID
    return _uuid.v4();
  }
  
  /// Harcama işlemini anonim olarak kaydet
  static Future<void> trackExpense(TransactionModelV2 transaction) async {
    try {
      // İzin kontrolü
      final hasConsent = await AnalyticsConsentService.isConsentGiven();
      if (!hasConsent) {
        debugPrint('📊 Analytics: No consent given, skipping tracking');
        return;
      }
      
      // Sadece harcamaları topla
      if (transaction.type != TransactionType.expense) {
        return;
      }
      
      debugPrint('🔍 Analytics Debug - Transaction Type: ${transaction.runtimeType}');
      
      // Kategori adını al (TransactionWithDetailsV2 ise categoryName var)
      String categoryName = 'unknown';
      bool isInstallment = false;
      int? installmentCount;
      double? monthlyAmount;
      double? totalInstallmentAmount;
      
      if (transaction is TransactionWithDetailsV2) {
        categoryName = transaction.categoryName ?? 'unknown';
        
        debugPrint('🔍 Analytics Debug - TransactionWithDetailsV2:');
        debugPrint('   installmentId: ${transaction.installmentId}');
        debugPrint('   isInstallment field: ${transaction.isInstallment}');
        debugPrint('   installmentCount: ${transaction.installmentCount}');
        debugPrint('   amount: ${transaction.amount}');
        debugPrint('   description: ${transaction.description}');
        
        // Taksitli mi kontrol et - installmentId veya isInstallment field'ından
        isInstallment = transaction.installmentId != null || transaction.isInstallment;
        installmentCount = transaction.installmentCount;
        
        debugPrint('🔍 Analytics Debug - Calculated:');
        debugPrint('   isInstallment: $isInstallment');
        debugPrint('   installmentCount: $installmentCount');
        
        // Taksitli ise tutarları hesapla
        if (isInstallment && installmentCount != null && installmentCount > 0) {
          // transaction.amount taksitli işlemlerde TOPLAM tutar olarak geliyor
          totalInstallmentAmount = transaction.amount; // Zaten toplam
          monthlyAmount = transaction.amount / installmentCount; // Aylık hesapla
          debugPrint('   totalInstallmentAmount: $totalInstallmentAmount');
          debugPrint('   monthlyAmount: $monthlyAmount');
        }
      }
      
      final anonymousData = AnonymousExpenseData(
        anonymousId: _getAnonymousId(),
        amount: transaction.amount.abs(),
        category: categoryName, // Kategori ADI (text) olarak kaydediliyor
        transactionDate: transaction.transactionDate,
        description: null, // Gizlilik için description ekleme
        isInstallment: isInstallment,
        installmentCount: installmentCount,
        monthlyAmount: monthlyAmount,
        totalInstallmentAmount: totalInstallmentAmount,
      );
      
      final jsonData = anonymousData.toJson();
      debugPrint('🔍 Analytics JSON: $jsonData');
      
      await _firestore
          .collection(_collectionName)
          .doc() // Auto-generated ID
          .set(jsonData);
      
      if (isInstallment) {
        debugPrint('📊 Analytics: Installment expense tracked - Category: $categoryName, Monthly: $monthlyAmount, Installments: $installmentCount, Total: $totalInstallmentAmount');
      } else {
        debugPrint('📊 Analytics: Expense tracked - Category: $categoryName, Amount: ${transaction.amount}');
      }
    } catch (e) {
      debugPrint('❌ Analytics Error: $e');
      // Hata olsa bile uygulamayı etkilemesin
    }
  }
  
  /// Toplu harcamaları kaydet
  static Future<void> trackExpenses(List<TransactionModelV2> transactions) async {
    try {
      // İzin kontrolü
      final hasConsent = await AnalyticsConsentService.isConsentGiven();
      if (!hasConsent) {
        debugPrint('📊 Analytics: No consent given, skipping bulk tracking');
        return;
      }
      
      // Sadece harcamaları filtrele
      final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
      
      if (expenses.isEmpty) return;
      
      // Batch write kullan (daha performanslı)
      final batch = _firestore.batch();
      
      for (final expense in expenses) {
        // Kategori adını ve taksit bilgilerini al
        String categoryName = 'unknown';
        bool isInstallment = false;
        int? installmentCount;
        double? monthlyAmount;
        double? totalInstallmentAmount;
        
        if (expense is TransactionWithDetailsV2) {
          categoryName = expense.categoryName ?? 'unknown';
          
          // Taksitli mi kontrol et - installmentId veya isInstallment field'ından
          isInstallment = expense.installmentId != null || expense.isInstallment;
          installmentCount = expense.installmentCount;
          
          // Taksitli ise tutarları hesapla
          if (isInstallment && installmentCount != null && installmentCount > 0) {
            totalInstallmentAmount = expense.amount; // Zaten toplam
            monthlyAmount = expense.amount / installmentCount; // Aylık hesapla
          }
        }
        
        final anonymousData = AnonymousExpenseData(
          anonymousId: _getAnonymousId(),
          amount: expense.amount.abs(),
          category: categoryName, // Kategori ADI (text) olarak kaydediliyor
          transactionDate: expense.transactionDate,
          description: null,
          isInstallment: isInstallment,
          installmentCount: installmentCount,
          monthlyAmount: monthlyAmount,
          totalInstallmentAmount: totalInstallmentAmount,
        );
        
        final docRef = _firestore.collection(_collectionName).doc();
        batch.set(docRef, anonymousData.toJson());
      }
      
      await batch.commit();
      debugPrint('📊 Analytics: ${expenses.length} expenses tracked anonymously');
    } catch (e) {
      debugPrint('❌ Analytics Bulk Error: $e');
    }
  }
  
  /// İzin iptal edildiğinde veri toplamayı durdur
  static Future<void> stopTracking() async {
    debugPrint('📊 Analytics: Tracking stopped by user');
    await AnalyticsConsentService.saveConsent(false);
  }
}

