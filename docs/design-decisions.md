# Design-Entscheidungen (Backlog)

Dieses Dokument haelt Design-Optionen fest, die bewusst aufgeschoben
wurden. Jeder Eintrag enthaelt: Problem, betrachtete Optionen,
gewaehlte Loesung (mit Datum), Konsequenzen, und konkrete Hinweise
fuer den Fall, dass wir die Entscheidung spaeter revidieren wollen.

---

## DD-001: Auto-Kategorisierung von Bon-Positionen

**Status:** Variante C aktiv ab 2026-05-04 (Commit folgt). Variante A
und B als Optionen festgehalten.

**Problem:**
Wenn ein Bon gescannt wird, hat er aktuell genau **eine** Kategorie
(z. B. „Lebensmittel"). Reale Bons mischen aber Kategorien
(Lebensmittel + Drogerie + Pfand). Der User will, dass die
Positionen „automatisch einer Kategorie zugeordnet" werden, statt
nur die Bon-Gesamtkategorie zu setzen.

**Optionen:**

### Variante A — Pro Item eine eigene Kategorie

**Idee:** `expense_items` bekommt eine optionale `category_id`-Spalte.
Ein Bon ist eine `Expense` mit einer Bon-Kategorie, aber jedes Item
darf seine eigene Kategorie haben (Default: Bon-Kategorie).

**Schemaaenderung:**
```sql
ALTER TABLE expense_items ADD COLUMN category_id TEXT
  REFERENCES categories(id) ON DELETE SET NULL;
```
Migration `_v3` in `lib/data/datasources/database/migrations.dart`.

**UI-Konsequenzen:**
- `_ItemRow` im `ExpenseFormScreen` braucht ein zusaetzliches
  Kategorie-Dropdown pro Zeile.
- `ExpenseItem` und `ExpenseItemDraft` (in
  `lib/domain/repositories/expense_repository.dart`) bekommen
  ein `categoryId`-Feld.
- `ExpenseRepositoryImpl.create/update` muss die Spalte mit-schreiben.

**Statistik / Dashboard:**
- Aktuell aggregiert `getTotalsByCategory(from, to)` ueber
  `expenses.total_cents` gruppiert nach `expenses.category_id`.
- Mit Variante A muesste das Pro-Item-Summen verwenden:
  `SELECT items.category_id, SUM(items.total_cents) ...
   GROUP BY items.category_id`.
  Bons OHNE Items (Modus „Nur Gesamtbetrag") fallen weiter zurueck
  auf `expenses.category_id` und `expenses.total_cents`.
- Das ist die invasivste Aenderung: alle Statistik-Queries muessen
  angepasst werden.

**Aufwand-Schaetzung:** ~1 Tag Arbeit, 4-5 Files plus Tests.

**Vorteile:** sauberste Loesung, granular, korrekt fuer
Mischbons.

**Nachteile:** groesste Aenderung, viele Touchpoints, alle
Statistik-Aggregationen anpassen.

### Variante B — Bon-Splitting

**Idee:** Beim Speichern eines Bon-Scans wird der Bon nicht als
einzelne `Expense` gespeichert, sondern als mehrere `Expenses` —
eine pro Kategorie. Aus einem REWE-Bon (95,92 €) werden z. B.
drei Expenses: REWE Lebensmittel (78,40 €), REWE Drogerie
(7,99 €), REWE Pfand (2,50 €). Auf der Statistik-Seite bleibt
alles wie bisher pro Expense.

**Schemaaenderung:**
- Optional: `expenses.parent_bon_id` als Gruppierungsfeld, damit
  man die zusammengehoerenden Splits wiedererkennt.
- Sonst kein Schemaaenderung noetig.

**UI-Konsequenzen:**
- Im `ExpenseFormScreen` braucht es einen „Bon-Splitten"-Button
  oder einen Modus, der die Items in mehrere Expense-Drafts
  gruppiert und alle auf einmal speichert.
- In der Liste wuerden splits nebeneinander stehen — das kann
  unuebersichtlich werden, wenn pro Bon plotzlich 3-4 Eintraege
  auftauchen.

**Statistik / Dashboard:**
- Keine Aenderung — pro Expense bleibt es wie bisher.

**Aufwand-Schaetzung:** ~1/2 Tag, weniger als A.

**Vorteile:** keine Schema-Migration, Statistik bleibt unveraendert.

**Nachteile:** macht die Expense-Liste fuer einen Bon unuebersicht-
licher (3 Zeilen statt 1). Edit-Workflow ist umstaendlich (welche
der 3 Expenses ist „der Bon"?).

### Variante C — Auto-Vorschlag fuer Bon-Kategorie (gewaehlt)

**Idee:** Bon bleibt eine Expense mit einer Kategorie. Beim Scan
laeuft eine Heuristik ueber die Item-Namen und schlaegt die
ueberwiegende Kategorie als Default vor (statt blind die erste
sichtbare zu nehmen). Items selbst haben keine eigene Kategorie.

**Files:**
- `lib/data/services/category_classifier.dart` — Lookup-Tabelle
  Substring -> Slug, Mehrheits-Vote.
- Integration in `ReceiptScanScreen._scanFrom`: nach
  `ReceiptParser.parse()` rufen wir `suggestSlug(items)` auf,
  matchen den Slug auf eine sichtbare Kategorie, fallen auf
  „erste sichtbare" zurueck wenn kein Match.
- `test/unit/data/services/category_classifier_test.dart`.

**Schemaaenderung:** keine.

**UI-Aenderung:** keine direkt sichtbare — die Kategorie im
vorbefuellten Form ist einfach „besser geraten".

**Aufwand:** ~1 Stunde.

**Vorteile:** Hauptnutzen (Bon landet in der richtigen Kategorie)
mit minimalem Aufwand. Kein DB-Schema, keine Statistik-Aenderung,
trivial revertierbar.

**Nachteile:** Mischbons werden weiter unter EINER Kategorie
verbucht. Wenn ein Lebensmittel-Bon ein paar Drogerie-Items hat,
gehen die in den Lebensmittel-Topf.

### Wenn wir spaeter nach A oder B umstellen wollen

- A: ist die saubere Endform. Migration V3 + Item-Schema-Erweiterung
  + Repository + UI + Statistik.
- B: koennte im `ReceiptScanScreen` schon vorbereitet werden, indem
  der Save-Pfad eine Liste statt einer einzelnen Expense schreibt.
- Variante C bleibt parallel nutzbar (als Default-Vorschlag) und
  widerspricht weder A noch B.

---
