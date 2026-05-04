# ============================================================
# ProGuard / R8 rules for BonReader (de.enno.bonreader)
# ============================================================

# --- Flutter engine ---------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Google ML Kit (OCR) ---------------------------------------------
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# --- SQLCipher --------------------------------------------------------
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# --- Flutter Secure Storage -------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- Prevent stripping of annotations used by Kotlin / Gson ----------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# --- General Android / Kotlin -----------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.**
