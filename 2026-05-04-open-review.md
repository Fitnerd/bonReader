# BonBudget – Offene Review-Punkte

**Datum:** 2026-05-04 (zuletzt aktualisiert: 2026-05-05)
**Stand:** Nach Biometrie-Umbau + Code-/Security-Review-Fixes + G1–G6 +
Pagination-UI-Migration.
Konsolidiert aus den drei alten Review-Files (Code-Review, Security-Review,
Biometrie-Todo) — die sind ersetzt durch dieses File.

---

## Kontext

Was bereits erledigt ist, steht hier *nicht* mehr. Konkret abgehakt sind:

- **Biometrie-Only-Umbau** komplett (Argon2-Passwort raus, Setup/Unlock/
  Legacy-Migration-Screens, DB-Migration v3, Tests).
- **Security-Review** (15 Punkte) bis auf zwei git-rm-Tasks erledigt.
- **Code-Review** (~50 Punkte) zum großen Teil erledigt:
  Race Conditions, Magic Numbers, Memory-Leak im AutoLogout, ProGuard,
  CI-Workflow, Accessibility-Labels (kritische Stellen), Bestätigungs-Dialoge,
  defensives `_fromRow` in Budget+Category, kaputte String-Interpolation,
  `BROETCHEN`-Duplikat, `_findCat` als Map-Lookup, irreführender
  `main.dart`-Kommentar, Assets-Indikator, `analysis_options` `todo: warning`.
- **Refactors:** `quantity` REAL → `quantityMilli` INTEGER (DB-Migration v4),
  `QuantityFormatter`, `DateFormatter`, `@immutable`+`const` auf Drafts.
- **Tests:** Migrations-Upgrade-Pfade v1→v3, v2→v3, v3→v4, Pagination-Tests,
  Widget-Tests Auth-Screens, E2E Reset/Setup-Cancel/Budget-Überschreitung,
  SQLCipher-Encryption-Test (on-device), `FakeBiometricService`,
  `FakeReceiptOcrService`, End-to-End-Bon-Parser-Tests.
- **Lokalisierung restliche Screens** (Dashboard, Home-Placeholder, Settings,
  Budget, Categories, Category-Edit, Expense-Form, Expenses-List, Receipt-Scan,
  Stats): hardcodierte Strings raus, ARB-Keys (de+en), Plurale via ICU,
  Umlaute in den neuen Strings korrekt.
- **Pagination-UI-Migration:** `expensesProvider` ist jetzt reiner
  Mutation-Notifier mit Versions-Counter, neuer `PagedExpensesNotifier`
  (Page-Size 50, `loadMore()`) treibt die Listen-Screen mit
  `ScrollController`-Trigger. Alle Aggregat-Provider (`totalSpent`,
  `spentByCategory`, `topCategories`, `dailyAverage`, `monthlyTotals`,
  `periodOverPeriod`) lesen aus Repo-Aggregaten (`getTotalCents`,
  `getTotalsByCategory`) statt In-Memory-Listen. Dashboard, Stats,
  HomePlaceholder konsumieren via `valueOrNull` mit Defaults. Tests
  inkl. neuem `loadMore`-Pfad grün.

---

## Offen — Mittel

### Verbleibende Repo-`!`-Casts
**Datei:** `lib/data/repositories/expense_repository_impl.dart`, `_hydrateOne`
(Zeilen ~190–215).

Budget- und Category-Repo sind defensiv. Expense-Repo hat noch
`row[ExpenseCols.id]! as String`-Pattern. Bei DB-Korruption gibt's
NPE statt verständlichem Fehler. Selbes Pattern wie bei Budget/Category
anwenden.

### Widget-Tests für Settings/Budget/Categories
Auth-Screens haben Widget-Tests (`auth_screens_test.dart`). Settings
und Budget sind fachlich kritisch (Reset-Account, Budget-Speichern) und
verdienen je 1–2 Widget-Tests.

### Biometrie-Verfügbarkeit live prüfen
`SetupScreen._checkBiometrics()` läuft einmal beim Mount. Wenn der
Nutzer in den Geräte-Einstellungen Biometrie nachträglich aktiviert,
sieht der Setup-Screen das nicht. Fix: `WidgetsBindingObserver` mit
`didChangeAppLifecycleState` + Re-Check beim Resume.

### Release-Build-Signatur-Härtung
**Datei:** `android/app/build.gradle.kts`, Zeile ~59.

Der `signingConfigs`-Block hat ein Silent-Fail wenn `key.properties`
fehlt — Release-Build läuft dann mit Debug-Keys durch. Sicherer:
`throw GradleException("key.properties fehlt")` statt stiller Fallback.

### `gradlew` / `gradlew.bat` in `.gitignore`
Beide sind ignoriert (Zeilen 42–43). Die Wrapper *gehören* eigentlich
ins Repo, damit jeder ohne lokale Gradle-Installation bauen kann.
Strittig, weil Standard-Flutter-Gitignore es so macht — Entscheidung
liegt beim Maintainer.

---

## Offen — Niedrig

### `.git/index.lock` (manuell)
0-Byte-Stale-Lock vom 2026-05-04 13:16, Windows-Layer hat sie gesperrt.
Manuell löschen:

```cmd
del /f D:\claudi\2026-05-03-bonbudget\.git\index.lock
```

Erst danach laufen `git restore`, `git stash`, `git rm --cached` wieder.

### `local.properties` und `.idea/` aus Git-Tracking
**Setzt `.git/index.lock`-Fix voraus.**

```bash
git rm --cached android/local.properties
git rm -r --cached .idea/
git commit -m "chore: stop tracking local IDE config"
```

### Mehr E2E-Tests im OCR-Pfad
Aktuelle E2E-Tests decken Setup, Reset, Budget-Überschreitung. Was
fehlt:

- Bon-Scan: Foto → OCR → Form vorausgefüllt (mit `FakeReceiptOcrService`-
  Override)
- Manuelle Erfassung mit Positionen + Pfand-Item
- Auto-Logout nach Inaktivität → Re-Unlock-Flow

Skeleton ist da (`integration_test/`), die zusätzlichen Tests sind
~30–60 Zeilen pro Szenario.

### `assets/`-Block in `pubspec.yaml`
Steht auskommentiert (`# assets: ...`). Wenn du Bilder/Icons aus dem
Repo nutzt, einkommentieren. Sonst Zeile löschen.

---

## Aufräumen — nach 2 Releases

Wenn die Legacy-Migration aus dem Argon2-Passwort-Modell sich gelegt
hat (Faustregel: 2 Minor-Releases nach Einführung), folgendes
entfernen:

- `lib/data/services/legacy_password_verifier.dart`
- `lib/presentation/screens/auth/legacy_migration_screen.dart`
- `AppRoutes.legacyMigration` und `/legacy-migration`-Route in `app_router.dart`
- `AuthStatus.needsLegacyMigration` und `migrateFromLegacy()` in
  `auth_state.dart`
- `legacyPasswordVerifierProvider` in `auth_providers.dart`
- `AppConstants.argon2*`, `secureKeyAuthHash`, `secureKeyAuthSalt`,
  `secureKeyBiometricEnabled`, `secureKeyFailedAttempts`,
  `secureKeyCooldownUntil`, `secureKeyLastPasswordLogin`
- `SecureStorageService.readAuthHash`, `readAuthSalt`, `deleteLegacyAuth`
- `pointycastle` Dependency in `pubspec.yaml`
- DB-Migration `_v3` darf bleiben (historische Korrektheit), kann aber
  vereinfacht werden falls gewünscht

Doku dazu: `docs/2026-05-04-biometrie-migration.md`.

---

## Bewusst nicht gemacht

- **`expense_form_screen.dart` setState→Riverpod-Refactor:**
  3 `TextEditingController` plus `_items`-Liste mit weiteren Controllern
  brauchen `State`-Lifecycle. Die übrigen `setState`-Calls sind reiner
  Form-UI-State (categoryId/summarizeOnly/occurredAt/saving). Form-State
  ist per Konvention lokal — Riverpod-Refactor brächte Komplexität ohne
  Wartbarkeitsgewinn. Der ursprüngliche Review-Punkt zielte auf die
  alten Auth-Screens (login/register), die sind weg.

- **`ExpenseItem.quantity` wirklich auf `int` (Stück) statt
  `quantityMilli`:** geht nicht, weil kg-Ware mit Kommawerten
  gespeichert werden muss. `quantityMilli` mit Faktor 1000 ist der
  saubere Mittelweg.

- **Vollständige a11y-Label-Abdeckung:** Kritische Stellen sind
  versorgt (Budget-Bars, Splash-Indicator). Eine vollständige Audit
  jeder `IconButton`/`Icon`-Verwendung ist eigene Arbeit.

---

## Vorgeschlagene Reihenfolge

1. `.git/index.lock` löschen (manuell, 30 Sek)
2. `flutter analyze && flutter test` grün halten nach jedem Schritt
3. Verbleibende Repo-`!`-Casts (klein)
4. Restliche Widget-Tests (klein)
5. Release-Build-Signatur-Härtung (klein)
