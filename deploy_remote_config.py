#!/usr/bin/env python3
"""
Firebase Remote Config Deployment Script
Amazon Rewards ve Points sistemi için Remote Config parametrelerini yükler
"""

import json
import sys
import subprocess
import os
from pathlib import Path

def get_firebase_access_token():
    """Firebase access token'ı al"""
    try:
        # Firebase CLI ile access token al
        result = subprocess.run(
            ['firebase', 'login:ci'],
            capture_output=True,
            text=True,
            check=False
        )
        
        # Alternatif: firebase use ile project ID al, sonra gcloud ile token al
        # Ya da kullanıcıdan manuel token iste
        print("⚠️  Firebase access token gerekiyor")
        print("   İki yöntem:")
        print("   1. Firebase Console → Project Settings → Service Accounts → Generate New Private Key")
        print("   2. Veya firebase login:ci komutunu çalıştırın")
        return None
    except Exception as e:
        print(f"❌ Token alma hatası: {e}")
        return None

def merge_remote_config(current_config_path, new_config_path, output_path):
    """Mevcut ve yeni Remote Config'i birleştir"""
    # Mevcut config'i yükle
    if os.path.exists(current_config_path):
        with open(current_config_path, 'r', encoding='utf-8') as f:
            current_config = json.load(f)
    else:
        current_config = {"parameters": {}}
    
    # Yeni config'i yükle
    with open(new_config_path, 'r', encoding='utf-8') as f:
        new_config = json.load(f)
    
    # Parametreleri birleştir (yeni parametreler mevcutları günceller)
    merged_parameters = current_config.get("parameters", {}).copy()
    merged_parameters.update(new_config.get("parameters", {}))
    
    # Birleştirilmiş config
    merged_config = {
        "parameters": merged_parameters,
        "version": new_config.get("version", {
            "versionNumber": "1",
            "updateTime": "2025-01-20T00:00:00Z",
            "updateUser": {
                "email": "qanta@remote-config.com"
            },
            "description": "Amazon Rewards ve Points sistemi için Remote Config ayarları",
            "updateOrigin": "REST_API",
            "updateType": "INCREMENTAL_UPDATE"
        })
    }
    
    # Kaydet
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(merged_config, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Birleştirilmiş config kaydedildi: {output_path}")
    return merged_config

def main():
    print("🚀 Firebase Remote Config Deployment")
    print("=" * 50)
    print()
    
    # Dosya yolları
    script_dir = Path(__file__).parent
    current_config_path = script_dir / "remote_config_current.json"
    new_config_path = script_dir / "firebase_remote_config_amazon_rewards_points.json"
    merged_config_path = script_dir / "remote_config_merged.json"
    
    # Dosya kontrolü
    if not new_config_path.exists():
        print(f"❌ Yeni config dosyası bulunamadı: {new_config_path}")
        sys.exit(1)
    
    # Mevcut config'i çek
    print("📥 Mevcut Remote Config çekiliyor...")
    try:
        subprocess.run(
            ['firebase', 'remoteconfig:get', '-o', str(current_config_path)],
            check=True,
            capture_output=True
        )
        print("✅ Mevcut config çekildi")
    except subprocess.CalledProcessError:
        print("⚠️  Mevcut config çekilemedi (devam ediliyor...)")
        current_config_path = None
    
    # Config'leri birleştir
    print()
    print("🔀 Config'ler birleştiriliyor...")
    merged_config = merge_remote_config(
        current_config_path if current_config_path and current_config_path.exists() else None,
        new_config_path,
        merged_config_path
    )
    
    # Parametre sayısı
    param_count = len(merged_config.get("parameters", {}))
    print(f"📊 Toplam parametre sayısı: {param_count}")
    print()
    
    # Yeni parametreleri listele
    if current_config_path and current_config_path.exists():
        with open(current_config_path, 'r', encoding='utf-8') as f:
            current_params = set(json.load(f).get("parameters", {}).keys())
    else:
        current_params = set()
    
    new_params = set(merged_config.get("parameters", {}).keys())
    added_params = new_params - current_params
    
    if added_params:
        print("🆕 Eklenen yeni parametreler:")
        for param in sorted(added_params):
            print(f"   - {param}")
        print()
    
    # Firebase REST API ile yükleme talimatları
    print("=" * 50)
    print("📤 Remote Config'i yüklemek için:")
    print()
    print("Yöntem 1: Firebase Console (Önerilen)")
    print("   1. Firebase Console → Remote Config")
    print("   2. 'remote_config_merged.json' dosyasını aç")
    print("   3. Her parametreyi manuel olarak ekle veya")
    print("   4. Firebase Console → Remote Config → '...' → 'Import from file'")
    print()
    print("Yöntem 2: Firebase REST API")
    print("   curl -X PUT https://firebaseremoteconfig.googleapis.com/v1/projects/YOUR_PROJECT_ID/remoteConfig \\")
    print("     -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \\")
    print("     -H 'Content-Type: application/json' \\")
    print("     -d @remote_config_merged.json")
    print()
    print("Yöntem 3: Firebase CLI (manuel)")
    print("   Firebase CLI'da Remote Config set komutu yok.")
    print("   Ancak mevcut config'i çekip, yeni parametreleri ekleyip")
    print("   Firebase Console'dan import edebilirsiniz.")
    print()
    print(f"✅ Birleştirilmiş config hazır: {merged_config_path}")
    print()

if __name__ == "__main__":
    main()

