# 🔥 Firebase Functions Setup Guide

## 📋 Kurulum Tamamlandı!

✅ Firebase Functions klasörü oluşturuldu  
✅ AI kategoriz asyon fonksiyonu yazıldı  
✅ Dependencies yüklendi

---

## 🔑 ŞİMDİ YAPILACAK: API Key Ekle

### **YÖ NTEM 1: Firebase Console'dan (Önerilir)** 🌟

1. **Firebase Console'a Git:**
   https://console.firebase.google.com/project/qanta-de0b9/functions

2. **Sol menüden "Functions" → "Environment Variables" seç**

3. **"Add Variable" butonuna tıkla**

4. **Şu bilgileri gir:**
   - Name: `GEMINI_API_KEY`
   - Value: `AIzaSyAZJAs_OCsi-gmYpN1RaX7dQGaIZY-8n-Q`

5. **Save** butonuna tıkla

---

### **YÖNTEM 2: Terminal ile (Alternatif)**

Terminal'de şunu çalıştır:

```bash
cd /Users/onurdemir/projects/qanta
echo "AIzaSyAZJAs_OCsi-gmYpN1RaX7dQGaIZY-8n-Q" | firebase functions:secrets:set GEMINI_API_KEY
```

---

## 🚀 DEPLOY ET!

API key eklendikten sonra:

```bash
cd /Users/onurdemir/projects/qanta
firebase deploy --only functions
```

---

## 📱 Flutter'da Kullan

Deploy edildikten sonra Flutter'da çağırmak için:

### 1. Package Ekle (Zaten var)
```yaml
dependencies:
  cloud_functions: ^5.1.3  # Zaten eklendi
```

### 2. Servisi Güncelle
```dart
// lib/core/services/ai/firebase_ai_service.dart oluştur
```

---

## 🎯 Test Et

Deploy edildikten sonra:
1. Uygulamayı aç
2. Yeni harcama ekle
3. "Starbucks kahve" yaz
4. AI kategorize edecek! 🤖

---

## ⚠️ Önemli Notlar

- API key güvende (backend'de)
- Rate limiting otomatik
- Fallback mekanizması var
- Auth kontrolü aktif

---

## 🐛 Sorun Giderme

### Deploy hatası alırsan:
```bash
firebase logout
firebase login
firebase deploy --only functions
```

### Function çalışmazsa:
- Firebase Console'dan logs kontrol et
- API key doğru eklenmiş mi kontrol et
- Billing aktif mi kontrol et

---

**Hazır mısın? Deploy et!** 🚀

