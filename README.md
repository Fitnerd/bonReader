# BonBudget

Privacy-first Bon- und Budget-Tracker für Android und iOS.
Alle Daten bleiben **lokal und verschlüsselt** auf deinem Gerät.

## Status

- [x] Schritt 1: Projekt-Setup & Architektur
- [x] Schritt 2: Datenmodell & verschlüsselte DB
- [x] Schritt 3: Auth-System (Argon2 + Secure Storage + Biometrie)
- [x] Schritt 4: Kategorien-Verwaltung & Budgets
- [x] Schritt 5: Manuelle Ausgabe-Erfassung
- [x] Schritt 6: Bon-Foto + OCR + Positions-Erkennung
- [x] Schritt 7: Dashboard & Budget-Anzeige
- [x] Schritt 8: Statistik & Diagramme
- [x] Schritt 9: Einstellungen, Polish, Release-Vorbereitung

## Features

- **Lokal & verschlüsselt**: SQLCipher (AES-256) + Argon2id-Passwort.
  Keine Cloud, keine Telemetrie.
- **Bon scannen**: On-device OCR (Google ML Kit). Foto wird unmittelbar
  nach Auswertung gelöscht.
- **Heuristischer Bon-Parser**: Erkennt Händler, Datum, Total und einzelne
  Positionen aus typischen deutschen Kassenbons.
- **Manuelle Erfassung**: Wenn kein Bon da ist – Form mit Positionen.
- **Budgets pro Kategorie**: Gesamtbudget = Summe der Kategorie-Budgets.
- **Dashboard**: Restbudget-Ring, Auslastung pro Kategorie, letzte Ausgaben.
- **Statistik**: 12-Monats-Trend, Top-Kategorien-Donut, Monatsvergleich.
- **Biometrie**: Fingerprint / Face ID als zusätzliche Anmeldung.
- **Auto-Logout**: konfigurierbar (1–30 Min) und sofort beim Backgrounding.
- **Account-Reset**: Komplett-Wipe direkt in der App.

## Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.22
- Android Studio (oder VS Code) mit Flutter-Plugin
- Für iOS-Build zusätzlich: Xcode auf macOS

Prüfen:
```bash
flutter --version
flutter doctor
```

## Erstes Setup

```bash
cd 2026-05-03-bonbudget
flutter pub get
```

## App starten

```bash
# Android-Emulator oder USB-Gerät verbinden, dann:
flutter run
```

## Tests ausführen

```bash
# Unit- + Widget-Tests
flutter test

# Mit Coverage-Report
flutter test --coverage

# Integration- / E2E-Tests (auf einem echten Gerät / Emulator)
flutter test integration_test/
```

## Release-Build (Android)

Mit Code-Obfuscation und ausgelagerten Debug-Symbolen:

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols/

# oder als App Bundle:
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/
```

Der `build/symbols/`-Ordner gehört NICHT in den Play-Store-Upload, aber
unbedingt **lokal aufbewahren** – sonst sind Crash-Reports unlesbar.

## Projektstruktur

```
lib/
├── app.dart               # MaterialApp + Theme + Router
├── main.dart      