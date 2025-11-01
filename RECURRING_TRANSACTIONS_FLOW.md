# Abonelikler ve Otomatik İşlem Oluşturma - Sistem Akışı

## 📋 Genel Bakış

Sistem iki ana aşamada çalışır:
1. **Abonelik Oluşturma** (Transaction Form'dan)
2. **Otomatik İşlem Oluşturma** (Background Task ile)

---

## 🔄 1. Abonelik Oluşturma Akışı

### Adım 1: Kullanıcı Transaction Form'unu Açar
- Kullanıcı "Gider Ekle" butonuna tıklar
- `ExpenseFormScreen` açılır

### Adım 2: Abonelik Olarak İşaretleme
- Kullanıcı **2. Adım: Kategori Seçimi**'ne gelir
- `ExpenseCategorySelectorV2` altında bir **"Bu bir abonelik"** checkbox'ı görür
- Checkbox işaretlendiğinde (`_isSubscription = true`):
  - Form altında ek alanlar görünür:
    - **Abonelik Kategorisi** (`RecurringCategory`: subscription, utilities, etc.)
    - **Sıklık** (`RecurringFrequency`: weekly, monthly, yearly)
    - **Başlangıç Tarihi** (Transaction tarihi ile aynı - senkronize)
    - **Bitiş Tarihi** (Opsiyonel, checkbox ile açılır/kapanır)

### Adım 3: Form Kaydedilir
Kullanıcı "Kaydet" butonuna tıkladığında, `_saveExpense()` methodu çalışır:

```dart
if (_isSubscription) {
  // 1. RecurringTransaction modeli oluşturulur
  final subscription = RecurringTransaction(
    name: description,              // "Netflix", "Spotify" vs.
    category: _subscriptionCategory,
    amount: amount,                 // 49.99 TL
    accountId: sourceAccountId,     // Hangi karttan
    frequency: _subscriptionFrequency, // monthly, yearly vs.
    startDate: _subscriptionStartDate,
    endDate: _hasSubscriptionEndDate ? _subscriptionEndDate : null,
    isActive: true,
    lastExecutedDate: null,        // İlk çalıştırmada null
    nextExecutionDate: null,        // Provider hesaplayacak
  );
  
  // 2. Firestore'a kaydedilir
  final subscriptionId = await subscriptionProvider.createSubscription(subscription);
  
  // 3. İlk transaction oluşturulur (eğer start date bugün veya geçmişte ise)
  if (!todayOnly.isBefore(startDateOnly)) {
    // TransactionWithDetailsV2 oluşturulur
    final firstTransaction = TransactionWithDetailsV2(
      type: TransactionType.expense,
      amount: amount,
      description: '$description (Otomatik)',
      transactionDate: _subscriptionStartDate,
      categoryId: categoryId,
      sourceAccountId: sourceAccountId,
      isRecurring: true,            // ← ÖNEMLİ: Otomatik oluşturulduğunu belirtir
      notes: 'Otomatik oluşturuldu (Abonelik)',
    );
    
    // Normal transaction olarak eklenir (UnifiedTransactionService)
    transactionId = await UnifiedTransactionService.addTransaction(firstTransaction);
    
    // 4. Subscription güncellenir
    final nextExecutionDate = subscription.calculateNextExecutionDate();
    await subscriptionProvider.updateSubscription(
      subscriptionId,
      subscription.copyWith(
        lastExecutedDate: _subscriptionStartDate,
        nextExecutionDate: nextExecutionDate, // Bir sonraki ödeme tarihi
      ),
    );
  }
}
```

### Sonuç:
- ✅ Abonelik Firestore'da `recurring_transactions` collection'ında kayıtlı
- ✅ İlk transaction (eğer bugün veya geçmişte ise) normal transaction listesinde görünür
- ✅ `lastExecutedDate` ve `nextExecutionDate` güncellenmiş

---

## 🤖 2. Otomatik İşlem Oluşturma (Background Task)

### Adım 1: Workmanager Başlatılır
Uygulama açıldığında (`main.dart`):

```dart
// Workmanager initialize edilir
await Workmanager().initialize(callbackDispatcher, ...);

// Her gün çalışacak periodic task kaydedilir
await Workmanager().registerPeriodicTask(
  'execute_recurring_transactions',
  'execute_recurring_transactions',
  frequency: const Duration(hours: 24), // Her 24 saatte bir
);
```

### Adım 2: Background Task Çalışır (Her Gün)
Android/iOS sistemi, kayıtlı task'ı çalıştırır:
- **Çalışma Zamanı**: Her 24 saatte bir (tam zamanı sistem belirler)
- **Network Gerekliliği**: Hayır (offline da çalışabilir)

### Adım 3: `callbackDispatcher` Çağrılır
```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'execute_recurring_transactions') {
      // RecurringTransactionService çağrılır
      await RecurringTransactionService.executeRecurringTransactions();
    }
  });
}
```

### Adım 4: `executeRecurringTransactions()` Çalışır
```dart
static Future<void> executeRecurringTransactions() async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  // 1. Tüm aktif abonelikler getirilir
  final recurringTransactions = await getActiveRecurringTransactions();
  // Query: where('is_active', isEqualTo: true)
  
  // 2. Her abonelik için kontrol yapılır
  for (final recurring in recurringTransactions) {
    if (_shouldExecute(recurring, today)) {
      // 3. Transaction oluşturulur
      await _createTransactionFromRecurring(recurring, now);
      
      // 4. Abonelik güncellenir
      await updateLastExecutedDate(recurring.id, now);
    }
  }
  
  // 5. Bildirim gönderilir (eğer transaction oluşturulduysa)
  if (executedCount > 0) {
    await _sendBatchNotification(executedCount);
  }
}
```

### Adım 5: `_shouldExecute()` Kontrolü
Bir abonelik şu koşullarda çalıştırılır:

```dart
static bool _shouldExecute(RecurringTransaction recurring, DateTime today) {
  // ❌ Aktif değilse → Atla
  if (!recurring.isActive) return false;
  
  // ❌ End date geçmişse → Atla
  if (recurring.endDate != null && today.isAfter(recurring.endDate!)) {
    return false;
  }
  
  // ❌ Start date henüz gelmediyse → Atla
  if (today.isBefore(recurring.startDate)) {
    return false;
  }
  
  // ✅ İlk çalıştırma (lastExecutedDate == null)
  if (recurring.lastExecutedDate == null) {
    // Start date bugün veya geçmişteyse → Çalıştır
    return !today.isBefore(recurring.startDate);
  }
  
  // ✅ Sonraki çalıştırmalar (nextExecutionDate kontrolü)
  if (recurring.nextExecutionDate != null) {
    // Next execution date bugün veya geçmişteyse → Çalıştır
    return !today.isBefore(recurring.nextExecutionDate!);
  }
  
  return false;
}
```

### Adım 6: Transaction Oluşturulur
```dart
static Future<String> _createTransactionFromRecurring(...) async {
  // 1. Account bilgisi getirilir
  final account = await UnifiedAccountService.getAccountById(recurring.accountId);
  
  // 2. TransactionWithDetailsV2 oluşturulur
  final transaction = TransactionWithDetailsV2(
    type: TransactionType.expense,
    amount: recurring.amount,
    description: '${recurring.name} (Otomatik)',
    transactionDate: executionDate, // Bugünün tarihi
    categoryId: recurring.categoryId,
    sourceAccountId: recurring.accountId,
    isRecurring: true,              // ← ÖNEMLİ: Otomatik oluşturuldu
    notes: 'Otomatik oluşturuldu (Abonelik)',
    sourceAccountName: account.name, // UI için
    sourceAccountType: account.typeDisplayName,
  );
  
  // 3. UnifiedTransactionService ile eklenir
  final transactionId = await UnifiedTransactionService.addTransaction(transaction);
  
  // 4. Kart bakiyesi otomatik güncellenir (UnifiedTransactionService içinde)
  // - Expense ise: balance -= amount
  // - Income ise: balance += amount
  
  return transactionId;
}
```

### Adım 7: Abonelik Güncellenir
```dart
static Future<void> updateLastExecutedDate(String id, DateTime executedDate) async {
  final recurring = await getRecurringTransactionById(id);
  if (recurring == null) return;
  
  // Bir sonraki execution date hesaplanır
  final nextExecutionDate = recurring.calculateNextExecutionDate();
  
  // Firestore'da güncellenir
  await updateRecurringTransaction(id, recurring.copyWith(
    lastExecutedDate: executedDate,
    nextExecutionDate: nextExecutionDate,
    updatedAt: DateTime.now(),
  ));
}
```

**Örnek:**
- Abonelik: Netflix, Monthly, Start: 1 Ocak 2024
- İlk çalıştırma: 1 Ocak 2024 → Transaction oluşturulur
- `lastExecutedDate`: 1 Ocak 2024
- `nextExecutionDate`: 1 Şubat 2024 (calculateNextExecutionDate ile)
- İkinci çalıştırma: 1 Şubat 2024 → Transaction oluşturulur
- `lastExecutedDate`: 1 Şubat 2024
- `nextExecutionDate`: 1 Mart 2024

---

## 📱 3. Bildirim Sistemi

Transaction oluşturulduğunda, kullanıcıya bildirim gönderilir:

```dart
static Future<void> _sendBatchNotification(int count) async {
  final notificationService = NotificationService();
  
  if (count == 1) {
    await notificationService.showNotification(
      title: 'Abonelik Ödemesi Yapıldı',
      body: '1 abonelik otomatik olarak işlendi',
    );
  } else {
    await notificationService.showNotification(
      title: 'Abonelik Ödemeleri Yapıldı',
      body: '$count abonelik otomatik olarak işlendi',
    );
  }
}
```

---

## 🎯 4. Örnek Senaryo

### Senaryo: Netflix Aboneliği

**Oluşturulma:**
- Kullanıcı: "Gider Ekle" → Kategori: "Eğlence" → "Bu bir abonelik" ✓
- Abonelik Bilgileri:
  - Ad: "Netflix"
  - Miktar: 99.99 TL
  - Sıklık: Monthly
  - Başlangıç: 15 Ocak 2024
  - Bitiş: Yok (sınırsız)
- Kaydet

**Sistem:**
1. `RecurringTransaction` Firestore'a kaydedilir
2. 15 Ocak bugün veya geçmişte olduğu için ilk transaction oluşturulur:
   - Transaction: 99.99 TL, "Netflix (Otomatik)", 15 Ocak 2024
   - Kart bakiyesi: 1000 TL → 900.01 TL
3. `lastExecutedDate`: 15 Ocak 2024
4. `nextExecutionDate`: 15 Şubat 2024 (calculateNextExecutionDate)

**Otomatik Çalıştırma:**
- 15 Şubat 2024'te (veya sonrasında) background task çalışır
- `_shouldExecute()` kontrol eder:
  - `isActive`: true ✓
  - `endDate`: null ✓
  - `nextExecutionDate`: 15 Şubat 2024 → Bugün: 15 Şubat 2024 ✓
  - **Çalıştır!**
- Yeni transaction oluşturulur:
  - Transaction: 99.99 TL, "Netflix (Otomatik)", 15 Şubat 2024
  - Kart bakiyesi: 900.01 TL → 800.02 TL
- `lastExecutedDate`: 15 Şubat 2024
- `nextExecutionDate`: 15 Mart 2024
- Bildirim: "Abonelik Ödemesi Yapıldı"

---

## 🔍 5. Transaction'ların Görünürlüğü

Otomatik oluşturulan transaction'lar:
- ✅ **Normal transaction listesinde görünür** (`RecentTransactionsWidget`, `TransactionListScreen`)
- ✅ **Filtrelerde görünür** (tarih, kategori, miktar)
- ✅ **İstatistiklerde dahil** (aylık toplam, kategori analizi)
- ✅ **Ayrı bir işaret var**: `isRecurring: true`
  - UI'da özel bir badge/ikon gösterilebilir (şu an gösterilmiyor)
  - Description'da "(Otomatik)" yazısı var

---

## 🧪 6. Test Etme

### Debug Mode (Otomatik Test)
Uygulama açıldığında (sadece debug mode'da):
- 5 saniye sonra bir one-off task çalışır
- `executeRecurringTransactions()` çağrılır

### Manuel Test (Profile Screen)
1. Profile Screen → "Debug Tools" bölümü
2. **"Test Recurring Transactions"** butonu:
   - Direkt olarak `RecurringTransactionService.executeRecurringTransactions()` çağrılır
   - Hemen sonuç gösterilir (snackbar)
3. **"Schedule Test Task"** butonu:
   - Workmanager'a bir one-off task kaydedilir
   - 5 saniye sonra background'da çalışır

---

## 📊 7. Firestore Yapısı

### Collection: `recurring_transactions`
```json
{
  "id": "abc123",
  "user_id": "user123",
  "name": "Netflix",
  "category": "subscription",
  "category_id": "cat123",
  "amount": 99.99,
  "account_id": "card123",
  "frequency": "monthly",
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": null,
  "is_active": true,
  "last_executed_date": "2024-01-15T00:00:00Z",
  "next_execution_date": "2024-02-15T00:00:00Z",
  "created_at": "2024-01-15T00:00:00Z",
  "updated_at": "2024-01-15T00:00:00Z"
}
```

### Collection: `transactions` (normal transaction'lar)
Otomatik oluşturulan transaction'lar:
```json
{
  "id": "txn123",
  "user_id": "user123",
  "type": "expense",
  "amount": 99.99,
  "description": "Netflix (Otomatik)",
  "transaction_date": "2024-01-15T00:00:00Z",
  "category_id": "cat123",
  "source_account_id": "card123",
  "is_recurring": true,
  "notes": "Otomatik oluşturuldu (Abonelik)",
  "is_paid": true,
  "created_at": "2024-01-15T00:00:00Z"
}
```

---

## ✅ Özet

1. **Kullanıcı abonelik oluşturur** → Transaction form'dan
2. **İlk transaction** (eğer bugün veya geçmişte ise) hemen oluşturulur
3. **Background task** her gün çalışır
4. **Vadesi gelen abonelikler** için transaction oluşturulur
5. **Kart bakiyesi** otomatik güncellenir
6. **Bildirim** gönderilir
7. **Transaction'lar** normal listede görünür

---

## 🐛 Sorun Giderme

### Transaction oluşturulmuyor
- ✅ `is_active: true` mı?
- ✅ `end_date` geçmiş mi?
- ✅ `next_execution_date` bugün veya geçmişte mi?
- ✅ Background task çalışıyor mu? (Debug Tools ile test et)

### Yanlış tarihte transaction oluşturuluyor
- ✅ `calculateNextExecutionDate()` doğru çalışıyor mu?
- ✅ `_shouldExecute()` logic'i doğru mu?

### Bildirim gelmiyor
- ✅ Notification permission verildi mi?
- ✅ `NotificationService` çalışıyor mu?

