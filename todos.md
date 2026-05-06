# BonBudget – Offene TODOs

Konsolidierte Aufgabenliste. Was bereits abgeschlossen ist (Biometrie-Umbau,
Code-/Security-Review-Runde 1, Pagination-UI-Migration, ML Kit OCR-Pfad
inkl. Tests, Lokalisierung), steht hier nicht mehr — siehe Git-Historie.

Features (Vorhanden, Geplant, Out-of-Scope) stehen separat in
[FEATURES.md](FEATURES.md). Diese Datei ist nur Bug-/Review-/
Aufräum-Backlog.

**Datum:** 2026-05-06 (übernommen aus 2026-05-04-open-review.md, +
Security-Review-Runde 2 vom 2026-05-05, + Code-Review-Runde 3 vom
2026-05-06: 4 Hoch, 6 Mittel, 6 Niedrig, eigene Sektion „Tests aufräumen")

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

### [ ] `SecureStorage.resetOnError: true` brickt DB bei einzelnem Lesefehler

*Code-Review 2026-05-06*

**Datei:** [lib/data/datasources/secure_storage_service.dart:14](lib/data/datasources/secure_storage_service.dart).

`AndroidOptions(resetOnError: true)` löscht bei einem einzelnen Lesefehler
(z. B. nach OS-Update, Restore, Keystore-Korruption) **alle** Keys inkl.
DB-Passphrase. Die SQLCipher-DB-Datei bleibt verschlüsselt, ist aber
ohne Passphrase nicht mehr zu öffnen → identischer Brick-Zustand wie
heute beim `resetAccount()`-Bug, nur ohne dass der Nutzer ihn ausgelöst
hat. Datenverlust > Sicherheitsgewinn.

**Fix:** `resetOnError: false` setzen, Lesefehler oben im Auth-Flow
abfangen und den Nutzer gezielt zum Account-Reset führen (mit klarer
Kommunikation, dass alle Daten weg sind), statt schweigend zu wipen.

### [ ] Default-Kategorien hardcoded deutsch — EN-User sehen permanent „Lebensmittel"

*Code-Review 2026-05-06*

**Datei:** [lib/data/repositories/category_repository_impl.dart:15-24](lib/data/repositories/category_repository_impl.dart).

`DefaultCategories.all` enthält fest verdrahtete deutsche Namen
(`'Lebensmittel'`, `'Drogerie'`, …), die beim ersten Start in die DB
geseedet werden. EN-User sehen permanent deutsche Kategorienamen. Der
Lookup `name.toLowerCase() == 'sonstiges'` in
[lib/presentation/screens/expense/expense_form_screen.dart:176](lib/presentation/screens/expense/expense_form_screen.dart)
würde nach einer kuenftigen Lokalisierung der Default-Namen brechen.

**Fix:** Stabiler `slug` (`groceries`, `drogerie`, `other`) als Spalte
in `categories`, Anzeige-Name aus `AppLocalizations` ableiten. Migration
v5 mappt bestehende deutsche Namen auf Slugs.

### [ ] Biometrie-Prompt-Texte und Auth-Fehler hardcoded deutsch

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/providers/auth_state.dart](lib/presentation/providers/auth_state.dart),
Zeilen 76, 107, 176, 224–235.

Der `localizedReason`-String, der an
`biometric.authenticate(...)` geht (`'BonBudget einrichten'`,
`'BonBudget entsperren'`, `'Auf Biometrie umstellen'`), wird vom OS
direkt im Biometrie-Dialog angezeigt — auch für EN-User. Gleiches gilt
für die Fehler-Strings (`'Vorgang abgebrochen.'`, `'Passwort falsch.'`,
`'Migration fehlgeschlagen.'`, `'Einrichtung fehlgeschlagen.'`).

**Fix:** Strings nicht im Notifier hardcoden; entweder vom Caller
(Widget mit Context) injizieren oder ARB-Keys via expliziten
Lookup-Hook (`l10n.authBiometricReasonSetup` etc.).

### [ ] BudgetScreen Controller nur einmal initialisiert — NPE bei nachträglichen Kategorien

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/screens/budget/budget_screen.dart:35-48](lib/presentation/screens/budget/budget_screen.dart).

`_initControllersIfNeeded` ist mit `_initialized`-Flag geschützt und
läuft genau einmal. Wenn der Nutzer auf einem zweiten Tab/Drawer eine
Kategorie hinzufügt und zurück zum Budget-Screen wechselt, fehlt für
die neue Kategorie ein Controller — der Lookup `_controllers[c.id]!`
in der Build-Phase wirft NPE.

**Fix:** Controller-Map bei jedem Build mit `cats` abgleichen — fehlende
anlegen, gelöschte disposen. `_initialized`-Flag entfernen.

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

### [ ] `selectedDateRangeLabelProvider` hat hardcodierte deutsche Monatsnamen

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/providers/expenses_state.dart:131-153](lib/presentation/providers/expenses_state.dart).

Der Provider liefert Strings wie `'Januar 2026'` mit fest verdrahtetem
Monats-Array (`'Januar', 'Februar', 'Maerz', …`), obwohl `stats_screen.dart`
schon `l10n.statsMonthJan…` benutzt. Das Label landet im Header der
Ausgabenliste — auch im EN-Build steht dort „Januar 2026".

**Fix:** Label-Berechnung in den Widget-Layer ziehen (Consumer mit
`AppLocalizations`) oder via Family-Provider mit Locale-Parameter.

### [ ] `AutoLogoutListener.onPointerMove` resettet Timer pro Touch-Frame

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/widgets/auto_logout_listener.dart:94-95](lib/presentation/widgets/auto_logout_listener.dart).

Sowohl `onPointerDown` **als auch** `onPointerMove` rufen `_resetTimer()`.
`onPointerMove` feuert pro Pointer-Event während Scrolling — bei
typischen 60 Hz heißt das: pro Sekunde Scrolling 60× Timer-Cancel/Recreate.
Ist nicht funktional kaputt, aber unnötiger Druck auf den Event-Loop.

**Fix:** nur `onPointerDown` (Touch-Start reicht für Inactivity-Reset),
oder zusätzlich Throttle (max. alle paar Sekunden ein Reset).

### [ ] `budgetByCategoryProvider` ohne `autoDispose`, lineares N×N-Lookup

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/providers/budgets_state.dart:36-43](lib/presentation/providers/budgets_state.dart).

`Provider.family` ohne `autoDispose` → für jede je angesehene Kategorie-ID
bleibt eine Provider-Instanz für die Session bestehen. Im Lookup läuft
ein linearer `for`-Loop durch alle Budgets pro Kategorie-Tile — auf
Dashboard und Stats ergibt das N×N pro Frame.

**Fix:** `Provider.family.autoDispose` und intern auf eine
`Map<String, Budget>` aus `budgetsProvider` setzen (Map einmal bauen,
dann O(1)-Lookup).

### [ ] `ExpenseRepositoryImpl._hydrateAll` macht N+1-Queries

*Code-Review 2026-05-06*

**Datei:** [lib/data/repositories/expense_repository_impl.dart:232-238](lib/data/repositories/expense_repository_impl.dart).

Für jede Expense in der Liste eine separate Query auf `expense_items`.
Bei der Listen-Page (50 Einträge) sind das 51 Round-Trips zur DB pro
Range-Wechsel.

**Fix:** ein einziges `WHERE expense_id IN (?,?,…)`, im Dart in eine
`Map<String, List<ExpenseItem>>` gruppieren und beim Hydrate die Map
abfragen.

### [ ] `receipt_scan_screen` liest `l10n` vor `await` — stale bei Sprachwechsel

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/screens/expense/receipt_scan_screen.dart:38](lib/presentation/screens/expense/receipt_scan_screen.dart).

`final l10n = AppLocalizations.of(context)!` wird vor allen `await`s
gelesen, aber Statustext (Zeile 68) und SnackBar (Zeile 113–118) laufen
nach async-Gaps. Sprachwechsel während des laufenden Scans würde stale
Strings zeigen.

**Fix:** l10n nach jedem Gap erneut aus dem Context holen
(`if (mounted) AppLocalizations.of(context)!`).

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

### [ ] `tesseract_receipt_ocr_service.dart` ist leerer Stub

*Code-Review 2026-05-06*

**Datei:** [lib/data/services/tesseract_receipt_ocr_service.dart](lib/data/services/tesseract_receipt_ocr_service.dart).

Datei enthält nur einen Kommentar — der Tesseract-Pfad wurde komplett
entfernt. Der Stub hält tote Bytes im Tree.

**Fix:** Datei löschen.

### [ ] `CurrencyFormatter.parseToCents` rundet still bei 3+ Nachkommastellen

*Code-Review 2026-05-06*

**Datei:** [lib/core/utils/currency_formatter.dart:31-38](lib/core/utils/currency_formatter.dart).

`parseToCents('1,234')` ergibt `123` Cent statt einen Validierungsfehler.
Bei OCR-Output / Form-Input führt das zu unbemerkter Präzisionsreduktion.

**Fix:** explizit ablehnen, wenn nach dem Komma mehr als zwei Stellen
kommen — `null` zurückgeben oder eigene `FormatException`.

### [ ] `DateRange.days` ist float-basiert, kann über DST-Wechsel um einen Tag drüber/drunter landen

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/providers/expenses_state.dart:84-87](lib/presentation/providers/expenses_state.dart).

`(diffMs / Duration.millisecondsPerDay).round()` ist Float-Arithmetik
und kann über DST-Wechsel um einen Tag verfehlen. Relevant für
`dailyAverageCentsProvider` (Tagesdurchschnitt-Anzeige).

**Fix:** `r.toExclusive.difference(r.from).inDays` direkt verwenden —
ist `int` und DST-stabil.

### [ ] `'€'` mehrfach hardcodiert in `expense_form_screen.dart`

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/screens/expense/expense_form_screen.dart](lib/presentation/screens/expense/expense_form_screen.dart),
Zeilen 402, 681.

Euro-Symbol als String-Literal in mehreren Field-Suffixen. Inkonsistent
mit `CurrencyFormatter`/`AppConstants.defaultCurrencyCode`. Dürfte
keinen funktionalen Effekt haben, ist aber ein Footgun für eine
spätere Multi-Currency-Erweiterung.

**Fix:** gemeinsame Konstante (`AppConstants.defaultCurrencySymbol`)
einführen und überall referenzieren.

### [ ] a11y: kein `Semantics` um den Restbudget-Ring

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/screens/home/dashboard_screen.dart](lib/presentation/screens/home/dashboard_screen.dart),
`_BudgetRingCard` ab Zeile 234.

Screenreader liest „60%" ohne Kontext. Sehende User sehen den Ring,
blinde User hören nur eine nackte Prozentzahl.

**Fix:** `Semantics(label: l10n.dashboardBudgetUsageLabel,
value: l10n.dashboardPercentSpoken(...))` um den Ring legen.

### [ ] `_ListFooter` enthält toten If-Branch

*Code-Review 2026-05-06*

**Datei:** [lib/presentation/screens/expense/expenses_list_screen.dart:289-296](lib/presentation/screens/expense/expenses_list_screen.dart).

Der `loadingMore`-Branch rendert sinnvoll einen Spinner. Der
zweite If-Branch (`!hasMore && shownCount > 0 && totalCount > shownCount`)
ist defensiv markiert mit „Sollte mit hasMore=false eigentlich nicht
eintreten" und gibt dann `SizedBox.shrink()` zurück — identisch zum
unbedingten Fallback darunter. Toter Code.

**Fix:** den toten If-Branch ersatzlos streichen.

---

## Tests aufräumen

*Code-Review 2026-05-06 — der Test-Suite ist mit 2 767 Zeilen für 11 057
Lib-Zeilen (~25 % Verhältnis) auf einem gesunden Maß, aber es gibt
konkrete Stellen mit Duplikaten oder Trivialität.*

### [ ] `receipt_parser_e2e_test.dart` ist fast vollständig redundant

**Datei:** [test/unit/data/services/receipt_parser_e2e_test.dart](test/unit/data/services/receipt_parser_e2e_test.dart)
(108 Zeilen).

Alle Szenarien existieren bereits in `receipt_parser_test.dart` mit
strikteren Assertions:

- „Rewe-Layout mit Mengen-Items, Pfand und Total" doppelt zu Mengen-/
  Pfand-Tests in der großen Datei.
- „Edeka-Layout mit kg-Mengen" doppelt zu „kg-Mengenzeile mit
  Dezimal-Menge".
- „Bon ohne Total" und „Komplett leerer Input" decken
  `receipt_parser_test.dart` ebenfalls ab.

**Genuin neu:**

- `'Datum 31.02.2026 ungueltig'` (impossible-date-Validierung).
- `'9999,99 EUR-Item wird verworfen'` (Plausibilitäts-Cap).

**Fix:** die zwei neuen Cases in `receipt_parser_test.dart` mergen,
dann die e2e-Datei löschen.

### [ ] `app_theme_test.dart` testet hauptsächlich Konstanten

**Datei:** [test/unit/core/theme/app_theme_test.dart](test/unit/core/theme/app_theme_test.dart)
(35 Zeilen).

Drei der vier Tests prüfen nur Compile-Time-Konstanten
(`useMaterial3 == true`, `brightness == light/dark`, drei Status-Farben
sind ungleich). Einzig `Chart-Palette length >= 5` hat Wert (verhindert,
dass jemand die Palette versehentlich leert).

**Fix:** Datei auf den Chart-Palette-Test reduzieren oder ganz löschen.

### [ ] `app_widget_test.dart` Material-3-Assertion doppelt zu `app_theme_test.dart`

**Datei:** [test/widget/app_widget_test.dart](test/widget/app_widget_test.dart)
(29 Zeilen).

Eine der beiden Test-Assertions (`expect(theme.useMaterial3, isTrue)`)
ist auch in `app_theme_test.dart`.

**Fix:** Material-3-Assertion in `app_widget_test.dart` streichen, der
Smoke-Test (Splash sichtbar) reicht. `app_theme_test.dart` darf bleiben
oder wird mit obigem Punkt ohnehin reduziert.

### [ ] `migrations_test.dart` „Foreign Keys sind aktiv" ist redundant

**Datei:** [test/unit/data/datasources/database/migrations_test.dart](test/unit/data/datasources/database/migrations_test.dart).

Der Test prüft ein einzelnes `PRAGMA foreign_keys` — der separate
Cascade-Delete-Test in derselben Datei würde fehlschlagen, wenn FKs
aus wären. Der Pragma-Test ist Doppel-Sicherung.

**Fix:** Pragma-Test streichen.

### [ ] `expenses_state_test.dart` re-testet Repository-Layer

**Datei:** [test/unit/presentation/providers/expenses_state_test.dart](test/unit/presentation/providers/expenses_state_test.dart)
(247 Zeilen).

Weil die Provider-Tests den realen `ExpenseRepositoryImpl` benutzen,
exercieren sie effektiv Repo-Verhalten (CRUD, Range-Filter, Pagination)
ein zweites Mal. Provider-Eigenschaft, die nur hier sinnvoll testbar ist:
**Versions-Counter inkrementiert** und **`selectedDateRangeProvider`
propagiert**.

**Fix:** Datei auf provider-spezifische Assertions trimmen
(geschätzt ~120 Zeilen statt 247).

### [ ] `receipt_parser_test.dart` (583 Zeilen) sollte parametrisiert werden

**Datei:** [test/unit/data/services/receipt_parser_test.dart](test/unit/data/services/receipt_parser_test.dart).

Mehrere Test-Gruppen mit nahezu identischen Cases:

- **Mengen-Zeile-Varianten** (Zeilen 107, 255, 275, 290, 334, 351, 487):
  alle prüfen „qty + unit + total derivation across line-break shapes".
- **Pfand-Varianten** (Zeilen 363, 378, 390, 403, 446, 569): sechs Tests
  mit gleichem Schema.
- **Datum-Format-Varianten** (Zeilen 13, 25, 219).
- **Total-Keyword-Varianten** (Zeilen 56, 66, 182, 206 — `Summe`,
  `Gesamt`, `Total`, `Zu zahlen`).

**Fix:** als parametrisierte Tabellen-Tests umstellen (Datentabelle +
einzelne `test`-Funktion). Realistische Reduktion auf ~250 Zeilen ohne
Coverage-Verlust.

### [ ] Coverage-Lücke: `auth_repository_test.dart` deckt DB-Datei-Löschung im `resetAccount` nicht ab

**Datei:** [test/unit/data/repositories/auth_repository_test.dart](test/unit/data/repositories/auth_repository_test.dart).

Der jüngste Commit `b6281ff fix(auth): resetAccount loescht DB-Datei
statt nur Tabellen` etabliert File-Deletion als Vertrag. Der Test
injiziert aber einen Resolver, der `null` liefert — der File-Deletion-
Pfad wird also nie betreten.

**Fix:** Test mit echtem Temp-File-DB ergänzen, der nach `resetAccount()`
prüft, dass die Datei weg ist.

### [ ] Coverage-Lücke: kein Migrations-Test für `v4 → latest`

**Datei:** [test/unit/data/datasources/database/migrations_test.dart](test/unit/data/datasources/database/migrations_test.dart).

Getestet werden v1, v2, v3 als Start-Versionen. Wenn `latestVersion > 4`
wird, ist der v4→latest-Pfad ungetestet. Klein, aber leicht zu vergessen.

**Fix:** `v4→latest`-Pfad-Test ergänzen, sobald nächste Migration kommt.

### [ ] Coverage-Lücke: kein EXIF-Orientation-Test im Image-Preprocessor

**Datei:** [test/unit/data/services/image_preprocessor_test.dart](test/unit/data/services/image_preprocessor_test.dart).

Kamera-Fotos kommen oft mit EXIF-Orientation-Tag (Portrait wird
landscape gespeichert + Tag „rotate 90°"). Wenn der Preprocessor das
nicht beachtet, ist der OCR-Input verdreht.

**Fix:** Test mit Fixture-Bild + EXIF-Tag, der prüft, dass das Output
visuell aufrecht steht.

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
