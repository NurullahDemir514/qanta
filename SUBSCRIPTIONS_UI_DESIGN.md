# Abonelikler (Otomatik Tekrarlayan İşlemler) UI Tasarım Önerisi

> **Tasarım Dili**: Mevcut Qanta Material 3 + iOS-style polish ile uyumlu
> **Referans**: Savings Goals, Budget Management, Transaction List pattern'leri

---

## 📱 1. Ana Ekran: Abonelikler Listesi

### 1.1. Sayfa Yapısı
```dart
// lib/modules/subscriptions/screens/subscriptions_screen.dart
AppPageScaffold(
  title: 'Abonelikler',
  subtitle: 'Aktif: ${activeCount} • Toplam: ${totalCount}',
  searchBar: SubscriptionSearchBar(),
  filters: SubscriptionFilters(
    // Aktif/Pasif toggle
    // Kategori filtreleri (Subscription, Utilities, Insurance, Rent, Loan)
    // Frequency filtreleri (Weekly, Monthly, Quarterly, Yearly)
  ),
  floatingActionButton: AddSubscriptionFAB(),
  body: SubscriptionList(),
)
```

### 1.2. Abonelik Kartı Tasarımı
**Stil**: Savings Goal Card pattern'i kullanarak, kompakt ve bilgilendirici

```dart
// lib/modules/subscriptions/widgets/subscription_card.dart
class SubscriptionCard extends StatelessWidget {
  final RecurringTransaction subscription;
  
  // Tasarım özellikleri:
  // - Gradient background (category'ye göre renk)
  // - Rounded corners (16px)
  // - Subtle shadow
  // - Compact layout (dikey)
  
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(subscription.category),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: İkon + İsim + Durum badge
          Row(
            children: [
              // Kategori ikonu (Netflix, Spotify, etc.)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(), size: 24, color: Colors.white),
              ),
              SizedBox(width: 12),
              
              // İsim ve kategori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getCategoryName(subscription.category),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Aktif/Pasif switch (iOS style)
              _buildActiveToggle(),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Orta satır: Tutar ve Frequency
          Row(
            children: [
              // Tutar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      CurrencyUtils.formatAmount(subscription.amount, currency),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Frequency badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(subscription.frequency.icon, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      subscription.frequency.getDisplayName(l10n),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Alt satır: Sonraki ödeme tarihi ve hesap
          Row(
            children: [
              // Sonraki ödeme
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.7)),
                    SizedBox(width: 6),
                    Text(
                      'Sonraki: ${_formatNextPaymentDate()}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Hesap adı (kısa)
              Text(
                _getAccountShortName(subscription.accountId),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Kategori Renkleri**:
- **Subscription** (Netflix, Spotify): Purple gradient (#9D50BB → #6E48AA)
- **Utilities** (Elektrik, Su): Blue gradient (#4A90E2 → #357ABD)
- **Insurance** (Sağlık, Araba): Green gradient (#4CAF50 → #45A049)
- **Rent** (Kira): Orange gradient (#FF6B6B → #EE5A6F)
- **Loan** (Kredi): Red gradient (#E74C3C → #C0392B)
- **Other**: Grey gradient (#6D6D70 → #5A5A5D)

---

## 📝 2. Abonelik Ekleme Formu

### 2.1. Form Yapısı
**Stil**: Budget Add Sheet pattern'i - Step-based form, iOS-style controls

```dart
// lib/modules/subscriptions/widgets/add_subscription_form.dart
class AddSubscriptionForm extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              _buildHandleBar(),
              
              // Header
              _buildHeader(),
              
              // Form content (PageView with steps)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1_Details(),      // İsim, kategori, tutar
                    _buildStep2_Schedule(),      // Frequency, başlangıç tarihi, bitiş tarihi
                    _buildStep3_Account(),       // Hesap seçimi
                    _buildStep4_Summary(),       // Özet ve kaydet
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        );
      },
    );
  }
}
```

### 2.2. Step 1: Detaylar (İsim, Kategori, Tutar)

**Layout**:
```
┌─────────────────────────────────────┐
│  📝 Abonelik Ekle                   │
│  ───────────────────────────────    │
│                                     │
│  [İsim/İşlem Açıklaması]           │
│  ┌─────────────────────────────┐   │
│  │ Netflix Premium              │   │
│  └─────────────────────────────┘   │
│                                     │
│  Kategori                           │
│  ┌───┬───┬───┬───┬───┬───┐        │
│  │🎵 │💡 │🏥 │🏠 │💰 │📄 │        │
│  │Sub│Util│Ins│Rent│Loan│Other│    │
│  └───┴───┴───┴───┴───┴───┘        │
│                                     │
│  Tutar                              │
│  ┌─────────────────────────────┐   │
│  │ 99.99 ₺                     │   │
│  └─────────────────────────────┘   │
│                                     │
│          [İleri →]                  │
└─────────────────────────────────────┘
```

**Kod Örneği**:
```dart
Widget _buildStep1_Details() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İsim input
        Text(
          'Abonelik Adı',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Örn: Netflix Premium',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Kategori seçimi (horizontal scroll)
        Text(
          'Kategori',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RecurringCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? _getCategoryColor(category)
                        : (isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? _getCategoryColor(category)
                          : (isDark ? Color(0xFF3A3A3C) : Color(0xFFE5E5EA)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_getCategoryEmoji(category), style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        _getCategoryName(category),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Tutar input
        Text(
          'Aylık Tutar',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${currencySymbol} ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}
```

### 2.3. Step 2: Takvim (Frequency, Tarihler)

**Layout**:
```
┌─────────────────────────────────────┐
│  📅 Tekrarlama Planı                │
│  ───────────────────────────────    │
│                                     │
│  Sıklık                             │
│  ┌───┬───┬───┬───┐                 │
│  │📅 │📆 │📊 │📈 │                 │
│  │Haft│Ayl│3 Ay│Yıl│                 │
│  └───┴───┴───┴───┘                 │
│                                     │
│  Başlangıç Tarihi                   │
│  ┌─────────────────────────────┐   │
│  │ 📅 15 Ocak 2025             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Bitiş Tarihi (Opsiyonel)           │
│  ┌─────────────────────────────┐   │
│  │ ☐ Sınırsız                  │   │
│  │ 📅 15 Ocak 2026             │   │
│  └─────────────────────────────┘   │
│                                     │
│     [← Geri]      [İleri →]        │
└─────────────────────────────────────┘
```

**Frequency Seçimi** (iOS-style segmented control):
```dart
Widget _buildFrequencySelector() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
      border: Border.all(
        color: isDark ? Color(0xFF3A3A3C) : Color(0xFFE5E5EA),
      ),
    ),
    child: Row(
      children: RecurringFrequency.values.map((freq) {
        final isSelected = _selectedFrequency == freq;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedFrequency = freq),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(freq.icon, size: 20, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                  SizedBox(height: 4),
                  Text(
                    freq.getDisplayName(l10n),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
```

### 2.4. Step 3: Hesap Seçimi

**Layout**: Budget management page'deki account selector gibi
- Cash accounts (yeşil)
- Debit cards (mavi)
- Credit cards (kırmızı)

**Kod**: `expense_payment_method_selector.dart` pattern'ini kullan

### 2.5. Step 4: Özet ve Onay

**Layout**:
```
┌─────────────────────────────────────┐
│  ✅ Özet                            │
│  ───────────────────────────────    │
│                                     │
│  📝 Netflix Premium                 │
│  🎵 Abonelik                        │
│  💰 99.99 ₺ / ay                   │
│  📅 Her ayın 15'i                   │
│  🏦 Garanti Kredi Kartı             │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Sonraki Ödeme                │   │
│  │ 15 Şubat 2025                │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Bildirim gönder             │   │
│  │ Ödeme gününden 2 gün önce   │   │
│  └─────────────────────────────┘   │
│                                     │
│  [← Geri]        [✅ Kaydet]        │
└─────────────────────────────────────┘
```

---

## 🔍 3. Filtreleme ve Arama

### 3.1. Filtreler
```dart
// lib/modules/subscriptions/widgets/subscription_filters.dart
class SubscriptionFilters extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Aktif/Pasif toggle (iOS style)
          _buildActiveFilter(),
          
          SizedBox(width: 12),
          
          // Kategori filtreleri (chip'ler)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildCategoryChips(),
              ),
            ),
          ),
          
          // Sıralama butonu
          _buildSortButton(),
        ],
      ),
    );
  }
}
```

**Filtre Seçenekleri**:
- **Durum**: Tümü / Aktif / Pasif
- **Kategori**: Tümü / Subscription / Utilities / Insurance / Rent / Loan / Other
- **Frequency**: Tümü / Weekly / Monthly / Quarterly / Yearly
- **Sıralama**: İsim (A-Z) / Tutar (Yüksek-Düşük) / Sonraki Ödeme (Yakın-Uzak)

---

## 📄 4. Detay Ekranı

### 4.1. Layout
**Stil**: Budget Management Page pattern'i

```dart
// lib/modules/subscriptions/screens/subscription_detail_screen.dart
AppPageScaffold(
  title: subscription.name,
  subtitle: '${subscription.frequency.getDisplayName(l10n)} • ${CurrencyUtils.formatAmount(subscription.amount, currency)}',
  actions: [
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: _showEditDialog,
    ),
    IconButton(
      icon: Icon(Icons.delete),
      onPressed: _showDeleteDialog,
    ),
  ],
  body: Column(
    children: [
      // Üst kart: Özet bilgiler
      _buildSummaryCard(),
      
      // Orta: Son ödemeler listesi
      _buildPaymentHistory(),
      
      // Alt: İstatistikler (opsiyonel)
      _buildStatistics(),
    ],
  ),
)
```

### 4.2. Özet Kartı
```
┌─────────────────────────────────────┐
│  💰 99.99 ₺ / ay                    │
│  📅 Her ayın 15'i                   │
│  🏦 Garanti Kredi Kartı             │
│                                     │
│  ┌──────────┬──────────┐           │
│  │ Toplam   │ Son Ödeme│           │
│  │ 599.94₺  │ 15 Oca   │           │
│  └──────────┴──────────┘           │
│                                     │
│  [Aktif] 🔵                        │
└─────────────────────────────────────┘
```

### 4.3. Ödeme Geçmişi
Transaction list pattern'i kullan, ama sadece bu aboneliğe ait işlemleri göster

---

## 🎨 5. Tasarım Detayları

### 5.1. Renk Paleti
**Kategori Renkleri** (Mevcut uygulama renklerine uyumlu):
- **Subscription**: Purple (#9D50BB, #6E48AA)
- **Utilities**: Blue (#4A90E2, #357ABD) - Mevcut Info color'a yakın
- **Insurance**: Green (#4CAF50) - Mevcut Success color
- **Rent**: Orange (#FF6B6B) - Yeni
- **Loan**: Red (#FF4C4C) - Mevcut Error color
- **Other**: Grey (#6D6D70) - Mevcut Primary color

### 5.2. İkonlar
- **Subscription**: 🎵 `Icons.music_note` / `Icons.subscriptions`
- **Utilities**: 💡 `Icons.flash_on` / `Icons.electric_bolt`
- **Insurance**: 🏥 `Icons.local_hospital` / `Icons.health_and_safety`
- **Rent**: 🏠 `Icons.home` / `Icons.apartment`
- **Loan**: 💰 `Icons.account_balance` / `Icons.money`
- **Other**: 📄 `Icons.description` / `Icons.category`

### 5.3. Animasyonlar
- Card'lar: Fade-in animation (mevcut pattern)
- Form steps: Slide transition
- Toggle switches: iOS-style smooth animation
- Empty state: `AnimatedEmptyState` widget kullan

### 5.4. Responsive Design
- `flutter_screenutil` kullan
- Padding ve margin'ler responsive
- Font size'lar responsive

---

## 📱 6. Empty State

```dart
Widget _buildEmptyState() {
  return AnimatedEmptyState(
    icon: Icons.subscriptions_outlined,
    iconColor: Color(0xFF007AFF),
    title: l10n.noSubscriptionsYet,
    description: l10n.addFirstSubscriptionDescription,
    actionButton: ElevatedButton.icon(
      onPressed: _showAddForm,
      icon: Icon(Icons.add),
      label: Text(l10n.addSubscription),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF007AFF),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}
```

---

## 🎯 7. Kullanıcı Deneyimi Detayları

### 7.1. Aktif/Pasif Toggle
**Konum**: Her abonelik kartının sağ üstünde
**Stil**: iOS Switch widget
**Etki**: Hemen aktif/pasif yapar, confirmation yok (geri alınabilir)

### 7.2. Hızlı Eylemler (Swipe Actions)
**Swipe Left**: Düzenle
**Swipe Right**: Sil (confirmation gerekli)

### 7.3. Bildirim Ayarları
Her abonelik için:
- Bildirim açık/kapalı
- Bildirim zamanı (kaç gün önce)
- Bildirim saati

### 7.4. Toplu İşlemler
- Çoklu seçim modu
- Toplu aktif/pasif
- Toplu silme

---

## 📋 8. Gerekli Localization Strings

```dart
// intl_tr.arb ve intl_en.arb'ye eklenecek:
- subscriptions: "Abonelikler"
- subscriptionsDescription: "Otomatik tekrarlayan işlemlerinizi yönetin"
- noSubscriptionsYet: "Henüz abonelik eklemediniz"
- addFirstSubscriptionDescription: "Netflix, Spotify gibi aboneliklerinizi ekleyerek otomatik takip edin"
- addSubscription: "Abonelik Ekle"
- nextPayment: "Sonraki Ödeme"
- lastPayment: "Son Ödeme"
- subscriptionActive: "Aktif"
- subscriptionInactive: "Pasif"
- totalPaid: "Toplam Ödenen"
- paymentCount: "Ödeme Sayısı"
- editSubscription: "Aboneliği Düzenle"
- deleteSubscription: "Aboneliği Sil"
- subscriptionDeleted: "Abonelik silindi"
- subscriptionSaved: "Abonelik kaydedildi"
- subscriptionActivated: "Abonelik aktifleştirildi"
- subscriptionDeactivated: "Abonelik pasifleştirildi"
- notificationDaysBefore: "Bildirim (gün öncesi)"
- notificationTime: "Bildirim Saati"
```

---

## 🔧 9. Teknik Implementasyon Notları

### 9.1. State Management
- `RecurringTransactionProvider` (yeni)
- `UnifiedProviderV2` ile entegrasyon
- Real-time updates için Firestore listeners

### 9.2. Data Model
```dart
class RecurringTransaction {
  final String id;
  final String userId;
  final String name;
  final RecurringCategory category;
  final double amount;
  final RecurringFrequency frequency;
  final String accountId;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? lastExecutedDate;
  final DateTime? nextExecutionDate;
  final NotificationSettings notificationSettings;
}
```

### 9.3. Services
- `RecurringTransactionService` - CRUD operations
- `RecurringTransactionScheduler` - Background task management
- `BudgetAlertService` entegrasyonu (budget limit uyarıları gibi)

---

---

## 🔗 10. Budget Sayfası Entegrasyonu

### 10.1. Entegrasyon Yaklaşımı: Segment Control (ÖNERİLEN ✅)

**Neden Segment Control?**
- ✅ Mevcut sayfa yapısına uyumlu (minimal değişiklik)
- ✅ Uygulamada zaten yaygın kullanılıyor (Stocks Screen, Premium Offer Screen, Budget Add Sheet)
- ✅ iOS-style polish (recurring toggle ile tutarlı)
- ✅ Daha kompakt ve kullanıcı dostu
- ✅ Büyük refactor gerektirmiyor
- ✅ Tek ekranda her şey görünür

**Karşılaştırma:**
| Özellik | Segment Control | Tab-Based |
|---------|----------------|-----------|
| **Implementasyon Zorluğu** | Kolay ⭐ | Zor ⭐⭐⭐ |
| **Refactor Gereksinimi** | Minimal | Büyük (AppPageScaffold) |
| **Mevcut Pattern Uyumu** | Yüksek (zaten kullanılıyor) | Orta (sadece Cards Screen) |
| **iOS-style Polish** | ✅ Yüksek | ⚠️ Orta |
| **Kompaktlık** | ✅ Çok kompakt | ⚠️ Daha fazla yer |
| **Scroll Davranışı** | Tek scroll, içerik değişir | Her tab ayrı scroll |

### 10.2. Detaylı Yapı ve Konumlandırma

#### 10.2.1. Segment Control Konumu

**Seçenek 1: Genel Bütçe Kartı Altında (Önerilen)**
```
┌─────────────────────────────────────────┐
│ AppBar: "Bütçe ve Abonelikler"         │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ Genel Bütçe Kartı (PageView)       │ │ ← Sadece Budget seçiliyse göster
│ │ [3 page indicator]                  │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ [ Bütçeler ] [ Abonelikler ]       │ │ ← Segment Control (16px padding)
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ İçerik (Seçime göre)                │ │
│ │ - Budget listesi VEYA               │ │
│ │ - Subscription listesi              │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Seçenek 2: AppBar Hemen Altında (Alternatif)**
```
┌─────────────────────────────────────────┐
│ AppBar: "Bütçe ve Abonelikler"         │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ [ Bütçeler ] [ Abonelikler ]       │ │ ← Segment Control (üstte)
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Genel Bütçe/Özet Kartı              │ │ ← Dinamik (hangi view seçili)
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ İçerik                               │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Öneri**: Seçenek 1 (Genel bütçe kartı altında)
- Budget view'da zaten genel kart var
- Subscription view'da özet kartı gösterilir
- Daha organize görünüm

### 10.3. Segment Control Implementasyonu

#### 10.3.1. Widget Yapısı

```dart
// lib/modules/home/pages/budget_management_page.dart
class BudgetManagementPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Bütçeler + Abonelikler
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bütçe ve Abonelikler'), // Yeni başlık
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Bütçeler',
              ),
              Tab(
                icon: Icon(Icons.subscriptions_outlined),
                text: 'Abonelikler',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BudgetsTab(),      // Mevcut budget içeriği
            SubscriptionsTab(), // Yeni abonelikler içeriği
          ],
        ),
        floatingActionButton: _buildFAB(), // Tab'a göre dinamik FAB
      ),
    );
  }
}
```

```dart
// lib/modules/home/pages/budget_management_page.dart
class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  int _selectedView = 0; // 0 = Budgets, 1 = Subscriptions
  final PageController _overallPageController = PageController();
  // ... mevcut state variables

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedProviderV2>(
      builder: (context, providerV2, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context)!.budgetAndSubscriptions, // Yeni localization
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Genel bütçe kartı (sadece Budget view'da ve bütçe varsa göster)
                  if (_selectedView == 0 && currentBudgets.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildOverallBudgetCard(
                        currentBudgets.map((b) => _calculateBudgetStats(b)).toList(),
                        isDark,
                      ),
                    ),
                    _buildPageIndicator(/*...*/),
                    const SizedBox(height: 8),
                  ],
                  
                  // Özet kartı (sadece Subscription view'da göster)
                  if (_selectedView == 1) ...[
                    _buildSubscriptionsSummaryCard(isDark),
                    const SizedBox(height: 8),
                  ],
                  
                  // Segment Control
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSegmentControl(isDark),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // İçerik (Seçime göre değişir)
                  Expanded(
                    child: _selectedView == 0
                        ? _buildBudgetsContent(currentBudgets, isDark)
                        : _buildSubscriptionsContent(isDark),
                  ),
                  
                  // Banner Reklam
                  if (!isPremium && _budgetBannerService.isLoaded) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: _budgetBannerService.bannerWidget!,
                    ),
                  ],
                ],
              ),
              
              // FABs
              _buildFABStack(isDark),
            ],
          ),
        );
      },
    );
  }

  /// Segment Control Widget
  Widget _buildSegmentControl(bool isDark) {
    return Container(
      height: 44, // iOS standard height
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Budgets Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedView = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _selectedView == 0
                      ? (isDark ? const Color(0xFF007AFF) : const Color(0xFF007AFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedView == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: _selectedView == 0
                            ? Colors.white
                            : (isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.budgets,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedView == 0
                              ? Colors.white
                              : (isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Subscriptions Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedView = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _selectedView == 1
                      ? (isDark ? const Color(0xFF007AFF) : const Color(0xFF007AFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedView == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.subscriptions_outlined,
                        size: 18,
                        color: _selectedView == 1
                            ? Colors.white
                            : (isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.subscriptions,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedView == 1
                              ? Colors.white
                              : (isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF6D6D70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
```

### 10.4. İçerik Widget'ları

#### 10.4.1. Budgets Content (Mevcut İçerik)
```dart
// lib/modules/subscriptions/widgets/subscriptions_tab.dart
class SubscriptionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecurringTransactionProvider>(
      builder: (context, provider, child) {
        final subscriptions = provider.activeSubscriptions;
        
        return Column(
          children: [
            // Özet kartı (Toplam abonelik maliyeti)
            _buildSummaryCard(subscriptions),
            
            // Abonelikler listesi
            Expanded(
              child: subscriptions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        return SubscriptionCard(
                          subscription: subscriptions[index],
                        );
                      },
                    ),
            ),
            
            // Banner reklam
            if (!isPremium) _buildBanner(),
          ],
        );
      },
    );
  }
}
```

```dart
/// Budgets view içeriği (mevcut kod)
Widget _buildBudgetsContent(List<BudgetModel> budgets, bool isDark) {
  if (budgets.isEmpty) {
    return _buildEmptyState(isDark);
  }
  
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: budgets.length,
    itemBuilder: (context, index) {
      final budget = budgets[index];
      final stat = _calculateBudgetStats(budget);
      return _buildBudgetCard(stat, isDark, index, budgets.length);
    },
  );
}
```

#### 10.4.2. Subscriptions Content (Yeni İçerik)

```dart
Widget _buildFAB(BuildContext context) {
  final tabController = DefaultTabController.of(context);
  
  return AnimatedBuilder(
    animation: tabController!,
    builder: (context, child) {
      final currentIndex = tabController.index;
      
      // Stack ile iki FAB: Budget Add + Subscription Add
      return Stack(
        children: [
          // Budget FAB (Tab 0'da görünür)
          if (currentIndex == 0)
            Positioned(
              right: FabPositioning.getRightPosition(context),
              bottom: FabPositioning.getBottomPosition(context),
              child: _buildAddBudgetFAB(),
            ),
          
          // Subscription FAB (Tab 1'de görünür)
          if (currentIndex == 1)
            Positioned(
              right: FabPositioning.getRightPosition(context),
              bottom: FabPositioning.getBottomPosition(context),
              child: _buildAddSubscriptionFAB(),
            ),
          
          // AI Chat FAB (Her zaman görünür, üstte)
          Positioned(
            right: FabPositioning.getRightPosition(context),
            bottom: FabPositioning.getBottomPosition(context) + 60,
            child: QuickAddChatFAB(),
          ),
        ],
      );
    },
  );
}
```

```dart
/// Subscriptions view içeriği
Widget _buildSubscriptionsContent(bool isDark) {
  return Consumer<RecurringTransactionProvider>(
    builder: (context, provider, child) {
      final subscriptions = provider.activeSubscriptions;
      
      if (subscriptions.isEmpty) {
        return _buildSubscriptionsEmptyState(isDark);
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          return SubscriptionCard(
            subscription: subscriptions[index],
            onTap: () => _showSubscriptionDetail(subscriptions[index]),
            onToggle: (isActive) => _toggleSubscription(subscriptions[index], isActive),
          );
        },
      );
    },
  );
}
```

### 10.5. Özet Kartları

#### 10.5.1. Subscriptions Summary Card

```dart
Widget _buildSummaryCard(List<RecurringTransaction> subscriptions) {
  final totalMonthly = subscriptions.fold<double>(
    0, 
    (sum, sub) => sum + (sub.frequency == RecurringFrequency.monthly ? sub.amount : 0),
  );
  
  final totalYearly = subscriptions.fold<double>(
    0,
    (sum, sub) {
      switch (sub.frequency) {
        case RecurringFrequency.monthly:
          return sum + (sub.amount * 12);
        case RecurringFrequency.weekly:
          return sum + (sub.amount * 52);
        case RecurringFrequency.quarterly:
          return sum + (sub.amount * 4);
        case RecurringFrequency.yearly:
          return sum + sub.amount;
      }
    },
  );
  
  return Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [/* purple gradient */],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.subscriptions, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Aylık Toplam',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          CurrencyUtils.formatAmount(totalMonthly, currency),
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Yıllık: ${CurrencyUtils.formatAmount(totalYearly, currency)}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    ),
  );
}
```

```dart
/// Abonelikler için özet kartı (üstte gösterilir)
Widget _buildSubscriptionsSummaryCard(bool isDark) {
  return Consumer<RecurringTransactionProvider>(
    builder: (context, provider, child) {
      final subscriptions = provider.activeSubscriptions;
      
      // Hesaplamalar
      final totalMonthly = _calculateTotalMonthly(subscriptions);
      final totalYearly = _calculateTotalYearly(subscriptions);
      final activeCount = subscriptions.length;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF6E48AA), // Mor (koyu)
                    const Color(0xFF9D50BB),
                    const Color(0xFF6E48AA),
                  ]
                : [
                    const Color(0xFF9D50BB), // Mor (açık)
                    const Color(0xFF6E48AA),
                    const Color(0xFF8E44AD),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D50BB).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.subscriptions,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık Toplam',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '$activeCount Aktif Abonelik',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tutar
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.formatAmount(totalMonthly, currency),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ ay',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Yıllık projeksiyon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Yıllık: ${CurrencyUtils.formatAmount(totalYearly, currency)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Aylık toplam hesapla
double _calculateTotalMonthly(List<RecurringTransaction> subscriptions) {
  return subscriptions.fold<double>(0, (sum, sub) {
    switch (sub.frequency) {
      case RecurringFrequency.monthly:
        return sum + sub.amount;
      case RecurringFrequency.weekly:
        return sum + (sub.amount * 4.33); // Ortalama hafta sayısı
      case RecurringFrequency.quarterly:
        return sum + (sub.amount / 3); // 3 ayda bir
      case RecurringFrequency.yearly:
        return sum + (sub.amount / 12); // 12 ayda bir
    }
  });
}

/// Yıllık toplam hesapla
double _calculateTotalYearly(List<RecurringTransaction> subscriptions) {
  return subscriptions.fold<double>(0, (sum, sub) {
    switch (sub.frequency) {
      case RecurringFrequency.monthly:
        return sum + (sub.amount * 12);
      case RecurringFrequency.weekly:
        return sum + (sub.amount * 52);
      case RecurringFrequency.quarterly:
        return sum + (sub.amount * 4);
      case RecurringFrequency.yearly:
        return sum + sub.amount;
    }
  });
}
```

### 10.6. Empty State'ler

#### 10.6.1. Subscriptions Empty State

```dart
Widget _buildEmptyState() {
  return AnimatedEmptyState(
    icon: Icons.subscriptions_outlined,
    iconColor: Color(0xFF007AFF),
    title: 'Henüz abonelik eklemediniz',
    description: 'Netflix, Spotify gibi aboneliklerinizi ekleyerek otomatik takip edin',
    actionButton: ElevatedButton.icon(
      onPressed: () => _showAddSubscriptionForm(),
      icon: Icon(Icons.add),
      label: Text('Abonelik Ekle'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
    ),
  );
}
```

```dart
/// Abonelikler için empty state
Widget _buildSubscriptionsEmptyState(bool isDark) {
  final l10n = AppLocalizations.of(context)!;
  
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subscriptions_outlined,
            size: 80,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSubscriptionsYet,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFirstSubscriptionDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showAddSubscriptionForm(),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addSubscription,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 10.7. Dinamik FAB Yapısı

**Adım 1: Mevcut Kodu Refactor Et**
```dart
// 1. BudgetManagementPage içeriğini BudgetsTab'e taşı
// 2. Yeni SubscriptionsTab oluştur
// 3. BudgetManagementPage'i TabController ile sarmala
```

**Adım 2: Routing Güncelle**
```dart
// app_router.dart
GoRoute(
  path: '/budget-management',
  builder: (context, state) => BudgetManagementPage(
    initialTab: state.uri.queryParameters['tab'] ?? '0',
  ),
),
```

**Adım 3: Navigation Güncelle**
```dart
// Home screen'den budget sayfasına giderken tab belirtilebilir
context.push('/budget-management?tab=1'); // Direkt abonelikler tab'ına git
```

```dart
/// Dinamik FAB yapısı (segment'e göre değişir)
Widget _buildFABStack(bool isDark) {
  final fabSize = FabPositioning.getFabSize(context);
  final iconSize = FabPositioning.getIconSize(context);
  final rightPosition = FabPositioning.getRightPosition(context);
  final safeAreaBottom = MediaQuery.of(context).padding.bottom;
  final bottomPosition = safeAreaBottom + 16.0;
  
  return Stack(
    children: [
      // Budget Add FAB (sadece Budget view'da görünür)
      if (_selectedView == 0)
        Positioned(
          right: rightPosition,
          bottom: bottomPosition,
          child: GestureDetector(
            onTap: () => _showAddBudgetBottomSheet(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF232326).withOpacity(0.85)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.18)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDark ? Colors.white : Colors.black,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      
      // Subscription Add FAB (sadece Subscription view'da görünür)
      if (_selectedView == 1)
        Positioned(
          right: rightPosition,
          bottom: bottomPosition,
          child: GestureDetector(
            onTap: () => _showAddSubscriptionBottomSheet(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.9), // Subscription için mavi
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      
      // AI Chat FAB (her zaman görünür, üstte)
      Positioned(
        right: rightPosition,
        bottom: bottomPosition + 60,
        child: QuickAddChatFAB(
          customRight: rightPosition,
          customBottom: bottomPosition + 60,
        ),
      ),
    ],
  );
}

/// Subscription ekleme bottom sheet
void _showAddSubscriptionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddSubscriptionForm(
      onSubscriptionSaved: () {
        // Refresh subscriptions
        final provider = Provider.of<RecurringTransactionProvider>(
          context,
          listen: false,
        );
        provider.loadSubscriptions();
      },
    ),
  );
}
```

### 10.8. Animasyonlar ve Geçişler

```dart
/// İçerik geçiş animasyonu (opsiyonel)
Widget _buildAnimatedContent(Widget child) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (Widget child, Animation<double> animation) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
    child: child,
  );
}

// Kullanım:
Expanded(
  child: _buildAnimatedContent(
    _selectedView == 0
        ? _buildBudgetsContent(currentBudgets, isDark)
        : _buildSubscriptionsContent(isDark),
  ),
),
```

### 10.9. Migration Planı ve Adımlar

**Adım 1: State Variable Ekle**
```dart
class _BudgetManagementPageState extends State<BudgetManagementPage> {
  int _selectedView = 0; // 0 = Budgets, 1 = Subscriptions
  // ... mevcut state variables
}
```

**Adım 2: Segment Control Widget Ekle**
- `_buildSegmentControl()` metodunu ekle (yukarıdaki kod)
- 16px horizontal padding ile sayfa içeriğine yerleştir

**Adım 3: İçerik Widget'larını Ayır**
- Mevcut budget içeriğini `_buildBudgetsContent()` metoduna taşı
- Yeni `_buildSubscriptionsContent()` metodunu ekle

**Adım 4: Özet Kartlarını Ekle**
- `_buildSubscriptionsSummaryCard()` metodunu ekle
- Budget view'da genel bütçe kartını conditional render et

**Adım 5: FAB Yapısını Güncelle**
- `_buildFABStack()` metodunu segment'e göre dinamik yap
- Subscription Add FAB ekle

**Adım 6: Empty State'leri Ekle**
- `_buildSubscriptionsEmptyState()` metodunu ekle

**Adım 7: Localization Ekle**
```dart
// intl_tr.arb ve intl_en.arb
"budgetAndSubscriptions": "Bütçe ve Abonelikler",
"budgets": "Bütçeler",
"subscriptions": "Abonelikler",
```

### 10.10. Tam Implementasyon Özeti

**Gerekli Değişiklikler:**
1. ✅ State variable: `_selectedView`
2. ✅ Segment Control widget
3. ✅ İki ayrı içerik widget'ı
4. ✅ Dinamik özet kartları
5. ✅ Dinamik FAB'lar
6. ✅ Empty state'ler
7. ✅ Localization strings

**Mevcut Kod Korunur:**
- ✅ Genel bütçe kartı mantığı (sadece conditional render)
- ✅ Budget kartları (değişmez)
- ✅ Budget Add Sheet (değişmez)
- ✅ Page Controller (değişmez)

**Yeni Eklenenler:**
- ✅ Segment Control
- ✅ Subscriptions Summary Card
- ✅ Subscriptions Content
- ✅ Subscription Add Form
- ✅ Subscription Card widget'ı

### 10.11. Sonuç ve Öneri

**Segment Control yaklaşımı önerilir çünkü:**
- ✅ Minimal refactor (mevcut kod %90 korunur)
- ✅ Uygulama pattern'leriyle tutarlı (Stocks, Premium)
- ✅ iOS-style polish
- ✅ Kompakt ve kullanıcı dostu
- ✅ Hızlı implementasyon (1-2 gün)

**Tahmini Geliştirme Süresi:**
- Segment Control: 1-2 gün
- Subscriptions Content: 2-3 gün
- Toplam: 3-5 gün (Budget entegrasyonu ile)

---

## ✅ Sonuç

Bu tasarım:
- ✅ Mevcut uygulama tasarım diline %100 uyumlu
- ✅ Savings Goals ve Budget Management pattern'lerini takip ediyor
- ✅ iOS-style polish ve animasyonlar içeriyor
- ✅ Kullanıcı dostu ve sezgisel
- ✅ Responsive ve performanslı
- ✅ Budget sayfasına seamless entegre edilebilir

**Tahmini Geliştirme Süresi**: 5-7 gün (standalone) / 7-9 gün (budget entegrasyonu ile)
**UI/UX Complexity**: Orta (mevcut pattern'leri takip ettiği için)

