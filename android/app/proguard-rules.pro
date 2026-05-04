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
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.**

# --- SQLCipher --------------------------------------------------------
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# --- Flutter Secure Storage -------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- Local Auth (Biometrie / Geraete-PIN) ----------------------------
# Plattform-Channels via io.flutter.plugins schon gekept; die
# explizite Regel hier ist defensiv fuer kuenftige Plugin-Updates.
-keep class io.flutter.plugins.localauth.** { *; }

# --- Image Picker (Kamera / Galerie) ---------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }

# --- Prevent stripping of annotations used by Kotlin / Gson ----------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# --- General Android / Kotlin -----------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.**
