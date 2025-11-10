import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ai/firebase_ai_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../shared/widgets/ai_limit_indicator.dart';
import '../../../shared/models/transaction_model_v2.dart';
import '../../../shared/models/unified_category_model.dart';
import '../../../shared/models/stock_models.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/utils/fab_positioning.dart';
import '../../../shared/utils/currency_utils.dart';
import 'bulk_transaction_chat_view.dart';
import 'account_selection_message.dart';
import 'installment_selection_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../stocks/providers/stock_provider.dart';
import '../../../shared/widgets/animated_typing_message.dart';

// ==================== DEBUG CONFIG ====================
// Production'da token bilgisini görmek için email veya UID ekleyin
const List<String> _debugTokenEmails = [
  't5@gmail.com',
  't6@gmail.com',
  't7@gmail.com',
  't8@gmail.com',
  't9@gmail.com',
  't10@gmail.com',
  't11@gmail.com',
  't12@gmail.com',
  't13@gmail.com',
  't14@gmail.com',
  't15@gmail.com',
  // Daha fazla email ekleyebilirsiniz
];
const List<String> _debugTokenUids = [
  // 'uid123456', // UID ile de kontrol edebilirsiniz
];

/// Token bilgisini göstermek için kontrol
bool _shouldShowTokenInfo() {
  if (kDebugMode) return true; // Debug modda her zaman göster
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Email kontrolü
    if (user.email != null && _debugTokenEmails.contains(user.email)) {
      return true;
    }
    
    // UID kontrolü
    if (_debugTokenUids.contains(user.uid)) {
      return true;
    }
    
    return false;
  } catch (e) {
    return false;
  }
}
// ==================== END DEBUG CONFIG ====================

// Kart ismini temizle ve localize et
String _getLocalizedAccountName(AccountModel account, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  // CASH_WALLET özel durumu
  if (account.name == 'CASH_WALLET') {
    return l10n.cashWallet;
  }
  
  // Localized card type
  final localizedCardType = account.type == AccountType.credit 
      ? l10n.creditCard 
      : account.type == AccountType.debit 
          ? l10n.debitCard 
          : l10n.cash;
  
  // Remove card type phrases in any language from account name
  String cleanName = account.name
      .replaceAll(RegExp(r'\s*(Credit Card|Kredi Kartı|Debit Card|Banka Kartı|Cash|Nakit)\s*$', caseSensitive: false), '')
      .trim();
  
  // If nothing left after cleaning, use bank name or just card type
  if (cleanName.isEmpty) {
    return account.bankName != null && account.bankName!.isNotEmpty
        ? '${account.bankName} $localizedCardType'
        : localizedCardType;
  }
  
  // Return cleaned name + localized card type
  return '$cleanName $localizedCardType';
}

/// Quick Add Chat FAB - AI ile konuşarak işlem ekleme
/// 
/// Kullanıcı AI ile doğal konuşma yaparak transaction ekler
class QuickAddChatFAB extends StatefulWidget {
  final double? customLeft;
  final double? customRight;
  final double? customBottom;
  final Key? tutorialKey; // Tutorial için key
  
  const QuickAddChatFAB({
    super.key,
    this.customLeft,
    this.customRight,
    this.customBottom,
    this.tutorialKey,
  });

  @override
  State<QuickAddChatFAB> createState() => _QuickAddChatFABState();
}

class _QuickAddChatFABState extends State<QuickAddChatFAB> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FirebaseAIService _aiService = FirebaseAIService();
  
  bool _isExpanded = false;
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false); // ValueNotifier for child rebuild
  late AnimationController _animController;
  
  // Chat messages
  final List<Map<String, dynamic>> _chatMessages = [];
  final List<Map<String, String>> _conversationHistory = [];
  final ValueNotifier<int> _messagesUpdateTrigger = ValueNotifier<int>(0); // Trigger rebuild
  
  // Timestamp tracking for streaming effect (yeni AI mesajları için)
  DateTime? _lastAIMessageTimestamp;
  int _lastAnimatedMessageIndex = -1; // Son animasyonlu mesajın index'i
  
  // AI Usage tracking - Günlük limit (yeni sistem, UI'da gösterilecek)
  int _dailyUsage = 0;
  int _dailyLimit = 0; // Firebase'den yüklenecek (Free: 10, Premium: 75)
  int _dailyRemaining = 0;
  int _bonusCount = 0; // Reklamla kazanılan bonus
  bool _bonusAvailable = false; // Daha bonus kazanılabilir mi?
  int _maxBonus = 15; // Maksimum bonus
  
  // AI Usage tracking - Aylık limit (eski sistem - backup)
  int _monthlyUsage = 0;
  int _monthlyLimit = 100000;
  int _monthlyRemaining = 100000;
  
  // Pending transaction confirmation
  Map<String, dynamic>? _pendingTransactionData;
  final ValueNotifier<bool> _isWaitingConfirmation = ValueNotifier<bool>(false);
  
  // Pending bulk delete confirmation
  Map<String, dynamic>? _pendingBulkDeleteFilters;
  final ValueNotifier<bool> _isWaitingBulkDeleteConfirmation = ValueNotifier<bool>(false);
  
  // Account selection state
  final ValueNotifier<bool> _isWaitingAccountSelection = ValueNotifier<bool>(false);
  
  // Hızlı cevap seçenekleri
  List<String> _quickReplies = [];
  
  // Finansal özet cache (performans için)
  Map<String, dynamic>? _cachedFinancialSummary;
  DateTime? _cacheSummaryTime;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // UnifiedProviderV2'den başlangıç değerlerini al ve günlük kullanımı yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // UnifiedProviderV2'den initial değerleri al
        final provider = context.read<UnifiedProviderV2>();
        final premiumService = context.read<PremiumService>();
        
        final isPremium = premiumService.isPremium;
        final isPremiumPlus = premiumService.isPremiumPlus;
        
        // UnifiedProviderV2 zaten loadAllData ile yüklenmiş olmalı
        setState(() {
          _dailyUsage = provider.aiUsageCurrent;
          _dailyLimit = provider.aiUsageLimit;
          _dailyRemaining = (_dailyLimit - _dailyUsage).clamp(0, _dailyLimit);
          _bonusAvailable = !isPremium;
        });
        
        final planName = isPremiumPlus ? 'Premium Plus' : isPremium ? 'Premium' : 'Free';
        debugPrint('🎯 Initial AI limit set from UnifiedProviderV2:');
        debugPrint('   Plan: $planName');
        debugPrint('   Usage: $_dailyUsage');
        debugPrint('   Limit: $_dailyLimit');
        debugPrint('   Remaining: $_dailyRemaining');
        
        // Günlük kullanım bilgisini yükle (Firebase'den en güncel değerleri çek)
        _loadDailyUsage();
      }
    });
    
    // Chat geçmişini yükle
    _loadChatHistory();
  }
  
  /// Günlük AI kullanım bilgisini UnifiedProviderV2'den yükle
  Future<void> _loadDailyUsage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ User not authenticated, cannot load daily usage');
        return;
      }
      
      // UnifiedProviderV2'den güncel AI limiti al (uygulama başlangıcında yüklenmiş)
      final provider = context.read<UnifiedProviderV2>();
      final currentUsage = provider.aiUsageCurrent;
      final baseLimit = provider.aiUsageLimit;
      
      // Premium kontrolü yap
      final premiumService = context.read<PremiumService>();
      
      final isPremium = premiumService.isPremium;
      final isPremiumPlus = premiumService.isPremiumPlus;
      
      final planName = isPremiumPlus ? 'Premium Plus' : isPremium ? 'Premium' : 'Free';
      final period = isPremium ? 'aylık' : 'günlük';
      
      debugPrint('📊 Loading AI usage (Plan: $planName, Period: $period)');
      debugPrint('   Current: $currentUsage');
      debugPrint('   Base Limit: $baseLimit');
      
      // Bonus sistemi sadece Free kullanıcılar için
      int bonusCount = 0;
      if (!isPremium) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_usage_daily')
            .doc(dateKey)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          bonusCount = (data['bonusCount'] as int?) ?? 0;
          debugPrint('   Bonus: +$bonusCount');
        }
      }
      
      // Toplam limit hesapla: Base + Bonus (sadece Free için)
      final totalLimit = baseLimit + bonusCount;
      final remaining = totalLimit - currentUsage;
      
      if (mounted) {
        setState(() {
          _dailyLimit = baseLimit;
          _dailyUsage = currentUsage;
          _bonusCount = bonusCount;
          _dailyRemaining = remaining;
          // Bonus hala kazanılabilir mi? (Premium'da bonus yok)
          _bonusAvailable = !isPremium && bonusCount < _maxBonus;
        });
        debugPrint('✅ AI usage loaded:');
        debugPrint('   Plan: $planName ($period)');
        debugPrint('   Usage: $_dailyUsage');
        debugPrint('   Base Limit: $_dailyLimit');
        if (bonusCount > 0) {
          debugPrint('   Bonus: +$bonusCount');
        }
        debugPrint('   Total Limit: $totalLimit');
        debugPrint('   Remaining: $_dailyRemaining');
        debugPrint('   Bonus Available: $_bonusAvailable');
      }
    } catch (e) {
      debugPrint('❌ Error loading daily usage: $e');
      // Hata durumunda varsayılan değerleri koru
    }
  }
  
  /// Chat geçmişini temizle (her uygulama açılışında temiz başla)
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Kullanıcıya özel key kullan
      final chatKey = 'ai_chat_history_${user.uid}';
      final conversationKey = 'ai_conversation_history_${user.uid}';
      final dateKey = 'ai_chat_history_date_${user.uid}';
      
      // Her açılışta geçmişi temizle
      debugPrint('🧹 App opened! Clearing chat history for fresh start.');
      await prefs.remove(chatKey);
      await prefs.remove(conversationKey);
      await prefs.remove(dateKey);
      
      // Chat mesajlarını ve conversation history'yi temizle
      _chatMessages.clear();
      _conversationHistory.clear();
      
      // Hoş geldin mesajı ekle (rastgele)
      final profileProvider = context.read<ProfileProvider>();
      final userName = profileProvider.userName ?? 'dostum';
      final firstName = userName.split(' ').first;
      
      _chatMessages.add({
        'role': 'ai',
        'content': _getRandomWelcomeMessage(firstName),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      setState(() {
        _messagesUpdateTrigger.value++;
      });
      
      // Scroll'u en alta kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('❌ Error clearing chat history: $e');
    }
  }
  
  /// Dosya/fotoğraf ekleme seçeneklerini göster
  void _showAttachmentOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                      color: Color(0xFF6D6D70),
                  ),
                ),
                title: Text(
                  'Fotoğraf Çek',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Fatura veya makbuz fotoğrafı çek',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF6D6D70),
                  ),
                ),
                title: Text(
                  'Galeriden Seç',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Mevcut fotoğraflardan seç',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D6D70).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFF6D6D70),
                  ),
                ),
                title: Text(
                  'PDF Yükle',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'PDF fatura veya ekstreyi yükle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdfFile();
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  /// Kameradan fotoğraf çek
  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekerken hata oluştu: $e'),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }

  /// Galeriden fotoğraf seç
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçerken hata oluştu: $e'),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }

  /// PDF dosyası seç
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        await _processPdf(File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('❌ Error picking PDF file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF seçerken hata oluştu: $e'),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }

  /// Görüntüyü işle ve AI'a gönder
  Future<void> _processImage(File imageFile) async {
    try {
      debugPrint('📸 Processing image: ${imageFile.path}');
      
      // Dosyayı base64'e çevir
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      debugPrint('✅ Image converted to base64: ${base64Image.length} characters');
      
      // AI'a gönder (görüntü analizi)
      await _sendImageToAI(base64Image, 'image');
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görüntü işlenirken hata oluştu: $e'),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }

  /// PDF'i işle ve AI'a gönder
  Future<void> _processPdf(File pdfFile) async {
    try {
      debugPrint('📄 Processing PDF: ${pdfFile.path}');
      
      // Dosyayı base64'e çevir
      final bytes = await pdfFile.readAsBytes();
      final base64Pdf = base64Encode(bytes);
      
      debugPrint('✅ PDF converted to base64: ${base64Pdf.length} characters');
      
      // AI'a gönder (PDF analizi)
      await _sendImageToAI(base64Pdf, 'pdf');
    } catch (e) {
      debugPrint('❌ Error processing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF işlenirken hata oluştu: $e'),
            backgroundColor: const Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }

  /// Görüntü/PDF'i AI'a gönder ve analiz et
  Future<void> _sendImageToAI(String base64Data, String fileType) async {
    if (_isProcessing.value) return;

    try {
      _isProcessing.value = true;
      
      // "Analiz ediliyor..." mesajı ekle
      setState(() {
        _chatMessages.add({
          'role': 'user',
          'content': fileType == 'image' ? '📷 Fotoğraf gönderildi' : '📄 PDF gönderildi',
        });
        _chatMessages.add({'role': 'typing', 'content': '...'});
        _messagesUpdateTrigger.value++;
      });
      
      _scrollToBottom();
      
      final l10n = AppLocalizations.of(context)!;
      
      // AI servisini çağır (görüntü analizi)
      final response = await FirebaseAIService().chatWithAI(
        fileType == 'image' 
            ? 'Bu fotoğraftaki tüm finansal işlemleri analiz et ve çıkar.'
            : 'Bu PDF\'deki tüm finansal işlemleri analiz et ve çıkar.',
        conversationHistory: [],
        userAccounts: null,
        financialSummary: null,
        language: l10n.localeName,
        currency: 'TRY',
        imageBase64: base64Data, // Görüntü/PDF base64
        fileType: fileType, // 'image' veya 'pdf'
      );
      
      final aiMessage = response?['message'] as String? ?? '';
      final isReady = response?['isReady'] as bool? ?? false;  // Backend 'isReady' dönüyor
      final transactionData = response?['transactionData'];
      
      // Token usage bilgisini parse et (type-safe)
      Map<String, dynamic>? tokenUsage;
      if (response?['tokenUsage'] != null) {
        try {
          tokenUsage = Map<String, dynamic>.from(response!['tokenUsage'] as Map);
        } catch (e) {
          debugPrint('⚠️ Failed to parse tokenUsage data: $e');
        }
      }
      
      debugPrint('🤖 AI Response: $aiMessage');
      debugPrint('📊 Ready: $isReady, Has Data: ${transactionData != null}');
      if (tokenUsage != null) {
        debugPrint('🔢 Token Usage: ${tokenUsage['totalTokenCount']} tokens (Prompt: ${tokenUsage['promptTokenCount']}, Response: ${tokenUsage['candidatesTokenCount']})');
      }
      
      if (mounted) {
        setState(() {
          // Typing indicator'ı kaldır
          if (_chatMessages.isNotEmpty && _chatMessages.last['role'] == 'typing') {
            _chatMessages.removeLast();
          }
          
          _chatMessages.add({
            'role': 'ai', 
            'content': aiMessage,
            'timestamp': DateTime.now().millisecondsSinceEpoch, // Streaming için timestamp
            'shouldAnimate': true, // Bu mesaj animasyonlu gösterilmeli
            'tokenUsage': tokenUsage, // Token kullanımı (debug için)
          });
          _lastAIMessageTimestamp = DateTime.now(); // En son AI mesajı zamanı
          _lastAnimatedMessageIndex = _chatMessages.length - 1; // Bu mesajın index'i
          _messagesUpdateTrigger.value++;
        });
        
        _isProcessing.value = false;
        _saveChatHistory();
        _scrollToBottom();
        
        // Eğer bulk_add varsa, onay ekranını göster
        if (isReady && transactionData != null) {
          final dataType = transactionData['type'] as String?;
          debugPrint('✅ Transaction data received, type: $dataType');
          
          if (dataType == 'bulk_add') {
            final transactions = transactionData['transactions'] as List<dynamic>?;
            if (transactions != null && transactions.isNotEmpty) {
              debugPrint('📋 ${transactions.length} transactions detected, asking for account...');
              
              // Önce hesap seçimi sor
              if (mounted) {
                setState(() {
                  _chatMessages.add({
                    'role': 'account_selection',
                    'pending_transactions': transactions
                        .map((t) => Map<String, dynamic>.from(t as Map))
                        .toList(),
                  });
                  _messagesUpdateTrigger.value++;
                });
                _scrollToBottom();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending image to AI: $e');
      
      if (mounted) {
        // Hata mesajını belirle
        String errorMessage;
        
        // Limit hatası kontrolü
        if (e.toString().contains('resource-exhausted')) {
          // Firebase'den gelen hata mesajını parse et
          final errorStr = e.toString();
          
          int startIndex = -1;
          // Öncelik: "] " formatı - tam mesajı verir
          if (errorStr.contains('] ')) {
            startIndex = errorStr.indexOf('] ') + 2;
          } 
          // Fallback: "Günlük" veya "Daily" kelimesinden başlat
          else if (errorStr.contains('Günlük')) {
            startIndex = errorStr.indexOf('Günlük');
          } else if (errorStr.contains('Daily')) {
            startIndex = errorStr.indexOf('Daily');
          }
          
          if (startIndex != -1) {
            int endIndex = errorStr.indexOf('.', startIndex);
            if (endIndex != -1) {
              final nextDotIndex = errorStr.indexOf('.', endIndex + 1);
              if (nextDotIndex != -1 && (nextDotIndex - endIndex) < 100) {
                endIndex = nextDotIndex;
              }
            }
            
            errorMessage = endIndex != -1 
                ? errorStr.substring(startIndex, endIndex + 1)
                : errorStr.substring(startIndex);
          } else {
            errorMessage = '⚠️ ${AppLocalizations.of(context)!.aiImageAnalysisError}';
          }
        } else {
          errorMessage = '❌ ${AppLocalizations.of(context)!.aiImageAnalysisError}';
        }
        
        setState(() {
          if (_chatMessages.isNotEmpty && _chatMessages.last['role'] == 'typing') {
            _chatMessages.removeLast();
          }
          
          // Limit hatası ise özel mesaj tipi
          if (e.toString().contains('resource-exhausted')) {
            _chatMessages.add({
              'role': 'limit_error',
              'content': errorMessage,
            });
          } else {
            _chatMessages.add({
              'role': 'ai',
              'content': errorMessage,
            });
          }
          _messagesUpdateTrigger.value++;
        });
        
        _isProcessing.value = false;
        _saveChatHistory();
        _scrollToBottom();
      }
    }
  }

  /// Chat geçmişini kaydetme (devre dışı - her açılışta temizleniyor)
  void _saveChatHistory() {
    // Chat geçmişi artık kaydedilmiyor - her uygulama açılışında temiz başlanıyor
    // debugPrint('ℹ️ Chat history not saved - cleared on each app launch');
  }

  @override
  void dispose() {
    // Chat geçmişini kaydet
    _saveChatHistory();
    
    _controller.dispose();
    _chatScrollController.dispose();
    _animController.dispose();
    _isWaitingConfirmation.dispose();
    _isWaitingBulkDeleteConfirmation.dispose();
    _messagesUpdateTrigger.dispose();
    _isProcessing.dispose();
    super.dispose(); // Bu hem State hem de ChangeNotifier dispose'unu çağırır
  }
  
  // setState wrapper - artık ChangeNotifier kullanmıyoruz
  // Normal setState yeterli

  /// Rastgele hoş geldin mesajı al
  String _getRandomWelcomeMessage(String firstName) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final isTurkish = locale == 'tr';
    final isGerman = locale == 'de';
    
    final welcomeMessages = [
      l10n.aiChatWelcome(firstName),
      isTurkish 
        ? 'Hey $firstName! Bugün hangi işlemi eklemek istersiniz?'
        : isGerman
          ? 'Hey $firstName! Welche Transaktion möchten Sie heute hinzufügen?'
          : 'Hey $firstName! What transaction would you like to add today?',
      isTurkish
        ? 'Selam $firstName! Finansal asistanınız hazır. Harcama mı gelir mi ekleyelim?'
        : isGerman
          ? 'Hallo $firstName! Ihr Finanzassistent ist bereit. Ausgabe oder Einnahme hinzufügen?'
          : 'Hi $firstName! Your financial assistant is ready. Expense or income?',
      isTurkish
        ? 'Hoş geldin $firstName! Yeni bir işlem eklemek için hazırım.'
        : isGerman
          ? 'Willkommen $firstName! Ich bin bereit, eine neue Transaktion hinzuzufügen.'
          : 'Welcome back $firstName! Ready to add a new transaction.',
      isTurkish
        ? 'Merhaba $firstName! Ne yapmak istersiniz? İşlem eklemek, analiz yapmak?'
        : isGerman
          ? 'Hallo $firstName! Was möchten Sie tun? Transaktion hinzufügen oder analysieren?'
          : 'Hello $firstName! What would you like to do? Add transaction or analyze?',
      isTurkish
        ? '$firstName, tekrar hoş geldin! Bugün bütçeni nasıl takip edelim?'
        : isGerman
          ? '$firstName, willkommen zurück! Wie sollen wir heute Ihr Budget verfolgen?'
          : '$firstName, welcome back! How should we track your budget today?',
      isTurkish
        ? 'Selam $firstName! Finansal verilerinizi güncelleyelim mi?'
        : isGerman
          ? 'Hallo $firstName! Sollen wir Ihre Finanzdaten aktualisieren?'
          : 'Hi $firstName! Shall we update your financial data?',
      isTurkish
        ? 'Hey $firstName! Yeni bir harcama veya gelir eklemek ister misiniz?'
        : isGerman
          ? 'Hey $firstName! Möchten Sie eine neue Ausgabe oder Einnahme hinzufügen?'
          : 'Hey $firstName! Would you like to add a new expense or income?',
    ];
    
    final randomIndex = (DateTime.now().millisecondsSinceEpoch % welcomeMessages.length);
    return welcomeMessages[randomIndex];
  }

  void _toggleExpand() {
    // Karşılama mesajı
    if (_chatMessages.isEmpty) {
      final profileProvider = context.read<ProfileProvider>();
      final userName = profileProvider.userName ?? 'dostum';
      final firstName = userName.split(' ').first;
      
      _chatMessages.add({
        'role': 'ai',
        'content': _getRandomWelcomeMessage(firstName),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Welcome mesajı için scroll
      _scrollToBottom();
    }
    
    // Tam sayfa olarak aç - StatefulWidget olarak
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AIChatPageWrapper(
          parent: this, // Parent widget referansı
        ),
      ),
            ).then((_) {
              // Sayfa kapatıldığında sadece pending state'i temizle
              // NOT: Chat geçmişi artık korunuyor (SharedPreferences)
              if (mounted) {
                _isWaitingConfirmation.value = false;
                _isWaitingBulkDeleteConfirmation.value = false;
                setState(() {
                  _controller.clear();
                  _pendingTransactionData = null;
                  _pendingBulkDeleteFilters = null;
                  // _chatMessages ve _conversationHistory artık korunuyor!
                });
              }
            });
  }

  /// Quick action pill tıklandığında otomatik mesaj gönder
  void _sendQuickAction(String action) {
    if (_isProcessing.value) return;
    
    // Controller'a metni yaz ve gönder
    _controller.text = action;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    debugPrint('🔵 _sendMessage called');
    final message = _controller.text.trim();
    debugPrint('📝 Message: "$message", isEmpty: ${message.isEmpty}, isProcessing: ${_isProcessing.value}');
    
    if (message.isEmpty || _isProcessing.value) {
      debugPrint('❌ Message blocked: isEmpty=${message.isEmpty}, isProcessing=${_isProcessing.value}');
      return;
    }

    // HEMEN processing flag'ini set et - çift gönderim önleme
    _isProcessing.value = true;
    debugPrint('✅ Message approved, sending...');
    
    // ⚡ ÖZEL DURUM: Taksit/Hesap seçim butonları gösteriliyorken manuel yanıt
    if (_chatMessages.isNotEmpty) {
      final lastMsg = _chatMessages.last;
      final lastRole = lastMsg['role'];
      
      // TAKSIT SEÇİMİ: Manuel taksit sayısı girildi mi?
      if (lastRole == 'installment_selection') {
        final pendingData = lastMsg['pending_transaction'] as Map<String, dynamic>?;
        final lowerMessage = message.toLowerCase();
        int? installmentCount;
        
        // "peşin" kontrolü
        if (lowerMessage == 'peşin' || lowerMessage == 'pesin') {
          installmentCount = 1;
        }
        // "5 taksit" gibi tam format
        else if (lowerMessage.contains('taksit')) {
          final match = RegExp(r'(\d+)\s*taksit', caseSensitive: false).firstMatch(lowerMessage);
          if (match != null) {
            installmentCount = int.tryParse(match.group(1) ?? '1');
          }
        }
        // Sadece rakam yazılmışsa (en yaygın durum)
        else {
          installmentCount = int.tryParse(message.trim());
        }
        
        if (installmentCount != null && installmentCount >= 1 && installmentCount <= 12) {
          debugPrint('💳 Manuel taksit seçimi: $installmentCount taksit');
          
          // Taksit seçim mesajını kaldır
          setState(() {
            _chatMessages.removeLast();
            _messagesUpdateTrigger.value++;
          });
          
          if (pendingData != null && pendingData.isNotEmpty) {
            // Pending data varsa, taksit ekleyip onayla
            pendingData['installmentCount'] = installmentCount;
            _pendingTransactionData = pendingData;
            _isWaitingConfirmation.value = true;
            _controller.clear();
            _isProcessing.value = false; // Processing tamamlandı
            return;
          } else {
            // Pending data yoksa AI'ya net mesaj gönder
            _controller.clear();
            setState(() {
              _chatMessages.add({'role': 'user', 'content': '$installmentCount taksit'});
              _conversationHistory.add({'role': 'user', 'content': '$installmentCount taksit'});
            });
            _messagesUpdateTrigger.value++;
            _scrollToBottom();
            
            // AI'ya gönder
            final tempMessage = '$installmentCount taksit';
            _isProcessing.value = true;
            
            try {
              final provider = context.read<UnifiedProviderV2>();
              final l10n = AppLocalizations.of(context)!;
              
              final userAccounts = provider.accounts.map((acc) {
                final displayName = _getLocalizedAccountName(acc, context);
                String typeDisplay;
                switch (acc.type) {
                  case AccountType.credit:
                    typeDisplay = l10n.creditCard;
                    break;
                  case AccountType.debit:
                    typeDisplay = l10n.debitCard;
                    break;
                  case AccountType.cash:
                    typeDisplay = l10n.cash;
                    break;
                }
                return {
                  'name': acc.name,
                  'displayName': displayName,
                  'type': acc.type.value,
                  'typeDisplay': typeDisplay,
                  'balance': acc.balance,
                };
              }).toList();
              
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              final language = themeProvider.locale.languageCode;
              final currency = themeProvider.currency.name;
              
              final response = await _aiService.chatWithAI(
                tempMessage,
                conversationHistory: _conversationHistory,
                userAccounts: userAccounts,
                financialSummary: _cachedFinancialSummary,
                budgets: [],
                categories: [],
                stockPortfolio: [],
                stockTransactions: [],
                language: language,
                currency: currency,
              );
              
              if (!mounted) return;
              
              final aiMessage = (response?['message'] ?? '') as String;
              _conversationHistory.add({'role': 'model', 'content': aiMessage});
              
              setState(() {
                _chatMessages.removeWhere((msg) => msg['role'] == 'typing');
                _chatMessages.add({'role': 'assistant', 'content': aiMessage});
                _messagesUpdateTrigger.value++;
              });
              
              _isProcessing.value = false;
              _scrollToBottom();
            } catch (e) {
              debugPrint('❌ AI error: $e');
              setState(() {
                _chatMessages.removeWhere((msg) => msg['role'] == 'typing');
              });
              _isProcessing.value = false;
            }
            
            return;
          }
        }
      }
      
      // HESAP SEÇİMİ: Manuel hesap adı girildi mi?
      if (lastRole == 'account_selection_inline') {
        final pendingData = lastMsg['pending_transaction'] as Map<String, dynamic>?;
        final provider = context.read<UnifiedProviderV2>();
        
        // Hesap adını bul (localized name ile match yap)
        final matchingAccount = provider.accounts.where((account) {
          final localizedName = _getLocalizedAccountName(account, context);
          final lowerAccountName = localizedName.toLowerCase();
          final lowerMessage = message.toLowerCase();
          return lowerAccountName.contains(lowerMessage) || lowerMessage.contains(lowerAccountName);
        }).firstOrNull;
        
        if (matchingAccount != null) {
          final localizedName = _getLocalizedAccountName(matchingAccount, context);
          debugPrint('💳 Manuel hesap seçimi: $localizedName');
          
          // Hesap seçim mesajını kaldır
          setState(() {
            _chatMessages.removeLast();
            _messagesUpdateTrigger.value++;
          });
          
          // Update pending data with account
          final updatedPendingData = pendingData != null 
              ? Map<String, dynamic>.from(pendingData)
              : <String, dynamic>{};
          updatedPendingData['account'] = localizedName;
          
          // Check if installment needed
          final needsInstallment = matchingAccount.type == AccountType.credit && 
                                  updatedPendingData['installmentCount'] == null &&
                                  updatedPendingData['type'] == 'expense';
          
          if (needsInstallment) {
            // Show installment selection
            setState(() {
              _chatMessages.add({
                'role': 'installment_selection',
                'pending_transaction': updatedPendingData,
                'ai_message': null,
              });
              _messagesUpdateTrigger.value++;
            });
            _controller.clear();
            _scrollToBottom();
            _isProcessing.value = false; // Processing tamamlandı
            return;
          } else {
            // Directly confirm
            _pendingTransactionData = updatedPendingData;
            _isWaitingConfirmation.value = true;
            _controller.clear();
            _isProcessing.value = false; // Processing tamamlandı
            return;
          }
        }
      }
    }
    
    // 1. Controller ve quick replies'ı HEMEN temizle
    _controller.clear();
    _quickReplies = [];
    _isWaitingAccountSelection.value = false; // Hesap seçimi varsa kapat
    
    // 2. setState'i HEMEN çağır
    setState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _conversationHistory.add({'role': 'user', 'content': message});
      _chatMessages.add({'role': 'typing', 'content': '...'});
    });
    // _isProcessing zaten fonksiyon başında true yapıldı
    
    // Trigger child widget rebuild
    _messagesUpdateTrigger.value++;
    
    debugPrint('📨 Message added to _chatMessages. Total: ${_chatMessages.length}');
    
    // 3. MULTIPLE frame bekle - ListView'in render olması için
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    // 4. Şimdi scroll yap
    _scrollToBottom();
    
    debugPrint('🚀 Starting API call...');

    try {
      final provider = context.read<UnifiedProviderV2>();
      final l10n = AppLocalizations.of(context)!;
      
      // Hesap listesini hazırla - Localized (transaction formdaki gibi)
      final userAccounts = provider.accounts.map((acc) {
        // Tam localize edilmiş ad (transaction formdaki mantık)
        final displayName = _getLocalizedAccountName(acc, context);
        
        // Hesap tipini localize et
        String typeDisplay;
        switch (acc.type) {
          case AccountType.credit:
            typeDisplay = l10n.creditCard;
            break;
          case AccountType.debit:
            typeDisplay = l10n.debitCard;
            break;
          case AccountType.cash:
            typeDisplay = l10n.cash;
            break;
        }
        
        final accountData = {
          'name': acc.name, // Orijinal ad (matching için)
          'displayName': displayName, // Tam localized ad (gösterim için)
          'type': acc.type.value, // 'credit', 'debit', 'cash'
          'typeDisplay': typeDisplay, // Localized tip
          'balance': acc.isCreditCard ? acc.availableAmount : acc.balance,
        };
        
        // Kredi kartı ise ek bilgiler
        if (acc.isCreditCard) {
          if (acc.creditLimit != null) {
            accountData['creditLimit'] = acc.creditLimit!;
            accountData['availableCredit'] = acc.availableAmount;
            accountData['usedCredit'] = acc.usedCredit;
            accountData['creditUtilization'] = acc.creditUtilization;
            
            // Ekstre ve ödeme tarihleri
            if (acc.statementDay != null) {
              accountData['statementDay'] = acc.statementDay!;
              final now = DateTime.now();
              var nextStatementDate = DateTime(now.year, now.month, acc.statementDay!);
              if (nextStatementDate.isBefore(now)) {
                nextStatementDate = DateTime(now.year, now.month + 1, acc.statementDay!);
              }
              accountData['nextStatementDate'] = nextStatementDate.toString().substring(0, 10);
            }
            
            if (acc.dueDay != null) {
              accountData['dueDay'] = acc.dueDay!;
              final now = DateTime.now();
              var nextDueDate = DateTime(now.year, now.month, acc.dueDay!);
              if (nextDueDate.isBefore(now)) {
                nextDueDate = DateTime(now.year, now.month + 1, acc.dueDay!);
              }
              accountData['nextDueDate'] = nextDueDate.toString().substring(0, 10);
            }
          }
        }
        
        return accountData;
      }).toList();
      
      // Kullanıcının finansal özetini hazırla (cache ile)
      final userFinancialSummary = await _prepareFinancialSummary(provider);

      // Bütçeleri hazırla
      final userBudgets = provider.budgets.map((budget) => {
        'categoryName': budget.categoryName,
        'limit': budget.limit,
        'spentAmount': budget.spentAmount,
        'period': budget.period.toString().split('.').last, // 'weekly', 'monthly', 'yearly'
        'percentage': budget.limit > 0 ? ((budget.spentAmount / budget.limit) * 100).round() : 0,
      }).toList();

      // Kategorileri hazırla (displayName ekle - AI için daha anlamlı)
      final userCategories = provider.categories.map((category) => {
        'name': category.name,
        'displayName': category.displayName, // Türkçe gösterim adı
        'type': category.categoryType.name, // 'expense' veya 'income'
      }).toList();

      // Hisse portföyünü hazırla
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final userStockPortfolio = stockProvider.stockPositions.map((position) {
        // Güncel fiyat hesapla
        final currentPrice = position.currentValue / position.totalQuantity;
        
        return {
          'symbol': position.stockSymbol,
          'quantity': position.totalQuantity,
          'averagePrice': position.averagePrice,
          'currentPrice': currentPrice,
          'totalValue': position.currentValue,
          'totalCost': position.totalCost,
          'profitLoss': position.profitLoss,
          'profitLossPercentage': position.profitLossPercent,
          'lastUpdated': position.lastUpdated.toIso8601String(),
        };
      }).toList();

      // Hisse işlem geçmişini hazırla (son 50 işlem) - _sendMessage için
      final stockTransactions = stockProvider.stockTransactions.take(50).map((txn) {
        return {
          'stockSymbol': txn.stockSymbol,
          'type': txn.type.name,
          'quantity': txn.quantity,
          'pricePerShare': txn.price,
          'totalAmount': txn.totalAmount,
          'date': txn.transactionDate.toIso8601String(),
          'notes': txn.notes,
        };
      }).toList();

      // ThemeProvider'dan dil ve para birimi bilgilerini al
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final language = themeProvider.locale.languageCode; // 'tr' veya 'en'
      final currency = themeProvider.currency.name; // 'TRY', 'USD', vs.

      // AI ile konuş
      final response = await _aiService.chatWithAI(
        message,
        conversationHistory: _conversationHistory,
        userAccounts: userAccounts,
        financialSummary: userFinancialSummary,
        budgets: userBudgets,
        categories: userCategories,
        stockPortfolio: userStockPortfolio,
        stockTransactions: stockTransactions,
        language: language,
        currency: currency,
      );

      if (response != null && mounted) {
        final aiMessage = response['message'] as String;
        final isReady = response['isReady'] as bool;
        final transactionData = response['transactionData'];
        
        // Token usage bilgisini parse et (type-safe)
        Map<String, dynamic>? tokenUsage;
        if (response['tokenUsage'] != null) {
          try {
            tokenUsage = Map<String, dynamic>.from(response['tokenUsage'] as Map);
          } catch (e) {
            debugPrint('⚠️ Failed to parse tokenUsage data: $e');
          }
        }
        
        // Usage bilgisini parse et (type-safe)
        Map<String, dynamic>? usage;
        if (response['usage'] != null) {
          try {
            usage = Map<String, dynamic>.from(response['usage'] as Map);
          } catch (e) {
            debugPrint('⚠️ Failed to parse usage data: $e');
          }
        }

        debugPrint('📥 Response received:');
        debugPrint('   Message: $aiMessage');
        debugPrint('   IsReady: $isReady');
        debugPrint('   TransactionData: $transactionData');
        if (tokenUsage != null) {
          debugPrint('🔢 Token Usage: ${tokenUsage['totalTokenCount']} tokens (Prompt: ${tokenUsage['promptTokenCount']}, Response: ${tokenUsage['candidatesTokenCount']})');
        }
        
        // Usage bilgisini güncelle
        if (usage != null) {
          // UnifiedProviderV2'yi güncelle
          final provider = context.read<UnifiedProviderV2>();
          
          // Günlük kullanım (öncelik)
          if (usage['daily'] != null) {
            final daily = Map<String, dynamic>.from(usage['daily'] as Map);
            
            // Backend'den gelen daily limit aslında total limit (base + bonus)
            // Bu yüzden base limit'i hesaplamamız gerekiyor
            final totalLimit = daily['limit'] as int? ?? _dailyLimit;
            final bonusCount = daily['bonusCount'] as int? ?? 0;
            final baseLimit = totalLimit - bonusCount;
            
            setState(() {
              _dailyUsage = daily['current'] as int? ?? 0;
              _dailyLimit = baseLimit; // Base limit (bonus hariç)
              _bonusCount = bonusCount;
              _bonusAvailable = daily['bonusAvailable'] as bool? ?? false;
              _maxBonus = daily['maxBonus'] as int? ?? 15;
              
              // Backend'den gelen remaining değerini kullan (zaten doğru hesaplanmış)
              _dailyRemaining = daily['remaining'] as int? ?? 0;
            });
            debugPrint('📊 Daily usage: $_dailyUsage/$baseLimit+$bonusCount (Total: $totalLimit, Remaining: $_dailyRemaining)');
            
            // UnifiedProviderV2'yi güncelle (backend'den gelen değerlerle)
            provider.updateAIUsageFromBackend(_dailyUsage, baseLimit);
          }
          
          // Aylık kullanım (backup)
          _monthlyUsage = usage['current'] as int? ?? 0;
          _monthlyLimit = usage['limit'] as int? ?? 100000;
          _monthlyRemaining = usage['remaining'] as int? ?? 100000;
          debugPrint('📊 Monthly usage: $_monthlyUsage/$_monthlyLimit');
        }

        // Typing indicator'ı kaldır ve gerçek mesajı ekle
        setState(() {
          // Son mesaj typing ise kaldır
          if (_chatMessages.isNotEmpty && _chatMessages.last['role'] == 'typing') {
            _chatMessages.removeLast();
          }
          
          // READY durumunda AI mesajı boş olabilir, fallback mesajı kullan
          String displayMessage = aiMessage;
          if (isReady && (aiMessage.isEmpty || aiMessage.trim().toLowerCase().startsWith('ready:'))) {
            // İşlem bilgilerinden fallback mesajı oluştur
            displayMessage = _createTransactionFallbackMessage(transactionData);
          }
          
          _chatMessages.add({
            'role': 'ai', 
            'content': displayMessage,
            'timestamp': DateTime.now().millisecondsSinceEpoch, // Streaming için timestamp
            'shouldAnimate': true, // Bu mesaj animasyonlu gösterilmeli
            'tokenUsage': tokenUsage, // Token kullanımı (debug için)
          });
          _lastAIMessageTimestamp = DateTime.now(); // En son AI mesajı zamanı
          _lastAnimatedMessageIndex = _chatMessages.length - 1; // Bu mesajın index'i
          _conversationHistory.add({'role': 'model', 'content': aiMessage}); // Conversation history'e orijinal mesajı ekle
        });
        _isProcessing.value = false;
        
        // Trigger child widget rebuild
        _messagesUpdateTrigger.value++;
        
        // Chat geçmişini kaydet
        _saveChatHistory();
        debugPrint('💬 AI response added. Total messages: ${_chatMessages.length}');
        
        // Scroll to bottom (AI cevabı eklendikten sonra)
        _scrollToBottom();
        
        // AI'dan gelen hızlı cevap seçeneklerini al
        final aiQuickReplies = response['quickReplies'];
        if (!isReady && aiQuickReplies != null && mounted) {
          setState(() {
            if (aiQuickReplies is List) {
              _quickReplies = List<String>.from(aiQuickReplies.map((e) => e.toString()));
              debugPrint('🎯 Quick replies from AI: $_quickReplies');
            } else {
              _quickReplies = [];
            }
          });
        } else {
          // Ready state'de veya quick replies yoksa temizle
          setState(() {
            _quickReplies = [];
          });
        }
        
        // AI hesap sorusu soruyorsa, inline hesap seçimi göster
        if (!isReady && _isAskingForAccount(aiMessage)) {
          debugPrint('💳 AI is asking for account, showing inline account selection...');
          if (mounted) {
            // Transaction data varsa kaydet, yoksa boş map oluştur
            final pendingData = transactionData != null 
                ? Map<String, dynamic>.from(transactionData as Map)
                : <String, dynamic>{};
            
            setState(() {
              // Hesap seçim mesajını ekle
              _chatMessages.add({
                'role': 'account_selection_inline',
                'pending_transaction': pendingData,
              });
              _messagesUpdateTrigger.value++;
            });
            _scrollToBottom();
          }
        }
        
        // AI taksit sorusu soruyor mu?
        if (!isReady && _isAskingForInstallment(aiMessage)) {
          debugPrint('💳 AI is asking for installment, showing installment selection...');
          if (mounted) {
            // Transaction data varsa kaydet, yoksa boş map oluştur
            final pendingData = transactionData != null 
                ? Map<String, dynamic>.from(transactionData as Map)
                : <String, dynamic>{};
            
            setState(() {
              // Taksit seçim mesajını ekle
              _chatMessages.add({
                'role': 'installment_selection',
                'pending_transaction': pendingData,
                'ai_message': aiMessage, // AI'ın mesajını da göster
              });
              _messagesUpdateTrigger.value++;
            });
            _scrollToBottom();
          }
        }

        // Eğer işlem hazırsa, onay bekle
        if (isReady && transactionData != null) {
          // Type-safe casting
          final Map<String, dynamic> safeTransactionData = 
              Map<String, dynamic>.from(transactionData as Map);
          debugPrint('✅ Transaction data safely casted');
          
          final dataType = safeTransactionData['type'] as String?;
          
          if (dataType == 'theme') {
            // Tema değiştirme - direkt uygula
            debugPrint('🎨 Theme change requested...');
            await _handleThemeChange(safeTransactionData);
          } else if (dataType == 'bulk_delete') {
            // Toplu silme - kullanıcıdan onay al ve sil
            debugPrint('🗑️ Bulk delete requested...');
            await _handleBulkDelete(safeTransactionData);
          } else if (dataType == 'budget_create') {
            // Bütçe oluştur
            debugPrint('💰 Budget create requested...');
            await _handleBudgetCreate(safeTransactionData);
          } else if (dataType == 'budget_update') {
            // Bütçe güncelle
            debugPrint('📊 Budget update requested...');
            await _handleBudgetUpdate(safeTransactionData);
          } else if (dataType == 'budget_delete') {
            // Bütçe sil
            debugPrint('🗑️ Budget delete requested...');
            await _handleBudgetDelete(safeTransactionData);
          } else if (dataType == 'category_create') {
            // Kategori oluştur
            debugPrint('📁 Category create requested...');
            await _handleCategoryCreate(safeTransactionData);
          } else if (dataType == 'stock') {
            // Hisse alım/satım - kullanıcı onayını bekle
            debugPrint('📈 Stock transaction requested...');
            if (mounted) {
              _pendingTransactionData = safeTransactionData;
              _isWaitingConfirmation.value = true;
              debugPrint('✅ Stock transaction pending confirmation');
            }
          } else {
            // Normal transaction - Önce taksit kontrolü yap
            debugPrint('⏳ Transaction ready, checking if installment selection needed...');
            
            // Taksit seçimi gerekli mi kontrol et
            final needsInstallmentSelection = _checkIfNeedsInstallmentSelection(
              safeTransactionData, 
              aiMessage,
            );
            
            if (needsInstallmentSelection) {
              // Taksit seçim mesajı göster
              debugPrint('💳 Installment selection needed - showing installment buttons');
              if (mounted) {
                setState(() {
                  _chatMessages.add({
                    'role': 'installment_selection',
                    'pending_transaction': safeTransactionData,
                    'ai_message': aiMessage, // AI'ın mesajını da göster
                  });
                  _messagesUpdateTrigger.value++;
                });
                _scrollToBottom();
              }
            } else {
              // Normal onay bekle
              debugPrint('⏳ Transaction ready, waiting for user confirmation...');
              debugPrint('   mounted: $mounted');
              if (mounted) {
                _pendingTransactionData = safeTransactionData;
                debugPrint('   pendingData set');
                _isWaitingConfirmation.value = true; // setState dışında!
                debugPrint('✅ ValueNotifier set to true: ${_isWaitingConfirmation.value}');
              } else {
                debugPrint('❌ Widget not mounted, cannot set confirmation state!');
              }
            }
          }
        } else if (isReady && transactionData == null) {
          debugPrint('⚠️ IsReady=true but transactionData is null!');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ EXCEPTION in _sendMessage: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        // Hata mesajını belirle
        String errorMessage;
        
        // Limit hatası kontrolü
        if (e.toString().contains('resource-exhausted')) {
          // Firebase'den gelen hata mesajını parse et
          final errorStr = e.toString();
          
          // "] " işaretinden sonraki kısmı al (tam mesaj)
          int startIndex = -1;
          
          // Öncelik: "] " formatı - tam mesajı verir
          if (errorStr.contains('] ')) {
            startIndex = errorStr.indexOf('] ') + 2;
          }
          // Fallback: "Günlük" veya "Daily" kelimesinden başlat
          else if (errorStr.contains('Günlük')) {
            startIndex = errorStr.indexOf('Günlük');
          }
          else if (errorStr.contains('Daily')) {
            startIndex = errorStr.indexOf('Daily');
          }
          
          if (startIndex != -1) {
            // Mesajın sonunu bul (bir sonraki nokta)
            int endIndex = errorStr.indexOf('.', startIndex);
            
            // Eğer "Premium'a yükseltin..." gibi devam eden cümle varsa, onu da dahil et
            if (endIndex != -1) {
              // Bir sonraki cümleyi de kontrol et
              final nextDotIndex = errorStr.indexOf('.', endIndex + 1);
              if (nextDotIndex != -1 && (nextDotIndex - endIndex) < 100) {
                endIndex = nextDotIndex;
              }
            }
            
            errorMessage = endIndex != -1 
                ? errorStr.substring(startIndex, endIndex + 1)
                : errorStr.substring(startIndex);
          } else {
            errorMessage = '⚠️ ${AppLocalizations.of(context)!.aiChatError}';
          }
        } else {
          errorMessage = '❌ ${AppLocalizations.of(context)!.aiChatError}';
        }
        
        setState(() {
          // Typing indicator'ı kaldır
          if (_chatMessages.isNotEmpty && _chatMessages.last['role'] == 'typing') {
            _chatMessages.removeLast();
          }
          
          // Limit hatası ise özel mesaj tipi
          if (e.toString().contains('resource-exhausted')) {
            _chatMessages.add({
              'role': 'limit_error',
              'content': errorMessage,
            });
          } else {
            _chatMessages.add({
              'role': 'ai',
              'content': errorMessage,
            });
          }
        });
        _isProcessing.value = false;
        
        // Trigger rebuild
        _messagesUpdateTrigger.value++;
        
        // Chat geçmişini kaydet
        _saveChatHistory();
        
        // Scroll to bottom (hata mesajı eklendikten sonra)
        _scrollToBottom();
      }
    }
  }

  /// AI'ya takip mesajı gönder (kullanıcıya gösterilmez, sadece arka planda)
  /// Kategori oluşturulduktan sonra işlem eklemesi için kullanılır
  Future<void> _sendFollowUpToAI(String message) async {
    if (!mounted) return;
    
    debugPrint('🔄 Sending follow-up message to AI: "$message"');
    
    _isProcessing.value = true;
    
    try {
      final provider = context.read<UnifiedProviderV2>();
      
      // Finansal özeti hazırla (cache'i invalidate et - yeni işlem eklendiyse)
      _cachedFinancialSummary = null; // Force fresh calculation
      final userFinancialSummary = await _prepareFinancialSummary(provider);
      
      // Hesapları hazırla (detaylı bilgi ile)
      final userAccounts = provider.accounts.map((account) {
        final accountData = {
          'name': account.name,
          'displayName': _getLocalizedAccountName(account, context),
          // Kredi kartı için kullanılabilir krediyi (mevcut limit), diğerleri için balance'ı göster
          'balance': account.isCreditCard ? account.availableAmount : account.balance,
          'type': account.type.name,
        };
        
        // Kredi kartı ise ek bilgiler
        if (account.isCreditCard) {
          if (account.creditLimit != null) {
            accountData['creditLimit'] = account.creditLimit!;
            accountData['availableCredit'] = account.availableAmount;
            accountData['usedCredit'] = account.usedCredit;
            accountData['creditUtilization'] = account.creditUtilization;
          }
          
          // Ekstre ve ödeme tarihleri
          if (account.statementDay != null) {
            accountData['statementDay'] = account.statementDay!;
            // Bir sonraki ekstre tarihini hesapla
            final now = DateTime.now();
            var nextStatementDate = DateTime(now.year, now.month, account.statementDay!);
            if (nextStatementDate.isBefore(now)) {
              nextStatementDate = DateTime(now.year, now.month + 1, account.statementDay!);
            }
            accountData['nextStatementDate'] = nextStatementDate.toString().substring(0, 10);
          }
          
          if (account.dueDay != null) {
            accountData['dueDay'] = account.dueDay!;
            // Bir sonraki ödeme tarihini hesapla
            final now = DateTime.now();
            var nextDueDate = DateTime(now.year, now.month, account.dueDay!);
            if (nextDueDate.isBefore(now)) {
              nextDueDate = DateTime(now.year, now.month + 1, account.dueDay!);
            }
            accountData['nextDueDate'] = nextDueDate.toString().substring(0, 10);
            
            // Ödeme tarihi yaklaşıyor mu? (7 gün içinde)
            final daysUntilDue = nextDueDate.difference(now).inDays;
            if (daysUntilDue <= 7 && daysUntilDue >= 0) {
              accountData['paymentDueSoon'] = true;
              accountData['daysUntilDue'] = daysUntilDue;
            }
          }
        }
        
        return accountData;
      }).toList();
      
      // Bütçeleri hazırla
      final userBudgets = provider.budgets.map((budget) {
        return {
          'category': budget.categoryName,
          'limit': budget.limit,
          'spent': budget.spentAmount,
          'period': budget.period.name,
        };
      }).toList();
      
      // Kategorileri hazırla
      final userCategories = provider.categories.map((category) {
        return {
          'name': category.name,
          'type': category.categoryType.name,
        };
      }).toList();
      
      // Hisse portföyünü hazırla
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final userStockPortfolio = stockProvider.stockPositions.map((position) {
        return {
          'symbol': position.stockSymbol,
          'quantity': position.totalQuantity,
          'averagePrice': position.averagePrice,
          'currentPrice': position.averagePrice, // StockPosition'da mevcut değil, average kullan
          'totalValue': position.currentValue,
          'totalCost': position.totalCost,
          'profitLoss': position.profitLoss,
          'profitLossPercentage': position.profitLossPercent,
        };
      }).toList();
      
      // Hisse işlem geçmişini hazırla (son 50 işlem)
      final userStockTransactions = stockProvider.stockTransactions.take(50).map((txn) {
        return {
          'stockSymbol': txn.stockSymbol,
          'type': txn.type.name, // 'buy' veya 'sell'
          'quantity': txn.quantity,
          'pricePerShare': txn.price,
          'totalAmount': txn.totalAmount,
          'date': txn.transactionDate.toIso8601String(),
          'notes': txn.notes,
        };
      }).toList();
      
      // ThemeProvider'dan dil ve para birimi bilgilerini al
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final language = themeProvider.locale.languageCode;
      final currency = themeProvider.currency.name;
      
      // AI ile konuş
      final response = await _aiService.chatWithAI(
        message,
        conversationHistory: _conversationHistory,
        userAccounts: userAccounts,
        financialSummary: userFinancialSummary,
        budgets: userBudgets,
        categories: userCategories,
        stockPortfolio: userStockPortfolio,
        stockTransactions: userStockTransactions,
        language: language,
        currency: currency,
      );
      
      if (!mounted) return;
      
      // AI yanıtını işle
      final aiMessage = response?['message'] as String? ?? '';
      final isReady = response?['isReady'] as bool? ?? false;
      final transactionData = response?['transactionData'];
      final quickReplies = response?['quickReplies'] as List<dynamic>?;
      
      // Token usage bilgisini parse et (type-safe)
      Map<String, dynamic>? tokenUsage;
      if (response?['tokenUsage'] != null) {
        try {
          tokenUsage = Map<String, dynamic>.from(response!['tokenUsage'] as Map);
        } catch (e) {
          debugPrint('⚠️ Failed to parse tokenUsage data: $e');
        }
      }
      
      debugPrint('📥 Follow-up response: $aiMessage');
      debugPrint('   IsReady: $isReady, TransactionData: $transactionData');
      if (tokenUsage != null) {
        debugPrint('🔢 Token Usage: ${tokenUsage['totalTokenCount']} tokens (Prompt: ${tokenUsage['promptTokenCount']}, Response: ${tokenUsage['candidatesTokenCount']})');
      }
      
      // Conversation history'e AI yanıtını ekle
      _conversationHistory.add({
        'role': 'model',
        'content': aiMessage,
      });
      
      // AI yanıtını chat'e ekle
      if (mounted && aiMessage.isNotEmpty) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': aiMessage,
            'tokenUsage': tokenUsage, // Token kullanımı (debug için)
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
      
      // Quick replies varsa ekle
      if (quickReplies != null && quickReplies.isNotEmpty) {
        _quickReplies = List<String>.from(quickReplies);
      }
      
      // Transaction data varsa işle
      if (isReady && transactionData != null) {
        final safeTransactionData = transactionData is Map
            ? Map<String, dynamic>.from(transactionData)
            : transactionData;
        
        debugPrint('✅ Transaction data from follow-up');
        
        final dataType = safeTransactionData['type'] as String?;
        
        if (dataType == 'category_create') {
          // Başka bir kategori mi oluşturmaya çalışıyor? Bunu önle
          debugPrint('⚠️ AI tried to create another category, ignoring...');
        } else if (mounted) {
          _pendingTransactionData = safeTransactionData;
          _isWaitingConfirmation.value = true;
        }
      }
      
      _saveChatHistory();
      _isProcessing.value = false;
      
    } catch (e) {
      debugPrint('❌ Follow-up message error: $e');
      _isProcessing.value = false;
    }
  }

  /// Kullanıcının finansal özetini hazırla (cache ile - performans optimizasyonu)
  Future<Map<String, dynamic>> _prepareFinancialSummary(UnifiedProviderV2 provider) async {
    try {
      // Cache kontrolü - son 30 saniye içinde hesaplandıysa cache'ten dön
      if (_cachedFinancialSummary != null && _cacheSummaryTime != null) {
        final cacheAge = DateTime.now().difference(_cacheSummaryTime!);
        if (cacheAge.inSeconds < 30) {
          debugPrint('📊 Using cached financial summary (${cacheAge.inSeconds}s old)');
          return _cachedFinancialSummary!;
        }
      }
      
      debugPrint('📊 Calculating fresh financial summary...');
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final last30Days = now.subtract(const Duration(days: 30));
      
      // Bu ayki işlemler
      final thisMonthTransactions = provider.transactions.where((t) => 
        t.transactionDate.isAfter(thisMonthStart)
      ).toList();
      
      // Son 30 gün işlemleri
      final last30DaysTransactions = provider.transactions.where((t) => 
        t.transactionDate.isAfter(last30Days)
      ).toList();
      
      // Gelir/Gider toplamları (bu ay)
      double thisMonthIncome = 0;
      double thisMonthExpense = 0;
      
      for (var t in thisMonthTransactions) {
        if (t.type == TransactionType.income) {
          thisMonthIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          thisMonthExpense += t.amount;
        }
      }
      
      // Geçen ay için veri (karşılaştırma)
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
      final lastMonthTransactions = provider.transactions.where((t) => 
        t.transactionDate.isAfter(lastMonthStart) && t.transactionDate.isBefore(lastMonthEnd)
      ).toList();
      
      double lastMonthIncome = 0;
      double lastMonthExpense = 0;
      for (var t in lastMonthTransactions) {
        if (t.type == TransactionType.income) {
          lastMonthIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          lastMonthExpense += t.amount;
        }
      }
      
      // Son 90 gün işlemleri (daha derin analiz için)
      final last90Days = now.subtract(const Duration(days: 90));
      final last90DaysTransactions = provider.transactions.where((t) => 
        t.transactionDate.isAfter(last90Days)
      ).toList();
      
      // Kategori bazlı DETAYLI analiz (son 90 gün)
      Map<String, Map<String, dynamic>> categoryDetails = {};
      
      for (var t in last90DaysTransactions) {
        if (t.type == TransactionType.expense && t.categoryId != null) {
          final category = provider.categories.firstWhere(
            (c) => c.id == t.categoryId,
            orElse: () => provider.categories.first,
          );
          final categoryName = category.displayName;
          
          if (!categoryDetails.containsKey(categoryName)) {
            categoryDetails[categoryName] = {
              'total': 0.0,
              'count': 0,
              'amounts': <double>[],
              'dates': <String>[],
              'installmentCount': 0,
              'totalInstallmentAmount': 0.0,
            };
          }
          
          categoryDetails[categoryName]!['total'] = 
            (categoryDetails[categoryName]!['total'] as double) + t.amount;
          categoryDetails[categoryName]!['count'] = 
            (categoryDetails[categoryName]!['count'] as int) + 1;
          (categoryDetails[categoryName]!['amounts'] as List<double>).add(t.amount);
          (categoryDetails[categoryName]!['dates'] as List<String>)
            .add(t.transactionDate.toString().substring(0, 10));
          
          // Taksitli işlem ise say
          if (t.isInstallment && t.installmentCount != null && t.installmentCount! > 1) {
            categoryDetails[categoryName]!['installmentCount'] = 
              (categoryDetails[categoryName]!['installmentCount'] as int) + 1;
            categoryDetails[categoryName]!['totalInstallmentAmount'] = 
              (categoryDetails[categoryName]!['totalInstallmentAmount'] as double) + t.amount;
          }
        }
      }
      
      // Her kategori için metrikleri hesapla
      final categoryAnalysis = categoryDetails.entries.map((entry) {
        final catName = entry.key;
        final data = entry.value;
        final total = data['total'] as double;
        final count = data['count'] as int;
        final amounts = data['amounts'] as List<double>;
        final dates = data['dates'] as List<String>;
        
        // Ortalama, min, max
        final avg = total / count;
        amounts.sort();
        final min = amounts.first;
        final max = amounts.last;
        
        // Frekans analizi (90 günde kaç kez)
        final frequency = count / 90.0; // günlük ortalama
        
        final analysisMap = {
          'category': catName,
          'total': total,
          'count': count,
          'average': avg,
          'min': min,
          'max': max,
          'frequency': frequency, // günlük frekans
          'dates': dates, // AI pattern tespiti yapabilsin
        };
        
        // Taksitli işlem bilgisi varsa ekle
        final installmentCount = data['installmentCount'] as int;
        final totalInstallmentAmount = data['totalInstallmentAmount'] as double;
        if (installmentCount > 0) {
          analysisMap['installmentCount'] = installmentCount;
          analysisMap['totalInstallmentAmount'] = totalInstallmentAmount;
        }
        
        return analysisMap;
      }).toList();
      
      // Toplam bazında sırala
      categoryAnalysis.sort((a, b) => 
        (b['total'] as double).compareTo(a['total'] as double)
      );
      
      // En çok harcama yapılan 5 kategori (basit view için)
      final topCategories = categoryAnalysis.take(5).map((e) => {
        'category': e['category'],
        'amount': e['total'],
      }).toList();
      
      // Son 10 işlem
      final recentTransactions = provider.transactions
        .take(10)
        .map((t) {
          final category = t.categoryId != null 
            ? provider.categories.firstWhere(
                (c) => c.id == t.categoryId,
                orElse: () => provider.categories.first,
              ).displayName
            : 'Diğer';
          
          final transactionMap = {
            'amount': t.amount,
            'category': category,
            'type': t.type.toString().split('.').last,
            'date': t.transactionDate.toString().substring(0, 10),
            'description': t.description,
          };
          
          // Taksitli işlem bilgisini ekle
          if (t.isInstallment && t.installmentCount != null && t.installmentCount! > 1) {
            transactionMap['isInstallment'] = true;
            transactionMap['installmentCount'] = t.installmentCount!;
            transactionMap['monthlyAmount'] = t.amount / t.installmentCount!;
          }
          
          return transactionMap;
        }).toList();
      
      // Günlük ortalama harcama (bu ay)
      final daysInMonth = now.day;
      final dailyAverage = daysInMonth > 0 ? thisMonthExpense / daysInMonth : 0;
      
      // Ay sonu tahmini
      final daysInMonthTotal = DateTime(now.year, now.month + 1, 0).day;
      final projectedMonthEnd = dailyAverage * daysInMonthTotal;
      
      // Kredi kartı bilgilerini hazırla
      final creditCardInfo = provider.creditCards.map((card) {
        return {
          'name': card['cardName'] ?? 'Kredi Kartı',
          'bankName': card['bankName'] ?? '',
          'totalDebt': card['totalDebt'] ?? 0.0,
          'creditLimit': card['creditLimit'] ?? 0.0,
          'availableLimit': card['availableLimit'] ?? 0.0,
          'usagePercentage': card['usagePercentage'] ?? 0.0,
        };
      }).toList();
      
      final summary = {
        'thisMonth': {
          'income': thisMonthIncome,
          'expense': thisMonthExpense,
          'balance': thisMonthIncome - thisMonthExpense,
          'dailyAverage': dailyAverage,
          'projectedMonthEnd': projectedMonthEnd,
          'daysRemaining': daysInMonthTotal - daysInMonth,
        },
        'lastMonth': {
          'income': lastMonthIncome,
          'expense': lastMonthExpense,
          'balance': lastMonthIncome - lastMonthExpense,
        },
        'comparison': {
          'incomeChange': thisMonthIncome - lastMonthIncome,
          'expenseChange': thisMonthExpense - lastMonthExpense,
          'incomeChangePercent': lastMonthIncome > 0 
            ? ((thisMonthIncome - lastMonthIncome) / lastMonthIncome * 100) 
            : 0,
          'expenseChangePercent': lastMonthExpense > 0 
            ? ((thisMonthExpense - lastMonthExpense) / lastMonthExpense * 100) 
            : 0,
        },
        'topCategories': topCategories,
        'categoryAnalysis': categoryAnalysis, // Detaylı analiz - AI bunu kullanacak
        'recentTransactions': recentTransactions,
        'totalAccounts': provider.accounts.length,
        'totalBalance': provider.accounts.fold<double>(
          0, 
          (sum, acc) => sum + acc.balance,
        ),
        'creditCards': creditCardInfo, // Kredi kartı limit bilgileri
        'installments': provider.installments.map((inst) {
          debugPrint('💳 Sending installment to AI: ${inst.description} (${inst.paidCount}/${inst.totalCount})');
          final remainingCount = inst.totalCount - inst.paidCount;
          return {
            'description': inst.description,
            'totalAmount': inst.totalAmount,
            'monthlyAmount': inst.monthlyAmount,
            'totalCount': inst.totalCount,
            'paidCount': inst.paidCount,
            'remainingCount': remainingCount,
            'isCompleted': inst.isCompleted,
            'progressPercentage': inst.progressPercentage,
            'startDate': inst.startDate.toString().substring(0, 10),
            'nextDueDate': inst.nextDueDate?.toString().substring(0, 10),
            'accountName': inst.accountName, // Hangi karttan yapıldığı bilgisi
          };
        }).toList(),
        'installmentSummary': {
          'activeCount': provider.activeInstallments.length,
          'totalMonthlyPayment': provider.activeInstallments.fold<double>(
            0, (sum, inst) => sum + inst.monthlyAmount
          ),
          'totalRemainingAmount': provider.activeInstallments.fold<double>(
            0, (sum, inst) => sum + (inst.monthlyAmount * (inst.totalCount - inst.paidCount))
          ),
        },
        'analysisMetadata': {
          'last90DaysTransactionCount': last90DaysTransactions.length,
          'thisMonthTransactionCount': thisMonthTransactions.length,
          'dataQuality': last90DaysTransactions.length >= 10 ? 'good' : 'limited',
        },
      };
      
      debugPrint('💳 Installment Summary for AI: ${provider.installments.length} total, ${provider.activeInstallments.length} active');
      
      // Cache'e kaydet
      _cachedFinancialSummary = summary;
      _cacheSummaryTime = DateTime.now();
      debugPrint('✅ Financial summary cached');
      
      return summary;
    } catch (e) {
      debugPrint('❌ Error preparing financial summary: $e');
      return {};
    }
  }

  /// Kullanıcı transaction'ı onayladı (Single Responsibility: Transaction confirmation)
  Future<void> _confirmTransaction() async {
    if (_pendingTransactionData == null) return;
    
    _isWaitingConfirmation.value = false; // setState dışında!
    _isProcessing.value = true;
    
    try {
      debugPrint('✅ User confirmed transaction');
      
      final dataType = _pendingTransactionData!['type'] as String?;
      
      // Type-based dispatch (Open/Closed Principle)
      if (dataType == 'stock') {
        await _createStockTransaction(_pendingTransactionData!);
      } else {
        await _createTransactionFromAI(_pendingTransactionData!);
      }
      
      // Transaction listesini yenile
      if (mounted) {
        final provider = context.read<UnifiedProviderV2>();
        await provider.loadTransactions();
        await provider.loadInstallments(); // Taksitli işlemler için
        debugPrint('🔄 Transaction list reloaded');
        
        // Cache'i invalidate et - yeni işlem eklendi
        _cachedFinancialSummary = null;
        debugPrint('🗑️ Financial summary cache invalidated');
      }
      
      if (mounted) {
        setState(() {
          _pendingTransactionData = null;
          // Başarı mesajı ekle
          _chatMessages.add({
            'role': 'system',
            'content': AppLocalizations.of(context)!.aiChatTransactionSuccess,
          });
        });
        _isProcessing.value = false;
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful transaction');
        
        _saveChatHistory(); // Chat geçmişini kaydet
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Error confirming transaction: $e');
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': '❌ ${AppLocalizations.of(context)!.aiChatTransactionFailed}',
          });
        });
        _isProcessing.value = false;
        _messagesUpdateTrigger.value++;
        _saveChatHistory(); // Chat geçmişini kaydet
        _scrollToBottom();
      }
    }
  }
  
  /// Kullanıcı transaction'ı iptal etti
  void _cancelTransaction() {
    debugPrint('❌ User cancelled transaction');
    _isWaitingConfirmation.value = false; // setState dışında!
    setState(() {
      _pendingTransactionData = null;
      
      _chatMessages.add({
        'role': 'ai',
        'content': AppLocalizations.of(context)!.aiChatTransactionCancelled,
      });
    });
    
    // Trigger rebuild
    _messagesUpdateTrigger.value++;
    
    // Scroll to bottom
    _scrollToBottom();
  }

  Future<void> _handleThemeChange(dynamic data) async {
    try {
      debugPrint('🎨 Handling theme change: $data');
      
      final Map<String, dynamic> themeData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final themeName = themeData['theme'] as String?;
      debugPrint('   Theme: $themeName');
      
      if (themeName != null && mounted) {
        // Theme provider'ı bul
        final themeProvider = context.read<ThemeProvider>();
        
        // Tema değiştir (AI zaten mesaj verdi, sistem mesajına gerek yok)
        if (themeName.toLowerCase() == 'light') {
          await themeProvider.setThemeMode(ThemeMode.light);
        } else if (themeName.toLowerCase() == 'dark') {
          await themeProvider.setThemeMode(ThemeMode.dark);
        }
        
        // AI zaten "Switching to light mode for you!" gibi mesaj verdi
        // Sistem mesajı eklemiyoruz, çünkü gereksiz tekrar olur
        
        debugPrint('✅ Theme changed successfully to: $themeName');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Theme change error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': '❌ ${AppLocalizations.of(context)!.aiChatThemeFailed}',
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }

  /// Toplu silme işlemini handle et
  Future<void> _handleBulkDelete(dynamic data) async {
    try {
      debugPrint('🗑️ Handling bulk delete: $data');
      
      final Map<String, dynamic> deleteData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final filters = deleteData['filters'];
      if (filters == null) {
        throw Exception('Filters are required for bulk delete');
      }
      
      final Map<String, dynamic> filterMap = filters is Map
          ? Map<String, dynamic>.from(filters)
          : {};
      
      debugPrint('   Filters: $filterMap');
      
      if (!mounted) return;
      
      // Onay mesajı ekle (chat içinde göster)
      _pendingBulkDeleteFilters = filterMap;
      _isWaitingBulkDeleteConfirmation.value = true;
      
      setState(() {
        _chatMessages.add({
          'role': 'bulk_delete_confirmation',
          'filters': filterMap,
          'message': _getBulkDeleteMessage(filterMap),
        });
      });
      _messagesUpdateTrigger.value++;
      _scrollToBottom();
      
      debugPrint('📝 Showing bulk delete confirmation in chat...');
    } catch (e, stackTrace) {
      debugPrint('❌ Bulk delete error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': '❌ ${AppLocalizations.of(context)!.aiChatDeleteFailed}',
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }
  
  /// Bütçe oluştur
  Future<void> _handleBudgetCreate(dynamic data) async {
    try {
      debugPrint('💰 Handling budget create: $data');
      
      final Map<String, dynamic> budgetData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final category = budgetData['category'] as String?;
      final limit = (budgetData['limit'] as num?)?.toDouble();
      final startDateStr = budgetData['startDate'] as String?;
      
      debugPrint('   Category: $category, Limit: $limit, StartDate: $startDateStr (Monthly)');
      
      if (category == null || limit == null) {
        throw Exception('Category and limit are required for budget creation');
      }
      
      // Sadece aylık bütçe destekleniyor
      const period = BudgetPeriod.monthly;
      
      // Parse start date
      DateTime startDate = DateTime.now();
      if (startDateStr != null && startDateStr.isNotEmpty && startDateStr != 'today') {
        try {
          final parsed = DateTime.parse(startDateStr);
          // UTC conversion'ı önle
          startDate = DateTime(parsed.year, parsed.month, parsed.day);
          debugPrint('   📅 Parsed start date: $startDate');
        } catch (e) {
          debugPrint('   ⚠️ Failed to parse start date: $startDateStr, using today');
          startDate = DateTime.now();
        }
      }
      
      if (!mounted) return;
      
      final provider = context.read<UnifiedProviderV2>();
      final themeProvider = context.read<ThemeProvider>();
      
      // Kategoriyi bul veya kullan
      String categoryName = category;
      String categoryId = '';
      final categories = provider.categories.where((cat) => 
        cat.displayName.toLowerCase() == category.toLowerCase() &&
        cat.categoryType == CategoryType.expense
      );
      
      if (categories.isNotEmpty) {
        categoryName = categories.first.displayName;
        categoryId = categories.first.id;
      } else {
        // Kategori yoksa, generic bir ID kullan veya hata ver
        throw Exception('Category not found: $category');
      }
      
      // Bütçe oluştur
      await provider.createBudget(
        categoryId: categoryId,
        categoryName: categoryName,
        limit: limit,
        period: period,
        isRecurring: false,
        startDate: startDate,
      );
      
      // Success mesajı
      final periodText = themeProvider.locale.languageCode == 'tr' ? 'aylık' : 'monthly';
      final limitText = CurrencyUtils.formatAmount(limit, themeProvider.currency);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': l10n.budgetCreated(categoryName, periodText, limitText),
          });
        });
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful budget creation');
        
        _scrollToBottom();
      }
      
      debugPrint('✅ Budget created successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Budget create error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': AppLocalizations.of(context)!.budgetCreateFailed,
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }
  
  /// Bütçe güncelle
  Future<void> _handleBudgetUpdate(dynamic data) async {
    try {
      debugPrint('📊 Handling budget update: $data');
      
      final Map<String, dynamic> budgetData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final category = budgetData['category'] as String?;
      final limit = (budgetData['limit'] as num?)?.toDouble();
      
      debugPrint('   Category: $category, New Limit: $limit');
      
      if (category == null || limit == null) {
        throw Exception('Category and limit are required for budget update');
      }
      
      if (!mounted) return;
      
      final provider = context.read<UnifiedProviderV2>();
      final themeProvider = context.read<ThemeProvider>();
      
      // Mevcut bütçeyi bul
      final existingBudget = provider.budgets.firstWhere(
        (b) => b.categoryName.toLowerCase() == category.toLowerCase(),
        orElse: () => throw Exception('Budget not found for category: $category'),
      );
      
      // Bütçeyi güncelle
      await provider.updateBudget(
        budgetId: existingBudget.id,
        limit: limit,
      );
      
      // Success mesajı
      final limitText = CurrencyUtils.formatAmount(limit, themeProvider.currency);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': l10n.budgetUpdated(category, limitText),
          });
        });
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful budget update');
        
        _scrollToBottom();
      }
      
      debugPrint('✅ Budget updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Budget update error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': AppLocalizations.of(context)!.budgetUpdateFailed,
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }
  
  /// Bütçe sil
  Future<void> _handleBudgetDelete(dynamic data) async {
    try {
      debugPrint('🗑️ Handling budget delete: $data');
      
      final Map<String, dynamic> budgetData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final category = budgetData['category'] as String?;
      
      debugPrint('   Category: $category');
      
      if (category == null) {
        throw Exception('Category is required for budget deletion');
      }
      
      if (!mounted) return;
      
      final provider = context.read<UnifiedProviderV2>();
      
      // Mevcut bütçeyi bul
      final existingBudget = provider.budgets.firstWhere(
        (b) => b.categoryName.toLowerCase() == category.toLowerCase(),
        orElse: () => throw Exception('Budget not found for category: $category'),
      );
      
      // Bütçeyi sil
      await provider.deleteBudget(existingBudget.id);
      
      // Success mesajı
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': l10n.budgetDeleted(category),
          });
        });
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful budget deletion');
        
        _scrollToBottom();
      }
      
      debugPrint('✅ Budget deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Budget delete error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': AppLocalizations.of(context)!.budgetDeleteFailed,
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }

  /// Kategori oluştur
  Future<void> _handleCategoryCreate(dynamic data) async {
    try {
      debugPrint('📁 Handling category create: $data');
      
      final Map<String, dynamic> categoryData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      final name = categoryData['name'] as String?;
      final categoryTypeStr = categoryData['categoryType'] as String?;
      
      debugPrint('   Name: $name, Type: $categoryTypeStr');
      
      if (name == null || categoryTypeStr == null) {
        throw Exception('Category name and type are required');
      }
      
      // CategoryType'a çevir
      final categoryType = categoryTypeStr == 'income' 
          ? CategoryType.income 
          : CategoryType.expense;
      
      if (!mounted) return;
      
      final provider = context.read<UnifiedProviderV2>();
      
      // Aynı isimde kategori var mı kontrol et
      final exists = provider.categories.any((cat) => 
        cat.name.toLowerCase() == name.toLowerCase() &&
        cat.categoryType == categoryType
      );
      
      if (exists) {
        // Zaten var
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'role': 'ai',
              'content': 'Bu kategori zaten mevcut. Başka bir isim deneyelim mi? 🤔',
            });
          });
          _messagesUpdateTrigger.value++;
          _scrollToBottom();
        }
        return;
      }
      
      // Yeni kategori oluştur
      await provider.createCategory(
        name: name,
        type: categoryType,
      );
      
      // Success mesajı
      if (mounted) {
        final typeDisplay = categoryType == CategoryType.income ? 'Gelir' : 'Gider';
        setState(() {
          _chatMessages.add({
            'role': 'system',
            'content': '✅ "$name" kategorisi ($typeDisplay) başarıyla oluşturuldu.',
          });
        });
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful category creation');
        
        _saveChatHistory();
        _scrollToBottom();
      }
      
      debugPrint('✅ Category created successfully');
      
      // 🎯 ÖNEMLİ: Kategori oluşturulduktan sonra AI'ya işlemi eklemesini söyle
      if (mounted) {
        debugPrint('🔄 Sending follow-up message to AI to add the transaction...');
        
        // AI'ya otomatik mesaj gönder: "Kategori hazır, şimdi işlemi ekle"
        final followUpMessage = categoryType == CategoryType.income
            ? 'Kategori hazır. Şimdi gelir işlemini ekle.'
            : 'Kategori hazır. Şimdi gider işlemini ekle.';
        
        // Conversation history'e kullanıcı mesajı olarak ekle
        _conversationHistory.add({
          'role': 'user',
          'content': followUpMessage,
        });
        
        // AI'ya gönder (ama chat UI'da gösterme, sadece arka planda)
        _sendFollowUpToAI(followUpMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Category create error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': '❌ ${AppLocalizations.of(context)!.aiCategoryCreationError}',
          });
        });
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }
  
  /// AI hesap sorusu soruyor mu kontrol et
  bool _isAskingForAccount(String message) {
    final lowerMessage = message.toLowerCase();
    
    // ŞARTLI İFADELER - Bunlar bilgilendirme, soru değil
    if (lowerMessage.contains('eğer') || 
        lowerMessage.contains('eger') ||
        lowerMessage.contains('isterseniz') ||
        lowerMessage.contains('if you want') ||
        lowerMessage.contains('if you would like')) {
      return false; // Şartlı ifade varsa buton gösterme
    }
    
    // ÇOK SPESİFİK kontroller - sadece gerçekten hesap/kart seçimi istenen durumlar
    final isAsking = 
        // Türkçe: "Hangi hesaptan/karttan/kredi kartı" gibi direkt soru kalıpları
        (lowerMessage.contains('hangi hesap') || 
         lowerMessage.contains('hangi kart') ||
         lowerMessage.contains('hangi hesab') || // "hesabından" gibi
         lowerMessage.contains('hangi kredi kart') || // "hangi kredi kartınızı"
         lowerMessage.contains('hangi banka') || // "hangi bankadan"
         // İngilizce: "Which account/card/credit card"
         lowerMessage.contains('which account') ||
         lowerMessage.contains('which card') ||
         lowerMessage.contains('which credit card') ||
         lowerMessage.contains('which bank') ||
         // "Hesap seç" / "Choose account" gibi imperatif
         (lowerMessage.contains('seç') && (lowerMessage.contains('hesap') || lowerMessage.contains('kart'))) ||
         (lowerMessage.contains('choose') && lowerMessage.contains('account')) ||
         (lowerMessage.contains('select') && lowerMessage.contains('account'))) &&
        // OLUMSUZ durumları hariç tut
        !lowerMessage.contains('portföy') && // "Hisse portföyümden"
        !lowerMessage.contains('portfolio') &&
        !(lowerMessage.contains(' kar ') || lowerMessage.contains('kar elde') || lowerMessage.contains('kar et')) && // "hesabımdan kar" ama "kart" değil
        !lowerMessage.contains('profit') &&
        !lowerMessage.contains('analiz') && // "hesabımı analiz"
        !lowerMessage.contains('analyze');
    
    if (isAsking) {
      debugPrint('🎯 AI is asking for account. Message: "$message"');
    } else {
      // Debug: Sadece gerektiğinde log (spam önlemek için)
    }
    
    return isAsking;
  }
  
  /// İşlem bilgilerinden fallback mesajı oluştur
  String _createTransactionFallbackMessage(dynamic transactionData) {
    if (transactionData == null) return '';
    
    final Map<String, dynamic> data = transactionData is Map<String, dynamic> 
        ? transactionData 
        : Map<String, dynamic>.from(transactionData as Map);
    
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currencySymbol = themeProvider.currency.symbol;
    final language = themeProvider.locale.languageCode;
    
    final type = data['type'] as String?;
    final amount = data['amount'];
    final category = data['category'] as String? ?? data['description'] as String?;
    final account = data['account'] as String?;
    final installmentCount = data['installmentCount'] as int? ?? 1;
    
    // Tutarı formatla
    final formattedAmount = amount != null 
        ? '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}$currencySymbol'
        : '';
    
    // Doğal konuşma dilinde mesaj oluştur
    String message = '';
    
    if (language == 'tr') {
      // Türkçe
      if (type == 'income') {
        message = '$formattedAmount';
        if (category != null && category.isNotEmpty) {
          message += ' $category geliri';
        }
        if (account != null && account.isNotEmpty) {
          message += " $account'a eklenecek.";
        }
      } else {
        // expense
        message = '$formattedAmount';
        if (category != null && category.isNotEmpty) {
          message += ' $category harcaması';
        }
        if (account != null && account.isNotEmpty) {
          message += " $account'tan";
        }
        if (installmentCount > 1) {
          message += ' $installmentCount taksit ile';
        }
        message += ' eklenecek.';
      }
    } else {
      // English
      if (type == 'income') {
        message = '$formattedAmount';
        if (category != null && category.isNotEmpty) {
          message += ' $category income';
        }
        message += ' will be added';
        if (account != null && account.isNotEmpty) {
          message += ' to $account';
        }
        message += '.';
      } else {
        // expense
        message = '$formattedAmount';
        if (category != null && category.isNotEmpty) {
          message += ' $category expense';
        }
        message += ' will be added';
        if (account != null && account.isNotEmpty) {
          message += ' from $account';
        }
        if (installmentCount > 1) {
          message += ' with $installmentCount installments';
        }
        message += '.';
      }
    }
    
    return message;
  }
  
  /// AI taksit sorusu mu soruyor kontrol et
  bool _isAskingForInstallment(String message) {
    final lowerMessage = message.toLowerCase();
    
    // ŞARTLI İFADELER - Bunlar bilgilendirme, soru değil
    if (lowerMessage.contains('eğer') || 
        lowerMessage.contains('eger') ||
        lowerMessage.contains('isterseniz') ||
        lowerMessage.contains('if you want') ||
        lowerMessage.contains('if you would like')) {
      return false; // Şartlı ifade varsa buton gösterme
    }
    
    // Taksit bilgisi zaten verilmiş mi kontrol et
    // Sadece KULLANICI mesajlarında ve NET taksit cevaplarında ara
    final hasInstallmentInHistory = _conversationHistory.any((msg) {
      if (msg['role'] != 'user') return false; // Sadece kullanıcı mesajları
      
      final content = (msg['content'] ?? '').toString().toLowerCase().trim();
      
      // "5 taksit", "12 taksit" gibi net taksit cevapları (başında/sonunda rakam olmalı)
      // "taksitli" gibi sıfatları dahil etme
      return RegExp(r'^\d+\s*taksit$|^\d+$|^peşin$|^pesin$').hasMatch(content) ||
             RegExp(r'\b\d+\s+taksit\b').hasMatch(content);
    });
    
    if (hasInstallmentInHistory) {
      debugPrint('⏭️ Installment already provided in conversation history');
      return false;
    }
    
    // Taksit SAYISI sorusu kontrolleri - çok spesifik olmalı
    final isAsking = 
        // Türkçe: "Kaç taksit" gibi direkt taksit SAYISI soruları
        lowerMessage.contains('kaç taksit') ||
        lowerMessage.contains('kac taksit') ||
        lowerMessage.contains('taksit sayısı') ||
        lowerMessage.contains('taksit sayisi') ||
        (lowerMessage.contains('kaç') && lowerMessage.contains('taksit')) ||
        (lowerMessage.contains('kac') && lowerMessage.contains('taksit')) ||
        // İngilizce: "How many installments"
        lowerMessage.contains('how many installment') ||
        lowerMessage.contains('installment count') ||
        lowerMessage.contains('number of installment');
    
    if (isAsking) {
      debugPrint('💳 AI is asking for installment. Message: "$message"');
    } else {
      // Debug: Sadece gerektiğinde log (spam önlemek için)
    }
    
    return isAsking;
  }
  
  /// Toplu silme onaylandı
  Future<void> _confirmBulkDelete() async {
    if (_pendingBulkDeleteFilters == null) return;
    
    _isWaitingBulkDeleteConfirmation.value = false;
    _isProcessing.value = true;
    
    try {
      debugPrint('✅ User confirmed bulk delete');
      
      // Onay mesajını kaldır
      setState(() {
        _chatMessages.removeWhere((msg) => msg['role'] == 'bulk_delete_confirmation');
      });
      
      // Loading mesajı ekle
      setState(() {
        _chatMessages.add({
          'role': 'ai',
          'content': '⏳ ${AppLocalizations.of(context)!.aiChatDeleteProcessing}',
        });
      });
      _messagesUpdateTrigger.value++;
      _scrollToBottom();
      
      // Silme işlemini gerçekleştir
      final startTime = DateTime.now();
      final result = await _aiService.bulkDeleteTransactions(filters: _pendingBulkDeleteFilters!);
      final duration = DateTime.now().difference(startTime);
      
      if (result != null && mounted) {
        final deletedCount = result['deletedCount'] as int? ?? 0;
        final message = result['message'] as String? ?? '';
        
        // AI usage bilgisini güncelle
        if (result['usage'] != null) {
          final provider = context.read<UnifiedProviderV2>();
          try {
            final usage = Map<String, dynamic>.from(result['usage'] as Map);
            final current = usage['current'] as int? ?? 0;
            final limit = usage['limit'] as int? ?? 1500;
            provider.updateAIUsageFromBackend(current, limit);
            
            // Local state'i de güncelle
            if (usage['daily'] != null) {
              final daily = Map<String, dynamic>.from(usage['daily'] as Map);
              final totalLimit = daily['limit'] as int? ?? _dailyLimit;
              final bonusCount = daily['bonusCount'] as int? ?? 0;
              final baseLimit = totalLimit - bonusCount;
              
              setState(() {
                _dailyUsage = daily['current'] as int? ?? 0;
                _dailyLimit = baseLimit;
                _bonusCount = bonusCount;
                _dailyRemaining = daily['remaining'] as int? ?? 0;
              });
              debugPrint('📊 Usage updated after bulk delete: $_dailyUsage/$baseLimit (Remaining: $_dailyRemaining)');
            }
          } catch (e) {
            debugPrint('⚠️ Failed to parse usage data after bulk delete: $e');
          }
        }
        
        // Loading mesajını kaldır
        setState(() {
          if (_chatMessages.isNotEmpty && 
              _chatMessages.last['content']?.toString().contains('⏳') == true) {
            _chatMessages.removeLast();
          }
        });
        
        // UnifiedProvider'ı yenile
        final provider = context.read<UnifiedProviderV2>();
        await provider.loadTransactions();
        
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': AppLocalizations.of(context)!.aiChatDeleteSuccess(message, deletedCount, duration.inMilliseconds),
          });
          _pendingBulkDeleteFilters = null;
        });
        _isProcessing.value = false;
        _messagesUpdateTrigger.value++;
        
        // ✨ Conversation history temizle (AI bir sonraki işlemde eski konuşmaları dikkate almasın)
        _conversationHistory.clear();
        debugPrint('🧹 Conversation history cleared after successful bulk delete');
        
        _scrollToBottom();
        
        debugPrint('✅ Bulk delete successful: $deletedCount transactions deleted in ${duration.inMilliseconds}ms');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Bulk delete execution error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': '❌ ${AppLocalizations.of(context)!.aiChatDeleteFailed}',
          });
          _pendingBulkDeleteFilters = null;
        });
        _isProcessing.value = false;
        _messagesUpdateTrigger.value++;
        _scrollToBottom();
      }
    }
  }
  
  /// Toplu silme iptal edildi
  void _cancelBulkDelete() {
    debugPrint('❌ User cancelled bulk delete');
    _isWaitingBulkDeleteConfirmation.value = false;
    
    setState(() {
      _pendingBulkDeleteFilters = null;
      
      // Onay mesajını kaldır
      _chatMessages.removeWhere((msg) => msg['role'] == 'bulk_delete_confirmation');
      
      _chatMessages.add({
        'role': 'ai',
        'content': 'Tamam, silme işlemini iptal ettim. İşlemleriniz güvende. 👍',
      });
    });
    
    _messagesUpdateTrigger.value++;
    _scrollToBottom();
  }
  
  /// Toplu silme için onay mesajı oluştur
  String _getBulkDeleteMessage(Map<String, dynamic> filters) {
    final days = filters['days'] as int? ?? 0;
    final transactionType = filters['transactionType'] as String? ?? 'all';
    
    String timeText;
    if (days == 0) {
      timeText = 'Bugünkü';
    } else if (days == 1) {
      timeText = 'Son 1 günkü';
    } else if (days == 7) {
      timeText = 'Son 1 haftaki';
    } else if (days == 30) {
      timeText = 'Son 1 ayki';
    } else {
      timeText = 'Son $days günkü';
    }
    
    String typeText;
    if (transactionType == 'expense') {
      typeText = 'harcamaları';
    } else if (transactionType == 'income') {
      typeText = 'gelirleri';
    } else {
      typeText = 'tüm işlemleri';
    }
    
    return '$timeText $typeText silmek üzeresiniz. Bu işlem geri alınamaz. Emin misiniz?';
  }

  Future<void> _createTransactionFromAI(dynamic data) async {
    try {
      debugPrint('🔄 Creating transaction from AI data: $data');
      debugPrint('   Data type: ${data.runtimeType}');
      
      // Ensure data is a Map
      final Map<String, dynamic> transactionData = data is Map 
          ? Map<String, dynamic>.from(data) 
          : {};
      
      debugPrint('   Parsed as Map: $transactionData');
      
      final provider = context.read<UnifiedProviderV2>();
      
      // bulk_add tipinde mi kontrol et
      final dataType = transactionData['type'] as String?;
      if (dataType == 'bulk_add') {
        debugPrint('🔄 Processing bulk_add - Multiple transactions');
        final transactions = transactionData['transactions'] as List?;
        if (transactions == null || transactions.isEmpty) {
          throw Exception('No transactions found in bulk_add!');
        }
        
        debugPrint('   Total transactions to create: ${transactions.length}');
        
        // Her bir transaction'ı paralel olarak oluştur (batch processing)
        int successCount = 0;
        const batchSize = 5; // 5'erli gruplar halinde işle
        
        for (int i = 0; i < transactions.length; i += batchSize) {
          final end = (i + batchSize < transactions.length) ? i + batchSize : transactions.length;
          final batch = transactions.sublist(i, end);
          
          debugPrint('   Processing batch ${(i ~/ batchSize) + 1}/${(transactions.length / batchSize).ceil()}: ${batch.length} transactions');
          
          // Batch'i paralel işle
          final futures = batch.map((txData) async {
            try {
              final tx = Map<String, dynamic>.from(txData as Map);
              await _createSingleTransactionFromAI(tx, provider);
              return true;
            } catch (e) {
              debugPrint('   ❌ Failed to create transaction: $e');
              return false;
            }
          }).toList();
          
          final results = await Future.wait(futures);
          successCount += results.where((success) => success).length;
          
          debugPrint('   Batch completed: ${results.where((success) => success).length}/${batch.length} successful');
        }
        
        debugPrint('✅ Bulk add completed: $successCount/${transactions.length} transactions created');
        return;
      }
      
      // Tek transaction için devam et
      await _createSingleTransactionFromAI(transactionData, provider);
      
    } catch (e, stackTrace) {
      debugPrint('❌ Transaction creation error: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Tek bir transaction oluştur (Single Responsibility)
  Future<void> _createSingleTransactionFromAI(
    Map<String, dynamic> transactionData,
    UnifiedProviderV2 provider,
  ) async {
    debugPrint('   Transaction data: $transactionData');
    
    // Hesap bul - Localized matching
      final accountName = transactionData['account'] as String?;
    debugPrint('   Account name from AI: $accountName');
    
    final l10n = AppLocalizations.of(context)!;
    
    // Hesap eşleştirme - daha kesin ve skorlu sistem
    AccountModel? account;
    if (accountName != null && accountName.isNotEmpty) {
      final searchName = accountName.toLowerCase().trim();
      
      // Her hesap için skor hesapla
      double bestScore = 0;
      AccountModel? bestMatch;
      
      for (final acc in provider.accounts) {
        double score = 0;
        
        // Localized tam ad oluştur (_getLocalizedAccountName mantığı)
        String localizedName = acc.name;
        if (acc.name == 'CASH_WALLET') {
          localizedName = l10n.cashWallet;
        } else {
          // Kart tipini temizle
          localizedName = localizedName
              .replaceAll(RegExp(r'\s*(kredi kartı|credit card|banka kartı|debit card|nakit|cash)\s*', caseSensitive: false), '')
              .trim();
        }
        
        final localizedType = acc.type == AccountType.credit 
            ? l10n.creditCard
            : acc.type == AccountType.debit 
                ? l10n.debitCard 
                : l10n.cash;
        
        final fullLocalizedName = '${localizedName} ${localizedType}'.toLowerCase();
        
        // 1. TAM EŞLEŞMELokalize isim tam eşleşme (en yüksek skor)
        if (fullLocalizedName == searchName) {
          score = 100;
        }
        // 2. Lokalize isim searchName'i içeriyor
        else if (fullLocalizedName.contains(searchName)) {
          score = 80;
        }
        // 3. SearchName lokalize ismi içeriyor
        else if (searchName.contains(fullLocalizedName)) {
          score = 70;
        }
        // 4. Sadece banka adı eşleşiyor (örn: "Garanti")
        else if (searchName.contains(localizedName.toLowerCase())) {
          score = 50;
        }
        // 5. Orijinal hesap adı ile eşleşme
        else if (acc.name.toLowerCase().contains(searchName)) {
          score = 40;
        }
        
        debugPrint('   Account matching: ${acc.name} → "$fullLocalizedName" → Score: $score');
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = acc;
        }
      }
      
      // En az %40 eşleşme olmalı, yoksa ilk hesabı kullan
      if (bestScore >= 40 && bestMatch != null) {
        account = bestMatch;
        debugPrint('   ✅ Best match: ${account.name} (Score: $bestScore)');
      } else {
        account = provider.accounts.first;
        debugPrint('   ⚠️ No good match found, using first account: ${account.name}');
      }
    } else {
      account = provider.accounts.first;
      debugPrint('   ⚠️ No account name provided, using first account: ${account.name}');
    }

      // Kategori bul veya oluştur
      final categoryName = transactionData['category'] as String? ?? transactionData['description'] as String?;
      final transactionType = transactionData['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense;
      
      debugPrint('   Category: $categoryName, Type: $transactionType');
      
      String? categoryId;
      if (categoryName != null && categoryName.isNotEmpty) {
        // Mevcut kategoriyi ara
        try {
          final existingCategory = provider.categories.firstWhere(
            (cat) => cat.displayName.toLowerCase() == categoryName.toLowerCase() &&
                     cat.categoryType == (transactionType == TransactionType.income 
                         ? CategoryType.income 
                         : CategoryType.expense),
          );
          categoryId = existingCategory.id;
          debugPrint('   ✅ Found existing category: ${existingCategory.displayName} (${existingCategory.id})');
        } catch (e) {
          // Kategori bulunamadı, yeni oluştur
          debugPrint('   🆕 Category not found, creating new: $categoryName');
          
          try {
            // Kategori adını capitalize et
            final capitalizedName = categoryName.isEmpty 
                ? 'Diğer' 
                : categoryName[0].toUpperCase() + categoryName.substring(1).toLowerCase();
            
            // Kategori rengini transaction type'a göre belirle
            final categoryColor = transactionType == TransactionType.income 
                ? '#34D399'  // Yeşil (gelir)
                : '#FF3B30'; // Kırmızı (gider)
            
            final newCategory = await provider.createCategory(
              type: transactionType == TransactionType.income 
                  ? CategoryType.income 
                  : CategoryType.expense,
              name: capitalizedName,
              iconName: categoryName.toLowerCase(),
              colorHex: categoryColor,
            );
            
            categoryId = newCategory.id;
            debugPrint('   ✅ New category created: $capitalizedName (${newCategory.id})');
            
            // Chat mesajı olarak göster
            if (mounted) {
              setState(() {
                _chatMessages.add({
                  'role': 'system',
                  'content': '**$capitalizedName** kategorisi oluşturuldu',
                });
              });
              _messagesUpdateTrigger.value++;
              _scrollToBottom();
            }
          } catch (createError) {
            debugPrint('   ❌ Failed to create category: $createError');
            // Fallback: İlk kategoriyi kullan
            final fallbackCategories = transactionType == TransactionType.income
                ? provider.incomeCategories
                : provider.expenseCategories;
            if (fallbackCategories.isNotEmpty) {
              categoryId = fallbackCategories.first.id;
              debugPrint('   ⚠️ Using fallback category: ${fallbackCategories.first.displayName}');
            }
          }
        }
      } else {
        // Kategori adı yoksa, default kategori kullan
        debugPrint('   ⚠️ No category name provided, using default');
        final defaultCategories = transactionType == TransactionType.income
            ? provider.incomeCategories
            : provider.expenseCategories;
        if (defaultCategories.isNotEmpty) {
          categoryId = defaultCategories.first.id;
        }
      }

      // Amount kontrol
      final amount = transactionData['amount'];
      debugPrint('   Amount: $amount (type: ${amount.runtimeType})');
      
      if (amount == null) {
        throw Exception('Amount is null!');
      }

      // Amount'u double'a çevir (String olabilir)
      final amountDouble = amount is num 
          ? amount.toDouble() 
          : double.tryParse(amount.toString()) ?? 0.0;
      
      debugPrint('   Amount as double: $amountDouble');

      // Tarihi parse et
      final dateStr = transactionData['date'] as String?;
      final transactionDate = _parseDate(dateStr);
      debugPrint('   Date string: $dateStr → Parsed date: $transactionDate');

      // Taksit bilgisini oku (kredi kartı için)
      final installmentCount = transactionData['installmentCount'] is num
          ? (transactionData['installmentCount'] as num).toInt()
          : int.tryParse(transactionData['installmentCount']?.toString() ?? '1') ?? 1;
      
      debugPrint('   Installment count: $installmentCount');

      // Transaction oluştur
      debugPrint('   Creating transaction...');
      
      // Kredi kartı ve taksitli işlem kontrolü
      if (account.type == AccountType.credit && installmentCount > 1 && transactionType == TransactionType.expense) {
        // Taksitli işlem oluştur
        debugPrint('   💳 Creating installment transaction (${installmentCount} installments)...');
        await provider.createInstallmentTransaction(
          sourceAccountId: account.id,
          totalAmount: amountDouble,
          count: installmentCount,
          description: transactionData['description'] as String? ?? '',
          categoryId: categoryId,
          startDate: transactionDate,
        );
        debugPrint('✅ Installment transaction created successfully!');
      } else {
        // Normal işlem oluştur
        await provider.createTransaction(
          type: transactionType,
          amount: amountDouble,
          description: transactionData['description'] as String? ?? '',
          categoryId: categoryId,
          sourceAccountId: account.id,
          transactionDate: transactionDate,
        );
        debugPrint('✅ Transaction created successfully!');
      }
  }

  /// Hisse alım/satım işlemi oluştur (Single Responsibility: Stock transaction creation)
  /// SOLID: Dependency Inversion - StockProvider'a depend ediyoruz
  Future<void> _createStockTransaction(Map<String, dynamic> data) async {
    try {
      debugPrint('📈 Creating stock transaction from AI data: $data');
      
      final stockProvider = context.read<StockProvider>();
      final unifiedProvider = context.read<UnifiedProviderV2>();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Parse stock transaction data
      final action = (data['action'] as String?)?.toLowerCase();
      final stockSymbol = (data['stockSymbol'] as String?)?.toUpperCase();
      final quantity = data['quantity'] is num 
          ? (data['quantity'] as num).toDouble()
          : double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;
      final price = data['price'] is num 
          ? (data['price'] as num).toDouble()
          : double.tryParse(data['price']?.toString() ?? '0');
      final accountName = data['account'] as String?;
      final dateStr = data['date'] as String?;
      
      debugPrint('   Action: $action, Symbol: $stockSymbol, Quantity: $quantity, Price: $price, Account: $accountName');
      
      // Validate data
      if (action == null || (action != 'buy' && action != 'sell')) {
        throw Exception('Invalid action: $action. Must be "buy" or "sell"');
      }
      if (stockSymbol == null || stockSymbol.isEmpty) {
        throw Exception('Stock symbol is required');
      }
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than 0');
      }
      
      // Find account
      final account = unifiedProvider.accounts.firstWhere(
        (acc) => acc.name.toLowerCase().contains(accountName?.toLowerCase() ?? ''),
        orElse: () => unifiedProvider.accounts.first,
      );
      debugPrint('   Found account: ${account.name}');
      
      // Find or fetch stock
      Stock? stock = stockProvider.watchedStocks
          .where((s) => s.symbol == stockSymbol)
          .firstOrNull;
      
      if (stock == null) {
        // Stock not in watchlist, search for it
        debugPrint('   Stock not in watchlist, searching...');
        final searchResults = await stockProvider.searchStocks(stockSymbol);
        stock = searchResults
            .where((s) => s.symbol == stockSymbol)
            .firstOrNull;
        
        if (stock == null) {
          throw Exception('Stock $stockSymbol not found');
        }
        
        // Add to watchlist
        await stockProvider.addWatchedStock(user.uid, stock);
        debugPrint('   ✅ Stock added to watchlist');
      }
      
      // Use provided price or current market price
      final transactionPrice = price ?? stock.currentPrice;
      debugPrint('   Transaction price: $transactionPrice');
      
      // Parse date
      final transactionDate = _parseDate(dateStr);
      debugPrint('   Transaction date: $transactionDate');
      
      // Create stock transaction with unique ID
      final transactionId = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stock_transactions')
          .doc()
          .id;
      
      final stockTransaction = StockTransaction(
        id: transactionId,
        userId: user.uid,
        stockSymbol: stockSymbol,
        stockName: stock.name, // Required field
        type: action == 'buy' 
            ? StockTransactionType.buy 
            : StockTransactionType.sell,
        quantity: quantity,
        price: transactionPrice,
        totalAmount: quantity * transactionPrice,
        transactionDate: transactionDate,
        accountId: account.id,
        commission: 0.0, // Default commission
        notes: 'AI tarafından oluşturuldu',
      );
      
      debugPrint('   Executing ${action} transaction...');
      
      // Execute transaction through StockProvider (Dependency Inversion)
      await stockProvider.executeStockTransaction(stockTransaction);
      
      debugPrint('✅ Stock transaction created successfully!');
    } catch (e, stackTrace) {
      debugPrint('❌ Stock transaction creation error: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow; // Hata _confirmTransaction'da yakalanacak
    }
  }

  /// Taksit seçimi gerekli mi kontrol et
  bool _checkIfNeedsInstallmentSelection(
    Map<String, dynamic> transactionData,
    String aiMessage,
  ) {
    try {
      // 1. Transaction type expense mi?
      final type = transactionData['type'] as String?;
      if (type != 'expense') {
        debugPrint('   Not an expense, no installment needed');
        return false;
      }

      // 2. installmentCount zaten var mı? (1'den büyük)
      final installmentCount = transactionData['installmentCount'];
      if (installmentCount != null && installmentCount is num && installmentCount > 1) {
        debugPrint('   Installment count already specified: $installmentCount');
        return false;
      }

      // 3. Account bilgisi var mı ve credit card mi?
      final accountName = transactionData['account'] as String?;
      if (accountName == null || accountName.isEmpty) {
        debugPrint('   No account specified, cannot check installment');
        return false;
      }

      // Account'u bul - transaction oluştururken kullanılan aynı mantıkla
      final provider = context.read<UnifiedProviderV2>();
      final l10n = AppLocalizations.of(context)!;
      final searchName = accountName.toLowerCase().trim();
      
      AccountModel? bestMatch;
      double bestScore = 0;
      
      for (final acc in provider.accounts) {
        double score = 0;
        
        // Localized tam ad oluştur
        String localizedName = acc.name;
        if (acc.name == 'CASH_WALLET') {
          localizedName = l10n.cashWallet;
        } else {
          localizedName = localizedName
              .replaceAll(RegExp(r'\s*(kredi kartı|credit card|banka kartı|debit card|nakit|cash)\s*', caseSensitive: false), '')
              .trim();
        }
        
        final localizedType = acc.type == AccountType.credit 
            ? l10n.creditCard
            : acc.type == AccountType.debit 
                ? l10n.debitCard 
                : l10n.cash;
        
        final fullLocalizedName = '$localizedName $localizedType'.toLowerCase();
        
        if (fullLocalizedName == searchName) {
          score = 100;
        } else if (fullLocalizedName.contains(searchName)) {
          score = 80;
        } else if (searchName.contains(fullLocalizedName)) {
          score = 70;
        } else if (searchName.contains(localizedName.toLowerCase())) {
          score = 50;
        } else if (acc.name.toLowerCase().contains(searchName)) {
          score = 40;
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = acc;
        }
      }
      
      final account = bestMatch ?? provider.accounts.first;
      debugPrint('   📍 Matched account: ${account.name} (Type: ${account.type}, Score: $bestScore)');

      // Kredi kartı ise taksit seçimi göster
      if (account.type == AccountType.credit) {
        debugPrint('   ✅ Credit card detected - showing installment selection');
        return true;
      }

      debugPrint('   ℹ️  Not a credit card (${account.type}), no installment needed');
      return false;
    } catch (e) {
      debugPrint('   ❌ Error checking installment selection: $e');
      return false;
    }
  }

  /// Tarih string'ini parse et
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }

    final lower = dateStr.toLowerCase().trim();
    final now = DateTime.now();

    // Bugün - şimdiki saati kullan
    if (lower == 'bugün' || lower == 'today') {
      return now;
    }

    // Dün - şimdiki saati koru
    if (lower == 'dün' || lower == 'yesterday') {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day, 
                      now.hour, now.minute, now.second, now.millisecond);
    }

    // Evvelsi gün - şimdiki saati koru
    if (lower == 'evvelsi gün' || lower == 'evvelsi') {
      final dayBefore = now.subtract(const Duration(days: 2));
      return DateTime(dayBefore.year, dayBefore.month, dayBefore.day,
                      now.hour, now.minute, now.second, now.millisecond);
    }

    // "15 ekim" formatı
    final monthMap = {
      'ocak': 1, 'şubat': 2, 'mart': 3, 'nisan': 4,
      'mayıs': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8,
      'eylül': 9, 'ekim': 10, 'kasım': 11, 'aralık': 12,
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    // "15 ekim" veya "15 october" pattern - şimdiki saati koru
    final match = RegExp(r'(\d{1,2})\s*(\w+)').firstMatch(lower);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final monthStr = match.group(2)?.toLowerCase();
      
      if (day != null && monthStr != null) {
        final month = monthMap[monthStr];
        if (month != null) {
          return DateTime(now.year, month, day,
                          now.hour, now.minute, now.second, now.millisecond);
        }
      }
    }

    // ISO format varsa parse et (UTC conversion olmadan)
    try {
      final parsed = DateTime.parse(dateStr);
      // ⚠️ IMPORTANT: DateTime.parse() UTC'ye çeviriyor!
      // Local timezone'da tutmak için yeniden oluştur
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
      );
    } catch (e) {
      // Parse edilemezse bugünü döndür
      return DateTime.now();
    }
  }

  void _scrollToBottom() {
    // Her zaman post-frame callback ile çağır (güvenli)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomImmediate();
    });
  }
  
  void _scrollToBottomImmediate() {
    if (!mounted || !_chatScrollController.hasClients) return;
    
    try {
      // Jump direkt (animasyon yok - daha hızlı ve güvenilir)
      _chatScrollController.jumpTo(
        _chatScrollController.position.maxScrollExtent,
      );
      debugPrint('📜 Scrolled to bottom');
    } catch (e) {
      debugPrint('⚠️ Scroll error: $e');
    }
  }
  
  /// Sayıyı formatla (1000 -> 1K, 100000 -> 100K)
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  /// Tutarı düzenle
  void _editAmount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final initialValue = _pendingTransactionData?['amount']?.toString() ?? '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController(text: initialValue);
        return AlertDialog(
          title: Text(l10n.localeName == 'tr' ? 'Tutarı Düzenle' : 'Edit Amount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.localeName == 'tr' ? 'Tutar girin' : 'Enter amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _pendingTransactionData!['amount'] = result;
      });
      _messagesUpdateTrigger.value++; // UI'ı güncelle
    }
  }

  /// Açıklamayı düzenle
  void _editDescription(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final initialValue = _pendingTransactionData?['description']?.toString() ?? '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController(text: initialValue);
        return AlertDialog(
          title: Text(l10n.localeName == 'tr' ? 'Açıklamayı Düzenle' : 'Edit Description'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.localeName == 'tr' ? 'Açıklama girin' : 'Enter description',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _pendingTransactionData!['description'] = result;
      });
      _messagesUpdateTrigger.value++; // UI'ı güncelle
    }
  }

  /// Kategoriyi düzenle
  void _editCategory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final initialValue = _pendingTransactionData?['category']?.toString() ?? '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController(text: initialValue);
        return AlertDialog(
          title: Text(l10n.localeName == 'tr' ? 'Kategoriyi Düzenle' : 'Edit Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.localeName == 'tr' ? 'Kategori girin' : 'Enter category',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _pendingTransactionData!['category'] = result;
      });
      _messagesUpdateTrigger.value++; // UI'ı güncelle
    }
  }

  /// Kartı/Hesabı düzenle
  void _editAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<UnifiedProviderV2>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mevcut işlemin türünü bul
    final currentAccountName = _pendingTransactionData?['account']?.toString();
    AccountType? currentAccountType;
    
    // Mevcut hesabı bul
    if (currentAccountName != null) {
      final currentAccount = provider.accounts.firstWhere(
        (acc) => _getLocalizedAccountName(acc, context) == currentAccountName,
        orElse: () => provider.accounts.first,
      );
      currentAccountType = currentAccount.type;
    }
    
    // Hesapları filtrele: Eğer kredi kartı ise, sadece kredi kartlarını göster
    List<AccountModel> filteredAccounts;
    if (currentAccountType == AccountType.credit) {
      filteredAccounts = provider.accounts.where((acc) => acc.type == AccountType.credit).toList();
    } else {
      filteredAccounts = provider.accounts;
    }

    if (filteredAccounts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentAccountType == AccountType.credit
                  ? (l10n.localeName == 'tr' ? 'Kredi kartı bulunamadı' : 'No credit card found')
                  : (l10n.localeName == 'tr' ? 'Hesap bulunamadı' : 'No accounts found'),
            ),
          ),
        );
      }
      return;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.localeName == 'tr' ? 'Hesap Seçin' : 'Select Account',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Divider
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              
              // Account List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredAccounts.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final account = filteredAccounts[index];
                    final localizedName = _getLocalizedAccountName(account, context);
                    
                    // Icon based on account type
                    IconData accountIcon;
                    Color iconColor;
                    
                    switch (account.type) {
                      case AccountType.credit:
                        accountIcon = Icons.credit_card;
                        iconColor = const Color(0xFFFF6B6B);
                        break;
                      case AccountType.debit:
                        accountIcon = Icons.account_balance_wallet;
                        iconColor = const Color(0xFF4ECDC4);
                        break;
                      case AccountType.cash:
                        accountIcon = Icons.payments_outlined;
                        iconColor = const Color(0xFF95E1D3);
                        break;
                    }
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext, localizedName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  accountIcon,
                                  size: 20,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Account Name
                              Expanded(
                                child: Text(
                                  localizedName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              
                              // Arrow
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: isDark 
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Divider
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              
              // Cancel Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6D6D70),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _pendingTransactionData!['account'] = result;
      });
      _messagesUpdateTrigger.value++; // UI'ı güncelle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // Custom positioning veya default positioning
        final leftPosition = widget.customLeft;
        final rightPosition = widget.customRight ?? FabPositioning.getRightPosition(context);
        final bottomPosition = widget.customBottom ?? FabPositioning.getBottomPosition(context);
        
        return Positioned(
          left: leftPosition,
          right: leftPosition == null ? rightPosition : null,
          bottom: bottomPosition,
          child: _buildCollapsedFAB(isDark),
        );
      },
    );
  }

  Widget _buildCollapsedFAB(bool isDark) {
    final fabSize = FabPositioning.getFabSize(context);
    final iconSize = FabPositioning.getIconSize(context);
    
    return GestureDetector(
      key: widget.tutorialKey, // Tutorial key ekle
      onTap: _toggleExpand,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: fabSize,
        height: fabSize,
        decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF232326).withOpacity(0.85)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.18)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0xFFE5E5EA),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: isDark ? Colors.white : const Color(0xFF6D6D70),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

}

// ==================== AI CHAT PAGE WRAPPER ====================
class _AIChatPageWrapper extends StatefulWidget {
  final _QuickAddChatFABState parent;

  const _AIChatPageWrapper({
    required this.parent,
  });

  @override
  State<_AIChatPageWrapper> createState() => _AIChatPageWrapperState();
}

class _AIChatPageWrapperState extends State<_AIChatPageWrapper> with WidgetsBindingObserver {
  // ChangeNotifier listener sistemi kaldırıldı
  // ValueNotifier ile state yönetimi yapılıyor
  
  double _previousKeyboardHeight = 0;
  
  // Banner Ad 1 (Header altında)
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  // Banner Ad 2 (Input üstünde)
  BannerAd? _bannerAd2;
  bool _isBannerAd2Loaded = false;
  
  // Interstitial Ad (Açıkken Reklam)
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
    _loadBannerAd2();
    _checkAndShowInterstitialAd();
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd2?.dispose();
    _interstitialAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// Banner reklamı yükle (Header altında - 1. Banner)
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-8222173839637306/8471335231' // Android Banner Ad Unit ID 1
          : 'ca-app-pub-8222173839637306/1234567890', // iOS Banner Ad Unit ID 1
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
          debugPrint('✅ Banner ad 1 loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad 1 failed to load: $error');
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
            });
          }
          ad.dispose();
        },
      ),
    );
    
    _bannerAd?.load();
  }
  
  /// Banner reklamı yükle (Input üstünde - 2. Banner)
  void _loadBannerAd2() {
    _bannerAd2 = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-8222217303967306/1932264468' // Android Banner Ad Unit ID 2 (yeni oluşturulan)
          : 'ca-app-pub-8222217303967306/1932264468', // iOS Banner Ad Unit ID 2 (aynı ID - AdMob'dan aldığınız)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAd2Loaded = true;
            });
          }
          debugPrint('✅ Banner ad 2 loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad 2 failed to load: $error');
          if (mounted) {
            setState(() {
              _isBannerAd2Loaded = false;
            });
          }
          ad.dispose();
        },
      ),
    );
    
    _bannerAd2?.load();
  }
  
  /// Interstitial reklamı yükle
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-8222173839637306/2064982630' // Android Interstitial Ad Unit ID
          : 'ca-app-pub-8222173839637306/1234567891', // iOS Interstitial Ad Unit ID (değiştirin)
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          
          // Reklam event'lerini dinle
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('📱 Interstitial ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('❌ Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }
  
  /// Chat açılma sayısını kontrol et ve interstitial reklam göster
  /// 3., 6., 9., 12. ... açılışlarda reklam gösterir
  Future<void> _checkAndShowInterstitialAd() async {
    try {
      // Premium kontrolü
      final premiumService = context.read<PremiumService>();
      if (premiumService.isPremium) {
        debugPrint('👑 Premium user - No interstitial ad');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Kullanıcıya özel sayaç key
      final countKey = 'ai_chat_open_count_${user.uid}';
      
      // Mevcut sayacı al (default: 0)
      int currentCount = prefs.getInt(countKey) ?? 0;
      
      // Sayacı artır
      currentCount++;
      await prefs.setInt(countKey, currentCount);
      
      debugPrint('🔢 Chat open count: $currentCount');
      
      // 3'ün katlarında reklam göster (3, 6, 9, 12, ...)
      if (currentCount % 3 == 0) {
        debugPrint('🎬 Showing interstitial ad at count: $currentCount');
        
        // Reklamı yükle
        _loadInterstitialAd();
        
        // Reklamın yüklenmesi için kısa bir süre bekle
        await Future.delayed(const Duration(seconds: 2));
        
        // Yüklendiyse göster
        if (_isInterstitialAdLoaded && _interstitialAd != null) {
          await _interstitialAd!.show();
        } else {
          debugPrint('⏳ Interstitial ad not ready yet');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking/showing interstitial ad: $e');
    }
  }
  
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    // Klavye yüksekliğini kontrol et
    final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Klavye açılıyorsa (yükseklik artıyorsa)
    if (currentKeyboardHeight > _previousKeyboardHeight && currentKeyboardHeight > 0) {
      // Kısa bir delay ile scroll yap (klavye açılma animasyonu için)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.parent._scrollToBottom();
        }
      });
    }
    
    _previousKeyboardHeight = currentKeyboardHeight;
  }
  
  /// Sayıyı formatla (1000 -> 1K, 100000 -> 100K)
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1C1C1E),
                    const Color(0xFF2C2C2E),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
          ),
        ),
      child: Column(
        children: [
          // Modern Header (basit, arkaplan yok)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Qanta AI + Beta badge
                      Row(
                        children: [
                          Text(
                            'Qanta AI',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.ioSBlue.withOpacity(0.8),
                                  AppColors.mintGreen.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BETA',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)!.aiChatAssistant,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Compact AI Limit Indicator - Consumer ile anlık güncelleme
                Consumer<UnifiedProviderV2>(
                  builder: (context, provider, _) {
                    // UnifiedProviderV2'den güncel değerleri al
                    final currentUsage = provider.aiUsageCurrent;
                    final baseLimit = provider.aiUsageLimit;
                    
                    // Bonus bilgisini local state'den al (Firebase'den yüklenecek)
                    final bonusCount = widget.parent._bonusCount;
                    final totalLimit = baseLimit + bonusCount;
                    
                    return AILimitIndicator(
                      currentUsage: currentUsage,
                      totalLimit: totalLimit,
                      bonusCount: bonusCount,
                      bonusAvailable: widget.parent._bonusAvailable,
                      maxBonus: widget.parent._maxBonus,
                      isCompact: true,
                      onAdWatched: () async {
                    // Reklam izlenince Firebase'den güncel limit bilgilerini yükle
                    debugPrint('🎬 Ad watched - Reloading daily usage...');
                    
                    // Firebase'e yazma işleminin tamamlanması için kısa delay
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    await widget.parent._loadDailyUsage();
                    
                    debugPrint('✅ Daily usage reloaded:');
                    debugPrint('   Usage: ${widget.parent._dailyUsage}');
                    debugPrint('   Base Limit: ${widget.parent._dailyLimit}');
                    debugPrint('   Bonus: ${widget.parent._bonusCount}');
                    debugPrint('   Total: ${widget.parent._dailyLimit + widget.parent._bonusCount}');
                    debugPrint('   Remaining: ${widget.parent._dailyRemaining}');
                    
                        // Parent'ı güncelle (QuickAddChatFABState)
                        if (widget.parent.mounted) {
                          widget.parent.setState(() {
                            debugPrint('🔄 Parent state updated after ad watch');
                          });
                        }
                        // Child'ı da güncelle (_AIChatPageWrapper)
                        if (mounted) {
                          setState(() {
                            debugPrint('🔄 Child state updated after ad watch');
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Banner Ad 1 - Header altında - Free kullanıcılar için
          Consumer<PremiumService>(
            builder: (context, premiumService, _) {
              // Premium kullanıcılar için reklam gösterme
              if (premiumService.isPremium) {
                return const SizedBox.shrink();
              }
              
              // Reklam yüklüyse göster, değilse shrink (gizle)
              if (_isBannerAdLoaded && _bannerAd != null) {
                return Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: AdWidget(ad: _bannerAd!),
                );
              }
              
              // Reklam yüklenmemişse shrink ile gizle
              return const SizedBox.shrink();
            },
          ),

          // Messages - ValueListenableBuilder ile wrap (parent setState'i dinle)
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: widget.parent._messagesUpdateTrigger,
              builder: (context, updateCount, child) {
                debugPrint('🔄 ListView rebuilding... Message count: ${widget.parent._chatMessages.length}, Update: $updateCount');
                return ListView.builder(
                  controller: widget.parent._chatScrollController,
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.parent._chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.parent._chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    final isTyping = msg['role'] == 'typing';
                    final isBulkTransactions = msg['role'] == 'bulk_transactions';
                    final isAccountSelection = msg['role'] == 'account_selection';
                    final isAccountSelectionInline = msg['role'] == 'account_selection_inline';
                    final isInstallmentSelection = msg['role'] == 'installment_selection';
                    final isLimitError = msg['role'] == 'limit_error';
                    final isBulkDeleteConfirmation = msg['role'] == 'bulk_delete_confirmation';
                
                // Limit Error - Premium kontrolü ile
                if (isLimitError) {
                  final errorMessage = msg['content'] as String;
                  
                  return Consumer2<PremiumService, RewardedAdService>(
                    builder: (context, premiumService, rewardedAdService, _) {
                      final isPremium = premiumService.isPremium;
                      final bonusAvailable = widget.parent._bonusAvailable;
                      final isAdReady = rewardedAdService.isAdReady;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 0, right: 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sadece Mesaj (icon yok)
                              Text(
                                errorMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                                
                              // Butonlar - Free kullanıcılar için
                              if (!isPremium) ...[
                                const SizedBox(height: 12),
                                
                                // Reklam İzle Butonu - Sadece bonus varsa
                                if (bonusAvailable) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isAdReady
                                          ? () async {
                                              final success = await rewardedAdService.showRewardedAd();
                                              if (success && mounted) {
                                                // 🔔 Reklam izlenince güncel bilgileri yükle
                                                debugPrint('🎁 Ad rewarded, reloading AI limits...');
                                                await Future.delayed(const Duration(milliseconds: 500));
                                                
                                                // UnifiedProviderV2'den güncel AI limitini yükle
                                                final provider = context.read<UnifiedProviderV2>();
                                                await provider.loadAIUsage();
                                                
                                                // Local state'i de güncelle
                                                await widget.parent._loadDailyUsage();
                                                if (widget.parent.mounted) {
                                                  widget.parent.setState(() {});
                                                }
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                                debugPrint('✅ AI limits reloaded after ad');
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.play_circle_filled, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            isAdReady ? AppLocalizations.of(context)!.watchAdBonus : AppLocalizations.of(context)!.adLoading,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                
                                // Premium Butonu - Her zaman göster
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.push('/premium-offer');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9500),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.upgradeToPremium,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                
                // Bulk Delete Confirmation - Inline onay
                if (isBulkDeleteConfirmation) {
                  final deleteMessage = msg['message'] as String? ?? '';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF4C4C).withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4C4C).withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // İkon + Mesaj
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4C4C).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFFF4C4C),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Toplu Silme Onayı',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        deleteMessage,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bu işlem geri alınamaz.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFF4C4C),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                // Single Transaction Account Selection kaldırıldı - artık inline gösteriliyor
                
                // Account Selection - Interaktif hesap seçimi (bulk)
                if (isAccountSelection) {
                  return AccountSelectionMessage(
                    onAccountSelected: (accountId, accountName) {
                      final pendingTransactions = msg['pending_transactions'] as List<dynamic>?;
                      
                      // Hesap seçim mesajını kaldır
                      widget.parent.setState(() {
                        widget.parent._chatMessages.removeAt(index);
                        
                        // Seçilen hesabı göster (sistem mesajı)
                        widget.parent._chatMessages.add({
                          'role': 'system',
                          'content': '✅ $accountName seçildi',
                        });
                        
                        // Transaction kartlarını göster (accountId ile)
                        widget.parent._chatMessages.add({
                          'role': 'bulk_transactions',
                          'transactions': pendingTransactions,
                          'selected_account_id': accountId,
                        });
                        
                        widget.parent._messagesUpdateTrigger.value++;
                      });
                      widget.parent._scrollToBottom();
                    },
                  );
                }
                
                // Inline Account Selection (Normal transaction için hesap seçimi)
                // Account selection is shown above input, not in chat
                if (isAccountSelectionInline) {
                  return const SizedBox.shrink();
                }
                
                // Installment Selection (Taksit seçimi)
                // Artık input üzerinde gösteriliyor, chat listesinde gösterme
                if (isInstallmentSelection) {
                  return const SizedBox.shrink();
                }
                
                // Typing indicator - ChatGPT tarzı thinking mesajı
                if (isTyping) {
                  final l10n = AppLocalizations.of(context)!;
                  final thinkingText = l10n.localeName == 'tr' 
                      ? 'Düşünüyor...'
                      : l10n.localeName == 'de'
                          ? 'Denke...'
                          : 'Thinking...';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ChatGPTThinkingIndicator(
                        isDark: isDark,
                        thinkingText: thinkingText,
                      ),
                    ),
                  );
                }
                    
                    // Bulk Transactions - WhatsApp tarzı
                    if (isBulkTransactions) {
                      final transactions = msg['transactions'] as List<dynamic>?;
                      final selectedAccountId = msg['selected_account_id'] as String?;
                      
                      if (transactions != null && transactions.isNotEmpty) {
                        return BulkTransactionChatView(
                          transactions: transactions.cast<Map<String, dynamic>>(),
                          preSelectedAccountId: selectedAccountId,
                          onClose: () {
                            // İptal mesajı ekle
                            widget.parent.setState(() {
                              widget.parent._chatMessages.removeAt(index);
                              widget.parent._chatMessages.add({
                                'role': 'system',
                                'content': 'İşlem iptal edildi.',
                              });
                              widget.parent._conversationHistory.add({
                                'role': 'model',
                                'content': 'İşlem iptal edildi.',
                              });
                              widget.parent._messagesUpdateTrigger.value++;
                            });
                            widget.parent._saveChatHistory();
                          },
                          onSaved: (count) {
                            // Başarı mesajı ekle
                            widget.parent.setState(() {
                              widget.parent._chatMessages.removeAt(index);
                              widget.parent._chatMessages.add({
                                'role': 'system',
                                'content': '✅ $count işlem başarıyla eklendi!',
                              });
                              widget.parent._conversationHistory.add({
                                'role': 'model',
                                'content': '✅ $count işlem başarıyla eklendi!',
                              });
                              widget.parent._messagesUpdateTrigger.value++;
                            });
                            widget.parent._saveChatHistory();
                            widget.parent._scrollToBottom();
                          },
                        );
                      }
                    }
                    
                    // Boş mesajları gösterme ve UTF-16 geçersiz karakterleri temizle
                    String content = (msg['content'] as String?)?.trim() ?? '';
                    if (content.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    // UTF-16 geçersiz karakterleri temizle (malformed string hatasını önle)
                    try {
                      content = content.replaceAll(RegExp(r'[\uFFFE\uFFFF]'), ''); // Geçersiz UTF-16 karakterlerini temizle
                      // Surrogate pair'leri kontrol et
                      content = String.fromCharCodes(
                        content.runes.where((rune) {
                          return rune >= 0 && rune <= 0xD7FF || rune >= 0xE000 && rune <= 0x10FFFF;
                        }),
                      );
                    } catch (e) {
                      debugPrint('⚠️ UTF-16 cleaning error: $e');
                      // Hata olursa basit temizleme
                      content = content.replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
                    }
                    
                    // Mesajın animasyon durumunu kontrol et
                    final isAI = msg['role'] == 'ai' || msg['role'] == 'assistant';
                    final shouldAnimateFlag = msg['shouldAnimate'] as bool? ?? false;
                    final shouldAnimate = isAI && shouldAnimateFlag && index == widget.parent._lastAnimatedMessageIndex;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: isUser 
                              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                              : EdgeInsets.zero, // AI mesajları için padding yok
                          decoration: isUser
                              ? BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6D6D70), Color(0xFF434343)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6D6D70).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null, // AI mesajları için arka plan yok
                          child: isUser 
                            ? Text(
                            content,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.4,
                                  color: Colors.white,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // AI mesajı
                                  (shouldAnimate && isAI)
                                ? AnimatedTypingMessage(
                                    fullMessage: content,
                                    isDark: isDark,
                                    wordsPerSecond: 18, // Karakter bazlı, smooth akış
                                    onComplete: () {
                                      // Animasyon tamamlandı - flag'i kaldır
                                      if (index < widget.parent._chatMessages.length) {
                                        widget.parent._chatMessages[index]['shouldAnimate'] = false;
                                      }
                                      // Scroll yap
                                      widget.parent._scrollToBottom();
                                    },
                                  )
                                : MarkdownBody(
                                    data: content,
                                    styleSheet: MarkdownStyleSheet(
                                      p: GoogleFonts.inter(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      strong: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500, // Bold yerine medium
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      em: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                      h1: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      h2: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      h3: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      listBullet: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: const Color(0xFF6D6D70),
                                      ),
                                      code: GoogleFonts.jetBrainsMono(
                                        fontSize: 14,
                                        backgroundColor: isDark 
                                          ? const Color(0xFF1C1C1E) 
                                          : const Color(0xFFF5F5F5),
                                        color: isDark ? Colors.green.shade500 : const Color(0xFF059669),
                                      ),
                                      blockquote: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                  // Token bilgisi (debug modda veya yetkili kullanıcılar için)
                                  if (isAI && _shouldShowTokenInfo()) ...[
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final tokenUsage = msg['tokenUsage'] as Map<String, dynamic>?;
                                        if (tokenUsage == null) return const SizedBox.shrink();
                                        
                                        final totalTokens = tokenUsage['totalTokenCount'] as int? ?? 0;
                                        final promptTokens = tokenUsage['promptTokenCount'] as int? ?? 0;
                                        final responseTokens = tokenUsage['candidatesTokenCount'] as int? ?? 0;
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? const Color(0xFF1C1C1E).withOpacity(0.5)
                                                : const Color(0xFFF5F5F5).withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '🔢 Tokens: $totalTokens (P: $promptTokens, R: $responseTokens)',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark 
                                                  ? Colors.white.withOpacity(0.6)
                                                  : Colors.black54,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Onay Butonları - Transaction veya Bulk Delete
          // Account Selection Buttons - Input'un üstünde
          ValueListenableBuilder<bool>(
            valueListenable: widget.parent._isWaitingAccountSelection,
            builder: (context, isWaitingAccount, child) {
              if (!isWaitingAccount) return const SizedBox.shrink();
              
              final provider = context.watch<UnifiedProviderV2>();
              final accounts = provider.accounts;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.credit_card_rounded,
                            color: Color(0xFF6D6D70),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hesap seçin',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hesap butonları - Yatay scroll
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: accounts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // Hesap seçildi - AI'a mesaj olarak gönder
                                debugPrint('💳 Account selected: ${account.name}');
                                
                                // Account selection durumunu kapat
                                widget.parent._isWaitingAccountSelection.value = false;
                                
                                // Controller'a localized hesap adını set et ve gönder
                                final localizedName = _getLocalizedAccountName(account, context);
                                widget.parent._controller.text = localizedName;
                                await widget.parent._sendMessage();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      account.type == AccountType.credit
                                          ? Icons.credit_card_rounded
                                          : account.type == AccountType.cash
                                          ? Icons.payments_rounded
                                          : Icons.account_balance_wallet_rounded,
                                      color: const Color(0xFF6D6D70),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLocalizedAccountName(account, context),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Quick Reply Buttons - Input'un üstünde (account selection aktif değilse)
          ValueListenableBuilder<bool>(
            valueListenable: widget.parent._isWaitingAccountSelection,
            builder: (context, isWaitingAccount, child) {
              // Account selection aktifse quick replies gösterme
              if (isWaitingAccount) return const SizedBox.shrink();
              
              // Quick replies yoksa gösterme
              if (widget.parent._quickReplies.isEmpty) return const SizedBox.shrink();
              
              final isDark = Theme.of(context).brightness == Brightness.dark;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '💡 Öneriler',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    // Hızlı yanıtlar
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.parent._quickReplies.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final reply = widget.parent._quickReplies[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      // Haptic feedback
                                      // HapticFeedback.lightImpact();
                                      // Hızlı cevabı gönder
                                      widget.parent._controller.text = reply;
                                      await widget.parent._sendMessage();
                                    },
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6D6D70).withOpacity(0.95),
                                            const Color(0xFF6D6D70).withOpacity(0.75),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6D6D70).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            reply,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Confirmation Buttons
          ValueListenableBuilder<bool>(
            valueListenable: widget.parent._isWaitingConfirmation,
            builder: (context, isWaitingTransaction, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: widget.parent._isWaitingBulkDeleteConfirmation,
                builder: (context, isWaitingBulkDelete, child) {
                  final isWaiting = isWaitingTransaction || isWaitingBulkDelete;
                  debugPrint('🔘 Building buttons - Transaction: $isWaitingTransaction, BulkDelete: $isWaitingBulkDelete');
                  
              return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // İşlem Detayları - Kompakt & Minimal Tasarım
                      if (isWaitingTransaction && widget.parent._pendingTransactionData != null)
                        ValueListenableBuilder<int>(
                          valueListenable: widget.parent._messagesUpdateTrigger,
                          builder: (context, _, __) {
                            return Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                final userCurrency = themeProvider.currency;
                                final data = widget.parent._pendingTransactionData!;
                                final isStock = data['type'] == 'stock';
                                final l10n = AppLocalizations.of(context)!;
                            
                            // Tutar hesapla
                            double amount;
                            if (isStock) {
                              final quantity = data['quantity'];
                              final price = data['price'];
                              amount = (quantity != null && price != null) 
                                  ? (double.tryParse(quantity.toString()) ?? 0) * (double.tryParse(price.toString()) ?? 0)
                                  : 0;
                            } else {
                              amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.06),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tutar - Düzenlenebilir
                                  Builder(
                                    builder: (ctx) => _buildInfoRow(
                                      label: l10n.localeName == 'tr' ? 'Tutar' : 'Amount',
                                      value: CurrencyUtils.formatAmount(amount, userCurrency),
                                      isDark: isDark,
                                      isHighlighted: true,
                                      onEdit: isStock ? null : () => widget.parent._editAmount(ctx),
                                    ),
                                  ),
                                  
                                  // Açıklama (varsa) - Düzenlenebilir
                                  if (isStock)
                                    ...[
                                      const SizedBox(height: 10),
                                      _buildInfoRow(
                                        label: l10n.localeName == 'tr' ? 'Detay' : 'Details',
                                        value: _buildStockDetails(data, userCurrency, l10n),
                                        isDark: isDark,
                                        // Hisse detayı düzenlenemez
                                      ),
                                    ]
                                  else if (data['description'] != null && data['description'].toString().isNotEmpty)
                                    ...[
                                      const SizedBox(height: 10),
                                      Builder(
                                        builder: (ctx) => _buildInfoRow(
                                          label: l10n.localeName == 'tr' ? 'Açıklama' : 'Description',
                                          value: data['description'],
                                          isDark: isDark,
                                          onEdit: () => widget.parent._editDescription(ctx),
                                        ),
                                      ),
                                    ],
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Kategori - Düzenlenebilir
                                  Builder(
                                    builder: (ctx) => _buildInfoRow(
                                      label: l10n.localeName == 'tr' ? 'Kategori' : 'Category',
                                      value: isStock 
                                          ? (l10n.localeName == 'tr' ? 'Hisse İşlemi' : 'Stock Transaction')
                                          : (data['category'] ?? (l10n.localeName == 'tr' ? 'Kategori' : 'Category')),
                                      isDark: isDark,
                                      onEdit: isStock ? null : () => widget.parent._editCategory(ctx),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Kart/Hesap - Düzenlenebilir
                                  Builder(
                                    builder: (ctx) => _buildInfoRow(
                                      label: l10n.localeName == 'tr' ? 'Kart' : 'Card',
                                      value: data['account'] ?? (l10n.localeName == 'tr' ? 'Hesap' : 'Account'),
                                      isDark: isDark,
                                      onEdit: () => widget.parent._editAccount(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            );
                              },
                            );
                          },
                        ),
                      
                      // Onay Butonları
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isWaiting ? 60 : 0,
                        child: isWaiting
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Cancel button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (isWaitingBulkDelete) {
                                        widget.parent._cancelBulkDelete();
                                      } else {
                                        widget.parent._cancelTransaction();
                                      }
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: Text(
                                      AppLocalizations.of(context)!.aiChatCancelButton,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF3C3C3E) : const Color(0xFFE0E0E0),
                                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Confirm button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (isWaitingBulkDelete) {
                                        widget.parent._confirmBulkDelete();
                                      } else {
                                        widget.parent._confirmTransaction();
                                      }
                                    },
                                    icon: Icon(
                                      isWaitingBulkDelete 
                                          ? Icons.delete_rounded 
                                          : Icons.check_circle_rounded, 
                                      size: 18,
                                    ),
                                    label: Text(
                                      isWaitingBulkDelete 
                                          ? 'Sil' 
                                          : AppLocalizations.of(context)!.aiChatConfirmButton,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isWaitingBulkDelete 
                                          ? const Color(0xFFFF4C4C)
                                          : const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
                              );
                            },
                          ),

                  // Installment Selection Chips (Horizontal above input)
                  ValueListenableBuilder<int>(
                    valueListenable: widget.parent._messagesUpdateTrigger,
                    builder: (context, _, child) {
                      // Check if last message is installment_selection
                      final hasInstallmentSelection = widget.parent._chatMessages.isNotEmpty &&
                          widget.parent._chatMessages.last['role'] == 'installment_selection';
                      
                      if (!hasInstallmentSelection) {
                        return const SizedBox.shrink();
                      }
                      
                      final lastMsg = widget.parent._chatMessages.last;
                      final pendingData = lastMsg['pending_transaction'] as Map<String, dynamic>?;
                      
                      return InstallmentSelectionMessage(
                        onInstallmentSelected: (installmentCount) async {
                          // Remove installment selection message
                          widget.parent.setState(() {
                            widget.parent._chatMessages.removeLast();
                            widget.parent._messagesUpdateTrigger.value++;
                          });
                          
                          if (pendingData != null && pendingData.isNotEmpty) {
                            // Has transaction data, add installmentCount and confirm
                            pendingData['installmentCount'] = installmentCount;
                            widget.parent._pendingTransactionData = pendingData;
                            widget.parent._isWaitingConfirmation.value = true;
                          } else {
                            // No data, send message to AI
                            final installmentText = installmentCount == 1 
                                ? 'Peşin' 
                                : '$installmentCount taksit';
                            
                            // Set controller text and send (sendMessage will add the message)
                            widget.parent._controller.text = installmentText;
                            await widget.parent._sendMessage();
                          }
                        },
                      );
                    },
                  ),

                  // Account Selection Chips (Horizontal above input)
                  ValueListenableBuilder<int>(
                    valueListenable: widget.parent._messagesUpdateTrigger,
                    builder: (context, _, child) {
                      // Check if last message is account_selection_inline
                      final hasAccountSelection = widget.parent._chatMessages.isNotEmpty &&
                          widget.parent._chatMessages.last['role'] == 'account_selection_inline';
                      
                      if (!hasAccountSelection) {
                        return const SizedBox.shrink();
                      }
                      
                      final lastMsg = widget.parent._chatMessages.last;
                      final pendingData = lastMsg['pending_transaction'] as Map<String, dynamic>?;
                      final provider = context.watch<UnifiedProviderV2>();
                      final l10n = AppLocalizations.of(context)!;
                      
                      // Taksitli işlem varsa sadece kredi kartlarını göster
                      // Conversation history veya chat messages'da taksit bilgisi var mı kontrol et
                      final isInstallmentTransaction = 
                          // Pending data'da taksit varsa
                          (pendingData?['installmentCount'] != null) ||
                          // Conversation history'de taksit geçiyorsa
                          widget.parent._conversationHistory.any((msg) {
                            final content = (msg['content'] ?? '').toString().toLowerCase();
                            return RegExp(r'\d+\s*taksit|taksitli|peşin|pesin').hasMatch(content);
                          }) ||
                          // Chat messages'da taksit seçimi varsa
                          widget.parent._chatMessages.any((msg) => 
                            msg['role'] == 'installment_selection' || 
                            (msg['content']?.toString().toLowerCase().contains('taksit') ?? false)
                          );
                      
                      final accounts = isInstallmentTransaction
                          ? provider.accounts.where((a) => a.type == AccountType.credit).toList()
                          : provider.accounts;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Başlık
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 14,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hesap seçin',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Horizontal chip'ler
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: accounts.map((account) {
                                  // Localized account name
                                  final localizedName = _getLocalizedAccountName(account, context);
                                  
                                  IconData icon;
                                  if (account.type == AccountType.cash) {
                                    icon = Icons.payments_rounded;
                                  } else if (account.type == AccountType.credit) {
                                    icon = Icons.credit_card_rounded;
                                  } else if (account.type == AccountType.debit) {
                                    icon = Icons.account_balance_wallet_rounded;
                                  } else {
                                    icon = Icons.account_balance_rounded;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      onTap: () async {
                                        // Remove account selection message
                                        widget.parent.setState(() {
                                          widget.parent._chatMessages.removeLast();
                                          widget.parent._messagesUpdateTrigger.value++;
                                        });
                                        
                                        // Update pending data with account
                                        final updatedPendingData = pendingData != null 
                                            ? Map<String, dynamic>.from(pendingData)
                                            : <String, dynamic>{};
                                        updatedPendingData['account'] = localizedName;
                                        
                                        // Eğer pending data boşsa, AI'ya bilgi eksiğini söyle
                                        if (updatedPendingData.isEmpty || 
                                            updatedPendingData['amount'] == null ||
                                            updatedPendingData['description'] == null) {
                                          // AI'ya hesap seçildiğini bildir, eksik bilgileri tamamlamasını iste
                                          widget.parent._controller.text = localizedName;
                                          await widget.parent._sendMessage();
                                          return;
                                        }
                                        
                                        // Check if installment needed
                                        final needsInstallment = account.type == AccountType.credit && 
                                                                updatedPendingData['installmentCount'] == null &&
                                                                updatedPendingData['type'] == 'expense';
                                        
                                        if (needsInstallment) {
                                          // Show installment selection
                                          widget.parent.setState(() {
                                            widget.parent._chatMessages.add({
                                              'role': 'installment_selection',
                                              'pending_transaction': updatedPendingData,
                                              'ai_message': null,
                                            });
                                            widget.parent._messagesUpdateTrigger.value++;
                                          });
                                        } else {
                                          // Directly confirm
                                          widget.parent._pendingTransactionData = updatedPendingData;
                                          widget.parent._isWaitingConfirmation.value = true;
                                        }
                                        
                                        widget.parent._scrollToBottom();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.1),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              icon,
                                              size: 16,
                                              color: const Color(0xFF6D6D70),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              localizedName,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Quick Action Pills - Sadece karşılama mesajından sonra göster
                  ValueListenableBuilder<int>(
                    valueListenable: widget.parent._messagesUpdateTrigger,
                    builder: (context, _, __) {
                      // Sadece 1 mesaj varsa ve o da AI karşılama mesajıysa pill'leri göster
                      final shouldShowPills = widget.parent._chatMessages.length == 1 && 
                                              widget.parent._chatMessages.first['role'] == 'ai';
                      
                      if (!shouldShowPills) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickActionPill(
                                label: l10n.quickActionAddExpense,
                                onTap: () => widget.parent._sendQuickAction(l10n.quickActionAddExpense),
                              ),
                              const SizedBox(width: 8),
                              _QuickActionPill(
                                label: l10n.quickActionAddIncome,
                                onTap: () => widget.parent._sendQuickAction(l10n.quickActionAddIncome),
                              ),
                              const SizedBox(width: 8),
                              _QuickActionPill(
                                label: l10n.quickActionAnalyzeInvoice,
                                onTap: () => widget.parent._sendQuickAction(l10n.quickActionAnalyzeInvoice),
                              ),
                              const SizedBox(width: 8),
                              _QuickActionPill(
                                label: l10n.quickActionCreateBudget,
                                onTap: () => widget.parent._sendQuickAction(l10n.quickActionCreateBudget),
                              ),
                              const SizedBox(width: 8),
                              _QuickActionPill(
                                label: l10n.quickActionViewTransactions,
                                onTap: () => widget.parent._sendQuickAction(l10n.quickActionViewTransactions),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Banner Ad 2 - Input üstünde - Free kullanıcılar için
                  Consumer<PremiumService>(
                    builder: (context, premiumService, _) {
                      // Premium kullanıcılar için reklam gösterme
                      if (premiumService.isPremium) {
                        return const SizedBox.shrink();
                      }
                      
                      // Reklam yüklüyse göster, değilse shrink (gizle)
                      if (_isBannerAd2Loaded && _bannerAd2 != null) {
                        return Container(
                          width: _bannerAd2!.size.width.toDouble(),
                          height: _bannerAd2!.size.height.toDouble(),
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AdWidget(ad: _bannerAd2!),
                        );
                      }
                      
                      // Reklam yüklenmemişse shrink ile gizle
                      return const SizedBox.shrink();
                    },
                  ),

                  // Premium Modern Input
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                      top: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF1C1C1E).withOpacity(0.95)
                          : Colors.white.withOpacity(0.95),
                      border: Border(
                        top: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Attachment Icon Button - Temporarily removed
                        // TODO: Re-enable when image processing is ready
                        
                        // Text Input Container
                Expanded(
                  child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 42,
                              maxHeight: 120,
                            ),
                    decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: widget.parent._isWaitingConfirmation,
                              builder: (context, isWaitingTransaction, child) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: widget.parent._isWaitingBulkDeleteConfirmation,
                                  builder: (context, isWaitingBulkDelete, child) {
                                    return ValueListenableBuilder<bool>(
                                      valueListenable: widget.parent._isWaitingAccountSelection,
                                      builder: (context, isWaitingAccount, child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.parent._isProcessing,
                          builder: (context, isProcessing, child) {
                                            final isWaiting = isWaitingTransaction || isWaitingBulkDelete || isWaitingAccount;
                            return TextField(
                              controller: widget.parent._controller,
                              enabled: !isProcessing && !isWaiting,
                              maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          autofocus: false,
                          onTap: () {
                            // TextField'a tıklandığında scroll yap
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                widget.parent._scrollToBottom();
                              }
                            });
                          },
                          style: GoogleFonts.inter(
                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? Colors.white : Colors.black87,
                                            height: 1.4,
                                            letterSpacing: -0.2,
                          ),
                          decoration: InputDecoration(
                            hintText: isWaiting 
                                ? AppLocalizations.of(context)!.aiChatPendingApproval 
                                : AppLocalizations.of(context)!.aiChatSendPlaceholder,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.35),
                                              letterSpacing: -0.2,
                        ),
                            border: InputBorder.none,
                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                            ),
                          ),
                          // onSubmitted kaldırıldı - Send butonu kullanılıyor, çift gönderim önlendi
                                            );
                                          },
                                        );
                                      },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                        const SizedBox(width: 10),
                        
                        // Send Button
                ValueListenableBuilder<bool>(
                  valueListenable: widget.parent._isWaitingConfirmation,
                          builder: (context, isWaitingTransaction, child) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: widget.parent._isWaitingBulkDeleteConfirmation,
                              builder: (context, isWaitingBulkDelete, child) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: widget.parent._isWaitingAccountSelection,
                                  builder: (context, isWaitingAccount, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: widget.parent._isProcessing,
                      builder: (context, isProcessing, child) {
                                        final isWaiting = isWaitingTransaction || isWaitingBulkDelete || isWaitingAccount;
                                        final isActive = !isProcessing && !isWaiting;
                                
                                    return Container(
                                      width: 42,
                                      height: 42,
                            decoration: BoxDecoration(
                                        gradient: isActive
                                            ? const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                colors: [
                                                  Color(0xFF6D6D70),
                                                  Color(0xFF434343),
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  const Color(0xFF6D6D70).withOpacity(0.3),
                                                  const Color(0xFF434343).withOpacity(0.3),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(21),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF6D6D70).withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isActive
                                              ? () {
                                                  debugPrint('🎯 Send button pressed!');
                                                  widget.parent._sendMessage();
                                                }
                                              : null,
                                          borderRadius: BorderRadius.circular(21),
                            child: Center(
                              child: isProcessing
                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                      child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                                : Icon(
                                                    Icons.arrow_upward_rounded,
                                                    color: isActive 
                                                        ? Colors.white 
                                                        : Colors.white.withOpacity(0.5),
                                                    size: 22,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      );
                                    },
                                  );
                                },
                      );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ),
        );
      },
    );
  }
}

// ==================== QUICK ACTION PILL ====================
class _QuickActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF2C2C2E) 
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER FUNCTIONS ====================
/// Bilgi satırı oluştur (Label: Value formatında) - Düzenlenebilir
Widget _buildInfoRow({
  required String label,
  required String value,
  required bool isDark,
  bool isHighlighted = false,
  VoidCallback? onEdit,
}) {
  final content = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Label
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.black45,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Separator
      Text(
        ':',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black26,
        ),
      ),
      const SizedBox(width: 12),
      // Value
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlighted ? 17 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted 
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
            letterSpacing: isHighlighted ? -0.3 : 0,
          ),
        ),
      ),
      // Edit icon
      if (onEdit != null) ...[
        const SizedBox(width: 8),
        Icon(
          Icons.edit_outlined,
          size: 16,
          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
        ),
      ],
    ],
  );

  // Eğer onEdit varsa, tıklanabilir yap
  if (onEdit != null) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: content,
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: content,
  );
}

/// Hisse detaylarını formatla
String _buildStockDetails(Map<String, dynamic> data, Currency currency, dynamic l10n) {
  final symbol = data['stockSymbol'] ?? '';
  final quantity = data['quantity'];
  final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0;
  final action = data['action'] ?? 'buy';
  final actionText = action == 'buy' 
      ? (l10n.localeName == 'tr' ? 'Alış' : 'Buy') 
      : (l10n.localeName == 'tr' ? 'Satış' : 'Sell');
  final formattedPrice = CurrencyUtils.formatAmount(price, currency);
  
  return '$actionText: $symbol × ${quantity ?? 0} lot @ $formattedPrice';
}

// ==================== CHATGPT-STYLE THINKING INDICATOR ====================
/// ChatGPT tarzı thinking mesajı - Mesaj balonu içinde "Thinking..." + animasyonlu noktalar
class _ChatGPTThinkingIndicator extends StatefulWidget {
  final bool isDark;
  final String thinkingText;

  const _ChatGPTThinkingIndicator({
    required this.isDark,
    required this.thinkingText,
  });

  @override
  State<_ChatGPTThinkingIndicator> createState() => _ChatGPTThinkingIndicatorState();
}

class _ChatGPTThinkingIndicatorState extends State<_ChatGPTThinkingIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark 
            ? const Color(0xFF2C2C2E) // ChatGPT'nin dark mode gri tonu
            : const Color(0xFFF5F5F7), // ChatGPT'nin light mode gri tonu
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Thinking..." yazısı
          Text(
            widget.thinkingText,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: widget.isDark 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black87.withOpacity(0.6),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          // Animasyonlu noktalar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0, _animation.value),
                  const SizedBox(width: 4),
                  _buildDot(1, _animation.value),
                  const SizedBox(width: 4),
                  _buildDot(2, _animation.value),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, double animationValue) {
    // Her nokta için farklı delay hesapla
    final delay = index * 0.15;
    final progress = (animationValue + delay) % 1.0;
    
    // Smooth wave animation
    final opacity = 0.3 + (0.7 * (0.5 - (progress - 0.5).abs()) * 2);
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isDark 
            ? Colors.white.withOpacity(opacity)
            : Colors.black87.withOpacity(opacity),
      ),
    );
  }
}

// ==================== MODERN TYPING INDICATOR (Backup - artık kullanılmıyor) ====================
/// ChatGPT tarzı modern typing indicator - Gradient pulse animasyonu
class _ModernTypingIndicator extends StatefulWidget {
  final bool isDark;

  const _ModernTypingIndicator({required this.isDark});

  @override
  State<_ModernTypingIndicator> createState() => _ModernTypingIndicatorState();
}

class _ModernTypingIndicatorState extends State<_ModernTypingIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0, _animation.value),
              const SizedBox(width: 6),
              _buildDot(1, _animation.value),
              const SizedBox(width: 6),
              _buildDot(2, _animation.value),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index, double animationValue) {
    // Her nokta için farklı delay hesapla
    final delay = index * 0.15;
    final progress = (animationValue + delay) % 1.0;
    
    // Smooth wave animation
    final scale = 0.6 + (0.4 * (0.5 - (progress - 0.5).abs()) * 2);
    final opacity = 0.3 + (0.7 * (0.5 - (progress - 0.5).abs()) * 2);
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isDark 
              ? Colors.white.withOpacity(opacity)
              : Colors.black87.withOpacity(opacity),
        ),
      ),
    );
  }
}

// Eski _TypingDot widget'ı - artık kullanılmıyor
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? Colors.white70 : Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}


