# Flutter için temel proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.** { *; }

# Firebase için (kullanıyorsanız)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson için (kullanıyorsanız)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Diğer yaygın kurallar
-dontwarn sun.misc.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# Uygulamanızda özel olarak keep edilmesi gereken sınıflar varsa buraya ekleyin 