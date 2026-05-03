# Agent-Memory: BonBudget

> Schnellstart fuer einen KI-Agenten, der dieses Projekt uebernimmt.
> Stand: 2026-05-03, nach Schritt 6.

## Was ist BonBudget?

Lokaler, privacy-first Bon- und Budget-Tracker (Flutter, Android + iOS).
Nutzer fotografiert einen Kassenbon, OCR erkennt Positionen, Ausgaben werden
einer Kategorie zugeordnet, jede Kategorie hat ein Monatsbudget. Das
Gesamtbudget = Summe der Kategorie-Budgets.

Alles bleibt lokal: AES-256 verschluesselte SQLCipher-DB, Argon2id-Passwort,
optional Biometrie. Keine Cloud, kein Telemetrie, kein Bild-Upload. Foto wird
direkt nach OCR-Auswertung geloescht.

## Sprache & Stil

* **UI: Deutsch.** Alle sichtbaren Strings sind deutsch (z. B. "Ausgaben",
  "Budgets speichern", "Bon scannen").
* **Code-Kommentare: Deutsch**, sachlich, mit Begruendung wenn Trade-offs
  vorhanden ("warum so" > "was tut der Code").
* **Umlaute in Strings vorsichtig:** Bash-Heredocs in dieser Sandbox haben
  Probleme mit `ü/ä/ö/ß` → wir benutzen in vielen Strings `ue/ae/oe/ss`.
  Kein zwingendes Muster, aber beim Hinzufuegen neuer UI-Strings: lieber `ue`
  als `ü`, ausser im UI-prominenten Bereich.
* Identifikatoren auf Englisch (Klassen, Variablen, Methoden).

## Architektur (Clean Architecture)

```
presentation/  Riverpod-Provider + Flutter-Widgets
   providers/   AsyncNotifier-State pro Domaene
   screens/     Auth, Home, Categories, Budget, Expense
   widgets/     Reusable widgets (AutoLogoutListener)
domain/        Entities (immutable), Repository-Interfaces
data/          SQLCipher-Implementierungen, Services (Hash, OCR, Photo)
core/          Theme, Router, Provider-Registry, Utils, Constants
```

Details: `docs/2026-05-03-architecture.md`, `docs/2026-05-03-security.md`,
`docs/2026-05-03-testing.md`.

## Konventionen, an die der Agent sich halten muss

1. **Geld immer als `int` in Cent.** Niemals `double` fuer Betraege.
   Konvertierung in `CurrencyFormatter` (`lib/core/utils/`).
2. **IDs sind UUIDv4** als String (uuid Paket). Entities haben `==` und
   `hashCode` basierend nur auf `id`.
3. **DB-Zugriff laeuft IMMER ueber Repository-Interfaces** im `domain/`-Layer.
   Provider in `lib/core/providers/data_providers.dart` injizieren die
   konkrete Impl. Tests overriden den Provider mit einer In-Memory-Repo.
4. **State-Management: Riverpod (`flutter_riverpod` ^2.5.1).**
   Pro Domaene ein `AsyncNotifier`. Ableitungen (Filter, Summen) sind
   `Provider<T>` oder `Provider.family<T, X>`.
5. **Routing: `go_router` ^14.2.0** mit `refreshListenable`-Bridge zu
   AuthState. Auth-basierte Redirects in `lib/core/router/app_router.dart`.
6. **Tests laufen on-host:** SQLCipher wird durch `sqflite_common_ffi`
   ersetzt (`test/helpers/in_memory_database.dart`). Argon2 braucht native
   Bindings, deshalb gibt es `FakePasswordHasher` (`test/helpers/`) und der
   echte Hasher wird per Integration-Test auf dem Geraet validiert.
7. **Keine Magic Strings fuer DB:** `lib/data/datasources/database/schema.dart`
   hat typed Konstanten (`DbTables`, `ExpenseCols`, etc.).
8. **Themen: Mint Green Material 3.** Seed-Color `#14B8A6`, definiert in
   `lib/core/theme/app_colors.dart`. Bitte nicht aendern, ohne den User zu
   fragen.

## Was steht (Stand 2026-05-03)

### Schritt 1: Projekt-Setup
* pubspec.yaml mit allen Dependencies (Riverpod, SQLCipher, Argon2, ML Kit,
  fl_chart, image_picker, local_auth, go_router, intl ^0.20.2 *gepinnt von
  flutter_localizations*).
* Theming, Router (Auth-Redirects), Constants (Argon2-Parameter,
  AppName "BonBudget"), Currency-Formatter.

### Schritt 2: Datenmodell & verschluesselte DB
* Entities (User, Category, Budget, Expense, ExpenseItem) – immutable mit
  copyWith, ID-basierter `==`.
* Repository-Interfaces inkl. `ExpenseDraft` / `ExpenseItemDraft`.
* SQLCipher-DB mit Migrationen, FK-Cascade, Indexes, CHECK-Constraints.
* DB-Passphrase: 256-bit `Random.secure`, base64, im Secure Storage.
  Wird *nicht* aus dem User-Passwort abgeleitet → Passwortwechsel
  erfordert keine DB-Re-Encryption.
* Default-Kategorien (Lebensmittel, Drogerie, Restaurant, Tanken, Freizeit,
  Wohnen, Kleidung, Sonstiges) per `seedDefaultsIfNeeded()`.

### Schritt 3: Auth-System
* Argon2id (RFC 9106: t=3, m=64MB, p=4) via `dargon2_flutter`.
* Hash + Salt parallel in DB *und* Secure Storage (Defense in Depth).
* Constant-time Vergleich gegen Timing-Attacks.
* Cooldown nach 5 Fehlversuchen.
* Biometrie via `local_auth`, optional einschaltbar.
* Auto-Logout: nach 5 min Inaktivitaet *oder* App-Backgrounding
  (`AutoLogoutListener` widget).
* Register/Login Screens mit Hinweis "kein Passwort-Reset moeglich".

### Schritt 4: Kategorien & Budgets
* `CategoriesNotifier` + `visibleCategoriesProvider` (filtert versteckte).
* `BudgetsNotifier` + `totalBudgetCentsProvider` + `budgetByCategoryProvider`.
* `CategoriesScreen` (Liste, Edit, Loeschen mit Default-vs-Custom-Logik:
  Defaults werden nur ausgeblendet, Custom werden physisch geloescht,
  blockiert wenn noch Ausgaben dranhaengen).
* `CategoryEditScreen` mit kuratiertem Farb- und Icon-Picker
  (`category_picker_data.dart` – 8 Farben, 16 Icons, Theme-konform).
* `BudgetScreen` mit Live-Summen-Header und Eingabefeld pro Kategorie.

### Schritt 5: Manuelle Ausgabe-Erfassung
* `ExpensesNotifier` (CRUD).
* `selectedMonthProvider` + abgeleitete:
  `expensesInSelectedMonthProvider`, `totalSpentInSelectedMonthProvider`,
  `spentByCategoryInSelectedMonthProvider`.
* `ExpenseFormScreen`: Haendler, Datum, Kategorie, Notiz, Liste der
  Positionen mit Live-Summen-Header. Wenn Positionen erfasst sind, zaehlt
  deren Summe; sonst manuelles Gesamtfeld. Akzeptiert sowohl `existing`
  (Edit-Modus) als auch `prefill: ExpensePrefill?` (OCR-Vorbefuellung).
* `ExpensesListScreen`: Monatsfilter, Wischen-zum-Loeschen mit Bestaetigung,
  Tap → Edit, FAB fuer Neu, AppBar-Action fuer "Bon scannen".
* Home upgegraded: Restbudget-Karte, Logout-Button, Drawer + NavTiles.

### Schritt 6: OCR & Bon-Scan
* `ReceiptOcrService` Interface + `MlKitReceiptOcrService` mit
  `google_mlkit_text_recognition`. On-device, kein Netz.
* `PhotoCaptureService`: nimmt Foto mit `image_picker`, kopiert in
  App-eigenes Tmp, loescht Original aus Picker-Cache, hat eine
  `deleteSafe`-Methode.
* `ReceiptParser` (heuristisch, regelbasiert):
  * Datum: `DD.MM.YYYY` / `DD.MM.YY`
  * Total: Zeilen mit "Summe", "Gesamt", "Total", "Zu zahlen"
  * Items: Zeilen mit Preis am Ende, ignoriert "MwSt", "Rueckgeld",
    "Gegeben", "Bar", etc.
  * Mengenzeilen "2 X 1,99" werden zur Folgezeile gemappt.
  * Liefert `ParsedReceipt` mit `confidence` (0..1).
* `ReceiptScanScreen`: Camera/Gallery-Auswahl, OCR, Foto-Loeschung,
  Pre-Fill-Form. Bei niedriger confidence: SnackBar-Hinweis.

## Was offen ist

Siehe `docs/2026-05-03-todo.md`.

## Wichtige Fallstricke

1. **Sandbox-Tmp ist fluechtig:** `/tmp` wird beim Sandbox-Restart
   komplett geleert. Frueher lag das `.git` in `/tmp/bonbudget.git`,
   weil das Schreiben ins Windows-Mount `D:\claudi\...` Permission-Probleme
   hatte. **Aktuell** liegt das `.git` IN der Projekt-Root (manuell
   wiederhergestellt). Wenn das nicht funktioniert: `.git` in einen
   *persistenten* Pfad verschieben, der NICHT `/tmp` ist (z. B.
   `/sessions/friendly-amazing-goldberg/mnt/outputs/bonbudget.git`).
   Mit `--git-dir=...` arbeiten.
2. **Edit-Tool kann zu Sync-Drift fuehren:** Wenn das Edit-Tool eine
   Datei aendert, sieht `git status` die Aenderung manchmal NICHT, obwohl
   der Inhalt da ist. Workaround: `python3` oder `cat > ... << EOF`
   im Bash benutzen, oder `git add -f`. Vor jedem Commit: mit
   `wc -l <file>` plausibilisieren.
3. **intl pinned:** Flutter-SDK-Constraint setzt `intl: 0.20.2` ueber
   `flutter_localizations`. NICHT auf 0.19.x runtersetzen.
4. **Argon2 native:** Auf dem Host laesst sich `dargon2_flutter` nicht
   ohne Native-Bindings benutzen. Tests verwenden `FakePasswordHasher`.
   Nur Integration-Tests auf dem echten Geraet pruefen den realen Hasher.
5. **Flutter-Version:** Projekt wurde mit Flutter 3.41.9 angelegt.
   Lockfile: keine ‒ wir leben mit Caret-Constraints, akzeptieren das
   Risiko fuer Privatprojekt.

## So weitermachen

Wenn der naechste Agent uebernimmt, sollte er zuerst:

1. Diesen File lesen (du tust das ja schon).
2. `docs/2026-05-03-todo.md` lesen → naechste konkrete Aufgabe.
3. `git log --oneline` pruefen, um den genauen Commit-Stand zu sehen.
4. Niemals an `lib/data/datasources/database/migrations.dart` ohne
   neue Versionsnummer ruehren – Migrations sind one-way.
5. Bei Regex/Parser-Aenderungen: `test/unit/data/services/receipt_parser_test.dart`
   ausweiten, NICHT existierende Tests kuerzen.
