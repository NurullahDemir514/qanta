# Flutter için temel proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.** { *; }

# Firebase için
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore için
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class ** {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Firebase Auth için
-keep class com.google.firebase.auth.** { *; }

# Gson için
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Model sınıfları için
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Diğer yaygın kurallar
-dontwarn sun.misc.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Crash raporları için stack trace bilgilerini koru
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile 