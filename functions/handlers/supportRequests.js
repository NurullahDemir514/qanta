const admin = require('firebase-admin');
const {HttpsError} = require('firebase-functions/v2/https');
const {v4: uuidv4} = require('uuid');

/**
 * Parse gift card information from support request message
 * @param {string} message - Support request message
 * @returns {Object|null} Parsed gift card info or null if not found
 */
function parseGiftCardFromMessage(message) {
  const lowerMessage = message.toLowerCase();
  
  // Provider detection
  let provider = 'amazon'; // Default
  if (lowerMessage.includes('paribu') || lowerMessage.includes('cineverse')) {
    provider = 'paribu';
  } else if (lowerMessage.includes('d&r') || lowerMessage.includes('dnr')) {
    provider = 'dnr';
  } else if (lowerMessage.includes('gratis')) {
    provider = 'gratis';
  } else if (lowerMessage.includes('amazon')) {
    provider = 'amazon';
  }

  // Extract TL amounts (look for patterns like "100 TL", "500 TL", "100tl", etc.)
  const tlPattern = /(\d+(?:\.\d+)?)\s*tl/gi;
  const tlMatches = message.match(tlPattern);
  let amount = null;
  if (tlMatches && tlMatches.length > 0) {
    // Take the first valid amount found
    const amountStr = tlMatches[0].replace(/\s*tl/gi, '');
    amount = parseFloat(amountStr);
  }

  // Extract quantity (look for patterns like "2 adet", "2 kart", "2x", etc.)
  const quantityPattern = /(\d+)\s*(?:adet|kart|x|×)/gi;
  const quantityMatches = message.match(quantityPattern);
  let quantity = 1; // Default to 1
  if (quantityMatches && quantityMatches.length > 0) {
    const qtyStr = quantityMatches[0].replace(/\s*(?:adet|kart|x|×)/gi, '');
    quantity = parseInt(qtyStr, 10) || 1;
  }

  // If amount is found, use it; otherwise calculate from quantity
  if (!amount) {
    // Default amounts based on provider
    const defaultAmounts = {
      'amazon': 100,
      'paribu': 500,
      'dnr': 100,
      'gratis': 100,
    };
    amount = (defaultAmounts[provider] || 100) * quantity;
  } else {
    // If amount is specified, adjust quantity if needed
    const defaultAmounts = {
      'amazon': 100,
      'paribu': 500,
      'dnr': 100,
      'gratis': 100,
    };
    const defaultAmount = defaultAmounts[provider] || 100;
    if (amount >= defaultAmount) {
      quantity = Math.floor(amount / defaultAmount);
      amount = defaultAmount * quantity; // Round to valid amount
    }
  }

  // Validate minimum amounts
  const minimumAmounts = {
    'amazon': 100,
    'paribu': 500,
    'dnr': 100,
    'gratis': 100,
  };
  const minAmount = minimumAmounts[provider] || 100;
  
  if (amount < minAmount) {
    console.log(`⚠️ Amount ${amount} TL is below minimum ${minAmount} TL for ${provider}`);
    return null;
  }

  // Extract email (look for email pattern)
  const emailPattern = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;
  const emailMatches = message.match(emailPattern);
  let giftCardEmail = null;
  if (emailMatches && emailMatches.length > 0) {
    giftCardEmail = emailMatches[0];
  }

  // Extract phone (look for Turkish phone patterns)
  const phonePattern = /(?:0)?(?:5\d{2}|5\d{2})\s?\d{3}\s?\d{2}\s?\d{2}/g;
  const phoneMatches = message.match(phonePattern);
  let phoneNumber = null;
  if (phoneMatches && phoneMatches.length > 0) {
    phoneNumber = phoneMatches[0].replace(/\s/g, '');
  }

  return {
    provider,
    amount,
    quantity,
    giftCardEmail,
    phoneNumber,
  };
}

/**
 * Process gift card request from support message
 * Parses message, deducts points, and creates admin request
 */
async function processGiftCardRequestFromMessage(userId, userEmail, message, subject) {
  // Parse gift card info from message
  const giftCardInfo = parseGiftCardFromMessage(message);
  
  if (!giftCardInfo) {
    console.log(`⚠️ Could not parse gift card info from message`);
    return;
  }

  console.log(`📋 Parsed gift card info:`, giftCardInfo);

  // Get user's point balance
  const balanceDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('point_balance')
    .doc('balance')
    .get();

  if (!balanceDoc.exists) {
    console.log(`⚠️ User point balance not found for ${userId}`);
    return;
  }

  const balanceData = balanceDoc.data();
  const currentPoints = balanceData.total_points || 0;

  // Calculate required points (200 points = 1 TL)
  const requiredPoints = Math.ceil(giftCardInfo.amount * 200);
  const totalPointsNeeded = requiredPoints * giftCardInfo.quantity;

  console.log(`💰 Current points: ${currentPoints}, Required: ${totalPointsNeeded}`);

  if (currentPoints < totalPointsNeeded) {
    console.log(`⚠️ Insufficient points: ${currentPoints} < ${totalPointsNeeded}`);
    return;
  }

  // Get gift card email (use parsed email or user email)
  const giftCardEmail = giftCardInfo.giftCardEmail || userEmail;

  if (!giftCardEmail || giftCardEmail === 'N/A') {
    console.log(`⚠️ Gift card email not found`);
    return;
  }

  // Deduct points
  const batch = admin.firestore().batch();
  const now = admin.firestore.Timestamp.now();

  // Create point transaction for spending
  const transactionId = uuidv4();
  const transactionRef = admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('point_transactions')
    .doc(transactionId);

  batch.set(transactionRef, {
    id: transactionId,
    user_id: userId,
    points: -totalPointsNeeded, // Negative for spending
    activity: 'redemption',
    description: `${giftCardInfo.provider} Hediye Kartı (${giftCardInfo.amount * giftCardInfo.quantity} TL) - Destek Talebi`,
    earned_at: now,
    created_at: now,
    updated_at: now,
  });

  // Update point balance
  const newTotalPoints = currentPoints - totalPointsNeeded;
  const newTotalSpent = (balanceData.total_spent || 0) + totalPointsNeeded;

  batch.update(balanceDoc.ref, {
    total_points: newTotalPoints,
    total_spent: newTotalSpent,
    updated_at: now,
  });

  // Create gift card requests (one per card)
  const giftCardIds = [];
  for (let i = 0; i < giftCardInfo.quantity; i++) {
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
      amount: giftCardInfo.amount,
      amazon_code: null,
      amazon_claim_code: null,
      purchased_at: null,
      sent_at: null,
      status: 'pending',
      recipient_email: giftCardEmail,
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
      amazon_email: giftCardEmail,
      phone_number: giftCardInfo.phoneNumber || '',
      provider: giftCardInfo.provider,
      amount: giftCardInfo.amount,
      points_spent: requiredPoints,
      status: 'pending',
      created_at: now,
      updated_at: now,
    });
  }

  // Commit all changes
  await batch.commit();

  console.log(`✅ Successfully processed gift card request:`);
  console.log(`   Provider: ${giftCardInfo.provider}`);
  console.log(`   Amount: ${giftCardInfo.amount} TL x ${giftCardInfo.quantity} = ${giftCardInfo.amount * giftCardInfo.quantity} TL`);
  console.log(`   Points deducted: ${totalPointsNeeded}`);
  console.log(`   Gift cards created: ${giftCardIds.length}`);
}

/**
 * Submit Support Request
 * Allows users to submit support/contact form requests
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.subject - Subject of the support request
 * @param {string} request.data.message - Message content
 * @param {string} request.data.category - Category (general, bug, feature, account, payment, other)
 * @returns {Object} Result with success status and request ID
 */
exports.submitSupportRequest = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const userId = request.auth.uid;
    const {subject, message, category} = request.data;

    // Validation
    if (!subject || typeof subject !== 'string' || subject.trim().length < 3) {
      throw new HttpsError('invalid-argument', 'Subject must be at least 3 characters');
    }

    if (!message || typeof message !== 'string' || message.trim().length < 10) {
      throw new HttpsError('invalid-argument', 'Message must be at least 10 characters');
    }

    const validCategories = ['general', 'bug', 'feature', 'account', 'payment', 'other'];
    if (!category || !validCategories.includes(category)) {
      throw new HttpsError('invalid-argument', 'Invalid category');
    }

    // Get user info
    let userEmail = 'N/A';
    let userName = 'N/A';
    
    try {
      const userRecord = await admin.auth().getUser(userId);
      userEmail = userRecord.email || 'N/A';
      userName = userRecord.displayName || 'N/A';
    } catch (authError) {
      console.log('⚠️ Could not get user from Auth:', authError.message);
    }

    // Try to get additional info from Firestore
    try {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.email && userData.email !== 'N/A') {
          userEmail = userData.email;
        }
        if (userData.name && userData.name !== 'N/A') {
          userName = userData.name;
        }
      }
    } catch (firestoreError) {
      console.log('⚠️ Could not get user from Firestore:', firestoreError.message);
    }

    // Create support request
    const requestId = admin.firestore().collection('support_requests').doc().id;
    const now = admin.firestore.Timestamp.now();

    const supportRequest = {
      id: requestId,
      user_id: userId,
      user_email: userEmail,
      user_name: userName,
      subject: subject.trim(),
      message: message.trim(),
      category: category,
      status: 'pending', // pending -> in_progress -> resolved -> closed
      created_at: now,
      updated_at: now,
      resolved_at: null,
      messages: [
        {
          id: admin.firestore().collection('support_requests').doc().id,
          sender_type: 'user', // 'user' or 'admin'
          sender_id: userId,
          sender_name: userName,
          message: message.trim(),
          created_at: now,
        }
      ],
      admin_notes: null, // Deprecated - use messages array instead
    };

    const docRef = admin.firestore()
      .collection('support_requests')
      .doc(requestId);
    
    await docRef.set(supportRequest);

    // Verify the document was created
    const createdDoc = await docRef.get();
    if (!createdDoc.exists) {
      console.error(`❌ Failed to create support request: ${requestId}`);
      throw new HttpsError('internal', 'Failed to create support request document');
    }

    console.log(`✅ Support request created successfully: ${requestId} by user ${userId}`);
    console.log(`   Subject: ${subject.trim()}`);
    console.log(`   Category: ${category}`);
    console.log(`   User: ${userName} (${userEmail})`);

    // Check if this is a gift card request (category is 'payment' and subject contains gift card keywords)
    const isGiftCardRequest = category === 'payment' && 
      (subject.toLowerCase().includes('hediye kart') || 
       subject.toLowerCase().includes('gift card') ||
       message.toLowerCase().includes('hediye kart') ||
       message.toLowerCase().includes('gift card'));

    if (isGiftCardRequest) {
      try {
        console.log(`🎁 Detected gift card request, attempting to parse and process...`);
        await processGiftCardRequestFromMessage(userId, userEmail, message, subject);
      } catch (giftCardError) {
        // Don't fail the support request if gift card processing fails
        // Just log the error and continue
        console.error(`⚠️ Failed to process gift card request from message: ${giftCardError.message}`);
        console.error(`   Support request ${requestId} was still created successfully`);
      }
    }

    return {
      success: true,
      message: 'Support request submitted successfully',
      requestId: requestId,
    };
  } catch (error) {
    console.error('❌ Error submitting support request:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to submit support request: ${error.message}`);
  }
};

/**
 * Add Message to Support Request
 * Allows admin to send messages to users and users to reply
 * 
 * @param {Object} request - Request object with data and auth
 * @param {string} request.data.requestId - Support request ID
 * @param {string} request.data.message - Message content
 * @param {string} [request.data.senderType] - 'admin' or 'user' (defaults to auth user type)
 * @returns {Object} Result with success status and message ID
 */
exports.addSupportMessage = async (request) => {
  try {
    // Auth kontrolü
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const userId = request.auth.uid;
    const {requestId, message, senderType} = request.data;

    // Validation
    if (!requestId || typeof requestId !== 'string') {
      throw new HttpsError('invalid-argument', 'Request ID is required');
    }

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'Message cannot be empty');
    }

    // Get support request
    const requestRef = admin.firestore()
      .collection('support_requests')
      .doc(requestId);
    
    const requestDoc = await requestRef.get();
    
    if (!requestDoc.exists) {
      throw new HttpsError('not-found', 'Support request not found');
    }

    const supportRequest = requestDoc.data();

    // Check if user is admin
    let isAdminUser = false;
    try {
      const adminListDoc = await admin.firestore()
        .collection('admins')
        .doc('admin_list')
        .get();
      
      if (adminListDoc.exists) {
        const adminList = adminListDoc.data();
        isAdminUser = adminList.userIds && adminList.userIds.includes(userId);
      }
      
      // Also check predefined admin
      if (!isAdminUser && userId === 'obwsYff7JuNBEis9ENvX2pIdIKE2') {
        isAdminUser = true;
      }
    } catch (error) {
      console.log('⚠️ Could not check admin status:', error.message);
    }

    // Determine sender type
    let actualSenderType = senderType;
    if (!actualSenderType) {
      actualSenderType = isAdminUser ? 'admin' : 'user';
    }

    // Verify permissions
    if (actualSenderType === 'user' && supportRequest.user_id !== userId) {
      throw new HttpsError('permission-denied', 'Users can only message their own support requests');
    }

    if (actualSenderType === 'admin' && !isAdminUser) {
      throw new HttpsError('permission-denied', 'Only admins can send admin messages');
    }

    // Get sender info
    let senderName = 'Admin';
    if (actualSenderType === 'user') {
      senderName = supportRequest.user_name || 'User';
    } else {
      // Get admin name from auth or Firestore
      try {
        const adminRecord = await admin.auth().getUser(userId);
        senderName = adminRecord.displayName || adminRecord.email || 'Admin';
      } catch (authError) {
        console.log('⚠️ Could not get admin from Auth:', authError.message);
      }
    }

    // Create message
    const messageId = admin.firestore().collection('support_requests').doc().id;
    const now = admin.firestore.Timestamp.now();

    const newMessage = {
      id: messageId,
      sender_type: actualSenderType,
      sender_id: userId,
      sender_name: senderName,
      message: message.trim(),
      created_at: now,
    };

    // Update support request
    await requestRef.update({
      messages: admin.firestore.FieldValue.arrayUnion(newMessage),
      updated_at: now,
      // If admin sends message and status is pending, change to in_progress
      status: (actualSenderType === 'admin' && supportRequest.status === 'pending') 
        ? 'in_progress' 
        : supportRequest.status,
    });

    console.log(`✅ Message added to support request ${requestId} by ${actualSenderType} ${userId}`);

    // TODO: Send push notification to user if admin sent message
    if (actualSenderType === 'admin') {
      // Send notification to user
      console.log(`📧 Admin message sent to user ${supportRequest.user_id}`);
      // Notification logic can be added here
    }

    return {
      success: true,
      message: 'Message added successfully',
      messageId: messageId,
    };
  } catch (error) {
    console.error('❌ Error adding support message:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to add message: ${error.message}`);
  }
};

