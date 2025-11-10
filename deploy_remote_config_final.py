#!/usr/bin/env python3
"""
Firebase Remote Config Deployment Script
Firebase CLI'nın credential'larını kullanarak REST API ile yükler
"""

import json
import subprocess
import sys
import os
from pathlib import Path
import requests

def get_firebase_project_id():
    """Project ID'yi .firebaserc'den al"""
    firebaserc_path = Path(__file__).parent / '.firebaserc'
    if firebaserc_path.exists():
        with open(firebaserc_path, 'r') as f:
            firebaserc = json.load(f)
            return firebaserc.get('projects', {}).get('default', 'qanta-de0b9')
    return 'qanta-de0b9'

def get_firebase_access_token():
    """Firebase CLI'dan access token al"""
    try:
        # Firebase CLI token'ını al (Firebase CLI'nın internal token'ını kullan)
        # Alternatif: gcloud auth print-access-token kullan
        result = subprocess.run(
            ['gcloud', 'auth', 'print-access-token'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    
    # Eğer gcloud yoksa, Firebase CLI'nın credential'larını kullan
    # Firebase CLI genellikle token'ı ~/.config/firebase/token.json'da saklar
    token_path = Path.home() / '.config' / 'firebase' / 'token.json'
    if token_path.exists():
        try:
            with open(token_path, 'r') as f:
                token_data = json.load(f)
                # Firebase CLI token formatı farklı olabilir
                # Bu durumda manuel token almak gerekebilir
                print('⚠️  Firebase CLI token bulundu ama format kontrolü gerekli')
        except:
            pass
    
    print('❌ Access token alınamadı')
    print('\n💡 Çözüm:')
    print('   1. Google Cloud SDK yükle: brew install google-cloud-sdk')
    print('   2. Authentication yap: gcloud auth application-default login')
    print('   3. Veya Firebase Console\'dan 1 parametre ekle, sonra script\'i çalıştır')
    return None

def get_current_template(project_id, access_token):
    """Mevcut Remote Config template'ini al"""
    url = f'https://firebaseremoteconfig.googleapis.com/v1/projects/{project_id}/remoteConfig'
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json',
    }
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        return response.json(), response.headers.get('ETag')
    elif response.status_code == 404:
        print('❌ Remote Config template bulunamadı')
        print('   Firebase Console\'dan en az bir parametre ekleyin')
        return None, None
    else:
        print(f'❌ Template alınamadı: HTTP {response.status_code}')
        print(f'   Response: {response.text}')
        return None, None

def deploy_template(project_id, access_token, template, etag):
    """Remote Config template'ini yükle"""
    url = f'https://firebaseremoteconfig.googleapis.com/v1/projects/{project_id}/remoteConfig'
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json',
        'If-Match': etag,
    }
    
    response = requests.put(url, headers=headers, json=template)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f'❌ Template yüklenemedi: HTTP {response.status_code}')
        print(f'   Response: {response.text}')
        return None

def main():
    print('🚀 Firebase Remote Config Deployment')
    print('=' * 60)
    print()
    
    # Project ID al
    project_id = get_firebase_project_id()
    print(f'📋 Project ID: {project_id}')
    print()
    
    # Access token al
    print('🔐 Access token alınıyor...')
    access_token = get_firebase_access_token()
    
    if not access_token:
        print('\n💡 Alternatif Yöntem:')
        print('   Firebase Console → Remote Config')
        print('   En az bir parametre ekle (ör: test_param)')
        print('   Sonra bu script\'i tekrar çalıştır')
        sys.exit(1)
    
    print('✅ Access token alındı')
    print()
    
    # Config dosyasını oku
    config_path = Path(__file__).parent / 'remote_config_merged.json'
    if not config_path.exists():
        print(f'❌ Config dosyası bulunamadı: {config_path}')
        print('   Önce deploy_remote_config.py scriptini çalıştırın')
        sys.exit(1)
    
    with open(config_path, 'r') as f:
        new_config = json.load(f)
    
    print(f'📖 Config dosyası okundu: {config_path}')
    print(f'   Yeni parametre sayısı: {len(new_config.get("parameters", {}))}')
    print()
    
    # Mevcut template'i al
    print('📥 Mevcut Remote Config template alınıyor...')
    current_template, etag = get_current_template(project_id, access_token)
    
    if not current_template:
        sys.exit(1)
    
    print('✅ Mevcut template alındı')
    print(f'   Mevcut parametre sayısı: {len(current_template.get("parameters", {}))}')
    print(f'   ETag: {etag}')
    print()
    
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
    result = deploy_template(project_id, access_token, updated_template, etag)
    
    if result:
        print('\n✅ Remote Config başarıyla yüklendi!')
        print(f'   Version: {result.get("version", {}).get("versionNumber", "N/A")}')
        print(f'   Update Time: {result.get("version", {}).get("updateTime", "N/A")}')
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

