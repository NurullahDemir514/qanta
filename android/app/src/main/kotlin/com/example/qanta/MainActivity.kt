package com.qanta

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.PurchasesUpdatedListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.qanta/country_detection"
    private var billingClient: BillingClient? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Billing Client for Play Store country detection
        initializeBillingClient()
        
        // Method Channel for country detection
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlayStoreCountry" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val countryCode = getPlayStoreCountry()
                            result.success(countryCode)
                        } catch (e: Exception) {
                            result.error("COUNTRY_ERROR", "Failed to get Play Store country: ${e.message}", null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Initialize Google Play Billing Client
     * Required for getting Play Store country code
     */
    private fun initializeBillingClient() {
        billingClient = BillingClient.newBuilder(this)
            .enablePendingPurchases()
            .setListener { billingResult, purchases -> }
            .build()
    }
    
    /**
     * Get Play Store country code using Google Play Billing Library
     * This is the most accurate method to detect the country where the app was downloaded from
     * Uses a dummy product query to get the currency code, which indicates the Play Store country
     */
    private suspend fun getPlayStoreCountry(): String? = suspendCancellableCoroutine { continuation ->
        val client = billingClient ?: run {
            continuation.resume(null)
            return@suspendCancellableCoroutine
        }
        
        // Connect to Billing Client
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    // Query a real product from the app to get currency code (indicates Play Store country)
                    // Using a real subscription product ID from the app
                    val productId = "qanta_premium_monthly" // Real product ID from the app
                    val productList = listOf(
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId(productId)
                            .setProductType(BillingClient.ProductType.SUBS)
                            .build()
                    )
                    
                    val params = QueryProductDetailsParams.newBuilder()
                        .setProductList(productList)
                        .build()
                    
                    client.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
                        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && productDetailsList.isNotEmpty()) {
                            // Get currency code from subscription product details
                            val productDetails = productDetailsList.first()
                            val subscriptionOfferDetails = productDetails.subscriptionOfferDetails
                            
                            if (subscriptionOfferDetails != null && subscriptionOfferDetails.isNotEmpty()) {
                                val offerDetails = subscriptionOfferDetails.first()
                                val pricingPhases = offerDetails.pricingPhases
                                
                                if (pricingPhases != null && pricingPhases.pricingPhaseList.isNotEmpty()) {
                                    val pricingPhase = pricingPhases.pricingPhaseList.first()
                                    val currencyCode = pricingPhase.priceCurrencyCode
                                    
                                    if (!currencyCode.isNullOrEmpty()) {
                                        // Convert currency code to country code
                                        val countryCode = currencyToCountryCode(currencyCode)
                                        client.endConnection()
                                        continuation.resume(countryCode)
                                        return@queryProductDetailsAsync
                                    }
                                }
                            }
                        }
                        
                        // If subscription product doesn't work, try with in-app product
                        val inAppProductId = "qanta_premium_monthly" // Try same ID as in-app
                        val inAppProductList = listOf(
                            QueryProductDetailsParams.Product.newBuilder()
                                .setProductId(inAppProductId)
                                .setProductType(BillingClient.ProductType.INAPP)
                                .build()
                        )
                        
                        val inAppParams = QueryProductDetailsParams.newBuilder()
                            .setProductList(inAppProductList)
                            .build()
                        
                        client.queryProductDetailsAsync(inAppParams) { inAppBillingResult, inAppProductDetailsList ->
                            if (inAppBillingResult.responseCode == BillingClient.BillingResponseCode.OK && inAppProductDetailsList.isNotEmpty()) {
                                val productDetails = inAppProductDetailsList.first()
                                val currencyCode = productDetails.oneTimePurchaseOfferDetails?.priceCurrencyCode
                                
                                if (!currencyCode.isNullOrEmpty()) {
                                    val countryCode = currencyToCountryCode(currencyCode)
                                    client.endConnection()
                                    continuation.resume(countryCode)
                                } else {
                                    client.endConnection()
                                    continuation.resume(null)
                                }
                            } else {
                                client.endConnection()
                                continuation.resume(null)
                            }
                        }
                    }
                } else {
                    client.endConnection()
                    continuation.resume(null)
                }
            }
            
            override fun onBillingServiceDisconnected() {
                continuation.resume(null)
            }
        })
    }
    
    /**
     * Convert currency code to country code
     * Maps common currency codes to their primary country codes
     */
    private fun currencyToCountryCode(currencyCode: String): String? {
        val currencyToCountry = mapOf(
            "TRY" to "TR",  // Turkish Lira -> Turkey
            "USD" to "US",  // US Dollar -> United States
            "EUR" to "DE",  // Euro -> Germany (primary, but used in many EU countries)
            "GBP" to "GB",  // British Pound -> United Kingdom
            "JPY" to "JP",  // Japanese Yen -> Japan
            "CNY" to "CN",  // Chinese Yuan -> China
            "INR" to "IN",  // Indian Rupee -> India
            "BRL" to "BR",  // Brazilian Real -> Brazil
            "RUB" to "RU",  // Russian Ruble -> Russia
            "KRW" to "KR",  // South Korean Won -> South Korea
            "MXN" to "MX",  // Mexican Peso -> Mexico
            "AUD" to "AU",  // Australian Dollar -> Australia
            "CAD" to "CA",  // Canadian Dollar -> Canada
            "CHF" to "CH",  // Swiss Franc -> Switzerland
            "SEK" to "SE",  // Swedish Krona -> Sweden
            "NOK" to "NO",  // Norwegian Krone -> Norway
            "DKK" to "DK",  // Danish Krone -> Denmark
            "PLN" to "PL",  // Polish Zloty -> Poland
            "CZK" to "CZ",  // Czech Koruna -> Czech Republic
            "HUF" to "HU",  // Hungarian Forint -> Hungary
            "RON" to "RO",  // Romanian Leu -> Romania
            "BGN" to "BG",  // Bulgarian Lev -> Bulgaria
            "HRK" to "HR",  // Croatian Kuna -> Croatia
            "SGD" to "SG",  // Singapore Dollar -> Singapore
            "HKD" to "HK",  // Hong Kong Dollar -> Hong Kong
            "TWD" to "TW",  // Taiwan Dollar -> Taiwan
            "THB" to "TH",  // Thai Baht -> Thailand
            "IDR" to "ID",  // Indonesian Rupiah -> Indonesia
            "MYR" to "MY",  // Malaysian Ringgit -> Malaysia
            "PHP" to "PH",  // Philippine Peso -> Philippines
            "VND" to "VN",  // Vietnamese Dong -> Vietnam
            "ZAR" to "ZA",  // South African Rand -> South Africa
            "EGP" to "EG",  // Egyptian Pound -> Egypt
            "ILS" to "IL",  // Israeli Shekel -> Israel
            "AED" to "AE",  // UAE Dirham -> United Arab Emirates
            "SAR" to "SA",  // Saudi Riyal -> Saudi Arabia
        )
        
        return currencyToCountry[currencyCode.uppercase()]
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Android 15+ (SDK 35) için Edge-to-Edge desteği
        // enableEdgeToEdge() Flutter tarafından otomatik çağrılıyor
        if (Build.VERSION.SDK_INT >= 35) { // Android 15 (VANILLA_ICE_CREAM)
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ için edge-to-edge
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
}
