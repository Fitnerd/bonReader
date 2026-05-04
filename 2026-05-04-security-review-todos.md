# BonBudget – Security Review Todos

**Datum:** 2026-05-04
**Reviewer:** Claude (automatisiert)
**Projekt:** BonBudget (Flutter, lokal, privacy-first)

---

## Legende Schweregrad

| Kürzel | Bedeutung |
|--------|-----------|
| 🔴 HOCH | Direktes Sicherheitsrisiko, zeitnah beheben |
| 🟠 MITTEL | Schwäche, die unter bestimmten Bedingungen ausnutzbar ist |
| 🟡 NIEDRIG | Best-Practice-Verstoß, geringes Risiko |
| 🔵 INFO | Verbesserungsvorschlag, kein direktes Risiko |

---

## Todos

### 🔴 HOCH

- [ ] **Login-Brute-Force-Schutz nur im Speicher (nicht persistent)**
  - **Datei:** `lib/presentation/providers/auth_state.dart`
  - **Problem:** `failedAttempts` und `cooldownUntil` leben im Riverpod-State. Ein Angreifer muss die App nur neu starten, um den Zähler zurückzusetzen und den 1-Minuten-Cooldown zu umgehen.
  - **Lösung:** Fehlversuche und Cooldown-Zeitstempel im SecureStorage persistieren. Beim App-Start den gespeicherten Wert laden und prüfen, ob der Cooldown noch aktiv ist.

- [ ] **Debug-Print gibt OCR-Daten in der Konsole aus**
  - **Datei:** `lib/presentation/screens/expense/receipt_scan_screen.dart` (Zeile mit `print('OCR LINES: …')`)
  - **Problem:** Im Release-Build werden Bon-Inhalte (Händler, Beträge, Positionen) in die System-Konsole geschrieben. Auf gerooteten Geräten oder bei USB-Debugging lesbar.
  - **Lösung:** `print`-Aufruf entfernen oder durch `debugPrint` mit `kDebugMode`-Guard ersetzen: `if (kDebugMode) debugPrint(…);`

- [ ] **Android Backup nicht deaktiviert**
  - **Datei:** `android/app/src/main/AndroidManifest.xml`
  - **Problem:** Kein `android:allowBackup="false"` und kein `android:dataExtractionRules` gesetzt. Android sichert die App-Daten (inkl. verschlüsselter DB-Datei) standardmäßig in Google Drive. Die Passphrase ist zwar im Keystore (device-bound), aber das Backup stellt trotzdem ein unnötiges Angriffsziel dar.
  - **Lösung:** `android:allowBackup="false"` im `<application>`-Tag setzen. Ab Android 12 zusätzlich `android:dataExtractionRules="@xml/backup_rules"` mit leeren Regeln.

---

### 🟠 MITTEL

- [ ] **Kein Screenshot-Schutz (FLAG_SECURE)**
  - **Datei:** `android/app/src/main/…/MainActivity.kt` (ggf. neu anlegen)
  - **Problem:** Sensitive Finanzdaten (Beträge, Budgets, Bon-Inhalte) können per Screenshot oder Screen-Recording erfasst werden. Bei App-Switchern ist ein Vorschaubild sichtbar.
  - **Lösung:** In der `MainActivity` `window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, …)` setzen. Alternativ per Flutter-Plugin (`flutter_windowmanager`) steuerbar machen (z. B. nur auf sensiblen Screens).

- [ ] **Passwort-Policy zu schwach (nur Mindestlänge 8)**
  - **Dateien:** `lib/data/repositories/auth_repository_impl.dart`, `lib/presentation/screens/auth/register_screen.dart`
  - **Problem:** Einzige Anforderung ist `password.length < 8`. Keine Prüfung auf Großbuchstaben, Ziffern, Sonderzeichen oder bekannte schwache Passwörter.
  - **Lösung:** Mindestens eine Komplexitätsregel (z. B. min. 1 Ziffer + 1 Buchstabe) einführen. Optional: Passwort-Stärke-Indikator im UI. Eine Blocklist der 100 häufigsten Passwörter wäre ein guter Zusatz.

- [ ] **Fehler-Details werden dem Nutzer angezeigt**
  - **Datei:** `lib/presentation/screens/expense/receipt_scan_screen.dart`
  - **Problem:** `SnackBar(content: Text('OCR fehlgeschlagen: $e'))` gibt die rohe Exception-Message an den Nutzer weiter. Kann Implementierungsdetails (Pfade, Klassennamen) leaken.
  - **Lösung:** Generische Fehlermeldung anzeigen ("Bon konnte nicht gelesen werden. Bitte erneut versuchen."). Exception-Details nur per `Logger` loggen.

- [ ] **Passwort-TextEditingController nicht explizit gecleart**
  - **Dateien:** `lib/presentation/screens/auth/login_screen.dart`, `register_screen.dart`, `settings_screen.dart`
  - **Problem:** Die Controller werden per `dispose()` freigegeben, aber der Passwort-Text wird nicht vorher mit `.clear()` überschrieben. Der String könnte theoretisch im Dart-Heap verbleiben, bis der GC ihn räumt.
  - **Lösung:** Vor `dispose()` jeweils `_passwordCtrl.clear()` aufrufen. Dart-Strings sind immutable, also ist das keine 100 %-Garantie, aber eine Defence-in-Depth-Maßnahme.

- [ ] **`local.properties` möglicherweise im Git-Verlauf**
  - **Datei:** `android/local.properties`
  - **Problem:** Die Datei enthält lokale SDK-Pfade (`sdk.dir`, `flutter.sdk`) und ist zwar in `.gitignore` gelistet, existiert aber im Repo. Sie könnte vor dem Gitignore-Eintrag committed worden sein.
  - **Lösung:** `git rm --cached android/local.properties` ausführen und committen, damit die Datei aus dem Tracking entfernt wird.

---

### 🟡 NIEDRIG

- [ ] **Kein Network-Security-Config (Android)**
  - **Datei:** `android/app/src/main/AndroidManifest.xml`
  - **Problem:** Kein `android:networkSecurityConfig` definiert. Obwohl die App offline-first ist, könnten Dependencies (ML Kit Model-Downloads) Netzwerkzugriff nutzen. Ohne explizite Konfiguration ist Cleartext-Traffic auf API <28 erlaubt.
  - **Lösung:** `network_security_config.xml` anlegen, die Cleartext-Traffic explizit verbietet: `<base-config cleartextTrafficPermitted="false">`.

- [ ] **Kein ProGuard/R8-Obfuscation-Setup sichtbar**
  - **Dateien:** `android/app/build.gradle` (nicht geprüft ob vorhanden)
  - **Problem:** Keine `proguard-rules.pro` im Repo sichtbar. Ohne Obfuscation sind Release-APKs leichter reverse-engineerbar.
  - **Lösung:** In `build.gradle` für den Release-Build `minifyEnabled true` und `shrinkResources true` setzen. ProGuard-Rules für Flutter und verwendete Plugins pflegen.

- [ ] **Biometrie-Login umgeht Passwort komplett**
  - **Datei:** `lib/presentation/providers/auth_state.dart` (`loginWithBiometric`)
  - **Problem:** Wenn Biometrie aktiviert ist, gewährt ein erfolgreicher Fingerabdruck/Face-ID sofort vollen Zugriff, ohne dass jemals das Passwort geprüft wird. Ein Angreifer, der einen Finger des Nutzers hat (z. B. im Schlaf), kommt sofort rein.
  - **Lösung:** Gelegentlich (z. B. alle 72h oder nach App-Update) Passwort-Eingabe erzwingen, selbst wenn Biometrie aktiviert ist. Dieses Pattern verwenden viele Banking-Apps.

- [ ] **`UniqueKey().toString()` statt UUID für Item-IDs im Update-Pfad**
  - **Datei:** `lib/presentation/screens/expense/expense_form_screen.dart`
  - **Problem:** Beim Update werden neue ExpenseItem-IDs mit `UniqueKey().toString()` generiert. Das erzeugt Flutter-Widget-Keys, keine kryptografisch sicheren UUIDs. Nicht direkt ein Sicherheitsrisiko, aber inkonsistent mit dem `Uuid().v4()`-Pattern im Repository.
  - **Lösung:** Auch hier `const Uuid().v4()` verwenden für Konsistenz.

---

### 🔵 INFO

- [ ] **DB-Passphrase wird nie rotiert**
  - **Datei:** `lib/data/datasources/database/database_passphrase_service.dart`
  - **Problem:** Die 32-Byte-Passphrase wird beim ersten Start generiert und danach nie geändert. Kein direktes Risiko, da sie im Secure Storage liegt, aber Key-Rotation ist generell Best Practice.
  - **Lösung:** Langfristig einen Mechanismus einbauen, der die DB-Passphrase z. B. bei Passwortänderung rotiert (SQLCipher unterstützt `PRAGMA rekey`).

- [ ] **Cooldown-Dauer sehr kurz (1 Minute, 5 Versuche)**
  - **Datei:** `lib/core/constants/app_constants.dart`
  - **Problem:** 5 Fehlversuche → 1 Minute Pause ist mild. In Kombination mit dem nicht-persistenten Zähler (siehe oben) nahezu wirkungslos.
  - **Lösung:** Exponentielles Backoff einführen (z. B. 1 Min → 5 Min → 15 Min → 1 Std). Erst sinnvoll nach Persistierung des Zählers.

- [ ] **`.idea/`-Ordner im Repo**
  - **Datei:** `.idea/workspace.xml`, etc.
  - **Problem:** IDE-Konfiguration (inkl. `workspace.xml`) ist im Repo. Enthält lokale Pfade und Einstellungen. Ist in `.gitignore` gelistet, aber die Dateien existieren dennoch.
  - **Lösung:** `git rm -r --cached .idea/` ausführen.

- [ ] **Keine Export-/Backup-Verschlüsselung geplant**
  - **Problem:** Falls in Zukunft ein Daten-Export (CSV, JSON) oder Cloud-Backup implementiert wird, müssen diese Daten ebenfalls verschlüsselt werden. Aktuell kein Code dafür vorhanden.
  - **Lösung:** Bei Implementierung eines Exports die Daten entweder mit dem Nutzerpasswort (via Argon2-derived Key) verschlüsseln oder ein separates Export-Passwort verlangen.

---

## Zusammenfassung

| Schweregrad | Anzahl |
|-------------|--------|
| 🔴 HOCH | 3 |
| 🟠 MITTEL | 4 |
| 🟡 NIEDRIG | 4 |
| 🔵 INFO | 4 |

**Positiv aufgefallen:**
- SQLCipher-Verschlüsselung der DB (AES-256) korrekt implementiert
- Argon2id mit RFC-9106-konformen Parametern (t=3, m=64MB, p=4)
- Constant-Time-Vergleich beim Passwort-Verify
- DB-Passphrase unabhängig vom Nutzerpasswort (gutes Design)
- Parametrisierte SQL-Queries durchgehend (kein SQL-Injection-Risiko)
- Secure Storage mit `encryptedSharedPreferences` (Android) und Keychain (iOS)
- OCR rein on-device (kein Netzwerk-Leak von Bon-Daten)
- Foto wird nach OCR sofort gelöscht (Privacy)
- Auto-Logout bei App-Backgrounding
- Biometrie-Aktivierung erfordert vorherige biometrische Bestätigung
