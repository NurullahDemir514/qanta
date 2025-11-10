const admin = require('firebase-admin');
const {HttpsError} = require('firebase-functions/v2/https');

/**
 * Check and Convert Amazon Rewards to Gift Card
 * When user reaches 100 TL threshold, creates a gift card request for admin
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.userId - User ID
 * @param {string} request.data.amazonEmail - User's Amazon account email
 * @returns {Object} Result with success status, gift cards created, remaining balance
 */
exports.checkAndConvertToGiftCard = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { userId, amazonEmail, amount } = request.data;
    
    if (!userId || !amazonEmail) {
      throw new HttpsError('invalid-argument', 'User ID and Amazon email are required');
    }
    
    // Amount is optional - if not provided, convert all available (100 TL multiples)
    let requestedAmount = amount;
    if (!requestedAmount) {
      // Legacy behavior: convert all available balance in 100 TL multiples
      requestedAmount = null; // Will be calculated below
    } else {
      // Validate requested amount
      if (requestedAmount < 100.0) {
        throw new HttpsError('invalid-argument', 'Amount must be at least 100 TL');
      }
      if (requestedAmount % 100.0 !== 0) {
        throw new HttpsError('invalid-argument', 'Amount must be a multiple of 100 TL');
      }
    }

    // Verify user is requesting for themselves
    if (request.auth.uid !== userId) {
      throw new HttpsError('permission-denied', 'Users can only request gift cards for themselves');
    }

    // Get user stats
    const statsDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('amazon_reward_stats')
      .doc('stats')
      .get();

    if (!statsDoc.exists) {
      throw new Error('User stats not found');
    }

    const stats = statsDoc.data();
    const currentBalance = stats.current_balance || 0;

    // Determine how much to convert
    let amountToConvert;
    if (requestedAmount) {
      // User requested specific amount
      if (currentBalance < requestedAmount) {
        return {
          success: false,
          message: `Balance ${currentBalance} TL is less than requested amount ${requestedAmount} TL`,
          remainingBalance: currentBalance,
        };
      }
      amountToConvert = requestedAmount;
    } else {
      // Legacy: convert all available in 100 TL multiples
      if (currentBalance < 100.0) {
        return {
          success: false,
          message: `Balance ${currentBalance} TL is below 100 TL threshold`,
          remainingBalance: currentBalance,
        };
      }
      amountToConvert = Math.floor(currentBalance / 100.0) * 100.0;
    }

    // Get user email for admin request
    // Try Firestore first, then Firebase Auth
    let userEmail = 'N/A';
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      userEmail = userData.email || 'N/A';
    } else {
      // User document doesn't exist, try Firebase Auth
      try {
        const authUser = await admin.auth().getUser(userId);
        userEmail = authUser.email || 'N/A';
        
        // Optionally create user document (but don't fail if it doesn't work)
        try {
          await admin.firestore()
            .collection('users')
            .doc(userId)
            .set({
              email: authUser.email || 'N/A',
              name: authUser.displayName || 'N/A',
              created_at: admin.firestore.FieldValue.serverTimestamp(),
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        } catch (createError) {
          console.log('⚠️ Could not create user document:', createError.message);
          // Continue anyway
        }
      } catch (authError) {
        console.log('⚠️ Could not get user from Auth:', authError.message);
        // Continue with 'N/A' email
      }
    }

    // Calculate how many gift cards can be created (100 TL each)
    const giftCardsToCreate = Math.floor(amountToConvert / 100.0);
    const amountPerCard = 100.0;
    const totalConverted = giftCardsToCreate * amountPerCard;
    const remainingBalance = currentBalance - totalConverted;

    // Get credits to convert (oldest first, up to totalConverted)
    // Note: We get all credits and filter in memory to avoid composite index requirement
    const creditsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('amazon_reward_credits')
      .get();

    // Filter accumulated credits and sort by earned_at
    const accumulatedCredits = creditsSnapshot.docs
      .filter(doc => {
        const data = doc.data();
        return data.status === 'accumulated';
      })
      .sort((a, b) => {
        const aTime = a.data().earned_at?.toMillis() || 0;
        const bTime = b.data().earned_at?.toMillis() || 0;
        return aTime - bTime;
      });

    let creditsToConvert = [];
    let totalAmount = 0;

    for (const creditDoc of accumulatedCredits) {
      if (totalAmount >= totalConverted) break;
      
      const credit = creditDoc.data();
      const creditAmount = credit.amount || 0;
      
      if (totalAmount + creditAmount <= totalConverted) {
        creditsToConvert.push({
          id: creditDoc.id,
          amount: creditAmount,
        });
        totalAmount += creditAmount;
      } else {
        // Partial conversion needed (shouldn't happen with 100 TL increments, but handle it)
        const remainingNeeded = totalConverted - totalAmount;
        if (remainingNeeded > 0) {
          creditsToConvert.push({
            id: creditDoc.id,
            amount: remainingNeeded,
            partial: true,
          });
          totalAmount += remainingNeeded;
        }
        break;
      }
    }

    // Create gift cards and admin requests
    const giftCardIds = [];
    const batch = admin.firestore().batch();
    const now = admin.firestore.Timestamp.now();

    // Distribute credits across gift cards
    let creditIndex = 0;
    for (let i = 0; i < giftCardsToCreate; i++) {
      const giftCardId = admin.firestore().collection('users').doc().id;
      giftCardIds.push(giftCardId);

      // Collect credits for this gift card (100 TL worth)
      const cardCreditIds = [];
      let cardTotal = 0;
      
      while (creditIndex < creditsToConvert.length && cardTotal < amountPerCard) {
        const credit = creditsToConvert[creditIndex];
        if (cardTotal + credit.amount <= amountPerCard) {
          cardCreditIds.push(credit.id);
          cardTotal += credit.amount;
          creditIndex++;
        } else {
          // Partial credit needed
          break;
        }
      }

      // Create gift card document
      const giftCardRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('amazon_gift_cards')
        .doc(giftCardId);

      batch.set(giftCardRef, {
        id: giftCardId,
        user_id: userId,
        amount: amountPerCard,
        amazon_code: null, // Admin will fill this
        amazon_claim_code: null, // Admin will fill this
        purchased_at: null, // Admin will fill this
        sent_at: null, // Admin will fill this
        status: 'pending', // pending -> sent -> redeemed
        recipient_email: amazonEmail,
        credit_ids: cardCreditIds,
        created_at: now,
        updated_at: now,
      });

      // Create admin request
      const adminRequestRef = admin.firestore()
        .collection('admin_requests')
        .doc();

      batch.set(adminRequestRef, {
        type: 'amazon_gift_card',
        user_id: userId,
        user_email: userEmail,
        gift_card_id: giftCardId,
        amazon_email: amazonEmail,
        amount: amountPerCard,
        status: 'pending', // pending -> completed
        created_at: now,
        updated_at: now,
      });
    }

    // Mark credits as converted
    // Map each credit to its gift card
    const creditToGiftCardMap = new Map();
    let currentGiftCardIndex = 0;
    let currentGiftCardTotal = 0;
    
    for (const credit of creditsToConvert) {
      if (currentGiftCardTotal >= amountPerCard && currentGiftCardIndex < giftCardIds.length - 1) {
        currentGiftCardIndex++;
        currentGiftCardTotal = 0;
      }
      
      if (currentGiftCardIndex < giftCardIds.length) {
        creditToGiftCardMap.set(credit.id, giftCardIds[currentGiftCardIndex]);
        currentGiftCardTotal += credit.amount;
      }
    }

    // Read all credit docs first (before batch operations)
    const creditDocs = [];
    for (const credit of creditsToConvert) {
      const creditDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('amazon_reward_credits')
        .doc(credit.id)
        .get();
      creditDocs.push({ doc: creditDoc, credit: credit });
    }

    // Now update credits in batch
    for (const { doc: creditDoc, credit } of creditDocs) {
      const creditRef = creditDoc.ref;
      
      if (credit.partial) {
        // Partial conversion - update amount
        const currentAmount = creditDoc.data().amount || 0;
        const newAmount = currentAmount - credit.amount;
        
        batch.update(creditRef, {
          status: 'accumulated', // Keep as accumulated if partial
          amount: newAmount,
          updated_at: now,
        });
      } else {
        // Full conversion - assign to gift card
        const assignedGiftCardId = creditToGiftCardMap.get(credit.id) || giftCardIds[0];
        
        batch.update(creditRef, {
          status: 'converted',
          gift_card_id: assignedGiftCardId,
          updated_at: now,
        });
      }
    }

    // Update stats
    const statsRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('amazon_reward_stats')
      .doc('stats');

    batch.update(statsRef, {
      current_balance: remainingBalance,
      total_converted: (stats.total_converted || 0) + totalConverted,
      total_gift_cards: (stats.total_gift_cards || 0) + giftCardsToCreate,
      last_converted_at: now,
      updated_at: now,
    });

    // Commit all changes
    await batch.commit();

    console.log(`✅ Created ${giftCardsToCreate} gift card request(s) for user ${userId}`);
    console.log(`   Converted: ${totalConverted} TL, Remaining: ${remainingBalance} TL`);

    return {
      success: true,
      giftCardsCreated: giftCardsToCreate,
      totalConverted: totalConverted,
      remainingBalance: remainingBalance,
      message: `Successfully created ${giftCardsToCreate} gift card request(s)`,
    };
  } catch (error) {
    console.error('❌ Error converting to gift card:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to convert: ${error.message}`);
  }
};

/**
 * Send push notification when gift card status changes to 'sent'
 * This function should be called by admin when they mark gift card as sent
 * 
 * @param {Object} request - Request object with data
 * @param {string} request.data.userId - User ID
 * @param {string} request.data.giftCardId - Gift card ID
 * @param {number} request.data.amount - Gift card amount
 */
/**
 * Create Gift Card Request From Points
 * Creates a gift card request directly when points have already been spent
 * This bypasses the TL-based balance check since points are already deducted
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.userId - User ID
 * @param {string} request.data.amazonEmail - User's Amazon account email
 * @param {number} request.data.amount - Amount in TL (must be multiple of 100)
 * @param {number} request.data.pointsSpent - Points that were already spent
 * @returns {Object} Result with success status, gift cards created
 */
exports.createGiftCardRequestFromPoints = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { userId, amazonEmail, amount, pointsSpent, provider, phoneNumber } = request.data;
    
    if (!userId || !amazonEmail || !amount || !pointsSpent) {
      throw new HttpsError('invalid-argument', 'User ID, Amazon email, amount, and pointsSpent are required');
    }
    
    // Provider defaults to 'amazon' if not provided
    // IMPORTANT: Always use the provided provider value, don't default unless truly missing
    const giftCardProvider = (provider && typeof provider === 'string' && provider.trim() !== '') 
      ? provider.trim() 
      : 'amazon';
    const userPhoneNumber = phoneNumber || '';
    
    // Debug: Log provider information
    console.log('📦 createGiftCardRequestFromPoints - Provider info:', {
      providedProvider: provider,
      giftCardProvider: giftCardProvider,
      userId: userId,
      amount: amount,
      pointsSpent: pointsSpent
    });
    
    // Validate amount
    if (amount < 100.0) {
      throw new HttpsError('invalid-argument', 'Amount must be at least 100 TL');
    }
    if (amount % 100.0 !== 0) {
      throw new HttpsError('invalid-argument', 'Amount must be a multiple of 100 TL');
    }

    // Verify user is requesting for themselves
    if (request.auth.uid !== userId) {
      throw new HttpsError('permission-denied', 'Users can only request gift cards for themselves');
    }

    // Get user email for admin request
    let userEmail = 'N/A';
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      userEmail = userData.email || 'N/A';
    } else {
      try {
        const authUser = await admin.auth().getUser(userId);
        userEmail = authUser.email || 'N/A';
      } catch (authError) {
        console.log('⚠️ Could not get user from Auth:', authError.message);
      }
    }

    // Calculate how many gift cards can be created (100 TL each)
    const giftCardsToCreate = Math.floor(amount / 100.0);
    const amountPerCard = 100.0;

    // Create gift cards and admin requests
    const giftCardIds = [];
    const batch = admin.firestore().batch();
    const now = admin.firestore.Timestamp.now();

    // Create gift cards directly without credit conversion
    for (let i = 0; i < giftCardsToCreate; i++) {
      const giftCardId = admin.firestore().collection('users').doc().id;
      giftCardIds.push(giftCardId);

      // Create gift card document
      const giftCardRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('amazon_gift_cards')
        .doc(giftCardId);

      batch.set(giftCardRef, {
        id: giftCardId,
        user_id: userId,
        amount: amountPerCard,
        amazon_code: null, // Admin will fill this
        amazon_claim_code: null, // Admin will fill this
        purchased_at: null, // Admin will fill this
        sent_at: null, // Admin will fill this
        status: 'pending', // pending -> sent -> redeemed
        recipient_email: amazonEmail,
        provider: giftCardProvider, // IMPORTANT: Store provider in gift card document
        credit_ids: [], // No credits used (points were spent directly)
        points_spent: pointsSpent / giftCardsToCreate, // Distribute points across cards
        created_at: now,
        updated_at: now,
      });

      // Create admin request
      const adminRequestRef = admin.firestore()
        .collection('admin_requests')
        .doc();

      const adminRequestData = {
        type: 'amazon_gift_card',
        user_id: userId,
        user_email: userEmail,
        gift_card_id: giftCardId,
        amazon_email: amazonEmail,
        phone_number: userPhoneNumber,
        provider: giftCardProvider, // Always include provider field
        amount: amountPerCard,
        points_spent: pointsSpent / giftCardsToCreate,
        status: 'pending', // pending -> completed
        created_at: now,
        updated_at: now,
      };
      
      // Debug: Log what we're saving
      console.log(`💾 Saving admin request ${giftCardId} with provider: ${giftCardProvider}`);
      
      batch.set(adminRequestRef, adminRequestData);
    }

    // Commit batch
    await batch.commit();

    console.log(`✅ Created ${giftCardsToCreate} gift card request(s) for user ${userId} from ${pointsSpent} points`);

    return {
      success: true,
      message: `Successfully created ${giftCardsToCreate} gift card request(s)`,
      giftCardsCreated: giftCardsToCreate,
      pointsSpent: pointsSpent,
    };
  } catch (error) {
    console.error('❌ Error creating gift card request from points:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to create gift card request: ${error.message}`);
  }
};

exports.notifyGiftCardSent = async (request) => {
  try {
    const { userId, giftCardId, amount, provider } = request.data;
    
    if (!userId || !giftCardId) {
      throw new HttpsError('invalid-argument', 'User ID and Gift Card ID are required');
    }

    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcm_token || userData.fcmToken;

    if (!fcmToken) {
      console.log('⚠️ No FCM token found for user, skipping notification');
      return {
        success: false,
        message: 'No FCM token found',
      };
    }

    // Provider name mapping
    const providerNames = {
      'amazon': 'Amazon',
      'paribu': 'Paribu Cineverse',
      'dnr': 'D&R',
      'gratis': 'Gratis',
    };
    
    const giftCardProvider = (provider && typeof provider === 'string' && provider.trim() !== '') 
      ? provider.trim() 
      : 'amazon';
    const providerName = providerNames[giftCardProvider] || 'Hediye Kartı';

    // Send push notification
    const message = {
      notification: {
        title: '🎉 Hediye Kartınız Hazır!',
        body: `${amount} TL ${providerName} hediye kartınız hazır. Hemen kullanabilirsiniz!`,
      },
      data: {
        type: 'amazon_gift_card',
        gift_card_id: giftCardId,
        amount: amount.toString(),
        provider: giftCardProvider,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'qanta_reminders',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Push notification sent: ${response} for ${providerName} gift card`);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to send notification: ${error.message}`);
  }
};
