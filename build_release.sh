#!/bin/bash

# Qanta App - Release Build Script
# Bu script uygulama için production-ready build oluşturur

echo "🚀 Qanta Release Build Başlıyor..."
echo "=================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Hata kontrolü
set -e

# 1. Clean
echo "🧹 Temizlik yapılıyor..."
flutter clean
cd android && ./gradlew clean && cd ..
echo -e "${GREEN}✓ Temizlik tamamlandı${NC}"
echo ""

# 2. Dependencies
echo "📦 Bağımlılıklar yükleniyor..."
flutter pub get
echo -e "${GREEN}✓ Bağımlılıklar yüklendi${NC}"
echo ""

# 3. Analyze
echo "🔍 Kod analizi yapılıyor..."
flutter analyze --no-fatal-infos
echo -e "${GREEN}✓ Kod analizi tamamlandı${NC}"
echo ""

# 4. Test
echo "🧪 Testler çalıştırılıyor..."
if flutter test; then
    echo -e "${GREEN}✓ Testler başarılı${NC}"
else
    echo -e "${YELLOW}⚠ Bazı testler başarısız oldu, devam ediliyor...${NC}"
fi
echo ""

# 5. Build App Bundle (Önerilen)
echo "📱 App Bundle oluşturuluyor..."
flutter build appbundle --release
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo -e "${GREEN}✓ App Bundle oluşturuldu${NC}"
    echo "  Dosya: $AAB_PATH"
    echo "  Boyut: $AAB_SIZE"
else
    echo -e "${RED}✗ App Bundle oluşturulamadı${NC}"
    exit 1
fi
echo ""

# 6. Build APK (Test için)
echo "📱 APK oluşturuluyor..."
flutter build apk --release
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✓ APK oluşturuldu${NC}"
    echo "  Dosya: $APK_PATH"
    echo "  Boyut: $APK_SIZE"
else
    echo -e "${YELLOW}⚠ APK oluşturulamadı${NC}"
fi
echo ""

# 7. Özet
echo "=================================="
echo -e "${GREEN}🎉 Build Başarılı!${NC}"
echo "=================================="
echo ""
echo "📦 Çıktılar:"
echo "  • App Bundle: $AAB_PATH ($AAB_SIZE)"
if [ -f "$APK_PATH" ]; then
    echo "  • APK: $APK_PATH ($APK_SIZE)"
fi
echo ""
echo "🚀 Sonraki Adımlar:"
echo "  1. Test cihazda çalıştır: flutter install --release"
echo "  2. Play Console'a yükle: $AAB_PATH"
echo "  3. Detaylı bilgi için: PLAY_STORE_READY.md"
echo ""
