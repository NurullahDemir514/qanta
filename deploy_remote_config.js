#!/usr/bin/env node
/**
 * Firebase Remote Config Deployment Script (Node.js)
 * Amazon Rewards ve Points sistemi için Remote Config parametrelerini yükler
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK başlat
async function initializeFirebase() {
  try {
    // Service account key dosyası var mı kontrol et
    const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
    
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK başlatıldı (Service Account)');
    } else {
      // Application Default Credentials kullan (gcloud veya Firebase CLI ile login)
      admin.initializeApp();
      console.log('✅ Firebase Admin SDK başlatıldı (Application Default Credentials)');
    }
    
    return true;
  } catch (error) {
    console.error('❌ Firebase Admin SDK başlatılamadı:', error.message);
    console.log('\n💡 Çözüm:');
    console.log('   1. Firebase CLI ile login: firebase login');
    console.log('   2. Veya service account key ekle: firebase-service-account.json');
    return false;
  }
}

// Remote Config'i yükle
async function deployRemoteConfig(configPath) {
  try {
    // Config dosyasını oku
    const configJson = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configJson);
    
    // Remote Config template oluştur
    const remoteConfig = admin.remoteConfig();
    const template = remoteConfig.createTemplateFromJSON(configJson);
    
    // Template'i yükle
    console.log('📤 Remote Config yükleniyor...');
    const updatedTemplate = await remoteConfig.publishTemplate(template);
    
    console.log('✅ Remote Config başarıyla yüklendi!');
    console.log(`   Version: ${updatedTemplate.version.versionNumber}`);
    console.log(`   Update Time: ${updatedTemplate.version.updateTime}`);
    
    return true;
  } catch (error) {
    console.error('❌ Remote Config yüklenemedi:', error.message);
    
    if (error.code === 'permission-denied') {
      console.log('\n💡 Çözüm:');
      console.log('   Firebase projesine yazma yetkisine sahip olduğunuzdan emin olun');
      console.log('   firebase login --reauth');
    }
    
    return false;
  }
}

// Ana fonksiyon
async function main() {
  console.log('🚀 Firebase Remote Config Deployment (Node.js)');
  console.log('='.repeat(50));
  console.log();
  
  // Config dosyası yolu
  const configPath = path.join(__dirname, 'remote_config_merged.json');
  
  if (!fs.existsSync(configPath)) {
    console.error(`❌ Config dosyası bulunamadı: ${configPath}`);
    console.log('   Önce deploy_remote_config.py scriptini çalıştırın');
    process.exit(1);
  }
  
  // Firebase'i başlat
  const initialized = await initializeFirebase();
  if (!initialized) {
    process.exit(1);
  }
  
  console.log();
  
  // Remote Config'i yükle
  const deployed = await deployRemoteConfig(configPath);
  
  if (deployed) {
    console.log();
    console.log('='.repeat(50));
    console.log('🎉 Tamamlandı!');
    console.log();
    console.log('📋 Sonraki Adımlar:');
    console.log('   1. Firebase Console → Remote Config');
    console.log('   2. Yeni parametreleri kontrol edin');
    console.log('   3. Değişiklikler 1 saat içinde uygulamaya yansıyacak');
  } else {
    process.exit(1);
  }
}

// Script'i çalıştır
main().catch((error) => {
  console.error('❌ Beklenmeyen hata:', error);
  process.exit(1);
});

