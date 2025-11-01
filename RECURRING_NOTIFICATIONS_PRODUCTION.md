# Recurring Transactions - Production Notifications Guide

## Bildirim Sistemi Genel Bakış

Recurring transaction'lar çalıştırıldığında kullanıcıya otomatik bildirim gönderilir. Sistem tamamen background'da çalışır ve localization desteği içerir.

## Bildirim Formatı

### Tek Abonelik Ödemesi
**Başlık (Title):**
- 🇹🇷 Türkçe: "Abonelik Ödemesi"
- 🇬🇧 İngilizce: "Subscription Payment"
- 🇩🇪 Almanca: "Abonnementzahlung"

**İçerik (Body):**
- 🇹🇷 Türkçe: "Otomatik ödeme işlemi oluşturuldu"
- 🇬🇧 İngilizce: "Automatic payment created"
- 🇩🇪 Almanca: "Automatische Zahlung erstellt"

### Çoklu Abonelik Ödemeleri
**Başlık (Title):**
- 🇹🇷 Türkçe: "3 Abonelik Ödemesi" (count'a göre)
- 🇬🇧 İngilizce: "3 Subscription Payments"
- 🇩🇪 Almanca: "3 Abonnementzahlungen"

**İçerik (Body):**
- 🇹🇷 Türkçe: "3 otomatik ödeme işlemi oluşturuldu"
- 🇬🇧 İngilizce: "3 automatic payments created"
- 🇩🇪 Almanca: "3 automatische Zahlungen erstellt"

## Localization Mantığı

1. **Kullanıcı Dil Tercihi**: SharedPreferences'tan `locale` key'i ile okunur
2. **Fallback**: Eğer dil tercihi yoksa, sistem diline göre otomatik algılanır
3. **Default**: Türkçe (tr)

### Desteklenen Diller
- 🇹🇷 Türkçe (tr) - Default
- 🇬🇧 İngilizce (en)
- 🇩🇪 Almanca (de)

## Production'da Çalışması İçin Gereksinimler

### 1. Notification Permission

#### Android
- **Android 13+ (API 33+)**: Runtime permission gerekli
- **Android 12 ve öncesi**: Otomatik olarak verilir
- Permission uygulama ilk açıldığında `NotificationService.initialize()` ile istenir

#### iOS
- Uygulama ilk açıldığında iOS otomatik permission dialog gösterir
- `NotificationService.initialize()` içinde `requestPermissions()` çağrılır

### 2. Android Notification Channel

Android 8+ (API 26+) için notification channel oluşturulur:
- **Channel ID**: `qanta_reminders`
- **Channel Name**: "Qanta Reminders"
- **Importance**: High
- **Sound**: Enabled
- **Vibration**: Enabled
- **Badge**: Enabled

### 3. Background Execution

#### WorkManager Task
- Her 24 saatte bir çalışır
- Background'da çalışabilir (uygulama kapalıyken)
- Network gerektirmez
- Battery optimization'dan etkilenebilir

#### Android Battery Optimization
Kullanıcıların bildirim alabilmesi için:
1. **Settings → Apps → Qanta → Battery → Unrestricted** seçilmeli
2. Ya da kullanıcıya uygulama içinde uyarı gösterilebilir

#### iOS Background Execution
- iOS daha kısıtlı background execution'a izin verir
- iOS 13+: Background task'lar kısa süreli çalışabilir
- Uygulama açıkken daha güvenilir çalışır

### 4. Notification Service Yapılandırması

#### Android Manifest
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### iOS Info.plist
iOS için özel bir ayar gerekmez (flutter_local_notifications otomatik hallediyor)

## Test Senaryoları

### 1. Permission Test
```
✅ Uygulama ilk açıldığında permission istenir
✅ Permission reddedilirse bildirim gönderilmez (sessizce fail)
✅ Permission verilirse bildirimler çalışır
```

### 2. Localization Test
```
✅ Türkçe dil tercihi → Türkçe bildirim
✅ İngilizce dil tercihi → İngilizce bildirim
✅ Almanca dil tercihi → Almanca bildirim
✅ Dil tercihi yoksa → Sistem diline göre
```

### 3. Background Test
```
✅ Uygulama kapalıyken WorkManager çalışır
✅ Transaction oluşturulur
✅ Bildirim gönderilir
```

### 4. Multiple Transactions Test
```
✅ 1 transaction → "Abonelik Ödemesi" (singular)
✅ 3 transactions → "3 Abonelik Ödemesi" (plural)
```

## Production Checklist

### Bildirim İçin
- [ ] Notification permission isteniyor (Android 13+)
- [ ] iOS permission dialog çalışıyor
- [ ] Android notification channel oluşturuluyor
- [ ] Localization doğru çalışıyor (tr, en, de)
- [ ] Background'da bildirim gönderilebiliyor
- [ ] Payload doğru set ediliyor ('subscriptions')
- [ ] Notification tap → Subscriptions sayfasına yönlendiriyor

### WorkManager İçin
- [ ] Periodic task kayıtlı (24 saat)
- [ ] Background execution çalışıyor
- [ ] Battery optimization uyarısı var (opsiyonel)
- [ ] Error handling yeterli

### Localization İçin
- [ ] SharedPreferences'tan dil tercihi okunuyor
- [ ] Sistem dili fallback olarak kullanılıyor
- [ ] Türkçe default olarak çalışıyor
- [ ] Tüm diller için mesajlar mevcut

## Bildirim Özellikleri

### Android
- **Icon**: `@drawable/ic_notification_q`
- **Sound**: Enabled
- **Vibration**: Enabled
- **Priority**: High
- **Auto Cancel**: Yes
- **Channel**: `qanta_reminders`

### iOS
- **Alert**: Enabled
- **Badge**: Enabled
- **Sound**: Enabled

## Sorun Giderme

### Bildirim Gelmiyor

**Android:**
1. Settings → Apps → Qanta → Notifications → Enabled mi?
2. Battery optimization → Unrestricted mi?
3. Notification channel enabled mi?
4. Permission verilmiş mi? (Android 13+)

**iOS:**
1. Settings → Qanta → Notifications → Enabled mi?
2. Background App Refresh enabled mi?
3. Uygulama arka planda çalışıyor mu?

### Yanlış Dil

1. SharedPreferences'ta `locale` key'i var mı?
2. Sistem dili doğru algılanıyor mu?
3. Fallback çalışıyor mu?

### Background'da Çalışmıyor

1. WorkManager task kayıtlı mı?
2. Battery optimization kapatılmış mı?
3. Android'de Doze mode aktif mi?
4. iOS'ta Background App Refresh enabled mi?

## Production İçin Öneriler

### 1. Permission Handling
- Uygulama açıldığında permission kontrolü yap
- Permission reddedilirse, kullanıcıya neden gerekli olduğunu açıkla
- Settings'e yönlendirme butonu ekle

### 2. Battery Optimization
- Android'de kullanıcıya battery optimization'dan çıkarması için uyarı göster
- Bu bildirimlerin çalışması için kritik

### 3. Error Handling
- Bildirim gönderilemezse sessizce fail olmalı
- Log'larda error kaydedilmeli
- Execution başarısız olmamalı

### 4. Testing
- Production'a çıkmadan önce tüm dillerde test et
- Background'da test et (uygulama kapalı)
- Permission senaryolarını test et
- Battery optimization senaryolarını test et

## Bildirim Payload

Bildirim tıklandığında:
- **Payload**: `'subscriptions'`
- **Action**: Subscriptions management sayfasına yönlendir (eğer router handler eklenirse)

## Log Formatı

```
📱 Sent batch notification for X transactions
❌ Error sending batch notification: [error]
```

Production'da bu loglar görünmeyecek (debug mode kapalı), ama hata durumunda sessizce fail olacak.

## Sonuç

Sistem production'da düzgün çalışacak şekilde yapılandırıldı:
- ✅ Localization desteği (tr, en, de)
- ✅ Permission handling
- ✅ Background execution
- ✅ Error handling
- ✅ Android & iOS support

Tek gereksinim: **Kullanıcıların notification permission vermesi ve (Android'de) battery optimization'ı kapatması**.

