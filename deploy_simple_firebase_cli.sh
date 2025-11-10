#!/bin/bash

# Firebase Remote Config Deployment - Basit Yöntem
# Mevcut config'i al, yeni parametreleri ekle, yükle

set -e

echo "🚀 Firebase Remote Config Deployment (Basit Yöntem)"
echo "=================================================="
echo ""

# Mevcut config'i al
echo "📥 Mevcut Remote Config alınıyor..."
firebase remoteconfig:get -o current_config.json

# Yeni config'i oku
echo "📖 Yeni config hazırlanıyor..."
python3 -c "
import json

# Mevcut config'i yükle
with open('current_config.json', 'r') as f:
    current = json.load(f)

# Yeni config'i yükle
with open('remote_config_merged.json', 'r') as f:
    new = json.load(f)

# Parametreleri birleştir
current_params = current.get('parameters', {})
new_params = new.get('parameters', {})

# Yeni parametreleri ekle
added = 0
for key, value in new_params.items():
    if key not in current_params:
        current_params[key] = value
        added += 1
        print(f'✅ {key} eklendi')

print(f'\n📊 {added} yeni parametre eklendi')

# Birleştirilmiş config'i kaydet
current['parameters'] = current_params
with open('final_config.json', 'w') as f:
    json.dump(current, f, indent=2)

print('✅ final_config.json hazırlandı')
"

echo ""
echo "📤 Firebase Console'dan yüklemek için:"
echo "   1. final_config.json dosyasını aç"
echo "   2. Firebase Console → Remote Config"
echo "   3. Her parametreyi manuel olarak ekle"
echo ""
echo "💡 VEYA Service Account Key ile otomatik yükle:"
echo "   1. Firebase Console → Project Settings → Service Accounts"
echo "   2. 'Generate new private key' → JSON indir"
echo "   3. Dosyayı firebase-service-account.json olarak kaydet"
echo "   4. python3 deploy_with_service_account.py"
echo ""

