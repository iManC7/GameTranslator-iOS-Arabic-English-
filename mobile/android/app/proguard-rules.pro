# libgtnative.so (gt_jni.c) bu sınıfı ve geri çağrı yöntemlerini adlarıyla bulur; küçültme adlarını değiştirmemeli.
-keep class com.gametranslator.gametranslator_mobile.Native { *; }
-keep interface com.gametranslator.gametranslator_mobile.Native$* { *; }
-keepclassmembers class * implements com.gametranslator.gametranslator_mobile.Native$ConsoleCallback { public *; }
-keepclassmembers class * implements com.gametranslator.gametranslator_mobile.Native$LogCallback { public *; }
-keepclassmembers class * implements com.gametranslator.gametranslator_mobile.Native$SessionListener { public *; }

# ML Kit bileşenlerini yansımayla (ComponentRegistrar, parametresiz kurucu) bulur; küçültme kurucuları siliyordu
# ("NoSuchMethodException: ...VisionCommonRegistrar.<init>") ve yayın derlemesinde yazı tanıma hiç başlamıyordu.
-keep class com.google.mlkit.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_translate.** { *; }
-keep class com.google.android.gms.internal.mlkit_language_id_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }

# JSch (LG TV kurulumu) algoritma sınıflarını adlarıyla yansımayla yükler; isteğe bağlı bağımlılıkları yoktur.
-keep class com.jcraft.jsch.** { *; }
-dontwarn com.jcraft.jsch.**
-dontwarn org.ietf.jgss.**
-dontwarn org.bouncycastle.**
-dontwarn org.newsclub.**
-dontwarn com.sun.jna.**
-dontwarn org.apache.logging.**
-dontwarn org.slf4j.**
