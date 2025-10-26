# 🤖 Qanta AI Setup Guide

## Gemini API Key Alma

1. **Google AI Studio'ya Git:**
   https://makersuite.google.com/app/apikey

2. **Google hesabınla giriş yap**

3. **"Get API Key" butonuna tıkla**

4. **"Create API key in new project" seç**

5. **API Key'i kopyala** (örnek: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXX)

## API Key'i Uygulamaya Ekle

1. Dosyayı aç:
   ```
   lib/core/services/ai/gemini_ai_service.dart
   ```

2. Şu satırı bul (satır 10):
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```

3. API key'i yapıştır:
   ```dart
   static const String _apiKey = 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXX';
   ```

4. Kaydet!

## Ücretsiz Limitler

- ✅ İlk 15 milyon token **TAMAMEN ÜCRETSIZ**
- ✅ Saniyede 15 istek
- ✅ Dakikada 1,500 istek
- ✅ Günlük 1,500,000 istek

**1,000 kullanıcı için ~3-6 ay ücretsiz kullanım!** 🎉

## Test Et

1. Uygulamayı çalıştır
2. Yeni harcama ekle
3. Description'a "Starbucks kahve" yaz
4. 1 saniye bekle
5. AI otomatik kategori önerecek! ✨

## Notlar

- API key şu an kod içinde (test için)
- Production'da environment variable'a taşınmalı
- Firebase Functions'a geçince key backend'de olacak (daha güvenli)

## Sorun Giderme

### "API key geçersiz" hatası:
- Key'i doğru kopyaladığından emin ol
- Başında/sonunda boşluk olmasın
- Tırnak işaretlerinin içinde olmalı

### "Network error" hatası:
- İnternet bağlantını kontrol et
- VPN kullanıyorsan kapat
- Biraz bekle ve tekrar dene

### AI yanıt vermiyor:
- Description en az 3 karakter olmalı
- 1 saniye bekle (debounce var)
- Console'da log'ları kontrol et

## İletişim

Sorun yaşarsan bana sor! 🚀

