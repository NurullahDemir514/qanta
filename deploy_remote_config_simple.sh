#!/bin/bash

# Firebase Remote Config Toplu Yükleme Script
# Bu script tüm parametreleri otomatik olarak yükler

set -e

echo "🚀 Firebase Remote Config Toplu Yükleme"
echo "========================================"
echo ""

# Firebase CLI kontrolü
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI yüklü değil!"
    echo "   Yüklemek için: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI bulundu"
echo ""

# Firebase login kontrolü
echo "🔐 Firebase authentication kontrol ediliyor..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Firebase'e giriş yapılmamış"
    echo "   Giriş yapmak için: firebase login"
    exit 1
fi

echo "✅ Firebase'e giriş yapılmış"
echo ""

# Mevcut Remote Config'i yedekle
echo "📦 Mevcut Remote Config yedekleniyor..."
BACKUP_FILE="remote_config_backup_$(date +%Y%m%d_%H%M%S).json"
firebase remoteconfig:get -o "$BACKUP_FILE" 2>&1 || echo "⚠️  Yedekleme başarısız (devam ediliyor...)"
echo ""

# Node.js script'i çalıştır
echo "📤 Remote Config yükleniyor..."
echo "   Script: functions/deploy_remote_config_bulk.js"
echo ""

cd functions

# Node.js kontrolü
if ! command -v node &> /dev/null; then
    echo "❌ Node.js yüklü değil!"
    exit 1
fi

# Script'i çalıştır
node deploy_remote_config_bulk.js

echo ""
echo "✅ Tamamlandı!"
echo ""
echo "📋 Sonraki Adımlar:"
echo "   1. Firebase Console → Remote Config"
echo "   2. Yeni parametreleri kontrol edin"
echo "   3. 'Publish changes' butonuna tıklayın (gerekirse)"
echo ""

