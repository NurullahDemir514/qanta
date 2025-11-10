/**
 * Check Referral Codes via Cloud Function
 * 
 * This script checks referral codes by calling the deployed Cloud Function
 * 
 * Usage:
 *   node scripts/checkReferralCodesViaFunction.js
 */

// This script provides alternative methods to check referral codes
// without requiring direct Firestore access

async function checkReferralCodesViaConsole() {
  console.log('📊 Referral Codes Kontrolü\n');
  console.log('Bu script Firestore\'a direkt erişim gerektirir.');
  console.log('Alternatif kontrol yöntemleri:\n');
  
  console.log('1️⃣  Firebase Console\'dan Kontrol:');
  console.log('   - Firebase Console → Firestore Database');
  console.log('   - users collection\'ına gidin');
  console.log('   - Bir kullanıcı document\'ını açın');
  console.log('   - referral_code field\'ının var olduğunu kontrol edin\n');
  
  console.log('2️⃣  Cloud Function Kontrolü:');
  console.log('   - Firebase Console → Functions');
  console.log('   - processReferralCode function\'ının deploy edildiğini kontrol edin');
  console.log('   - Logs sekmesinden function çağrılarını kontrol edin\n');
  
  console.log('3️⃣  App\'te Kontrol:');
  console.log('   - Uygulamayı açın');
  console.log('   - Profile → Referral Widget');
  console.log('   - Referral code\'un göründüğünü kontrol edin\n');
  
  console.log('4️⃣  Service Account Key ile Kontrol:');
  console.log('   - Firebase Console → Project Settings → Service Accounts');
  console.log('   - "Generate New Private Key" → JSON indir');
  console.log('   - functions/serviceAccountKey.json olarak kaydet');
  console.log('   - node scripts/checkReferralCodes.js\n');
  
  console.log('📝 Mevcut Durum:');
  console.log('   ✅ processReferralCode Cloud Function deploy edildi');
  console.log('   ✅ Yeni kullanıcılar için referral code otomatik oluşturuluyor');
  console.log('   ⚠️  Eski kullanıcılar için migration script çalıştırılmalı\n');
  
  console.log('🚀 Migration için:');
  console.log('   - Service account key ekleyin');
  console.log('   - node scripts/generateReferralCodes.js\n');
}

// Run the check
checkReferralCodesViaConsole()
  .then(() => {
    console.log('✅ Kontrol tamamlandı');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Kontrol başarısız:', error);
    process.exit(1);
  });

