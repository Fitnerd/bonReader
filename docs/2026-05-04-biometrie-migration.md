# Biometrie-Migration

**Datum:** 2026-05-04
**Scope:** Umstellung von Argon2-Passwort auf Biometrie / Geraete-PIN

## Was passiert ist

Die App hatte bisher ein klassisches App-Passwort (Argon2id mit Salt im
Secure Storage), zusaetzlich optional Biometrie. Das wurde umgestellt
auf ein **Biometrie-Only-Modell**: kein App-Passwort mehr, der Zugriff
auf die DB-Passphrase wird vom Betriebssystem ueber Biometrie oder
Geraete-PIN autorisiert.

## Architektur

| Schicht | Vorher | Nachher |
|---|---|---|
| Domain | `AuthRepository` mit `createAccount`, `verifyPassword`, `changePassword`, `setBiometricEnabled`, `resetAccount` | `AuthRepository` mit `isSetupComplete`, `completeSetup`, `getAuth`, `resetAccount` |
| Data | `Argon2PasswordHasher`, Hash + Salt in DB **und** Secure Storage | DB-Passphrase im Secure Storage, kein Hash mehr |
| DB | `auth(id, password_hash, password_salt, biometric_enabled, ...)` | `auth(id, created_at, updated_at)` |
| Presentation | Login + Register + Change-Password | Setup + Unlock + Legacy-Migration |

## Migrationspfade fuer Bestandsinstallationen

1. **Schema-Migration v3** (automatisch beim DB-Open). Recreate-Pattern
   fuer die `auth`-Tabelle: neue Schlanke Tabelle, Daten kopieren
   (createdAt, updatedAt, id), alte droppen.
2. **Secure-Storage-Inhalte** (Argon2-Hash + Salt) bleiben zunaechst
   liegen - sie sind das Erkennungsmerkmal fuer eine Legacy-Installation.
3. **UI-Migration:** Beim ersten Start nach dem Update erkennt
   `AuthNotifier.build()` den Legacy-Hash und routet zum
   `LegacyMigrationScreen`. Der User gibt einmal das alte Passwort ein,
   wir verifizieren mit dem `LegacyPasswordVerifier`, lassen den
   System-Biometrie-Prompt durchlaufen, oeffnen die DB (= triggert
   Schema-Migration v3), loeschen die Legacy-Eintraege im Secure Storage
   und setzen den Setup-Marker.

## Zu loeschen, sobald alle Bestandsinstallationen migriert sind

| Datei / Element | Zweck |
|---|---|
| `lib/data/services/legacy_password_verifier.dart` | Argon2-Verify nur fuer Migration |
| `lib/presentation/screens/auth/legacy_migration_screen.dart` | UI-Flow fuer Migration |
| `AppConstants.argon2*` | Argon2-Parameter |
| `AppConstants.secureKeyAuthHash`, `secureKeyAuthSalt`, `secureKeyBiometricEnabled`, `secureKeyFailedAttempts`, `secureKeyCooldownUntil`, `secureKeyLastPasswordLogin` | Legacy-Keys |
| `SecureStorageService.readAuthHash`, `readAuthSalt`, `deleteLegacyAuth` | Legacy-Reader |
| `pointycastle` Dependency in `pubspec.yaml` | Argon2-Implementierung |
| Legacy-Pfade in `auth_state.dart` (`needsLegacyMigration`, `migrateFromLegacy`) | Migrations-Logik |
| Migration `_v3` in `migrations.dart` | Schema-Umbau (kann bleiben fuer historische Korrektheit) |

Empfohlener Zeitpunkt: 2 Minor-Releases nach Einfuehrung, oder wenn
`needsLegacyMigration` in keiner Telemetrie mehr auftaucht (Telemetrie
gibt es nicht - also: pragmatisch nach 2 Releases entfernen).

## Risiken / bekannte Edge-Cases

- **Keystore-Invalidation bei neuem Fingerabdruck (Android):** wird vom
  OS reportiert. Aktuell faellt der Nutzer dann automatisch in den
  Geraete-PIN-Fallback (weil `biometricOnly = false` in
  `BiometricService.authenticate`). Falls auch der PIN nicht
  funktioniert, bleibt nur Account-Reset.
- **Biometrie nicht eingerichtet:** Setup-Screen zeigt klaren Hinweis
  und blockt den Setup-Button.
- **Migration-Abbruch:** Wenn Biometrie-Prompt mitten in der Migration
  abgebrochen wird, ist der Schema-Stand schon v3, aber der Setup-Marker
  noch nicht gesetzt. Beim naechsten Start ruft die App ein erneuter
  Migrations-Versuch auf - korrekt, weil der Legacy-Hash noch da ist.
- **Reset:** wischt SecureStorage komplett (`wipeAll`), damit auch noch
  uebrig gebliebene Legacy-Eintraege weg sind.
