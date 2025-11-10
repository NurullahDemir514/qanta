#!/usr/bin/env node

/**
 * Add Admin Script
 * Email'den kullanıcıyı bulup admin listesine ekler
 * 
 * Kullanım: node scripts/add_admin.js <email>
 * Örnek: node scripts/add_admin.js nurullahdemir6337@gmail.com
 */

const admin = require('firebase-admin');
const path = require('path');

// Firebase Admin SDK'yı başlat
// Bu script functions klasöründen çalıştırılacak, o yüzden service account'u functions klasöründen yükleyelim
try {
  // Service account key dosyası varsa onu kullan
  const serviceAccount = require('../functions/serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('✅ Firebase Admin SDK initialized with service account');
} catch (e) {
  // Service account yoksa, default credentials kullan (Firebase CLI ile login yapılmış olmalı)
  try {
    admin.initializeApp();
    console.log('✅ Firebase Admin SDK initialized with default credentials');
  } catch (err) {
    console.error('❌ Firebase Admin SDK initialization failed:', err.message);
    console.log('\n💡 Çözümler:');
    console.log('1. Firebase CLI ile login yapın: firebase login');
    console.log('2. Veya serviceAccountKey.json dosyasını functions/ klasörüne ekleyin');
    process.exit(1);
  }
}

const db = admin.firestore();
const auth = admin.auth();

async function addAdminByEmail(email) {
  try {
    console.log(`\n🔍 Searching for user with email: ${email}`);
    
    // Firebase Authentication'dan kullanıcıyı bul
    let user;
    try {
      user = await auth.getUserByEmail(email);
      console.log(`✅ User found in Firebase Authentication:`);
      console.log(`   User ID: ${user.uid}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Display Name: ${user.displayName || 'N/A'}`);
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        console.error(`❌ User not found in Firebase Authentication: ${email}`);
        console.log('\n💡 Kullanıcının uygulamaya en az bir kez giriş yapmış olması gerekiyor.');
        return false;
      }
      throw err;
    }
    
    // Admin listesini al
    const adminDocRef = db.collection('admins').doc('admin_list');
    const adminDoc = await adminDocRef.get();
    
    let userIds = [];
    if (adminDoc.exists) {
      const data = adminDoc.data();
      userIds = data.userIds || [];
      console.log(`\n📋 Current admin list: ${userIds.length} admin(s)`);
    } else {
      console.log(`\n📋 Admin list document does not exist, creating new one...`);
    }
    
    // User ID zaten listede var mı kontrol et
    if (userIds.includes(user.uid)) {
      console.log(`\nℹ️  User ${user.uid} is already an admin`);
      return true;
    }
    
    // User ID'yi listeye ekle
    userIds.push(user.uid);
    
    // Firestore'a kaydet
    await adminDocRef.set({
      userIds: userIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: false });
    
    console.log(`\n✅ Successfully added ${email} to admin list`);
    console.log(`   User ID: ${user.uid}`);
    console.log(`   Total admins: ${userIds.length}`);
    
    // User document'ı Firestore'da yoksa oluştur
    const userDocRef = db.collection('users').doc(user.uid);
    const userDoc = await userDocRef.get();
    
    if (!userDoc.exists) {
      console.log(`\n📝 Creating user document in Firestore...`);
      await userDocRef.set({
        email: user.email,
        displayName: user.displayName,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log(`✅ User document created`);
    } else {
      console.log(`\n✅ User document already exists in Firestore`);
    }
    
    return true;
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    console.error(error);
    return false;
  }
}

// Script başlat
const email = process.argv[2];

if (!email) {
  console.error('❌ Email address is required');
  console.log('\nKullanım: node scripts/add_admin.js <email>');
  console.log('Örnek: node scripts/add_admin.js nurullahdemir6337@gmail.com');
  process.exit(1);
}

// Email format kontrolü
if (!email.includes('@')) {
  console.error('❌ Invalid email format');
  process.exit(1);
}

addAdminByEmail(email)
  .then((success) => {
    if (success) {
      console.log('\n🎉 Admin ekleme işlemi tamamlandı!');
      process.exit(0);
    } else {
      console.log('\n⚠️  Admin ekleme işlemi başarısız oldu.');
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  });
