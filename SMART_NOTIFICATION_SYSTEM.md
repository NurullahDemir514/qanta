# 📱 Akıllı Bildirim Sistemi

## 🎯 Genel Bakış

Qanta'nın akıllı bildirim sistemi, kullanıcıları rahatsız etmeden optimal zamanlarda finansal hatırlatmalar gönderir. Sistem, hafta içi ve hafta sonu için farklı zamanlamalar kullanır ve kullanıcı davranışlarına göre akıllıca ayarlanır.

## 📅 Bildirim Zamanlaması

### Hafta İçi (Pazartesi - Cuma)
Günde maksimum **5 bildirim**:

| Saat | Zaman Dilimi | Mesaj Tipi | Açıklama |
|------|--------------|------------|----------|
| **09:00** | 08:30 - 09:45 | `morning` | 🌅 Sabah motivasyonu ve günlük bütçe kontrolü |
| **12:30** | 12:00 - 13:15 | `lunch` | 🍽️ Öğle yemeği harcama hatırlatması |
| **15:30** | 15:00 - 16:15 | `afternoon` | ☕ Öğleden sonra küçük harcama kontrolü |
| **19:00** | 18:30 - 19:45 | `evening` | 🌆 Akşam alışveriş hatırlatması |
| **21:00** | 20:30 - 21:45 | `night` | 🌙 Gün sonu özet ve gözden geçirme |

### Hafta Sonu (Cumartesi - Pazar)
Günde maksimum **2 bildirim**:

| Saat | Zaman Dilimi | Mesaj Tipi | Açıklama |
|------|--------------|------------|----------|
| **11:00** | 10:30 - 11:45 | `weekend_morning` | 🎯 Haftalık harcama kontrolü |
| **20:00** | 19:30 - 20:45 | `weekend_evening` | 📊 Hafta sonu özeti ve gelecek hafta planı |

## 🔧 Teknik Detaylar

### Zaman Dilimi Mantığı
Her bildirim için **±30-45 dakika** tolerans sağlanır:
- **Başlangıç**: Hedef saat - 30 dakika
- **Bitiş**: Hedef saat + 45 dakika
- **Örnek**: 12:00 hedefi için → 11:30 - 12:45 arası geçerli

### Akıllı Kontroller

1. **⏰ Zaman Dilimi Kontrolü**
   - Yalnızca tanımlı zaman dilimlerinde bildirim gönderilir
   - Her zaman dilimi için günde bir kez bildirim

2. **📊 Günlük Limit Kontrolü**
   - Hafta içi: Maksimum 5 bildirim
   - Hafta sonu: Maksimum 2 bildirim

3. **⏱️ Minimum Aralık Kontrolü**
   - Bildirimler arası minimum **2 saat** beklenir
   - Aynı gün içinde aynı slot'a tekrar bildirim gönderilmez

4. **🔄 Mesaj Çeşitlendirmesi**
   - Her zaman dilimi için özel mesajlar
   - Tekrar eden mesajlar önlenir

## 📝 Mesaj Formatı

### Türkçe Mesajlar
```
morning|Günaydın! 🌅|Bugünkü bütçenizi kontrol edin
lunch|Öğle Arası 🍽️|Öğle yemeği harcamanızı eklediniz mi?
afternoon|Öğleden Sonra ☕|Küçük harcamalarınızı kaydetmeyi unutmayın
evening|Akşam Saati 🌆|Alışverişlerinizi kaydetme zamanı
night|Gün Sonu 🌙|Bugünkü işlemlerinizi gözden geçirin
weekend_morning|Hafta Sonu 🎯|Haftalık harcamalarınızı inceleyin
weekend_evening|Hafta Sonu Özeti 📊|Gelecek hafta için planınızı yapın
general|Qanta Hatırlatıcı|Finanslarınızı düzenli tutun
```

### İngilizce Mesajlar
```
morning|Good Morning! 🌅|Check your budget for today
lunch|Lunch Time 🍽️|Have you tracked your lunch expenses?
afternoon|Afternoon Break ☕|Don't forget to track small expenses
evening|Evening Time 🌆|Time to record your shopping
night|Day End 🌙|Review your today's transactions
weekend_morning|Weekend 🎯|Review your weekly spending
weekend_evening|Weekend Summary 📊|Plan for next week
general|Qanta Reminder|Keep your finances organized
```

## 🔥 Firebase Remote Config Ayarları

### Parametreler

```javascript
{
  // Bildirim Mesajları (Türkçe)
  "notification_messages_tr": {
    "value": "morning|Günaydın! 🌅|Bugünkü bütçenizi kontrol edin\nlunch|Öğle Arası 🍽️|Öğle yemeği harcamanızı eklediniz mi?\nafternoon|Öğleden Sonra ☕|Küçük harcamalarınızı kaydetmeyi unutmayın\nevening|Akşam Saati 🌆|Alışverişlerinizi kaydetme zamanı\nnight|Gün Sonu 🌙|Bugünkü işlemlerinizi gözden geçirin\nweekend_morning|Hafta Sonu 🎯|Haftalık harcamalarınızı inceleyin\nweekend_evening|Hafta Sonu Özeti 📊|Gelecek hafta için planınızı yapın\ngeneral|Qanta Hatırlatıcı|Finanslarınızı düzenli tutun"
  },
  
  // Bildirim Mesajları (İngilizce)
  "notification_messages_en": {
    "value": "morning|Good Morning! 🌅|Check your budget for today\nlunch|Lunch Time 🍽️|Have you tracked your lunch expenses?\nafternoon|Afternoon Break ☕|Don't forget to track small expenses\nevening|Evening Time 🌆|Time to record your shopping\nnight|Day End 🌙|Review your today's transactions\nweekend_morning|Weekend 🎯|Review your weekly spending\nweekend_evening|Weekend Summary 📊|Plan for next week\ngeneral|Qanta Reminder|Keep your finances organized"
  },
  
  // Bildirim Aktif Mi?
  "notifications_enabled": {
    "value": true
  },
  
  // Workmanager Kontrol Sıklığı (dakika)
  "notification_interval_minutes": {
    "value": 15
  },
  
  // Akıllı Zamanlama Aktif Mi?
  "smart_scheduling_enabled": {
    "value": true
  },
  
  // Bildirimler Arası Minimum Saat
  "min_hours_between_notifications": {
    "value": 2
  },
  
  // Günlük Maksimum Bildirim (hafta içi)
  "max_daily_notifications": {
    "value": 5
  }
}
```

### Remote Config'i Güncelleme

1. **Firebase Console'a git**: https://console.firebase.google.com
2. **Remote Config** sekmesine tıkla
3. Yukarıdaki parametreleri ekle/güncelle
4. **Publish changes** butonuna tıkla
5. Değişiklikler 1 saat içinde canlıya yansır

## 🏗️ Mimari

### Sınıf Yapısı

```
SmartNotificationScheduler (Helper Class)
├── shouldSendNotification()     // Bildirim gönderilmeli mi?
├── markNotificationSent()       // Bildirim kaydını tut
├── getMessageIndexForSlot()     // Slot'a göre mesaj anahtarı
└── _findCurrentSlot()           // Şu anki zaman dilimi

NotificationService (Main Service)
├── initialize()                 // Servisi başlat
├── startScheduledNotifications() // Workmanager'ı başlat
├── stopScheduledNotifications()  // Workmanager'ı durdur
├── showNotification()           // Bildirim göster (static)
└── getNotificationMessages()    // Remote Config'den mesajları al

RemoteConfigService (Config Service)
├── initialize()                 // Remote Config'i başlat
├── fetchAndActivate()           // Uzak verileri çek
├── getNotificationMessages()    // Mesajları parse et
└── areNotificationsEnabled()    // Bildirimler aktif mi?

callbackDispatcher (Background Task)
├── _findCurrentSlot()           // Zaman dilimini bul
├── Slot kontrolü                // Bildirim gönderildi mi?
├── Limit kontrolü               // Günlük limit aşıldı mı?
└── Bildirim gönder              // NotificationService.showNotification()
```

### Veri Akışı

```
1. Workmanager (her 15 dakikada)
   ↓
2. callbackDispatcher() çalışır
   ↓
3. Zaman dilimi kontrolü (_findCurrentSlot)
   ↓
4. Akıllı kontroller (slot, limit, zaman)
   ↓
5. Remote Config'den mesajları al
   ↓
6. Slot'a göre doğru mesajı seç
   ↓
7. NotificationService.showNotification()
   ↓
8. SharedPreferences'a kaydet
   ↓
9. Task tamamlandı ✅
```

## 📊 Veri Saklama (SharedPreferences)

```dart
'last_notification_time'     // Son bildirim zamanı (ISO8601)
'last_notification_date'     // Son bildirim tarihi (YYYY-MM-DD)
'last_notification_slot'     // Son bildirim slot'u (int: 9, 12, 15, 19, 21)
'last_notification_message'  // Son bildirim başlığı (string)
'daily_notification_count'   // Günlük bildirim sayısı (int)
```

## 🧪 Test Senaryoları

### Manuel Test

```dart
// 1. Bildirim izni kontrolü
await NotificationService().hasNotificationPermission;

// 2. Bildirim gönder (test)
await NotificationService.showNotification(
  title: 'Test Bildirimi',
  body: 'Bu bir test bildirimidir',
  payload: 'home_screen',
);

// 3. İstatistikleri görüntüle
final stats = await SmartNotificationScheduler.getNotificationStats();
print(stats);

// 4. Verileri sıfırla (test için)
await SmartNotificationScheduler.resetNotificationData();
```

### Otomatik Test

```dart
// Test edilmesi gerekenler:
// ✅ Zaman dilimi bulma (_findCurrentSlot)
// ✅ Hafta içi / hafta sonu slot kontrolü
// ✅ Günlük limit kontrolü
// ✅ Minimum aralık kontrolü
// ✅ Mesaj seçimi (slot bazlı)
// ✅ Remote Config fallback
```

## 📱 Kullanıcı Deneyimi

### Bildirimlerin Mantığı

1. **Sabah (09:00)**: Güne başlarken bütçe kontrolü
2. **Öğle (12:30)**: Öğle yemeği gibi rutin harcamalar
3. **Öğleden Sonra (15:30)**: Kahve, atıştırmalık gibi küçük harcamalar
4. **Akşam (19:00)**: İşten sonra alışveriş hatırlatması
5. **Gece (21:00)**: Gün sonu özet ve analiz
6. **Hafta Sonu Sabah (11:00)**: Haftalık kontrol
7. **Hafta Sonu Akşam (20:00)**: Hafta sonu özeti

### Neden Bu Saatler?

- **09:00**: İnsanların çoğu işe başlarken
- **12:30**: Öğle yemeği vakti
- **15:30**: Öğleden sonra molası
- **19:00**: İşten çıkış saati
- **21:00**: Akşam yemeği sonrası dinlenme
- **11:00 (Hafta sonu)**: Hafta sonu geç uyanma
- **20:00 (Hafta sonu)**: Hafta sonu akşamı

## 🚀 Deployment

### 1. Remote Config'i Güncelle
```bash
# Firebase Console üzerinden parametreleri güncelle
```

### 2. Kodu Deploy Et
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 3. Test Et
```bash
# Bildirimleri test et
flutter run --release
```

## 🔍 Debugging

### Log Formatı

```
⏰ Not in notification time slot (14:25)
📭 Notification already sent for slot 12 today
📊 Daily notification limit reached (5/5)
⏱️ Too soon since last notification (1 hours)
✅ Notification sent: Öğle Arası 🍽️ at 12:35 (Slot: 12, Weekday)
📝 Notification logged: Öğle Arası 🍽️ at 12:35 (Slot: 12, Weekday)
```

### Logları İzleme

```bash
# Android
adb logcat | grep "Notification\|qanta_notification"

# iOS
xcrun simctl spawn booted log stream --predicate 'subsystem contains "flutter"' | grep "Notification"
```

## 📈 Metrikler

### Firebase Analytics Event'leri
```dart
// Bildirim gönderildiğinde
analytics.logEvent(
  name: 'notification_sent',
  parameters: {
    'slot': currentSlot,
    'day_type': isWeekend ? 'weekend' : 'weekday',
    'message_key': messageKey,
  },
);

// Bildirime tıklandığında
analytics.logEvent(
  name: 'notification_tapped',
  parameters: {
    'slot': currentSlot,
    'message_key': messageKey,
  },
);
```

## 🎨 Özet

✅ **Akıllı Zamanlama**: Kullanıcıları rahatsız etmeyen optimal saatler
✅ **Hafta İçi/Hafta Sonu**: Farklı yaşam tarzlarına uyum
✅ **Limit Kontrolü**: Günde maksimum 2-5 bildirim
✅ **Çeşitli Mesajlar**: Her zaman dilimi için özel mesajlar
✅ **Firebase Entegrasyonu**: Uzaktan mesaj güncelleme
✅ **Dil Desteği**: Türkçe ve İngilizce
✅ **Background Task**: Workmanager ile güvenilir çalışma
✅ **Debug Dostu**: Detaylı loglar ve test araçları

---

**Son Güncelleme**: 29 Ekim 2025
**Versiyon**: 2.0
**Durum**: ✅ Production Ready

