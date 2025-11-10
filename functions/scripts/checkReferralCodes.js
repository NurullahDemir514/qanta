/**
 * Check Referral Codes Status
 * 
 * This script checks the status of referral codes for all users.
 * 
 * Usage:
 *   node scripts/checkReferralCodes.js
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

async function checkReferralCodesStatus() {
  try {
    console.log('🔄 Checking referral codes status...\n');

    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Total users: ${usersSnapshot.size}\n`);

    let withCodeCount = 0;
    let withoutCodeCount = 0;
    let invalidCodeCount = 0;
    let usersWithoutCodes = [];
    let usersWithInvalidCodes = [];

    // Check each user
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const referralCode = userData.referral_code;
      const expectedCode = userId.substring(0, 8).toUpperCase();

      if (!referralCode) {
        console.log(`❌ User ${userId} (${userData.email || 'N/A'}): No referral code`);
        withoutCodeCount++;
        usersWithoutCodes.push({
          userId,
          email: userData.email || 'N/A',
          expectedCode,
        });
      } else if (referralCode.length !== 8) {
        console.log(`⚠️  User ${userId} (${userData.email || 'N/A'}): Invalid referral code length: ${referralCode} (expected 8, got ${referralCode.length})`);
        invalidCodeCount++;
        usersWithInvalidCodes.push({
          userId,
          email: userData.email || 'N/A',
          currentCode: referralCode,
          expectedCode,
        });
      } else if (referralCode !== expectedCode) {
        console.log(`⚠️  User ${userId} (${userData.email || 'N/A'}): Referral code mismatch: ${referralCode} (expected ${expectedCode})`);
        invalidCodeCount++;
        usersWithInvalidCodes.push({
          userId,
          email: userData.email || 'N/A',
          currentCode: referralCode,
          expectedCode,
        });
      } else {
        console.log(`✅ User ${userId} (${userData.email || 'N/A'}): ${referralCode}`);
        withCodeCount++;
      }
    }

    console.log('\n📊 Summary:');
    console.log(`   ✅ With valid code: ${withCodeCount}`);
    console.log(`   ❌ Without code: ${withoutCodeCount}`);
    console.log(`   ⚠️  With invalid code: ${invalidCodeCount}`);
    console.log(`   📊 Total: ${usersSnapshot.size}`);

    if (usersWithoutCodes.length > 0) {
      console.log('\n❌ Users without referral codes:');
      usersWithoutCodes.forEach((user) => {
        console.log(`   - ${user.userId} (${user.email}): Expected ${user.expectedCode}`);
      });
    }

    if (usersWithInvalidCodes.length > 0) {
      console.log('\n⚠️  Users with invalid referral codes:');
      usersWithInvalidCodes.forEach((user) => {
        console.log(`   - ${user.userId} (${user.email}): ${user.currentCode} (expected ${user.expectedCode})`);
      });
    }

    console.log('\n✅ Check completed!');
  } catch (error) {
    console.error('❌ Error checking referral codes:', error);
    process.exit(1);
  }
}

// Run the script
checkReferralCodesStatus()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

