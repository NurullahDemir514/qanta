/**
 * Qanta AI Functions
 *
 * Firebase Cloud Functions for AI-powered features
 * Organized following SOLID principles
 */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {GoogleGenerativeAI} = require("@google/generative-ai");
const admin = require("firebase-admin");

// Import handlers
const {chatWithAI} = require("./handlers/chatWithAI");
const {bulkDeleteTransactions} = require("./handlers/bulkDeleteTransactions");
const {trackAIUsage, checkDailyLimit, incrementDailyUsage, addAIBonus} = require("./utils/helpers");

// Firebase Admin başlat
admin.initializeApp();

// API key - Google AI Studio'dan alındı
const GEMINI_API_KEY = "AIzaSyB6fyIYr-G1I5t4HF6aPjXSrkGMAc4P9io";

// Gemini AI instance
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

// ========================================
// EXPORTED CLOUD FUNCTIONS
// ========================================

/**
 * Conversational AI Assistant - Quick Add için sohbet arayüzü
 * Handler: handlers/chatWithAI.js
 */
exports.chatWithAI = onCall({region: "us-central1"}, chatWithAI);

/**
 * Bulk Delete Transactions - Filtrelere göre toplu işlem silme
 * Handler: handlers/bulkDeleteTransactions.js
 */
exports.bulkDeleteTransactions = onCall({region: "us-central1"}, bulkDeleteTransactions);

/**
 * Add AI Bonus - Reklam izlenince bonus hakkı ekle
 * Free kullanıcılar için günlük AI limitini artırır
 */
exports.addAIBonus = onCall({region: "us-central1"}, async (request) => {
  // Auth kontrolü
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
  }

  const userId = request.auth.uid;
  const {userTimezone} = request.data || {};

  try {
    // Kullanıcı timezone'u (varsayılan: +03:00)
    const timezone = userTimezone || "+03:00";
    
    logger.info(`📺 Adding AI bonus for user: ${userId}`);
    
    const result = await addAIBonus(userId, timezone);
    
    logger.info(`✅ AI bonus added: +${result.bonusAdded} (Total: ${result.currentBonus}/${result.maxBonus})`);
    
    return result;
  } catch (error) {
    logger.error(`❌ Add AI bonus error: ${error.message}`);
    throw error;
  }
});

/**
 * Harcama kategorizasyonu için AI function
 * 
 * @param {Object} data - Request data
 * @param {string} data.description - Harcama açıklaması
 * @param {string[]} data.availableCategories - Mevcut kategoriler
 * @return {Object} Kategori tahmini sonucu
 */
exports.categorizeExpense = onCall(async (request) => {
  // Auth kontrolü
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
  }

  const userId = request.auth.uid;
  const {description, availableCategories, userTimezone} = request.data;

  // Validation
  if (!description || typeof description !== "string") {
    throw new HttpsError("invalid-argument", "Geçerli bir açıklama gerekli");
  }

  try {
    // Kullanıcı timezone'u (varsayılan: +03:00)
    const timezone = userTimezone || "+03:00";
    
    // 🚨 GÜNLÜK LİMİT KONTROLÜ
    await checkDailyLimit(userId, "chat", timezone);
    
    console.log(`🤖 AI Categorizing: "${description}"`);

    // Gemini AI model (Lite version - hızlı ve ucuz)
    const model = genAI.getGenerativeModel({model: "gemini-2.5-flash-lite"});

    // Kategorileri hazırla
    const categoriesText = availableCategories && availableCategories.length > 0 ?
      availableCategories.join(", ") :
      "Yiyecek & İçecek, Ulaşım, Eğlence, Sağlık, Alışveriş, Faturalar, Eğitim, Diğer";

    // Prompt oluştur
    const prompt = `
Aşağıdaki harcama açıklamasını analiz et ve en uygun kategoriyi seç.

Harcama: "${description}"

Mevcut Kategoriler:
${categoriesText}

Sadece şu formatta yanıt ver (başka açıklama ekleme):
KATEGORİ: [kategori adı]
GÜVENİLİRLİK: [0-100 arası sayı]
NEDEN: [kısa açıklama]

Örnek:
KATEGORİ: Yiyecek & İçecek
GÜVENİLİRLİK: 95
NEDEN: Starbucks bir kafe zinciridir
`;

    // AI'dan yanıt al
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    console.log(`✅ AI Response: ${text.substring(0, 100)}...`);

    // Parse response
    const parsed = parseCategorizationResponse(text);

    // İşlem başarılı - kullanımı kaydet
    await incrementDailyUsage(userId, "chat", timezone);

    return {
      success: true,
      categoryId: getCategoryId(parsed.categoryName),
      categoryName: parsed.categoryName,
      categoryIcon: getCategoryIcon(parsed.categoryName),
      confidence: parsed.confidence,
      reasoning: parsed.reasoning,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error("❌ AI Error:", error);

    // Fallback - Basit kategorizasyon
    const fallback = fallbackCategorization(description);

    return {
      success: true,
      ...fallback,
      isFallback: true,
      error: error.message,
    };
  }
});

/**
 * Quick Add Text Parsing - AI ile otomatik işlem tespiti
 */
exports.parseQuickAddText = onCall({region: "us-central1"}, async (request) => {
  try {
    const {text, userTimezone} = request.data;
    const userId = request.auth?.uid;
    
    logger.info("parseQuickAddText called", {text, userId});

    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    if (!text || typeof text !== "string") {
      throw new HttpsError(
          "invalid-argument",
          "Text is required",
      );
    }

    // Kullanıcı timezone'u (varsayılan: +03:00)
    const timezone = userTimezone || "+03:00";

    // 🚨 GÜNLÜK LİMİT KONTROLÜ
    await checkDailyLimit(userId, "chat", timezone);

    // Gemini AI ile parse et (Lite version - hızlı ve ucuz)
    const model = genAI.getGenerativeModel({model: "gemini-2.5-flash-lite"});
    
    const prompt = `Sen bir finansal asistan yapay zekasısın. Kullanıcının girdiği metni analiz edip şu bilgileri çıkar:

METIN: "${text}"

Lütfen şu formatta yanıt ver (her satır ayrı):

MIKTAR: [sayı] (örn: 50, 100.50)
AÇIKLAMA: [kısa açıklama] (örn: kahve, market alışverişi)
KATEGORİ: [tek kelime kategori adı] (örn: Kahve, Market, Ulaşım, Yemek)
HESAP: [hesap adı veya BULUNMADI] (örn: Ziraat, Garanti, BULUNMADI)
TARİH: [bugün/dün/tarih veya BULUNMADI] (örn: bugün, dün, 15 ekim, BULUNMADI)
TİP: [gelir veya gider]
HİSSE: [evet veya hayır]

Eğer hisse işlemiyse (HİSSE: evet), ayrıca şunları ekle:
HİSSE_SEMBOL: [hisse sembolü] (örn: THYAO, AKBNK, ASELS)
HİSSE_MİKTAR: [adet]
HİSSE_FİYAT: [birim fiyat veya BULUNMADI]
HİSSE_İŞLEM: [alım veya satış]

ÖRNEKLER:

"50 tl kahve ziraat"
MIKTAR: 50
AÇIKLAMA: kahve
KATEGORİ: Kahve
HESAP: Ziraat
TARİH: BULUNMADI
TİP: gider
HİSSE: hayır

"5000 tl maaş yattı"
MIKTAR: 5000
AÇIKLAMA: maaş
KATEGORİ: Maaş
HESAP: BULUNMADI
TARİH: BULUNMADI
TİP: gelir
HİSSE: hayır

"15 aselsan 205 tlden sattım garanti"
MIKTAR: 0
AÇIKLAMA: hisse satışı
KATEGORİ: Hisse
HESAP: Garanti
TARİH: BULUNMADI
TİP: gider
HİSSE: evet
HİSSE_SEMBOL: ASELS
HİSSE_MİKTAR: 15
HİSSE_FİYAT: 205
HİSSE_İŞLEM: satış

Şimdi yukarıdaki metni analiz et ve yanıtla:`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiText = response.text();
    
    logger.info("AI Response:", {aiText});

    // Parse AI response
    const parsed = parseQuickAddResponse(aiText);
    
    // İşlem başarılı - kullanımı kaydet
    await incrementDailyUsage(userId, "chat", timezone);
    
    return {
      success: true,
      ...parsed,
    };

  } catch (error) {
    logger.error("parseQuickAddText error:", error);
    
    // Fallback yok - hata fırlat
    throw new HttpsError(
        "internal",
        "AI parsing failed: " + error.message,
    );
  }
});

/**
 * AI Financial Summary - Kullanıcının finansal durumunu analiz eder
 * Kullanım: Total kart, dashboard özet, vs.
 */
exports.getAIFinancialSummary = onCall({region: "us-central1"}, async (request) => {
  try {
    const {financialData, period, userTimezone} = request.data;
    const userId = request.auth?.uid;
    
    logger.info("getAIFinancialSummary called", {userId, period});

    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    
    if (!financialData) {
      throw new HttpsError("invalid-argument", "Financial data is required");
    }

    // Kullanıcı timezone'u (varsayılan: +03:00)
    const timezone = userTimezone || "+03:00";

    // 🚨 GÜNLÜK LİMİT KONTROLÜ
    await checkDailyLimit(userId, "chat", timezone);

    // Gemini AI model (Lite version - hızlı ve ucuz)
    const model = genAI.getGenerativeModel({model: "gemini-2.5-flash-lite"});

    const prompt = `Sen bir finansal danışmansın. Kullanıcının ${period || 'bu ayki'} finansal verilerini analiz et ve kısa, öz bir özet ver.

FİNANSAL VERİLER:
- Gelir: ${financialData.income || 0}₺
- Gider: ${financialData.expense || 0}₺
- Net Bakiye: ${financialData.balance || 0}₺
- En Çok Harcanan Kategoriler: ${financialData.topCategories ? financialData.topCategories.map((c) => `${c.category} (${c.amount}₺)`).join(", ") : "Yok"}

GÖREV:
1. Finansal durumu değerlendir (iyi/kötü/orta)
2. 2-3 cümle ile özet ver
3. 1-2 tavsiye ver
4. Emoji kullan ama abartma

YANIT FORMATI:
Kısa, öz ve dostane. Max 4-5 cümle.`;

    const result = await model.generateContent(prompt);
    const aiSummary = result.response.text();
    
    logger.info("✅ AI Summary generated");

    // İşlem başarılı - kullanımı kaydet
    await incrementDailyUsage(userId, "chat", timezone);
    const usage = await trackAIUsage(userId, "summary");

    return {
      success: true,
      summary: aiSummary,
      usage: usage,
    };
  } catch (error) {
    logger.error("getAIFinancialSummary error:", error);
    
    if (error.code === "resource-exhausted") {
      throw error;
    }
    
    throw new HttpsError("internal", "AI summary failed: " + error.message);
  }
});

/**
 * Test function - Mevcut Gemini modellerini listele
 */
exports.listGeminiModels = onCall({region: "us-central1"}, async (request) => {
  try {
    logger.info("Listing available Gemini models...");

    // API'den model listesini al
    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`,
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    logger.info("Available models:", data);

    return {
      success: true,
      models: data.models || [],
      count: data.models?.length || 0,
    };
  } catch (error) {
    logger.error("Error listing models:", error);
    throw new HttpsError("internal", "Failed to list models: " + error.message);
  }
});

// ========================================
// HELPER FUNCTIONS
// ========================================

/**
 * AI yanıtını parse et
 */
function parseCategorizationResponse(text) {
  const lines = text.trim().split("\n");
  let categoryName = "Diğer";
  let confidence = 0.5;
  let reasoning = "";

  for (const line of lines) {
    const upperLine = line.toUpperCase();
    if (upperLine.startsWith("KATEGORİ:")) {
      categoryName = line.substring(line.indexOf(":") + 1).trim();
    } else if (upperLine.startsWith("GÜVENİLİRLİK:")) {
      const confidenceStr = line.substring(line.indexOf(":") + 1).trim();
      confidence = (parseFloat(confidenceStr) || 50) / 100;
    } else if (upperLine.startsWith("NEDEN:")) {
      reasoning = line.substring(line.indexOf(":") + 1).trim();
    }
  }

  return {categoryName, confidence, reasoning};
}

/**
 * Kategori adından ID oluştur
 */
function getCategoryId(categoryName) {
  const map = {
    "Yiyecek & İçecek": "food_drink",
    "Ulaşım": "transportation",
    "Eğlence": "entertainment",
    "Sağlık": "health",
    "Alışveriş": "shopping",
    "Faturalar": "bills",
    "Eğitim": "education",
    "Diğer": "other",
  };
  return map[categoryName] || "other";
}

/**
 * Kategori için ikon seç
 */
function getCategoryIcon(categoryName) {
  const map = {
    "Yiyecek & İçecek": "🍔",
    "Ulaşım": "🚗",
    "Eğlence": "🎭",
    "Sağlık": "💊",
    "Alışveriş": "🛒",
    "Faturalar": "📱",
    "Eğitim": "📚",
    "Diğer": "💰",
  };
  return map[categoryName] || "💰";
}

/**
 * Quick Add AI yanıtını parse et
 */
function parseQuickAddResponse(text) {
  const lines = text.trim().split("\n");
  const result = {
    amount: 0,
    description: "",
    categoryName: "Diğer",
    accountName: null,
    transactionDate: null,
    transactionType: "expense",
    isStock: false,
  };

  for (const line of lines) {
    const upperLine = line.toUpperCase();
    
    if (upperLine.startsWith("MIKTAR:")) {
      const amountStr = line.substring(line.indexOf(":") + 1).trim();
      result.amount = parseFloat(amountStr.replace(",", ".")) || 0;
    } else if (upperLine.startsWith("AÇIKLAMA:")) {
      result.description = line.substring(line.indexOf(":") + 1).trim();
    } else if (upperLine.startsWith("KATEGORİ:")) {
      result.categoryName = line.substring(line.indexOf(":") + 1).trim();
    } else if (upperLine.startsWith("HESAP:")) {
      const account = line.substring(line.indexOf(":") + 1).trim();
      result.accountName = account === "BULUNMADI" ? null : account;
    } else if (upperLine.startsWith("TARİH:")) {
      const dateStr = line.substring(line.indexOf(":") + 1).trim();
      if (dateStr !== "BULUNMADI") {
        result.transactionDate = parseDateString(dateStr);
      }
    } else if (upperLine.startsWith("TİP:")) {
      const type = line.substring(line.indexOf(":") + 1).trim().toLowerCase();
      result.transactionType = type === "gelir" ? "income" : "expense";
    } else if (upperLine.startsWith("HİSSE:")) {
      const isStock = line.substring(line.indexOf(":") + 1).trim().toLowerCase();
      result.isStock = isStock === "evet" || isStock === "yes";
    } else if (upperLine.startsWith("HİSSE_SEMBOL:")) {
      result.stockSymbol = line.substring(line.indexOf(":") + 1).trim();
    } else if (upperLine.startsWith("HİSSE_MİKTAR:")) {
      const qty = line.substring(line.indexOf(":") + 1).trim();
      result.quantity = parseFloat(qty) || 0;
    } else if (upperLine.startsWith("HİSSE_FİYAT:")) {
      const priceStr = line.substring(line.indexOf(":") + 1).trim();
      if (priceStr !== "BULUNMADI") {
        result.price = parseFloat(priceStr.replace(",", ".")) || null;
      }
    } else if (upperLine.startsWith("HİSSE_İŞLEM:")) {
      const action = line.substring(line.indexOf(":") + 1).trim().toLowerCase();
      result.isBuy = action.includes("alım") || action.includes("buy");
      result.isSell = action.includes("satış") || action.includes("sat") || action.includes("sell");
    }
  }

  return result;
}

/**
 * Tarih string'ini parse et
 */
function parseDateString(dateStr) {
  const lower = dateStr.toLowerCase().trim();
  const now = new Date();

  if (lower === "bugün" || lower === "today") {
    return now.toISOString();
  } else if (lower === "dün" || lower === "yesterday") {
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString();
  } else if (lower === "evvelsi gün" || lower === "evvelsi") {
    const dayBefore = new Date(now);
    dayBefore.setDate(dayBefore.getDate() - 2);
    return dayBefore.toISOString();
  }
  
  // "15 ekim" formatı
  const monthMap = {
    "ocak": 0, "şubat": 1, "mart": 2, "nisan": 3,
    "mayıs": 4, "haziran": 5, "temmuz": 6, "ağustos": 7,
    "eylül": 8, "ekim": 9, "kasım": 10, "aralık": 11,
  };
  
  const match = dateStr.match(/(\d{1,2})\s*(\w+)/);
  if (match) {
    const day = parseInt(match[1]);
    const month = monthMap[match[2].toLowerCase()];
    if (month !== undefined) {
      const date = new Date(now.getFullYear(), month, day);
      return date.toISOString();
    }
  }

  return now.toISOString();
}

/**
 * Fallback kategorizasyon (AI hata verirse)
 */
function fallbackCategorization(description) {
  const lowerDesc = description.toLowerCase();

  // Yiyecek & İçecek
  if (lowerDesc.includes("market") ||
      lowerDesc.includes("migros") ||
      lowerDesc.includes("şok") ||
      lowerDesc.includes("bim") ||
      lowerDesc.includes("a101")) {
    return {
      categoryId: "food_drink",
      categoryName: "Yiyecek & İçecek",
      categoryIcon: "🛒",
      confidence: 0.7,
      reasoning: "Market alışverişi tespit edildi",
    };
  }

  if (lowerDesc.includes("starbucks") ||
      lowerDesc.includes("cafe") ||
      lowerDesc.includes("kahve") ||
      lowerDesc.includes("restaurant")) {
    return {
      categoryId: "food_drink",
      categoryName: "Yiyecek & İçecek",
      categoryIcon: "☕",
      confidence: 0.8,
      reasoning: "Yeme-içme yeri tespit edildi",
    };
  }

  // Ulaşım
  if (lowerDesc.includes("benzin") ||
      lowerDesc.includes("shell") ||
      lowerDesc.includes("opet") ||
      lowerDesc.includes("uber") ||
      lowerDesc.includes("taksi")) {
    return {
      categoryId: "transportation",
      categoryName: "Ulaşım",
      categoryIcon: "⛽",
      confidence: 0.8,
      reasoning: "Ulaşım gideri tespit edildi",
    };
  }

  // Eğlence
  if (lowerDesc.includes("netflix") ||
      lowerDesc.includes("spotify") ||
      lowerDesc.includes("youtube") ||
      lowerDesc.includes("sinema")) {
    return {
      categoryId: "entertainment",
      categoryName: "Eğlence",
      categoryIcon: "🎬",
      confidence: 0.9,
      reasoning: "Eğlence hizmeti tespit edildi",
    };
  }

  // Varsayılan
  return {
    categoryId: "other",
    categoryName: "Diğer",
    categoryIcon: "💰",
    confidence: 0.3,
    reasoning: "Belirli bir kategori tespit edilemedi",
  };
}
