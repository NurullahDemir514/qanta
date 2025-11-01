/**
 * Helper Utilities
 * Genel yardımcı fonksiyonlar
 */

const admin = require("firebase-admin");
const {HttpsError} = require("firebase-functions/v2/https");
const fs = require("fs");
const path = require("path");

// Load localization files
const locales = {
  tr: JSON.parse(fs.readFileSync(path.join(__dirname, "../locales/tr.json"), "utf8")),
  en: JSON.parse(fs.readFileSync(path.join(__dirname, "../locales/en.json"), "utf8")),
};

/**
 * Get localized message with parameter substitution
 * @param {string} locale - Language code (tr/en)
 * @param {string} key - Dot-notation key (e.g., "limits.freeWithoutBonus")
 * @param {Object} params - Parameters to replace in the message
 * @return {string} Localized message
 */
function getLocalizedMessage(locale = "tr", key, params = {}) {
  const keys = key.split(".");
  let message = locales[locale] || locales.tr;
  
  for (const k of keys) {
    message = message[k];
    if (!message) {
      console.error(`Localization key not found: ${key} for locale: ${locale}`);
      return key;
    }
  }
  
  // Replace parameters {param} with actual values
  Object.keys(params).forEach((param) => {
    message = message.replace(new RegExp(`\\{${param}\\}`, "g"), params[param]);
  });
  
  return message;
}

// 🔓 Developer Bypass - Limitsiz kullanım için UID listesi
const DEVELOPER_BYPASS_UIDS = [
  //"R1ZBRZ8iaaRBiH1XIdg5RlV4ab23", // Onur - Developer (Limitsiz)
  //"tQLr6RQ0A4OQJI5FdsEmkgQFAa12", // Test User (Limitsiz)
];

// Aylık limitler - PREMIUM PLUS
const MONTHLY_LIMITS_PREMIUM_PLUS = {
  chat: 3000,            // Toplam AI mesaj: 3000/ay (Premium Plus)
  chat_with_image: 120,  // Görsel mesaj: 120/ay (Premium Plus)
};

// Aylık limitler - PREMIUM
const MONTHLY_LIMITS_PREMIUM = {
  chat: 1500,            // Toplam AI mesaj: 1500/ay (Premium)
  chat_with_image: 50,   // Görsel mesaj: 50/ay (Premium)
};

// Günlük limitler - FREE (günlük resetleniyor)
const DAILY_LIMITS_FREE = {
  chat: 10,              // Toplam AI mesaj: 10/gün (Free)
  chat_with_image: 2,    // Görsel mesaj: 2/gün (Free)
  max_bonus: 15,         // Reklamla kazanılabilecek max bonus (3 reklam x 5 = 15)
  bonus_per_ad: 5,       // Her reklam için bonus hak
};

/**
 * Kullanıcının premium tier'ını döndür
 * @param {string} userId - Kullanıcı ID
 * @return {string} "free" | "premium" | "premium_plus"
 */
async function getPremiumTier(userId) {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();
  
  if (!userDoc.exists) {
    return "free";
  }
  
  const userData = userDoc.data();
  
  // Test modu - Premium olarak kabul et
  if (userData.isTestMode === true) {
    return "premium";
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
 * Kullanıcının premium olup olmadığını kontrol et (backward compatibility)
 * @param {string} userId - Kullanıcı ID
 * @return {boolean} Premium ise true
 */
async function checkIsPremium(userId) {
  const tier = await getPremiumTier(userId);
  return tier === "premium" || tier === "premium_plus";
}

/**
 * Kullanıcının premium plus olup olmadığını kontrol et
 * @param {string} userId - Kullanıcı ID
 * @return {boolean} Premium Plus ise true
 */
async function checkIsPremiumPlus(userId) {
  const tier = await getPremiumTier(userId);
  return tier === "premium_plus";
}

/**
 * Kullanıcının timezone'una göre tarih oluştur
 * @param {string} timezone - Kullanıcının timezone offset (örn: "+03:00", "-05:00")
 * @return {string} YYYY-MM-DD formatında tarih
 */
function getUserLocalDateKey(timezone = "+03:00") {
  const now = new Date();
  
  // Timezone offset'i parse et (örn: "+03:00" -> 3, "-05:00" -> -5)
  const match = timezone.match(/([+-])(\d{2}):(\d{2})/);
  if (!match) {
    // Geçersiz format, UTC kullan
    return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}-${String(now.getUTCDate()).padStart(2, "0")}`;
  }
  
  const sign = match[1] === "+" ? 1 : -1;
  const hours = parseInt(match[2]);
  const minutes = parseInt(match[3]);
  const offsetMs = sign * (hours * 60 + minutes) * 60 * 1000;
  
  // Kullanıcının local saatini hesapla
  const localTime = new Date(now.getTime() + offsetMs);
  
  return `${localTime.getUTCFullYear()}-${String(localTime.getUTCMonth() + 1).padStart(2, "0")}-${String(localTime.getUTCDate()).padStart(2, "0")}`;
}

/**
 * Kullanıcının timezone'una göre ay anahtarı oluştur (Premium için)
 * @param {string} timezone - Kullanıcının timezone offset (örn: "+03:00", "-05:00")
 * @return {string} YYYY-MM formatında ay
 */
function getUserLocalMonthKey(timezone = "+03:00") {
  const now = new Date();
  
  // Timezone offset'i parse et
  const match = timezone.match(/([+-])(\d{2}):(\d{2})/);
  if (!match) {
    // Geçersiz format, UTC kullan
    return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
  }
  
  const sign = match[1] === "+" ? 1 : -1;
  const hours = parseInt(match[2]);
  const minutes = parseInt(match[3]);
  const offsetMs = sign * (hours * 60 + minutes) * 60 * 1000;
  
  // Kullanıcının local saatini hesapla
  const localTime = new Date(now.getTime() + offsetMs);
  
  return `${localTime.getUTCFullYear()}-${String(localTime.getUTCMonth() + 1).padStart(2, "0")}`;
}

/**
 * Günlük AI kullanım limitini kontrol et (MODEL ÇAĞRILMADAN ÖNCE)
 * @param {string} userId - Kullanıcı ID
 * @param {string} requestType - İstek tipi (chat, chat_with_image, categorize, vs.)
 * @param {string} userTimezone - Kullanıcının timezone offset (örn: "+03:00", "-05:00")
 * @param {string} locale - Dil kodu (tr/en) - Default: tr
 * @return {object} { allowed: boolean, current: number, limit: number, bonusAvailable: boolean }
 * @throws {HttpsError} Limit aşılmışsa
 */
async function checkDailyLimit(userId, requestType, userTimezone = "+03:00", locale = "tr") {
  // 🔓 Developer Bypass - Limitsiz erişim
  if (DEVELOPER_BYPASS_UIDS.includes(userId)) {
    return {
      allowed: true,
      current: 0,
      limit: 999999, // Sonsuz
      remaining: 999999,
      isPremium: true,
      bonusCount: 0,
      bonusAvailable: false,
    };
  }

  const db = admin.firestore();
  
  // Kullanıcının premium tier'ını kontrol et
  const tier = await getPremiumTier(userId);
  const isPremium = tier === "premium" || tier === "premium_plus";
  const isPremiumPlus = tier === "premium_plus";
  
  // Tier'a göre limit ve collection belirle
  let LIMITS, usageRef, timeKey, periodText;
  if (isPremiumPlus) {
    LIMITS = MONTHLY_LIMITS_PREMIUM_PLUS;
    timeKey = getUserLocalMonthKey(userTimezone); // YYYY-MM
    usageRef = db.collection("users").doc(userId).collection("ai_usage_monthly").doc(timeKey);
    periodText = "Aylık";
  } else if (isPremium) {
    LIMITS = MONTHLY_LIMITS_PREMIUM;
    timeKey = getUserLocalMonthKey(userTimezone); // YYYY-MM
    usageRef = db.collection("users").doc(userId).collection("ai_usage_monthly").doc(timeKey);
    periodText = "Aylık";
  } else {
    LIMITS = DAILY_LIMITS_FREE;
    timeKey = getUserLocalDateKey(userTimezone); // YYYY-MM-DD
    usageRef = db.collection("users").doc(userId).collection("ai_usage_daily").doc(timeKey);
    periodText = "Günlük";
  }
  
  const usageDoc = await usageRef.get();
  const usageData = usageDoc.exists ? usageDoc.data() : {};
  
  const currentCount = usageData[requestType] || 0;
  const bonusCount = usageData.bonusCount || 0; // Reklamla kazanılan bonus (sadece free için)
  const baseLimit = LIMITS[requestType] || LIMITS.chat; // Default: chat limiti
  
  // Toplam limit = Base limit + Bonus (bonus sadece free için)
  const totalLimit = baseLimit + (isPremium ? 0 : bonusCount);
  
  // Bonus hala kazanılabilir mi? (sadece free için)
  const maxBonus = DAILY_LIMITS_FREE.max_bonus || 0;
  const bonusAvailable = !isPremium && bonusCount < maxBonus;
  
  if (currentCount >= totalLimit) {
    // Localized message based on user's language
    const messageType = getLocalizedMessage(locale, `limits.types.${requestType}`);
    const period = getLocalizedMessage(locale, `limits.periods.${isPremium ? "monthly" : "daily"}`);
    
    let message;
    if (isPremium) {
      // Premium ve Premium Plus - Aylık limit
      const limitText = isPremiumPlus ? "3000/ay" : "1500/ay";
      message = getLocalizedMessage(locale, "limits.premiumMonthly", {
        period: period,
        limit: limitText,
      });
    } else if (bonusAvailable) {
      message = getLocalizedMessage(locale, "limits.freeWithBonus", {
        period: period,
        type: messageType,
      });
    } else {
      message = getLocalizedMessage(locale, "limits.freeWithoutBonus", {
        period: period,
        type: messageType,
      });
    }
    
    throw new HttpsError(
        "resource-exhausted",
        message,
        {
          current: currentCount,
          limit: totalLimit,
          bonusAvailable: bonusAvailable,
          bonusCount: bonusCount,
          maxBonus: maxBonus,
        },
    );
  }
  
  return {
    allowed: true,
    current: currentCount,
    limit: totalLimit,
    remaining: totalLimit - currentCount,
    isPremium: isPremium,
    bonusCount: bonusCount,
    bonusAvailable: bonusAvailable,
    maxBonus: maxBonus,
  };
}

/**
 * AI kullanımını artır (model başarıyla çalıştıktan SONRA)
 * Premium/Plus: Aylık, Free: Günlük
 * @param {string} userId - Kullanıcı ID
 * @param {string} requestType - İstek tipi
 * @param {string} userTimezone - Kullanıcının timezone offset (örn: "+03:00", "-05:00")
 * @param {string} locale - Dil kodu (tr/en) - Default: tr (not used in this function but kept for consistency)
 */
async function incrementDailyUsage(userId, requestType, userTimezone = "+03:00", locale = "tr") {
  const db = admin.firestore();
  
  // Kullanıcının premium tier'ını kontrol et
  const tier = await getPremiumTier(userId);
  const isPremium = tier === "premium" || tier === "premium_plus";
  
  let usageRef, timeKey;
  if (isPremium) {
    // Premium/Plus: Aylık collection
    timeKey = getUserLocalMonthKey(userTimezone);
    usageRef = db.collection("users").doc(userId).collection("ai_usage_monthly").doc(timeKey);
  } else {
    // Free: Günlük collection
    timeKey = getUserLocalDateKey(userTimezone);
    usageRef = db.collection("users").doc(userId).collection("ai_usage_daily").doc(timeKey);
  }
  
  await usageRef.set({
    [requestType]: admin.firestore.FieldValue.increment(1),
    lastUsed: new Date(),
    date: timeKey,
  }, {merge: true});
}

/**
 * AI kullanımını track et (AYLIK - backward compatibility)
 * @param {string} userId - Kullanıcı ID
 * @param {string} requestType - İstek tipi (chat, categorize, vs.)
 * @return {object} Kullanım bilgisi
 */
async function trackAIUsage(userId, requestType) {
  const db = admin.firestore();
  
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  
  const usageRef = db.collection("users").doc(userId).collection("ai_usage").doc(currentMonth);
  const usageDoc = await usageRef.get();
  
  const usageData = usageDoc.exists ? usageDoc.data() : {};
  const currentTotalRequests = usageData.totalRequests || 0;
  const requestsByType = usageData.requestsByType || {};
  const REQUEST_LIMIT = 100000;
  
  // Limit kontrolü
  if (currentTotalRequests >= REQUEST_LIMIT) {
    throw new HttpsError(
        "resource-exhausted",
        `Aylık AI kullanım limitinize ulaştınız (${REQUEST_LIMIT}). Lütfen gelecek ay tekrar deneyin.`,
    );
  }
  
  // Sayacı artır
  const newTypeCount = (requestsByType[requestType] || 0) + 1;
  const newTotalRequests = currentTotalRequests + 1;
  
  await usageRef.set({
    totalRequests: newTotalRequests,
    requestsByType: {
      ...requestsByType,
      [requestType]: newTypeCount,
    },
    lastUsed: now,
    month: currentMonth,
    userId: userId,
  }, {merge: true});
  
  return {
    current: newTotalRequests,
    limit: REQUEST_LIMIT,
    remaining: REQUEST_LIMIT - newTotalRequests,
    byType: {
      ...requestsByType,
      [requestType]: newTypeCount,
    },
  };
}

/**
 * Reklam izlendiğinde AI bonus hakkı ekle
 * @param {string} userId - Kullanıcı ID
 * @param {string} userTimezone - Kullanıcının timezone offset (örn: "+03:00", "-05:00")
 * @return {object} Güncel bonus bilgisi
 * @throws {HttpsError} Limit aşılmışsa veya premium ise
 */
async function addAIBonus(userId, userTimezone = "+03:00") {
  // Premium kontrolü - Premium kullanıcılar reklam izleyemez
  const isPremium = await checkIsPremium(userId);
  if (isPremium) {
    throw new HttpsError(
        "failed-precondition",
        "Premium kullanıcılar için bonus sistemi geçerli değil.",
    );
  }

  const db = admin.firestore();
  
  // Kullanıcının local timezone'una göre tarih oluştur
  const dateKey = getUserLocalDateKey(userTimezone);
  
  const dailyUsageRef = db
      .collection("users")
      .doc(userId)
      .collection("ai_usage_daily")
      .doc(dateKey);
  
  const dailyDoc = await dailyUsageRef.get();
  const dailyData = dailyDoc.exists ? dailyDoc.data() : {};
  
  const currentBonus = dailyData.bonusCount || 0;
  const maxBonus = DAILY_LIMITS_FREE.max_bonus || 15;
  const bonusPerAd = DAILY_LIMITS_FREE.bonus_per_ad || 5;
  
  // Max bonus kontrolü
  if (currentBonus >= maxBonus) {
    throw new HttpsError(
        "resource-exhausted",
        "Günlük maksimum bonus limitine ulaştınız.",
        {
          currentBonus: currentBonus,
          maxBonus: maxBonus,
        },
    );
  }
  
  // Bonus ekle
  const newBonus = Math.min(currentBonus + bonusPerAd, maxBonus); // Max'ı aşmasın
  
  await dailyUsageRef.set({
    bonusCount: newBonus,
    lastBonusAdded: new Date(),
    date: dateKey,
  }, {merge: true});
  
  return {
    success: true,
    bonusAdded: bonusPerAd,
    currentBonus: newBonus,
    maxBonus: maxBonus,
    remaining: maxBonus - newBonus,
  };
}

module.exports = {
  checkDailyLimit,
  incrementDailyUsage,
  trackAIUsage,
  checkIsPremium,
  checkIsPremiumPlus,
  getPremiumTier,
  addAIBonus,
  getUserLocalDateKey,
  getUserLocalMonthKey,
  MONTHLY_LIMITS_PREMIUM_PLUS,
  MONTHLY_LIMITS_PREMIUM,
  DAILY_LIMITS_FREE,
};

