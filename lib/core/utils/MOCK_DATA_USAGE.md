# Mock Data Generator - Kullanım Kılavuzu

## 📱 Ne İçin Kullanılır?

Bu mock data generator, **Play Store screenshot'ları** için uygulamayı gerçekçi verilerle doldurmak amacıyla oluşturulmuştur.

## ⚠️ ÖNEMLİ UYARILAR

- **ASLA production'da kullanılmamalı**
- **ASLA Firebase'e yazılmamalı**
- **SADECE local UI state için kullanılmalı**
- **Screenshot çekildikten sonra temizlenmeli**

## 📊 Mock Veriler

### Hesaplar (4 adet):
1. **HSBC Türkiye Kredi Kartı** - 5.000 TL borç (15.000 TL limit)
2. **Akbank Vadesiz Hesap** - 12.500,50 TL bakiye
3. **Nakit Cüzdan** - 850 TL
4. **Garanti BBVA Miles&Smiles** - 2.300 TL borç (10.000 TL limit)

**Toplam Net Değer:** ~6.050,50 TL (nakit hesaplar - kredi kartı borçları)

### İşlemler (7 adet):
- Migros Market (350 TL) - Bugün
- Maaş Ödemesi (15.000 TL) - Bugün
- Shell Benzin (1.200 TL) - Dün
- Starbucks (85 TL) - Dün
- Zara (2.500 TL) - 3 gün önce
- Türk Telekom (850 TL) - 5 gün önce
- Cinemaximum (450 TL) - 6 gün önce

### Hisse Pozisyonları (3 adet):
1. **THYAO** - 250 adet, +10.33% kar
2. **AKBNK** - 500 adet, +8.25% kar
3. **EREGL** - 300 adet, +2.80% kar

**Toplam Hisse Değeri:** ~123.450 TL

## 🔧 Nasıl Kullanılır?

### Metod 1: Provider ile (Önerilen)

```dart
import 'package:qanta/core/utils/mock_data_generator.dart';

// Provider'da mock veriler ile state'i doldur
class MyProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [];
  List<TransactionModelV2> _transactions = [];
  
  void loadMockData() {
    if (MockDataGenerator.isMockDataEnabled()) {
      _accounts = MockDataGenerator.generateMockAccounts();
      _transactions = MockDataGenerator.generateMockTransactions();
      notifyListeners();
      
      print('✅ Mock veriler yüklendi!');
      print(MockDataGenerator.getMockDataSummary());
    }
  }
  
  void clearMockData() {
    _accounts = [];
    _transactions = [];
    notifyListeners();
    MockDataGenerator.clearMockData();
  }
}
```

### Metod 2: Debug Menü ile

Profile screen'e bir debug toggle eklenebilir:

```dart
// profile_screen.dart içinde

if (kDebugMode) {
  ListTile(
    leading: Icon(Icons.bug_report),
    title: Text('Mock Veriler'),
    subtitle: Text('Screenshot için örnek veri yükle'),
    trailing: Switch(
      value: _mockDataEnabled,
      onChanged: (value) {
        setState(() {
          _mockDataEnabled = value;
          if (value) {
            _loadMockData();
          } else {
            _clearMockData();
          }
        });
      },
    ),
  ),
}
```

### Metod 3: Startup Flag ile

```dart
// main.dart içinde

void main() {
  const bool enableMockData = false; // Screenshot çekerken true yap
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MyProvider()..init(useMockData: enableMockData),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

## 📸 Screenshot İş Akışı

1. **Mock Veriyi Etkinleştir**
   ```dart
   // main.dart veya debug menüde
   const bool enableMockData = true;
   ```

2. **Uygulamayı Hot Restart Et**
   ```
   Hot restart yaparak tüm state'i sıfırla
   ```

3. **Screenshot'ları Çek**
   - Home Screen
   - Hesaplar Sayfası
   - İşlemler Listesi
   - Hisse Portföyü
   - Profil Sayfası

4. **Mock Veriyi Temizle**
   ```dart
   const bool enableMockData = false;
   ```

5. **Commit Etme**
   ```
   Mock data flag'i ASLA true olarak commit edilmemeli!
   ```

## 🎨 Özet Bilgiler

```dart
final summary = MockDataGenerator.getMockDataSummary();

print(summary);
// {
//   'totalAccounts': 4,
//   'totalTransactions': 7,
//   'totalStockPositions': 3,
//   'totalBalance': 6050.50,
//   'totalStockValue': 123450.00,
//   'totalNetWorth': 129500.50,
//   'totalIncome': 15000.00,
//   'totalExpense': 5435.00
// }
```

## 🗑️ Temizleme

```dart
// Tüm mock veriyi temizle
MockDataGenerator.clearMockData();

// Provider state'ini sıfırla
provider.clearMockData();
```

## ⚙️ Yardımcı Metodlar

```dart
// Hesap isimlerini al
final accountNames = MockDataGenerator.getMockAccountNames();
// ['HSBC Türkiye Kredi Kartı', 'Akbank Vadesiz Hesap', ...]

// İşlem kategorilerini al
final categories = MockDataGenerator.getMockTransactionCategories();
// ['grocery', 'salary', 'transportation', ...]

// Hisse sembollerini al
final symbols = MockDataGenerator.getMockStockSymbols();
// ['THYAO', 'AKBNK', 'EREGL']
```

## 🔒 Güvenlik Notları

1. **Firebase'e Yazma**: Mock veriler ASLA Firebase'e yazılmamalı
2. **Production Build**: Release build'de mock data kodu tamamen devre dışı
3. **Debug Flag**: `kDebugMode` ile guard edilmeli
4. **User Data**: Mock veriler gerçek kullanıcı verilerini overwrite etmemeli

## 📝 Özelleştirme

Kendi mock verilerinizi eklemek için:

```dart
// mock_data_generator.dart içinde

static List<AccountModel> generateMockAccounts() {
  return [
    AccountModel(
      id: 'your_id',
      userId: 'mock_user',
      name: 'Yeni Hesap',
      type: AccountType.debit,
      balance: 1000.0,
      // ... diğer alanlar
    ),
    // ... daha fazla hesap
  ];
}
```

## 🐛 Debug

Mock veriler yüklendiğinde console'da:

```
✅ Mock veriler yüklendi!
{totalAccounts: 4, totalTransactions: 7, ...}
```

Mock veriler temizlendiğinde:

```
🧹 Mock veriler temizlendi
```

---

**Son Güncelleme:** 2024
**Versiyon:** 1.0.0
**Kullanım:** Play Store Screenshots Only
