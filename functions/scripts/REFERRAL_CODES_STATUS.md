# Referral Codes - Durum ve Kontrol

## ✅ Tamamlanan İşlemler

### 1. Cloud Function Deploy
- ✅ `processReferralCode` function deploy edildi
- ✅ Region: `us-central1`
- ✅ Function referral code'ları otomatik oluşturuyor

### 2. Referral Code Oluşturma Mantığı
- ✅ Referral code = User ID'nin ilk 8 karakteri (uppercase)
- ✅ Örnek: User ID `rcyqEbFJHbYzfFsiC4XtQUN7sx92` → Referral Code `RCYQEBFJ`
- ✅ `processReferralCode` function'ı referral code oluşturuyor

### 3. Migration Script'leri
- ✅ `generateReferralCodes.js` - Eski kullanıcılar için referral code oluşturur
- ✅ `checkReferralCodes.js` - Referral code'ları kontrol eder

## ⚠️ Yapılması Gerekenler

### 1. Eski Kullanıcılar İçin Migration

Eski kullanıcıların referral code'larını oluşturmak için:

```bash
cd functions
node scripts/generateReferralCodes.js
```

**Not**: Script çalıştırmadan önce `serviceAccountKey.json` dosyasının `functions/` klasöründe olduğundan emin olun.

### 2. Kontrol

Referral code'ların doğru oluşturulup oluşturulmadığını kontrol etmek için:

```bash
cd functions
node scripts/checkReferralCodes.js
```

### 3. Deploy Kontrolü

`processReferralCode` function'ının deploy edildiğini kontrol etmek için:

```bash
cd functions
firebase deploy --only functions:processReferralCode
```

## 🔍 Kontrol Adımları

### 1. Firestore'da Kontrol

1. Firebase Console → Firestore Database
2. `users` collection'ına gidin
3. Bir kullanıcı document'ını açın
4. `referral_code` field'ının var olduğunu ve 8 karakter olduğunu kontrol edin

### 2. App'te Kontrol

1. Uygulamayı açın
2. Profile → Referral Widget'a gidin
3. Referral code'un göründüğünü kontrol edin
4. Referral code'un 8 karakter olduğunu kontrol edin

### 3. Cloud Function Log'ları

1. Firebase Console → Functions → `processReferralCode`
2. Logs sekmesine gidin
3. Referral code işlemlerinin loglandığını kontrol edin

## 📊 Referral Code Formatı

- **Format**: 8 karakter, alphanumeric, uppercase
- **Örnek**: `RCYQEBFJ`, `ABCD1234`, `XYZ98765`
- **Oluşturma**: User ID'nin ilk 8 karakteri (uppercase)

## 🚀 Yeni Kullanıcılar İçin

Yeni kullanıcılar için referral code otomatik olarak oluşturulur:
1. Kullanıcı kayıt olur
2. `processReferralCode` function'ı çağrılır
3. Referral code otomatik oluşturulur (User ID'nin ilk 8 karakteri)

## ⚙️ Troubleshooting

### Referral Code Görünmüyor

1. User document'ında `referral_code` field'ı var mı kontrol edin
2. Referral code 8 karakter mi kontrol edin
3. App log'larını kontrol edin
4. Migration script'ini çalıştırın

### Referral Code Geçersiz

1. `checkReferralCodes.js` script'ini çalıştırın
2. Hatalı referral code'ları kontrol edin
3. `generateReferralCodes.js` script'ini çalıştırarak düzeltin

### Referral Code Bulunamıyor

1. Referral code'un Firestore'da var olduğunu kontrol edin
2. Referral code'un doğru formatta olduğunu kontrol edin (8 karakter, uppercase)
3. Cloud Function log'larını kontrol edin

## 📝 Notlar

- Referral code'lar user ID'ye bağlıdır, değiştirilemez
- Her kullanıcının benzersiz bir referral code'u vardır
- Referral code lookup `referral_code` field'ına göre yapılır
- Self-referral engellenmiştir
- Max 5 referral limiti vardır

