#!/usr/bin/env node

/**
 * Add Admin by User ID Script
 * User ID'den direkt admin yapar
 * 
 * Kullanım: node functions/add_admin_by_id.js <userId>
 */

const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat
try {
  admin.initializeApp();
  console.log('✅ Firebase Admin SDK initialized');
} catch (err) {
  console.error('❌ Firebase Admin SDK initialization failed:', err.message);
  process.exit(1);
}

const db = admin.firestore();

async function addAdminByUserId(userId) {
  try {
    console.log(`\n🔍 Adding user ${userId} to admin list...`);
    
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
    if (userIds.includes(userId)) {
      console.log(`\nℹ️  User ${userId} is already an admin`);
      return true;
    }
    
    // User ID'yi listeye ekle
    userIds.push(userId);
    
    // Firestore'a kaydet
    await adminDocRef.set({
      userIds: userIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: false });
    
    console.log(`\n✅ Successfully added ${userId} to admin list`);
    console.log(`   Total admins: ${userIds.length}`);
    
    return true;
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    console.error(error);
    return false;
  }
}

// Script başlat
const userId = process.argv[2];

if (!userId) {
  console.error('❌ User ID is required');
  console.log('\nKullanım: node functions/add_admin_by_id.js <userId>');
  process.exit(1);
}

addAdminByUserId(userId)
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

