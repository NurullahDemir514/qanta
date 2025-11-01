import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import '../../shared/utils/currency_utils.dart';

/// Bank Model - Firestore'dan gelen banka verisi
class BankModel {
  final String code;
  final String name;
  final List<int> gradientColors; // [color1, color2, color3] hex değerleri
  final int accentColor; // hex değeri
  final List<String>? supportedCountries; // Desteklenen ülkeler (ISO codes: TR, IN, PK, BD, SD, vb.)
  final int? priority; // Öncelik sırası (düşük sayı = yüksek öncelik)
  final bool isActive; // Aktif mi?

  BankModel({
    required this.code,
    required this.name,
    required this.gradientColors,
    required this.accentColor,
    this.supportedCountries,
    this.priority,
    this.isActive = true,
  });

  factory BankModel.fromMap(Map<String, dynamic> map) {
    return BankModel(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      gradientColors: List<int>.from(map['gradientColors'] ?? []),
      accentColor: map['accentColor'] ?? 0xFF1976D2,
      supportedCountries: map['supportedCountries'] != null
          ? List<String>.from(map['supportedCountries'])
          : null,
      priority: map['priority']?.toInt(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'gradientColors': gradientColors,
      'accentColor': accentColor,
      'supportedCountries': supportedCountries,
      'priority': priority,
      'isActive': isActive,
    };
  }

  /// Color list'e dönüştür
  List<Color> get gradientColorsList {
    return gradientColors.map((hex) => Color(hex)).toList();
  }

  Color get accentColorValue => Color(accentColor);
}

/// Dinamik Banka Servisi
/// Firestore'dan banka listesini çeker, cache'ler ve bölgesel öneriler yapar
class BankService {
  static final BankService _instance = BankService._internal();
  factory BankService() => _instance;
  BankService._internal();

  static const String _cacheKey = 'cached_banks';
  static const String _cacheTimestampKey = 'cached_banks_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24); // 24 saat cache

  List<BankModel> _banks = [];
  bool _isLoading = false;
  DateTime? _lastFetchTime;

  List<BankModel> get banks => _banks;
  bool get isLoading => _isLoading;

  /// Bankaları yükle (cache öncelikli)
  Future<void> loadBanks({bool forceRefresh = false}) async {
    if (_isLoading) {
      debugPrint('⏳ BankService: Already loading banks...');
      return;
    }

    // Cache kontrolü
    if (!forceRefresh && await _isCacheValid()) {
      await _loadFromCache();
      if (_banks.isNotEmpty) {
        debugPrint('✅ BankService: Loaded ${_banks.length} banks from cache');
        return;
      }
    }

    // Firestore'dan yükle
    await _loadFromFirestore();
  }

  /// Cache geçerli mi?
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference < _cacheExpiry && _banks.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Cache'den yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final banksJson = prefs.getString(_cacheKey);
      if (banksJson == null) return;

      final List<dynamic> banksList = json.decode(banksJson);
      _banks = banksList.map((b) => BankModel.fromMap(b)).toList();
      _lastFetchTime = DateTime.now();

      debugPrint('✅ BankService: Loaded ${_banks.length} banks from cache');
    } catch (e) {
      debugPrint('❌ BankService: Error loading from cache: $e');
      _banks = [];
    }
  }

  /// Firestore'dan yükle
  Future<void> _loadFromFirestore() async {
    _isLoading = true;
    try {
      debugPrint('📡 BankService: Loading banks from Firestore...');

      final banksRef = FirebaseFirestore.instance.collection('banks');
      final snapshot = await banksRef
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: false) // Öncelik sırasına göre
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ BankService: No banks found in Firestore, using static fallback');
        _loadStaticBanks();
        await _saveToCache();
        return;
      }

      _banks = snapshot.docs.map((doc) {
        final data = doc.data();
        return BankModel.fromMap({
          ...data,
          'code': data['code'] ?? doc.id,
        });
      }).toList();

      _lastFetchTime = DateTime.now();
      await _saveToCache();

      debugPrint('✅ BankService: Loaded ${_banks.length} banks from Firestore');
    } catch (e) {
      // Permission denied veya başka bir hata - Static fallback kullan
      final errorMessage = e.toString();
      if (errorMessage.contains('permission-denied') || 
          errorMessage.contains('PERMISSION_DENIED')) {
        debugPrint('⚠️ BankService: Firestore permission denied - Using static banks (this is normal if banks collection does not exist yet)');
      } else {
        debugPrint('❌ BankService: Error loading from Firestore: $e');
      }
      _loadStaticBanks(); // Fallback: Static bankalar
      await _saveToCache(); // Cache'e static bankaları kaydet
    } finally {
      _isLoading = false;
    }
  }

  /// Cache'e kaydet
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final banksJson = json.encode(
        _banks.map((b) => b.toMap()).toList(),
      );
      await prefs.setString(_cacheKey, banksJson);
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      debugPrint('✅ BankService: Saved ${_banks.length} banks to cache');
    } catch (e) {
      debugPrint('❌ BankService: Error saving to cache: $e');
    }
  }

  /// Static bankaları yükle (fallback)
  void _loadStaticBanks() {
    final staticBanks = AppConstants.getAvailableBanks();
    _banks = staticBanks.map((code) {
      final name = AppConstants.getBankName(code);
      final gradientColors = AppConstants.getBankGradientColors(code);
      final accentColor = AppConstants.getBankAccentColor(code);
      
      // Banka koduna göre ülke kodu belirle
      final supportedCountries = _getCountriesForBankCode(code);
      final priority = _getPriorityForBankCode(code);

      return BankModel(
        code: code,
        name: name,
        gradientColors: gradientColors.map((c) => c.value).toList(),
        accentColor: accentColor.value,
        supportedCountries: supportedCountries,
        priority: priority,
        isActive: true,
      );
    }).toList();

    debugPrint('✅ BankService: Loaded ${_banks.length} static banks (fallback)');
  }

  /// Banka koduna göre desteklenen ülke kodlarını döndür
  List<String> _getCountriesForBankCode(String bankCode) {
    final code = bankCode.toLowerCase();
    
    // Amerikan bankaları (önce kontrol et, çünkü citibank hem TR hem US olabilir)
    if (code.contains('bankofamerica') || code.contains('wellsfargo') || 
        code.contains('jpmorgan') || code.contains('chase') || code.contains('citibankus')) {
      return ['US'];
    }
    
    // Türk bankaları (citibank Türkiye için TR'ye dahil)
    if (code.contains('garanti') || code.contains('isbank') || code.contains('akbank') ||
        code.contains('ziraat') || code.contains('vakifbank') || code.contains('yapikredi') ||
        code.contains('kuveytturk') || code.contains('albaraka') || code.contains('qnb') ||
        code.contains('enpara') || code.contains('papara') || code.contains('turkiyefinans') ||
        code.contains('teb') || code.contains('hsbcturkiye') || code.contains('ing') ||
        code.contains('denizbank') || code.contains('anadolubank') || code.contains('halkbank') ||
        code.contains('turkishbank') || code.contains('fibabank') || code.contains('osmanli') ||
        code.contains('icbc') || code.contains('citibank') || code.contains('qanta')) {
      return ['TR'];
    }
    
    // Hint bankaları (India)
    if (code.contains('sbi') || code.contains('hdfc') || code.contains('icici') ||
        code.contains('axis') || code.contains('pnb') || code.contains('bob') ||
        code.contains('canara') || code.contains('union') || code.contains('idfc') ||
        code.contains('kotak') || code.contains('indian')) {
      return ['IN'];
    }
    
    // Pakistan bankaları
    if (code.contains('hbl') || code.contains('ubl') || code.contains('mcb') ||
        code.contains('allied') || code.contains('pakistan')) {
      return ['PK'];
    }
    
    // Bangladeş bankaları
    if (code.contains('sonalibank') || code.contains('janata') || code.contains('agrani') ||
        code.contains('rupali') || code.contains('bangladesh')) {
      return ['BD'];
    }
    
    // Sudan bankaları
    if (code.contains('bankofkhartoum') || code.contains('sudanese') || code.contains('sudan')) {
      return ['SD'];
    }
    
    // Default: Türkiye (çünkü çoğu banka Türk)
    return ['TR'];
  }

  /// Banka koduna göre öncelik değeri döndür
  int _getPriorityForBankCode(String bankCode) {
    final code = bankCode.toLowerCase();
    
    // Önemli Türk bankaları (yüksek öncelik)
    if (code.contains('garanti') || code.contains('isbank') || code.contains('akbank') ||
        code.contains('ziraat') || code.contains('yapikredi')) {
      return 1;
    }
    
    // Diğer Türk bankaları
    if (code.contains('vakifbank') || code.contains('qnb') || code.contains('teb') ||
        code.contains('denizbank') || code.contains('halkbank')) {
      return 2;
    }
    
    // Diğerleri
    return 3;
  }

  /// Kullanılabilir bankaları getir (bölgesel filtreleme ve para birimi önceliklendirmesi ile)
  /// 
  /// [countryCode] - Filtreleme için ülke kodu (opsiyonel)
  /// [currency] - Para birimi (opsiyonel, önceliklendirme için kullanılır)
  List<BankModel> getAvailableBanks({
    String? countryCode,
    dynamic currency,
  }) {
    if (_banks.isEmpty) {
      _loadStaticBanks();
    }

    var filtered = _banks.where((b) => b.isActive).toList();

    // Bölgesel filtreleme
    if (countryCode != null) {
      filtered = filtered.where((b) {
        // Eğer supportedCountries yoksa veya boşsa, tüm bankaları göster
        if (b.supportedCountries == null || b.supportedCountries!.isEmpty) {
          return true;
        }
        return b.supportedCountries!.contains(countryCode.toUpperCase());
      }).toList();
    }

    // Para birimine göre önceliklendirme
    if (currency != null) {
      try {
        // Currency enum kontrolü
        if (currency is Currency) {
          final preferredCountries = CurrencyUtils.getCountryCodesForCurrency(currency);
          debugPrint('🎯 BankService: Prioritizing banks for currency ${currency.code}, preferred countries: $preferredCountries');
          
          filtered.sort((a, b) {
            // ÖNCE para birimi ile uyumluluğa göre (bu en önemli!)
            final aMatches = a.supportedCountries != null && 
                           a.supportedCountries!.isNotEmpty &&
                           a.supportedCountries!.any((c) => preferredCountries.contains(c.toUpperCase()));
            final bMatches = b.supportedCountries != null && 
                           b.supportedCountries!.isNotEmpty &&
                           b.supportedCountries!.any((c) => preferredCountries.contains(c.toUpperCase()));
            
            // Para birimi uyumlu olanlar önce gelsin
            if (aMatches && !bMatches) return -1; // a önce (uyumlu)
            if (!aMatches && bMatches) return 1;  // b önce (uyumlu)
            
            // Her ikisi de uyumlu veya uyumsuz ise, priority'ye göre sırala
            final priorityA = a.priority ?? 999;
            final priorityB = b.priority ?? 999;
            return priorityA.compareTo(priorityB);
          });
        }
      } catch (e) {
        debugPrint('⚠️ BankService: Error prioritizing by currency: $e');
      }
    }

    // Öncelik sırasına göre sırala (eğer currency yoksa)
    if (currency == null) {
      filtered.sort((a, b) {
        final priorityA = a.priority ?? 999;
        final priorityB = b.priority ?? 999;
        return priorityA.compareTo(priorityB);
      });
    }

    return filtered;
  }

  /// Banka kodu ile banka bul
  BankModel? getBankByCode(String code) {
    try {
      return _banks.firstWhere((b) => b.code.toLowerCase() == code.toLowerCase());
    } catch (e) {
      // Fallback: Static bankadan al
      if (AppConstants.getAvailableBanks().contains(code)) {
        final name = AppConstants.getBankName(code);
        final gradientColors = AppConstants.getBankGradientColors(code);
        final accentColor = AppConstants.getBankAccentColor(code);

        return BankModel(
          code: code,
          name: name,
          gradientColors: gradientColors.map((c) => c.value).toList(),
          accentColor: accentColor.value,
          isActive: true,
        );
      }
      return null;
    }
  }

  /// Banka adı ile arama
  List<BankModel> searchBanks(String query) {
    if (query.isEmpty) return getAvailableBanks();

    final queryLower = query.toLowerCase();
    return _banks.where((b) {
      return b.name.toLowerCase().contains(queryLower) ||
          b.code.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _banks = [];
      _lastFetchTime = null;
      debugPrint('✅ BankService: Cache cleared');
    } catch (e) {
      debugPrint('❌ BankService: Error clearing cache: $e');
    }
  }

  /// İlk yükleme - Uygulama başlangıcında çağrılır
  Future<void> initialize() async {
    debugPrint('🎬 BankService: Initializing...');
    await loadBanks(forceRefresh: false);
  }
}

