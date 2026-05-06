# BonBudget – Offene TODOs

Konsolidierte Aufgabenliste. Was bereits abgeschlossen ist (Biometrie-Umbau,
Code-/Security-Review-Runde 1, Pagination-UI-Migration, ML Kit OCR-Pfad
inkl. Tests, Lokalisierung), steht hier nicht mehr — siehe Git-Historie.

Features (Vorhanden, Geplant, Out-of-Scope) stehen separat in
[FEATURES.md](FEATURES.md). Diese Datei ist nur Bug-/Review-/
Aufräum-Backlog.

**Datum:** 2026-05-06 (übernommen aus 2026-05-04-open-review.md, +
Security-Review-Runde 2 vom 2026-05-05)

**Vorgeschlagene Reihenfolge:**

1. `.git/index.lock` (manuell, 30 Sek)
2. `flutter analyze && flutter test` grün halten nach jedem Schritt
3. **Hoch:** iOS App-Switcher-Snapshot blocken + `resetAccount()` DB-Datei mit löschen
4. Verbleibende Repo-`!`-Casts (klein)
5. Restliche Widget-Tests (klein)
6. Release-Build-Signatur-Härtung (klein)

---

## Hoch

### [ ] iOS hat kein FLAG_SECURE-Pendant — App-Switcher-Snapshot leakt Finanzdaten

**Dateien:** [ios/Runner/SceneDelegate.swift](ios/Runner/SceneDelegate.swift),
[ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift),
Kommentar-Verweis in [lib/main.dart:11](lib/main.dart) Zeilen 11–12.

`MainActivity.kt` setzt `FLAG_SECURE` und blockt damit auf Android
Screenshots, Screen-Recording und das App-Switcher-Vorschaubild. Der
Kommentar in `main.dart` verspricht diesen Schutz auch global, aber die
iOS-Seite ist leer: weder `AppDelegate` noch `SceneDelegate` reagieren auf
`sceneWillResignActive` / `applicationWillResignActive`. Folge: iOS legt
beim Hintergrund-Wechsel ein Snapshot der App in
`~/Library/Caches/Snapshots/<bundle-id>/...` ab — mit allen aktuell
sichtbaren Beträgen, Bons und Budgets. Diese Snapshots überleben App-
Restarts und können bei iCloud-Backup-Restore auf andere Geräte gelangen.

**Fix:** in `SceneDelegate.swift` bei `sceneWillResignActive(_:)` ein
blickdichtes Overlay (UIView mit Bundle-Icon oder Brandfarbe) auf das
Window legen, bei `sceneDidBecomeActive(_:)` wieder entfernen. Der
Code-Kommentar in `main.dart` muss entweder ergänzt werden („auf iOS via
SceneDelegate-Overlay") oder den iOS-Teil ehrlich erwähnen.

### [ ] `resetAccount()` löscht DB-Datei nicht — App ist nach Reset gebricked

**Datei:** [lib/data/repositories/auth_repository_impl.dart](lib/data/repositories/auth_repository_impl.dart),
`resetAccount()` Zeilen 75–88.

Die Methode macht `txn.delete(...)` auf alle Tabellen und ruft danach
`_storage.wipeAll()`. Die SQLCipher-DB-Datei selbst bleibt am alten Pfad
und ist mit der **alten** Passphrase verschlüsselt. Beim nächsten Setup
generiert `DatabasePassphraseService` eine **neue** 32-Byte-Passphrase,
und `openDatabase()` versucht damit die alte Datei zu öffnen → SQLCipher
gibt „file is encrypted or is not a database" zurück, der Setup-Flow
schlägt fehl, App ist nicht mehr nutzbar bis der Nutzer App-Daten manuell
löscht (Android-Settings) bzw. die App neu installiert (iOS).

Zweiter Aspekt: gelöschte Tabellen-Inhalte können bei roher Filesystem-
Forensik (vor SQLCipher-Page-Reuse) noch rekonstruierbar sein.

**Fix:**

```dart
Future<void> resetAccount() async {
  // 1. DB schliessen (Filehandle freigeben)
  await ref.read(appDatabaseProvider.future).then((db) => db.close());
  // 2. Secure Storage zuerst — beseitigt Marker, falls Schritt 3 crasht
  await _storage.wipeAll();
  // 3. DB-Datei loeschen
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, AppConstants.databaseFileName));
  if (await file.exists()) await file.delete();
}
```

Nebenwirkung des Fix: die Reihenfolge wird atomar-resilient — wenn der
Prozess zwischen Schritt 2 und 3 stirbt, ist der Setup-Marker schon weg,
beim nächsten Start wird das Setup neu durchlaufen und die alte Datei mit
einer neuen Passphrase überschrieben. Aktuelle Reihenfolge (DB-Tabellen
leeren → Storage wipen) kann den umgekehrten Halbzustand erzeugen
(`setupComplete=1` im Storage, leere Tabellen — `isSetupComplete()` deckt
das defensiv ab, ist aber Defence-in-Depth, kein sauberes Design).

---

## Mittel

### [ ] DB-Passphrase nicht hardware-/biometrisch gebunden

*Security-Runde 2026-05-05*

**Dateien:** [lib/data/datasources/secure_storage_service.dart](lib/data/datasources/secure_storage_service.dart),
[lib/data/datasources/database/database_passphrase_service.dart](lib/data/datasources/database/database_passphrase_service.dart).

`SecureStorageService` benutzt `KeychainAccessibility.first_unlock_this_device`
(iOS) und `EncryptedSharedPreferences` (Android). Beide Verfahren sind
hardware-backed im Sinne von „Schlüssel liegt im Secure Element / Keystore",
aber **nicht** an User-Authentication gebunden. Nach erfolgreicher
Biometrie ruft die App schlicht `_storage.read(secureKeyDbPassphrase)`
auf — der Biometrie-Prompt ist also ein reiner App-Layer-Gate. Ein
Angreifer mit Root/Jailbreak (oder mit forensischem Zugriff auf ein
Gerät, das nach einem Reboot mindestens einmal entsperrt wurde) kann die
Passphrase ohne den Prompt extrahieren und die DB-Datei entschlüsseln.

Echtes Biometrie-Binding würde verlangen:

- **Android:** Keystore-Schlüssel mit
  `KeyGenParameterSpec.Builder(...).setUserAuthenticationRequired(true)
  .setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)`,
  Verschlüsselung der Passphrase mit diesem Schlüssel.
- **iOS:** Keychain-Item mit
  `SecAccessControlCreateWithFlags(.biometryCurrentSet)` und
  `kSecUseAuthenticationContext`.

`flutter_secure_storage` kann das nicht. Optionen: Native-Method-Channel
(viel Code), oder Wechsel auf eine Lib wie `biometric_storage`. Trade-off
ist bewusst zu fällen (Komfort: Geräte-PIN-Fallback bleibt einfach, vs.
Schutz vor physischem Angreifer mit Root). Empfehlung: zumindest in der
Threat-Model-Doku festhalten, was die Biometrie-Schicht aktuell tatsächlich
abwehrt (Diebstahl mit gesperrtem Gerät) und was nicht (Root/Forensik).

### [ ] `AutoLogoutListener` deckt nur Dashboard-Route ab — Touch-Reset wirkungslos in Sub-Screens

*Security-Runde 2026-05-05*

**Datei:** [lib/core/router/app_router.dart:93](lib/core/router/app_router.dart).

`AutoLogoutListener` wraps nur `DashboardScreen`. Alle Sub-Screens
(Expenses, Stats, Settings, Categories, Budget, ExpenseForm,
ReceiptScan) werden via `Navigator.push` auf den App-weiten Navigator
gepusht und sind **nicht** Kinder des Listeners. Der Inactivity-Timer
läuft im Hintergrund weiter, wird durch Touch-Aktivität auf Sub-Screens
aber nicht zurückgesetzt. Ein Nutzer, der 5+ Minuten lang Ausgaben
einträgt oder Statistiken durchscrollt, wird mitten in der Aktion
ausgeloggt.

Lifecycle-basierter Logout (Backgrounding) bleibt korrekt, weil der
`WidgetsBindingObserver` am State-Objekt hängt, nicht am Widget-Tree.

**Fix-Optionen:**

1. `AutoLogoutListener` in `BonBudgetApp.build` um den ganzen Router
   legen (`MaterialApp.router` Builder oder `routerConfig.builder`).
2. `NavigatorObserver` registrieren, der bei jedem Push/Pop den Timer
   resettet und ein zentraler `AutoLogoutController` fungiert.

Variante 1 ist kürzer, hat aber das Problem, dass Auth-Screens (Setup/
Unlock) nicht im autenthifizierten Bereich sind — dort darf der Timer
nicht laufen. Variante 2 ist sauberer.

### [ ] Verbleibende Repo-`!`-Casts

**Datei:** [lib/data/repositories/expense_repository_impl.dart](lib/data/repositories/expense_repository_impl.dart),
`_hydrateOne` (Zeilen ~190–215).

Budget- und Category-Repo sind defensiv. Expense-Repo hat noch
`row[ExpenseCols.id]! as String`-Pattern. Bei DB-Korruption gibt's
NPE statt verständlichem Fehler. Selbes Pattern wie bei Budget/Category
anwenden.

### [ ] Widget-Tests für Settings/Budget/Categories

Auth-Screens haben Widget-Tests (`auth_screens_test.dart`). Settings
und Budget sind fachlich kritisch (Reset-Account, Budget-Speichern) und
verdienen je 1–2 Widget-Tests.

### [ ] Biometrie-Verfügbarkeit live prüfen

`SetupScreen._checkBiometrics()` läuft einmal beim Mount. Wenn der
Nutzer in den Geräte-Einstellungen Biometrie nachträglich aktiviert,
sieht der Setup-Screen das nicht. Fix: `WidgetsBindingObserver` mit
`didChangeAppLifecycleState` + Re-Check beim Resume.

### [ ] Release-Build-Signatur-Härtung

**Datei:** [android/app/build.gradle.kts](android/app/build.gradle.kts), Zeile ~59.

Der `signingConfigs`-Block hat ein Silent-Fail wenn `key.properties`
fehlt — Release-Build läuft dann mit Debug-Keys durch. Sicherer:
`throw GradleException("key.properties fehlt")` statt stiller Fallback.

### [ ] `gradlew` / `gradlew.bat` in `.gitignore`

Beide sind ignoriert (Zeilen 42–43). Die Wrapper *gehören* eigentlich
ins Repo, damit jeder ohne lokale Gradle-Installation bauen kann.
Strittig, weil Standard-Flutter-Gitignore es so macht — Entscheidung
liegt beim Maintainer.

---

## Niedrig

### [ ] `debugPrint('OCR LINES: ...')` loggt PII im Debug-Modus

*Security-Runde 2026-05-05*

**Datei:** [lib/presentation/screens/expense/receipt_scan_screen.dart:72](lib/presentation/screens/expense/receipt_scan_screen.dart).

Der Aufruf ist mit `kDebugMode` umschlossen, also kein Release-Risiko.
Im Debug-Build geht aber der gesamte OCR-Output (Händler, Beträge, Items)
ins Logcat / Xcode-Console — bei aktivem USB-Debugging mit fremdem Host
oder bei Crash-Reportern, die Logs einsammeln, sichtbar. Ist mehr ein
Pattern-Problem: PII direkt in `debugPrint` verleitet dazu, dass das
beim nächsten Refactor versehentlich aus dem `kDebugMode`-Block
herausrutscht.

**Empfehlung:** `_log(parsed)`-Helper, der nur Zeilenanzahl und Confidence
loggt, nie Inhalte:

```dart
if (kDebugMode) {
  debugPrint('OCR: ${ocrResult.lines.length} lines, '
      'confidence=${parsed.confidence.toStringAsFixed(2)}');
}
```

Gleicher Helper auch für `auth_state.dart` `debugPrintStack`-Aufrufe
(`auth.setup`, `auth.unlock`, `auth.migrate`, `auth.reset` — derzeit
ungefährlich, aber konsistenter Stil).

### [ ] Tempdir `bonbudget_scan/` wird nach Crash nicht aufgeräumt

*Security-Runde 2026-05-05*

**Datei:** [lib/data/services/photo_capture_service.dart](lib/data/services/photo_capture_service.dart),
`ImagePickerPhotoCaptureService.capture()`.

`capture()` legt `${tempDir}/bonbudget_scan/scan_<ts>.jpg` an. Im
Normalpfad löscht `_scanFrom`'s `finally`-Block die Datei. Bei Hard-
Crash (OOM während OCR, OS-Kill) bleibt das Foto liegen. Im Tesseract-
Pfad mit `enabled: false` (`PreprocessingPhotoCaptureService` ohne
`processInPlace`) enthält die Datei zusätzlich noch die EXIF-/GPS-Tags
des Originalbilds — Standortinformation des Bon-Aufnahmeorts.

**Fix:** beim App-Start (z. B. in `main.dart` vor `runApp`) einmal
`${tempDir}/bonbudget_scan/` rekursiv leeren:

```dart
final tempDir = await getTemporaryDirectory();
final scanDir = Directory(p.join(tempDir.path, 'bonbudget_scan'));
if (scanDir.existsSync()) {
  try { scanDir.deleteSync(recursive: true); } catch (_) {}
}
```

Zusätzlich: Wenn der Tesseract-Pfad doch jemals reaktiviert wird, vor
der OCR explizit EXIF strippen (image-Lib's `bakeOrientation` +
re-encode reicht).

### [ ] Ungenutzte `logger`-Dependency

*Security-Runde 2026-05-05*

**Datei:** [pubspec.yaml:57](pubspec.yaml).

`logger: ^2.3.0` ist deklariert, aber kein einziger
`import 'package:logger/...'` im `lib/`. Ungenutzte Dependencies
vergrößern die Supply-Chain-Surface (transitive Updates, mögliche CVEs in
Sub-Deps) ohne Nutzen. Streichen oder einsetzen — derzeit weder noch.

### [ ] `BiometricCancelled` wird auch bei Auth-Failure zurückgegeben

*Security-Runde 2026-05-05*

**Datei:** [lib/data/services/biometric_service.dart](lib/data/services/biometric_service.dart),
`LocalAuthBiometricService.authenticate()` Zeilen 89–98.

`local_auth.authenticate(...)` liefert `false` sowohl bei Nutzer-Cancel
als auch bei Auth-Failure (z. B. dreimal falscher Finger ohne den
expliziten `lockedOut`-PlatformException-Code). Der Code mappt beides
pauschal auf `BiometricCancelled` — der Nutzer sieht „Vorgang
abgebrochen", obwohl die Biometrie-Erkennung fehlgeschlagen ist.

Aktuell eher UX als Security. Wird relevant, sobald irgendwann ein
Failure-Counter / Rate-Limit eingeführt wird (Audit-Reasoning würde dann
fehlerhaft auf „User hat abgebrochen" schließen statt „Auth schlug fehl").

**Fix:** zwischen Cancel und Failure ist mit `local_auth` allein nicht sauber
unterscheidbar; Workaround ist, den Aufrufer zwischen „Nutzer hat
explizit Reset gewählt" (Cancel) und „Re-Try" (Failure) entscheiden zu
lassen, oder den Status auf `BiometricFailure(code: 'unknown')` zu
mappen statt auf Cancel. Realistisch erst angehen, wenn ein konkreter
Use-Case dafür existiert.

### [ ] `.git/index.lock` (manuell)

0-Byte-Stale-Lock vom 2026-05-04 13:16, Windows-Layer hat sie gesperrt.
Manuell löschen:

```cmd
del /f D:\claudi\2026-05-03-bonbudget\.git\index.lock
```

Erst danach laufen `git restore`, `git stash`, `git rm --cached` wieder.

### [ ] `local.properties` und `.idea/` aus Git-Tracking

**Setzt `.git/index.lock`-Fix voraus.**

```bash
git rm --cached android/local.properties
git rm -r --cached .idea/
git commit -m "chore: stop tracking local IDE config"
```

### [ ] Mehr E2E-Tests im OCR-Pfad

Aktuelle E2E-Tests decken Setup, Reset, Budget-Überschreitung. Was
fehlt:

- Bon-Scan: Foto → OCR → Form vorausgefüllt (mit `FakeReceiptOcrService`-
  Override)
- Manuelle Erfassung mit Positionen + Pfand-Item
- Auto-Logout nach Inaktivität → Re-Unlock-Flow

Skeleton ist da (`integration_test/`), die zusätzlichen Tests sind
~30–60 Zeilen pro Szenario.

### [ ] `assets/`-Block in `pubspec.yaml`

Steht auskommentiert (`# assets: ...`). Wenn du Bilder/Icons aus dem
Repo nutzt, einkommentieren. Sonst Zeile löschen.

---

## Aufräumen — nach 2 Releases

Wenn die Legacy-Migration aus dem Argon2-Passwort-Modell sich gelegt
hat (Faustregel: 2 Minor-Releases nach Einführung), folgendes
entfernen:

- [ ] `lib/data/services/legacy_password_verifier.dart`
- [ ] `lib/presentation/screens/auth/legacy_migration_screen.dart`
- [ ] `AppRoutes.legacyMigration` und `/legacy-migration`-Route in `app_router.dart`
- [ ] `AuthStatus.needsLegacyMigration` und `migrateFromLegacy()` in `auth_state.dart`
- [ ] `legacyPasswordVerifierProvider` in `auth_providers.dart`
- [ ] `AppConstants.argon2*`, `secureKeyAuthHash`, `secureKeyAuthSalt`,
  `secureKeyBiometricEnabled`, `secureKeyFailedAttempts`,
  `secureKeyCooldownUntil`, `secureKeyLastPasswordLogin`
- [ ] `SecureStorageService.readAuthHash`, `readAuthSalt`, `deleteLegacyAuth`
- [ ] `pointycastle` Dependency in `pubspec.yaml`
- [ ] DB-Migration `_v3` darf bleiben (historische Korrektheit), kann aber
  vereinfacht werden falls gewünscht

Doku dazu: [docs/2026-05-04-biometrie-migration.md](docs/2026-05-04-biometrie-migration.md).

---

## Bewusst nicht gemacht

(Verschoben nach FEATURES.md → „Bewusst nicht geplant", weil das
Feature-Entscheidungen sind und kein Backlog.)
