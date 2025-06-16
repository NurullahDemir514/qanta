# Transaction Skeleton - Kullanım Kılavuzu

Bu dosya, Qanta uygulamasında tutarlı transaction UI tasarımı için oluşturulan `transaction_skeleton.dart` bileşenlerinin kullanım kılavuzudur.

## 📋 İçerik

- [Temel Bileşenler](#temel-bileşenler)
- [Kullanım Örnekleri](#kullanım-örnekleri)
- [Yardımcı Fonksiyonlar](#yardımcı-fonksiyonlar)
- [Özelleştirme](#özelleştirme)

## 🧩 Temel Bileşenler

### 1. TransactionContainer
Tüm transaction item'ları için temel container.

```dart
TransactionContainer(
  isDark: isDarkMode,
  onTap: () => print('Tapped'),
  child: YourWidget(),
)
```

### 2. TransactionIcon
Transaction için standart icon widget'ı.

```dart
TransactionIcon(
  icon: Icons.shopping_bag_outlined,
  iconColor: Colors.red,
  backgroundColor: Colors.red.withValues(alpha: 0.1),
  size: 28,
  iconSize: 14,
)
```

### 3. TransactionContent
Transaction için standart içerik yapısı.

```dart
TransactionContent(
  title: 'Market Alışverişi',
  subtitle: 'Akbank Kredi Kartı',
  amount: '-45.50₺',
  amountColor: Colors.red,
  isDark: isDarkMode,
  time: '2 saat önce',
)
```

### 4. TransactionAmount
Transaction için standart tutar gösterimi.

```dart
TransactionAmount(
  amount: '-45.50₺',
  color: Colors.red,
  isDark: isDarkMode,
  fontSize: 16,
  fontWeight: FontWeight.w600,
)
```

### 5. TransactionItem
Standart transaction item - tüm uygulamada kullanılacak.

```dart
TransactionItem(
  title: 'Market Alışverişi',
  subtitle: 'Akbank Kredi Kartı',
  amount: '-45.50₺',
  time: '2 saat önce',
  icon: Icons.shopping_bag_outlined,
  iconColor: Colors.red,
  backgroundColor: Colors.red.withValues(alpha: 0.1),
  amountColor: Colors.red,
  isDark: isDarkMode,
  onTap: () => print('Transaction tapped'),
)
```

### 6. TransactionList
Standart transaction listesi.

```dart
TransactionList(
  transactions: transactionWidgets,
  isDark: isDarkMode,
  title: 'Son İşlemler',
  onSeeAllTap: () => navigateToAllTransactions(),
  emptyTitle: 'Henüz işlem yok',
  emptyDescription: 'İlk işleminizi yaptığınızda burada görünecek',
  emptyIcon: Icons.receipt_long_outlined,
)
```

### 7. TransactionLoadingSkeleton
Yükleme durumu için iskelet.

```dart
TransactionLoadingSkeleton(
  isDark: isDarkMode,
  itemCount: 3,
  title: 'Son İşlemler',
)
```

### 8. CardTransactionWidget
CardTransactionModel'dan Widget'a dönüştürücü.

```dart
CardTransactionWidget(
  id: 'transaction_001',
  card: paymentCard,
  transactionType: TransactionType.purchase,
  title: 'Market Alışverişi',
  description: 'Nakit ödeme',
  amount: 45.50,
  date: DateTime.now(),
  isIncome: false,
  merchantName: 'Migros',
  isDarkMode: isDarkMode,
)
```

## 📝 Kullanım Örnekleri

### Basit Transaction Listesi

```dart
class MyTransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TransactionList(
      transactions: [
        TransactionItem(
          title: 'Kahve',
          subtitle: 'Starbucks',
          amount: '-15.50₺',
          time: '1 saat önce',
          icon: Icons.local_cafe_outlined,
          iconColor: TransactionUtils.getExpenseColor(),
          backgroundColor: TransactionUtils.getExpenseColor().withValues(alpha: 0.1),
          amountColor: TransactionUtils.getExpenseColor(),
          isDark: isDark,
        ),
        // Daha fazla transaction...
      ],
      isDark: isDark,
      title: 'Bugünkü İşlemler',
    );
  }
}
```

### Loading State ile

```dart
class TransactionSection extends StatelessWidget {
  final bool isLoading;
  final List<Widget> transactions;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isLoading) {
      return TransactionLoadingSkeleton(
        isDark: isDark,
        title: 'Son İşlemler',
        itemCount: 3,
      );
    }
    
    return TransactionList(
      transactions: transactions,
      isDark: isDark,
      title: 'Son İşlemler',
    );
  }
}
```

### CardTransactionModel Dönüştürme

```dart
List<Widget> convertCardTransactions(List<CardTransactionModel> cardTransactions, bool isDark) {
  return cardTransactions.map((transaction) => 
    CardTransactionWidget(
      id: transaction.id,
      card: transaction.card,
      transactionType: transaction.transactionType,
      title: transaction.title,
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
      isIncome: transaction.isIncome,
      merchantName: transaction.merchantName,
      isDarkMode: isDark,
    )
  ).toList();
}
```

## 🛠 Yardımcı Fonksiyonlar

### TransactionUtils Sınıfı

```dart
// Tarih formatı
String timeAgo = TransactionUtils.formatTransactionDate(DateTime.now());

// Tutar formatı
String amount = TransactionUtils.formatAmount(45.50, isIncome: false); // "-45.50₺"

// Renkler
Color incomeColor = TransactionUtils.getIncomeColor();    // Yeşil
Color expenseColor = TransactionUtils.getExpenseColor();  // Kırmızı
Color transferColor = TransactionUtils.getTransferColor(); // Mavi

// Kategori iconları
IconData icon = TransactionUtils.getCategoryIcon('food'); // restaurant_outlined
```

## 🎨 Özelleştirme

### Renk Özelleştirme

```dart
// TransactionUtils sınıfında renkleri değiştirin
static Color getIncomeColor() => const Color(0xFF34C759);  // Yeşil
static Color getExpenseColor() => const Color(0xFFFF3B30); // Kırmızı
static Color getTransferColor() => const Color(0xFF007AFF); // Mavi
```

### Icon Özelleştirme

```dart
// TransactionUtils.getCategoryIcon metodunu güncelleyin
static IconData getCategoryIcon(String? category) {
  switch (category?.toLowerCase()) {
    case 'food':
      return Icons.restaurant_outlined;
    case 'transport':
      return Icons.directions_car_outlined;
    // Yeni kategoriler ekleyin...
    default:
      return Icons.payment_outlined;
  }
}
```

### Boyut Özelleştirme

```dart
TransactionIcon(
  icon: Icons.shopping_bag_outlined,
  iconColor: Colors.red,
  backgroundColor: Colors.red.withValues(alpha: 0.1),
  size: 32,      // Varsayılan: 28
  iconSize: 16,  // Varsayılan: 14
)
```

## 📱 Responsive Tasarım

Tüm bileşenler otomatik olarak dark/light mode'u destekler:

```dart
// isDark parametresi ile tema desteği
TransactionList(
  transactions: transactions,
  isDark: Theme.of(context).brightness == Brightness.dark,
  // ...
)
```

## 🔄 Migration Kılavuzu

### Eski IOSTransactionList'ten Geçiş

```dart
// ESKI
IOSTransactionList.fromCardTransactions(
  cardTransactions: cardTransactions,
  title: 'Son İşlemler',
)

// YENİ
TransactionList(
  transactions: cardTransactions.map((t) => 
    CardTransactionWidget.fromCardTransaction(t, isDark)
  ).toList(),
  isDark: isDark,
  title: 'Son İşlemler',
)
```

## 📋 Best Practices

1. **Tutarlılık**: Tüm transaction UI'ları için aynı bileşenleri kullanın
2. **Performance**: Büyük listeler için ListView.builder kullanın
3. **Accessibility**: Semantic labels ekleyin
4. **Error Handling**: Loading ve error state'leri ekleyin
5. **Testing**: Widget testleri yazın

## 🐛 Troubleshooting

### Sık Karşılaşılan Sorunlar

1. **Import Hatası**: `import '../../../shared/widgets/transaction_skeleton.dart';`
2. **Theme Sorunu**: `isDark` parametresini doğru geçtiğinizden emin olun
3. **Performance**: Çok fazla transaction için pagination kullanın

Bu kılavuz, transaction skeleton bileşenlerinin doğru ve tutarlı kullanımını sağlamak için oluşturulmuştur. Sorularınız için geliştirici ekibi ile iletişime geçin. 