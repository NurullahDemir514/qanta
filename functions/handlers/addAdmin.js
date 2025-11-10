/**
 * Add Admin Handler
 * User ID'den direkt admin yapar
 */

const {HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * Add user to admin list by User ID
 * Only existing admins can add new admins (or use this function directly)
 */
async function addAdmin(request) {
  // Auth kontrolü - opsiyonel, direkt çağrılabilir
  const {userId} = request.data || {};
  
  if (!userId) {
    throw new HttpsError(
      "invalid-argument",
      "userId is required",
    );
  }

  try {
    logger.info(`🔍 Adding user ${userId} to admin list...`);

    const db = admin.firestore();

    // Admin listesini al
    const adminDocRef = db.collection("admins").doc("admin_list");
    const adminDoc = await adminDocRef.get();

    let userIds = [];
    if (adminDoc.exists) {
      const data = adminDoc.data();
      userIds = data.userIds || [];
      logger.info(`📋 Current admin list: ${userIds.length} admin(s)`);
    } else {
      logger.info(`📋 Admin list document does not exist, creating new one...`);
    }

    // User ID zaten listede var mı kontrol et
    if (userIds.includes(userId)) {
      logger.info(`ℹ️  User ${userId} is already an admin`);
      return {
        success: true,
        message: "User is already an admin",
        isAdmin: true,
      };
    }

    // User ID'yi listeye ekle
    userIds.push(userId);

    // Firestore'a kaydet
    await adminDocRef.set({
      userIds: userIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: false});

    logger.info(`✅ Successfully added ${userId} to admin list`);
    logger.info(`   Total admins: ${userIds.length}`);

    return {
      success: true,
      message: `User ${userId} added to admin list`,
      totalAdmins: userIds.length,
    };
  } catch (error) {
    logger.error(`❌ addAdmin error: ${error.message}`);
    throw new HttpsError(
      "internal",
      `Failed to add admin: ${error.message}`,
    );
  }
}

module.exports = {addAdmin};

