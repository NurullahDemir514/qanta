# Qanta - Personal Finance App

Modern bir kişisel finans yönetimi mobil uygulaması. Flutter ile geliştirilmiş, bütçe yönetimi, harcama takibi, yatırım portföyü ve AI destekli finansal analitikler sunar.

## 🎯 Özellikler

- **Harcama Takibi**: Gelir ve giderleri kategorize ederek takip edin
- **Kart Yönetimi**: Kredi kartları, banka kartları ve nakit hesapları
- **Bütçe Planlama**: Aylık bütçe hedefleri ve takibi
- **Finansal Analitikler**: Detaylı raporlar ve grafikler
- **AI Öneriler**: Akıllı finansal öneriler ve insights
- **Multi-dil Desteği**: Türkçe ve İngilizce
- **Tema Desteği**: Açık ve koyu tema seçenekleri

## 🛠 Teknoloji Stack

- **Framework**: Flutter 3.8.1+
- **Dil**: Dart
- **State Management**: Provider
- **Veritabanı**: Supabase
- **Navigasyon**: GoRouter
- **UI**: Material 3 Design System
- **Fontlar**: Google Fonts (Inter)

## 🎨 Renk Paleti

- **Primary**: Sophisticated Grey (#6D6D70)
- **Secondary**: Mint Green (#34D399)
- **iOS Blue**: (#007AFF)
- **Success**: Green (#4CAF50)
- **Error**: Red (#FF4C4C)

## 📱 Kurulum

1. Flutter SDK'yı yükleyin (3.8.1+)
2. Projeyi klonlayın:
   ```bash
   git clone [repository-url]
   cd qanta
   ```
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 🖼 Logo Assets

Logo dosyaları `assets/images/` klasöründe bulunmalıdır:
- `logo.png` - Ana logo (512x512px)
- `logo_white.png` - Beyaz logo (512x512px)
- `logo_small.png` - Küçük logo (128x128px)

Detaylı bilgi için: `assets/images/README.md`

## 📁 Proje Yapısı

```
lib/
├── core/                 # Temel servisler ve yapılandırma
├── modules/             # Özellik modülleri
│   ├── auth/           # Kimlik doğrulama
│   ├── home/           # Ana sayfa
│   ├── transactions/   # İşlem yönetimi
│   ├── cards/          # Kart yönetimi
│   ├── insights/       # Analitikler
│   └── settings/       # Ayarlar
├── shared/             # Paylaşılan bileşenler
└── l10n/              # Çoklu dil desteği
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'i push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
