# Release-APK bauen

Stand: 2026-05-04. Ziel: signiertes Release-APK fuer Android, das Du
auf Dein Geraet kopieren und installieren kannst (Sideload).

---

## 1. Einmalig: Signing-Key erstellen

Android verlangt fuer jede Release-APK eine digitale Signatur. Den
Schluessel erzeugst Du **einmal** und benutzt ihn fuer alle weiteren
Releases. Verlierst Du ihn, kannst Du Updates nicht mehr installieren
(neue Signatur = "andere App"). **Backup wichtig!**

In PowerShell:

```powershell
cd D:\claudi\2026-05-03-bonbudget\android
keytool -genkey -v `
  -keystore D:\bonbudget-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias bonbudget
```

`keytool` kommt mit dem JDK. Falls nicht im Path: aus dem Flutter-SDK
nutzen, z. B. `D:\claudi\flutter\bin\cache\dart-sdk\..\..\jbr\bin\keytool.exe`.

Du wirst zweimal nach Passwoertern gefragt (Keystore + Key) und nach
Identitaet. Schreib Dir die Passwoerter sicher auf — z. B. in den
Passwort-Manager. Den Keystore-Pfad bewusst **ausserhalb** vom
Projekt (oben: `D:\bonbudget-keystore.jks`), damit er nicht
versehentlich ins git landet.

## 2. key.properties anlegen

Datei `D:\claudi\2026-05-03-bonbudget\android\key.properties`:

```
storePassword=DEIN_KEYSTORE_PASSWORT
keyPassword=DEIN_KEY_PASSWORT
keyAlias=bonbudget
storeFile=D:/bonbudget-keystore.jks
```

Wichtig: **NICHT in git committen.** In `.gitignore` ergaenzen:

```
android/key.properties
```

## 3. android/app/build.gradle (oder .kts) anpassen

Oeffne `android/app/build.gradle` (Groovy) oder
`android/app/build.gradle.kts` (Kotlin DSL).

**Groovy-Variante:** Am Anfang des Files (vor `android { ... }`):

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Im `android { ... }`-Block:

```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Kotlin-DSL-Variante** (`build.gradle.kts`):

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

## 4. ApplicationId pruefen

Im selben `build.gradle` unter `defaultConfig`:

```
applicationId "com.example.bonbudget"
```

`com.example.*` ist das Flutter-Default. Aendere das auf was Eigenes,
z. B. `de.enno.bonbudget` — sonst kollidiert es theoretisch mit anderen
Test-Apps. Wenn Du die App spaeter im Play Store veroeffentlichen
willst, muss die ID dauerhaft eindeutig sein.

## 5. ProGuard-Rules: ML Kit & sqlcipher schuetzen

Code-Shrinking koennte die OCR/DB-Klassen wegoptimieren. In
`android/app/proguard-rules.pro` (anlegen falls nicht vorhanden):

```
# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# SQLCipher
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }
```

## 6. Versionsnummer bumpen

In `pubspec.yaml`:

```yaml
version: 0.1.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`. Bei jeder neuen APK
mindestens den Build-Counter erhoehen, sonst weigert sich Android
beim Update.

## 7. Build-Befehl

```powershell
cd D:\claudi\2026-05-03-bonbudget
flutter clean
flutter pub get
flutter build apk --release
```

Nach 1-3 Minuten:

```
D:\claudi\2026-05-03-bonbudget\build\app\outputs\flutter-apk\app-release.apk
```

Diese Datei aufs Handy kopieren (USB, Mail an sich selbst,
Nextcloud, was auch immer) und installieren. Android wird einmal
nachfragen, ob es Apps aus unbekannten Quellen erlauben darf.

## 8. Optional: kleinere APKs (split per ABI)

Eine universelle APK enthaelt Native-Code fuer ARM32, ARM64 und
x86_64 — entsprechend gross. Wenn Du nur **dein** Geraet versorgst,
reicht in der Regel arm64 (modernes Android-Phone):

```powershell
flutter build apk --release --split-per-abi
```

Erzeugt drei kleinere Dateien:

```
build\app\outputs\flutter-apk\app-arm64-v8a-release.apk    <- nimm die
build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
build\app\outputs\flutter-apk\app-x86_64-release.apk
```

## 9. Optional: Code-Obfuscation (Privacy)

Privacy-First-App -> wir wollen, dass Reverse-Engineers es schwer
haben:

```powershell
flutter build apk --release `
  --obfuscate `
  --split-debug-info=build\debug-symbols
```

`build\debug-symbols\` aufheben, falls Du Stack-Traces aus Crash-
Reports lesen willst (sonst sind die unleserlich).

## 10. Troubleshooting

- **"keystore was tampered with"**: falsches Passwort. Pruefen.
- **"INSTALL_FAILED_VERSION_DOWNGRADE"**: Du hast eine hoehere Version
  schon installiert. Erst alte deinstallieren.
- **App startet nicht / Crash**: ProGuard hat zu viel weggeworfen.
  In `proguard-rules.pro` mehr `-keep`-Regeln eintragen, oder
  `minifyEnabled false` setzen, neu bauen.
- **Argon2 / Login schlaegt fehl im Release**: Pointycastle-Klassen
  obfuscated. Eintragen:
  ```
  -keep class org.bouncycastle.** { *; }
  -keep class pointycastle.** { *; }
  ```

## 11. Naechster Build

Schritte 1-5 sind einmalig. Danach genuegen:

```powershell
# Versionsnummer in pubspec.yaml hochziehen
flutter build apk --release --split-per-abi
```

APK aufs Handy.
