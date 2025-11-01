# Recurring Transactions System - Testing & Verification Guide

## Sistem Mimarisi

### 1. WorkManager Task
- **Task Name**: `execute_recurring_transactions`
- **Frequency**: Her 24 saatte bir (günlük)
- **Constraints**: Network gerekmez, offline çalışabilir
- **Initialization**: `main.dart` içinde uygulama başlatılırken kayıt edilir

### 2. RecurringTransactionService
- **Konum**: `lib/core/services/recurring_transaction_service.dart`
- **Temel Fonksiyonlar**:
  - `executeRecurringTransactions()`: Aktif abonelikleri kontrol eder ve gerekirse transaction oluşturur
  - `_shouldExecute()`: Bir aboneliğin şu anda çalıştırılması gerekip gerekmediğini kontrol eder
  - `_createTransactionFromRecurring()`: Recurring transaction'dan gerçek bir transaction oluşturur

### 3. Execution Logic
1. Tüm aktif recurring transaction'lar getirilir
2. Her biri için `_shouldExecute()` kontrolü yapılır:
   - Aktif mi?
   - End date geçmiş mi?
   - Start date gelmiş mi?
   - Last executed date var mı? Yoksa ilk çalıştırma mı?
   - Next execution date bugün veya geçmiş mi?
3. Gerekli olanlar için transaction oluşturulur
4. `lastExecutedDate` ve `nextExecutionDate` güncellenir

## Test Araçları

### Profile Screen - Debug Tools (Sadece Debug Mode)
Profile ekranında **🧪 Debug Tools** bölümünde:

1. **Test Recurring Transactions**
   - Manuel olarak execution logic'i çalıştırır
   - Sonuçları anında gösterir
   - WorkManager'a bağlı değil, direkt service'i çağırır

2. **Recurring Transactions Debug**
   - Detaylı sistem durumu gösterir:
     - Summary: Toplam, aktif, pasif, bugün due, bu hafta, bu ay due olanlar
     - Test Execution: Hangi aboneliklerin çalıştırılması gerektiğini gösterir
     - WorkManager Status: Task'ın kayıtlı olup olmadığını gösterir
     - Details: Her abonelik için detaylı durum (neden çalıştırılıyor/çalıştırılmıyor)
   - "Execute Now" butonu ile manuel execution yapılabilir

3. **Schedule Test Task**
   - WorkManager'a 5 saniye sonra çalışacak bir one-off task kaydeder
   - Background task'ın gerçekten çalışıp çalışmadığını test eder
   - Loglarda sonuçları görebilirsiniz

## Nasıl Test Edilir?

### 1. Manuel Test (Immediate)
```
Profile Screen → Debug Tools → Test Recurring Transactions
```
- Anında çalışır
- Sonuçları hemen gösterir
- Transaction listesinde yeni transaction'ları kontrol edin

### 2. Background Task Test
```
Profile Screen → Debug Tools → Schedule Test Task
```
- 5 saniye sonra WorkManager task'ı çalışır
- Logcat'te şunları göreceksiniz:
  ```
  🔄 Starting recurring transaction execution...
  📊 Found X active recurring transactions
  ✅ Executing recurring transaction: [Name]
  ✅ Recurring transaction task completed
  ```

### 3. Detaylı Debug
```
Profile Screen → Debug Tools → Recurring Transactions Debug
```
- Sistem durumunu gösterir
- Her abonelik için:
  - Neden çalıştırılacak/çalıştırılmayacak
  - Next execution date
  - Last executed date
  - Status

### 4. WorkManager Kontrolü

#### Android
- Android Studio → View → Tool Windows → App Inspection
- Logcat'te `WorkManager` tag'i ile filtreleyin
- Şunları görmelisiniz:
  ```
  ✅ Workmanager initialized with recurring transaction task
  ```

#### iOS
- Xcode Console'da logları kontrol edin
- WorkManager iOS'ta daha kısıtlı çalışır (background execution limits)

## Kontrol Listesi

### ✅ WorkManager Kayıtlı mı?
1. Uygulama başlatıldığında `main.dart`'ta kayıt yapılır
2. Logcat'te "✅ Workmanager initialized" mesajını görmelisiniz
3. Profile → Debug Tools → Recurring Transactions Debug
   - WorkManager Status bölümünde `Task Registered: true` olmalı

### ✅ Execution Logic Doğru mu?
1. Debug Tools → Recurring Transactions Debug
2. Test Execution bölümünde:
   - Due Today sayısı doğru mu?
   - Her abonelik için "reason" mantıklı mı?
3. Details'te her abonelik için neden çalıştırılacak/çalıştırılmayacak açıklanıyor

### ✅ Transaction Oluşturuluyor mu?
1. Test'i çalıştırın
2. Transaction listesine gidin
3. Yeni oluşturulan transaction'ları kontrol edin:
   - `isRecurring: true` olmalı
   - `notes: 'AUTO_CREATED_SUBSCRIPTION'` olmalı
   - `isPaid: true` olmalı
   - `description`: Abonelik adı olmalı

### ✅ Last Executed Date Güncelleniyor mu?
1. Debug Tools → Recurring Transactions Debug
2. Details'te abonelikleri kontrol edin
3. Test çalıştıktan sonra:
   - `lastExecutedDate` bugünün tarihi olmalı
   - `nextExecutionDate` bir sonraki çalışma tarihi olmalı

### ✅ Next Execution Date Hesaplanıyor mu?
- Frequency'ye göre:
  - **Weekly**: 7 gün sonra
  - **Monthly**: Bir ay sonra (aynı gün)
  - **Yearly**: Bir yıl sonra (aynı gün)

## Yaygın Sorunlar ve Çözümler

### 1. WorkManager Task Çalışmıyor
**Nedenler:**
- Android battery optimization
- Doze mode aktif
- Background restrictions

**Çözümler:**
- Android Settings → Apps → Qanta → Battery → Unrestricted
- Debug mode'da test task ile kontrol edin
- Logcat'te hataları kontrol edin

### 2. Abonelikler Çalıştırılmıyor
**Kontrol Edilecekler:**
- `isActive: true` mi?
- `endDate` geçmiş mi?
- `startDate` gelmiş mi?
- `nextExecutionDate` bugün veya geçmiş mi?

**Debug:**
- Recurring Transactions Debug → Details'te her abonelik için "reason" kontrol edin

### 3. Transaction Oluşturulmuyor
**Kontrol Edilecekler:**
- Account mevcut mu? (`accountId` doğru mu?)
- Firebase bağlantısı aktif mi?
- UnifiedTransactionService çalışıyor mu?

**Loglar:**
```
❌ Error executing recurring transaction [Name]: [Error]
❌ Error creating transaction from recurring: [Error]
```

### 4. Next Execution Date Yanlış
**Kontrol:**
- `calculateNextExecutionDate()` method'unu kontrol edin
- Frequency doğru mu?
- Last executed date güncellendi mi?

## Production Checklist

- [ ] WorkManager task production'da kayıtlı (debug mode'da test task'ı çıkarılmış)
- [ ] Battery optimization uyarısı kullanıcıya gösteriliyor mu?
- [ ] Error handling ve logging yeterli
- [ ] Notification gönderiliyor mu?
- [ ] Transaction'lar doğru account'tan çıkarılıyor mu?
- [ ] Last executed date doğru güncelleniyor mu?
- [ ] Next execution date doğru hesaplanıyor mu?

## Debug Log Formatı

```
🔄 Starting recurring transaction execution...
📊 Found X active recurring transactions
✅ Executing recurring transaction: [Name]
   ✅ [Name]: Next execution date reached ([Date])
   ⏭️ [Name]: Not active, skipping
   ⏭️ [Name]: End date passed ([Date]), skipping
   ⏭️ [Name]: Next execution date not reached ([Date])
✅ Created transaction [ID] for subscription [Name]
✅ Recurring transaction execution completed: X executed, Y errors
```

## Notlar

- WorkManager task minimum 15 dakikada bir çalışabilir (Android limitation)
- Production'da 24 saatlik interval kullanılıyor
- Debug mode'da test için daha kısa interval kullanılabilir (ama minimum 15 dakika)
- Background execution iOS'ta daha kısıtlıdır
- Network gerektirmez, offline çalışabilir

