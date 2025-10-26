import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Premium (Reklamsız) Servis
/// In-App Purchase ile premium satın alma işlemleri
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // Abonelik ürün ID'leri - Premium
  static const String _monthlySubscriptionId = 'qanta_premium_monthly';
  static const String _yearlySubscriptionId = 'qanta_premium_yearly';
  
  // Abonelik ürün ID'leri - Premium Plus
  static const String _monthlyPlusSubscriptionId = 'qanta_premium_plus_monthly';
  static const String _yearlyPlusSubscriptionId = 'qanta_premium_plus_yearly';
  
  static const String _premiumKey = 'is_premium_user';
  static const String _premiumPlusKey = 'is_premium_plus_user';
  
  // Free version limits
  static const int maxFreeCards = 3; // Free kullanıcılar max 3 kart ekleyebilir (debit + credit toplam)
  static const int maxFreeStocks = 3; // Free kullanıcılar max 3 hisse ekleyebilir
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  bool _isPremium = false;
  bool _isPremiumPlus = false;
  bool _isTestMode = false; // Test modu için
  bool get isPremium => _isPremium || _isPremiumPlus || _isTestMode; // Test modu da premium sayılacak
  bool get isPremiumPlus => _isPremiumPlus || _isTestMode; // Premium Plus kontrolü
  
  /// Free kullanıcı için kart limiti kontrolü
  /// Returns true if can add more cards
  bool canAddCard(int currentCardCount) {
    if (isPremium) return true; // Premium veya test modu kullanıcıları sınırsız
    return currentCardCount < maxFreeCards; // Free kullanıcılar max 3
  }
  
  /// Kalan kart sayısı (sadece free kullanıcılar için)
  int getRemainingCards(int currentCardCount) {
    if (isPremium) return -1; // -1 = unlimited
    return maxFreeCards - currentCardCount;
  }
  
  /// Free kullanıcı için hisse limiti kontrolü
  /// Returns true if can add more stocks
  bool canAddStock(int currentStockCount) {
    if (isPremium) return true; // Premium veya test modu kullanıcıları sınırsız
    return currentStockCount < maxFreeStocks; // Free kullanıcılar max 3
  }
  
  /// Kalan hisse sayısı (sadece free kullanıcılar için)
  int getRemainingStocks(int currentStockCount) {
    if (isPremium) return -1; // -1 = unlimited
    return maxFreeStocks - currentStockCount;
  }
  
  /// Servisi başlat
  Future<void> initialize() async {
    debugPrint('🔐 PremiumService: Initializing...');
    
    // Satın alma dinleyicisini başlat
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint('❌ PremiumService: Purchase stream error: $error');
      },
    );
    
    // Kaydedilmiş premium durumunu yükle
    await _loadPremiumStatus();
    
    // Geçmiş satın almaları kontrol et
    await _restorePurchases();
    
    debugPrint('✅ PremiumService: Initialized - isPremium: $_isPremium');
  }
  
  /// Premium durumunu yükle (SharedPreferences)
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      _isPremiumPlus = prefs.getBool(_premiumPlusKey) ?? false;
      debugPrint('📱 PremiumService: Loaded from storage - isPremium: $_isPremium, isPremiumPlus: $_isPremiumPlus');
    } catch (e) {
      debugPrint('❌ PremiumService: Error loading premium status: $e');
      _isPremium = false;
      _isPremiumPlus = false;
    }
  }
  
  /// Premium durumunu kaydet
  Future<void> _savePremiumStatus(bool isPremium, {bool isPremiumPlus = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      await prefs.setBool(_premiumPlusKey, isPremiumPlus);
      _isPremium = isPremium;
      _isPremiumPlus = isPremiumPlus;
      notifyListeners(); // UI'ı güncelle
      debugPrint('💾 PremiumService: Saved premium status: isPremium=$isPremium, isPremiumPlus=$isPremiumPlus');
    } catch (e) {
      debugPrint('❌ PremiumService: Error saving premium status: $e');
    }
  }
  
  /// Geçmiş satın almaları geri yükle
  Future<void> _restorePurchases() async {
    try {
      debugPrint('🔄 PremiumService: Restoring purchases...');
      
      // Mevcut premium durumunu kaydet
      final wasPremium = _isPremium;
      
      // Restore işlemi başlat
      await _inAppPurchase.restorePurchases();
      
      // 3 saniye bekle (Google Play'den yanıt gelmesi için)
      await Future.delayed(const Duration(seconds: 3));
      
      // Eğer önceden premium idiyse ama restore'dan sonra hala premium değilse
      // muhtemelen abonelik iptal edilmiş veya süresi dolmuş
      if (wasPremium && !_isPremium) {
        debugPrint('⚠️ PremiumService: No active subscription found - Removing premium');
        await _savePremiumStatus(false);
      }
    } catch (e) {
      debugPrint('❌ PremiumService: Error restoring purchases: $e');
    }
  }
  
  /// Satın alma güncellemelerini dinle
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('📦 PremiumService: Purchase update received - ${purchaseDetailsList.length} items');
    
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('   Product: ${purchaseDetails.productID}');
      debugPrint('   Status: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Premium veya Premium Plus aboneliği satın alındı veya geri yüklendi
        if (purchaseDetails.productID == _monthlySubscriptionId ||
            purchaseDetails.productID == _yearlySubscriptionId ||
            purchaseDetails.productID == _monthlyPlusSubscriptionId ||
            purchaseDetails.productID == _yearlyPlusSubscriptionId) {
          _verifyAndDeliverProduct(purchaseDetails);
        }
      }
      
      // İptal kontrolü
      if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('⚠️ PremiumService: Subscription canceled');
        if (purchaseDetails.productID == _monthlySubscriptionId ||
            purchaseDetails.productID == _yearlySubscriptionId) {
          _savePremiumStatus(false); // Premium durumunu kapat
        } else if (purchaseDetails.productID == _monthlyPlusSubscriptionId ||
            purchaseDetails.productID == _yearlyPlusSubscriptionId) {
          _savePremiumStatus(false, isPremiumPlus: false); // Premium Plus durumunu kapat
        }
      }
      
      if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('❌ PremiumService: Purchase error: ${purchaseDetails.error}');
      }
      
      // Satın alma işlemini tamamla
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// Ürünü doğrula ve teslim et
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    debugPrint('✅ PremiumService: Verifying and delivering product');
    
    // Premium Plus kontrolü
    final bool isPlusProduct = purchaseDetails.productID == _monthlyPlusSubscriptionId ||
        purchaseDetails.productID == _yearlyPlusSubscriptionId;
    
    if (isPlusProduct) {
      // Premium Plus satın alındı
      await _savePremiumStatus(true, isPremiumPlus: true);
      debugPrint('🎉 Premium Plus aktif edildi!');
    } else {
      // Normal Premium satın alındı
      await _savePremiumStatus(true, isPremiumPlus: false);
      debugPrint('🎉 Premium aktif edildi!');
    }
  }
  
  /// Premium abonelik satın al
  /// [isYearly] - true ise yıllık, false ise aylık abonelik
  /// [isPremiumPlus] - true ise Premium Plus, false ise Premium
  Future<bool> purchasePremium({bool isYearly = false, bool isPremiumPlus = false}) async {
    try {
      // Abonelik türünü seç
      String subscriptionId;
      if (isPremiumPlus) {
        subscriptionId = isYearly ? _yearlyPlusSubscriptionId : _monthlyPlusSubscriptionId;
      } else {
        subscriptionId = isYearly ? _yearlySubscriptionId : _monthlySubscriptionId;
      }
      
      final tierName = isPremiumPlus ? "PREMIUM PLUS" : "PREMIUM";
      final periodName = isYearly ? "YEARLY" : "MONTHLY";
      
      debugPrint('💳 PremiumService: Starting subscription purchase...');
      debugPrint('📦 PremiumService: Tier: $tierName');
      debugPrint('📅 PremiumService: Period: $periodName');
      debugPrint('🆔 PremiumService: ID: $subscriptionId');
      
      // In-app purchase mevcut mu kontrol et
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('❌ PremiumService: In-app purchase not available');
        return false;
      }
      
      // Abonelik detaylarını al
      final Set<String> kIds = {subscriptionId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('❌ PremiumService: Subscription not found: ${response.notFoundIDs}');
        debugPrint('💡 TIP: Play Console\'da abonelik oluşturun ve Aktif edin!');
        return false;
      }
      
      if (response.productDetails.isEmpty) {
        debugPrint('❌ PremiumService: No subscription details found');
        return false;
      }
      
      // Abonelik satın alma işlemini başlat
      final ProductDetails productDetails = response.productDetails.first;
      debugPrint('🛒 PremiumService: Subscription found - ${productDetails.title}');
      debugPrint('💰 PremiumService: Price - ${productDetails.price}');
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      debugPrint('📱 PremiumService: Subscription purchase initiated: $success');
      return success;
    } catch (e) {
      debugPrint('❌ PremiumService: Subscription purchase error: $e');
      return false;
    }
  }
  
  /// Premium satın almaları geri yükle (kullanıcı restore butonu için)
  Future<void> restorePurchases() async {
    await _restorePurchases();
  }
  
  /// Servisi temizle
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  /// Test için premium durumunu manuel ayarla (sadece development)
  /// Test modu için premium durumunu manuel ayarla
  Future<void> setTestPremium(bool isPremium) async {
    debugPrint('🧪 PremiumService: setTestPremium called with: $isPremium');
    debugPrint('🧪 PremiumService: Current isPremium before: $_isPremium');
    
    // Local state'i güncelle
    _isTestMode = isPremium;
    await _savePremiumStatus(isPremium);
    
    // Firebase'e de yaz (backend için)
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({'isTestMode': isPremium}, SetOptions(merge: true));
        debugPrint('🧪 PremiumService: isTestMode written to Firebase: $isPremium');
      }
    } catch (e) {
      debugPrint('❌ PremiumService: Error writing isTestMode to Firebase: $e');
    }
    
    debugPrint('🧪 PremiumService: Current isPremium after: $_isPremium');
    debugPrint('🧪 PremiumService: notifyListeners() called');
  }
  
  /// Test kullanıcıları için premium durumunu tamamen sıfırla
  /// SharedPreferences'tan da siler ve restore purchases çağırır
  Future<void> resetPremiumStatus() async {
    try {
      debugPrint('🔄 PremiumService: Resetting premium status...');
      
      // SharedPreferences'tan premium durumunu sil
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_premiumKey);
      
      // Local state'i güncelle
      _isPremium = false;
      _isTestMode = false;
      notifyListeners();
      
      // Firebase'den test modu da kaldır
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({'isTestMode': false}, SetOptions(merge: true));
          debugPrint('🔄 PremiumService: isTestMode reset in Firebase');
        }
      } catch (e) {
        debugPrint('❌ PremiumService: Error resetting isTestMode in Firebase: $e');
      }
      
      // Google Play'den restore yap (aktif abonelik varsa tekrar aktif olur)
      await _restorePurchases();
      
      debugPrint('✅ PremiumService: Premium status reset complete');
    } catch (e) {
      debugPrint('❌ PremiumService: Error resetting premium status: $e');
    }
  }
}

