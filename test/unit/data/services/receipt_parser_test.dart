import 'package:bonbudget/data/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit-Tests fuer den Bon-Parser.
///
/// Wir testen mit synthetischem OCR-Output, der typische deutsche
/// Bon-Strukturen abbildet (Rewe, Aldi, Edeka). Layout-Varianten:
/// * Mit Steuerklassen-Markern (A, B, *)
/// * Mengen-Zeilen vor Positionen (`2 X 1,99`)
/// * Tausendertrenner `1.234,56`
void main() {
  group('ReceiptParser', () {
    test('extrahiert Datum im Format DD.MM.YYYY', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Datum: 03.05.2026 14:32',
        'Brot 1,99 A',
        'Summe 1,99',
      ]);
      expect(r.occurredAt.year, 2026);
      expect(r.occurredAt.month, 5);
      expect(r.occurredAt.day, 3);
    });

    test('extrahiert Datum im Format DD.MM.YY', () {
      final r = ReceiptParser.parse(<String>[
        'EDEKA',
        '03.05.26',
        'Summe 5,00',
      ]);
      expect(r.occurredAt.year, 2026);
      expect(r.occurredAt.month, 5);
      expect(r.occurredAt.day, 3);
    });

    test('faellt auf fallbackDate zurueck wenn kein Datum gefunden', () {
      final fallback = DateTime(2026, 1, 1);
      final r = ReceiptParser.parse(<String>[
        'EDEKA',
        'Brot 1,99',
      ], fallbackDate: fallback);
      expect(r.occurredAt, fallback);
    });

    test('erkennt Haendler aus erster prominenter Zeile', () {
      final r = ReceiptParser.parse(<String>[
        'ALDI SUED',
        'Hauptstrasse 1',
        '12345 Musterstadt',
        '03.05.2026',
        'Summe 0,00',
      ]);
      expect(r.merchant, 'ALDI SUED');
    });

    test('erkennt Total aus Zeile mit „Summe"', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'Milch 1,29',
        'Summe 3,28',
      ]);
      expect(r.totalCents, 328);
    });

    test('erkennt Total aus Zeile mit „Gesamt" / „Total"', () {
      final r1 = ReceiptParser.parse(<String>[
        'EDEKA',
        'Apfel 0,99',
        'Gesamt 0,99',
      ]);
      expect(r1.totalCents, 99);

      final r2 = ReceiptParser.parse(<String>[
        'KAUFLAND',
        'Brot 2,49',
        'Total: 2,49 EUR',
      ]);
      expect(r2.totalCents, 249);
    });

    test('faellt fuer Total auf Summe der Positionen zurueck', () {
      final r = ReceiptParser.parse(<String>[
        'EDEKA',
        'Apfel 1,00',
        'Birne 2,00',
        // kein Summe-Keyword
      ]);
      expect(r.items, hasLength(2));
      expect(r.totalCents, 300);
    });

    test('erkennt einfache Positionen mit Steuerklassen-Marker', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot Vollkorn 1,99 A',
        'Milch 1,29 B',
        'Summe 3,28',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[0].name, 'Brot Vollkorn');
      expect(r.items[0].totalCents, 199);
      expect(r.items[1].name, 'Milch');
      expect(r.items[1].totalCents, 129);
    });

    test('Mengen-Zeile NACH Position aktualisiert qty/unit retroaktiv', () {
      // Deutsches Rewe/Edeka-Layout: erst Position mit Gesamtbetrag,
      // dann '2 Stk x 1,99' als Detail-Aufschluesselung.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 3,98 A',
        '2 X 1,99',
        'Summe 3,98',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'Brot');
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 199);
      expect(r.items[0].totalCents, 398);
    });

    test('Geg.EC-Cash-Zeile wird nicht als Position dupliziert', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'SUMME EUR 1,99',
        'Geg. EC-Cash EUR 1,99',
        'Kartenzahlung',
        'Contactless',
        'girocard',
      ]);
      // Nur Brot, NICHT Geg. EC-Cash erneut
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'Brot');
      expect(r.totalCents, 199);
    });

    test('ignoriert Steuer-/MwSt-/Rueckgeld-Zeilen', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'MwSt 7%: 0,13',
        'Gegeben 5,00',
        'Rueckgeld 3,01',
        'Summe 1,99',
      ]);
      expect(r.items.map((i) => i.name), <String>['Brot']);
      expect(r.totalCents, 199);
    });

    test('parst Tausender-Trenner korrekt (1.234,56)', () {
      final r = ReceiptParser.parse(<String>[
        'BAUMARKT',
        'Heimwerker-Set 1.234,56',
        'Summe 1.234,56',
      ]);
      expect(r.totalCents, 123456);
    });

    test('confidence steigt mit erfolgreich erkannten Feldern', () {
      final empty = ReceiptParser.parse(<String>[]);
      expect(empty.confidence, lessThan(0.3));

      final full = ReceiptParser.parse(<String>[
        'REWE',
        '03.05.2026',
        'Brot 1,99',
        'Summe 1,99',
      ]);
      expect(full.confidence, greaterThanOrEqualTo(0.9));
    });

    test('liefert leere Items, wenn keine Preise erkannt werden', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Vielen Dank fuer Ihren Einkauf',
      ]);
      expect(r.items, isEmpty);
    });

    test('akzeptiert „Zu zahlen" als Total-Keyword', () {
      final r = ReceiptParser.parse(<String>[
        'EDEKA',
        'Apfel 1,00',
        'Zu zahlen: 1,00 EUR',
      ]);
      expect(r.totalCents, 100);
    });

    test('robust gegen leere und whitespace-Zeilen', () {
      final r = ReceiptParser.parse(<String>[
        '',
        '   ',
        'REWE',
        '',
        'Brot 1,99',
        '   ',
        'Summe 1,99',
      ]);
      expect(r.merchant, 'REWE');
      expect(r.items, hasLength(1));
      expect(r.totalCents, 199);
    });

    test('Plausibilitaet: ignoriert Zeilen mit absurd hohen Preisen', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'Telefonnummer 0123456789',  // sieht wie eine Zahl aus
        'Summe 1,99',
      ]);
      expect(r.totalCents, 199);
    });
  });
}
