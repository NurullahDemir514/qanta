/**
 * Set Test Mode Handler
 * SADECE DEBUG BUILD'DE ERİŞİLEBİLİR!
 * 
 * Production güvenliği:
 * - Frontend'de kDebugMode ile korumalı
 * - Backend'de ek güvenlik kontrolü yapılabilir
 */

const {HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * Test modunu aktif/pasif et (sadece development için)
 * Premium-related field'lar client-side'dan güncellenemez, sadece backend'den
 */
async function setTestMode(request) {
  // Auth kontrolü
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
  }

  const userId = request.auth.uid;
  const {enabled} = request.data;

  if (typeof enabled !== "boolean") {
    throw new HttpsError(
        "invalid-argument",
        "enabled must be a boolean",
    );
  }

  try {
    logger.info(`🧪 setTestMode called for user ${userId}: ${enabled}`);

    const db = admin.firestore();

    // Premium field'ları güncelle (sadece backend yapabilir)
    await db.collection("users").doc(userId).set({
      isTestMode: enabled,
      isPremium: enabled,
      isPremiumPlus: enabled, // Test mode = Premium Plus
      subscriptionStatus: enabled ? "premium_plus" : "free",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    logger.info(`✅ Test mode ${enabled ? "enabled" : "disabled"} for user ${userId}`);

    return {
      success: true,
      isTestMode: enabled,
      isPremium: enabled,
      isPremiumPlus: enabled,
      message: enabled ?
        "Test mode enabled - Premium Plus activated" :
        "Test mode disabled - Back to Free",
    };
  } catch (error) {
    logger.error(`❌ setTestMode error for user ${userId}:`, error);
    throw new HttpsError(
        "internal",
        `Failed to set test mode: ${error.message}`,
    );
  }
}

module.exports = {setTestMode};

