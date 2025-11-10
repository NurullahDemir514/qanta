const admin = require('firebase-admin');
const {HttpsError} = require('firebase-functions/v2/https');
const crypto = require('crypto');

/**
 * Handle Referral Code on User Registration
 * Triggered when a new user is created in Firebase Auth
 * 
 * Flow:
 * 1. New user signs up with referral code
 * 2. Cloud Function checks if referral code is valid
 * 3. If valid, gives points to referrer (500 points)
 * 4. Updates referral count for referrer
 * 5. Stores referral relationship in Firestore
 * 
 * @param {Object} user - Firebase Auth user object
 * @param {Object} context - Event context
 */
exports.handleReferralOnUserCreate = async (user, context) => {
  try {
    const newUserId = user.uid;
    const userEmail = user.email;
    const displayName = user.displayName;
    
    console.log(`🔄 Processing referral for new user: ${newUserId}`);
    
    // Get referral code from user's custom claims or user document
    // First, check if user document exists and has referral_code
    const userDocRef = admin.firestore()
      .collection('users')
      .doc(newUserId);
    
    let userDoc = await userDocRef.get();
    let userData = userDoc.exists ? userDoc.data() : null;
    
    // If user document doesn't exist, create it
    if (!userDoc.exists) {
      console.log(`⚠️ User document not found for ${newUserId}, creating...`);
      
      // Create user document with initial data
      // referral_code and referred_by will be set after processing
      const initialData = {
        email: userEmail,
        displayName: displayName || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        referral_code: null, // Will be set after processing referral
        referred_by: null, // Will be set if referral code is valid
        referred_by_code: null, // Will be set if referral code is provided
      };
      
      await userDocRef.set(initialData, { merge: true });
      console.log(`✅ User document created for ${newUserId}`);
      
      // Refresh userDoc to get the data
      userDoc = await userDocRef.get();
      userData = userDoc.data();
    }
    
    const referralCode = userData?.referral_code || userData?.referred_by_code || null;
    
    if (!referralCode) {
      console.log(`ℹ️ No referral code found for user ${newUserId}`);
      
      // Generate referral code for new user (first 8 chars of user ID, uppercase)
      const newUserReferralCode = newUserId.substring(0, 8).toUpperCase();
      
      await userDocRef.update({
        referral_code: newUserReferralCode,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`✅ Generated referral code for new user: ${newUserReferralCode}`);
      return;
    }
    
    console.log(`🔍 Processing referral code: ${referralCode} for user ${newUserId}`);
    
    // Find referrer by referral code
    // Referral code is first 8 characters of user ID (uppercase)
    const referrerQuery = await admin.firestore()
      .collection('users')
      .where('referral_code', '==', referralCode.toUpperCase())
      .limit(1)
      .get();
    
    if (referrerQuery.empty) {
      console.log(`⚠️ Referral code not found: ${referralCode}`);
      
      // Generate referral code for new user anyway
      const newUserReferralCode = newUserId.substring(0, 8).toUpperCase();
      await userDocRef.update({
        referral_code: newUserReferralCode,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return;
    }
    
    const referrerDoc = referrerQuery.docs[0];
    const referrerId = referrerDoc.id;
    const referrerData = referrerDoc.data();
    
    // Prevent self-referral
    if (referrerId === newUserId) {
      console.log(`⚠️ Self-referral detected for user ${newUserId}`);
      
      // Generate referral code for new user
      const newUserReferralCode = newUserId.substring(0, 8).toUpperCase();
      await userDocRef.update({
        referral_code: newUserReferralCode,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return;
    }
    
    console.log(`✅ Found referrer: ${referrerId} for new user ${newUserId}`);
    
    // Check if referrer has reached max referrals (5)
    const referralStatsRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referral_stats')
      .doc('stats');
    
    const referralStatsDoc = await referralStatsRef.get();
    const referralStats = referralStatsDoc.exists ? referralStatsDoc.data() : {};
    const currentReferralCount = referralStats.referral_count || 0;
    const maxReferrals = 5;
    
    if (currentReferralCount >= maxReferrals) {
      console.log(`⚠️ Referrer ${referrerId} has reached max referrals (${maxReferrals})`);
      
      // Still create referral record but don't give points
      await userDocRef.update({
        referral_code: newUserId.substring(0, 8).toUpperCase(),
        referred_by: referrerId,
        referral_status: 'max_reached',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return;
    }
    
    // Check if this user was already referred (prevent duplicate)
    const existingReferral = await admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referrals')
      .where('referred_user_id', '==', newUserId)
      .limit(1)
      .get();
    
    if (!existingReferral.empty) {
      console.log(`⚠️ User ${newUserId} was already referred by ${referrerId}`);
      return;
    }
    
    // Use fixed 500 points for referral (matching Flutter app and requirements)
    // Remote Config might have different value, but we use 500 as standard
    const referralPoints = 500;
    
    console.log(`💰 Giving ${referralPoints} points to referrer ${referrerId}`);
    console.log(`💰 Giving ${referralPoints} points to new user ${newUserId} (referred user)`);
    
    // Get referrer's current point balance
    const balanceDocRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('point_balance')
      .doc('balance');
    
    const balanceDoc = await balanceDocRef.get();
    let currentBalance = 0;
    let currentTotalEarned = 0;
    
    if (balanceDoc.exists) {
      const balanceData = balanceDoc.data();
      currentBalance = balanceData.total_points || 0;
      currentTotalEarned = balanceData.total_earned || 0;
    }
    
    // Create point transaction for referrer
    const transactionId = crypto.randomUUID();
    const now = admin.firestore.Timestamp.now();
    
    const transaction = {
      id: transactionId,
      user_id: referrerId,
      points: referralPoints,
      activity: 'referral',
      reference_id: newUserId,
      description: `Arkadaş referansı: ${displayName || userEmail || newUserId}`,
      earned_at: now,
      created_at: now,
      updated_at: now,
    };
    
    // Update referrer's point balance
    const newBalance = currentBalance + referralPoints;
    const newTotalEarned = currentTotalEarned + referralPoints;
    
    // Create referral record
    const referralRecordId = crypto.randomUUID();
    const referralRecord = {
      id: referralRecordId,
      referred_user_id: newUserId,
      referred_user_email: userEmail,
      referred_user_name: displayName || null,
      referral_code_used: referralCode,
      points_awarded: referralPoints,
      referred_at: now,
      created_at: now,
      updated_at: now,
    };
    
    // Update referral stats
    const newReferralCount = currentReferralCount + 1;
    const totalPointsEarned = (referralStats.total_points_earned || 0) + referralPoints;
    
    // ========== GIVE POINTS TO NEW USER (REFERRED) ==========
    // Get new user's current point balance
    const newUserBalanceDocRef = admin.firestore()
      .collection('users')
      .doc(newUserId)
      .collection('point_balance')
      .doc('balance');
    
    const newUserBalanceDoc = await newUserBalanceDocRef.get();
    let newUserCurrentBalance = 0;
    let newUserCurrentTotalEarned = 0;
    
    if (newUserBalanceDoc.exists) {
      const newUserBalanceData = newUserBalanceDoc.data();
      newUserCurrentBalance = newUserBalanceData.total_points || 0;
      newUserCurrentTotalEarned = newUserBalanceData.total_earned || 0;
    }
    
    // Create point transaction for new user (referred user gets 500 points)
    const newUserTransactionId = crypto.randomUUID();
    const newUserTransaction = {
      id: newUserTransactionId,
      user_id: newUserId,
      points: referralPoints,
      activity: 'referral',
      reference_id: referrerId,
      description: `Referans kodu ile kayıt bonusu (${referralCode})`,
      earned_at: now,
      created_at: now,
      updated_at: now,
    };
    
    // Update new user's point balance
    const newUserNewBalance = newUserCurrentBalance + referralPoints;
    const newUserNewTotalEarned = newUserCurrentTotalEarned + referralPoints;
    
    // Batch write
    const batch = admin.firestore().batch();
    
    // 1. Update new user's document
    batch.update(userDocRef, {
      referral_code: newUserId.substring(0, 8).toUpperCase(),
      referred_by: referrerId,
      referral_status: 'success',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // 2. Add point transaction for referrer
    const transactionRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('point_transactions')
      .doc(transactionId);
    batch.set(transactionRef, transaction);
    
    // 3. Update referrer's point balance
    batch.set(balanceDocRef, {
      user_id: referrerId,
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
    
    // 4. Add point transaction for new user (referred)
    const newUserTransactionRef = admin.firestore()
      .collection('users')
      .doc(newUserId)
      .collection('point_transactions')
      .doc(newUserTransactionId);
    batch.set(newUserTransactionRef, newUserTransaction);
    
    // 5. Update new user's point balance
    batch.set(newUserBalanceDocRef, {
      user_id: newUserId,
      total_points: newUserNewBalance,
      total_earned: newUserNewTotalEarned,
      total_spent: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().total_spent || 0) : 0,
      rewarded_ad_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().rewarded_ad_count || 0) : 0,
      transaction_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().transaction_count || 0) : 0,
      daily_login_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().daily_login_count || 0) : 0,
      weekly_streak_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().weekly_streak_count || 0) : 0,
      longest_streak: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().longest_streak || 0) : 0,
      last_daily_login: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().last_daily_login || null) : null,
      last_earned_at: now,
      updated_at: now,
    }, { merge: true });
    
    // 6. Create referral record
    const referralRecordRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referrals')
      .doc(referralRecordId);
    batch.set(referralRecordRef, referralRecord);
    
    // 7. Update referral stats
    batch.set(referralStatsRef, {
      user_id: referrerId,
      referral_count: newReferralCount,
      total_points_earned: totalPointsEarned,
      last_referral_at: now,
      updated_at: now,
    }, { merge: true });
    
    // Commit batch
    await batch.commit();
    
    console.log(`✅ Referral processed successfully:`);
    console.log(`   Referrer: ${referrerId}`);
    console.log(`   Referrer Points Awarded: ${referralPoints}`);
    console.log(`   Referrer New Balance: ${newBalance}`);
    console.log(`   New User: ${newUserId}`);
    console.log(`   New User Points Awarded: ${referralPoints}`);
    console.log(`   New User New Balance: ${newUserNewBalance}`);
    console.log(`   New Referral Count: ${newReferralCount}/${maxReferrals}`);
    
    return {
      success: true,
      referrerId: referrerId,
      referrerPointsAwarded: referralPoints,
      referrerNewBalance: newBalance,
      newUserId: newUserId,
      newUserPointsAwarded: referralPoints,
      newUserNewBalance: newUserNewBalance,
      newReferralCount: newReferralCount,
    };
    
  } catch (error) {
    console.error(`❌ Error processing referral: ${error.message}`);
    console.error(error);
    
    // Don't throw error - we don't want to block user registration
    // Just log it and continue
    return {
      success: false,
      error: error.message,
    };
  }
};

/**
 * Process Referral Code (Called from Flutter after user registration)
 * This function is called after user signs up, if they provided a referral code
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.referralCode - Referral code to process
 * @returns {Object} Result with success status
 */
exports.processReferralCode = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    
    const userId = request.auth.uid;
    const { referralCode } = request.data;
    
    if (!referralCode || typeof referralCode !== 'string') {
      throw new HttpsError('invalid-argument', 'Referral code is required');
    }
    
    console.log(`🔄 Processing referral code ${referralCode} for user ${userId}`);
    
    // Check if user already has a referrer
    const userDocRef = admin.firestore()
      .collection('users')
      .doc(userId);
    
    let userDoc = await userDocRef.get();
    let userData = userDoc.exists ? userDoc.data() : null;
    
    // If user document doesn't exist, create it from Firebase Auth
    if (!userDoc.exists) {
      console.log(`⚠️ User document not found for ${userId}, creating from Auth...`);
      
      try {
        // Get user from Firebase Auth
        const authUser = await admin.auth().getUser(userId);
        
        // Create user document
        const newUserData = {
          email: authUser.email || null,
          displayName: authUser.displayName || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          referral_code: null, // Will be set after processing referral
          referred_by: null, // Will be set if referral code is valid
          referred_by_code: referralCode.toUpperCase().trim(), // Store referral code for processing
        };
        
        await userDocRef.set(newUserData, { merge: true });
        console.log(`✅ User document created for ${userId}`);
        
        // Refresh userDoc
        userDoc = await userDocRef.get();
        userData = userDoc.data();
      } catch (authError) {
        console.error(`❌ Error getting user from Auth: ${authError.message}`);
        throw new HttpsError('not-found', 'User document not found and could not create from Auth');
      }
    }
    
    // Check if user was already referred
    if (userData?.referred_by) {
      console.log(`⚠️ User ${userId} was already referred by ${userData.referred_by}`);
      return {
        success: false,
        message: 'User was already referred',
        referredBy: userData.referred_by,
      };
    }
    
    // Validate referral code format
    const normalizedCode = referralCode.toUpperCase().trim();
    if (normalizedCode.length !== 8 || !/^[A-Z0-9]{8}$/.test(normalizedCode)) {
      throw new HttpsError('invalid-argument', 'Invalid referral code format. Referral code must be 8 alphanumeric characters.');
    }
    
    // Find referrer by referral code
    // Referral code is first 8 characters of user ID (uppercase)
    let referrerDoc = null;
    let referrerId = null;
    
    // First, try to find by referral_code field
    const referrerQuery = await admin.firestore()
      .collection('users')
      .where('referral_code', '==', normalizedCode)
      .limit(1)
      .get();
    
    if (!referrerQuery.empty) {
      referrerDoc = referrerQuery.docs[0];
      referrerId = referrerDoc.id;
      console.log(`✅ Found referrer by referral_code field: ${referrerId}`);
    } else {
      // If not found by referral_code field, the referral code doesn't exist
      // This means either:
      // 1. The referral code is invalid
      // 2. The referrer hasn't set up their referral code yet
      console.log(`⚠️ Referral code ${normalizedCode} not found in any user document`);
      throw new HttpsError('not-found', `Referral code ${normalizedCode} not found. Please check the code and try again.`);
    }
    
    // Prevent self-referral
    if (referrerId === userId) {
      throw new HttpsError('invalid-argument', 'Cannot refer yourself');
    }
    
    // Get referrer data
    const referrerData = referrerDoc.data();
    
    // Check if referrer has reached max referrals (5)
    const referralStatsRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referral_stats')
      .doc('stats');
    
    const referralStatsDoc = await referralStatsRef.get();
    const referralStats = referralStatsDoc.exists ? referralStatsDoc.data() : {};
    const currentReferralCount = referralStats.referral_count || 0;
    const maxReferrals = 5;
    
    if (currentReferralCount >= maxReferrals) {
      console.log(`⚠️ Referrer ${referrerId} has reached max referrals (${maxReferrals})`);
      
      // Still store referral but don't give points
      await userDocRef.update({
        referred_by: referrerId,
        referred_by_code: normalizedCode,
        referral_status: 'max_reached',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return {
        success: false,
        message: 'Referrer has reached maximum referrals',
        maxReached: true,
      };
    }
    
    // Check if this user was already referred (prevent duplicate)
    const existingReferral = await admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referrals')
      .where('referred_user_id', '==', userId)
      .limit(1)
      .get();
    
    if (!existingReferral.empty) {
      console.log(`⚠️ User ${userId} was already referred by ${referrerId}`);
      return {
        success: false,
        message: 'User was already referred by this referrer',
      };
    }
    
    // Use fixed 500 points for referral
    const referralPoints = 500;
    
    console.log(`💰 Giving ${referralPoints} points to referrer ${referrerId}`);
    console.log(`💰 Giving ${referralPoints} points to new user ${userId} (referred user)`);
    
    // Get referrer's current point balance
    const balanceDocRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('point_balance')
      .doc('balance');
    
    const balanceDoc = await balanceDocRef.get();
    const currentBalance = balanceDoc.exists ? (balanceDoc.data().total_points || 0) : 0;
    const currentTotalEarned = balanceDoc.exists ? (balanceDoc.data().total_earned || 0) : 0;
    const newBalance = currentBalance + referralPoints;
    const newTotalEarned = currentTotalEarned + referralPoints;
    
    // Get new user's current point balance
    const newUserBalanceDocRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('point_balance')
      .doc('balance');
    
    const newUserBalanceDoc = await newUserBalanceDocRef.get();
    const newUserCurrentBalance = newUserBalanceDoc.exists ? (newUserBalanceDoc.data().total_points || 0) : 0;
    const newUserCurrentTotalEarned = newUserBalanceDoc.exists ? (newUserBalanceDoc.data().total_earned || 0) : 0;
    const newUserNewBalance = newUserCurrentBalance + referralPoints;
    const newUserNewTotalEarned = newUserCurrentTotalEarned + referralPoints;
    
    // Update referral count
    const newReferralCount = currentReferralCount + 1;
    
    // Create point transaction for referrer
    const transactionId = crypto.randomUUID();
    const now = admin.firestore.Timestamp.now();
    const transaction = {
      id: transactionId,
      user_id: referrerId,
      points: referralPoints,
      activity: 'referral',
      reference_id: userId,
      description: `Referans kodu ile yeni kullanıcı (${normalizedCode})`,
      earned_at: now,
      created_at: now,
      updated_at: now,
    };
    
    // Create point transaction for new user (referred user gets 500 points)
    const newUserTransactionId = crypto.randomUUID();
    const newUserTransaction = {
      id: newUserTransactionId,
      user_id: userId,
      points: referralPoints,
      activity: 'referral',
      reference_id: referrerId,
      description: `Referans kodu ile kayıt bonusu (${normalizedCode})`,
      earned_at: now,
      created_at: now,
      updated_at: now,
    };
    
    // Batch write
    const batch = admin.firestore().batch();
    
    // 1. Update new user's document
    batch.update(userDocRef, {
      referral_code: userId.substring(0, 8).toUpperCase(),
      referred_by: referrerId,
      referred_by_code: normalizedCode,
      referral_status: 'success',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // 2. Add point transaction for referrer
    const transactionRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('point_transactions')
      .doc(transactionId);
    batch.set(transactionRef, transaction);
    
    // 3. Update referrer's point balance
    batch.set(balanceDocRef, {
      user_id: referrerId,
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
    
    // 4. Add point transaction for new user (referred)
    const newUserTransactionRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('point_transactions')
      .doc(newUserTransactionId);
    batch.set(newUserTransactionRef, newUserTransaction);
    
    // 5. Update new user's point balance
    batch.set(newUserBalanceDocRef, {
      user_id: userId,
      total_points: newUserNewBalance,
      total_earned: newUserNewTotalEarned,
      total_spent: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().total_spent || 0) : 0,
      rewarded_ad_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().rewarded_ad_count || 0) : 0,
      transaction_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().transaction_count || 0) : 0,
      daily_login_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().daily_login_count || 0) : 0,
      weekly_streak_count: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().weekly_streak_count || 0) : 0,
      longest_streak: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().longest_streak || 0) : 0,
      last_daily_login: newUserBalanceDoc.exists ? (newUserBalanceDoc.data().last_daily_login || null) : null,
      last_earned_at: now,
      updated_at: now,
    }, { merge: true });
    
    // 6. Create referral record
    const referralRecordRef = admin.firestore()
      .collection('users')
      .doc(referrerId)
      .collection('referrals')
      .doc();
    batch.set(referralRecordRef, {
      referred_user_id: userId,
      referred_user_email: userData.email || null,
      referred_user_name: userData.displayName || null,
      points_awarded: referralPoints,
      referred_at: now,
      created_at: now,
      updated_at: now,
    });
    
    // 7. Update referral stats
    batch.set(referralStatsRef, {
      user_id: referrerId,
      referral_count: newReferralCount,
      total_points_earned: (referralStats.total_points_earned || 0) + referralPoints,
      last_referral_at: now,
      updated_at: now,
    }, { merge: true });
    
    // Commit batch
    await batch.commit();
    
    console.log(`✅ Referral processed successfully:`);
    console.log(`   Referrer: ${referrerId} - Points: ${referralPoints}, New balance: ${newBalance}`);
    console.log(`   New user: ${userId} - Points: ${referralPoints}, New balance: ${newUserNewBalance}`);
    console.log(`   Referral count: ${newReferralCount}`);
    
    return {
      success: true,
      message: 'Referral code processed successfully',
      pointsAwarded: referralPoints,
      newReferralCount: newReferralCount,
      referrerPointsAwarded: referralPoints,
      referrerNewBalance: newBalance,
      newUserId: userId,
      newUserPointsAwarded: referralPoints,
      newUserNewBalance: newUserNewBalance,
    };
    
  } catch (error) {
    console.error(`❌ Error processing referral code: ${error.message}`);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to process referral code: ${error.message}`);
  }
};

/**
 * Generate referral codes for all users who don't have one
 * Admin only function
 */
exports.generateReferralCodesForAllUsers = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    
    const userId = request.auth.uid;
    
    // Check if user is admin (simple check - you can enhance this)
    const adminListRef = admin.firestore().collection('admins').doc('admin_list');
    const adminListDoc = await adminListRef.get();
    
    if (!adminListDoc.exists) {
      throw new HttpsError('permission-denied', 'Admin list not found');
    }
    
    const adminList = adminListDoc.data();
    const adminUserIds = adminList.userIds || [];
    
    if (!adminUserIds.includes(userId)) {
      throw new HttpsError('permission-denied', 'Only admins can generate referral codes');
    }
    
    console.log(`🔄 Admin ${userId} is generating referral codes for all users...`);
    
    // Get all users
    const usersSnapshot = await admin.firestore().collection('users').get();
    console.log(`📊 Total users found: ${usersSnapshot.size}`);
    
    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    
    // Process in batches to avoid timeout
    const batchSize = 500;
    const batches = [];
    
    for (let i = 0; i < usersSnapshot.docs.length; i += batchSize) {
      batches.push(usersSnapshot.docs.slice(i, i + batchSize));
    }
    
    for (const batch of batches) {
      const writeBatch = admin.firestore().batch();
      
      for (const userDoc of batch) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        
        // Check if user already has a referral code
        if (userData.referral_code && userData.referral_code.length === 8) {
          skippedCount++;
          continue;
        }
        
        // Generate referral code (first 8 characters of user ID, uppercase)
        const referralCode = userId.substring(0, 8).toUpperCase();
        
        writeBatch.update(userDoc.ref, {
          referral_code: referralCode,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        updatedCount++;
      }
      
      // Commit batch
      await writeBatch.commit();
      console.log(`✅ Processed batch: ${updatedCount} updated, ${skippedCount} skipped`);
    }
    
    console.log(`✅ Referral code generation completed:`);
    console.log(`   Updated: ${updatedCount}`);
    console.log(`   Skipped: ${skippedCount}`);
    console.log(`   Errors: ${errorCount}`);
    
    return {
      success: true,
      message: 'Referral codes generated successfully',
      updated: updatedCount,
      skipped: skippedCount,
      errors: errorCount,
      total: usersSnapshot.size,
    };
    
  } catch (error) {
    console.error(`❌ Error generating referral codes: ${error.message}`);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to generate referral codes: ${error.message}`);
  }
};

