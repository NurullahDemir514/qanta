#!/usr/bin/env node
/**
 * Firebase Remote Config Bulk Deployment Script
 * Tüm parametreleri tek seferde yükler (REST API kullanarak)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK başlat
async function initializeFirebase() {
  try {
    // Project ID'yi .firebaserc'den oku
    const firebasercPath = path.join(__dirname, '..', '.firebaserc');
    let projectId = null;
    
    if (fs.existsSync(firebasercPath)) {
      const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, 'utf8'));
      const projects = firebaserc.projects || {};
      projectId = projects.default || projects.production || Object.values(projects)[0];
    }
    
    // Service account key dosyasını bul
    const serviceAccountPaths = [
      path.join(__dirname, '..', 'firebase-service-account.json'),
      path.join(__dirname, '..', 'service-account-key.json'),
      path.join(__dirname, '..', 'qanta-de0b9-firebase-adminsdk-fbsvc-c8fb95eebc.json'),
      ...fs.readdirSync(path.join(__dirname, '..'))
        .filter(f => f.startsWith('qanta-') && f.endsWith('.json') && f.includes('firebase-adminsdk'))
        .map(f => path.join(__dirname, '..', f)),
    ];
    
    let serviceAccount = null;
    for (const saPath of serviceAccountPaths) {
      if (fs.existsSync(saPath)) {
        try {
          serviceAccount = require(saPath);
          console.log(`✅ Service account key bulundu: ${path.basename(saPath)}`);
          if (!projectId && serviceAccount.project_id) {
            projectId = serviceAccount.project_id;
          }
          break;
        } catch (e) {
          // Devam et
        }
      }
    }
    
    if (!projectId) {
      console.error('❌ Project ID bulunamadı. .firebaserc dosyasını kontrol edin.');
      return false;
    }
    
    // Service account key ile başlat
    if (serviceAccount) {
      try {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: projectId,
        });
        console.log(`✅ Firebase Admin SDK başlatıldı (Service Account, Project ID: ${projectId})`);
        return true;
      } catch (error) {
        console.error('❌ Firebase Admin SDK başlatılamadı (Service Account):', error.message);
      }
    }
    
    // Application Default Credentials kullan (fallback)
    try {
      admin.initializeApp({
        projectId: projectId,
      });
      console.log(`✅ Firebase Admin SDK başlatıldı (Application Default Credentials, Project ID: ${projectId})`);
      return true;
    } catch (error) {
      console.error('❌ Firebase Admin SDK başlatılamadı:', error.message);
      console.log('\n💡 Çözüm:');
      console.log('   1. Service account key dosyasını proje root\'una ekleyin');
      console.log('   2. Veya Firebase CLI ile login: firebase login');
      console.log('   3. Veya gcloud auth application-default login');
      return false;
    }
  } catch (error) {
    console.error('❌ Hata:', error.message);
    return false;
  }
}

// Remote Config'i toplu yükle
async function deployRemoteConfigBulk(configPath) {
  try {
    const remoteConfig = admin.remoteConfig();
    
    // Mevcut template'i al
    console.log('📥 Mevcut Remote Config template alınıyor...');
    let template;
    try {
      template = await remoteConfig.getTemplate();
      console.log('✅ Mevcut template alındı');
      console.log(`   Mevcut parametre sayısı: ${Object.keys(template.parameters || {}).length}`);
    } catch (error) {
      console.error('❌ Mevcut template alınamadı:', error.message);
      console.log('\n💡 Çözüm:');
      console.log('   Firebase Console → Remote Config');
      console.log('   En az bir parametre manuel olarak ekleyin (ör: test_param)');
      console.log('   Sonra tekrar çalıştırın');
      return false;
    }
    
    // Yeni config'i oku
    console.log('\n📖 Yeni config dosyası okunuyor...');
    const configJson = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configJson);
    const newParameters = config.parameters || {};
    
    console.log(`   Yeni parametre sayısı: ${Object.keys(newParameters).length}`);
    
    // Parametreleri birleştir
    console.log('\n🔀 Parametreler birleştiriliyor...');
    let addedCount = 0;
    let updatedCount = 0;
    
    for (const [key, paramConfig] of Object.entries(newParameters)) {
      const defaultValue = paramConfig.defaultValue?.value;
      const valueType = paramConfig.valueType || 'STRING';
      const description = paramConfig.description || '';
      
      if (!defaultValue && defaultValue !== '0' && defaultValue !== '') {
        console.log(`⚠️  Parametre atlandı (defaultValue yok): ${key}`);
        continue;
      }
      
      // Parametreyi ekle veya güncelle
      if (template.parameters[key]) {
        template.parameters[key].defaultValue = { value: String(defaultValue) };
        template.parameters[key].valueType = valueType;
        if (description) template.parameters[key].description = description;
        updatedCount++;
      } else {
        template.parameters[key] = {
          defaultValue: { value: String(defaultValue) },
          valueType: valueType,
        };
        if (description) {
          template.parameters[key].description = description;
        }
        addedCount++;
      }
    }
    
    console.log(`✅ ${addedCount} yeni parametre eklendi`);
    console.log(`✅ ${updatedCount} parametre güncellendi`);
    console.log(`📊 Toplam parametre sayısı: ${Object.keys(template.parameters).length}`);
    
    // Template'i yükle
    console.log('\n📤 Remote Config yükleniyor...');
    const updatedTemplate = await remoteConfig.publishTemplate(template);
    
    console.log('\n✅ Remote Config başarıyla yüklendi!');
    console.log(`   Version: ${updatedTemplate.version.versionNumber}`);
    console.log(`   Update Time: ${updatedTemplate.version.updateTime}`);
    console.log(`   Description: ${updatedTemplate.version.description || 'N/A'}`);
    
    return true;
  } catch (error) {
    console.error('\n❌ Remote Config yüklenemedi:', error.message);
    
    if (error.code === 'permission-denied' || error.codePrefix === 'remote-config') {
      console.log('\n💡 Çözüm:');
      console.log('   1. Firebase projesine yazma yetkisine sahip olduğunuzdan emin olun');
      console.log('   2. firebase login --reauth');
      console.log('   3. gcloud auth application-default login');
    }
    
    if (error.message.includes('ETag')) {
      console.log('\n💡 ETag hatası:');
      console.log('   Mevcut template alınamadı. Firebase Console\'dan en az bir parametre ekleyin.');
    }
    
    return false;
  }
}

// Ana fonksiyon
async function main() {
  console.log('🚀 Firebase Remote Config Bulk Deployment');
  console.log('='.repeat(60));
  console.log();
  
  // Config dosyası yolu
  const configPath = path.join(__dirname, '..', 'remote_config_merged.json');
  
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
  const deployed = await deployRemoteConfigBulk(configPath);
  
  if (deployed) {
    console.log();
    console.log('='.repeat(60));
    console.log('🎉 Tamamlandı!');
    console.log();
    console.log('📋 Sonraki Adımlar:');
    console.log('   1. Firebase Console → Remote Config');
    console.log('   2. Yeni parametreleri kontrol edin');
    console.log('   3. "Publish changes" butonuna tıklayın (gerekirse)');
    console.log('   4. Değişiklikler 1 saat içinde uygulamaya yansıyacak');
    console.log();
  } else {
    console.log();
    console.log('💡 Alternatif Yöntem:');
    console.log('   Firebase Console → Remote Config');
    console.log('   "Import from file" özelliğini kullanın (varsa)');
    console.log('   Veya remote_config_merged.json dosyasındaki parametreleri');
    console.log('   toplu olarak eklemek için Firebase Console API kullanın');
    process.exit(1);
  }
}

// Script'i çalıştır
main().catch((error) => {
  console.error('\n❌ Beklenmeyen hata:', error);
  process.exit(1);
});

