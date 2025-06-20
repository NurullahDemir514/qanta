# Qanta Logo Assets

Bu klasör Qanta uygulamasının logo dosyalarını içerir.

## Mevcut Logo Dosyaları

### 1. logo.png (30KB)
- **Boyut**: 192x192px (mipmap-xxxhdpi'den kopyalandı)
- **Format**: PNG
- **Kullanım**: Ana logo, splash screen, onboarding

### 2. logo_white.png (30KB)
- **Boyut**: 192x192px
- **Format**: PNG
- **Kullanım**: Koyu arka planlar için (şu anda ana logo ile aynı)

### 3. logo_small.png (4KB)
- **Boyut**: 72x72px (mipmap-hdpi'den kopyalandı)
- **Format**: PNG
- **Kullanım**: App bar, küçük widget'lar, kompakt alanlar

## Kaynak Dosyalar

Logo dosyaları şu kaynaklardan kopyalandı:
- `assets/android/mipmap-xxxhdpi/logo.png` → `logo.png`, `logo_white.png`
- `assets/android/mipmap-hdpi/logo.png` → `logo_small.png`

## Fallback Mekanizması

Logo dosyaları bulunamazsa, `QantaLogo` widget'ı otomatik olarak gradient arka planlı "Q" harfi gösterir.

## Kullanım

```dart
// Küçük logo (app bar için)
QantaLogo.small()

// Orta boyut logo (metin ile)
QantaLogo.medium(showText: true)

// Büyük logo (splash screen için)
QantaLogo.large()
```

## Güncelleme

Logo dosyalarını güncellemek için:
1. Yeni logo dosyalarını bu klasöre koyun
2. `flutter clean && flutter pub get` çalıştırın
3. Uygulamayı yeniden başlatın

## Tasarım Kuralları

- Logo tasarımı minimalist ve modern olmalı
- Qanta markasını temsil etmeli
- Farklı boyutlarda okunabilir olmalı
- Şeffaf arka plan kullanmalı
- Yüksek çözünürlükte olmalı

## Dosya Konumları

- `assets/images/logo.png` - Ana logo
- `assets/images/logo_white.png` - Beyaz logo
- `assets/images/logo_small.png` - Küçük logo

Bu dosyalar `pubspec.yaml` içinde `assets/images/` klasörü altında tanımlanmıştır. 