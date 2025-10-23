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

# Google Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications için
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# Gson TypeToken için özel kurallar
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    <init>(...);
}

# Gson generic type preservation
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepclassmembers class * {
    @com.google.gson.annotations.Expose <fields>;
}

# Diğer yaygın kurallar
-dontwarn sun.misc.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Crash raporları için stack trace bilgilerini koru
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile 