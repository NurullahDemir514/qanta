# 🔥 Firebase Remote Config Kurulum Rehberi

## 📋 Genel Bakış

Bu rehber, Qanta uygulamasının yeni akıllı bildirim sistemi için Firebase Remote Config parametrelerinin nasıl ekleneceğini açıklar.

## 🚀 Adım Adım Kurulum

### 1. Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com) adresine git
2. Qanta projesini seç
3. Sol menüden **Remote Config** sekmesine tıkla

### 2. Parametreleri Ekle

Her bir parametre için aşağıdaki adımları takip et:

---

#### Parametre 1: `notification_messages_tr`

**Tür:** String  
**Açıklama:** Türkçe bildirim mesajları (Format: key|title|body)

**Değer:**
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

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notification_messages_tr`
3. Default value: Yukarıdaki değeri yapıştır
4. Description: "Türkçe bildirim mesajları"
5. Save

---

#### Parametre 2: `notification_messages_en`

**Tür:** String  
**Açıklama:** İngilizce bildirim mesajları (Format: key|title|body)

**Değer:**
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

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notification_messages_en`
3. Default value: Yukarıdaki değeri yapıştır
4. Description: "İngilizce bildirim mesajları"
5. Save

---

#### Parametre 3: `notifications_enabled`

**Tür:** Boolean  
**Açıklama:** Bildirimler aktif mi?

**Değer:** `true`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notifications_enabled`
3. Value type: Boolean seç
4. Default value: true
5. Description: "Bildirimler aktif mi?"
6. Save

---

#### Parametre 4: `notification_interval_minutes`

**Tür:** Number  
**Açıklama:** Workmanager kontrol sıklığı (dakika)

**Değer:** `15`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notification_interval_minutes`
3. Value type: Number seç
4. Default value: 15
5. Description: "Workmanager kontrol sıklığı (dakika, minimum 15)"
6. Save

---

#### Parametre 5: `smart_scheduling_enabled`

**Tür:** Boolean  
**Açıklama:** Akıllı zamanlama aktif mi?

**Değer:** `true`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `smart_scheduling_enabled`
3. Value type: Boolean seç
4. Default value: true
5. Description: "Akıllı zamanlama aktif mi?"
6. Save

---

#### Parametre 6: `min_hours_between_notifications`

**Tür:** Number  
**Açıklama:** Bildirimler arası minimum saat

**Değer:** `2`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `min_hours_between_notifications`
3. Value type: Number seç
4. Default value: 2
5. Description: "Bildirimler arası minimum saat"
6. Save

---

#### Parametre 7: `max_daily_notifications`

**Tür:** Number  
**Açıklama:** Günlük maksimum bildirim sayısı

**Değer:** `5`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `max_daily_notifications`
3. Value type: Number seç
4. Default value: 5
5. Description: "Günlük maksimum bildirim sayısı (hafta içi)"
6. Save

---

#### Parametre 8: `notification_start_hour`

**Tür:** Number  
**Açıklama:** İlk bildirim saati

**Değer:** `9`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notification_start_hour`
3. Value type: Number seç
4. Default value: 9
5. Description: "İlk bildirim saati (0-23)"
6. Save

---

#### Parametre 9: `notification_end_hour`

**Tür:** Number  
**Açıklama:** Son bildirim saati

**Değer:** `21`

**Nasıl Eklerim:**
1. "Add parameter" butonuna tıkla
2. Parameter key: `notification_end_hour`
3. Value type: Number seç
4. Default value: 21
5. Description: "Son bildirim saati (0-23)"
6. Save

---

### 3. Değişiklikleri Yayınla

1. Tüm parametreleri ekledikten sonra
2. Sağ üstteki **"Publish changes"** butonuna tıkla
3. Onay mesajını onayla
4. Değişiklikler 1 saat içinde tüm kullanıcılara yansır

---

## 📸 Görsel Rehber

### Remote Config Sayfası
```
┌─────────────────────────────────────────────────────────┐
│  Remote Config                        [Add parameter]    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  notification_messages_tr              [Edit] [Delete]   │
│  └─ "morning|Günaydın! 🌅|Bugünkü..."                   │
│                                                           │
│  notification_messages_en              [Edit] [Delete]   │
│  └─ "morning|Good Morning! 🌅|Check..."                 │
│                                                           │
│  notifications_enabled                 [Edit] [Delete]   │
│  └─ true                                                  │
│                                                           │
│  ...                                                      │
│                                                           │
│                               [Publish changes]           │
└─────────────────────────────────────────────────────────┘
```

---

## 🧪 Test Etme

### Parametreleri Test Et

1. **Firebase Console'da:**
   - Remote Config sayfasında parametreleri görüntüle
   - Her parametrenin doğru değerde olduğunu kontrol et

2. **Uygulamada Test:**
```bash
# Android
adb logcat | grep "Remote Config"
```

**Beklenen Log:**
```
✅ RemoteConfigService initialized
🔄 Remote Config updated and activated
```

### Manuel Mesaj Testi

Remote Config Console'da bir mesajı değiştir:
```
morning|Test Mesajı 🧪|Bu bir test mesajıdır
```

1-2 saat içinde uygulamada yeni mesaj görünmeli.

---

## 🔄 Güncelleme Yaparken

### Mesajları Güncelleme
1. Firebase Console → Remote Config
2. İlgili parametreyi bul (örn: `notification_messages_tr`)
3. **Edit** butonuna tıkla
4. Mesajı düzenle
5. **Update** butonuna tıkla
6. **Publish changes** butonuna tıkla

### Zamanlamayı Değiştirme
```
notification_start_hour: 9 → 10  (1 saat sonra başlat)
notification_end_hour: 21 → 20   (1 saat önce bitir)
```

### Bildirim Sıklığını Değiştirme
```
max_daily_notifications: 5 → 3  (Günde 3 bildirim)
min_hours_between_notifications: 2 → 3  (3 saat arayla)
```

---

## ⚠️ Önemli Notlar

### 1. Mesaj Formatı
```
key|title|body
```
- **key**: Mesaj anahtarı (morning, lunch, vb.)
- **title**: Bildirim başlığı
- **body**: Bildirim içeriği
- **|** (pipe): Ayırıcı karakter

❌ **Yanlış:**
```
Günaydın - Bugünkü bütçenizi kontrol edin
```

✅ **Doğru:**
```
morning|Günaydın! 🌅|Bugünkü bütçenizi kontrol edin
```

### 2. Emoji Kullanımı
Firebase Remote Config emoji'leri destekler. Özgürce kullanabilirsiniz:
```
🌅 🍽️ ☕ 🌆 🌙 🎯 📊
```

### 3. Satır Sonları
Her mesaj yeni satırda olmalı (multi-line string):
```
morning|Günaydın! 🌅|Bugünkü bütçenizi kontrol edin
lunch|Öğle Arası 🍽️|Öğle yemeği harcamanızı eklediniz mi?
```

### 4. Güncelleme Süresi
- Parametreler **1 saat** içinde aktif olur
- Test için: Uygulamayı tamamen kapatıp açın
- Minimum fetch interval: 1 saat (production)

---

## 🎯 Hızlı Kontrol Listesi

Kurulumu tamamladıktan sonra:

- [ ] 9 parametre eklendi
- [ ] Tüm mesajlar doğru formatta (key|title|body)
- [ ] Emoji'ler düzgün görünüyor
- [ ] Boolean parametreler doğru (true/false)
- [ ] Number parametreler doğru (15, 2, 5, 9, 21)
- [ ] "Publish changes" yapıldı
- [ ] Uygulamada test edildi
- [ ] Loglar kontrol edildi

---

## 🆘 Sorun Giderme

### "Remote Config yüklenmiyor"
```dart
// Debug log kontrol et
adb logcat | grep "RemoteConfig"

// Beklenen:
✅ RemoteConfigService initialized
🔄 Remote Config updated and activated
```

**Çözüm:**
- İnternet bağlantısını kontrol et
- Firebase projesinin doğru olduğunu kontrol et
- 1 saat bekle (fetch interval)

### "Mesajlar güncellenmiyor"
**Çözüm:**
1. Uygulamayı tamamen kapat
2. Cache'i temizle
3. Uygulamayı yeniden aç
4. 1 saat bekle

### "Yanlış mesaj gösteriliyor"
**Çözüm:**
- Mesaj formatını kontrol et: `key|title|body`
- Pipe karakteri (|) kullanıldığından emin ol
- Satır sonlarını kontrol et

---

## 📚 İlgili Dökümanlar

- [SMART_NOTIFICATION_SYSTEM.md](./SMART_NOTIFICATION_SYSTEM.md) - Detaylı sistem dokümantasyonu
- [NOTIFICATION_SYSTEM_UPDATE.md](./NOTIFICATION_SYSTEM_UPDATE.md) - Güncelleme raporu
- [firebase_remote_config_notifications.json](./firebase_remote_config_notifications.json) - JSON template

---

## ✅ Başarı!

Remote Config kurulumu tamamlandı! 🎉

Artık bildirim mesajlarını uygulama güncellemesi olmadan değiştirebilirsiniz.

---

**Son Güncelleme**: 29 Ekim 2025  
**Versiyon**: 1.0  
**Durum**: ✅ Production Ready

