# 🚀 Play Store Yükleme Hazırlık Raporu

## ✅ Tamamlanan Konfigürasyonlar

### 1. Uygulama Bilgileri
- **Uygulama Adı**: Qanta
- **Package Name**: com.qanta
- **Versiyon**: 1.0.0 (Build 1)
- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 34 (Android 14)

### 2. Signing Configuration
- ✅ Keystore dosyası mevcut: `qanta-release-key.jks`
- ✅ key.properties dosyası yapılandırıldı
- ✅ Release build signing yapılandırıldı

### 3. Build Optimization
- ✅ ProGuard kuralları eklendi ve optimize edildi
- ✅ Minify enabled (kod boyutu küçültme)
- ✅ Shrink resources enabled (kullanılmayan kaynakları temizleme)
- ✅ MultiDex desteği eklendi
- ✅ Debug symbols yapılandırıldı

### 4. Android Manifest
- ✅ Gerekli tüm izinler eklendi
- ✅ Backup rules yapılandırıldı
- ✅ Data extraction rules eklendi
- ✅ Firebase ve Google Play Services entegrasyonu

### 5. Güvenlik
- ✅ Backup rules (hassas verilerin yedeklenmemesi için)
- ✅ Data extraction rules (cihaz transferi için)
- ✅ usesCleartextTraffic = false (HTTPS zorunluluğu)

---

## 🎯 Play Store'a Yükleme Adımları

### Adım 1: APK/AAB Build

#### Option A: App Bundle (Önerilen)
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
**Çıktı**: `build/app/outputs/bundle/release/app-release.aab`

#### Option B: APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```
**Çıktı**: `build/app/outputs/flutter-apk/app-release.apk`

### Adım 2: Build Doğrulama
Build tamamlandıktan sonra kontrol edin:
- ✅ Dosya boyutu makul mı? (genellikle 20-50 MB)
- ✅ Hata mesajı yok mu?
- ✅ Test cihazında çalışıyor mu?

Test için:
```bash
# APK'yı test cihazına yükle
flutter install --release

# veya adb ile
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Adım 3: Play Console'da Uygulama Oluşturma

1. **Play Console'a giriş yapın**: https://play.google.com/console
2. **Tüm uygulamalar** > **Uygulama oluştur**
3. Uygulama detaylarını doldurun:
   - Uygulama adı: **Qanta**
   - Varsayılan dil: **Türkçe**
   - Uygulama türü: **Uygulama**
   - Ücretsiz/Ücretli: **Ücretsiz**

### Adım 4: Uygulama İçeriği Beyanları

#### 4.1 Gizlilik Politikası
- ⚠️ **GEREKLI**: Gizlilik politikası URL'i hazırlamanız gerekiyor
- Firebase Auth kullanıyorsunuz, bu yüzden zorunlu
- Örnek: `https://yourwebsite.com/privacy-policy`

#### 4.2 Veri Güvenliği Formu
Uygulamanızın topladığı veriler:
- ✅ Kullanıcı hesap bilgileri (Email - Firebase Auth)
- ✅ Finansal bilgiler (Hisse senetleri, işlemler)
- ✅ Kişisel bilgiler (İsim, profil bilgileri)
- ✅ Fotoğraflar (Profil fotoğrafı)

Veri paylaşımı:
- ✅ Firebase (Google) ile paylaşılıyor
- ✅ SSL/TLS ile şifreleniyor

#### 4.3 İçerik Derecelendirmesi
Finansal uygulama olduğu için:
- Yaş sınırı: **13+** (önerilen)
- İçerik kategorisi: **Eğitim/Finans**

#### 4.4 Hedef Kitle
- Ana hedef: **18-65 yaş arası**
- Çocuklara yönelik değil

### Adım 5: Store Listing (Mağaza Kaydı)

#### 5.1 Metin İçerikleri

**Kısa Açıklama** (80 karakter max):
```
Hisse senedi portföyünüzü takip edin, işlemlerinizi kaydedin ve analiz edin
```

**Uzun Açıklama** (4000 karakter max):
```
📈 Qanta - Akıllı Hisse Senedi Portföy Yönetimi

Qanta ile hisse senedi portföyünüzü kolayca yönetin, işlemlerinizi takip edin ve yatırım performansınızı analiz edin.

🎯 Özellikler:

📊 Portföy Yönetimi
• Gerçek zamanlı portföy değeri takibi
• Hisse bazlı kar/zarar hesaplama
• Detaylı işlem geçmişi
• Ortalama maliyet hesaplama

💰 Finansal Takip
• Gelir-gider yönetimi
• Nakit akışı takibi
• Aylık finansal raporlar
• Kategori bazlı harcama analizi

📱 Kullanıcı Dostu Arayüz
• Modern ve şık tasarım
• Kolay kullanım
• Türkçe dil desteği
• Karanlık mod desteği

🔒 Güvenlik
• Firebase güvenlik altyapısı
• Kişisel verileriniz güvende
• Hesap doğrulama sistemi

📸 Ek Özellikler
• Profil fotoğrafı yükleme
• Özelleştirilebilir ayarlar
• Bildirim yönetimi

Qanta ile yatırımlarınızı profesyonel bir şekilde yönetin!

📧 Destek: support@qanta.com (değiştirin)
🌐 Web: www.qanta.com (değiştirin)
```

#### 5.2 Grafiksel Varlıklar

**Gerekli:**
- ⚠️ **Uygulama İkonu**: 512x512 PNG (mevcut: `play-store-assets/app_icon_512.png`)
- ⚠️ **Feature Graphic**: 1024x500 PNG (OLUŞTURULMALI)
- ⚠️ **Ekran Görüntüleri**: Min 2, Max 8 adet
  - Telefon: 1080x1920 veya 1080x2340 px
  - Tablet (opsiyonel): 1536x2048 px

**Ekran Görüntüsü Rehberi:**
1. Ana sayfa (Dashboard)
2. Portföy ekranı
3. İşlem ekleme
4. Finansal rapor
5. Profil sayfası

### Adım 6: Fiyatlandırma ve Dağıtım

- ✅ Ücretsiz uygulama
- ✅ Türkiye ve diğer ülkeler seçili
- ✅ Reklam içeriyor mu? (Google Ads kullanıyorsunuz → **EVET**)
- ✅ Uygulama içi satın alma var mı? → **HAYIR** (şimdilik)

### Adım 7: App Bundle/APK Yükleme

1. Play Console'da **Üretim** > **Yeni sürüm oluştur**
2. `app-release.aab` dosyasını yükleyin
3. **Sürüm notları** ekleyin:
```
İlk sürüm - v1.0.0

• Hisse senedi portföy yönetimi
• Gelir-gider takibi
• Detaylı finansal raporlar
• Modern kullanıcı arayüzü
```

### Adım 8: İnceleme ve Yayınlama

1. Tüm bölümlerin doldurulduğundan emin olun
2. **İncelemeye gönder** butonuna tıklayın
3. Google'ın incelemesi **1-7 gün** sürer
4. Onaylandıktan sonra yayında olacak!

---

## ⚠️ Yapılması Gerekenler

### Kritik (Build Öncesi)
- [ ] Google Ads App ID'yi gerçek ID ile değiştir (şu an test ID)
  ```xml
  <!-- android/app/src/main/AndroidManifest.xml -->
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ```

### Orta Öncelik (Store Listing için)
- [ ] Gizlilik politikası URL'i hazırla
- [ ] Feature Graphic (1024x500) oluştur
- [ ] En az 2 ekran görüntüsü al
- [ ] Destek email adresi hazırla
- [ ] Varsa web sitesi URL'i ekle

### Düşük Öncelik (Gelişmiş)
- [ ] Tablet ekran görüntüleri (opsiyonel)
- [ ] Tanıtım videosu (opsiyonel)
- [ ] Çoklu dil desteği (İngilizce store listing)

---

## 🧪 Test Checklist

Build öncesi test edin:
- [ ] Uygulama açılıyor mu?
- [ ] Giriş/Kayıt çalışıyor mu?
- [ ] Firebase bağlantısı var mı?
- [ ] Tüm sayfalar yükleniyor mu?
- [ ] İşlem ekleme/silme çalışıyor mu?
- [ ] Raporlar düzgün gösteriliyor mu?
- [ ] Reklam gösterimi çalışıyor mu?
- [ ] Profil fotoğrafı yükleme çalışıyor mu?
- [ ] Çıkış yapma çalışıyor mu?

---

## 📱 Test Build Komutu

```bash
# Release build test
flutter build apk --release
flutter install --release

# veya App Bundle
flutter build appbundle --release
```

---

## 🎨 Ekran Görüntüsü Alma

```bash
# Android cihazdan ekran görüntüsü al
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# veya Flutter DevTools kullan
flutter screenshot
```

---

## 📞 Destek ve Yardım

Build veya yükleme sırasında sorun yaşarsanız:

1. **Build Hataları**: 
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   cd .. && flutter build appbundle --release
   ```

2. **Signing Hataları**: 
   - `key.properties` dosyasını kontrol edin
   - Keystore şifresinin doğru olduğundan emin olun

3. **Size Hataları**: 
   - App Bundle kullanın (APK'dan daha küçük)
   - Kullanılmayan asset'leri temizleyin

---

## 🎉 Başarılı Build Sonrası

AAB/APK başarıyla oluştuysa:
1. ✅ Test cihazında çalıştırın
2. ✅ Tüm özellikleri test edin
3. ✅ Play Console'da yükleyin
4. ✅ Store listing bilgilerini doldurun
5. ✅ İncelemeye gönderin
6. ✅ Onayı bekleyin (1-7 gün)

---

**Son Güncelleme**: 8 Ekim 2025
**Hazırlayan**: Qanta Development Team
