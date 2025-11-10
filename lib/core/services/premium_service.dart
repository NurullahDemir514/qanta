import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

/// Premium (Reklamsız) Servis
/// In-App Purchase ile premium satın alma işlemleri
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();
  
  // Callback for when premium status changes (for UnifiedProviderV2)
  Function()? onPremiumStatusChanged;

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
  static const int maxFreeAIRequests = 10; // Free kullanıcılar günlük 10 AI isteği yapabilir
  
  // Premium version limits
  static const int maxPremiumAIRequests = 1500; // Premium kullanıcılar aylık 1500 AI isteği yapabilir
  
  // Premium Plus version limits  
  static const int maxPremiumPlusAIRequests = 3000; // Premium Plus kullanıcılar aylık 3000 AI isteği yapabilir
  
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
  
  /// Firebase'den gerçek kart sayısını al (cache sorununu çözer)
  Future<int> getCurrentCardCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      
      final firestore = FirebaseFirestore.instance;
      
      // Accounts collection'dan AKTIF kart sayısını say (debit + credit)
      final accountsSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('is_active', isEqualTo: true) // ✅ Sadece aktif kartları say
          .where('type', whereIn: ['credit', 'debit']) // ✅ Backend ile aynı type değerleri
          .get(const GetOptions(source: Source.server)); // Server'dan al
      
      final count = accountsSnapshot.docs.length;
      
      // 🔍 DEBUG: Kartların detaylarını göster
      if (count > 0) {
        debugPrint('🔍 PremiumService: Found $count cards:');
        for (var doc in accountsSnapshot.docs) {
          final data = doc.data();
          debugPrint('   - ${doc.id}: ${data['name']} (${data['type']})');
        }
      } else {
        debugPrint('🔢 PremiumService: No cards found in Firebase');
      }
      
      debugPrint('🔢 PremiumService: Current card count from Firebase: $count (debit + credit)');
      return count;
    } catch (e) {
      debugPrint('❌ PremiumService: Error getting card count: $e');
      return 0; // Hata durumunda 0 döndür (güvenli taraf)
    }
  }
  
  /// Firebase'den gerçek hisse sayısını al (cache sorununu çözer)
  Future<int> getCurrentStockCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      
      final firestore = FirebaseFirestore.instance;
      
      // Stock positions'dan aktif hisse sayısını say
      final stocksSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('stock_positions')
          .where('totalQuantity', isGreaterThan: 0)
          .get(const GetOptions(source: Source.server)); // Server'dan al
      
      final count = stocksSnapshot.docs.length;
      debugPrint('🔢 PremiumService: Current stock count from Firebase: $count');
      return count;
    } catch (e) {
      debugPrint('❌ PremiumService: Error getting stock count: $e');
      return 0; // Hata durumunda 0 döndür (güvenli taraf)
    }
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
  
  /// AI limiti kontrolü
  /// Returns true if can use more AI
  bool canUseAI(int currentAICount) {
    final limit = _getAILimit();
    return currentAICount < limit;
  }
  
  /// Kalan AI isteği sayısı
  int getRemainingAI(int currentAICount) {
    final limit = _getAILimit();
    return limit - currentAICount;
  }
  
  /// AI limit sayısını getir (internal)
  int _getAILimit() {
    if (isPremiumPlus) return maxPremiumPlusAIRequests; // 3000/ay
    if (isPremium) return maxPremiumAIRequests; // 1500/ay
    return maxFreeAIRequests; // 10/gün
  }
  
  /// AI limit sayısını getir (public)
  int getAILimit() {
    return _getAILimit();
  }
  
  /// Firebase'den AI kullanım sayısını al (cache sorununu çözer)
  /// Free: günlük 10, Premium: aylık 1500, Premium Plus: aylık 3000
  Future<Map<String, int>> getCurrentAIUsage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'current': 0, 'limit': _getAILimit()};
      
      final firestore = FirebaseFirestore.instance;
      
      // Free kullanıcılar için günlük, Premium için aylık kontrol
      final docId = isPremium ? 'monthly' : 'daily';
      
      // ai_usage document'ını al
      final usageDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_usage')
          .doc(docId)
          .get(const GetOptions(source: Source.server)); // Server'dan al
      
      if (!usageDoc.exists) {
        final limit = _getAILimit();
        debugPrint('🤖 PremiumService: AI usage doc not found, count=0/$limit');
        return {'current': 0, 'limit': limit};
      }
      
      final data = usageDoc.data()!;
      final count = (data['count'] as num?)?.toInt() ?? 0;
      final lastReset = (data['lastReset'] as Timestamp?)?.toDate();
      
      final now = DateTime.now();
      bool needsReset = false;
      
      if (isPremium) {
        // Aylık reset kontrolü (Premium & Premium Plus)
        if (lastReset != null && 
            (lastReset.year != now.year || lastReset.month != now.month)) {
          needsReset = true;
        }
      } else {
        // Günlük reset kontrolü (Free)
        if (lastReset != null && 
            (lastReset.year != now.year || 
             lastReset.month != now.month || 
             lastReset.day != now.day)) {
          needsReset = true;
        }
      }
      
      if (needsReset) {
        final period = isPremium ? 'aylık' : 'günlük';
        debugPrint('🤖 PremiumService: AI usage reset ($period), count=0');
        return {'current': 0, 'limit': _getAILimit()};
      }
      
      final limit = _getAILimit();
      final period = isPremium ? 'aylık' : 'günlük';
      final planName = isPremiumPlus ? 'Premium Plus' : isPremium ? 'Premium' : 'Free';
      debugPrint('🤖 PremiumService: Current AI usage from Firebase: $count/$limit ($period - $planName)');
      return {
        'current': count,
        'limit': limit,
      };
    } catch (e) {
      debugPrint('❌ PremiumService: Error getting AI usage: $e');
      return {'current': 0, 'limit': _getAILimit()}; // Hata durumunda 0 döndür
    }
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
    
    // Premium durumunu Firebase'e senkronize et (UnifiedProviderV2 için)
    await _syncPremiumStatusToFirebase();
    
    // Geçmiş satın almaları kontrol et
    await _restorePurchases();
    
    debugPrint('✅ PremiumService: Initialized - isPremium: $_isPremium, isPremiumPlus: $_isPremiumPlus');
  }
  
  /// Premium durumunu Firebase'e senkronize et
  Future<void> _syncPremiumStatusToFirebase() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
              'isPremium': _isPremium,
              'isPremiumPlus': _isPremiumPlus,
              'isTestMode': _isTestMode,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        debugPrint('🔄 PremiumService: Premium status synced to Firebase: isPremium=$_isPremium, isPremiumPlus=$_isPremiumPlus, isTestMode=$_isTestMode');
      }
    } catch (e) {
      debugPrint('❌ PremiumService: Error syncing premium status to Firebase: $e');
    }
  }
  
  /// Premium durumunu yükle (SharedPreferences ve Firebase)
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      _isPremiumPlus = prefs.getBool(_premiumPlusKey) ?? false;
      debugPrint('📱 PremiumService: Loaded from storage - isPremium: $_isPremium, isPremiumPlus: $_isPremiumPlus');
      
      // 🧪 Firebase'den test mode kontrolü yap
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            _isTestMode = userData['isTestMode'] as bool? ?? false;
            if (_isTestMode) {
              debugPrint('🧪 PremiumService: Test mode enabled from Firebase');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ PremiumService: Failed to check test mode: $e');
        _isTestMode = false;
      }
    } catch (e) {
      debugPrint('❌ PremiumService: Error loading premium status: $e');
      _isPremium = false;
      _isPremiumPlus = false;
      _isTestMode = false;
    }
  }
  
  /// Premium durumunu kaydet
  Future<void> _savePremiumStatus(bool isPremium, {bool isPremiumPlus = false}) async {
    try {
      // Check if status actually changed
      final bool statusChanged = _isPremium != isPremium || _isPremiumPlus != isPremiumPlus;
      
      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      await prefs.setBool(_premiumPlusKey, isPremiumPlus);
      _isPremium = isPremium;
      _isPremiumPlus = isPremiumPlus;
      notifyListeners(); // UI'ı güncelle
      debugPrint('💾 PremiumService: Saved premium status: isPremium=$isPremium, isPremiumPlus=$isPremiumPlus');
      
      // Firebase'e de kaydet (UnifiedProviderV2 için)
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({
                'isPremium': isPremium,
                'isPremiumPlus': isPremiumPlus,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          debugPrint('💾 PremiumService: Premium status written to Firebase');
        }
      } catch (e) {
        debugPrint('❌ PremiumService: Error writing premium status to Firebase: $e');
      }
      
      // 🔔 NOTIFY: Premium status changed - trigger AI limit reload
      if (statusChanged) {
        debugPrint('🔔 PremiumService: Premium status changed, notifying listeners...');
        onPremiumStatusChanged?.call();
      }
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
  /// ⚠️ Premium field'lar client-side'dan yazılamaz, backend çağırılır
  Future<void> setTestPremium(bool isPremium) async {
    debugPrint('🧪 PremiumService: setTestPremium called with: $isPremium');
    debugPrint('🧪 PremiumService: Current state before: _isPremium=$_isPremium, _isPremiumPlus=$_isPremiumPlus, _isTestMode=$_isTestMode');
    
    try {
      // Backend'e çağrı yap (Firestore rules premium field'ları koruyor)
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('setTestMode');
      
      final result = await callable.call({
        'enabled': isPremium,
      });
      
      debugPrint('🧪 PremiumService: Backend response: ${result.data}');
      
      // Local state'i güncelle
      _isTestMode = isPremium;
      
      // Test mode aktifse Premium Plus olarak ele al
      if (isPremium) {
        await _savePremiumStatus(true, isPremiumPlus: true);
      } else {
        await _savePremiumStatus(false, isPremiumPlus: false);
      }
      
      // State değişti, callback'i tetikle
      debugPrint('🔔 PremiumService: Test mode changed, notifying listeners...');
      onPremiumStatusChanged?.call();
      debugPrint('🧪 PremiumService: Final state: _isPremium=$_isPremium, _isPremiumPlus=$_isPremiumPlus, _isTestMode=$_isTestMode');
    } catch (e) {
      debugPrint('❌ PremiumService: Error setting test mode: $e');
      rethrow;
    }
  }
  
  /// Activate premium from points (1 month)
  /// Called when user redeems points for premium
  static Future<void> activatePremiumFromPoints(String userId, int months) async {
    try {
      debugPrint('🎁 PremiumService: Activating premium from points for $months month(s)');
      
      // Calculate expiration date
      final now = DateTime.now();
      final expirationDate = now.add(Duration(days: 30 * months));
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'isPremium': true,
            'isPremiumPlus': false,
            'premiumExpiresAt': expirationDate.toIso8601String(),
            'premiumSource': 'points',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      // Update local state
      final instance = PremiumService();
      await instance._savePremiumStatus(true, isPremiumPlus: false);
      
      debugPrint('✅ PremiumService: Premium activated from points');
    } catch (e) {
      debugPrint('❌ PremiumService: Error activating premium from points: $e');
      rethrow;
    }
  }

  /// Activate premium plus from points (1 month)
  /// Called when user redeems points for premium plus
  static Future<void> activatePremiumPlusFromPoints(String userId, int months) async {
    try {
      debugPrint('🎁 PremiumService: Activating premium plus from points for $months month(s)');
      
      // Calculate expiration date
      final now = DateTime.now();
      final expirationDate = now.add(Duration(days: 30 * months));
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'isPremium': true,
            'isPremiumPlus': true,
            'premiumExpiresAt': expirationDate.toIso8601String(),
            'premiumSource': 'points',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      // Update local state
      final instance = PremiumService();
      await instance._savePremiumStatus(true, isPremiumPlus: true);
      
      debugPrint('✅ PremiumService: Premium Plus activated from points');
    } catch (e) {
      debugPrint('❌ PremiumService: Error activating premium plus from points: $e');
      rethrow;
    }
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

