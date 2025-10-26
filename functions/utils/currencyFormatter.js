/**
 * Currency Formatter Utility
 * Flutter CurrencyUtils'e benzer şekilde para birimlerini formatlar
 */

const CURRENCIES = {
  TRY: { code: "TRY", symbol: "₺", locale: "tr-TR" },
  USD: { code: "USD", symbol: "$", locale: "en-US" },
  EUR: { code: "EUR", symbol: "€", locale: "de-DE" },
  GBP: { code: "GBP", symbol: "£", locale: "en-GB" },
};

/**
 * Para miktarını formatla
 * @param {number} amount - Miktar
 * @param {string} currencyCode - Para birimi kodu (TRY, USD, EUR, GBP)
 * @return {string} Formatlanmış miktar
 */
function formatCurrency(amount, currencyCode = "TRY") {
  if (!amount && amount !== 0) return "0";
  
  const currency = CURRENCIES[currencyCode] || CURRENCIES.TRY;
  
  try {
    const formatter = new Intl.NumberFormat(currency.locale, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    
    const formatted = formatter.format(Math.abs(amount));
    return `${formatted}${currency.symbol}`;
  } catch (error) {
    console.error("Currency formatting error:", error);
    return `${amount}${currency.symbol}`;
  }
}

/**
 * Para birimi sembolünü al
 * @param {string} currencyCode - Para birimi kodu
 * @return {string} Sembol
 */
function getCurrencySymbol(currencyCode = "TRY") {
  const currency = CURRENCIES[currencyCode] || CURRENCIES.TRY;
  return currency.symbol;
}

/**
 * Para birimi locale'ini al
 * @param {string} currencyCode - Para birimi kodu
 * @return {string} Locale
 */
function getCurrencyLocale(currencyCode = "TRY") {
  const currency = CURRENCIES[currencyCode] || CURRENCIES.TRY;
  return currency.locale;
}

/**
 * Desteklenen para birimlerini kontrol et
 * @param {string} currencyCode - Para birimi kodu
 * @return {boolean} Destekleniyor mu?
 */
function isSupportedCurrency(currencyCode) {
  return currencyCode in CURRENCIES;
}

module.exports = {
  formatCurrency,
  getCurrencySymbol,
  getCurrencyLocale,
  isSupportedCurrency,
  CURRENCIES,
};

