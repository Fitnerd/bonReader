import 'package:bonbudget/data/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-End-Tests des Parsers mit synthetischen, aber realistischen
/// Bon-Layouts deutscher Supermaerkte. Ergaenzt die spezifischen
/// receipt_parser_test.dart-Tests um Gesamtbon-Szenarien.
///
/// Bewusst keine echten Bilder + ML Kit hier - das wuerde Geraete-
/// abhaengigkeit einfuehren. ML-Kit-spezifisches Verhalten (Bbox-Merge)
/// wird in einem separaten on-device Test abgedeckt.
void main() {
  group('ReceiptParser - End-to-End-Bons', () {
    test('Rewe-Layout mit Mengen-Items, Pfand und Total', () {
      final result = ReceiptParser.parse(<String>[
        'REWE Markt GmbH',
        'Hauptstr. 1, 10115 Berlin',
        '01.05.2026  10:32',
        '',
        'BROT MEHRKORN  2,49 B',
        '2 X 1,29',
        'TOMATEN  2,58 B',
        'MILCH 1,5%  1,29 B',
        'PFAND LEERGUT  -0,75 A',
        '',
        'SUMME EUR  5,61',
        'GEGEBEN BAR  10,00',
        'RUECKGELD  4,39',
      ]);

      expect(result.merchant, isNotEmpty);
      expect(result.totalCents, 561);
      expect(result.occurredAt.year, 2026);
      expect(result.occurredAt.month, 5);
      expect(result.occurredAt.day, 1);
      expect(result.items, isNotEmpty);

      // Pfand muss als negative Position erkannt werden.
      final pfand = result.items.firstWhere(
        (i) => i.totalCents < 0,
        orElse: () => throw StateError('Pfand-Item nicht erkannt'),
      );
      expect(pfand.totalCents, -75);
    });

    test('Edeka-Layout mit kg-Mengen und Multi-Spalten', () {
      final result = ReceiptParser.parse(<String>[
        'EDEKA',
        '15.05.2026',
        'AEPFEL BRAEBURN  3,98 B',
        '1.598 kg x 2,49 EUR/kg',
        'KAFFEE  6,99 B',
        'SUMME  10,97',
      ]);

      expect(result.totalCents, 1097);
      expect(result.items, isNotEmpty);
      // Mengen-Item: 1.598 kg → 1598 milli
      final apfel = result.items.firstWhere(
        (i) => i.name.toUpperCase().contains('AEPFEL'),
        orElse: () => throw StateError('Apfel-Item nicht erkannt'),
      );
      expect(apfel.quantityMilli, 1598);
      expect(apfel.unitPriceCents, 249);
    });

    test('Bon ohne Total - Confidence niedrig', () {
      final result = ReceiptParser.parse(<String>[
        'KIOSK',
        '03.05.2026',
        'ZEITUNG  3,50',
      ]);
      expect(result.confidence, lessThan(0.7));
    });

    test('Komplett leerer Input crasht nicht', () {
      final result = ReceiptParser.parse(const <String>[]);
      expect(result.items, isEmpty);
      expect(result.totalCents, 0);
      expect(result.merchant, isEmpty);
    });

    test('Datum-Heuristik: 31.02.2026 (ungueltig) wird ignoriert', () {
      final result = ReceiptParser.parse(<String>[
        'REWE',
        '31.02.2026', // ungueltig - sollte uebersprungen werden
        '01.03.2026', // gueltig
        'SUMME  1,00',
      ]);
      expect(result.occurredAt.month, 3);
      expect(result.occurredAt.day, 1);
    });

    test('Plausibilitaet: 9999,99 EUR-Item wird verworfen', () {
      // 9999,99 = 999999 cent > AppConstants.receiptParserMaxCents (100000)
      final result = ReceiptParser.parse(<String>[
        'REWE',
        '01.05.2026',
        'BROT  1,99 B',
        'KOMISCHES_ITEM  9999,99 B',
        'SUMME  1,99',
      ]);
      // 9999,99 wird vom Parser ignoriert (Plausibilitaets-Cap)
      final hasUnreasonable =
          result.items.any((i) => i.totalCents > 100000);
      expect(hasUnreasonable, isFalse);
    });
  });
}
