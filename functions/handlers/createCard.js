/**
 * Create Card Handler
 * Kart oluşturma işlemini backend'de limit kontrolü ile yapar
 * 
 * Free kullanıcılar: Max 3 kart (debit + credit toplam)
 * Premium kullanıcılar: Sınırsız
 */

const {HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {getLocalizedMessage} = require("../utils/helpers");

/**
 * Get user tier (free/premium/premium_plus)
 */
async function getUserTier(userId) {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();
  
  if (!userDoc.exists) {
    return "free";
  }
  
  const userData = userDoc.data();
  
  // Test modu - Premium Plus olarak kabul et
  if (userData.isTestMode === true) {
    return "premium_plus";
  }
  
  // Premium Plus kontrolü
  if (userData.subscriptionStatus === "premium_plus" || 
      userData.isPremiumPlus === true) {
    return "premium_plus";
  }
  
  // Premium kontrolü
  if (userData.isPremium === true || 
      userData.subscriptionStatus === "premium") {
    return "premium";
  }
  
  return "free";
}

/**
 * Yeni kart/hesap oluştur (limit kontrolü ile)
 */
async function createCard(request) {
  // Auth kontrolü
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
  }

  const userId = request.auth.uid;
  const {
    type, // 'credit', 'debit', 'cash'
    name,
    bankName,
    balance,
    creditLimit,
    statementDay,
    dueDay,
  } = request.data;

  // Validation
  if (!type || !name) {
    throw new HttpsError(
        "invalid-argument",
        "type ve name gerekli",
    );
  }

  if (!["credit", "debit", "cash"].includes(type)) {
    throw new HttpsError(
        "invalid-argument",
        "type 'credit', 'debit' veya 'cash' olmalı",
    );
  }

  try {
    logger.info(`💳 Creating ${type} card for user ${userId}`);

    const db = admin.firestore();

    // Premium status kontrolü
    const userTier = await getUserTier(userId);
    logger.info(`   User tier: ${userTier}`);

    // Cash hesaplar için limit yok
    if (type !== "cash") {
      // Mevcut kart sayısını al (debit + credit)
      const accountsSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("accounts")
          .where("is_active", "==", true) // ✅ Sadece aktif kartları say
          .where("type", "in", ["credit", "debit"])
          .get();

      const currentCardCount = accountsSnapshot.size;
      logger.info(`   Current card count: ${currentCardCount}`);

      // Free kullanıcı için limit kontrolü
      if (userTier === "free" && currentCardCount >= 3) {
        logger.warn(`   ⚠️ Card limit reached for free user: ${currentCardCount}/3`);
        
        // Lokalize mesaj: Premium'dan free'ye geçenler için özel mesaj
        const locale = "tr"; // TODO: Kullanıcı dilini backend'e gönder
        const message = currentCardCount > 3
            ? getLocalizedMessage(locale, "cards.limitExceeded", {
              count: currentCardCount,
              deleteCount: currentCardCount - 2,
            })
            : getLocalizedMessage(locale, "cards.limitReached");
        
        throw new HttpsError(
            "resource-exhausted",
            message,
        );
      }
    }

    // Kartı oluştur
    const accountData = {
      user_id: userId,
      type: type,
      name: name,
      balance: balance || 0.0,
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Optional fields
    if (bankName) accountData.bank_name = bankName;
    if (creditLimit) accountData.credit_limit = creditLimit;
    if (statementDay) accountData.statement_day = statementDay;
    if (dueDay) accountData.due_day = dueDay;

    const docRef = await db
        .collection("users")
        .doc(userId)
        .collection("accounts")
        .add(accountData);

    logger.info(`✅ ${type} card created: ${docRef.id}`);

    return {
      success: true,
      accountId: docRef.id,
      message: `${type} kartı başarıyla oluşturuldu`,
    };
  } catch (error) {
    logger.error(`❌ createCard error for user ${userId}:`, error);
    
    // HttpsError ise direkt fırlat
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError(
        "internal",
        `Kart oluşturulamadı: ${error.message}`,
    );
  }
}

module.exports = {createCard};

