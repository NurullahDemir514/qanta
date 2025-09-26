# Firebase Firestore & Storage Kullanım Örnekleri - Qanta

## 🏗️ Yeni Yapı Kullanımı

### 1. Hesap Ekleme (Kart/Bakiye)

```dart
import 'package:qanta/core/services/unified_account_service.dart';
import 'package:qanta/shared/models/account_model.dart';

// Kredi kartı ekleme
final creditCard = AccountModel(
  id: '', // Boş bırakın, otomatik oluşturulur
  userId: '', // Boş bırakın, otomatik doldurulur
  type: AccountType.credit,
  name: 'Akbank World Card',
  bankName: 'Akbank',
  balance: 0.0,
  creditLimit: 10000.0,
  statementDay: 15,
  dueDay: 25,
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final accountId = await UnifiedAccountService.addAccount(creditCard);
print('Kredi kartı eklendi: $accountId');

// Debit kart ekleme
final debitCard = AccountModel(
  id: '',
  userId: '',
  type: AccountType.debit,
  name: 'Garanti Debit Card',
  bankName: 'Garanti',
  balance: 5000.0,
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final debitAccountId = await UnifiedAccountService.addAccount(debitCard);

// Nakit hesap ekleme
final cashAccount = AccountModel(
  id: '',
  userId: '',
  type: AccountType.cash,
  name: 'Nakit Cüzdan',
  balance: 1000.0,
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final cashAccountId = await UnifiedAccountService.addAccount(cashAccount);
```

### 2. Bakiye Yönetimi

```dart
// Bakiye güncelleme
await UnifiedAccountService.updateBalance(
  accountId: accountId,
  newBalance: 2500.0,
);

// Bakiyeye ekleme
await UnifiedAccountService.addToBalance(
  accountId: accountId,
  amount: 500.0,
);

// Bakiyeden çıkarma
await UnifiedAccountService.subtractFromBalance(
  accountId: accountId,
  amount: 200.0,
);
```

### 3. İşlem Ekleme

```dart
import 'package:qanta/core/services/unified_transaction_service.dart';
import 'package:qanta/shared/models/transaction_model_v2.dart';

// Gider işlemi
final expense = TransactionWithDetailsV2(
  id: '',
  userId: '',
  accountId: accountId,
  type: TransactionType.expense,
  amount: 150.0,
  description: 'Market alışverişi',
  categoryId: 'category_123',
  categoryName: 'Market',
  transactionDate: DateTime.now(),
  isPaid: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final transactionId = await UnifiedTransactionService.addTransaction(expense);

// Gelir işlemi
final income = TransactionWithDetailsV2(
  id: '',
  userId: '',
  accountId: accountId,
  type: TransactionType.income,
  amount: 5000.0,
  description: 'Maaş',
  categoryId: 'category_456',
  categoryName: 'Maaş',
  transactionDate: DateTime.now(),
  isPaid: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await UnifiedTransactionService.addTransaction(income);
```

### 4. Veri Çekme

```dart
// Tüm hesapları getir
final accounts = await UnifiedAccountService.getAllAccounts();

// Kredi kartlarını getir
final creditCards = await UnifiedAccountService.getAccountsByType(AccountType.credit);

// Tüm işlemleri getir
final transactions = await UnifiedTransactionService.getAllTransactions();

// Belirli hesabın işlemlerini getir
final accountTransactions = await UnifiedTransactionService.getTransactionsByAccount(
  accountId: accountId,
);

// Tarih aralığındaki işlemleri getir
final dateRangeTransactions = await UnifiedTransactionService.getTransactionsByDateRange(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
```

### 5. Real-time Veri Dinleme

```dart
// Hesapları real-time dinle
StreamBuilder<List<AccountModel>>(
  stream: UnifiedAccountService.getAccountStream(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('Hata: ${snapshot.error}');
    }
    
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    final accounts = snapshot.data ?? [];
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return ListTile(
          title: Text(account.name),
          subtitle: Text('Bakiye: ${account.balance}'),
        );
      },
    );
  },
)

// İşlemleri real-time dinle
StreamBuilder<List<TransactionWithDetailsV2>>(
  stream: UnifiedTransactionService.getTransactionStream(),
  builder: (context, snapshot) {
    // Similar implementation
  },
)
```

### 6. Firebase Storage Kullanımı

```dart
import 'package:qanta/core/services/firebase_storage_service.dart';
import 'dart:io';

// CSV dosyası yükleme
final csvFile = File('/path/to/transactions.csv');
final downloadUrl = await FirebaseStorageService.uploadCSVFile(
  file: csvFile,
  tableName: 'transactions',
);

// Resim yükleme
final imageFile = File('/path/to/receipt.jpg');
final imageUrl = await FirebaseStorageService.uploadImageFile(
  file: imageFile,
  folder: 'receipts',
);

// Dosya indirme
final localFile = await FirebaseStorageService.downloadFile(
  downloadUrl: downloadUrl,
  localPath: '/local/path/file.csv',
);

// Dosya listesi
final files = await FirebaseStorageService.listFiles(
  folder: 'tables',
);

// Depolama kullanımı
final usage = await FirebaseStorageService.getStorageUsage();
print('Kullanılan alan: ${usage.formattedSize}');
```

### 7. Migration Kullanımı

```dart
import 'package:qanta/core/services/migration_service.dart';

// Migration gerekli mi kontrol et
final needsMigration = await MigrationService.isMigrationNeeded();

if (needsMigration) {
  // Migration yap
  await MigrationService.migrateUserData();
  
  // Eski verileri temizle (opsiyonel)
  await MigrationService.cleanupOldCollections();
}
```

## 🔒 Güvenlik Kuralları

### Firestore Rules
```javascript
// firestore.rules dosyasını Firebase Console'da aktifleştirin
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{collection}/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Storage Rules
```javascript
// storage.rules dosyasını Firebase Console'da aktifleştirin
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📊 Performans İpuçları

### 1. Indexing
```javascript
// Firebase Console'da aşağıdaki indexleri oluşturun:

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
```

### 2. Pagination
```dart
// Sayfalama ile veri çekme
final transactions = await UnifiedTransactionService.getAllTransactions(
  limit: 20,
  offset: 0,
);

// Sonraki sayfa
final nextPage = await UnifiedTransactionService.getAllTransactions(
  limit: 20,
  offset: 20,
);
```

### 3. Caching
```dart
// Offline-first yaklaşım için
final transactions = await UnifiedTransactionService.getAllTransactions();
// Veriler otomatik olarak cache'lenir
```

## 🚀 Deployment

### 1. Firebase Console'da
1. Firestore Rules'ı aktifleştirin
2. Storage Rules'ı aktifleştirin
3. Indexleri oluşturun
4. Güvenlik kurallarını test edin

### 2. Uygulama Güncellemesi
1. Yeni servisleri import edin
2. Eski servisleri kaldırın
3. Migration'ı çalıştırın
4. Test edin

Bu yapı ile kart ekleme, bakiye yönetimi ve Firebase Storage kullanımı çok daha verimli ve güvenli hale gelir! 🎉
