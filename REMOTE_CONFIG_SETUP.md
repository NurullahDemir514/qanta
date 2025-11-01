# 🔧 Firebase Remote Config Setup Guide

## 📋 Genel Bakış

Firebase Remote Config ile bildirim mesajlarını ve zamanlamalarını **uygulama güncellemeden** değiştirebilirsiniz.

### 🎯 Akıllı Bildirim Sistemi

Qanta, **Smart Scheduling** (Akıllı Zamanlama) kullanır:

✅ **Workmanager:** Her 15 dakikada arka planda çalışır  
✅ **Akıllı Kontrol:** Her çalışmada bildirim göndermez  
✅ **Kullanıcı Dostu:** Sadece uygun zamanlarda bildirim gönderir  

**Örnek:** 
```
09:00 → Kontrol (Uygun değil - Son bildirimden 1 saat geçti)
09:15 → Kontrol (Uygun değil - Son bildirimden 1.25 saat geçti)
11:00 → Kontrol (Uygun ✅ - 2 saat geçti, saat 9-21 arası, günlük limit aşılmadı)
       → BİLDİRİM GÖNDERİLİR
13:00 → Kontrol (Uygun değil - Son bildirimden 2 saat geçti ama henüz değil)
13:15 → Kontrol (Uygun ✅ - 2+ saat geçti)
       → BİLDİRİM GÖNDERİLİR
```

**Sonuç:** Workmanager her 15 dk çalışır ama bildirim ~2-3 saatte bir gönderilir! 🎯

## 🚀 Kurulum Adımları

### 1️⃣ Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com)'a gidin
2. Qanta projenizi seçin
3. Sol menüden **"Engage"** → **"Remote Config"** seçin

### 2️⃣ Remote Config Parametrelerini Ekleyin

#### **A) notification_messages_tr** (Bildirim Mesajları - Türkçe)

**Parameter key:** `notification_messages_tr`  
**Data type:** String  
**Default value:**
```
Öğle Arası|Öğle yemeği harcamanızı eklediniz mi?
Akşam Kontrolü|Günlük harcamalarınızı gözden geçirin
Gün Sonu|Bugünkü işlemleri eklemeyi unutmayın
Qanta Hatırlatıcı|Finanslarınızı düzenli tutun
Kahve Molası|Küçük harcamaları da kaydetmeyi unutmayın
Alışveriş Sonrası|Yeni alışverişinizi hemen kaydedin
Hafta Sonu|Bu haftaki harcamalarınızı inceleyin
Bütçe Takibi|Aylık bütçenizi kontrol edin
```

**Format:** Her satır `Başlık|Mesaj` formatında

---

#### **B) notification_messages_en** (Bildirim Mesajları - İngilizce)

**Parameter key:** `notification_messages_en`  
**Data type:** String  
**Default value:**
```
Lunch Break|Have you tracked your lunch expenses?
Evening Check|Time to review your daily expenses
Day End|Don't forget to add today's transactions
Qanta Reminder|Keep your finances organized
Coffee Break|Don't forget to track small expenses
After Shopping|Record your new purchases now
Weekend|Review this week's spending
Budget Tracking|Check your monthly budget
```

**Format:** Her satır `Başlık|Mesaj` formatında

**Not:** Uygulama, kullanıcının sistem diline göre otomatik olarak doğru parametreyi seçer!

---

#### **C) notification_hours** (Bildirim Saatleri)

**Parameter key:** `notification_hours`  
**Data type:** String  
**Default value:** `9,12,15,18,21`

**Format:** Virgülle ayrılmış saat değerleri (0-23 arası)

**Örnekler:**
- `9,12,15,18,21` → 09:00, 12:00, 15:00, 18:00, 21:00
- `8,13,20` → 08:00, 13:00, 20:00

---

#### **D) notifications_enabled** (Bildirimler Aktif mi?)

**Parameter key:** `notifications_enabled`  
**Data type:** Boolean  
**Default value:** `true`

**Kullanım:** Tüm bildirimleri uzaktan kapatmak için `false` yapın

---

#### **E) notification_interval_minutes** (Workmanager Çalışma Sıklığı)

**Parameter key:** `notification_interval_minutes`  
**Data type:** Number  
**Default value:** `15`

**Not:** Bu Workmanager'ın çalışma sıklığıdır, bildirim sıklığı DEĞİL! Android minimum 15 dakikadır.

---

### 🎯 Akıllı Zamanlama Parametreleri

#### **F) smart_scheduling_enabled** (Akıllı Zamanlama)

**Parameter key:** `smart_scheduling_enabled`  
**Data type:** Boolean  
**Default value:** `true`

**Açıklama:** Akıllı zamanlama sayesinde kullanıcı rahatsız edilmez. Her 15 dakikada kontrol edilir ama sadece uygun zamanda bildirim gönderilir.

---

#### **G) min_hours_between_notifications** (Bildirimler Arası Minimum Süre)

**Parameter key:** `min_hours_between_notifications`  
**Data type:** Number  
**Default value:** `2`

**Açıklama:** İki bildirim arasında minimum kaç saat olmalı

**Örnekler:**
- `2` → Minimum 2 saat arayla bildirim
- `3` → Minimum 3 saat arayla bildirim
- `4` → Minimum 4 saat arayla bildirim

---

#### **H) max_daily_notifications** (Günlük Maksimum Bildirim)

**Parameter key:** `max_daily_notifications`  
**Data type:** Number  
**Default value:** `4`

**Açıklama:** Bir günde en fazla kaç bildirim gösterilsin

**Örnekler:**
- `3` → Günde maksimum 3 bildirim
- `4` → Günde maksimum 4 bildirim
- `5` → Günde maksimum 5 bildirim

---

#### **I) notification_start_hour** (İlk Bildirim Saati)

**Parameter key:** `notification_start_hour`  
**Data type:** Number  
**Default value:** `9`

**Açıklama:** Günün kaçıncı saatinde bildirimler başlasın (0-23)

---

#### **J) notification_end_hour** (Son Bildirim Saati)

**Parameter key:** `notification_end_hour`  
**Data type:** Number  
**Default value:** `21`

**Açıklama:** Günün kaçıncı saatinde bildirimler bitsin (0-23)

**Örnek:** `notification_start_hour: 9` ve `notification_end_hour: 21` → 09:00 - 21:00 arası bildirim

---

### 3️⃣ Yayınlama

1. Tüm parametreleri ekledikten sonra **"Publish changes"** butonuna tıklayın
2. Değişikliklerin yayınlanması **birkaç dakika** sürebilir
3. Uygulama her açıldığında veya arka planda çalıştığında yeni değerleri alır

---

## 🎯 Kullanım Senaryoları

### Senaryo 1: Yeni Mesaj Eklemek
```
1. Firebase Console → Remote Config → notification_messages
2. Yeni satır ekle: "Yılbaşı|Yeni yıl hediyelerinizi kaydedin!"
3. Publish changes
4. Kullanıcılar yeni mesajı alır (uygulama güncellemeden)
```

### Senaryo 2: Bildirim Saatlerini Değiştirmek
```
1. notification_hours parametresini düzenle
2. Örnek: "10,14,19" → 10:00, 14:00, 19:00
3. Publish changes
```

### Senaryo 3: Bildirimleri Geçici Kapatmak
```
1. notifications_enabled → false
2. Publish changes
3. Tüm bildirimler durur (uygulama güncellemeden)
```

### Senaryo 4: Bildirim Sıklığını Azaltmak
```
1. notification_interval_minutes → 60 (her saat)
2. Publish changes
3. Kullanıcılar saatte bir bildirim alır
```

### Senaryo 5: Bildirim Saatlerini Değiştirmek
```
1. notification_start_hour → 10 (Sabah 10'dan itibaren)
2. notification_end_hour → 20 (Akşam 8'e kadar)
3. Publish changes
4. Artık sadece 10:00 - 20:00 arası bildirim gelir
```

### Senaryo 6: Daha Az Agresif Bildirim
```
1. min_hours_between_notifications → 3 (3 saat arayla)
2. max_daily_notifications → 3 (günde max 3)
3. Publish changes
4. Kullanıcılar daha az rahatsız edilir
```

### Senaryo 7: Premium Kullanıcılara Daha Az Bildirim
```
1. Remote Config → Conditions → Create condition
2. Name: "Premium Users"
3. Condition: User property "is_premium" = true
4. min_hours_between_notifications → 4 (Premium için)
5. max_daily_notifications → 2 (Premium için)
6. Default value → 2 ve 4 (Free için)
7. Publish changes
```

---

## 📊 İzleme ve Test

### Test Etmek İçin:
1. Firebase Console'da değişiklik yapın
2. Uygulamayı kapatıp yeniden açın (fetch için)
3. 15 dakika bekleyin (Workmanager periyodu)
4. Bildirim gelecektir

### Debug Logs:
```
✅ RemoteConfigService initialized
✅ Remote Config initialized
🔄 Remote Config updated and activated
🎉 Promo price loaded: ₺24,99 (24.99)
```

---

## ⚙️ Gelişmiş Ayarlar

### Koşullu Değerler (Conditions)

Firebase Console'da koşullar oluşturabilirsiniz:

**Örnek 1: Dil bazlı mesajlar**
```
Condition: App language = Turkish
notification_messages: Türkçe mesajlar...

Condition: App language = English
notification_messages: English messages...
```

**Örnek 2: Platform bazlı saatler**
```
Condition: Platform = Android
notification_hours: 9,12,18,21

Condition: Platform = iOS
notification_hours: 8,13,20
```

**Örnek 3: Kullanıcı segmentasyonu**
```
Condition: User in "Premium Users"
notification_interval_minutes: 30 (Daha az bildirim)

Condition: User in "Free Users"
notification_interval_minutes: 15
```

---

## 🔒 Güvenlik

- Remote Config değerleri **public**'tir (herkes görebilir)
- **Hassas bilgi koymayın** (API keys, secrets, vb.)
- Sadece **UI/UX ayarları** için kullanın

---

## 📱 Fetch Stratejisi

### Mevcut Ayarlar:
```dart
fetchTimeout: 10 saniye
minimumFetchInterval: 1 saat (production)
```

**Anlamı:**
- Uygulama her açıldığında **en fazla 1 saatte bir** fetch yapar
- İnternet yoksa **local cache** kullanılır
- **Default değerler** her zaman fallback olarak hazır

---

## ❓ Sık Sorulan Sorular

**S: Değişiklikler ne kadar sürede yansır?**  
C: Firebase'de yayınladıktan sonra 5-10 dakika içinde. Uygulama fetch ettiğinde hemen aktive olur.

**S: İnternet yokken çalışır mı?**  
C: Evet! En son fetch edilen değerler local cache'de saklanır.

**S: Mesaj formatını değiştirebilir miyim?**  
C: Evet, ama kod güncellemesi gerekir. Şu an `Başlık|Mesaj` formatı kullanılıyor.

**S: Kaç mesaj ekleyebilirim?**  
C: Sınır yok, ama 10-15 mesaj optimal. Sistem rotasyon yapar.

---

## 🎉 Başarı!

Artık bildirim sisteminiz tamamen dinamik! 🚀

- ✅ Mesajları uzaktan değiştirin
- ✅ Zamanlamaları ayarlayın
- ✅ Bildirimleri açıp kapatın
- ✅ Uygulama güncellemeden her şeyi kontrol edin

---

**Son Güncelleme:** Ekim 2025  
**Versiyon:** 1.0.4

