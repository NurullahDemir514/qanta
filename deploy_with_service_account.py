#!/usr/bin/env python3
"""
Firebase Remote Config Deployment - Service Account Key ile
En basit ve garantili yöntem!
"""

import json
import sys
import os
from pathlib import Path
import requests

def load_service_account_key():
    """Service account key dosyasını yükle"""
    # Olası konumlar
    possible_paths = [
        Path(__file__).parent / 'firebase-service-account.json',
        Path(__file__).parent / 'service-account-key.json',
        # Firebase'in otomatik oluşturduğu dosya adı
        Path(__file__).parent / 'qanta-de0b9-firebase-adminsdk-fbsvc-c8fb95eebc.json',
        # Genel pattern: qanta-*-firebase-adminsdk-*.json
        *list(Path(__file__).parent.glob('qanta-*-firebase-adminsdk-*.json')),
        Path.home() / 'Downloads' / 'firebase-service-account.json',
        Path.home() / 'Downloads' / 'service-account-key.json',
    ]
    
    for path in possible_paths:
        if path.exists():
            with open(path, 'r') as f:
                return json.load(f)
    
    print('❌ Service account key dosyası bulunamadı!')
    print('\n💡 Nasıl alınır:')
    print('   1. Firebase Console → Project Settings → Service Accounts')
    print('   2. "Generate new private key" butonuna tıkla')
    print('   3. JSON dosyasını indir')
    print('   4. Dosyayı proje root dizinine kopyala: firebase-service-account.json')
    print('\n📋 Alternatif: Dosyayı şu konumlara koyabilirsiniz:')
    for path in possible_paths:
        print(f'   - {path}')
    
    return None

def get_access_token(service_account):
    """Service account key ile access token al"""
    try:
        from google.oauth2 import service_account
        from google.auth.transport import requests as google_requests
        
        # Service account key'den credential oluştur
        credentials = service_account.Credentials.from_service_account_info(
            service_account,
            scopes=['https://www.googleapis.com/auth/firebase.remoteconfig']
        )
        
        # Token refresh et
        request = google_requests.Request()
        credentials.refresh(request)
        return credentials.token
    except ImportError as e:
        print('❌ Google Auth kütüphanesi yüklü değil!')
        print(f'   Hata: {e}')
        print('\n💡 Yüklemek için:')
        print('   pip install --upgrade google-auth google-auth-oauthlib google-auth-httplib2')
        return None
    except Exception as e:
        print(f'❌ Token alınamadı: {e}')
        import traceback
        traceback.print_exc()
        return None

def deploy_remote_config(project_id, access_token, config_path):
    """Remote Config'i yükle"""
    # Mevcut template'i al
    url = f'https://firebaseremoteconfig.googleapis.com/v1/projects/{project_id}/remoteConfig'
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json',
    }
    
    print('📥 Mevcut Remote Config template alınıyor...')
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f'❌ Template alınamadı: HTTP {response.status_code}')
        print(f'   Response: {response.text}')
        return False
    
    current_template = response.json()
    etag = response.headers.get('ETag')
    
    print('✅ Mevcut template alındı')
    print(f'   Mevcut parametre sayısı: {len(current_template.get("parameters", {}))}')
    print(f'   ETag: {etag}')
    print()
    
    # Yeni config'i oku
    with open(config_path, 'r') as f:
        new_config = json.load(f)
    
    # Parametreleri birleştir
    print('🔀 Parametreler birleştiriliyor...')
    merged_parameters = current_template.get('parameters', {}).copy()
    new_parameters = new_config.get('parameters', {})
    
    added_count = 0
    updated_count = 0
    
    for key, param_config in new_parameters.items():
        defaultValue = param_config.get('defaultValue', {}).get('value')
        valueType = param_config.get('valueType', 'STRING')
        description = param_config.get('description', '')
        
        if not defaultValue and defaultValue != '0' and defaultValue != '':
            continue
        
        if key in merged_parameters:
            merged_parameters[key]['defaultValue'] = {'value': str(defaultValue)}
            merged_parameters[key]['valueType'] = valueType
            if description:
                merged_parameters[key]['description'] = description
            updated_count += 1
        else:
            merged_parameters[key] = {
                'defaultValue': {'value': str(defaultValue)},
                'valueType': valueType,
            }
            if description:
                merged_parameters[key]['description'] = description
            added_count += 1
    
    print(f'✅ {added_count} yeni parametre eklendi')
    print(f'✅ {updated_count} parametre güncellendi')
    print(f'📊 Toplam parametre sayısı: {len(merged_parameters)}')
    print()
    
    # Template'i güncelle
    updated_template = {
        **current_template,
        'parameters': merged_parameters,
        'version': {
            **current_template.get('version', {}),
            'description': 'Amazon Rewards ve Points sistemi için Remote Config ayarları',
        },
    }
    
    # Template'i yükle
    print('📤 Remote Config yükleniyor...')
    headers['If-Match'] = etag
    response = requests.put(url, headers=headers, json=updated_template)
    
    if response.status_code == 200:
        result = response.json()
        print('\n✅ Remote Config başarıyla yüklendi!')
        print(f'   Version: {result.get("version", {}).get("versionNumber", "N/A")}')
        print(f'   Update Time: {result.get("version", {}).get("updateTime", "N/A")}')
        return True
    else:
        print(f'❌ Template yüklenemedi: HTTP {response.status_code}')
        print(f'   Response: {response.text}')
        return False

def main():
    print('🚀 Firebase Remote Config Deployment (Service Account)')
    print('=' * 60)
    print()
    
    # Service account key yükle
    print('🔑 Service account key yükleniyor...')
    service_account = load_service_account_key()
    
    if not service_account:
        sys.exit(1)
    
    project_id = service_account.get('project_id', 'qanta-de0b9')
    print(f'✅ Service account key yüklendi')
    print(f'📋 Project ID: {project_id}')
    print()
    
    # Access token al
    print('🔐 Access token alınıyor...')
    access_token = get_access_token(service_account)
    
    if not access_token:
        print('\n💡 Google Auth kütüphanesini yükleyin:')
        print('   pip install google-auth google-auth-oauthlib google-auth-httplib2')
        sys.exit(1)
    
    print('✅ Access token alındı')
    print()
    
    # Config dosyasını oku
    config_path = Path(__file__).parent / 'remote_config_merged.json'
    if not config_path.exists():
        print(f'❌ Config dosyası bulunamadı: {config_path}')
        sys.exit(1)
    
    # Remote Config'i yükle
    success = deploy_remote_config(project_id, access_token, config_path)
    
    if success:
        print()
        print('=' * 60)
        print('🎉 Tamamlandı!')
        print()
        print('📋 Sonraki Adımlar:')
        print('   1. Firebase Console → Remote Config')
        print('   2. Yeni parametreleri kontrol edin')
        print('   3. "Publish changes" butonuna tıklayın (gerekirse)')
        print()
    else:
        sys.exit(1)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\n\n⚠️  İptal edildi')
        sys.exit(1)
    except Exception as e:
        print(f'\n❌ Beklenmeyen hata: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

