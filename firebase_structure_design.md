# Firebase Firestore Yapı Tasarımı - Qanta Finans Uygulaması

## 🏗️ Önerilen Koleksiyon Yapısı

### 1. Ana Koleksiyonlar

```
users/{userId}/
├── accounts/           # Tüm hesap türleri (kredi, debit, nakit)
├── transactions/       # Tüm işlemler
├── categories/         # Kategoriler
├── budgets/           # Bütçeler
├── installments/      # Taksitli işlemler
└── quick_notes/       # Hızlı notlar
```

### 2. Hesap Yönetimi (accounts/)

```json
{
  "id": "account_123",
  "user_id": "user_456",
  "type": "credit", // credit, debit, cash
  "name": "Akbank World Card",
  "bank_name": "Akbank",
  "balance": 1500.00,
  "credit_limit": 10000.00,
  "statement_day": 15,
  "due_day": 25,
  "is_active": true,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "metadata": {
    "card_number_last4": "1234",
    "card_holder": "John Doe",
    "expiry_month": 12,
    "expiry_year": 2026
  }
}
```

### 3. İşlem Yönetimi (transactions/)

```json
{
  "id": "transaction_789",
  "user_id": "user_456",
  "account_id": "account_123",
  "type": "expense", // expense, income, transfer
  "amount": 150.00,
  "description": "Market alışverişi",
  "category_id": "category_456",
  "category_name": "Market",
  "transaction_date": "2024-01-15T14:30:00Z",
  "is_paid": true,
  "installment_id": null, // Taksitli işlemler için
  "installment_number": null,
  "total_installments": null,
  "created_at": "2024-01-15T14:30:00Z",
  "updated_at": "2024-01-15T14:30:00Z",
  "metadata": {
    "location": "Migros AVM",
    "merchant": "Migros",
    "tags": ["market", "gıda"]
  }
}
```

### 4. Kategori Yönetimi (categories/)

```json
{
  "id": "category_456",
  "user_id": "user_456",
  "type": "expense", // expense, income
  "name": "Market",
  "icon": "shopping_cart",
  "color": "#FF6B6B",
  "parent_id": null, // Alt kategori için
  "is_system": false, // Sistem kategorisi mi
  "is_active": true,
  "sort_order": 1,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### 5. Taksit Yönetimi (installments/)

```json
{
  "id": "installment_789",
  "user_id": "user_456",
  "account_id": "account_123",
  "category_id": "category_456",
  "total_amount": 1200.00,
  "monthly_amount": 200.00,
  "total_installments": 6,
  "current_installment": 2,
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-06-01T00:00:00Z",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## 🔒 Güvenlik Kuralları

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı verilerine erişim
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Alt koleksiyonlar
      match /{collection}/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Sistem kategorileri (herkes okuyabilir)
    match /system_categories/{document} {
      allow read: if request.auth != null;
    }
  }
}
```

## 📊 Performans Optimizasyonları

### 1. Indexing Stratejisi

```javascript
// transactions koleksiyonu için
{
  "fields": [
    {"fieldPath": "user_id", "order": "ASCENDING"},
    {"fieldPath": "transaction_date", "order": "DESCENDING"}
  ]
}

{
  "fields": [
    {"fieldPath": "user_id", "order": "ASCENDING"},
    {"fieldPath": "account_id", "order": "ASCENDING"},
    {"fieldPath": "transaction_date", "order": "DESCENDING"}
  ]
}

{
  "fields": [
    {"fieldPath": "user_id", "order": "ASCENDING"},
    {"fieldPath": "type", "order": "ASCENDING"},
    {"fieldPath": "transaction_date", "order": "DESCENDING"}
  ]
}
```

### 2. Veri Yapısı Optimizasyonları

- **Compound Queries**: Kullanıcı + tarih + hesap kombinasyonları
- **Pagination**: Limit ve offset kullanımı
- **Caching**: Offline-first yaklaşım
- **Batch Operations**: Toplu işlemler için

## 🚀 Implementasyon Adımları

### 1. Yeni Servis Sınıfları
- `UnifiedAccountService`
- `UnifiedTransactionService`
- `CategoryService`
- `InstallmentService`

### 2. Migration Stratejisi
- Mevcut verileri yeni yapıya taşıma
- Backward compatibility
- Aşamalı geçiş

### 3. Test Stratejisi
- Unit testler
- Integration testler
- Performance testler
