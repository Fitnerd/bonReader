# BonBudget

Privacy-first Bon- und Budget-Tracker fuer Android und iOS.
Alle Daten bleiben **lokal und verschluesselt** auf deinem Geraet.

## Status

- [x] Schritt 1: Projekt-Setup & Architektur
- [x] Schritt 2: Datenmodell & verschluesselte DB
- [x] Schritt 3: Auth-System (Biometrie / Geraete-PIN + Secure Storage)
- [x] Schritt 4: Kategorien-Verwaltung & Budgets
- [x] Schritt 5: Manuelle Ausgabe-Erfassung
- [x] Schritt 6: Bon-Foto + OCR + Positions-Erkennung
- [x] Schritt 7: Dashboard & Budget-Anzeige
- [x] Schritt 8: Statistik & Diagramme
- [x] Schritt 9: Einstellungen, Polish, Release-Vorbereitung

## Features

- **Lokal & verschluesselt**: SQLCipher (AES-256). Zugriff per Biometrie
  oder Geraete-PIN ueber den hardware-gestuetzten Secure Storage.
  Kein App-Passwort. Keine Cloud, keine Telemetrie.
- **Bon scannen**: On-device OCR (Google ML Kit). Foto wird unmittelbar
  nach Auswertung geloescht.
- **Heuristischer Bon-Parser**: Erkennt Haendler, Datum, Total und einzelne
  Positionen aus typischen deutschen Kassenbons.
- **Manuelle Erfassung**: Wenn kein Bon da ist - Form mit Positionen.
- **Budgets pro Kategorie**: Gesamtbudget = Summe der Kategorie-Budgets.
- **Dashboard**: Restbudget-Ring, Auslastung pro Kategorie, letzte Ausgaben.
- **Statistik**: 12-Monats-Trend, Top-Kategorien-Donut, Monatsvergleich.
- **Biometrie-Only**: Fingerprint / Face ID oder Geraete-PIN als alleinige
  Anmeldung. **Kein Recovery** - bei Geraeteverlust sind die Daten weg.
- **Auto-Logout**: konfigurierbar (1-30 Min) und sofort beim Backgrounding.
- **Account-Reset**: Komplett-Wipe direkt in der App.

---

## Voraussetzungen

| Tool | Version | Wofuer |
|------|---------|-------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | >= 3.22 (entwickelt mit 3.41.9) | Build & Runtime |
| Dart SDK | >= 3.4 (kommt mit Flutter) | Sprache |
| [Android Studio](https://developer.android.com/studio) | aktuelle | Android-SDK + Emulator |
| [Visual Studio Code](https://code.visualstudio.com/) | aktuelle | Editor (optional, alternativ Android Studio / IntelliJ) |
| Xcode | >= 15 | nur fuer iOS-Build, nur auf macOS |
| Git | >= 2.30 | Versionskontrolle |

Nach der Flutter-Installation pruefen:

```bash
flutter --version
flutter doctor -v
```

`flutter doctor` muss bei den Punkten **Flutter**, **Android toolchain** und
deiner gewaehlten IDE einen gruenen Haken zeigen. Web/Linux/macOS-Desktop
sind fuer dieses Projekt nicht erforderlich.

### Empfohlene VS-Code-Erweiterungen

- **Dart-Code/Flutter** (`Dart-Code.flutter`) - Pflicht
- **Dart-Code/Dart** (`Dart-Code.dart-code`) - kommt automatisch mit
- **Error Lens** (`usernamehw.errorlens`) - inline-Fehleranzeige
- **Flutter Riverpod Snippets** (`robert-brunhage.flutter-riverpod-snippets`) - optional
- **Material Icon Theme** (`PKief.material-icon-theme`) - optional

In VS Code: `Strg+Shift+X` -> suchen -> **Install**.

---

## Projekt einrichten

```bash
# 1. Repository klonen oder Ordner oeffnen
cd D:\claudi\2026-05-03-bonbudget

# 2. Abhaengigkeiten holen (laedt ca. 200 MB an Pub-Packages und ML-Kit-SDKs)
flutter pub get
```

Falls du das Projekt aus dem Git-Bundle wiederherstellst, das mitgeliefert
wird (siehe `2026-05-03-bonbudget-history.bundle` im Parent-Ordner):

```cmd
:: kaputten leeren .git-Ordner aus dem Projekt entfernen
rmdir /s /q D:\claudi\2026-05-03-bonbudget\.git

:: Bundle in das Projekt klonen (Branch heisst "main")
cd D:\claudi
git clone D:\claudi\2026-05-03-bonbudget-history.bundle bonbudget-restored
xcopy /E /H /Y bonbudget-restored\.git 2026-05-03-bonbudget\.git\
rmdir /s /q bonbudget-restored

:: pruefen
cd 2026-05-03-bonbudget
git log --oneline
```

---

## In Visual Studio Code arbeiten

### Schritt fuer Schritt: erstes Mal in VS Code starten

1. **VS Code oeffnen** -> `Datei` -> `Ordner oeffnen` ->
   `D:\claudi\2026-05-03-bonbudget`.
2. Beim ersten Oeffnen fragt VS Code, ob die Pakete installiert werden
   sollen. Auf **Get packages** klicken (oder im Terminal
   `flutter pub get` ausfuehren).
3. Unten rechts in der Statusleiste das **Zielgeraet** waehlen:
   - Klick auf das Geraete-Label (z. B. "No Device") -> Auswahl-Dropdown
     oeffnet sich.
   - **Android-Emulator starten:** "Start Android Emulator" -> einen aus
     der Liste waehlen. Wenn keiner da ist, in Android Studio einen
     anlegen (`AVD Manager` -> `Create Virtual Device`, **API 33** oder
     neuer wegen ML Kit).
   - **Echtes Android-Geraet:** USB-Debugging aktivieren (`Einstellungen`
     -> `Ueber das Telefon` -> 7x auf Build-Nummer tippen -> zurueck ->
     `Entwickleroptionen` -> `USB-Debugging`). Dann am USB anschliessen
     und Dialog auf dem Telefon bestaetigen.
4. **App starten:** `F5` (Run/Debug) oder oben rechts auf den gruenen
   Play-Pfeil. Beim ersten Mal dauert es 1-3 Min (Gradle-Setup,
   Native-Code kompilieren).
5. Sobald die App laeuft, wird automatisch der **Splash-Screen** angezeigt
   und du landest auf der Registrierung.

### Hot Reload / Hot Restart

Waehrend die App laeuft (Debug-Modus):

- **Hot Reload** (`r` im Debug-Terminal oder `Strg+S` automatisch durch
  VS Code): UI-Aenderungen sind sofort sichtbar, ohne State-Verlust.
- **Hot Restart** (`Shift+r` oder `Strg+Shift+F5`): App wird komplett neu
  initialisiert, State weg.

Wann was:

- Logik in Widgets / Theme-Aenderungen -> Hot Reload reicht.
- Provider-Builder, `main.dart`, neue Routes -> Hot Restart.
- pubspec-Aenderungen, native Code -> komplett neu starten (`F5` neu).

### Debugger nutzen

- Breakpoints per Klick links neben der Zeilennummer setzen.
- Waehrend die App laeuft: `F5` -> der Code stoppt am Breakpoint.
- Variables-Panel links zeigt alle Variablen im Scope.
- Debug Console unten erlaubt Eingaben (z. B. `ref.read(...)` zum Inspizieren).

### Useful Commands (`Strg+Shift+P`)

| Command | Zweck |
|---------|-------|
| `Flutter: Get Packages` | `flutter pub get` |
| `Flutter: Run Flutter Doctor` | Diagnose |
| `Flutter: Hot Reload` | Manuelles Reload |
| `Flutter: Open DevTools` | Performance/Inspector im Browser |
| `Dart: Sort Members` | Imports/Member sortieren |
| `Dart: Restart Analysis Server` | Bei "stuck" Editor |

---

## App starten (Kommandozeile)

```bash
# Liste aller verbundenen Geraete
flutter devices

# Auf erstes verfuegbares Geraet:
flutter run

# Auf ein bestimmtes Geraet:
flutter run -d <device-id>

# Release-Performance testen (langsamer Build, schneller Runtime):
flutter run --release
```

Waehrend `flutter run` laeuft:
- `r` = Hot Reload
- `R` = Hot Restart
- `q` = beenden

---

## Tests ausfuehren

### Unit-Tests + Widget-Tests (lokal, ohne Geraet)

```bash
# Alles
flutter test

# Einzelne Datei
flutter test test/unit/data/services/receipt_parser_test.dart

# Tests, die einen Begriff im Namen enthalten
flutter test --plain-name "ReceiptParser"

# Mit Coverage-Report (erzeugt coverage/lcov.info)
flutter test --coverage
```

In VS Code: Tests werden automatisch erkannt. Ueber dem `void main()`-Block
erscheinen die Lenses **Run | Debug**. Klicken um den jeweiligen Test
laufen zu lassen, mit Live-Ergebnis im "Test Results"-Panel.

Coverage als HTML anzeigen (Optional, braucht
[`lcov`](https://github.com/linux-test-project/lcov)):

```bash
genhtml coverage/lcov.info -o coverage/html
# dann coverage/html/index.html im Browser oeffnen
```

### Integration- / E2E-Tests (brauchen Geraet oder Emulator)

```bash
flutter test integration_test/
```

> WARNUNG: Vorbedingung: Der E2E-Happy-Path-Test in `integration_test/`
> legt einen Account an. Wenn auf dem Testgeraet schon einer existiert,
> schlaegt der Test fehl. Vorher in der App ueber *Einstellungen ->
> Account und alle Daten loeschen* zuruecksetzen oder die App
> deinstallieren.

### Was wird getestet

- **Repository-Layer** (`test/unit/data/repositories/`): Schema, CRUD,
  Edge-Cases (z. B. Default-Kategorien-Hide-Logik), gegen In-Memory
  SQLite (`sqflite_common_ffi`).
- **Provider-Layer** (`test/unit/presentation/providers/`): Riverpod
  AsyncNotifier, abgeleitete Provider, Aggregations-Logik.
- **Services** (`test/unit/data/services/`): Receipt-Parser-Heuristiken
  gegen synthetischen OCR-Output.
- **Widgets** (`test/widget/`): App-Smoke (Splash, Material-3-Theme).
- **Auth-Repository**: gegen `FakePasswordHasher` und `FakeSecureStorage`.
  *Nicht* getestet: echtes Argon2 (braucht native Bindings; wird durch
  E2E-Test auf Geraet abgedeckt).

---

## Code-Qualitaet

```bash
# Statische Analyse (lints aus analysis_options.yaml)
flutter analyze

# Dart-Format auf alle Dateien anwenden
dart format lib test integration_test
```

In VS Code: Format on Save aktivieren - lege `.vscode/settings.json` an
mit folgendem Inhalt:

```jsonc
{
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "Dart-Code.dart-code"
  },
  "dart.lineLength": 80
}
```

Lints zeigen sich automatisch durch wellenfoermige Unterstreichungen +
Probleme-Panel (`Strg+Shift+M`).

---

## Deployment & Release

Komplette Anleitung in [`docs/2026-05-04-deployment.md`](docs/2026-05-04-deployment.md):
- Auf das eigene Handy per USB (Debug-Build)
- Signed Release-APK + Sideload
- Pflichtarbeiten vor dem Play-Store (Signing-Key, App-Icon, Splash, Permissions, Datenschutzerklaerung)
- AAB bauen, Play Console einrichten, Listing, Datenschutz-Formular, Release-Stufen
- Updates ausrollen, Crash-Reports lesen
- iOS-Kurzanleitung
- F-Droid und Direkt-APK als Alternativen
- Pre-Release-Checkliste

## Release-Build (Android)

Mit Code-Obfuscation und ausgelagerten Debug-Symbolen:

```bash
# APK (sideloadable):
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols/

# App Bundle (fuer Play Store):
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/
```

- APK liegt danach in `build/app/outputs/flutter-apk/app-release.apk`.
- AAB liegt in `build/app/outputs/bundle/release/app-release.aab`.
- Der `build/symbols/`-Ordner gehoert **NICHT** in den Play-Store-Upload,
  aber unbedingt **lokal aufbewahren** - sonst sind spaetere Crash-Reports
  unlesbar.

### Vor dem ersten Release

1. **Signing-Konfiguration** in `android/key.properties` und
   `android/app/build.gradle` einrichten (Standard-Flutter-Doku).
2. **App-Icon** generieren (z. B. mit `flutter_launcher_icons` ergaenzen -
   im pubspec noch nicht enthalten).
3. **Splash-Screen** generieren (`flutter_native_splash`).
4. **`AndroidManifest.xml`** pruefen: Camera- und Storage-Permissions
   muessen explizit aufgelistet sein (siehe TODO in
   `docs/2026-05-03-todo.md`).
5. **`flutter analyze`** muss clean sein.
6. Manuell durchklicken: Register -> Login -> Kategorie -> Budget -> Bon
   scannen -> Liste -> Statistik -> Settings.

---

## Release-Build (iOS, macOS only)

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/
```

Voraussetzung: Apple-Developer-Account, Provisioning-Profile, Xcode-Setup.

---

## Projektstruktur

```
lib/
+-- app.dart                  # MaterialApp + Theme + Router-Bootstrap
+-- main.dart                 # Entry Point, ProviderScope
+-- core/                     # Querschnittsbelange
|   +-- constants/            # AppConstants (Argon2-Parameter, Keys, ...)
|   +-- providers/            # Provider-Registry (DB, Auth, OCR)
|   +-- router/               # go_router + Auth-Redirects
|   +-- theme/                # Mint-Gruen Material-3
|   +-- utils/                # CurrencyFormatter, ...
+-- data/                     # Datenschicht
|   +-- datasources/          # SQLCipher-DB, SecureStorage
|   |   +-- database/         # Migrationen, Schema, Passphrase
|   +-- repositories/         # Repository-Implementierungen
|   +-- services/             # PasswordHasher, OCR, Photo, Biometrie
+-- domain/                   # Domain-Modell (frameworkfrei)
|   +-- entities/             # Immutable Entities
|   +-- repositories/         # Repository-Interfaces
+-- presentation/             # UI-Schicht
    +-- providers/            # Riverpod-State (auth, categories,
    |                         #   budgets, expenses, settings, stats)
    +-- screens/              # Auth, Home/Dashboard, Categories,
    |                         #   Budget, Expense, Stats, Settings
    +-- widgets/              # AutoLogoutListener, ...

test/
+-- helpers/                  # FakeSecureStorage, FakePasswordHasher,
|                             #   In-Memory-DB-Helper
+-- unit/                     # Pure-Logik-Tests (Repos, Provider,
|                             #   Services)
+-- widget/                   # App-Smoke-Tests

integration_test/             # E2E-Tests auf Geraet / Emulator
docs/                         # Architektur, Security, Testing,
                              #   Agent-Memory, TODO
```

Im VS-Code-Explorer kann der Projektbaum sehr gut nach diesem Schema
durchstoebert werden - Datei-Icons via "Material Icon Theme" helfen dabei.

---

## Sicherheit & Datenschutz

Siehe [`docs/2026-05-03-security.md`](docs/2026-05-03-security.md).

Kurzfassung:
- Passwort wird mit **Argon2id** (RFC 9106: t=3, m=64 MB, p=4) gehasht.
  Nie im Klartext gespeichert.
- Sensible Daten (DB-Passphrase, Hash, Salt) liegen im **Android Keystore**
  / **iOS Keychain** via `flutter_secure_storage`.
- Datenbank wird mit **SQLCipher** (AES-256) verschluesselt
  (`sqflite_sqlcipher`).
- DB-Passphrase ist eine 256-bit `Random.secure()`-Groesse - **nicht** vom
  User-Passwort abgeleitet, damit ein Passwortwechsel keine
  DB-Re-Encryption ausloest.
- **Bon-Fotos** werden nach OCR-Auswertung sofort geloescht.
- **Auto-Logout** nach Inaktivitaet (konfigurierbar 1-30 Min) und sofort
  beim Wechsel in den Hintergrund.
- **Constant-time** Vergleich beim Passwort-Check (verhindert
  Timing-Attacks).
- **5 Fehlversuche** aktivieren einen Cool-down.

---

## Architektur-Ueberblick

Siehe [`docs/2026-05-03-architecture.md`](docs/2026-05-03-architecture.md).

Stichwort: **Clean Architecture mit drei Schichten**
(`presentation` <-> `domain` <-> `data`), **Riverpod** als
State-Management, **go_router** mit Auth-basiertem Redirect,
Geld immer als `int` in Cent.

---

## Bekannte offene Punkte

Siehe [`docs/2026-05-03-todo.md`](docs/2026-05-03-todo.md). Kurze
Highlights:

- App-Icon und nativer Splash-Screen sind noch nicht generiert.
- Camera-/Galerie-Permissions im `AndroidManifest.xml` und
  `Info.plist` muessen vor dem ersten Release ergaenzt werden.
- Kategorie-Heuristik nach Haendlername waere nice-to-have.
- Receipt-Parser ist DE-only; weitere Locales out-of-scope.

---

## Haeufige Probleme

| Problem | Ursache / Loesung |
|---------|--------------------|
| `pub get` schlaegt fehl mit "Because every version of flutter_localizations from sdk depends on intl 0.20.2 ..." | Im pubspec ist `intl: ^0.20.2` korrekt gepinnt. Wenn das Problem auftritt, `flutter clean && flutter pub get`. |
| `Could not resolve all files for configuration ':app:debugCompileClasspath'` | Gradle-Cache loeschen: `cd android && ./gradlew clean` (Linux/Mac) bzw. `gradlew clean` (Windows). |
| App startet, aber zeigt nur weissen Bildschirm | Native ML-Kit-Bindings nicht installiert. Beim ersten Start wartet Flutter darauf, dass ML Kit das Modell herunterlaedt. Geraete-Internet sicherstellen. |
| Tests scheitern mit "MissingPluginException(No implementation found for method ...)" | Plugin-spezifische Tests muessen via `integration_test/` auf Geraet laufen, nicht via `flutter test`. |
| `flutter doctor` meldet "Android licenses not accepted" | `flutter doctor --android-licenses` ausfuehren und alle bestaetigen. |
| In VS Code findet Dart-Plugin keinen Flutter-SDK | `Strg+Shift+P` -> `Dart: Change SDK` -> Flutter-SDK-Pfad eingeben. |

---

## Lizenz

Privates Projekt, alle Rechte vorbehalten.
