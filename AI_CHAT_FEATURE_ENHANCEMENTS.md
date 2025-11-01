# AI Chat Özellik Geliştirmeleri

## 📋 Mevcut Özellikler

✅ **Şu an desteklenen özellikler:**
- Transaction ekleme (income/expense)
- Stock trading (buy/sell)
- Budget yönetimi (create/update/delete)
- Category yönetimi (create)
- Görüntü/PDF analizi ve transaction extraction
- Bulk transaction oluşturma
- Bulk delete
- Theme değiştirme
- Quick replies sistemi
- Smart financial analysis ve recommendations
- Conversation history

---

## 🚀 Eklenebilecek Özellikler

### 1. **Recurring Transactions (Abonelikler) Yönetimi** ⭐⭐⭐

**Öncelik**: Yüksek  
**Süre**: 2-3 gün  
**ROI**: Yüksek (%40 engagement artışı)

#### Özellikler:
- ✅ Abonelik oluşturma: "Create monthly Netflix subscription for $15"
- ✅ Abonelik listeleme: "Show my subscriptions"
- ✅ Abonelik güncelleme: "Change Netflix to $20" veya "Update Spotify frequency to yearly"
- ✅ Abonelik silme: "Cancel my Netflix subscription"
- ✅ Abonelik sorguları: "How much do I spend on subscriptions monthly?"

#### READY Format Örnekleri:
```json
// Create subscription
READY: {
  "type": "subscription_create",
  "name": "Netflix",
  "amount": 15,
  "category": "Subscription",
  "account": "Chase Credit Card",
  "frequency": "monthly",
  "startDate": "2025-01-15"
}

// Update subscription
READY: {
  "type": "subscription_update",
  "subscriptionId": "abc123",
  "amount": 20
}

// Delete subscription
READY: {
  "type": "subscription_delete",
  "subscriptionId": "abc123"
}

// List subscriptions
READY: {
  "type": "subscription_list",
  "filters": {
    "category": "Subscription",
    "frequency": "monthly"
  }
}
```

#### Implementation Plan:

**1. Backend (functions/handlers/chatWithAI.js):**
```javascript
// System prompt'a ekle:
12. Subscription Management:
   - "Create monthly Netflix subscription for $15" → READY: {"type": "subscription_create", "name": "Netflix", "amount": 15, "category": "Subscription", "account": "Chase", "frequency": "monthly"}
   - "Update Netflix to $20" → READY: {"type": "subscription_update", "name": "Netflix", "amount": 20}
   - "Cancel Netflix subscription" → READY: {"type": "subscription_delete", "name": "Netflix"}
   - "Show my subscriptions" → List all active subscriptions with details
   - frequency: "weekly", "monthly", "quarterly", "yearly"
   - category: "Subscription", "Utilities", "Insurance", "Rent", "Loan"
   - REQUIRED: name, amount, account, frequency
   - OPTIONAL: category (default: "Subscription"), startDate (default: today), endDate
```

**2. Frontend (lib/modules/transactions/widgets/quick_add_chat_fab.dart):**
```dart
// Transaction data handling'e ekle:
else if (dataType == 'subscription_create') {
  await _handleSubscriptionCreate(safeTransactionData);
} else if (dataType == 'subscription_update') {
  await _handleSubscriptionUpdate(safeTransactionData);
} else if (dataType == 'subscription_delete') {
  await _handleSubscriptionDelete(safeTransactionData);
} else if (dataType == 'subscription_list') {
  await _handleSubscriptionList(safeTransactionData);
}

// Handler metodları:
Future<void> _handleSubscriptionCreate(Map<String, dynamic> data) async {
  final provider = context.read<UnifiedProviderV2>();
  final recurringService = RecurringTransactionService();
  
  // Gerekli alanları parse et
  final name = data['name'] as String;
  final amount = (data['amount'] as num).toDouble();
  final accountName = data['account'] as String;
  final frequency = _parseFrequency(data['frequency'] as String);
  final category = _parseRecurringCategory(data['category'] as String? ?? 'Subscription');
  
  // Account'u bul
  final account = provider.accounts.firstWhere(
    (a) => _getLocalizedAccountName(a, context) == accountName,
  );
  
  // Category'yi bul veya oluştur
  String? categoryId;
  // ... category logic
  
  // RecurringTransaction oluştur
  final subscription = RecurringTransaction(
    name: name,
    amount: amount,
    accountId: account.id,
    categoryId: categoryId,
    frequency: frequency,
    category: category,
    startDate: _parseDate(data['startDate']) ?? DateTime.now(),
    endDate: _parseDate(data['endDate']),
    isActive: true,
  );
  
  await recurringService.createSubscription(subscription);
  
  // İlk transaction'ı oluştur (eğer startDate bugün veya geçmişte ise)
  // ...
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscription created successfully!')),
    );
  }
}
```

**3. Service Entegrasyonu:**
- `RecurringTransactionService` mevcut mu kontrol et
- Eğer yoksa, `lib/core/services/recurring_transaction_service.dart` oluştur
- Firebase collection: `recurring_transactions`

---

### 2. **Savings Goals (Birikimler) Yönetimi** ⭐⭐⭐

**Öncelik**: Yüksek  
**Süre**: 2-3 gün  
**ROI**: Yüksek (%35 engagement artışı)

#### Özellikler:
- ✅ Goal oluşturma: "Create vacation savings goal for $5000 by June 2025"
- ✅ Goal güncelleme: "Update vacation goal target to $6000"
- ✅ Goal silme: "Delete vacation goal"
- ✅ Para ekleme: "Add $500 to vacation goal"
- ✅ Para çekme: "Withdraw $200 from vacation goal"
- ✅ Goal sorguları: "How much progress on my vacation goal?" veya "Show all my savings goals"

#### READY Format Örnekleri:
```json
// Create goal
READY: {
  "type": "savings_goal_create",
  "name": "Vacation",
  "targetAmount": 5000,
  "targetDate": "2025-06-01",
  "emoji": "✈️",
  "category": "vacation"
}

// Update goal
READY: {
  "type": "savings_goal_update",
  "goalId": "abc123",
  "targetAmount": 6000
}

// Deposit to goal
READY: {
  "type": "savings_goal_deposit",
  "goalId": "abc123",
  "amount": 500,
  "account": "Cash Wallet"
}

// Withdraw from goal
READY: {
  "type": "savings_goal_withdraw",
  "goalId": "abc123",
  "amount": 200,
  "account": "Cash Wallet"
}

// Delete goal
READY: {
  "type": "savings_goal_delete",
  "goalId": "abc123"
}
```

#### Implementation Plan:

**1. Backend (functions/handlers/chatWithAI.js):**
```javascript
// System prompt'a ekle:
13. Savings Goals Management:
   - "Create vacation savings goal for $5000 by June 2025" → READY: {"type": "savings_goal_create", "name": "Vacation", "targetAmount": 5000, "targetDate": "2025-06-01", "emoji": "✈️", "category": "vacation"}
   - "Add $500 to vacation goal" → READY: {"type": "savings_goal_deposit", "name": "Vacation", "amount": 500, "account": "Cash Wallet"}
   - "Withdraw $200 from vacation goal" → READY: {"type": "savings_goal_withdraw", "name": "Vacation", "amount": 200, "account": "Cash Wallet"}
   - "Update vacation goal to $6000" → READY: {"type": "savings_goal_update", "name": "Vacation", "targetAmount": 6000}
   - "Show my savings goals" → List all goals with progress
   - category: "emergency", "vacation", "shopping", "education", "home", "other"
   - emoji: Optional, user can specify or AI can suggest based on category
```

**2. Frontend (lib/modules/transactions/widgets/quick_add_chat_fab.dart):**
```dart
// Transaction data handling'e ekle:
else if (dataType == 'savings_goal_create') {
  await _handleSavingsGoalCreate(safeTransactionData);
} else if (dataType == 'savings_goal_update') {
  await _handleSavingsGoalUpdate(safeTransactionData);
} else if (dataType == 'savings_goal_deposit') {
  await _handleSavingsGoalDeposit(safeTransactionData);
} else if (dataType == 'savings_goal_withdraw') {
  await _handleSavingsGoalWithdraw(safeTransactionData);
} else if (dataType == 'savings_goal_delete') {
  await _handleSavingsGoalDelete(safeTransactionData);
}

// Handler metodları:
Future<void> _handleSavingsGoalCreate(Map<String, dynamic> data) async {
  final savingsProvider = context.read<SavingsProvider>();
  
  final name = data['name'] as String;
  final targetAmount = (data['targetAmount'] as num).toDouble();
  final targetDate = _parseDate(data['targetDate']);
  final emoji = data['emoji'] as String? ?? '💰';
  final category = _parseSavingsCategory(data['category'] as String? ?? 'other');
  
  final goal = SavingsGoal(
    name: name,
    targetAmount: targetAmount,
    currentAmount: 0,
    targetDate: targetDate,
    emoji: emoji,
    category: category,
    createdAt: DateTime.now(),
  );
  
  await savingsProvider.createGoal(goal);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Savings goal created successfully!')),
    );
  }
}
```

**3. Service Entegrasyonu:**
- `SavingsProvider` ve `SavingsService` mevcut
- Firebase collection: `savings_goals`

---

### 3. **Card (Account) Yönetimi** ⭐⭐

**Öncelik**: Orta  
**Süre**: 1-2 gün  
**ROI**: Orta (%20 engagement artışı)

#### Özellikler:
- ✅ Card sorguları: "Show my credit cards" veya "What's my Chase balance?"
- ✅ Card ekleme: "Add new credit card named Chase"
- ✅ Card güncelleme: "Update Chase credit limit to $10000"
- ✅ Card silme: "Delete Wells Fargo card"

#### READY Format Örnekleri:
```json
// List cards
READY: {
  "type": "card_list",
  "filter": "credit" // veya "debit", "all"
}

// Add card
READY: {
  "type": "card_create",
  "name": "Chase",
  "type": "credit",
  "bankName": "Chase",
  "creditLimit": 10000,
  "balance": 0
}

// Update card
READY: {
  "type": "card_update",
  "cardId": "abc123",
  "creditLimit": 15000
}
```

#### Implementation Plan:

**1. Backend:**
```javascript
// System prompt'a ekle:
14. Card/Account Management:
   - "Show my credit cards" → List all credit cards with balances and limits
   - "What's my Chase balance?" → Show specific card balance
   - "Add new credit card named Chase with $10000 limit" → READY: {"type": "card_create", "name": "Chase", "type": "credit", "creditLimit": 10000}
   - "Update Chase credit limit to $15000" → READY: {"type": "card_update", "name": "Chase", "creditLimit": 15000}
```

**2. Frontend:**
```dart
else if (dataType == 'card_list') {
  await _handleCardList(safeTransactionData);
} else if (dataType == 'card_create') {
  await _handleCardCreate(safeTransactionData);
} else if (dataType == 'card_update') {
  await _handleCardUpdate(safeTransactionData);
}
```

---

### 4. **Gelişmiş Analiz Özellikleri** ⭐⭐

**Öncelik**: Orta  
**Süre**: 1-2 gün  
**ROI**: Orta (%25 engagement artışı)

#### Özellikler:
- ✅ Recurring pattern detection: "What are my recurring expenses?"
- ✅ Savings suggestions: "How can I save more money?"
- ✅ Financial forecasting: "How much will I spend this month?"
- ✅ Category comparison: "Compare my restaurant spending this month vs last month"
- ✅ Account balance summary: "Show me all account balances"

#### Implementation:
- Bunlar zaten AI analysis'te var ama prompt'u genişlet
- READY format'a gerek yok, sadece analiz döndür

---

### 5. **Export ve Rapor Özellikleri** ⭐

**Öncelik**: Düşük  
**Süre**: 1 gün  
**ROI**: Düşük (%10 engagement artışı)

#### Özellikler:
- ✅ "Export my transactions as CSV"
- ✅ "Generate monthly report"
- ✅ "Show spending report for last 3 months"

#### Implementation:
- PDF/CSV export servisi ekle
- READY format: `{"type": "export", "format": "csv", "dateRange": "last_month"}`

---

## 📝 Implementation Checklist

### Phase 1: Recurring Transactions (Öncelik: Yüksek)
- [ ] Backend: System prompt'a subscription yönetimi ekle
- [ ] Backend: READY format parsing ekle
- [ ] Frontend: Subscription handler metodları ekle
- [ ] Frontend: RecurringTransactionService entegrasyonu
- [ ] Test: "Create monthly Netflix subscription for $15"
- [ ] Test: "Show my subscriptions"
- [ ] Test: "Cancel Netflix subscription"
- [ ] Localization: Subscription strings ekle

### Phase 2: Savings Goals (Öncelik: Yüksek)
- [ ] Backend: System prompt'a savings goals ekle
- [ ] Backend: READY format parsing ekle
- [ ] Frontend: Savings goal handler metodları ekle
- [ ] Frontend: SavingsProvider entegrasyonu
- [ ] Test: "Create vacation goal for $5000"
- [ ] Test: "Add $500 to vacation goal"
- [ ] Test: "Show my savings goals"
- [ ] Localization: Savings goal strings ekle

### Phase 3: Card Management (Öncelik: Orta)
- [ ] Backend: System prompt'a card management ekle
- [ ] Frontend: Card handler metodları ekle
- [ ] Frontend: UnifiedAccountService entegrasyonu
- [ ] Test: "Show my credit cards"
- [ ] Test: "Add new Chase credit card"

### Phase 4: Gelişmiş Analiz (Öncelik: Orta)
- [ ] Backend: Prompt'u genişlet (recurring patterns, forecasting)
- [ ] Test: "What are my recurring expenses?"
- [ ] Test: "How much will I spend this month?"

---

## 🔧 Teknik Detaylar

### Backend Değişiklikler

**functions/handlers/chatWithAI.js:**
1. `buildSystemPrompt()` fonksiyonuna yeni özellikleri ekle
2. READY format parsing'e yeni type'ları ekle:
   - `subscription_create`
   - `subscription_update`
   - `subscription_delete`
   - `savings_goal_create`
   - `savings_goal_update`
   - `savings_goal_deposit`
   - `savings_goal_withdraw`
   - `savings_goal_delete`
   - `card_list`
   - `card_create`
   - `card_update`

### Frontend Değişiklikler

**lib/modules/transactions/widgets/quick_add_chat_fab.dart:**
1. `_sendMessage()` metodunda transaction data handling'i genişlet
2. Yeni handler metodları ekle:
   - `_handleSubscriptionCreate()`
   - `_handleSubscriptionUpdate()`
   - `_handleSubscriptionDelete()`
   - `_handleSavingsGoalCreate()`
   - `_handleSavingsGoalDeposit()`
   - `_handleSavingsGoalWithdraw()`
   - vb.

**lib/core/services/ai/firebase_ai_service.dart:**
1. `chatWithAI()` metoduna yeni parametreler ekle:
   - `recurringTransactions` (subscription list)
   - `savingsGoals` (goals list)

### Service Entegrasyonları

**RecurringTransactionService:**
- `createSubscription()` - Yeni abonelik oluştur
- `updateSubscription()` - Abonelik güncelle
- `deleteSubscription()` - Abonelik sil
- `getSubscriptions()` - Tüm abonelikleri getir

**SavingsProvider:**
- `createGoal()` - Yeni goal oluştur
- `updateGoal()` - Goal güncelle
- `depositToGoal()` - Goal'a para ekle
- `withdrawFromGoal()` - Goal'dan para çek
- `deleteGoal()` - Goal sil

**UnifiedAccountService:**
- `createAccount()` - Yeni card oluştur
- `updateAccount()` - Card güncelle
- `getAccounts()` - Tüm card'ları getir (zaten var)

---

## 📊 Beklenen Sonuçlar

### Engagement Artışı:
- Recurring Transactions: %40
- Savings Goals: %35
- Card Management: %20
- **Toplam**: %95 engagement artışı

### Kullanıcı Memnuniyeti:
- Daha hızlı işlem yapma (konuşma tabanlı)
- Daha az ekran değişimi
- Daha doğal etkileşim

### Premium Conversion:
- Yeni özellikler premium gated olabilir
- Premium kullanıcılara daha fazla AI limit

---

## 🎯 Öncelik Sırası

1. **Phase 1: Recurring Transactions** (2-3 gün) - En yüksek ROI
2. **Phase 2: Savings Goals** (2-3 gün) - Yüksek engagement
3. **Phase 3: Card Management** (1-2 gün) - Orta öncelik
4. **Phase 4: Gelişmiş Analiz** (1-2 gün) - Mevcut özelliği genişlet

---

## 📚 Kaynaklar

- `RECURRING_TRANSACTIONS_FLOW.md` - Recurring transactions akışı
- `SUBSCRIPTIONS_UI_DESIGN.md` - UI tasarım önerileri
- `.cursorrules` - Savings Goals kuralları
- `functions/handlers/chatWithAI.js` - Mevcut AI chat handler
- `lib/modules/transactions/widgets/quick_add_chat_fab.dart` - Chat UI

---

## ✅ Sonraki Adımlar

1. Bu dokümantasyonu review et
2. Phase 1'e başla (Recurring Transactions)
3. Her phase sonunda test et ve deploy et
4. Kullanıcı feedback'lerini topla
5. Iterasyon yap

