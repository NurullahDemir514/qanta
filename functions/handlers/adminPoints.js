const admin = require('firebase-admin');
const {HttpsError} = require('firebase-functions/v2/https');
const crypto = require('crypto');

/**
 * Admin Add Points
 * Allows admin to add points to a user's account
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.userId - Target user ID
 * @param {number} request.data.points - Points to add
 * @param {string} request.data.reason - Reason for adding points (optional)
 * @returns {Object} Result with success status and new balance
 */
exports.adminAddPoints = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const adminUserId = request.auth.uid;
    const { userId, points, reason } = request.data;
    
    if (!userId || !points) {
      throw new HttpsError('invalid-argument', 'User ID and points are required');
    }
    
    if (points <= 0) {
      throw new HttpsError('invalid-argument', 'Points must be greater than 0');
    }
    
    if (!Number.isInteger(points)) {
      throw new HttpsError('invalid-argument', 'Points must be an integer');
    }

    // Verify admin status
    const isAdminUser = await checkAdminStatus(adminUserId);
    if (!isAdminUser) {
      throw new HttpsError('permission-denied', 'Only admins can add points');
    }

    // Verify target user exists
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    // Get current balance
    const balanceDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('point_balance')
      .doc('balance')
      .get();

    let currentBalance = 0;
    let currentTotalEarned = 0;
    
    if (balanceDoc.exists) {
      const balanceData = balanceDoc.data();
      currentBalance = balanceData.total_points || 0;
      currentTotalEarned = balanceData.total_earned || 0;
    }

    // Create transaction
    const transactionId = crypto.randomUUID();
    const now = admin.firestore.Timestamp.now();
    
    const transaction = {
      id: transactionId,
      user_id: userId,
      points: points,
      activity: 'specialEvent', // Admin bonus
      reference_id: null,
      description: reason || `Admin bonus from ${adminUserId}`,
      earned_at: now,
      created_at: now,
      updated_at: now,
    };

    // Update balance
    const newBalance = currentBalance + points;
    const newTotalEarned = currentTotalEarned + points;

    const batch = admin.firestore().batch();

    // Save transaction
    const transactionRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('point_transactions')
      .doc(transactionId);
    
    batch.set(transactionRef, transaction);

    // Update balance
    const balanceRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('point_balance')
      .doc('balance');
    
    batch.set(balanceRef, {
      user_id: userId,
      total_points: newBalance,
      total_earned: newTotalEarned,
      total_spent: balanceDoc.exists ? (balanceDoc.data().total_spent || 0) : 0,
      rewarded_ad_count: balanceDoc.exists ? (balanceDoc.data().rewarded_ad_count || 0) : 0,
      transaction_count: balanceDoc.exists ? (balanceDoc.data().transaction_count || 0) : 0,
      daily_login_count: balanceDoc.exists ? (balanceDoc.data().daily_login_count || 0) : 0,
      weekly_streak_count: balanceDoc.exists ? (balanceDoc.data().weekly_streak_count || 0) : 0,
      longest_streak: balanceDoc.exists ? (balanceDoc.data().longest_streak || 0) : 0,
      last_daily_login: balanceDoc.exists ? (balanceDoc.data().last_daily_login || null) : null,
      last_earned_at: now,
      updated_at: now,
    }, { merge: true });

    // Commit batch
    await batch.commit();

    console.log(`✅ Admin ${adminUserId} added ${points} points to user ${userId}. New balance: ${newBalance}`);

    return {
      success: true,
      message: `Successfully added ${points} points to user`,
      newBalance: newBalance,
      pointsAdded: points,
    };
  } catch (error) {
    console.error('❌ Error adding points:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to add points: ${error.message}`);
  }
};

/**
 * Check if user is admin
 */
async function checkAdminStatus(userId) {
  // Check predefined admin
  const PREDEFINED_ADMIN_ID = 'obwsYff7JuNBEis9ENvX2pIdIKE2';
  if (userId === PREDEFINED_ADMIN_ID) {
    return true;
  }

  // Check admin list
  try {
    const adminListDoc = await admin.firestore()
      .collection('admins')
      .doc('admin_list')
      .get();
    
    if (adminListDoc.exists) {
      const adminList = adminListDoc.data();
      const userIds = adminList.userIds || [];
      return userIds.includes(userId);
    }
  } catch (error) {
    console.error('Error checking admin status:', error);
  }

  return false;
}

