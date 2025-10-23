package com.qanta

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.view.LayoutInflater
import android.widget.TextView
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

class MainActivity : FlutterActivity() {
    private class ListTileNativeAdFactory(private val inflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {
        override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
            val adView = NativeAdView(inflater.context)
            val headline = TextView(inflater.context)
            headline.text = nativeAd.headline ?: "Sponsored"
            headline.textSize = 16f
            adView.addView(headline)
            adView.headlineView = headline
            adView.setNativeAd(nativeAd)
            return adView
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "listTile", ListTileNativeAdFactory(layoutInflater))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Android 15+ (SDK 35) için Edge-to-Edge desteği
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // enableEdgeToEdge() çağrısı otomatik olarak sistem tarafından yapılıyor
            // Sadece window insets'i ayarlıyoruz
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ için eski yöntem
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
}
