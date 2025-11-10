/**
 * Get User Info Handler
 * Firebase Auth'tan user bilgilerini çeker
 */

const {HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * Get user info from Firebase Auth and Firestore
 * Returns email and displayName for a user
 */
async function getUserInfo(request) {
  // Auth kontrolü - admin olmalı
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const {userId} = request.data || {};
  
  if (!userId) {
    throw new HttpsError(
      "invalid-argument",
      "userId is required",
    );
  }

  try {
    logger.info(`🔍 Getting user info for ${userId}...`);

    // First, try Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      const email = userData.email || userData.email_address || null;
      const name = userData.displayName || 
                   userData.name || 
                   userData.display_name || 
                   userData.full_name ||
                   (userData.first_name && userData.last_name ? 
                     `${userData.first_name} ${userData.last_name}` : 
                     userData.first_name || userData.last_name || null);

      if (email || name) {
        logger.info(`✅ User info found in Firestore for ${userId}`);
        return {
          success: true,
          userId,
          email: email || 'N/A',
          name: name || 'Kullanıcı',
          source: 'firestore',
        };
      }
    }

    // If not found in Firestore or missing fields, try Firebase Auth
    try {
      const authUser = await admin.auth().getUser(userId);
      logger.info(`✅ User info found in Firebase Auth for ${userId}`);
      
      const email = authUser.email || 'N/A';
      const name = authUser.displayName || 
                   (email !== 'N/A' ? email.split('@')[0] : 'Kullanıcı');

      // Optionally create/update user document in Firestore
      try {
        await admin.firestore()
          .collection('users')
          .doc(userId)
          .set({
            email: authUser.email || 'N/A',
            displayName: authUser.displayName || null,
            name: authUser.displayName || null,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        logger.info(`✅ User document created/updated in Firestore for ${userId}`);
      } catch (createError) {
        logger.warn(`⚠️ Could not create user document: ${createError.message}`);
        // Continue anyway
      }

      return {
        success: true,
        userId,
        email,
        name,
        source: 'auth',
      };
    } catch (authError) {
      logger.error(`❌ Could not get user from Auth: ${authError.message}`);
      return {
        success: false,
        userId,
        email: 'N/A',
        name: `User ${userId.substring(0, 8)}`,
        source: 'fallback',
        error: authError.message,
      };
    }
  } catch (error) {
    logger.error(`❌ getUserInfo error: ${error.message}`);
    throw new HttpsError(
      "internal",
      `Failed to get user info: ${error.message}`,
    );
  }
}

module.exports = {getUserInfo};

