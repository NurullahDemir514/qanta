# Referral Code Generation Guide

## Admin Olarak Referral Code'ları Generate Etme

Mevcut kullanıcılar için referral code'ları generate etmek için web admin panelinden yapabilirsiniz:

### Yöntem: Web Admin Panelinden (Önerilen)

1. Web admin paneline gidin: `https://your-domain.com/admin`
2. Admin olarak giriş yapın
3. "Referrals" sekmesine tıklayın
4. Sayfanın üst kısmında "Referral Kodları Oluştur" butonuna tıklayın
5. Onay mesajını kabul edin
6. İşlem tamamlandığında sonuçları görüntüleyin

**Özellikler:**
- ✅ Admin kontrolü (sadece admin kullanıcılar çağırabilir)
- ✅ Loading state (işlem sırasında buton disabled)
- ✅ Başarı/hata mesajları
- ✅ Otomatik stats güncelleme

### Alternatif Yöntem: Firebase Console'dan

1. Firebase Console'a gidin: https://console.firebase.google.com/project/qanta-de0b9
2. Functions sekmesine gidin
3. `generateReferralCodesForAllUsers` function'ını bulun
4. "Test" sekmesine tıklayın
5. "Run" butonuna tıklayın
6. Sonuçları kontrol edin

## Önemli Notlar

1. **Admin Kontrolü**: Bu function sadece admin kullanıcılar tarafından çağrılabilir
2. **Batch İşleme**: Kullanıcılar 500'lük batch'ler halinde işlenir (timeout önleme)
3. **Mevcut Kodlar**: Zaten referral code'u olan kullanıcılar atlanır
4. **Referral Code Formatı**: User ID'nin ilk 8 karakteri (uppercase)

## Sonuç

Function başarıyla çalıştıktan sonra:
- Tüm kullanıcıların `referral_code` field'ı set edilmiş olacak
- Yeni kullanıcılar için referral code otomatik oluşturulacak
- Referral sistemi tam olarak çalışır hale gelecek

