# Referral Codes - Hızlı Kontrol Rehberi

## ✅ Kontrol Adımları

### 1. Cloud Function Deploy Kontrolü

```bash
cd functions
firebase deploy --only functions:processReferralCode
```

**Beklenen Çıktı:**
```
✔  functions[processReferralCode(us-central1)] Successful update operation.
```

### 2. Firebase Console'dan Kontrol

1. **Firebase Console'a gidin**: https://console.firebase.google.com/project/qanta-de0b9
2. **Firestore Database** → **Data** sekmesine gidin
3. **users** collection'ına gidin
4. Bir kullanıcı document'ını açın
5. **referral_code** field'ının var olduğunu kontrol edin
   - ✅ Varsa: 8 karakter olmalı (örn: `RCYQEBFJ`)
   - ❌ Yoksa: Migration script çalıştırılmalı

### 3. App'te Kontrol

1. Uygulamayı açın
2. **Profile** → **Referral Widget**'a gidin
3. Referral code'un göründüğünü kontrol edin
   - ✅ Görünüyorsa: Referral code mevcut
   - ❌ Görünmüyorsa: Referral code oluşturulmamış

### 4. Cloud Function Log'ları

1. **Firebase Console** → **Functions** → **processReferralCode**
2. **Logs** sekmesine gidin
3. Referral code işlemlerinin loglandığını kontrol edin

## 🔧 Migration (Eski Kullanıcılar İçin)

### Service Account Key Gerekli

1. **Firebase Console** → **Project Settings** → **Service Accounts**
2. **"Generate New Private Key"** butonuna tıklayın
3. JSON dosyasını indirin
4. `functions/serviceAccountKey.json` olarak kaydedin
5. Script'i çalıştırın:

```bash
cd functions
node scripts/generateReferralCodes.js
```

## 📊 Kontrol Script'leri

### checkReferralCodes.js
- Tüm kullanıcıların referral code'larını kontrol eder
- Service account key veya Firebase CLI credentials gerekli

### generateReferralCodes.js
- Eski kullanıcılar için referral code oluşturur
- Service account key gerekli

### checkReferralCodesViaFunction.js
- Alternatif kontrol yöntemleri gösterir
- Herhangi bir credential gerektirmez

## ✅ Mevcut Durum

- ✅ **processReferralCode Cloud Function**: Deploy edildi
- ✅ **Yeni kullanıcılar**: Referral code otomatik oluşturuluyor
- ⚠️  **Eski kullanıcılar**: Migration script çalıştırılmalı

## 🚀 Hızlı Test

1. Yeni bir test kullanıcısı oluşturun
2. App'te Profile → Referral Widget'a gidin
3. Referral code'un göründüğünü kontrol edin
4. Referral code'un 8 karakter olduğunu kontrol edin

## 📝 Notlar

- Referral code = User ID'nin ilk 8 karakteri (uppercase)
- Her kullanıcının benzersiz bir referral code'u vardır
- Referral code değiştirilemez (user ID'ye bağlı)
- Self-referral engellenmiştir
- Max 5 referral limiti vardır

