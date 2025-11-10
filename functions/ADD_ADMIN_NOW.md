# ✅ Admin Ekleme - Hızlı Adımlar

## User ID Bulundu! 🎉

**Email:** nurullahdemir6337@gmail.com  
**User ID:** `rcyqEbFJHbYzfFsiC4XtQUN7sx92`

---

## Firebase Console'dan Ekleme (2 dakika) ⭐

1. **Firebase Console**: https://console.firebase.google.com/project/qanta-de0b9/firestore
2. **Firestore Database → Data** sekmesine gidin
3. **Collection oluştur/düzenle**: `admins` → Document: `admin_list`
4. **Document'ı düzenleyin**:
   ```json
   {
     "userIds": ["rcyqEbFJHbYzfFsiC4XtQUN7sx92"],
     "updatedAt": "2025-01-15T10:00:00Z"
   }
   ```
   - Eğer `userIds` array'i varsa, içine ekleyin
   - Eğer yoksa, yeni array oluşturup ekleyin
5. **Save** butonuna tıklayın

✅ **Tamamlandı!** Artık admin yetkisine sahipsiniz.

---

## Script ile Ekleme (Service Account Key gerekli)

1. **Service Account Key oluştur**:
   - Firebase Console → Project Settings → Service Accounts
   - "Generate New Private Key" → JSON indir
   - `functions/serviceAccountKey.json` olarak kaydet

2. **Script'i çalıştır**:
   ```bash
   cd functions
   USER_ID=rcyqEbFJHbYzfFsiC4XtQUN7sx92 node add_admin.js
   ```

---

## Doğrulama

Uygulamada:
1. Profile sayfasına gidin
2. "Admin Info" butonuna tıklayın
3. User ID'nizin listede olduğunu kontrol edin
4. "Admin Dashboard" linkinin göründüğünü kontrol edin
