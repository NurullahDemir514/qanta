# Qanta Veritabanı Geliştirme Kuralları
**🚨 KRİTİK: Herhangi bir veritabanı değişikliği yapmadan önce okuyun**

## ❌ ASLA BUNLARI YAPMAYIN
1. **Migration dosyalarını silmeyin** - Prodüksiyona uygulandılar
2. **Mevcut migration'ları değiştirmeyin** - Şema uyumsuzluğuna neden olur
3. **Prodüksiyonda `supabase db reset` çalıştırmayın** - Tüm veriyi yok eder
4. **Test edilmemiş migration'ları push'lamayın** - Önce yerel ortamda test edin
5. **Migration hatalarını görmezden gelmeyin** - Hemen düzeltin

## ✅ GÜVENLİ PRATİKLER

### Yeni Özellikler İçin
```bash
# 1. Yeni migration oluşturun
supabase migration new ozellik_adi

# 2. Yeni dosyaya SQL değişikliklerini yazın
# 3. Yerel ortamda test edin (Docker varsa)
supabase db reset
supabase db push

# 4. Test ettikten sonra prodüksiyona push'layın
supabase db push
```

### Hata Düzeltmeleri İçin
```bash
# 1. Yeni migration oluşturun (mevcut olanı değiştirmeyin)
supabase migration new hata_duzeltmesi_adi

# 2. Düzeltici SQL yazın
# 3. Kapsamlı test yapın
# 4. Prodüksiyona push'layın
```

### Şema Değişiklikleri İçin
```bash
# 1. Her zaman yeni migration oluşturun
supabase migration new tablo_degisikligi_adi

# 2. Güvenli SQL pratiklerini kullanın:
#    - Sütunları DEFAULT değerlerle ekleyin
#    - Silme işlemleri için IF EXISTS kullanın
#    - Kısıtlamaları dikkatli ekleyin
```

## 🔒 PRODÜKSİYON GÜVENLİĞİ

### Herhangi Bir Veritabanı Değişikliğinden Önce
- [ ] Yedek dokümantasyonu oluşturun
- [ ] Migration'ı yerel ortamda test edin
- [ ] SQL'i yıkıcı işlemler için gözden geçirin
- [ ] Geri alma planının olduğundan emin olun
- [ ] Önce kod değişikliklerini commit edin

### Acil Durum Geri Alma
Bir şeyler ters giderse:
1. **PANİK YAPMAYIN**
2. `supabase/MIGRATION_BACKUP.md` dosyasını kontrol edin
3. Eksik migration'ları yedekten geri yükleyin
4. Veri bozulması şüphesi varsa ekiple iletişime geçin

## 📝 MIGRATION İSİMLENDİRME KURALI
```
YYYYMMDDHHMMSS_aciklayici_isim.sql

Örnekler:
20250616163000_kullanici_tercihleri_ekle.sql
20250616163100_islem_kisitlamasi_duzelt.sql
20250616163200_taksit_mantigi_guncelle.sql
```

## 🧪 YEREL GELİŞTİRME
```bash
# Güvenli yerel sıfırlama (sadece yerel Docker'ı etkiler)
supabase stop
supabase start
supabase db reset

# Bu işlem:
# - Yerel veritabanını yok eder
# - Migration'lardan yeniden oluşturur
# - Geliştirme için güvenlidir
```

## 📞 ACİL DURUM İLETİŞİM
- Veritabanı sorunları: GitHub issues'ı kontrol edin
- Migration problemleri: Yedekten geri yükleyin
- Veri bozulması: **TÜM İŞLEMLERİ DURDURUN**

## Son Güncelleme: 2025-06-16 