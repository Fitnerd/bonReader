# Deployment-Anleitung

Wie BonBudget auf dein Handy kommt - vom ersten USB-Test bis zum Play-Store-Release.

> Stand: 2026-05-04. Alle Befehle setzen voraus, dass das Setup aus
> [`README.md`](../README.md) komplett ist (Flutter, Android Studio,
> `flutter doctor` clean).

---

## Inhalt

1. [Auf das eigene Handy per USB (Debug-Build)](#1-auf-das-eigene-handy-per-usb-debug-build)
2. [Signed Release-APK bauen und sideloaden](#2-signed-release-apk-bauen-und-sideloaden)
3. [Vor dem Play-Store: Pflichtarbeiten am Projekt](#3-vor-dem-play-store-pflichtarbeiten-am-projekt)
4. [App Bundle (AAB) fuer den Play Store bauen](#4-app-bundle-aab-fuer-den-play-store-bauen)
5. [Google Play Console: erstmaliges Release](#5-google-play-console-erstmaliges-release)
6. [Updates ausrollen](#6-updates-ausrollen)
7. [iOS in Kuerze](#7-ios-in-kuerze)
8. [Alternativen: Direkt-APK & F-Droid](#8-alternativen-direkt-apk--f-droid)
9. [Checkliste vor jedem Release](#9-checkliste-vor-jedem-release)

---

## 1. Auf das eigene Handy per USB (Debug-Build)

Schnellster Weg: USB-Kabel + `flutter run`.

### 1.1 USB-Debugging am Handy aktivieren (Einmalig)

1. **Einstellungen** -> **Ueber das Telefon**.
2. 7x auf **Build-Nummer** tippen, bis "Du bist jetzt Entwickler" erscheint.
3. Zurueck -> **System** -> **Entwickleroptionen**.
4. **USB-Debugging** einschalten.
5. (Empfohlen) **Beim USB-Debugging immer zulassen** aktivieren, sonst
   musst du jedes Mal beim Anstecken bestaetigen.

### 1.2 Handy am Rechner anstecken

1. USB-Kabel anstecken (idealerweise das Original-Datenkabel; manche
   Ladekabel uebertragen keine Daten).
2. Auf dem Handy erscheint ein Dialog "USB-Debugging zulassen?" -> **Ja**.
3. Im Terminal pruefen:
   ```bash
   flutter devices
   ```
   Dein Geraet muss in der Liste auftauchen, z. B.:
   ```
   Pixel 7 (mobile) - 13B23001VV - android-arm64
   ```

### 1.3 App starten

```bash
cd D:\claudi\2026-05-03-bonbudget
flutter run
```

Wenn mehrere Geraete verbunden sind:

```bash
flutter run -d 13B23001VV
```

Beim ersten Start dauert es 1-3 Min (Gradle-Cache, ML Kit Native-Code).
Folgestarts <30 s. Hot Reload funktioniert wie im Emulator.

> **Hinweis:** Debug-Builds sind langsamer und groesser als Release-Builds.
> Sie sind nur zum Entwickeln gedacht, nicht zum Verteilen.

---

## 2. Signed Release-APK bauen und sideloaden

Wenn du die App ohne Play Store auf dein eigenes oder ein zweites Handy
bringen willst (z. B. Familien-Geraet), brauchst du ein **signiertes
Release-APK**.

### 2.1 Signing-Key generieren (Einmalig)

Der Key signiert ALLE deine Releases. **Geht er verloren, kannst du
nie wieder Updates fuer dieselbe App im Play Store veroeffentlichen.**
Backup an mindestens zwei sichere Orte (Passwort-Manager + USB-Stick im Tresor).

```bash
cd D:\claudi\2026-05-03-bonbudget
keytool -genkey -v ^
  -keystore android/app/upload-keystore.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias upload
```

> Auf macOS/Linux statt `^` ein `\` als Zeilenumbruch.

`keytool` fragt nach:
- **Keystore-Passwort:** lang und stark, gut aufbewahren.
- **Vor- und Nachname / Org / Stadt / Land:** beliebig, taucht im Cert auf.
- **Key-Passwort:** kann gleich dem Keystore-Passwort sein (RETURN druecken).

Ergebnis: `android/app/upload-keystore.jks`. **Niemals committen.**
Steht bereits im `.gitignore`-Pattern, aber pruefe es zur Sicherheit.

### 2.2 Signing in Gradle einbinden

`android/key.properties` anlegen (nicht committen!):

```properties
storePassword=DEIN_KEYSTORE_PASSWORT
keyPassword=DEIN_KEY_PASSWORT
keyAlias=upload
storeFile=upload-keystore.jks
```

In `android/app/build.gradle` _vor_ dem `android { ... }`-Block:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Innerhalb von `android { ... }` einen `signingConfigs`-Block einfuegen
und in `buildTypes.release` darauf verweisen:

```gradle
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
    }
}
```

### 2.3 Release-APK bauen

```bash
flutter build apk --release ^
  --obfuscate ^
  --split-debug-info=build/symbols
```

- **`--obfuscate`** verschleiert Dart-Code (verhindert triviale
  Reverse-Engineering-Ansaetze).
- **`--split-debug-info=...`** legt Debug-Symbole separat ab. Du brauchst
  diese Symbole, um spaeter Crash-Reports zu lesen. **Backup mitnehmen.**

Ergebnis: `build/app/outputs/flutter-apk/app-release.apk` (~30-50 MB,
ML Kit ist gross).

### 2.4 APK auf das Handy uebertragen

**Variante A: Direkt per USB (`adb`)**

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

`adb` kommt mit den Android-SDK-Platform-Tools (Android Studio installiert
das automatisch). Funktioniert nur, wenn USB-Debugging an ist.

**Variante B: Per Datei (z. B. ueber Cloud / E-Mail)**

1. APK auf das Handy uebertragen (Drive, Mail, USB-Stick mit OTG).
2. APK-Datei am Handy oeffnen.
3. Beim ersten Mal: **"Installieren von unbekannten Quellen erlauben"**
   im jeweiligen App-Store / Datei-Manager bestaetigen.
4. Installation laeuft durch.

> **Achtung:** Eine zweite App-Installation aus anderer Quelle
> (z. B. spaeter Play Store) erfordert vorher Deinstallation. Daten
> gehen dabei verloren - das Auto-Backup ist abgeschaltet (siehe
> Privacy-Konzept).

---

## 3. Vor dem Play-Store: Pflichtarbeiten am Projekt

Diese Punkte muessen erledigt sein, bevor Google Play den AAB akzeptiert.

### 3.1 Application-ID festlegen

In `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "de.deinedomain.bonbudget"
    // ...
}
```

Die ID **kann nie wieder geaendert werden**, sobald die App im Store ist.
Format: `tld.domain.appname`. Idealerweise eine Domain, die dir gehoert.

### 3.2 Versionierung

In `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- Vor dem Pluszeichen = **versionName** (sichtbar im Store).
- Nach dem Pluszeichen = **versionCode** (intern, MUSS bei jedem Upload
  hochgezaehlt werden, sonst akzeptiert Google das nicht).

### 3.3 App-Icon

Erst neues Paket hinzufuegen (in `pubspec.yaml`):

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

Dann am Ende der `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/icon/icon.png
  adaptive_icon_background: "#14B8A6"
  adaptive_icon_foreground: assets/icon/icon-foreground.png
```

`assets/icon/icon.png` muss 1024x1024 PNG sein, mit transparentem Hintergrund.
Generator-Command:

```bash
flutter pub get
dart run flutter_launcher_icons
```

### 3.4 Splash-Screen

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.1
```

```yaml
flutter_native_splash:
  color: "#14B8A6"
  image: assets/splash/logo.png
  android_12:
    image: assets/splash/logo-android12.png
    color: "#14B8A6"
```

```bash
dart run flutter_native_splash:create
```

### 3.5 AndroidManifest.xml: Permissions

In `android/app/src/main/AndroidManifest.xml` muessen die folgenden
Permissions deklariert sein, weil ML Kit, image_picker und
flutter_secure_storage darauf angewiesen sind:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <application
        android:label="BonBudget"
        android:allowBackup="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        ...>
```

`allowBackup="false"` ist wichtig: sonst wuerde Android bei System-Backups
die SQLCipher-Datei kopieren - das wollen wir bei einem Privacy-First-Tool
vermeiden.

Lege auch `android/app/src/main/res/xml/backup_rules.xml` und
`data_extraction_rules.xml` an, jeweils mit `<full-backup-content>` /
`<data-extraction-rules>` ohne Includes (= explizit nichts).

### 3.6 Datenschutzerklaerung

Google Play **verlangt eine oeffentliche URL** mit Datenschutzerklaerung
(auch wenn die App lokal arbeitet, weil sie Camera/Storage nutzt).

Minimal-Inhalt:
- Welche Daten werden erhoben? -> Keine. Alle bleiben lokal.
- Permissions: Camera (Bon-OCR), Storage (Galerie-Upload), Biometrie
  (Anmeldung).
- Wer ist verantwortlich? -> Du, mit Kontakt.
- Stand des Dokuments.

Hosting: GitHub Pages, eigene Domain, oder Notion/Telegraph - Hauptsache
dauerhaft erreichbar.

### 3.7 R8 / Code-Shrinking

In `android/app/build.gradle` ist `minifyEnabled true` und
`shrinkResources true` schon gesetzt (siehe 2.2). Falls Build dann
Reflection-Crashes meldet, brauchen wir ProGuard-Rules in
`android/app/proguard-rules.pro`. Fuer dieses Projekt sollte das
nicht noetig sein, weil keine Reflection-Pakete (Hive, json_serializable,
etc.) genutzt werden. Falls doch, hier Regeln ergaenzen.

---

## 4. App Bundle (AAB) fuer den Play Store bauen

Google bevorzugt **AAB** (Android App Bundle) statt APK. Google Play
generiert daraus automatisch optimierte APKs pro Geraet.

```bash
flutter build appbundle --release ^
  --obfuscate ^
  --split-debug-info=build/symbols
```

Ergebnis: `build/app/outputs/bundle/release/app-release.aab`.

Pruefen, was drin ist (optional, mit `bundletool` aus den Android-Tools):

```bash
bundletool build-apks --bundle=app-release.aab --output=test.apks
bundletool install-apks --apks=test.apks
```

---

## 5. Google Play Console: erstmaliges Release

### 5.1 Account anlegen

1. <https://play.google.com/console> -> registrieren.
2. **Einmalige Gebuehr 25 USD** mit Kreditkarte.
3. Identitaet verifizieren (kann 24-48 h dauern).

### 5.2 Neue App anlegen

1. **Alle Apps** -> **App erstellen**.
2. App-Name: `BonBudget` (Anzeige).
3. Standardsprache: Deutsch.
4. Typ: **App** (kein Spiel).
5. Kostenlos / Kostenpflichtig: **Kostenlos**.
6. Erklaerungen abhaken (Richtlinien, US-Exportgesetze).

### 5.3 Pflicht-Setup (linke Sidebar arbeiten)

| Punkt | Was eintragen |
|---|---|
| **Datenschutzerklaerung** | URL aus Schritt 3.6 |
| **App-Zugriff** | "Alle Funktionen verfuegbar ohne Einschraenkungen" (kein Login fuer Reviewer noetig, weil lokaler Account) |
| **Werbung** | "Enthaelt keine Werbung" |
| **Inhaltsbewertung** | Fragebogen ausfuellen, Bonbudget passt in "Tools / Finance", USK 0 / PEGI 3 |
| **Zielgruppe / Inhalt** | Erwachsene |
| **Datenschutz / Datensicherheit** | Wichtigster Block, siehe 5.4 |
| **Regierungs-Apps** | Nein |
| **News-App** | Nein |
| **COVID-19** | Nein |

### 5.4 Datenschutz-Formular ("Data Safety")

BonBudget sammelt **keine** Daten. Im Formular angeben:
- "Erfasst deine App Nutzerdaten?" -> **Nein**.
- "Werden Daten verschluesselt uebertragen?" -> n/a (es gibt keine Uebertragung).
- "Koennen Nutzer Daten loeschen?" -> Ja, ueber **Einstellungen ->
  Account zuruecksetzen**.

### 5.5 Store-Eintrag (Listing)

| Feld | Inhalt |
|---|---|
| **App-Name** | BonBudget |
| **Kurzbeschreibung** (max. 80 Zeichen) | Lokaler Bon-Tracker mit OCR. Privacy-first, alles bleibt auf deinem Handy. |
| **Vollstaendige Beschreibung** | (siehe Vorlage unten) |
| **App-Icon** | 512x512 PNG, aus dem 1024er Source verkleinert |
| **Feature-Grafik** | 1024x500 PNG, prominent oben in der Store-Seite |
| **Screenshots** | mind. 2, max. 8, mind. 320 px Kantenlaenge. **Empfehlung: 6** (Login, Dashboard, Bon-Scan, Statistik, Einstellungen, Kategorien) |
| **App-Kategorie** | Finanzen |
| **Tags** | budget, expenses, ocr, privacy |
| **Kontakt** | Eigene Email, optional Website |

**Vorlage Vollbeschreibung:**

```
BonBudget ist ein Bon- und Budget-Tracker, der konsequent ohne Cloud
arbeitet. Du fotografierst deinen Kassenbon, On-Device-OCR (Google ML
Kit) erkennt Haendler, Datum und einzelne Positionen, und das Foto
wird unmittelbar danach geloescht.

** Funktionen **
- Lokal verschluesselte Datenbank (SQLCipher / AES-256)
- Argon2id-Passwort + optionale Biometrie (Fingerabdruck / Face ID)
- Budgets pro Kategorie, automatisches Gesamtbudget
- Dashboard mit Restbudget-Ring und Auslastung pro Kategorie
- Statistik mit Monats-Trend, Top-Kategorien, Kategorie-vs-Budget-Vergleich
- Auto-Logout nach Inaktivitaet, sofortiger Logout bei App-Wechsel

** Deine Daten bleiben deine Daten. **
- Keine Cloud, keine Server, keine Telemetrie
- Keine Werbung, keine Tracker
- Open-Source-Lizenzen direkt in der App einsehbar

Anforderungen: Android 8.0+, Kamera fuer Bon-Foto (optional).
```

### 5.6 Release rollen

1. Linke Sidebar -> **Veroeffentlichen** -> **Tests** -> **Internal Testing**.
2. **Neuen Release erstellen**.
3. AAB hochladen.
4. Release-Name automatisch (`1.0.0 (1)` z. B.).
5. **Versionshinweise** in Deutsch und Englisch eintippen.
6. **Speichern** -> **Pruefen** -> **Rollout starten**.
7. Tester-Liste anlegen (eigene Email-Adresse), Opt-In-Link aus der Console
   teilen, im Browser oeffnen, Bestaetigung anklicken.
8. App im Play Store ueber den Tester-Link installieren.

> **Internal Testing** ist sofort verfuegbar (kein Review). Erst beim
> Schritt **Production** geht der Antrag in die Pruefung (3-7 Tage).

### 5.7 Production-Release

Wenn Internal Testing OK ist:

1. **Closed Testing** (optional) -> kleine Tester-Gruppe via Email-Liste.
2. **Open Testing** (optional) -> jeder mit dem Opt-In-Link.
3. **Production** -> oeffentlich. Hier kommt der Pflicht-Review.

Erstes Production-Review: meist 3 Tage, kann bis zu 7 Tage dauern.
Wenn Google Probleme findet (haeufig: Permissions ohne Erklaerung,
Datenschutz-URL nicht erreichbar), bekommst du eine Email mit Liste.

---

## 6. Updates ausrollen

1. Code committen.
2. `pubspec.yaml`-Version hochziehen, z. B. `1.0.0+1` -> `1.0.1+2`.
3. AAB neu bauen (siehe Abschnitt 4).
4. Play Console -> **Production** -> **Neuen Release erstellen**.
5. Neue AAB hochladen, Versionshinweise.
6. Rollout starten.
7. **Phased rollout** nutzen: erst 5 % der Nutzer, nach 24 h auf 50 %,
   dann auf 100 %. So fallen Crash-Spitzen schnell auf, ohne alle
   Nutzer zu betreffen.

### Crash-Reports lesen

Play Console -> **Vitals** -> **Crashes & ANRs**. Stack-Traces sind
**ohne `--split-debug-info`-Symbole unlesbar** (verschleiert/obfuskiert).
Daher in **Vitals** -> **App Bundle Explorer** -> **Debug-Symbole hochladen**:

```
D:\claudi\2026-05-03-bonbudget\build\symbols\
```

Das Verzeichnis als ZIP einpacken und hochladen.

---

## 7. iOS in Kuerze

iOS-Deployment ist deutlich aufwendiger und teurer:

- **Apple Developer Program**: 99 USD pro Jahr (NICHT einmalig).
- **macOS** mit aktuellem Xcode zwingend.
- Provisioning-Profile / Certificates ueber Apple Developer Portal.
- TestFlight als Beta-Verteilung (vergleichbar mit Internal Testing).
- App Store Connect statt Play Console.

```bash
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols
```

Ergebnis als IPA in `build/ios/ipa/`. Hochladen via **Transporter** App
oder `xcrun altool`.

iOS-Review ist meist innerhalb von 24 h durch, oft schneller als Google.
Aber Reviewer testen aktiv und melden mehr stilistische Probleme.

---

## 8. Alternativen: Direkt-APK & F-Droid

### 8.1 Direkt-APK ueber GitHub Releases

Wenn du keine Play-Store-Reichweite brauchst:

1. APK aus Schritt 2.3 nehmen.
2. GitHub Release anlegen, APK anhaengen.
3. Nutzer laden runter, "Installation aus unbekannter Quelle" einmalig.

Vorteil: kein Review, kein 25 USD-Account, keine Daten an Google.
Nachteil: keine automatischen Updates, schwer zu finden.

### 8.2 F-Droid

F-Droid ist DER Store fuer Privacy-First-Apps. Anforderungen:

- App muss Open-Source sein (FOSS-Lizenz wie GPL/MIT/Apache).
- Keine Google-Play-Services, keine geschlossenen Bibliotheken.
- **Problem:** `google_mlkit_text_recognition` ist proprietaer. Fuer
  F-Droid-Aufnahme muesstest du einen Open-Source-OCR-Pfad
  alternativ einbauen (z. B. Tesseract via `flutter_tesseract_ocr`),
  oder zwei Build-Varianten pflegen.

Wenn das interessant wird, separate TODO-Spur. Aktuell out-of-scope.

---

## 9. Checkliste vor jedem Release

```
[ ] git status sauber, alle Aenderungen committet
[ ] pubspec.yaml versionCode + versionName hochgezogen
[ ] flutter analyze: keine Errors / Warnings
[ ] flutter test: alle Tests gruen
[ ] flutter test integration_test/: E2E auf einem Geraet gruen
[ ] AAB / APK frisch gebaut mit --obfuscate --split-debug-info
[ ] Manuell durchklicken: Register -> Login -> Kategorie -> Budget ->
    Bon scannen -> Statistik -> Settings -> Account-Reset
[ ] Versionshinweise vorbereitet (DE + EN)
[ ] Falls Permissions-Aenderung: AndroidManifest.xml aktuell
[ ] Datenschutzerklaerung erreichbar und aktuell
[ ] Symbol-Verzeichnis (build/symbols) gesichert
[ ] Backup vom Keystore an zweitem Ort vorhanden
```

Erst dann hochladen.
