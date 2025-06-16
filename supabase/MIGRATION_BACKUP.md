# Qanta Veritabanı Migration Yedeği
**Oluşturulma:** 2025-06-16  
**Amaç:** Veri kaybını önlemek için tüm uygulanan migration'ların yedeği

## Uygulanan Migration'lar (Prodüksiyon)

### Temel Şema ve Fonksiyonlar
- `20250101000000_qanta_v2_schema.sql` - Ana veritabanı şeması (tablolar, kısıtlamalar)
- `20250101000001_qanta_v2_functions.sql` - Temel veritabanı fonksiyonları (CRUD işlemleri)
- `20250101000002_fix_auth_integration.sql` - Kimlik doğrulama entegrasyonu düzeltmeleri
- `20250101000003_fix_installment_constraints.sql` - Taksit tablosu kısıtlamaları

### Taksit Sistemi Düzeltmeleri (2025-06-16)
- `20250116000000_fix_monthly_amount_constraint.sql` - Aylık tutar kısıtlaması düzeltmesi
- `20250116000001_fix_installment_transaction_link.sql` - İşlem-taksit bağlantısı
- `20250116000002_fix_installment_deletion.sql` - Taksit silme mantığı
- `20250616155621_fix_installment_deletion_v2.sql` - Gelişmiş silme ve doğru iade
- `20250616160343_fix_monthly_amount_precision.sql` - Ondalık hassasiyet işleme
- `20250616160622_fix_installment_refund_calculation.sql` - Doğru iade hesaplaması
- `20250616161721_fix_installment_credit_limit.sql` - Kredi kartı limit düşme düzeltmesi
- `20250616162020_fix_installment_refund_credit_card.sql` - Kredi kartı iade mantığı

### Veri Yönetimi (2025-06-16)
- `20250616170856_remove_test_data.sql` - Test verilerini temizleme

### Boş/Geri Alınan Migration'lar
- `20250616134058_revert_installment_first_payment_date.sql` - (Boş - geri alındı)

## ⚠️ KRİTİK: BU MIGRATION'LARI SİLMEYİN
Bu migration'lar prodüksiyon veritabanına uygulandı. Silmek şunlara neden olur:
- Veritabanı şema uyumsuzluğu
- Veri bozulması
- Uygulama çökmeleri

## Güvenli Geliştirme Pratikleri
1. Değişiklikler için her zaman YENİ migration oluşturun
2. Mevcut migration dosyalarını asla değiştirmeyin
3. Migration'ları önce yerel ortamda test edin
4. `supabase db reset`'i sadece yerel geliştirme için kullanın
5. Bu yedek dosyasını güncel tutun

## Kurtarma Talimatları
Migration'lar yanlışlıkla silinirse:
1. Bu yedekten geri yükleyin
2. Migration durumunu kontrol edin: `supabase migration list`
3. Eksik migration'ları uygulayın: `supabase db push`
4. Veritabanı bütünlüğünü doğrulayın

## Son Güncelleme
- Tarih: 2025-06-16
- Uygulanan Migration'lar: Toplam 14
- Prodüksiyon Durumu: ✅ Tümü başarıyla uygulandı 