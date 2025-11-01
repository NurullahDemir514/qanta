# Tutorial - İlk Adım Tasarımı: FAB Tutorial

## 🎯 Hedef

**İlk Adım**: Transaction FAB (Floating Action Button) Tutorial

Kullanıcıya "Hızlı İşlem Ekleme" özelliğini tanıtmak.

---

## 📐 Detaylı Tasarım

### **Ekran Görünümü**

```
╔═══════════════════════════════════════════╗
║                                           ║
║  ╔═════════════════════════════════════╗  ║
║  ║                                     ║  ║
║  ║  [Dark Overlay - %70 opacity]      ║  ║
║  ║                                     ║  ║
║  ║     ╔═══════════════════╗          ║  ║
║  ║     ║                   ║          ║  ║
║  ║     ║  HOME SCREEN       ║          ║  ║
║  ║     ║  (Normal görünüm)  ║          ║  ║
║  ║     ║                   ║          ║  ║
║  ║     ║  [Balance Card]    ║          ║  ║
║  ║     ║  [Transactions]   ║          ║  ║
║  ║     ║                   ║          ║  ║
║  ║     ║      ╔═══════╗    ║          ║  ║
║  ║     ║      ║  [+]  ║    ║ ← SPOTLIGHT
║  ║     ║      ║       ║    ║   (Glow)
║  ║     ║      ╚═══════╝    ║          ║  ║
║  ║     ║                   ║          ║  ║
║  ║     ╚═══════════════════╝          ║  ║
║  ║                                     ║  ║
║  ╚═════════════════════════════════════╝  ║
║                                           ║
║  ┌─────────────────────────────────────┐ ║
║  │  ╭───────────────────────────────╮  │ ║
║  │  │  🎯 Hızlı İşlem Ekleme       │  │ ║ ← TOOLTIP
║  │  │                               │  │ ║   CARD
║  │  │  Alt köşedeki butona tıklayarak│  │ ║
║  │  │  harcama veya gelir ekleyebilir│  │ ║
║  │  │  siniz. AI chat ile konuşarak │  │ ║
║  │  │  da ekleyebilirsiniz!         │  │ ║
║  │  │                               │  │ ║
║  │  │    [← Geri]  [Devam Et →]    │  │ ║
║  │  ╰───────────────────────────────╯  │ ║
║  └─────────────────────────────────────┘ ║
║                                           ║
║              [Atla Tutorial]             ║
╚═══════════════════════════════════════════╝
```

---

## 🎨 UI Specifications

### **1. Dark Overlay**
- **Color**: `Colors.black.withOpacity(0.7)`
- **Coverage**: Tüm ekran (spotlight dışı)
- **Animation**: Fade in (300ms)

### **2. Spotlight Effect**
- **Target**: FAB widget (TransactionFab)
- **Effect**: 
  - Cutout (boş alan) - FAB çevresinde 12px padding
  - Glow effect - `Color(0xFF007AFF).withOpacity(0.3)`
  - Blur radius: 20px
- **Animation**: Pulse (400ms, infinite loop)

### **3. Tooltip Card**
- **Position**: FAB'ın üstünde (Top)
- **Margin from FAB**: 16px
- **Width**: Screen width - 32px (16px margin each side)
- **Max Height**: 200px (scroll if needed)
- **Background**: `Theme.of(context).cardColor`
- **Border Radius**: 16px
- **Shadow**: 
  ```dart
  BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 20,
    offset: Offset(0, 4),
  )
  ```
- **Padding**: 20px all sides

### **4. Tooltip Content**

#### **Title:**
- **Text**: "Hızlı İşlem Ekleme"
- **Icon**: 🎯 (veya Icons.add_circle_outline)
- **Font**: Inter, 20sp, Bold
- **Color**: `Theme.of(context).colorScheme.onSurface`

#### **Description:**
- **Text**: "Alt köşedeki butona tıklayarak harcama veya gelir ekleyebilirsiniz. AI chat ile konuşarak da ekleyebilirsiniz!"
- **Font**: Inter, 14sp, Regular
- **Color**: `Theme.of(context).colorScheme.onSurface.withOpacity(0.7)`
- **Line Height**: 1.5

#### **Arrow Indicator:**
- **Direction**: Down (tooltip'ten FAB'a)
- **Size**: 12px
- **Color**: `Theme.of(context).cardColor`
- **Position**: Tooltip card'ın alt ortasında

### **5. Navigation Buttons**

#### **Previous Button:**
- **Text**: "Geri"
- **Style**: TextButton
- **Visibility**: İlk adımda görünmez
- **Color**: `Color(0xFF6D6D70)`

#### **Next Button:**
- **Text**: "Devam Et"
- **Style**: ElevatedButton
- **Color**: `Color(0xFF6D6D70)` (Qanta primary)
- **Text Color**: White
- **Visibility**: Her zaman görünür (son adımda "Anladım!" olur)

#### **Skip Button:**
- **Text**: "Atla Tutorial"
- **Style**: TextButton
- **Position**: Bottom center
- **Color**: `Color(0xFF8E8E93)` (neutral)
- **Visibility**: Her zaman görünür

---

## 🎬 Animations

### **Sequence:**
1. **Overlay Fade In** (300ms)
   - `Curves.easeInOut`
   
2. **Spotlight Pulse** (400ms, infinite)
   - Glow effect fade in/out
   - `Curves.easeInOut`
   
3. **Tooltip Slide Up** (400ms)
   - From bottom to position
   - `Curves.easeOut`
   
4. **Button Hover** (150ms)
   - Scale 1.0 → 1.05 on press
   - `Curves.easeInOut`

### **Exit Animations:**
1. **Tooltip Slide Down** (300ms)
2. **Overlay Fade Out** (300ms)

---

## 📱 Responsive Design

### **Small Screens (< 375px)**
- Tooltip width: 90% of screen
- Font sizes: -2sp
- Padding: 16px (instead of 20px)

### **Medium Screens (375px - 414px)**
- Standard design

### **Large Screens (> 414px)**
- Tooltip max width: 400px (centered)
- Larger font sizes: +2sp

---

## 🌍 Localization

### **Türkçe (TR)**
```json
{
  "tutorialTitle": "Hızlı İşlem Ekleme",
  "tutorialDescription": "Alt köşedeki butona tıklayarak harcama veya gelir ekleyebilirsiniz. AI chat ile konuşarak da ekleyebilirsiniz!",
  "tutorialNext": "Devam Et",
  "tutorialPrevious": "Geri",
  "tutorialSkip": "Atla Tutorial",
  "tutorialGotIt": "Anladım!"
}
```

### **English (EN)**
```json
{
  "tutorialTitle": "Quick Add Transaction",
  "tutorialDescription": "Tap the button in the bottom corner to add expenses or income. You can also use AI chat to add by talking!",
  "tutorialNext": "Continue",
  "tutorialPrevious": "Previous",
  "tutorialSkip": "Skip Tutorial",
  "tutorialGotIt": "Got it!"
}
```

### **Deutsch (DE)**
```json
{
  "tutorialTitle": "Transaktion schnell hinzufügen",
  "tutorialDescription": "Tippen Sie auf die Schaltfläche in der unteren Ecke, um Ausgaben oder Einkommen hinzuzufügen. Sie können auch den KI-Chat verwenden, um per Spracheingabe hinzuzufügen!",
  "tutorialNext": "Weiter",
  "tutorialPrevious": "Zurück",
  "tutorialSkip": "Tutorial überspringen",
  "tutorialGotIt": "Verstanden!"
}
```

---

## 🔧 Technical Implementation

### **Key Points:**
1. **GlobalKey Usage**: FAB widget'ına key ekle
2. **RenderBox Access**: Key'den RenderBox'a eriş
3. **Position Calculation**: FAB pozisyonunu hesapla
4. **CustomPainter**: Spotlight effect için
5. **Stack Widget**: Overlay için Stack kullan
6. **Ignore Pointer**: Dark overlay tıklanabilir olmalı (skip için)

### **Code Structure:**
```dart
Stack(
  children: [
    // 1. Dark overlay with spotlight cutout
    CustomPaint(
      painter: SpotlightPainter(targetKey: _fabKey),
    ),
    
    // 2. Tooltip card
    Positioned(
      top: fabPosition.y - tooltipHeight - 16,
      child: TutorialTooltipCard(...),
    ),
    
    // 3. Navigation buttons
    Positioned(
      bottom: 40,
      child: TutorialNavigationButtons(...),
    ),
    
    // 4. Skip button
    Positioned(
      bottom: 16,
      child: TutorialSkipButton(...),
    ),
  ],
)
```

---

## ✅ Success Criteria

- [ ] Tutorial ilk açılışta otomatik gösteriliyor
- [ ] FAB spotlight effect çalışıyor (cutout + glow)
- [ ] Tooltip card doğru pozisyonda (FAB üstü)
- [ ] Navigation butonları çalışıyor
- [ ] Skip button tutorial'ı kapatıyor
- [ ] Tutorial tamamlandıktan sonra tekrar gösterilmiyor
- [ ] Dark/Light theme'de düzgün görünüyor
- [ ] Responsive (tüm ekran boyutları)
- [ ] Localization çalışıyor (TR/EN/DE)
- [ ] Animations smooth (60fps)
- [ ] Performance OK (no lag)

---

## 🚀 Next Steps (İlk Adım Beğenilirse)

1. **Cards Section Tutorial** - Kart ekleme
2. **Statistics Tab Tutorial** - Analytics
3. **AI Chat Tutorial** - AI özelliği
4. **Budget Tutorial** - Budget management

---

**Status**: 📝 Design Ready  
**Ready for**: Implementation  
**Estimated Time**: 6-7 days for first step

