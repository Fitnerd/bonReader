# BonBudget – Umstellung auf Biometrie-Only

**Datum:** 2026-05-04
**Ziel:** Argon2-Passwort als Login-Faktor entfernen. Stattdessen Biometrie
(Fingerprint / Face ID) mit Geräte-PIN als Fallback. UI bleibt minimalistisch,
keine zusätzlichen Optionen.

---

## 0. Konzept & Entscheidungen

- [ ] **Threat-Model festschreiben** in `docs/2026-05-03-security.md` ergänzen:
  geschützt gegen verlorenes/gestohlenes (entsperrtes) Telefon, Forensik mit
  physischem Zugriff, Malware ohne Root. Nicht geschützt gegen kompromittierte
  Hardware mit Root oder kompromittiertes OS.
- [ ] **Fallback = Geräte-PIN/Pattern**, nicht App-Passwort. (`AuthenticationOptions.biometricOnly = false`,
  iOS `LAPolicy.deviceOwnerAuthentication`.) Begründung: Nutzer kennt es bereits,
  keine zweite Geheimnis-Verwaltung nötig.
- [ ] **Kein Recovery, keine Cloud, keine Export-Lösung in v1.** Klartext in
  README + Onboarding: Bei Geräteverlust sind Daten weg. Das ist der Privacy-Preis.
- [ ] **Komplett-Entfernung des Passworts**, nicht „optional". Ein Code-Pfad,
  weniger Tests, weniger Bugs.

## 1. Architektur-Änderungen

- [ ] **DB-Passphrase an Biometrie binden.** Heute liegt sie unbedingt im Secure
  Storage. Neu: Android Keystore mit `setUserAuthenticationRequired(true)` +
  `setInvalidatedByBiometricEnrollment(true)`, iOS Keychain mit
  `kSecAccessControlBiometryCurrentSet`. Auslesen löst System-Auth aus.
- [ ] **Argon2id-Hashing entfernen** (`pointycastle`-Aufrufe in
  `auth_repository_impl.dart`, `password_hasher.dart` falls existent).
  `pointycastle` aus `pubspec.yaml` raus, wenn nicht anderweitig genutzt.
- [ ] **`UserAuth`-Entity simplifizieren**: `passwordHash`, `salt`, `iterations`
  entfernen. Bleibt: `createdAt`, evtl. `lastUnlockAt` für UX.
- [ ] **`auth`-Tabelle in DB-Schema**: Migration v(N+1) – Spalten `passwordHash`,
  `salt`, `iterations` droppen. SQLite kann das nur via Tabellen-Recreate, also
  sauber als Migration schreiben.
- [ ] **Race Condition in `DatabasePassphraseService.getOrCreate()` beheben**
  (Mutex), bevor das Refactoring kommt. Sonst pflanzt sich der Bug fort.

## 2. Domain-Layer

- [ ] `domain/repositories/auth_repository.dart`: API auf folgende Methoden reduzieren:
  - `Future<bool> isBiometricsAvailable()`
  - `Future<bool> isSetupComplete()`
  - `Future<void> completeSetup()` (legt `auth`-Zeile an, generiert DB-Passphrase)
  - `Future<bool> unlock()` (löst System-Auth aus, lädt DB-Passphrase)
  - `Future<void> resetAccount()` (bleibt – Komplett-Wipe).
- [ ] Methoden raus: `register(password)`, `login(password)`,
  `changePassword(...)`, `verifyPassword(...)`.
- [ ] `domain/entities/user_auth.dart`: `@immutable` Annotation, oben genannte
  Felder entfernen.

## 3. Data-Layer

- [ ] `BiometricService` erweitern: zweite Methode
  `authenticateAndUnlockSecret({required String key})` die Biometrie-Prompt + Secure-Storage-Read in einem Schritt macht (auf Android via `AuthenticationRequired`-Key, iOS via Access Control).
- [ ] **Spezifische Exceptions** statt `catch (Object)`: `BiometricNotEnrolledException`,
  `BiometricLockoutException`, `UserCancelledException`. (Auch im Review.)
- [ ] `AuthRepositoryImpl.resetAccount()` in Transaction wrappen. (Auch im Review.)
- [ ] `auth_repository_impl.dart` von Argon2-Logik befreien, neue Setup-Logik:
  `completeSetup()` legt nur Marker-Zeile an, `unlock()` ruft
  `BiometricService.authenticateAndUnlockSecret(key: 'db_passphrase')` und
  setzt Auth-State.
- [ ] `DatabasePassphraseService.getOrCreate()`: Lock einbauen
  (`synchronized`-Paket oder eigenes Completer-Pattern).

## 4. Presentation-Layer

- [ ] **Login- und Register-Screen entfernen.** `login_screen.dart`,
  `register_screen.dart`, `login_placeholder_screen.dart` löschen.
- [ ] **Setup-Screen** neu (`setup_screen.dart`): Single-Page, Erklärung
  „Diese App schützt deine Daten mit Geräte-Biometrie", Button „Einrichten".
  Bei Erfolg → Dashboard. Bei kein Biometrie verfügbar → klare Fehlermeldung
  mit Verweis auf Geräte-Settings.
- [ ] **Unlock-Screen** neu (`unlock_screen.dart`): Splash-artig, sofortiger
  Biometrie-Prompt beim Start. Kein Eingabefeld. Bei Fehlschlag: Retry-Button +
  Reset-Option (mit harter Bestätigung).
- [ ] **`settings_screen.dart`**: Block „Passwort ändern" entfernen,
  Block „Biometrie" simplifizieren (nur noch Status-Anzeige, da kein Toggle mehr).
- [ ] **Auto-Logout**: bleibt, ruft beim Re-Open `unlock()` statt Login.
- [ ] **`auth_state.dart`**: States reduzieren auf `unknown`, `needsSetup`,
  `locked`, `unlocked`, `error`. `setState`+Riverpod-Mix in Auth-Screens
  weg-refactoren.
- [ ] **Router** (`app_router.dart`): Routen für `/login`, `/register` entfernen.
  Neue Routen `/setup`, `/unlock`. Redirect-Logik anpassen.

## 5. Migration für bestehende Installationen

- [ ] **Erkennen**: Wenn `auth.passwordHash` noch in DB-Schema, ist es eine
  alte Installation.
- [ ] **Einmal-Flow** vor erstem Unlock: Modal „Wir aktualisieren die Anmeldung
  auf Biometrie. Bitte einmal dein altes Passwort eingeben." → verifiziert mit
  altem Argon2 → bei Erfolg Migration v(N+1) ausführen → Biometrie-Setup.
- [ ] **Code für alten Argon2-Verifier behalten** als isolierte
  `LegacyPasswordVerifier`-Klasse, ausschließlich für diesen Migrations-Pfad.
  Nach 2 Releases zusammen mit Migration entfernen.
- [ ] Plan dokumentieren in `docs/2026-05-04-biometrie-migration.md`
  (anlegen).

## 6. Tests

- [ ] `FakeBiometricService` erweitern: `authenticateAndUnlockSecret`-Methode,
  konfigurierbare Fehlerszenarien (cancel, lockout, not enrolled).
- [ ] Repository-Tests umschreiben: kein Passwort-Hashing mehr testen,
  stattdessen Setup → Unlock → Reset durchspielen.
- [ ] **Neuer Test**: Enrollment-Change. `BiometricService` wirft
  `BiometricInvalidatedException`, App muss zu Reset-Screen leiten.
- [ ] **Neuer Test**: Auto-Logout → Re-Unlock-Flow.
- [ ] **Migration-Test**: Setze v(N) DB mit Passwort an, führe Migration aus,
  verifiziere dass Passwort-Spalten weg sind und DB weiter lesbar bleibt.
- [ ] **Brute-Force-Cooldown im `FakeSecureStorageService`** wird obsolet,
  Cooldown jetzt via OS-Lockout. Test entfernen oder anpassen.
- [ ] **Integration-Test**: kompletter First-Launch-Flow Setup → Dashboard.

## 7. Edge-Cases (alle explizit im Code behandeln)

- [ ] **Biometrie nicht verfügbar / nicht eingerichtet** → klare Meldung mit
  Link zu Geräte-Einstellungen.
- [ ] **Biometrie eingerichtet aber abgeschaltet** (z. B. Android nach
  mehreren Fehlversuchen): Geräte-PIN-Fallback springt automatisch ein
  (kommt vom OS, kein eigener Code).
- [ ] **Neuer Fingerabdruck zum Gerät hinzugefügt** (Android): Keystore-Key
  invalidiert. App muss diesen Fall erkennen und Reset-Flow anbieten,
  weil DB-Passphrase weg ist.
- [ ] **OS-Update zerlegt Keystore-Key** (selten, aber kommt vor): selbe
  Behandlung wie oben.
- [ ] **App im Hintergrund während Biometrie-Prompt**: Auto-Logout-Suppression
  prüfen, ist heute schon implementiert (`autoLogoutSuppressionProvider`).
  Beim neuen Unlock-Flow muss das auch greifen.

## 8. UX & Strings

- [ ] Strings in `lib/core/constants/` oder dediziertem `auth_strings.dart`
  zentralisieren – auch wenn Lokalisierung später kommt.
- [ ] **Onboarding-Text Setup-Screen** schreiben: kurz, klar, nennt
  „kein Recovery" beim Namen.
- [ ] **Reset-Bestätigungsdialog** verschärfen: zwei Klicks, expliziter
  Text „Alle Bons, Budgets und Kategorien werden unwiederbringlich
  gelöscht."
- [ ] README anpassen: „Biometrie + Geräte-PIN" statt „Argon2 + Biometrie",
  Status-Liste in README aktualisieren.

## 9. Bonus – mit anfassen weil man eh in der Auth-Ecke ist

- [ ] **`MainActivity.kt` ist abgeschnitten** (124 Bytes, endet mitten im
  `import io.flutter.embedding.androi`). Vermutlich nie ein Android-Build
  durchgelaufen. **`FLAG_SECURE`** dort gleich mit setzen, damit die App
  nicht im App-Switcher / in Screenshots auftaucht – passt thematisch zur
  Privacy-Story und ist heute *nicht* gegeben. (Der Kommentar in `main.dart`
  über Screenshots ist irreführend; `setPreferredOrientations` macht das
  nicht.)
- [ ] **`android:allowBackup="false"`** ist gesetzt – gut. Dazu:
  `android:fullBackupContent="false"` + leere `data_extraction_rules`
  prüfen, ob sie wirklich alles ausschließen.
- [ ] **Race Condition in Passwortänderung** (Settings-Screen) wird durch das
  Entfernen automatisch behoben. Im Review-Todo abhaken.

---

## Reihenfolge zum Abarbeiten

1. Konzept festschreiben (0)
2. Race Condition in Passphrase-Service fixen (1)
3. `MainActivity.kt` reparieren + `FLAG_SECURE` (9)
4. Data-Layer: BiometricService erweitern (3)
5. Migration vorbereiten (5)
6. Domain + Data umbauen (2, 3)
7. Presentation umbauen (4)
8. Tests anpassen + ergänzen (6)
9. Edge-Cases verifizieren (7)
10. README / Doku anpassen (8)
