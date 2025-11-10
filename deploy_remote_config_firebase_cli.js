#!/usr/bin/env node
/**
 * Firebase Remote Config Deployment Script (Firebase CLI Token kullanarak)
 * Firebase CLI'nın access token'ını kullanarak REST API ile yükler
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const https = require('https');

// Firebase CLI'dan access token al
function getFirebaseAccessToken() {
  try {
    // Firebase CLI'nın token'ını al
    const token = execSync('firebase login:ci --no-localhost', { 
      encoding: 'utf-8',
      stdio: 'pipe'
    }).trim();
    
    if (!token || token.includes('Error')) {
      throw new Error('Token alınamadı');
    }
    
    return token;
  } catch (error) {
    console.error('❌ Firebase CLI token alınamadı:', error.message);
    console.log('\n💡 Çözüm:');
    console.log('   1. firebase login --reauth');
    console.log('   2. Veya manuel token al: firebase login:ci');
    return null;
  }
}

// REST API ile Remote Config yükle
async function deployViaRESTAPI(configPath, accessToken) {
  return new Promise((resolve, reject) => {
    const configJson = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configJson);
    
    // Project ID'yi .firebaserc'den oku
    const firebasercPath = path.join(__dirname, '..', '.firebaserc');
    const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, 'utf8'));
    const projectId = firebaserc.projects?.default || 'qanta-de0b9';
    
    // Önce mevcut template'i al (ETag için)
    const getUrl = `https://firebaseremoteconfig.googleapis.com/v1/projects/${projectId}/remoteConfig`;
    
    const getOptions = {
      hostname: 'firebaseremoteconfig.googleapis.com',
      path: `/v1/projects/${projectId}/remoteConfig`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    };
    
    console.log('📥 Mevcut Remote Config template alınıyor...');
    
    const getReq = https.request(getOptions, (getRes) => {
      let getData = '';
      
      getRes.on('data', (chunk) => {
        getData += chunk;
      });
      
      getRes.on('end', () => {
        if (getRes.statusCode !== 200) {
          console.error('❌ Mevcut template alınamadı:', getRes.statusCode);
          console.error('   Response:', getData);
          
          if (getRes.statusCode === 404) {
            console.log('\n💡 Çözüm:');
            console.log('   Firebase Console → Remote Config');
            console.log('   En az bir parametre manuel olarak ekleyin (ör: test_param)');
            console.log('   Sonra tekrar çalıştırın');
          }
          
          reject(new Error(`HTTP ${getRes.statusCode}: ${getData}`));
          return;
        }
        
        try {
          const currentTemplate = JSON.parse(getData);
          const etag = getRes.headers['etag'];
          
          console.log('✅ Mevcut template alındı');
          console.log(`   Mevcut parametre sayısı: ${Object.keys(currentTemplate.parameters || {}).length}`);
          console.log(`   ETag: ${etag}`);
          
          // Parametreleri birleştir
          console.log('\n🔀 Parametreler birleştiriliyor...');
          const mergedParameters = { ...(currentTemplate.parameters || {}) };
          const newParameters = config.parameters || {};
          
          let addedCount = 0;
          let updatedCount = 0;
          
          for (const [key, paramConfig] of Object.entries(newParameters)) {
            const defaultValue = paramConfig.defaultValue?.value;
            const valueType = paramConfig.valueType || 'STRING';
            const description = paramConfig.description || '';
            
            if (!defaultValue && defaultValue !== '0' && defaultValue !== '') {
              continue;
            }
            
            if (mergedParameters[key]) {
              mergedParameters[key].defaultValue = { value: String(defaultValue) };
              mergedParameters[key].valueType = valueType;
              if (description) mergedParameters[key].description = description;
              updatedCount++;
            } else {
              mergedParameters[key] = {
                defaultValue: { value: String(defaultValue) },
                valueType: valueType,
              };
              if (description) {
                mergedParameters[key].description = description;
              }
              addedCount++;
            }
          }
          
          console.log(`✅ ${addedCount} yeni parametre eklendi`);
          console.log(`✅ ${updatedCount} parametre güncellendi`);
          console.log(`📊 Toplam parametre sayısı: ${Object.keys(mergedParameters).length}`);
          
          // Template'i güncelle
          const updatedTemplate = {
            ...currentTemplate,
            parameters: mergedParameters,
            version: {
              ...currentTemplate.version,
              description: 'Amazon Rewards ve Points sistemi için Remote Config ayarları',
            },
          };
          
          // Template'i yükle
          console.log('\n📤 Remote Config yükleniyor...');
          
          const putOptions = {
            hostname: 'firebaseremoteconfig.googleapis.com',
            path: `/v1/projects/${projectId}/remoteConfig`,
            method: 'PUT',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
              'If-Match': etag,
            },
          };
          
          const putReq = https.request(putOptions, (putRes) => {
            let putData = '';
            
            putRes.on('data', (chunk) => {
              putData += chunk;
            });
            
            putRes.on('end', () => {
              if (putRes.statusCode !== 200) {
                console.error('❌ Remote Config yüklenemedi:', putRes.statusCode);
                console.error('   Response:', putData);
                reject(new Error(`HTTP ${putRes.statusCode}: ${putData}`));
                return;
              }
              
              try {
                const result = JSON.parse(putData);
                console.log('\n✅ Remote Config başarıyla yüklendi!');
                console.log(`   Version: ${result.version?.versionNumber || 'N/A'}`);
                console.log(`   Update Time: ${result.version?.updateTime || 'N/A'}`);
                resolve(result);
              } catch (error) {
                reject(error);
              }
            });
          });
          
          putReq.on('error', (error) => {
            reject(error);
          });
          
          putReq.write(JSON.stringify(updatedTemplate));
          putReq.end();
          
        } catch (error) {
          reject(error);
        }
      });
    });
    
    getReq.on('error', (error) => {
      reject(error);
    });
    
    getReq.end();
  });
}

// Ana fonksiyon
async function main() {
  console.log('🚀 Firebase Remote Config Deployment (Firebase CLI Token)');
  console.log('='.repeat(60));
  console.log();
  
  // Config dosyası yolu
  const configPath = path.join(__dirname, '..', 'remote_config_merged.json');
  
  if (!fs.existsSync(configPath)) {
    console.error(`❌ Config dosyası bulunamadı: ${configPath}`);
    console.log('   Önce deploy_remote_config.py scriptini çalıştırın');
    process.exit(1);
  }
  
  // Access token al
  console.log('🔐 Firebase CLI access token alınıyor...');
  const accessToken = getFirebaseAccessToken();
  
  if (!accessToken) {
    console.log('\n💡 Alternatif:');
    console.log('   firebase login --reauth');
    console.log('   Sonra tekrar çalıştırın');
    process.exit(1);
  }
  
  console.log('✅ Access token alındı');
  console.log();
  
  // Remote Config'i yükle
  try {
    await deployViaRESTAPI(configPath, accessToken);
    
    console.log();
    console.log('='.repeat(60));
    console.log('🎉 Tamamlandı!');
    console.log();
    console.log('📋 Sonraki Adımlar:');
    console.log('   1. Firebase Console → Remote Config');
    console.log('   2. Yeni parametreleri kontrol edin');
    console.log('   3. "Publish changes" butonuna tıklayın (gerekirse)');
    console.log();
  } catch (error) {
    console.error('\n❌ Hata:', error.message);
    process.exit(1);
  }
}

// Script'i çalıştır
main().catch((error) => {
  console.error('\n❌ Beklenmeyen hata:', error);
  process.exit(1);
});

