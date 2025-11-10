import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Tutorial Service
/// Tutorial state management ve persistence
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _tutorialSkippedKey = 'tutorial_skipped';
  static const String _tutorialStepCompletedKey = 'tutorial_step_completed_';
  
  // Tutorial durumu için static flag (runtime tracking)
  static bool _isTutorialActive = false;
  static String? _currentStepId; // Şu anki tutorial step ID
  
  // Tutorial'ı geçici olarak devre dışı bırakmak için flag
  // TODO: İleride tutorial'ı tekrar aktif etmek için bu flag'i true yap
  static const bool _isTutorialSuspended = true;
  
  /// Tutorial aktif mi?
  static bool get isTutorialActive => _isTutorialActive;
  
  /// Şu anki tutorial step ID'si
  static String? get currentStepId => _currentStepId;
  
  /// Recent Transactions tutorial adımında mıyız?
  static bool get isRecentTransactionsStep => _currentStepId == 'recent_transactions_tutorial';
  
  /// Tutorial'ı aktif olarak işaretle
  static void setTutorialActive(bool active, {String? stepId}) {
    _isTutorialActive = active;
    _currentStepId = stepId;
    debugPrint('📚 TutorialService: Tutorial ${active ? "active" : "inactive"} - Step: ${stepId ?? "none"}');
  }

  /// Tutorial tamamlandı mı kontrol et
  static Future<bool> isTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tutorialCompletedKey) ?? false;
    } catch (e) {
      debugPrint('❌ TutorialService.isTutorialCompleted error: $e');
      return false;
    }
  }

  /// Tutorial skip edildi mi kontrol et
  static Future<bool> isTutorialSkipped() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tutorialSkippedKey) ?? false;
    } catch (e) {
      debugPrint('❌ TutorialService.isTutorialSkipped error: $e');
      return false;
    }
  }

  /// Belirli bir adım tamamlandı mı kontrol et
  static Future<bool> isStepCompleted(String stepId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_tutorialStepCompletedKey$stepId') ?? false;
    } catch (e) {
      debugPrint('❌ TutorialService.isStepCompleted error: $e');
      return false;
    }
  }

  /// Tutorial'ı tamamlandı olarak işaretle
  static Future<void> completeTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialCompletedKey, true);
      debugPrint('✅ Tutorial marked as completed');
    } catch (e) {
      debugPrint('❌ TutorialService.completeTutorial error: $e');
    }
  }

  /// Tutorial'ı skip edildi olarak işaretle
  static Future<void> skipTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialSkippedKey, true);
      await prefs.setBool(_tutorialCompletedKey, true); // Skip = complete
      debugPrint('✅ Tutorial marked as skipped');
    } catch (e) {
      debugPrint('❌ TutorialService.skipTutorial error: $e');
    }
  }

  /// Belirli bir adımı tamamlandı olarak işaretle
  static Future<void> completeStep(String stepId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_tutorialStepCompletedKey$stepId', true);
      debugPrint('✅ Tutorial step completed: $stepId');
    } catch (e) {
      debugPrint('❌ TutorialService.completeStep error: $e');
    }
  }

  /// Tutorial'ı reset et (settings'ten kullanılabilir)
  static Future<void> resetTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tutorialCompletedKey);
      await prefs.remove(_tutorialSkippedKey);
      
      // Tüm step'leri temizle
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_tutorialStepCompletedKey)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('✅ Tutorial reset completed');
    } catch (e) {
      debugPrint('❌ TutorialService.resetTutorial error: $e');
    }
  }

  /// Tutorial gösterilmeli mi kontrol et
  /// İlk açılışta ve tamamlanmadıysa göster
  static Future<bool> shouldShowTutorial() async {
    try {
      // Tutorial geçici olarak devre dışı bırakıldı
      if (_isTutorialSuspended) {
        debugPrint('📚 TutorialService: Tutorial is currently suspended');
        return false;
      }
      
      final completed = await isTutorialCompleted();
      final skipped = await isTutorialSkipped();
      
      // Tamamlandıysa veya skip edildiyse gösterme
      if (completed || skipped) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ TutorialService.shouldShowTutorial error: $e');
      return false;
    }
  }
}

