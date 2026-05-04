# BonBudget – Projekt-Review & Todo-Liste

**Datum:** 2026-05-04  
**Scope:** Vollständiges Code-Review über Domain/Data-Layer, Presentation-Layer und Tests/Konfiguration

---

## Kritisch (vor Release beheben)

- [ ] **Unsichere `!`-Operatoren in ExpenseRepositoryImpl** – `getById()` nach `create()`/`update()` gibt möglicherweise `null` zurück → Runtime-Crash. Zeilen 104–105, 140–141 in `expense_repository_impl.dart`. Explizite Fehlerbehandlung statt `!` verwenden.

- [ ] **Unsichere `!`-Casts in allen `_fromRow()`-Methoden** – `row[...]! as Type` Pattern in `auth_repository_impl.dart`, `budget_repository_impl.dart`, `category_repository_impl.dart`, `expense_repository_impl.dart`. Datenbank-Korruption oder unerwartete Null-Werte → App-Crash. Defensiver mit `as Type?` und Validierung arbeiten.

- [ ] **Race Condition in `DatabasePassphraseService.getOrCreate()`** – Nicht-atomare Read-Then-Write-Sequenz (Zeile 30–37). Zwei parallele Aufrufe erzeugen zwei verschiedene Passphrases → DB nicht mehr lesbar. Mutex/Lock einbauen.

- [ ] **Fehlende Transaktion in `AuthRepositoryImpl.resetAccount()`** – 5 sequenzielle `DELETE`-Statements ohne `transaction()` (Zeilen 159–165). App-Crash zwischendrin → inkonsistenter Zustand. In Transaction wrappen.

- [ ] **Exception-Handling in BiometricService zu breit** – `catch (Object)` verschluckt alle Fehler pauschal (Zeilen 29, 47 in `biometric_service.dart`). Spezifischere Exceptions fangen und loggen.

- [ ] **OCR-Fehlerbehandlung im ReceiptScanScreen undifferenziert** – Generischer catch-Block unterscheidet nicht zwischen User-Abbruch, OCR-Fehler und Dateifehler (Zeile 125–135). Benutzer sieht "Bon konnte nicht gelesen werden" auch bei normalem Abbruch.

- [ ] **Fehlende Validierung für Währungs-Parsing im ExpenseFormScreen** – `CurrencyFormatter.parseToCents()` kann `null` zurückgeben, aber der Validator fängt das nicht ab (Zeile 401–413 in `expense_form_screen.dart`).

- [ ] **Keine OCR-Integrationstests vorhanden** – Kritischer Pfad (Foto → OCR → Parsing) ist nicht End-to-End getestet. Testbilder mit ML Kit Mocks einführen.

- [ ] **Keine Tests für SQLCipher-Verschlüsselung** – Privacy-First-Anspruch, aber Verschlüsselung wird nicht validiert. Integrationstests für Encryption-Workflow hinzufügen.

- [ ] **Brute-Force-Schutz nicht getestet** – `FakeSecureStorageService` hat Cooldown-Logik, aber kein Unit-Test prüft, ob nach 5 Fehlversuchen tatsächlich blockiert wird.

---

## Wichtig (zeitnah beheben)

- [ ] **`setState()` und Riverpod gemischt** – Mehrere Screens (`login_screen.dart`, `register_screen.dart`, `budget_screen.dart`, `expense_form_screen.dart`) verwenden lokales `setState()` neben Riverpod. Anti-Pattern refactoren → NotifierProvider verwenden.

- [ ] **Fehlende Accessibility-Labels** – Icons, `CircularProgressIndicator`, `LinearProgressIndicator` und `IconButton` ohne `semanticLabel`. Screen-Reader können die App nicht bedienen.

- [ ] **Hardcodierte deutsche Strings** – 500+ Strings nicht lokalisierbar. `flutter_localizations` ist in pubspec, wird aber nicht genutzt. L10n-Dateien einrichten oder zumindest Strings extrahieren.

- [ ] **Unbegrenzte ListView ohne Pagination** – `expensesInSelectedRangeProvider` lädt alle Ausgaben in Memory. Bei >10.000 Einträgen Performance-Problem. Pagination implementieren.

- [ ] **Memory-Leak-Risiko in AutoLogoutListener** – Timer kann feuern während Widget disposed wird (Zeile 61–68). Timer vor Logout-Aufruf canceln.

- [ ] **ReceiptParser: Stille Fehler bei Datumserkennung und Preisparser** – `catch (_) { continue; }` (Zeile 159–172) und potenzielle Fehler bei `"1.234,56"` Format (Zeile 345–353). Logging einbauen.

- [ ] **ImagePreprocessor: Stille Exception-Behandlung** – `catch (_) { image = null; }` (Zeile 44–48). Fehler loggen, nicht verschlucken.

- [ ] **Keine Input-Validierung in `CategoryRepository.create()`** – Name wird nur getrimmt, keine Längen- oder Leerprüfung (Zeile 85–101). Validierung in Domain oder Repository.

- [ ] **DB-Version nicht gegen Migrations-Anzahl validiert** – `AppConstants.databaseVersion` und `Migrations.latestVersion` können divergieren. Assertion hinzufügen.

- [ ] **Inkonsistente Fehlerdarstellung** – Manche Screens zeigen `Text('Fehler: $e')`, andere SnackBars. Einheitliche Fehler-UI definieren.

- [ ] **Fehlende Bestätigungs-Dialoge** – Budget-Screen speichert alle Werte ohne "Bist du sicher?"-Prompt. Versehentlicher Datenverlust möglich.

- [ ] **Race Condition bei Passwortänderung** – `settings_screen.dart` Zeile 289–305: paralleler State-Update möglich.

- [ ] **Riverpod-Provider Error-Handling nicht getestet** – Kein Test prüft, was passiert wenn die DB einen Fehler wirft.

- [ ] **Database-Migrations-Tests zu simpel** – Nur v1-Schema getestet. Keine Upgrade-Path-Tests (v1→v2→v3).

- [ ] **Nur 1 E2E-Test vorhanden** – Integration-Test deckt nur Happy-Path ab. Mindestens 5–8 weitere Szenarien (Auth-Fehler, Budget-Überschreitung, Offline).

---

## Minor (bei Gelegenheit)

- [ ] **Duplikat in CategoryClassifier** – `'BROETCHEN'` doppelt in Pattern-Liste (Zeile 32).
- [ ] **`UserAuth` fehlt `@immutable`-Annotation** – Alle anderen Entities haben sie.
- [ ] **`ExpenseDraft`/`ExpenseItemDraft` sollten `@immutable` sein** – Oder als DTOs ins Data-Layer verschieben.
- [ ] **Magic Numbers** – `0.85` Budget-Schwelle (dashboard), `100000` Cent-Limit (receipt_parser) → als `AppConstants` definieren.
- [ ] **`ExpenseItem.quantity` ist `double`** – IEEE 754 Rundungsfehler möglich. Cent-basierte Lösung erwägen.
- [ ] **Redundante Assertion in `expenses_state.dart`** – Zeile 53: `assert(from != toExclusive || from == toExclusive)` ist immer true → sinnlos.
- [ ] **`home_placeholder_screen.dart` nutzt deprected Provider** – `totalSpentInSelectedMonthProvider` → `totalSpentInSelectedRangeProvider`.
- [ ] **Lineare Suche statt Map-Lookup in `_findCat()`** – `dashboard_screen.dart` Zeile 166–171: O(n) statt O(1).
- [ ] **Inline-Datumsformatierung statt zentralem Formatter** – `.padLeft(2, '0')` Pattern in mehreren Screens dupliziert.
- [ ] **`.gitignore`: `gradlew`/`gradlew.bat` sollten NICHT ignoriert werden** – Gehören ins Repository (Zeile 42–43).
- [ ] **`.gitignore`: Duplikat** – `app.*.map.json` steht doppelt (Zeile 19 und 22).
- [ ] **`analysis_options.yaml`: `todo: ignore`** – Sicherheitskritische TODOs könnten übersehen werden → `todo: warning`.
- [ ] **`DROP TABLE` ohne `IF EXISTS` in Migrations** – Zeile 153 in `migrations.dart`.
- [ ] **Release-Build ohne Signatur-Validierung** – `build.gradle.kts` Zeile 59–61: Silent-Fail wenn `key.properties` fehlt.
- [ ] **Widget-Tests zu minimal** – Nur 2 Tests in `app_widget_test.dart`. Navigation, Theme-Switch, Auth-Flows nicht abgedeckt.
- [ ] **`pubspec.yaml`: Assets-Eintrag auskommentiert** – Prüfen ob Assets existieren und einkommentieren.
- [ ] **Biometrie-Verfügbarkeit wird nicht regelmäßig geprüft** – Einmalig beim Start → nach OS-Update veraltet.

---

## Positives

- Solide Clean-Architecture-Struktur (Domain/Data/Presentation)
- Gute kryptographische Praxis (Argon2id, SQLCipher, SecureStorage)
- Privacy-First: OCR-Bilder werden nach Verarbeitung gelöscht
- Gute Unit-Test-Abdeckung für Business-Logik (Parser, Formatter, Repositories)
- Material 3 Theme sauber implementiert
- Robustes Auto-Logout mit Background-Suppression
- TextEditingController werden vor dispose() sicher gelöscht
