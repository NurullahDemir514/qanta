/**
 * Bulk Delete Transactions Handler
 * Toplu işlem silme işlevi
 */

const admin = require("firebase-admin");
const {HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {checkDailyLimit, incrementDailyUsage, trackAIUsage} = require("../utils/helpers");

/**
 * Bulk Delete Transactions Handler
 */
async function bulkDeleteTransactions(request) {
  try {
    const {filters} = request.data;
    const userId = request.auth?.uid;
    
    logger.info("bulkDeleteTransactions called", {userId, filters});

    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    
    if (!filters) {
      throw new HttpsError("invalid-argument", "Filters are required");
    }

    // 🚨 GÜNLÜK LİMİT KONTROLÜ
    const limitCheck = await checkDailyLimit(userId, "chat");
    logger.info(`✅ Daily limit check passed: ${limitCheck.current}/${limitCheck.limit}`);

    const db = admin.firestore();
    const transactionsRef = db.collection("users").doc(userId).collection("transactions");
    
    // Tarih filtresini hazırla
    let query = transactionsRef;
    
    if (filters.days !== undefined && filters.days !== null) {
      const now = new Date();
      const startDate = new Date(now);
      
      if (filters.days === 0) {
        // Bugün - günün başından itibaren
        startDate.setHours(0, 0, 0, 0);
      } else {
        // X gün geriye git
        startDate.setDate(startDate.getDate() - filters.days);
      }
      
      // transaction_date ISO8601 string olarak saklanıyor
      const startDateStr = startDate.toISOString();
      query = query.where("transaction_date", ">=", startDateStr);
    }
    
    // Tip filtresini hazırla
    if (filters.transactionType && filters.transactionType !== "all") {
      query = query.where("type", "==", filters.transactionType);
    }
    
    // Kategori filtresi varsa
    if (filters.category) {
      query = query.where("category", "==", filters.category);
    }
    
    // İşlemleri al
    const snapshot = await query.get();
    
    if (snapshot.empty) {
      return {
        success: true,
        deletedCount: 0,
        message: "Silinecek işlem bulunamadı",
      };
    }
    
    logger.info(`Found ${snapshot.size} transactions to delete`);
    
    // Batch işlemi - Firestore batch limiti 500
    const batches = [];
    let currentBatch = db.batch();
    let operationCounter = 0;
    let batchCounter = 0;
    
    snapshot.docs.forEach((doc) => {
      currentBatch.delete(doc.ref);
      operationCounter++;
      
      // Her 500 işlemde bir yeni batch oluştur
      if (operationCounter === 500) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        operationCounter = 0;
        batchCounter++;
      }
    });
    
    // Son batch'i ekle (eğer dolu değilse)
    if (operationCounter > 0) {
      batches.push(currentBatch);
      batchCounter++;
    }
    
    // Tüm batch'leri PARALEL commit et (çok daha hızlı!)
    await Promise.all(batches.map((batch) => batch.commit()));
    
    logger.info(`✅ Deleted ${snapshot.size} transactions in ${batchCounter} batches (parallel)`);
    
    // İşlem başarılı - kullanımı kaydet
    await incrementDailyUsage(userId, "chat");
    const usage = await trackAIUsage(userId, "bulk_delete");
    
    return {
      success: true,
      deletedCount: snapshot.size,
      message: `${snapshot.size} işlem başarıyla silindi`,
      usage: {
        ...usage,
        daily: {
          current: limitCheck.current + 1,
          limit: limitCheck.limit,
          remaining: limitCheck.remaining - 1,
        },
      },
    };
  } catch (error) {
    logger.error("bulkDeleteTransactions error:", error);
    throw new HttpsError("internal", "Bulk delete failed: " + error.message);
  }
}

module.exports = {bulkDeleteTransactions};

