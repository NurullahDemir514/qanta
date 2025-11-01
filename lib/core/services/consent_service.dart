import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// GDPR & CCPA Consent Management Service
/// 
/// Manages user consent for personalized ads using Google's UMP SDK.
/// This service MUST be initialized before Google Mobile Ads.
class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  bool _isConsentFormAvailable = false;
  bool _isConsentGathered = false;
  ConsentStatus? _consentStatus;

  bool get isConsentGathered => _isConsentGathered;
  bool get canRequestAds => _consentStatus == ConsentStatus.obtained || 
                            _consentStatus == ConsentStatus.notRequired;

  /// Initialize UMP SDK and check consent status
  /// 
  /// This method should be called BEFORE MobileAds.instance.initialize()
  Future<void> initialize() async {
    try {
      debugPrint('🔐 ConsentService: Initializing UMP SDK...');

      // Create consent request parameters
      final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          // PRODUCTION: Use real user location (change to debugGeographyEea for testing)
          debugGeography: DebugGeography.debugGeographyDisabled,
          // Test device IDs (only used in debug mode)
          testIdentifiers: ['189BB15FEA642FC3E45EED2AFB6E499B'],
        ),
      );

      // Request consent information update
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback
          _isConsentFormAvailable = await ConsentInformation.instance.isConsentFormAvailable();
          _consentStatus = await ConsentInformation.instance.getConsentStatus();
          
          debugPrint('🔐 ConsentService: Consent form available: $_isConsentFormAvailable');
          debugPrint('🔐 ConsentService: Consent status: $_consentStatus');

          // If consent is required, load the form
          if (_consentStatus == ConsentStatus.required && _isConsentFormAvailable) {
            await _loadConsentForm();
          } else {
            _isConsentGathered = true;
            debugPrint('✅ ConsentService: Consent not required or already obtained');
          }
        },
        (FormError error) {
          // Error callback
          debugPrint('❌ ConsentService: Failed to update consent info: ${error.message}');
          _isConsentGathered = true; // Continue anyway with non-personalized ads
        },
      );
    } catch (e) {
      debugPrint('❌ ConsentService: Initialization failed: $e');
      // Continue with default consent (non-personalized ads)
      _isConsentGathered = true;
    }
  }

  /// Load and show consent form if required
  Future<void> _loadConsentForm() async {
    try {
      debugPrint('📋 ConsentService: Loading consent form...');
      
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          debugPrint('✅ ConsentService: Consent form loaded successfully');
          
          // Show the form immediately
          consentForm.show((FormError? formError) async {
            if (formError != null) {
              debugPrint('❌ ConsentService: Form error: ${formError.message}');
            }
            
            // Reload consent status after form submission
            _consentStatus = await ConsentInformation.instance.getConsentStatus();
            _isConsentGathered = true;
            
            debugPrint('✅ ConsentService: Consent gathered, status: $_consentStatus');
            
            // If still required, load form again
            if (_consentStatus == ConsentStatus.required) {
              _loadConsentForm();
            }
          });
        },
        (FormError formError) {
          debugPrint('❌ ConsentService: Failed to load form: ${formError.message}');
          _isConsentGathered = true; // Continue anyway
        },
      );
    } catch (e) {
      debugPrint('❌ ConsentService: Load form failed: $e');
      _isConsentGathered = true;
    }
  }

  /// Show privacy options form
  /// 
  /// This allows users to change their consent preferences at any time
  Future<void> showPrivacyOptionsForm() async {
    try {
      debugPrint('⚙️ ConsentService: Showing privacy options...');
      
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          consentForm.show((FormError? formError) async {
            if (formError != null) {
              debugPrint('❌ ConsentService: Privacy options error: ${formError.message}');
            }
            
            // Reload consent status
            _consentStatus = await ConsentInformation.instance.getConsentStatus();
            debugPrint('✅ ConsentService: Privacy options updated, status: $_consentStatus');
          });
        },
        (FormError formError) {
          debugPrint('❌ ConsentService: Failed to load privacy options: ${formError.message}');
        },
      );
    } catch (e) {
      debugPrint('❌ ConsentService: Show privacy options failed: $e');
    }
  }

  /// Reset consent for testing purposes
  /// 
  /// WARNING: Use only for testing!
  Future<void> resetConsent() async {
    try {
      await ConsentInformation.instance.reset();
      _isConsentGathered = false;
      _consentStatus = null;
      debugPrint('🔄 ConsentService: Consent reset successfully');
    } catch (e) {
      debugPrint('❌ ConsentService: Reset failed: $e');
    }
  }

  /// Check if privacy options button should be shown
  /// 
  /// Returns true if the privacy options entry point should be visible
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('❌ ConsentService: Privacy options check failed: $e');
      return false;
    }
  }
}

