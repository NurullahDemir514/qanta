# 🎉 İlk Kullanıcılar İçin %50 İndirimli Aylık Premium Kampanyası

## 📋 Kampanya Detayları

- **Hedef Grup**: İlk 7 gün içindeki yeni kullanıcılar
- **İndirim Oranı**: %50
- **Normal Fiyat**: ₺49,99/ay
- **Kampanya Fiyatı**: ₺24,99/ay
- **Kampanya Süresi**: İlk 7 gün (kayıt tarihinden itibaren)
- **Product ID**: `qanta_premium_monthly_promo_50`

---

## 🚀 Google Play Console Kurulumu

### Adım 1: Yeni Abonelik Ürünü Oluştur

1. **Google Play Console**'a git
2. Sol menüden **Monetization** > **Subscriptions** seçeneğini seç
3. **Create subscription** butonuna tıkla

### Adım 2: Ürün Detayları

```
Product ID: qanta_premium_monthly_promo_50
Name: Qanta Premium Monthly (50% Off - Welcome Campaign)
Description: Get Qanta Premium for 50% off! Special offer for new users.
```

### Adım 3: Fiyatlandırma

```
Base Plan: Monthly
Billing Period: 1 Month (Recurring)
Grace Period: 3 Days (Recommended)
```

**Fiyat Ayarları:**
- **Türkiye (TRY)**: ₺24,99
- **ABD (USD)**: $2,99 (referans)
- **Euro (EUR)**: €2,99 (referans)

### Adım 4: Kampanya Özel Ayarları

1. **Eligibility**: Yeni aboneler
2. **Auto Renew**: Evet
   - İlk ay sonrasında **₺49,99** ile yenilenir
3. **Free Trial**: Hayır (zaten %50 indirimli)

---

## 🎯 Kampanya Mantığı (Kod Tarafı)

### Otomatik Kontrol Sistemi

```dart
// PremiumService içinde
Future<bool> isEligibleForPromotion() async {
  // 1. Premium kullanıcı değilse
  // 2. Kayıt tarihinden 7 gün geçmemişse
  // 3. Kampanyalı üründen daha önce satın almamışsa
  return eligible;
}
```

### UI Gösterimi

- **Premium Offer Screen**'de kampanya banner otomatik gösterilir
- Kalan gün sayısı canlı güncellenir
- 7 gün sonra banner kaybolur

---

## 📱 Kullanıcı Deneyimi

### Kampanya Bannerı

```
┌─────────────────────────────────────┐
│ 🎉  Hoş Geldin Kampanyası!         │
│                                     │
│ İlk X gün için aylık premium       │
│ sadece ₺24,99                      │
│                                     │
│ %50 İNDİRİM                    [7] │
│                                gün  │
└─────────────────────────────────────┘
```

### Satın Alma Akışı

1. Kullanıcı kampanya bannerını görür
2. "Premium" planını seçer
3. **Aylık** seçeneği seçili olmalı
4. Fiyat **₺24,99** olarak gösterilir
5. Satın alır
6. İlk ay sonunda **₺49,99** ile otomatik yenilenir

---

## ⚠️ Önemli Notlar

### 1. Fiyat Yenileme
- İlk ay: **₺24,99**
- 2. ay ve sonrası: **₺49,99** (normal fiyat)
- Google Play otomatik yeniler

### 2. İptal Politikası
- Kullanıcı istediği zaman iptal edebilir
- İptal ederse mevcut dönem sonuna kadar premium devam eder

### 3. Kampanya Sınırlaması
- Her kullanıcı **sadece bir kez** kampanyadan yararlanabilir
- 7 gün sonra kampanya otomatik devre dışı kalır

---

## 🔍 Test Etme

### Test Senaryoları

1. **Yeni Kullanıcı (0-7 gün)**
   - Kampanya banner görünmeli ✅
   - Kampanyalı fiyat gösterilmeli ✅
   - Satın alabilmeli ✅

2. **Eski Kullanıcı (8+ gün)**
   - Kampanya banner görünmemeli ✅
   - Normal fiyat gösterilmeli ✅

3. **Premium Kullanıcı**
   - Kampanya banner görünmemeli ✅

### Test Komutu

```bash
# Debug logları açık
flutter run

# Kampanya kontrolü için loglar:
# 🎉 Promotion Check:
#    Registration: 2025-01-20 12:00:00
#    Days since registration: 3
#    Eligible: true
```

---

## 📊 Analytics Takibi

### Önerilen Metrikler

1. **Kampanya Görüntülenme**: Kampanya bannerı kaç kere gösterildi
2. **Kampanya Tıklama**: Kampanyaya kaç kişi tıkladı
3. **Kampanya Conversion**: Kaç kişi kampanyadan satın aldı
4. **Retention Rate**: Kampanyadan satın alanların 2. ay yenileme oranı

---

## 🎁 İlave Öneriler

### Kampanya Genişletme Fikirleri

1. **Referral Kampanyası**: Arkadaşını getir, %30 indirim kazan
2. **Dönemsel Kampanyalar**: Yılbaşı, Ramazan, vb.
3. **Geri Kazanma**: Premium iptal eden kullanıcılara %40 indirim
4. **Yükseltme Kampanyası**: Premium → Premium Plus geçişte %20 indirim

---

## ✅ Kurulum Checklist

- [x] PremiumService'e kampanya mantığı eklendi
- [x] Premium Offer Screen'e banner eklendi
- [x] Eligibility kontrolü eklendi
- [x] Kalan gün sayacı eklendi
- [x] Banner tıklanabilir yapıldı
- [x] Play Store satın alma entegrasyonu yapıldı
- [x] purchasePromotion() metodu eklendi
- [x] Satın alma ve iptal kontrollerinde kampanyalı ürün eklendi
- [ ] Google Play Console'da ürün oluştur
- [ ] Fiyatları ayarla (₺24,99)
- [ ] Test et (sandbox)
- [ ] Production'a deploy et
- [ ] Analytics kurulumu yap

---

## 🚨 Önemli Hatırlatma

**Google Play Console'da ürün oluşturmadan önce:**
- Ürün ID'sinin kodda kullanılan ile **tamamen aynı** olduğundan emin olun
- Fiyatları **doğru** girdiğinizden emin olun
- Test ortamında **sandbox** hesabıyla test edin
- Production'a geçmeden önce **en az 2-3 test** yapın

---

## 📞 Destek

Kampanya kurulumu sırasında sorun yaşarsanız:
1. Debug loglarını kontrol edin
2. Google Play Console'da ürün durumunu kontrol edin
3. Test hesabıyla tekrar deneyin

---

**Son Güncelleme**: 29 Ekim 2025
**Versiyon**: 1.0.0
**Durum**: Kod tarafı hazır, Google Play Console kurulumu bekleniyor

