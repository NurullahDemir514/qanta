/**
 * Localization Utility
 * Çoklu dil desteği için yardımcı fonksiyonlar
 */

const fs = require("fs");
const path = require("path");

// Dil dosyalarını yükle
const translations = {
  tr: require("../locales/tr.json"),
  en: require("../locales/en.json"),
};

/**
 * Metni çevir ve placeholder'ları değiştir
 * @param {string} key - Çeviri anahtarı (örn: "greeting", "financialSummary.title")
 * @param {string} language - Dil kodu (tr, en)
 * @param {object} params - Placeholder değerleri (örn: {name: "Ali", amount: "100₺"})
 * @return {string} Çevrilmiş metin
 */
function t(key, language = "tr", params = {}) {
  const lang = translations[language] || translations.tr;
  
  // Nested key desteği (örn: "financialSummary.title")
  const keys = key.split(".");
  let translation = lang;
  
  for (const k of keys) {
    if (translation && typeof translation === "object") {
      translation = translation[k];
    } else {
      translation = undefined;
      break;
    }
  }
  
  // Çeviri bulunamadıysa key'i döndür
  if (!translation) {
    console.warn(`Translation not found: ${key} (${language})`);
    return key;
  }
  
  // Placeholder'ları değiştir
  let result = translation;
  Object.keys(params).forEach((param) => {
    const regex = new RegExp(`\\{${param}\\}`, "g");
    result = result.replace(regex, params[param]);
  });
  
  return result;
}

/**
 * Ay adını al
 * @param {number} month - Ay numarası (1-12)
 * @param {string} language - Dil kodu
 * @return {string} Ay adı
 */
function getMonthName(month, language = "tr") {
  return t(`months.${month}`, language);
}

/**
 * Desteklenen dilleri kontrol et
 * @param {string} language - Dil kodu
 * @return {boolean} Destekleniyor mu?
 */
function isSupportedLanguage(language) {
  return language in translations;
}

/**
 * Dil kodu normalize et (varsayılan: tr)
 * @param {string} language - Dil kodu
 * @return {string} Normalize edilmiş dil kodu
 */
function normalizeLanguage(language) {
  if (!language) return "tr";
  const lang = language.toLowerCase().substring(0, 2);
  return isSupportedLanguage(lang) ? lang : "tr";
}

module.exports = {
  t,
  getMonthName,
  isSupportedLanguage,
  normalizeLanguage,
};

