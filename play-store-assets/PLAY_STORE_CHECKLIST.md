# 🚀 Play Store Yükleme Hazırlık Checklist

## ✅ Tamamlananlar

### 1. Grafikler ve Medya
- [x] **App Icon** - 512x512 PNG oluşturuldu (`play-store-assets/app_icon_512.png`)
- [x] **Figma Design Prompt** - Detaylı tasarım kılavuzu hazır (`play-store-assets/FIGMA_DESIGN_PROMPT.md`)
- [ ] **Feature Graphic** - 1024x500 PNG (Figma'da oluşturulmalı)
- [ ] **Screenshots** - En az 2, maksimum 8 adet (1080x1920 veya 1080x2340)

### 2. Mock Data Generator
- [x] Mock accounts generator (4 hesap)
- [x] Mock transactions generator (7 işlem)
- [x] Mock stock positions generator (3 hisse)
- [x] Yardımcı metodlar ve summary fonksiyonları
- [x] Kullanım kılavuzu (`MOCK_DATA_USAGE.md`)
- [ ] Provider entegrasyonu (screenshot için)

## 🎯 Önümüzdeki Adımlar

### Adım 1: Mock Data Entegrasyonu (30 dk)

**1.1 Debug Toggle Ekle**
```dart
// lib/modules/profile/profile_screen.dart içinde

// Debug section ekle (en alta)
if (kDebugMode) {
  Divider(),
  Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🐛 Debug Tools', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.data_object, color: Colors.orange),
          title: Text('Mock Data'),
          subtitle: Text('Screenshot için örnek veriler'),
          trailing: Switch(
            value: _mockDataEnabled,
            onChanged: (value) => _toggleMockData(value),
          ),
        ),
      ],
    ),
  ),
}
```

**1.2 Toggle Handler Ekle**
```dart
bool _mockDataEnabled = false;

void _toggleMockData(bool enabled) async {
  setState(() => _mockDataEnabled = enabled);
  
  if (enabled) {
    // Mock verileri yükle
    final mockAccounts = MockDataGenerator.generateMockAccounts();
    final mockTransactions = MockDataGenerator.generateMockTransactions();
    final mockStocks = MockDataGenerator.generateMockStockPositions();
    
    // Provider'lara yükle (örnek)
    // context.read<UnifiedProviderV2>().loadMockData(mockAccounts, mockTransactions);
    // context.read<StockProvider>().loadMockData(mockStocks);
    
    print('✅ Mock veriler yüklendi');
    print(MockDataGenerator.getMockDataSummary());
  } else {
    // Verileri temizle ve Firebase'den yeniden yükle
    // context.read<UnifiedProviderV2>().reloadFromFirebase();
    // context.read<StockProvider>().reloadFromFirebase();
    
    MockDataGenerator.clearMockData();
  }
}
```

### Adım 2: Screenshot Çek (15 dk)

**2.1 Mock Data'yı Etkinleştir**
- Profile → Debug Tools → Mock Data → ON

**2.2 Ekran Görüntüleri Çek**
1. **Home Screen** - Net değer, hesaplar, hisseler görünsün
2. **Hesaplar Listesi** - 4 hesap görünsün
3. **İşlemler Listesi** - Son işlemler görünsün
4. **Hisse Portföyü** - 3 hisse pozisyonu görünsün
5. **Profil & Ayarlar** - Profil bilgileri görünsün

**2.3 Kaydet**
```bash
# Screenshot'ları kaydet
mkdir -p play-store-assets/screenshots
# iOS: Cmd+S (Simulator)
# Android: Volume Down + Power
```

### Adım 3: Feature Graphic Oluştur (30 dk)

**3.1 Figma'da Aç**
- `play-store-assets/FIGMA_DESIGN_PROMPT.md` dosyasını takip et
- 1024x500 boyutunda artboard oluştur

**3.2 Tasarım Elementleri**
- Gradient background (Tema 1, 2 veya 3)
- App icon (sol üst)
- Ana başlık: "Qanta" veya "Akıllı Finans Yönetimi"
- Alt başlık: "Hesaplarınızı ve Yatırımlarınızı Tek Bir Yerde"
- Mockup phone screenshot (sağda)

**3.3 Export**
```
Format: PNG
Size: 1024x500
Quality: 100%
Save as: play-store-assets/feature_graphic_1024x500.png
```

### Adım 4: Screenshot Mockup (İsteğe Bağlı) (20 dk)

**4.1 Mockup Tool Kullan**
- [mockuuups.studio](https://mockuuups.studio)
- [previewed.app](https://previewed.app)
- Veya Figma'da manuel olarak

**4.2 Device Frames**
- iPhone 15 Pro veya Samsung S24
- Minimal arka plan (beyaz veya açık gri gradient)

**4.3 Export**
```
Format: PNG
Size: 1080x1920 veya 1080x2340
Quality: 100%
Save as: play-store-assets/screenshots/screen_1.png, etc.
```

### Adım 5: Play Store Metadata (15 dk)

**5.1 Başlık**
```
Qanta - Finans Yönetimi
```

**5.2 Kısa Açıklama** (80 karakter maks)
```
Hesaplarınızı, harcamalarınızı ve yatırımlarınızı tek bir yerde yönetin
```

**5.3 Tam Açıklama** (4000 karakter maks)
```
Qanta ile finansal hayatınızı tam kontrolünüz altına alın! 💰

✨ ÖZELLİKLER

📊 Hesap Yönetimi
• Banka hesaplarınızı, kredi kartlarınızı ve nakit paranızı tek bir yerden takip edin
• Hesaplarınız arasında hızlıca transfer yapın
• Kredi kartı borçlarınızı ve limitlerini görüntüleyin

💸 Akıllı Harcama Takibi
• Tüm harcamalarınızı otomatik kategorilere ayırın
• Günlük, haftalık ve aylık harcamalarınızı analiz edin
• Gelir-gider dengenizi grafiklerle görselleştirin

📈 Hisse Senedi Takibi
• BIST 100 ve diğer hisseleri takip edin
• Portföyünüzün anlık değerini görün
• Günlük performansınızı ve kar/zarar durumunuzu izleyin

🎯 Bütçe ve Hedefler
• Kategori bazlı harcama limitleri belirleyin
• Hedeflerinize ulaşma sürecinizi takip edin
• Akıllı bildirimlerle bütçenizi aşmayın

🔒 Güvenlik
• Biometric giriş (Face ID / Touch ID)
• Verileriniz güvenli Firebase altyapısında
• Şifreleme ile korunan hassas bilgiler

🌙 Modern Tasarım
• Koyu ve açık tema desteği
• Sezgisel ve kullanıcı dostu arayüz
• Türkçe dil desteği

Qanta ile finansal özgürlüğünüze bir adım daha yaklaşın! 🚀

İletişim: [email]
Gizlilik Politikası: [url]
Kullanım Koşulları: [url]
```

**5.4 Kategoriler**
- Birincil: Finance
- İkincil: Productivity

**5.5 Anahtar Kelimeler**
```
finans, bütçe, hesap, harcama, gelir, para, yatırım, hisse, borsa, BIST, kredi kartı, banka
```

### Adım 6: Store Listing Kontrolü

- [ ] App icon yüklendi (512x512)
- [ ] Feature graphic yüklendi (1024x500)
- [ ] En az 2 screenshot yüklendi
- [ ] Başlık 50 karakter altında
- [ ] Kısa açıklama 80 karakter altında
- [ ] Tam açıklama 4000 karakter altında
- [ ] Gizlilik politikası URL'i eklendi
- [ ] İletişim email adresi eklendi
- [ ] Kategoriler seçildi
- [ ] İçerik derecelendirmesi tamamlandı

### Adım 7: App Bundle Hazırlık

**7.1 Version & Build Number**
```yaml
# pubspec.yaml
version: 1.0.0+1
```

**7.2 Build AAB**
```bash
# Android App Bundle oluştur
flutter build appbundle --release

# Dosya burada:
# build/app/outputs/bundle/release/app-release.aab
```

**7.3 Test**
```bash
# Internal testing track'e yükle
# Play Console → Testing → Internal testing
# → Create release → Upload app-release.aab
```

### Adım 8: Play Console Yapılandırması

**8.1 Uygulama Bilgileri**
- [ ] Uygulama adı
- [ ] Kısa açıklama
- [ ] Tam açıklama
- [ ] Uygulama ikonu
- [ ] Feature graphic
- [ ] Screenshots

**8.2 Mağaza Ayarları**
- [ ] Uygulama kategorisi
- [ ] İçerik derecelendirmesi
- [ ] Hedef kitle ve içerik
- [ ] Gizlilik politikası
- [ ] Veri güvenliği

**8.3 Fiyatlandırma ve Dağıtım**
- [ ] Ülkeler seçildi (Türkiye)
- [ ] Fiyat: Ücretsiz
- [ ] İçi içerikler (varsa belirtildi)
- [ ] Reklam içeriği (varsa belirtildi)

**8.4 App Content**
- [ ] Privacy Policy URL
- [ ] Data Safety Form
- [ ] Target Audience
- [ ] App Category
- [ ] Content Ratings (ESRB, PEGI, etc.)

## 📋 Final Checklist

### Release Öncesi
- [ ] Mock data toggle Profile'da çalışıyor
- [ ] Screenshot'lar çekildi (5 adet)
- [ ] Feature graphic oluşturuldu
- [ ] Play Store metadata hazır
- [ ] AAB build başarılı
- [ ] Internal test başarılı

### Play Console
- [ ] Store listing tamamlandı
- [ ] App content tamamlandı
- [ ] Pricing & distribution tamamlandı
- [ ] Release management ayarlandı

### Son Kontroller
- [ ] Mock data kodu DEBUG modunda
- [ ] Firebase kuralları production'a hazır
- [ ] API key'ler güvende
- [ ] Test kullanıcıları eklendi
- [ ] Crash reporting aktif

## 🎉 Yayınlama

```bash
# Production release oluştur
1. Play Console → Production → Create Release
2. Upload app-release.aab
3. Release notes ekle
4. Review & Submit
5. Google review'ı bekle (1-3 gün)
```

## 📞 Destek

Mock data veya Play Store sorunları için:
- `MOCK_DATA_USAGE.md` dosyasına bakın
- `FIGMA_DESIGN_PROMPT.md` dosyasına bakın
- Play Console Help Center: https://support.google.com/googleplay/android-developer

---

**Tahmini Toplam Süre:** 2-3 saat
**Zorluk Seviyesi:** Orta
**Öncelik:** Yüksek 🔥
