const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function getProjectId() {
  try {
    const firebasercPath = path.join(__dirname, '..', '.firebaserc');
    if (fs.existsSync(firebasercPath)) {
      const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, 'utf8'));
      return firebaserc.projects?.default;
    }
  } catch (e) {}
  return process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
}

async function getUserByEmail(email) {
  const projectId = getProjectId();
  if (!projectId) {
    console.error('❌ Project ID bulunamadı');
    process.exit(1);
  }
  
  // Firebase Auth REST API kullan
  // Önce Firebase CLI token al
  const { execSync } = require('child_process');
  
  try {
    // Firebase CLI token ile API çağrısı yap
    console.log('🔍 Searching for user with email:', email);
    console.log('📝 Project ID:', projectId);
    console.log('\n💡 Firebase Console\'dan user ID\'yi bulmak için:');
    console.log('   1. Firebase Console → Authentication → Users');
    console.log('   2. Email ile arama yapın: ' + email);
    console.log('   3. User ID (UID) kopyalayın\n');
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

const email = process.argv[2];
if (!email) {
  console.error('❌ Email gerekli');
  process.exit(1);
}

getUserByEmail(email);
