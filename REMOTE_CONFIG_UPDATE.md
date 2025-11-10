# 🔄 Remote Config Güncelleme - point_referral = 500

## ✅ Yapılan Değişiklikler

1. **Cloud Function**: Sabit 500 puan kullanıyor (deploy edildi ✅)
2. **Flutter App**: Sabit 500 puan kullanıyor (mesaj ve widget'ta)
3. **Remote Config Dosyası**: `remote_config_merged.json` güncellendi (500'e çevrildi)

## 📋 Firebase Console'dan Manuel Güncelleme (2 dakika)

### Adımlar:

1. **Firebase Console'a gidin:**
   - https://console.firebase.google.com/project/qanta-de0b9/config

2. **Remote Config sayfasına gidin:**
   - Sol menüden **"Remote Config"** seçin

3. **`point_referral` parametresini bulun/güncelleyin:**
   - Mevcut parametreler listesinde `point_referral`'ı arayın
   - Eğer yoksa: **"+ Add parameter"** butonuna tıklayın
   - **Parameter key**: `point_referral`
   - **Default value**: `500`
   - **Data type**: `Number`
   - **Description**: `Point - Referans puanı (her arkadaş getirene)`

4. **Değişiklikleri yayınlayın:**
   - **"Publish changes"** butonuna tıklayın
   - Onaylayın

## 🎯 Alternatif: Script ile Deploy (Firebase login gerekli)

```bash
# 1. Firebase'e login olun
firebase login --reauth

# 2. Script'i çalıştırın
cd /Users/onurdemir/projects/qanta
node functions/deploy_remote_config_firebase_cli.js
```

## ✅ Doğrulama

Remote Config güncellemesi yapıldıktan sonra:

1. Flutter app'i yeniden başlatın
2. Referral widget'ta mesajın 500 puan gösterdiğini kontrol edin
3. Cloud Function log'larında 500 puan verildiğini kontrol edin

## 📝 Not

- **Cloud Function** ve **Flutter App** şu anda sabit 500 puan kullanıyor
- Remote Config'i güncellemek **zorunlu değil** ama **tutarlılık için önerilir**
- Eğer Remote Config'de farklı bir değer varsa, Cloud Function ve Flutter App yine de 500 puan kullanacak

## 🔍 Mevcut Durum

- ✅ Cloud Function: Sabit 500 puan (deploy edildi)
- ✅ Flutter App: Sabit 500 puan (mesajda ve widget'ta)
- ⏳ Remote Config: 100 (Firebase Console'dan 500'e güncellenmeli)

