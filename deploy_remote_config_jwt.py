#!/usr/bin/env python3
"""
Firebase Remote Config Deployment - JWT Token ile
Service account key'den direkt JWT token oluşturur
"""

import json
import sys
import time
from pathlib import Path
import requests
import jwt
from datetime import datetime, timedelta

def load_service_account_key():
    """Service account key dosyasını yükle"""
    possible_paths = [
        Path(__file__).parent / 'firebase-service-account.json',
        Path(__file__).parent / 'service-account-key.json',
        Path(__file__).parent / 'qanta-de0b9-firebase-adminsdk-fbsvc-c8fb95eebc.json',
        *list(Path(__file__).parent.glob('qanta-*-firebase-adminsdk-*.json')),
    ]
    
    for path in possible_paths:
        if path.exists():
            with open(path, 'r') as f:
                return json.load(f)
    
    print('❌ Service account key dosyası bulunamadı!')
    return None

def create_jwt_token(service_account):
    """Service account key'den JWT token oluştur"""
    try:
        # JWT token oluştur (kısa ömürlü: 1 saat)
        now = datetime.utcnow()
        # 55 dakika sonra expire (güvenlik için)
        expiry = now + timedelta(minutes=55)
        
        payload = {
            'iss': service_account.get('client_email'),
            'sub': service_account.get('client_email'),
            'aud': 'https://oauth2.googleapis.com/token',
            'iat': int(now.timestamp()),
            'exp': int(expiry.timestamp()),
            'scope': 'https://www.googleapis.com/auth/firebase.remoteconfig',
        }
        
        # Private key ile imzala
        private_key = service_account.get('private_key')
        if not private_key:
            print('❌ Private key bulunamadı!')
            return None
        
        # Private key'i formatla (newline'ları düzelt)
        private_key = private_key.replace('\\n', '\n')
        
        token = jwt.encode(payload, private_key, algorithm='RS256')
        # jwt.encode Python dict döner, string'e çevir
        if isinstance(token, bytes):
            token = token.decode('utf-8')
        return token
    except ImportError:
        print('❌ PyJWT kütüphanesi yüklü değil!')
        print('\n💡 Yüklemek için:')
        print('   pip install PyJWT cryptography')
        return None
    except Exception as e:
        print(f'❌ JWT token oluşturulamadı: {e}')
        import traceback
        traceback.print_exc()
        return None

def exchange_jwt_for_access_token(jwt_token):
    """JWT token'ı access token'a çevir"""
    try:
        response = requests.post(
            'https://oauth2.googleapis.com/token',
            data={
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': jwt_token,
            },
            headers={
                'Content-Type': 'application/x-www-form-urlencoded',
            },
        )
        
        if response.status_code == 200:
            data = response.json()
            return data.get('access_token')
        else:
            print(f'❌ Access token alınamadı: HTTP {response.status_code}')
            print(f'   Response: {response.text}')
            return None
    except Exception as e:
        print(f'❌ Access token exchange hatası: {e}')
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
    print('🚀 Firebase Remote Config Deployment (JWT Token)')
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
    
    # JWT token oluştur
    print('🔐 JWT token oluşturuluyor...')
    jwt_token = create_jwt_token(service_account)
    
    if not jwt_token:
        print('\n💡 PyJWT kütüphanesini yükleyin:')
        print('   pip install PyJWT cryptography')
        sys.exit(1)
    
    print('✅ JWT token oluşturuldu')
    print()
    
    # Access token al
    print('🔐 Access token alınıyor...')
    access_token = exchange_jwt_for_access_token(jwt_token)
    
    if not access_token:
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

