#!/bin/bash

# Firebase Remote Config Deployment Script
# Bu script, Amazon Rewards ve Points sistemi için Remote Config parametrelerini yükler

set -e

echo "🚀 Firebase Remote Config Deployment Başlatılıyor..."
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
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Firebase'e giriş yapılmamış"
    echo "   Giriş yapmak için: firebase login"
    exit 1
fi

echo "✅ Firebase'e giriş yapılmış"
echo ""

# Mevcut Remote Config'i yedekle
echo "📦 Mevcut Remote Config yedekleniyor..."
firebase remoteconfig:get -o remote_config_backup_$(date +%Y%m%d_%H%M%S).json || echo "⚠️  Yedekleme başarısız (devam ediliyor...)"
echo ""

# Yeni Remote Config'i yükle
echo "📤 Yeni Remote Config yükleniyor..."
echo "   Dosya: firebase_remote_config_amazon_rewards_points.json"
echo ""

firebase remoteconfig:set firebase_remote_config_amazon_rewards_points.json

echo ""
echo "✅ Remote Config başarıyla yüklendi!"
echo ""
echo "📋 Sonraki Adımlar:"
echo "   1. Firebase Console'da Remote Config'i kontrol edin"
echo "   2. 'Publish changes' butonuna tıklayın"
echo "   3. Değişiklikler 1 saat içinde uygulamaya yansıyacak"
echo ""
echo "🎉 Tamamlandı!"

