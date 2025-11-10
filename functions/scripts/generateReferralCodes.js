/**
 * Generate Referral Codes for Existing Users
 * 
 * This script generates referral codes for all users who don't have one.
 * Referral code = first 8 characters of user ID (uppercase)
 * 
 * Usage:
 *   node scripts/generateReferralCodes.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Get project ID from .firebaserc or environment
function getProjectId() {
  try {
    const firebasercPath = path.join(__dirname, '..', '..', '.firebaserc');
    if (fs.existsSync(firebasercPath)) {
      const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, 'utf8'));
      return firebaserc.projects?.default;
    }
  } catch (e) {
    // Ignore errors
  }
  return process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'qanta-de0b9';
}

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    // Try to use service account key if available
    const serviceAccount = require('../serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id || getProjectId(),
    });
    console.log('✅ Firebase Admin SDK initialized with service account');
  } catch (e) {
    // If service account not found, use default credentials (Firebase CLI login)
    try {
      const projectId = getProjectId();
      admin.initializeApp({
        projectId: projectId,
      });
      console.log(`✅ Firebase Admin SDK initialized with default credentials (Project: ${projectId})`);
    } catch (err) {
      console.error('❌ Firebase Admin SDK initialization failed:', err.message);
      console.log('\n💡 Solutions:');
      console.log('1. Login with Firebase CLI: firebase login');
      console.log('2. Set project: firebase use qanta-de0b9');
      console.log('3. Or add serviceAccountKey.json to functions/ folder');
      process.exit(1);
    }
  }
}

const db = admin.firestore();

async function generateReferralCodesForAllUsers() {
  try {
    console.log('🔄 Starting referral code generation for all users...\n');

    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Total users found: ${usersSnapshot.size}\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Process each user
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      
      // Check if user already has a referral code
      if (userData.referral_code && userData.referral_code.length === 8) {
        console.log(`⏭️  User ${userId} already has referral code: ${userData.referral_code}`);
        skippedCount++;
        continue;
      }

      // Generate referral code (first 8 characters of user ID, uppercase)
      const referralCode = userId.substring(0, 8).toUpperCase();
      
      try {
        // Update user document
        await userDoc.ref.update({
          referral_code: referralCode,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`✅ Updated user ${userId}: ${referralCode}`);
        updatedCount++;
      } catch (error) {
        console.error(`❌ Error updating user ${userId}: ${error.message}`);
        errorCount++;
      }
    }

    console.log('\n📊 Summary:');
    console.log(`   ✅ Updated: ${updatedCount}`);
    console.log(`   ⏭️  Skipped: ${skippedCount}`);
    console.log(`   ❌ Errors: ${errorCount}`);
    console.log(`   📊 Total: ${usersSnapshot.size}`);
    console.log('\n✅ Referral code generation completed!');
  } catch (error) {
    console.error('❌ Error generating referral codes:', error);
    process.exit(1);
  }
}

// Run the script
generateReferralCodesForAllUsers()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

