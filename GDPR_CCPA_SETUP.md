# GDPR & CCPA Compliance Setup - Qanta

## ✅ Completed Tasks

### 1. Web Site Setup
- ✅ Created privacy policy page: `https://qanta.app/privacy-policy`
- ✅ Added privacy policy to sitemap for SEO
- ✅ Deployed to Vercel (live now)
- ✅ Created app-ads.txt file: `https://qanta.app/app-ads.txt`

### 2. Flutter App - UMP SDK Integration
- ✅ Created `ConsentService` (`lib/core/services/consent_service.dart`)
- ✅ Integrated UMP SDK in `main.dart` (initialized BEFORE Google Mobile Ads)
- ✅ Added Privacy Options button in Profile/Settings screen
- ✅ iOS: Added NSUserTrackingUsageDescription to Info.plist
- ✅ iOS: Added SKAdNetwork items for attribution
- ✅ Android: Already configured with AdMob App ID

## 📋 Next Steps (AdMob Console)

### Step 1: Privacy Policy URL ✅
**Action:** Add privacy policy URL to AdMob console

1. Go to AdMob Console: https://apps.admob.com
2. Navigate to **Apps** → Select Qanta app
3. Go to **App Settings** → **App Information**
4. Add **Privacy Policy URL**: `https://qanta.app/privacy-policy`
5. Save

### Step 2: Create Consent Message 🎯
**Action:** Create EU consent message in AdMob

1. In AdMob, click the screenshot button **"İleti oluştur"** (Create Message)
2. Follow the 5-step wizard:

#### Step 2.1: Add Privacy Policy URL to App
- Already done! ✅ `https://qanta.app/privacy-policy`

#### Step 2.2: Select Consent Options
Choose which consent options to include:
- ✅ **Personalized Ads** (Kişiselleştirilmiş reklamlar)
- ✅ **Non-Personalized Ads** (Kişiselleştirilmemiş reklamlar)
- ✅ **Use data for ad measurement**

#### Step 2.3: Review EU Settings
Check your account settings for GDPR compliance:
- Make sure **Google Certified CMP** is selected
- Review partner settings

#### Step 2.4: Publish Message
- Publish the EU consent message
- It will show to users in EU/EEA countries

#### Step 2.5: Implement UMP SDK
- Already done! ✅ `ConsentService` is integrated

### Step 3: Test the Implementation 🧪

#### Test in Flutter App:
1. Build and run the app
2. For EU users: Consent form will show automatically
3. For testing:
   - Change `debugGeography` in `consent_service.dart`:
     ```dart
     debugGeography: DebugGeography.debugGeographyEea, // Simulate EU
     ```
   - Or use:
     ```dart
     debugGeography: DebugGeography.debugGeographyDisabled, // Real location
     ```

#### Test Privacy Options:
1. Open app
2. Go to Profile → Security → **Privacy Options**
3. Consent form should appear
4. User can change their preferences

### Step 4: Reset Consent (Testing Only)
For testing purposes, you can reset consent:

```dart
// In debug mode only!
await ConsentService().resetConsent();
```

## 🌍 How It Works

### For Users in EU/EEA (GDPR):
1. App opens → UMP SDK checks user location
2. If in EU → Shows consent form automatically
3. User selects preferences (personalized/non-personalized ads)
4. Preferences saved → Ads shown according to choice
5. User can change anytime via **Privacy Options** in Settings

### For Users in California (CCPA):
1. App opens → UMP SDK checks location
2. Shows "Do Not Sell My Personal Information" option
3. User can opt-out of data sale
4. Preferences saved and respected

### For Users in Other Regions:
1. App opens → No consent form (not required)
2. Ads shown normally
3. Privacy Options available in Settings (optional)

## 📱 User Journey

### First Time User (EU):
```
App Launch
    ↓
Firebase Init
    ↓
Consent Check (UMP SDK)
    ↓
[EU Detected] → Show Consent Form
    ↓
User Chooses Preferences
    ↓
Google Mobile Ads Init
    ↓
Home Screen
```

### Returning User (EU):
```
App Launch
    ↓
Consent Check (UMP SDK)
    ↓
[Consent Already Given] → Skip Form
    ↓
Google Mobile Ads Init (with saved preferences)
    ↓
Home Screen
```

### User Changes Mind:
```
Profile Screen
    ↓
Settings → Privacy Options
    ↓
Consent Form Opens
    ↓
User Updates Preferences
    ↓
Ads Updated Accordingly
```

## 🔧 Configuration Files

### ConsentService Settings:
Location: `lib/core/services/consent_service.dart`

```dart
// For PRODUCTION:
consentDebugSettings: ConsentDebugSettings(
  debugGeography: DebugGeography.debugGeographyDisabled, // Use real location
),

// For TESTING EU:
consentDebugSettings: ConsentDebugSettings(
  debugGeography: DebugGeography.debugGeographyEea, // Simulate EU
  testIdentifiers: ['YOUR_TEST_DEVICE_ID'],
),
```

### Privacy Policy URL:
- Web: `https://qanta.app/privacy-policy`
- AdMob Console: Set in App Settings
- Flutter App: Accessible via Profile → Privacy Policy

## 📊 Monitoring & Compliance

### Check Compliance Status:
1. AdMob Console → Apps → Qanta
2. Check for any warnings or errors
3. Monitor consent rate (% of users giving consent)

### Consent Rate Optimization:
- Clear, concise consent form text
- Easy-to-understand options
- Professional privacy policy
- Trust signals (data security, encryption)

## 🎯 Expected Timeline

- ✅ **Day 0:** Code deployed, privacy policy live
- ⏳ **Day 0-1:** Configure AdMob consent message (do now!)
- ⏳ **Day 1-2:** Google validates app-ads.txt and privacy policy
- ⏳ **Day 2-3:** Full compliance verified
- ✅ **Day 3+:** Global launch ready!

## 🚨 Important Notes

1. **Privacy Policy is REQUIRED** before publishing to Play Store/App Store
2. **Consent must be obtained BEFORE loading ads** (we do this correctly ✅)
3. **Privacy Options must be accessible** to users at any time (in Settings ✅)
4. **Non-personalized ads are still allowed** without consent (UMP SDK handles this ✅)
5. **Under 13 users cannot consent** - ensure your app's age rating is correct

## 🎉 Benefits

- ✅ **GDPR Compliant** - EU users protected
- ✅ **CCPA Compliant** - California users protected
- ✅ **Google Certified** - Using official Google UMP SDK
- ✅ **Global Ready** - Works worldwide
- ✅ **User Control** - Users can change preferences anytime
- ✅ **Revenue Optimized** - Personalized ads when consented, non-personalized otherwise

## 📞 Support

If you encounter issues:
1. Check AdMob console for errors
2. Test with debug geography enabled
3. Verify privacy policy URL is accessible
4. Check UMP SDK logs in console

## 🔗 Resources

- Google UMP SDK: https://developers.google.com/admob/ump/android/quick-start
- GDPR Info: https://policies.google.com/technologies/partner-sites
- Privacy Policy Template: https://www.freeprivacypolicy.com/
- AdMob Help: https://support.google.com/admob

---

**Status:** 🟡 Partially Complete
**Next Action:** Configure consent message in AdMob Console (see Step 2 above)
**Estimated Time:** 10-15 minutes

