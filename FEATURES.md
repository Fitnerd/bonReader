# BonBudget – Feature-Liste

Lebende Liste aller Features: was bereits drin ist, was geplant ist, was
ausdrücklich nicht kommt. Aufgaben/Bugs/Reviews stehen in [todos.md](todos.md),
nicht hier.

**Datum:** 2026-05-06
**Aktuelle Version:** 1.0.0+1
**Plattformen:** Android, iOS

---

## Geplant

### 1. Optionaler Cloud-OCR-Dienst (Opt-in)

**Status:** Konzeption
**Priorität:** Hoch
**Plattformen:** Android, iOS

Heute läuft die OCR ausschließlich on-device über Google ML Kit
(`MlKitReceiptOcrService` in
[lib/data/services/receipt_ocr_service.dart](lib/data/services/receipt_ocr_service.dart)).
Das ist privacy-first, hat aber bei dichten oder schlecht beleuchteten Bons
Erkennungsschwächen. Als Alternative soll ein **zweiter, cloud-basierter
OCR-Dienst** integriert werden — der Nutzer entscheidet aktiv, ob er ihn
einsetzt.

**Anforderungen:**

- **Opt-in, nicht opt-out.** Default bleibt on-device. Cloud-OCR muss in den
  Einstellungen ausdrücklich aktiviert werden.
- **Pro-Scan-Bestätigung optional.** Settings-Schalter „Vor jedem Scan
  fragen" zusätzlich zur globalen Aktivierung. Default: an.
- **Transparenz:** Settings-Screen zeigt klar, *welcher* Anbieter genutzt
  wird, *was* gesendet wird (Bildbytes), und *welche Datenschutzlage* gilt
  (Verlinkung auf Anbieter-Policy).
- **Architektur:** Bestehendes `ReceiptOcrService`-Interface beibehalten,
  zweite Implementierung `CloudReceiptOcrService`. Auswahl per Riverpod-
  Provider, der die Setting liest und entsprechend den Dienst injiziert.
- **Failure-Handling:** Bei Cloud-Fehler (Offline, 5xx, Timeout) automatisch
  auf on-device zurückfallen — mit Hinweis im UI, damit der Nutzer weiß,
  dass diesmal lokal gescannt wurde.
- **API-Key-Speicherung:** falls der Anbieter einen User-Key braucht, im
  `flutter_secure_storage` analog zur DB-Passphrase. Kein Hardcoding.
- **Telemetrie weiterhin null.** Auch der Cloud-Pfad sendet ausschließlich
  das Bon-Foto an den OCR-Anbieter — keine Geräte-IDs, keine Analytics.
- **Bild nach Auswertung weg.** Wie heute auch.

**Offene Entscheidungen (zu klären in eigener Brainstorming-Session):**

- Anbieter (Google Cloud Vision? Azure? AWS Textract? Selbst gehostetes
  Tesseract über VPS?) — abhängig von Kosten, Datenschutz-Footprint, und
  ob der Anbieter Daten zu Trainingszwecken verwendet.
- Bezahlmodell: User-eigener API-Key vs. App-eigenes Konto + Limits.
- Region-Pinning (EU-Region erzwingen, wo möglich).

**Out-of-Scope für v1 dieses Features:**

- Server-seitiges Caching/Speichern von Bons.
- Hybrid-OCR (gleichzeitig beide Dienste, dann Mergen).

---

## Vorhanden (Stand 1.0.0)

### Sicherheit & Privatsphäre

- **SQLCipher-verschlüsselte Datenbank** (AES-256, on-device).
  256-Bit-Passphrase aus `Random.secure()`, nicht aus User-Input abgeleitet.
- **Biometrie-Only-Login.** Fingerprint / Face ID / Geräte-PIN als
  alleiniger Auth-Factor. Kein App-Passwort, kein Recovery.
- **Hardware-gestützter Secure Storage** (Android Keystore / iOS Keychain)
  für die DB-Passphrase.
- **FLAG_SECURE auf Android** — App-Switcher-Snapshot und Screenshots
  geblockt. *(iOS-Pendant noch offen, siehe todos.md → Hoch.)*
- **Auto-Logout.** Konfigurierbar 1–30 Min Inaktivität *(Sub-Screens
  decken den Timer noch nicht zurück, siehe todos.md → Mittel)* und sofort
  beim Backgrounding.
- **Account-Reset.** Komplett-Wipe direkt in der App. *(Bug bei DB-Datei,
  siehe todos.md → Hoch.)*
- **Constant-Time-Vergleich** an Auth-relevanten Stellen.
- **Cool-down nach 5 Fehlversuchen.** *(Legacy-Pfad — steht zum Aufräumen
  nach 2 Releases; siehe todos.md → Aufräumen.)*
- **Keine Cloud, keine Telemetrie.** Alles bleibt lokal.

### Erfassung

- **Bon scannen via Foto** (Kamera oder Galerie).
- **On-device OCR** mit Google ML Kit Text Recognition (Latin-Script).
- **Bildvorverarbeitung** vor OCR: Graustufen, Auto-Kontrast, Schärfen
  (pure Dart, keine native Lib).
- **Heuristischer Bon-Parser** (DE-only): erkennt Händler, Datum, Total,
  Einzelpositionen, Pfand-Items.
- **Manuelle Erfassung** mit beliebig vielen Positionen pro Bon.
- **Pfand-Erkennung & getrennte Position.**
- **Foto wird nach OCR sofort gelöscht** (Tempdir-Cleanup im finally —
  Crash-Pfad noch offen, siehe todos.md → Niedrig).

### Budget & Kategorien

- **Kategorien-Verwaltung** mit Vordefinierten + eigenen Kategorien.
- **Default-Kategorien können einzeln versteckt werden** (statt gelöscht,
  damit Migrationspfad sauber bleibt).
- **Kategorie-Klassifizierer** schlägt Kategorie aufgrund von
  Item-Bezeichnungen vor.
- **Budgets pro Kategorie** als monatliches Limit.
- **Gesamtbudget = Summe der Kategorie-Budgets** (kein separates Top-Level-
  Budget).

### Auswertung

- **Dashboard** mit Restbudget-Ring, Auslastung pro Kategorie, letzte
  Ausgaben.
- **Statistik-Screen:**
  - 12-Monats-Trend (Säulendiagramm)
  - Top-Kategorien als Donut
  - Monatsvergleich (Periode-zu-Periode)
- **Tagesdurchschnitt** in der Auswertung.

### App-Infrastruktur

- **Flutter 3.22+, Dart 3.4+**, Clean Architecture (presentation/domain/
  data).
- **Riverpod** für State-Management.
- **go_router** für Navigation mit Auth-basiertem Redirect.
- **Lokalisierung** DE/EN (ARB-Keys, Plurale via ICU).
- **Material 3** mit Mint-Grün-Theme.
- **Pagination** für Ausgabenliste (Page-Size 50, `loadMore()`-Trigger via
  `ScrollController`).
- **Aggregat-Provider** lesen direkt aus Repo-Aggregaten (kein In-Memory-
  Sum), sodass auch große Datenmengen flüssig bleiben.

### Persistenz

- **SQLCipher-DB** mit Migrations-Pfad v1→v4.
- **Geld als `int` in Cent**, Mengen als `int` in Tausendstel
  (`quantityMilli`).

### Build & Release

- **Code-Obfuscation + Split-Debug-Info** im Release-Build.
- **ProGuard-Regeln** für ML Kit + Riverpod.
- **CI-Workflow** (GitHub Actions) für `flutter analyze` + `flutter test`.
- **iOS-Plattform-Setup** mit Camera/Photo/Face-ID-Permissions.

### Tests

- Repository-Layer (Auth, Budget, Category, Expense) gegen In-Memory-
  SQLite.
- Migrations-Tests v1→v3, v2→v3, v3→v4.
- Provider-Tests (Riverpod AsyncNotifier, Aggregations-Provider,
  Pagination).
- Service-Tests (Receipt-Parser inkl. End-to-End-Bon-Tests, Image-
  Preprocessor, Category-Classifier).
- Widget-Tests für Auth-Screens.
- E2E-Tests (Setup, Reset, Setup-Cancel, Budget-Überschreitung).
- SQLCipher-Encryption-Test (on-device).

---

## Geplant (weitere)

### 2. iOS-App-Switcher-Schutz (FLAG_SECURE-Pendant)

**Status:** Bekannt, in todos.md → Hoch
**Hintergrund:** Auf iOS legt das System beim Hintergrund-Wechsel ein
Snapshot der App im Cache ab. Mit aktuell sichtbaren Beträgen, Bons,
Budgets — sichtbar im App-Switcher und potenziell in iCloud-Backups.

Fix: in `SceneDelegate.swift` ein blickdichtes Overlay einblenden.

### 3. Echtes Biometrie-Binding der DB-Passphrase

**Status:** Konzeption, in todos.md → Mittel
**Hintergrund:** Die DB-Passphrase liegt heute hardware-backed im
Keystore/Keychain, ist aber **nicht** an User-Authentication gebunden.
Nach Boot + Unlock kann sie ohne Biometrie-Prompt gelesen werden — bei
Root/Jailbreak extrahierbar.

Lösung: Native Method-Channel oder Wechsel auf `biometric_storage`. Der
Trade-off (Komfort vs. Schutz vor physischem Angreifer) muss bewusst
gewählt werden.

### 4. Auto-Logout deckt alle Screens ab

**Status:** Bekannt, in todos.md → Mittel
**Hintergrund:** Heute wraps `AutoLogoutListener` nur den Dashboard-
Screen. Wer 5+ Min Ausgaben einträgt oder Statistiken durchscrollt, wird
mitten in der Aktion ausgeloggt, weil Touch-Events auf Sub-Screens den
Timer nicht zurücksetzen.

Lösung: NavigatorObserver, der bei jedem Push/Pop einen zentralen
`AutoLogoutController` zurücksetzt.

### 5. Mehr Widget-Tests

**Status:** Backlog, in todos.md → Mittel
Settings (Reset-Account-Flow) und Budget (Speichern, Validation) sind
fachlich kritisch und verdienen je 1–2 Widget-Tests.

### 6. Mehr E2E-Tests im OCR-Pfad

**Status:** Backlog, in todos.md → Niedrig
Aktuelle E2E-Tests decken Setup/Reset/Budget. Zu ergänzen:

- Bon-Scan: Foto → OCR → Form vorausgefüllt
  (mit `FakeReceiptOcrService`-Override)
- Manuelle Erfassung mit Positionen + Pfand
- Auto-Logout → Re-Unlock-Flow

### 7. App-Icon + nativer Splash-Screen

**Status:** Pre-Release-Pflicht, in docs/2026-05-03-todo.md
Mit `flutter_launcher_icons` und `flutter_native_splash` generieren.

---

## Bewusst nicht geplant

- **Mehrere Konten / Multi-User in einer App-Instanz.** Eine App = ein
  Haushalts-Konto.
- **Cloud-Sync zwischen Geräten.** Würde dem Privacy-First-Anspruch
  widersprechen. Das Cloud-OCR-Opt-in (Geplant #1) ist explizit *nur* für
  den OCR-Schritt — keine Datensynchronisation.
- **Account-Recovery / Passwort-Reset.** Bewusste Trade-off-Entscheidung:
  bei Geräteverlust sind die Daten weg. Recovery-Mechanismen würden
  Schlüsselableitung außerhalb des Geräts bedeuten.
- **Receipt-Parser für andere Locales als DE.** Out-of-Scope.
- **`expense_form_screen.dart` setState→Riverpod-Refactor.** Die
  Controller-Lifecycles brauchen `State`. Refactor brächte Komplexität
  ohne Wartbarkeitsgewinn.
- **`ExpenseItem.quantity` als `int` (Stück).** kg-Ware mit Kommawerten
  funktioniert nicht. `quantityMilli` mit Faktor 1000 ist der Mittelweg.
- **Vollständige a11y-Label-Audit jeder `IconButton`/`Icon`-Verwendung.**
  Kritische Stellen sind versorgt. Vollständige Audit ist eigene Arbeit.
