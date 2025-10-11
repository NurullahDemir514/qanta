# 🎨 Figma Tasarım Promptu - Qanta Play Store Görselleri

## 📐 1. Feature Graphic (1024 x 500 px)

### Genel Konsept
Modern, minimal ve profesyonel bir finans uygulaması feature graphic tasarımı. Gradient ve glassmorphism etkilerini kullanarak premium bir görünüm.

---

### Layout & Struktur

```
┌────────────────────────────────────────────────────────────┐
│                                                              │
│  [APP ICON]          QANTA                                  │
│   200x200           Finans Yönetimi                         │
│                                                              │
│                     Hisselerinizi ve harcamalarınızı        │
│                     tek yerden yönetin                      │
│                                                              │
│                                          [Chart Icon]        │
└────────────────────────────────────────────────────────────┘
    300px                      724px
```

---

### Detaylı Tasarım Özellikleri

#### Arka Plan
- **Type:** Linear Gradient
- **Angle:** 135° (diagonal)
- **Color 1:** `#0F172A` (Deep Navy) - Top Left
- **Color 2:** `#1E293B` (Slate Gray) - Center
- **Color 3:** `#334155` (Light Slate) - Bottom Right
- **Alternative:** Blue gradient
  - Color 1: `#1E3A8A` (Dark Blue)
  - Color 2: `#3B82F6` (Blue)
  - Color 3: `#60A5FA` (Light Blue)

#### Dekoratif Elementler (Background)
- **Subtle Shapes:** 
  - 3-4 adet büyük circle/blob shapes
  - Opacity: 5-8%
  - Blur: 80-120px
  - Colors: White veya #60A5FA
  - Position: Random, overlapping

#### Sol Bölüm (0-300px)
- **App Icon:**
  - Size: 200 x 200 px
  - Position: Centered vertically & horizontally (50px, 150px)
  - Border Radius: 50px (rounded square)
  - Shadow: 
    - Color: `#000000` 40% opacity
    - Blur: 40px
    - Offset: (0, 20px)
  - Optional: Glassmorphism container
    - Background: White 10% opacity
    - Backdrop blur: 20px
    - Border: 1px white 20% opacity
    - Padding: 30px

#### Sağ Bölüm (300-1024px)

**Ana Başlık - "QANTA":**
- Font: Inter/SF Pro Display Bold
- Size: 72pt
- Weight: 700 (Bold)
- Color: `#FFFFFF`
- Position: 350px, 150px
- Letter Spacing: -2px
- Text Shadow:
  - Color: `#000000` 30% opacity
  - Blur: 20px
  - Offset: (0, 4px)

**Alt Başlık - "Finans Yönetimi":**
- Font: Inter/SF Pro Display Regular
- Size: 36pt
- Weight: 400 (Regular)
- Color: `#FFFFFF` 85% opacity
- Position: 350px, 230px
- Letter Spacing: -0.5px

**Tagline - "Hisselerinizi ve harcamalarınızı tek yerden yönetin":**
- Font: Inter/SF Pro Text Light
- Size: 20pt
- Weight: 300 (Light)
- Color: `#FFFFFF` 65% opacity
- Position: 350px, 290px
- Max Width: 550px
- Line Height: 1.4

**Dekoratif Icon (Opsiyonel):**
- Chart/Graph icon veya finance-related icon
- Size: 120 x 120 px
- Position: 870px, 350px (bottom right)
- Opacity: 25%
- Color: White
- Style: Line icon, minimal

---

### 🎨 Alternative Color Schemes

#### Şık & Minimal (Önerilen)
- Background: Dark gradient (`#0F172A` → `#1E293B` → `#334155`)
- Text: White with varying opacity
- Accent: `#60A5FA` (Blue accent shapes)

#### Premium Blue
- Background: Blue gradient (`#1E3A8A` → `#3B82F6` → `#60A5FA`)
- Text: White
- Accent: `#FBBF24` (Gold/Yellow accent)

#### Modern Purple
- Background: Purple gradient (`#581C87` → `#7C3AED` → `#A78BFA`)
- Text: White
- Accent: `#34D399` (Green accent)

#### Clean & Professional
- Background: Light gradient (`#F8FAFC` → `#E2E8F0`)
- Text: `#0F172A` (Dark blue/black)
- Accent: `#3B82F6` (Blue)

---

## 📱 2. Phone Screenshots Mockup Tasarımı

### Mockup Container (1080 x 2340 px)

#### Arka Plan
- Solid color: `#F8FAFC` (Light gray) veya `#1E293B` (Dark)
- Gradient alternative:
  - Top: `#F8FAFC`
  - Bottom: `#E2E8F0`

#### Phone Device Frame
- Model: iPhone 15 Pro veya Samsung Galaxy S24
- Device frame color: Black/Midnight
- Position: Centered (90px padding on sides)
- Shadow:
  - Color: `#000000` 20% opacity
  - Blur: 60px
  - Offset: (0, 30px)

#### Screenshot İçi
- Gerçek app screenshot'ları
- Fit: Fill container
- Corner Radius: Match device (55px for iPhone 15 Pro)

#### Opsiyonel: Text Overlay
- **Bottom Text (Başlık):**
  - Font: Inter Bold
  - Size: 48pt
  - Color: `#0F172A` veya `#FFFFFF` (bg'ye göre)
  - Position: Bottom center, 80px from bottom
  - Text examples:
    - "Net Değerinizi Takip Edin"
    - "Hisselerinizi Yönetin"
    - "Bütçenizi Kontrol Edin"
    - "Detaylı Raporlar"
    - "Güvenli & Kolay"

---

## 🎯 Figma Workflow

### Adım 1: Frame Oluştur
```
1. Create Frame (F)
2. Name: "Feature Graphic - Qanta"
3. Width: 1024px
4. Height: 500px
```

### Adım 2: Background
```
1. Rectangle (R)
2. Fill: Linear Gradient
3. Apply gradient colors and angle
4. Lock layer
```

### Adım 3: Dekoratif Shapes
```
1. Ellipse (O)
2. Size: 400-800px
3. Fill: White 5-8% opacity
4. Effects: Layer Blur 80-120px
5. Duplicate and position randomly
```

### Adım 4: App Icon
```
1. Import app_icon_512.png
2. Size: 200 x 200px
3. Position: x:50px, y:150px
4. Corner Radius: 50px
5. Effects: Drop Shadow (blur:40, y:20, opacity:40%)
```

### Adım 5: Typography
```
1. Text tool (T)
2. Add "QANTA", "Finans Yönetimi", tagline
3. Apply font properties (size, weight, color, opacity)
4. Position according to specs
5. Apply text shadow
```

### Adım 6: Export
```
1. Select frame
2. Export settings:
   - Format: PNG
   - Scale: 1x
   - Quality: Best
3. Export
```

---

## 📦 Export Settings

### Feature Graphic
- Format: PNG (24-bit, no alpha)
- Size: 1024 x 500 px
- Quality: 100%
- Max file size: 15 MB

### Phone Screenshots
- Format: PNG
- Size: 1080 x 2340 px (or device native)
- Quality: 100%
- Max file size: 8 MB each

---

## 🔗 Useful Resources

**Fonts:**
- Inter: https://fonts.google.com/specimen/Inter
- SF Pro: https://developer.apple.com/fonts/

**Icons:**
- Heroicons: https://heroicons.com/
- Lucide: https://lucide.dev/
- Phosphor Icons: https://phosphoricons.com/

**Mockups:**
- Device frames: https://www.figma.com/community/search?model_type=files&q=device%20mockup
- iPhone 15 Pro: https://www.figma.com/community/file/1296212419537166610

**Gradients:**
- Coolors: https://coolors.co/gradient-maker
- Mesh Gradients: https://meshgradient.com/

**Inspiration:**
- Dribbble: https://dribbble.com/tags/play-store
- Behance: https://www.behance.net/search?search=google+play

---

## ✅ Checklist

- [ ] Frame created (1024 x 500 px)
- [ ] Background gradient applied
- [ ] Dekorative shapes added (subtle)
- [ ] App icon imported and positioned
- [ ] Typography added (title, subtitle, tagline)
- [ ] Text shadows applied
- [ ] Optional decorative icon added
- [ ] Export settings configured
- [ ] PNG exported
- [ ] File size checked (< 15 MB)
- [ ] Visual quality verified

---

## 💡 Pro Tips

1. **Consistency:** Use same colors across feature graphic and screenshots
2. **Legibility:** Test on small screens - text must be readable at thumbnail size
3. **Brand:** Use your brand colors if you have established ones
4. **Contrast:** High contrast between text and background
5. **Simplicity:** Don't overcrowd - less is more
6. **Testing:** Export and view at actual size (zoom out in Figma)
7. **Mockups:** Use real device mockups for screenshots
8. **Updates:** Keep source Figma file for future updates

---

## 🎬 Quick Start Summary

**5-Minute Version:**
1. Create 1024x500 frame
2. Add dark gradient background (#0F172A → #334155)
3. Place app icon (200x200, left side)
4. Add "QANTA" text (72pt, white, bold, right side)
5. Add tagline (20pt, white 65%, below title)
6. Add subtle blur shapes (optional)
7. Export PNG

**Done! 🎉**
