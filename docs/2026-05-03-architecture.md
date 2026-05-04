# Architektur-Überblick (Stand 2026-05-03)

## Leitprinzipien

1. **Privacy first** – alles lokal, keine Cloud.
2. **Verschlüsselung by default** – DB und Secrets werden immer verschlüsselt.
3. **Schichtentrennung** – UI kennt keine SQL, Logik ist isoliert testbar.
4. **Sinnvolle Tests** – nicht jede Datei wird getestet, aber jede Logik mit echtem Risiko (Geld, Sicherheit, Parsing) bekommt einen Test.

## Schichten (Clean Architecture)

```
┌─────────────────────────────────────────────┐
│   presentation/  (Widgets, Screens, State)  │
│           ↓ ruft Use Cases auf              │
├─────────────────────────────────────────────┤
│   domain/        (Entities, Use Cases,      │
│                   Repository-Interfaces)    │
│           ↑ wird von data/ implementiert    │
├─────────────────────────────────────────────┤
│   data/          (SQLCipher, Secure Storage,│
│                   ML Kit, Repository-Impls) │
└─────────────────────────────────────────────┘
```

- **presentation** kennt nur `domain`.
- **domain** ist reines Dart, kein Flutter, keine Plugins → **leicht zu unit-testen**.
- **data** kennt `domain` und implementiert dessen Interfaces.

Riverpod (`flutter_riverpod`) verdrahtet die Schichten via Dependency Injection. Repositories werden als Provider exponiert; UI konsumiert nur Provider, nie konkrete Klassen.

## State Management: Riverpod

- Kein `setState` für App-State, nur für lokale UI-Zustände.
- `Notifier` / `AsyncNotifier` für Geschäftslogik.
- Tests können Provider mit `ProviderContainer` und `overrideWith` einfach mocken.

## Routing: go_router

- Deklarative Routes in `core/router/app_router.dart`.
- In Schritt 3 kommt ein `redirect`-Callback dazu, der nicht-eingeloggte Nutzer zum Login zwingt.

## Datenhaltung

- **SQLite** über `sqflite_sqlcipher` mit AES-256-Verschlüsselung.
- DB-Schlüssel wird beim ersten Start zufällig erzeugt und **im Secure Storage** abgelegt – nicht im Code, nicht in SharedPreferences.
- Geld wird **immer in Cent als `int`** gehalten, nie als `double`. Konvertierung nur an UI-Rändern (`CurrencyFormatter`).

## Testpyramide (Definition für dieses Projekt)

| Ebene | Wo | Was wird abgedeckt |
|---|---|---|
| Unit | `test/unit/` | Pure Dart-Logik: Parser, Formatter, Berechnungen, Hashing-Wrapper |
| Widget | `test/widget/` | Einzelne UI-Komponenten in Isolation, mit gemockten Providern |
| Integration / E2E | `integration_test/` | Echte User-Flows auf Gerät / Emulator |

**Regel:** Wenn ein Bug Geld falsch berechnet, Daten leakt oder Auth umgeht, gibt es einen Test, der diesen Bug fängt. Smoke-Tests, die nur „App startet" prüfen, gibt es genau einen pro Feature, nicht mehr.

## Design-System

- Material 3 mit Seed-Color **#14B8A6** (Mint-Teal).
- Helles und dunkles Theme automatisch nach Systemeinstellung.
- Abgerundete Ecken (14 px), keine starken Schlagschatten, ruhige Typografie.
- Eigene Chart-Palette (in `app_colors.dart`), damit Diagramme in beiden Themes konsistent wirken.

## Offene Architekturentscheidungen

- **Hive/Isar statt SQLite?** Bewusst gegen NoSQL entschieden, weil Aggregationen über Ausgaben/Kategorien (Statistik) mit SQL deutlich einfacher sind.
- **Freezed?** Wird in Schritt 2 hinzugenommen, um immutable Entities mit `copyWith` zu generieren.
- **Code-Obfuscation für Release** wird in Schritt 9 aktiviert.
