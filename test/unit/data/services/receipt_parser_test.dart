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

    test('erkennt Total aus Zeile mit Summe', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'Milch 1,29',
        'Summe 3,28',
      ]);
      expect(r.totalCents, 328);
    });

    test('erkennt Total aus Zeile mit Gesamt / Total', () {
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

    test('akzeptiert Zu zahlen als Total-Keyword', () {
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

    test('Multi-Line: SUMME-Keyword auf eigener Zeile, Preis daneben', () {
      // Wenn OCR den Whitespace-Block zwischen 'SUMME' und 'EUR 95,92'
      // als Newline interpretiert, landen Keyword und Wert auf zwei Zeilen.
      // Der Parser muss trotzdem das Total finden.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'SUMME',
        'EUR 95,92',
      ]);
      expect(r.totalCents, 9592);
    });

    test('Datum mit Whitespaces um die Punkte', () {
      // Manche OCR-Engines fuegen Spaces ein: '23. 01. 2026'
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Datum: 23. 01. 2026',
        'Brot 1,99',
        'Summe 1,99',
      ]);
      expect(r.occurredAt.year, 2026);
      expect(r.occurredAt.month, 1);
      expect(r.occurredAt.day, 23);
    });

    test('Bekannter Haendler-Name irgendwo in den ersten Zeilen', () {
      final r = ReceiptParser.parse(<String>[
        'Filiale 1234',
        'REWE',
        'Westerstrasse 19',
        '28199 Bremen',
        'Brot 1,99',
        'Summe 1,99',
      ]);
      expect(r.merchant, 'REWE');
    });

    test('Bekannter Haendler liefert Confidence-Bonus (>= 1.0 wenn voll)', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        '03.05.2026',
        'Brot 1,99',
        'Summe 1,99',
      ]);
      // 0.40 + 0.30 + 0.15 + 0.10 + 0.05 (REWE-Bonus) = 1.00
      expect(r.confidence, 1.0);
    });

    test('Multi-Line-Item: Name auf eine Zeile, Preis auf naechster Zeile', () {
      // ML Kit splittet bei breiten Whitespace-Luecken oft in zwei
      // separate OCR-Zeilen. Der Parser muss den Namen aus der vorigen
      // Zeile uebernehmen, wenn die naechste Zeile nur einen Preis hat.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'RISPENTOMATE',
        '3,88 B',
        'ROTKOHL',
        '3,93 B',
        'SUMME 7,81',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[0].name, 'RISPENTOMATE');
      expect(r.items[0].totalCents, 388);
      expect(r.items[1].name, 'ROTKOHL');
      expect(r.items[1].totalCents, 393);
      expect(r.totalCents, 781);
    });

    test('Mengen-Zeile mit Stk-Suffix: 2 Stk x 1,59', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'BIO GOUDA GER.',
        '3,18 B',
        '2 Stk x 1,59',
        'SUMME 3,18',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'BIO GOUDA GER.');
      expect(r.items[0].totalCents, 318);
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 159);
    });

    test('Mehrfacher Multi-Line-Mix: Name/Preis-Paare und Mengenzeile dazwischen',
        () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'WAGNER PICCOLINI',
        '6,98 B',
        '2 Stk x 3,49',
        'JA! GOUDA JUNG',
        '2,45 B',
        'SUMME 9,43',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[0].name, 'WAGNER PICCOLINI');
      expect(r.items[0].totalCents, 698);
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 349);
      expect(r.items[1].name, 'JA! GOUDA JUNG');
      expect(r.items[1].totalCents, 245);
    });

    test('Preise mit OCR-Space nach Komma: 11, 99 wird als 1199 geparst', () {
      // ML Kit liefert manchmal '11, 99' (mit Space nach Komma) statt
      // '11,99'. Der Parser muss das als 1199 Cent interpretieren.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'MANDELMUS BRAUN  11, 99 B',
        'SUMME EUR  11, 99',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'MANDELMUS BRAUN');
      expect(r.items[0].totalCents, 1199);
      expect(r.totalCents, 1199);
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

    test('Mengenzeile mit fuehrendem OCR-Punkt: .2 Stk x 3,49', () {
      // ML Kit liest manchmal einen Pixel-Punkt vor der Mengen-Ziffer.
      // Trotzdem soll das als Mengenzeile, nicht als eigene Position
      // erkannt werden.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'WAGNER PICCOLINI 6,98 B',
        '.2 Stk x  3,49',
        'SUMME 6,98',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'WAGNER PICCOLINI');
      expect(r.items[0].totalCents, 698);
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 349);
    });

    test('Mengenzeile mit fuehrendem Komma: ,2 Stk x 1,59', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'BIO GOUDA GER. 3,18 B',
        ',2 Stk x  1,59',
        'SUMME 3,18',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 159);
    });

    test('Pfand-Erstattung mit fuehrendem Minus wird negativ erfasst', () {
      // Leergut-Rueckgabe: User bekommt Geld zurueck.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'Leergut -2,99',
        'Summe -1,00',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[0].name, 'Brot');
      expect(r.items[0].totalCents, 199);
      expect(r.items[1].totalCents, -299);
      expect(r.items[1].name.toLowerCase(), contains('leergut'));
    });

    test('Pfand-Erstattung mit nachgestelltem Minus: 2,99-', () {
      // Manche Bons drucken das Minus hinter den Wert.
      final r = ReceiptParser.parse(<String>[
        'EDEKA',
        'Apfel 1,00',
        'PFAND 2,99-',
        'Summe -1,99',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[1].totalCents, -299);
    });

    test('Positives Pfand wird als Position aufgenommen', () {
      // Pfandflasche kaufen -> Wert positiv.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Mineralwasser 0,89',
        'EINWEGPFAND 0,25',
        'Summe 1,14',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[1].totalCents, 25);
      expect(r.items[1].name.toLowerCase(), contains('pfand'));
    });

    test('Pfand-Position alleine (nur Wort Pfand, kein Kontextname)', () {
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'Brot 1,99',
        'Pfand -0,25',
      ]);
      expect(r.items, hasLength(2));
      expect(r.items[1].totalCents, -25);
    });

    test('Bon3-Szenario: WAGNER PICCOLINI + .2 Stk x + Leergut', () {
      // Reproduziert das Screenshot-Problem von Bon3:
      //  - WAGNER PICCOLINI 6,98 mit Mengenzeile '.2 Stk x 3,49'
      //    (fuehrender OCR-Punkt)
      //  - Pfand-Rueckgabe als negative Position
      // Erwartet: kein Phantom-Item '.2 Stk x', Pfand mit korrektem
      // Vorzeichen.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'WAGNER PICCOLINI 6,98 B',
        '.2 Stk x  3,49',
        'PIZZA AMORE MOZZ 3,79 B',
        'KNABE KOLA ZERO 2,38 B',
        'LEERGUT -2,99',
        'SUMME 10,16',
      ]);
      // 3 echte Positionen + 1 Leergut, KEIN Phantom-Item '.2 Stk x'.
      expect(r.items, hasLength(4));
      expect(r.items[0].name, 'WAGNER PICCOLINI');
      expect(r.items[0].quantity, 2);
      expect(r.items[0].unitPriceCents, 349);
      expect(r.items[0].totalCents, 698);
      expect(r.items[1].name, 'PIZZA AMORE MOZZ');
      expect(r.items[1].totalCents, 379);
      expect(r.items[2].name, 'KNABE KOLA ZERO');
      expect(r.items[2].totalCents, 238);
      expect(r.items[3].totalCents, -299);
      expect(r.totalCents, 1016);
      // Items-Summe entspricht jetzt dem Bon-Total:
      final itemSum = r.items.fold<int>(0, (s, i) => s + i.totalCents);
      expect(itemSum, 1016);
    });

    test('PFAND-Zeile mit Stern-Marker am Ende: "0,25 B *"', () {
      // Bon4-Szenario: REWE druckt PFAND mit Steuerklasse B und einem
      // zusaetzlichen '*'-Marker. Der Preis-Regex muss den '*' nach dem
      // Marker tolerieren.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'SALATBOWL VETA 3,49 B',
        'BIO KEFIR 1,5% 1,59 B',
        'PFAND 0,25 EURO  0,25 B *',
        'SKYR 0,2% 1,45 B',
        'BIO TK HEIDELBEE 3,69 B',
        'SUMME EUR 10,47',
      ]);
      expect(r.items, hasLength(5));
      expect(r.items[0].name, 'SALATBOWL VETA');
      expect(r.items[0].totalCents, 349);
      expect(r.items[1].name, 'BIO KEFIR 1,5%');
      expect(r.items[1].totalCents, 159);
      expect(r.items[2].totalCents, 25);
      expect(r.items[2].name.toLowerCase(), contains('pfand'));
      expect(r.items[3].name, 'SKYR 0,2%');
      expect(r.items[3].totalCents, 145);
      expect(r.items[4].name, 'BIO TK HEIDELBEE');
      expect(r.items[4].totalCents, 369);
      expect(r.totalCents, 1047);
      final itemSum = r.items.fold<int>(0, (s, i) => s + i.totalCents);
      expect(itemSum, 1047);
    });

    test('Stern-Marker hinter normalem Item: "0,25 *"', () {
      // Auch fuer Nicht-Pfand-Zeilen mit alleinstehendem '*'-Marker.
      final r = ReceiptParser.parse(<String>[
        'REWE',
        'TEST-PRODUKT 1,99 *',
        'SUMME 1,99',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'TEST-PRODUKT');
      expect(r.items[0].totalCents, 199);
    });

    test('Baecker-Layout: Mengenzeile mit Total am Ende, Name auf Folgezeile',
        () {
      // Bon5 (Baeckerei): das umgekehrte Layout.
      //   1 x 4,15 EUR        4,15 EUR
      //   Dinkel-Deern
      //   2 x 1,15 EUR        2,30 EUR
      //   Seemoehren
      //   1 x 3,00 EUR        3,00 EUR
      //   Kaffee to go, gross
      //   Total               9,45 EUR
      final r = ReceiptParser.parse(<String>[
        'Westerstr. 19',
        '28199 Bremen',
        'Rechnung',
        '1 x 4,15 €    4,15 €',
        'Dinkel-Deern',
        '2 x 1,15 €    2,30 €',
        'Seemoehren',
        '1 x 3,00 €    3,00 €',
        'Kaffee to go, gross',
        'Total 9,45 €',
      ]);
      expect(r.items, hasLength(3));
      expect(r.items[0].name, 'Dinkel-Deern');
      expect(r.items[0].quantity, 1);
      expect(r.items[0].unitPriceCents, 415);
      expect(r.items[0].totalCents, 415);
      expect(r.items[1].name, 'Seemoehren');
      expect(r.items[1].quantity, 2);
      expect(r.items[1].unitPriceCents, 115);
      expect(r.items[1].totalCents, 230);
      expect(r.items[2].name, 'Kaffee to go, gross');
      expect(r.items[2].quantity, 1);
      expect(r.items[2].unitPriceCents, 300);
      expect(r.items[2].totalCents, 300);
      expect(r.totalCents, 945);
    });

    test('Baecker-Layout: keine Folge-Name-Zeile -> Item wird verworfen', () {
      // Edge case: '1 x 2,00 EUR  2,00 EUR' ist letzte Zeile. Ohne
      // Folgename darf kein Phantom-Item entstehen.
      final r = ReceiptParser.parse(<String>[
        'BAECKER',
        '1 x 4,15 €    4,15 €',
        'Brezel',
        '1 x 2,00 €    2,00 €',
      ]);
      expect(r.items, hasLength(1));
      expect(r.items[0].name, 'Brezel');
    });

  });
}
