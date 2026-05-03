# BonBudget

Privacy-first Bon- und Budget-Tracker für Android und iOS.
Alle Daten bleiben **lokal und verschlüsselt** auf deinem Gerät.

## Status

- [x] Schritt 1: Projekt-Setup & Architektur
- [ ] Schritt 2: Datenmodell & verschlüsselte DB
- [ ] Schritt 3: Auth-System (Argon2 + Secure Storage + Biometrie)
- [ ] Schritt 4: Kategorien-Verwaltung & Budgets
- [ ] Schritt 5: Manuelle Ausgabe-Erfassung
- [ ] Schritt 6: Bon-Foto + OCR + Positions-Erkennung
- [ ] Schritt 7: Dashboard & Budget-Anzeige
- [ ] Schritt 8: Statistik & Diagramme
- [ ] Schritt 9: Einstellungen, Polish, Release-Vorbereitung

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

## Projektstruktur

```
lib/
├── app.dart               # MaterialApp + Theme + Router
├── main.dart              # Entry Point, ProviderScope
├── core/                  # Querschnittsbelange
│   ├── constants/         # zentrale Konstanten
│   ├── router/            # go_router Setup
│   ├── theme/             # Mint-Grün Material-3-Theme
│   └── utils/             # Helper (Currency, …)
├── data/                  # (Schritt 2) DB, Repositories
├── domain/                # (Schritt 2) Entities, Use Cases
└── presentation/          # UI: Screens + Widgets
    └── screens/

test/
├── unit/                  # Pure-Logik-Tests, ohne UI
└── widget/                # Einzelne Widgets in Isolation

integration_test/          # E2E-Tests auf Gerät / Emulator
```

## Sicherheit & Datenschutz

Siehe [`docs/2026-05-03-security.md`](docs/2026-05-03-security.md).

Kurzfassung:
- Passwort wird mit Argon2id gehasht – nie im Klartext gespeichert.
- Sensible Daten liegen im Android Keystore / iOS Keychain.
- Datenbank wird mit SQLCipher (AES-256) verschlüsselt.
- Bon-Fotos werden nach OCR sofort gelöscht.
- Auto-Logout nach Inaktivität.

## Architektur-Überblick

Siehe [`docs/2026-05-03-architecture.md`](docs/2026-05-03-architecture.md).

## Lizenz

Privates Projekt, alle Rechte vorbehalten.
