# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keepattributes *Annotation*
-dontwarn io.flutter.embedding.**

# ML Kit Text Recognition ProGuard rules
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google_mlkit_text_recognition.**
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Plugins
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
