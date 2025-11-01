# Interactive Tutorial - Implementation Plan

## 🎯 Hedef
Kullanıcı dostu, lokalize edilmiş, adım adım interaktif tutorial sistemi.

**Strateji**: İlk önce **TEK BİR ADIM** ile başla, beğenilirse diğer adımları ekle.

---

## 📋 KAPSAMLI TODO LİSTESİ

### **Phase 1: Foundation (Temel Yapı)** 

#### ✅ TODO 1.1: Tutorial Service Oluştur
**Dosya**: `lib/core/services/tutorial_service.dart`
**Süre**: 1 gün
**Açıklama**: Tutorial state management ve persistence

**Özellikler:**
- [ ] Tutorial tamamlandı mı kontrol et (SharedPreferences)
- [ ] Tutorial adımlarını yönet
- [ ] Tutorial skip edildi mi kaydet
- [ ] Tutorial'ı reset et (settings'ten)

**Kod Yapısı:**
```dart
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _tutorialSkippedKey = 'tutorial_skipped';
  
  static Future<bool> isTutorialCompleted() async { ... }
  static Future<void> completeTutorial() async { ... }
  static Future<void> skipTutorial() async { ... }
  static Future<void> resetTutorial() async { ... }
}
```

---

#### ✅ TODO 1.2: Tutorial Overlay Widget
**Dosya**: `lib/shared/widgets/tutorial_overlay.dart`
**Süre**: 2 gün
**Açıklama**: Spotlight efektli overlay widget

**Özellikler:**
- [ ] Dark overlay (arkaplanda karartma)
- [ ] Spotlight effect (hedef widget vurgulama)
- [ ] Tooltip card (açıklama kartı)
- [ ] Navigation buttons (Next, Previous, Skip)
- [ ] Smooth animations (fade, scale, slide)
- [ ] Responsive design (tüm ekran boyutları)
- [ ] Dark/Light theme support

**UI Gereksinimleri:**
- Modern iOS-style design
- Material 3 design system uyumu
- Smooth animations (300ms transitions)
- Accessibility support

---

#### ✅ TODO 1.3: Tutorial Step Model
**Dosya**: `lib/shared/models/tutorial_step_model.dart`
**Süre**: 0.5 gün
**Açıklama**: Tutorial adım veri modeli

**Özellikler:**
- [ ] Step ID (unique identifier)
- [ ] Target widget key (hangi widget vurgulanacak)
- [ ] Title (lokalize edilmiş)
- [ ] Description (lokalize edilmiş)
- [ ] Position (tooltip nerede görünsün)
- [ ] Icon (opsiyonel)
- [ ] Callback (adım tamamlandığında)

---

### **Phase 2: İlk Adım - FAB Tutorial** ⭐ (ŞİMDİLİK BUNA ODAKLANIYORUZ)

#### ✅ TODO 2.1: Localization Keys Ekle
**Dosyalar**: 
- `lib/l10n/intl_tr.arb`
- `lib/l10n/intl_en.arb`
- `lib/l10n/intl_de.arb`

**Süre**: 0.5 gün

**Eklenmesi Gereken Keys:**
```json
{
  "tutorialTitle": "Hızlı İşlem Ekleme",
  "@tutorialTitle": {
    "description": "Tutorial başlığı - FAB adımı"
  },
  "tutorialDescription": "Alt köşedeki butona tıklayarak harcama veya gelir ekleyebilirsiniz. AI chat ile konuşarak da ekleyebilirsiniz!",
  "@tutorialDescription": {
    "description": "Tutorial açıklaması - FAB adımı"
  },
  "tutorialNext": "Devam Et",
  "@tutorialNext": {
    "description": "Tutorial sonraki adım butonu"
  },
  "tutorialPrevious": "Geri",
  "@tutorialPrevious": {
    "description": "Tutorial önceki adım butonu"
  },
  "tutorialSkip": "Atla",
  "@tutorialSkip": {
    "description": "Tutorial atla butonu"
  },
  "tutorialGotIt": "Anladım!",
  "@tutorialGotIt": {
    "description": "Tutorial tamamlandı butonu"
  },
  "tutorialWelcome": "Hoş Geldiniz! 👋",
  "@tutorialWelcome": {
    "description": "Tutorial hoş geldin mesajı"
  },
  "tutorialSubtitle": "Size uygulamayı kısa bir turla tanıtacağız",
  "@tutorialSubtitle": {
    "description": "Tutorial alt başlık"
  }
}
```

**Lokalizasyonlar:**
- 🇹🇷 Türkçe (TR)
- 🇬🇧 English (EN)
- 🇩🇪 Deutsch (DE)

---

#### ✅ TODO 2.2: FAB Key Ekle
**Dosya**: `lib/modules/home/home_screen.dart` veya `lib/modules/transactions/widgets/transaction_fab.dart`
**Süre**: 0.5 gün

**Açıklama**: FAB widget'ına GlobalKey ekle (tutorial için)

**Değişiklik:**
```dart
// Home screen'de FAB'a key ekle
final GlobalKey _fabKey = GlobalKey();

// TransactionFab widget'ına key geçir
TransactionFab(
  key: _fabKey, // ← Tutorial için
  customBottom: baseBottom + 60,
)
```

---

#### ✅ TODO 2.3: Tutorial Trigger Logic
**Dosya**: `lib/modules/home/widgets/home_screen.dart` (ana home screen widget)
**Süre**: 1 gün

**Açıklama**: İlk açılışta tutorial göster

**Logic:**
```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // 1. Tutorial tamamlandı mı kontrol et
    final tutorialCompleted = await TutorialService.isTutorialCompleted();
    
    // 2. Tamamlanmadıysa göster
    if (!tutorialCompleted && mounted) {
      await _showTutorial();
    }
  });
}

Future<void> _showTutorial() async {
  // İlk adım: FAB tutorial
  final step = TutorialStep(
    id: 'fab_tutorial',
    targetKey: _fabKey,
    titleKey: 'tutorialTitle',
    descriptionKey: 'tutorialDescription',
    position: TutorialPosition.top,
  );
  
  await TutorialOverlay.show(
    context,
    steps: [step],
  );
}
```

---

#### ✅ TODO 2.4: Tutorial Overlay - Spotlight Painter
**Dosya**: `lib/shared/widgets/tutorial_overlay.dart`
**Süre**: 1.5 gün

**Açıklama**: Spotlight efektini implement et

**Teknik Detaylar:**
- CustomPainter kullan
- Target widget'ın pozisyonunu hesapla
- Dark overlay çiz (spotlight dışı)
- Cutout path oluştur (target widget çevresinde boş alan)
- Glow effect ekle (opsiyonel)
- Smooth animations

**Challenges:**
- GlobalKey'den RenderBox'a erişim
- Widget henüz render olmadıysa bekle
- Responsive positioning

---

#### ✅ TODO 2.5: Tutorial Tooltip Card
**Dosya**: `lib/shared/widgets/tutorial_overlay.dart`
**Süre**: 1 gün

**Açıklama**: Açıklama kartı widget'ı

**Tasarım Gereksinimleri:**
- Modern card design (rounded corners, shadow)
- Title + Description
- Icon (opsiyonel)
- Position: Top, Bottom, Left, Right, Center
- Arrow indicator (hedefe işaret eden ok)
- Responsive (küçük ekranlarda scroll)

**UI Specs:**
- Padding: 20px
- Border radius: 16px
- Shadow: Medium
- Font: Inter (Google Fonts)
- Colors: Theme colors (light/dark support)

---

#### ✅ TODO 2.6: Navigation Buttons
**Dosya**: `lib/shared/widgets/tutorial_overlay.dart`
**Süre**: 0.5 gün

**Açıklama**: İleri/Geri/Atla butonları

**Butonlar:**
- **Previous**: İlk adımda görünmez
- **Next**: Son adımda "Got it!" olur
- **Skip**: Her zaman görünür (alt sol köşe)

**Stil:**
- iOS-style buttons
- Smooth hover effects
- Disabled state support

---

#### ✅ TODO 2.7: Testing
**Süre**: 1 gün

**Test Senaryoları:**
- [ ] İlk açılışta tutorial gösteriliyor mu?
- [ ] Skip çalışıyor mu?
- [ ] Tutorial tamamlandıktan sonra tekrar gösterilmiyor mu?
- [ ] Dark/Light theme'de düzgün görünüyor mu?
- [ ] Farklı ekran boyutlarında çalışıyor mu?
- [ ] FAB vurgulanıyor mu (spotlight)?
- [ ] Tooltip doğru pozisyonda mı?
- [ ] Animations smooth mu?
- [ ] Localization çalışıyor mu?

---

## 🎨 İLK ADIM TASARIMI - FAB TUTORIAL

### **Hedef**: Transaction FAB (Floating Action Button) Tutorial

### **Görsel Tasarım**

```
┌─────────────────────────────────────┐
│                                     │
│  ╔═══════════════════════╗         │
│  ║                       ║         │
│  ║   [HOME SCREEN]       ║         │
│  ║                       ║         │
│  ║   [Balance Card]      ║         │
│  ║   [Transactions]      ║         │
│  ║                       ║         │
│  ║           ╔═══════╗   ║ ← Spotlight
│  ║           ║  [+]  ║   ║   (vurgulu)
│  ║           ╚═══════╝   ║
│  ║                       ║
│  ╚═══════════════════════╝         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  🎯 Hızlı İşlem Ekleme        │ │ ← Tooltip
│  │                                 │ │   Card
│  │  Alt köşedeki butona tıklayarak│ │
│  │  harcama veya gelir ekleyebilir│ │
│  │  siniz. AI chat ile konuşarak   │ │
│  │  da ekleyebilirsiniz!           │ │
│  │                                 │ │
│  │        [← Geri]  [Devam Et →]  │ │ ← Buttons
│  └───────────────────────────────┘ │
│                                     │
│           [Atla Tutorial]           │
└─────────────────────────────────────┘
```

### **Teknik Detaylar**

#### **Pozisyon:**
- **Spotlight**: FAB widget'ı (sağ alt köşe)
- **Tooltip**: FAB'ın üstünde (Top position)
- **Arrow**: Tooltip'ten FAB'a işaret eden ok

#### **Animations:**
1. **Overlay fade in**: 300ms
2. **Spotlight highlight**: 400ms pulse
3. **Tooltip slide up**: 400ms
4. **Button hover**: 150ms

#### **Responsive:**
- Küçük ekranlarda tooltip scroll edilebilir
- FAB pozisyonu ekran boyutuna göre ayarlanır
- Text font size responsive (flutter_screenutil)

---

### **Kullanıcı Akışı**

```
1. Kullanıcı ilk kez home screen'i açıyor
   ↓
2. 1-2 saniye sonra tutorial overlay gösteriliyor
   ↓
3. Arka plan kararıyor (dark overlay)
   ↓
4. FAB vurgulanıyor (spotlight effect + glow)
   ↓
5. Tooltip card slide up animasyonu ile görünüyor
   ↓
6. Kullanıcı "Devam Et" tıklıyor
   ↓
7. Tutorial tamamlanıyor
   ↓
8. Overlay kayboluyor (fade out)
   ↓
9. Tutorial tamamlandı kaydediliyor
   ↓
10. Bir daha gösterilmiyor
```

---

## 📐 UI/UX SPECIFICATIONS

### **Colors (Theme-based)**
- **Overlay**: `Colors.black.withOpacity(0.7)`
- **Spotlight Glow**: `Color(0xFF007AFF).withOpacity(0.3)`
- **Tooltip Card BG**: `Theme.of(context).cardColor`
- **Tooltip Text**: `Theme.of(context).colorScheme.onSurface`
- **Button Primary**: `Color(0xFF6D6D70)` (Qanta primary)
- **Button Text**: `Colors.white`

### **Typography**
- **Title**: Inter, 20sp, Bold
- **Description**: Inter, 14sp, Regular
- **Button**: Inter, 16sp, SemiBold

### **Spacing**
- Tooltip padding: 20px
- Tooltip margin from FAB: 16px
- Button spacing: 12px
- Arrow size: 12px

### **Animations**
- **Duration**: 300ms (standard), 400ms (complex)
- **Curve**: `Curves.easeInOut`
- **Spring**: `Curves.spring` (bounce effect için)

---

## 🔧 Implementation Steps (Sıralı)

### **Step 1**: Tutorial Service (1 gün)
```bash
# Dosya: lib/core/services/tutorial_service.dart
```

### **Step 2**: Localization Keys (0.5 gün)
```bash
# Dosyalar: lib/l10n/intl_*.arb
```

### **Step 3**: Tutorial Step Model (0.5 gün)
```bash
# Dosya: lib/shared/models/tutorial_step_model.dart
```

### **Step 4**: Tutorial Overlay Widget (2 gün)
```bash
# Dosya: lib/shared/widgets/tutorial_overlay.dart
# - Spotlight painter
# - Tooltip card
# - Navigation buttons
```

### **Step 5**: FAB Key Ekleme (0.5 gün)
```bash
# Dosya: lib/modules/home/home_screen.dart
# veya TransactionFab widget
```

### **Step 6**: Tutorial Trigger (1 gün)
```bash
# Dosya: lib/modules/home/widgets/home_screen.dart
```

### **Step 7**: Testing & Polish (1 gün)

**Toplam Süre**: ~6-7 gün

---

## ✅ Definition of Done (Başarı Kriterleri)

- [ ] İlk açılışta tutorial otomatik gösteriliyor
- [ ] FAB spotlight effect çalışıyor
- [ ] Tooltip doğru pozisyonda görünüyor
- [ ] Navigation butonları çalışıyor
- [ ] Skip functionality çalışıyor
- [ ] Tutorial tamamlandıktan sonra tekrar gösterilmiyor
- [ ] Dark/Light theme'de düzgün görünüyor
- [ ] Responsive (tüm ekran boyutları)
- [ ] Localization çalışıyor (TR/EN/DE)
- [ ] Smooth animations
- [ ] Accessibility support
- [ ] No performance issues

---

## 🚀 Sonraki Adımlar (İlk Adım Beğenilirse)

1. **Cards Section Tutorial**
   - Kart ekleme özelliğini tanıt

2. **Statistics Tab Tutorial**
   - Analytics özelliklerini tanıt

3. **AI Chat Tutorial**
   - AI özelliğini tanıt

4. **Budget Tutorial**
   - Budget management'ı tanıt

---

## 📝 Notes

- **Performance**: Tutorial overlay optimize edilmeli (render cost)
- **Accessibility**: Screen reader desteği eklenebilir
- **Analytics**: Tutorial completion rate track edilmeli
- **A/B Testing**: Farklı tutorial style'ları test edilebilir

---

**Status**: 📝 Ready for Implementation  
**Priority**: ⭐⭐⭐ High  
**Estimated Time**: 6-7 days

