import 'package:bonbudget/data/services/category_classifier.dart';
import 'package:bonbudget/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseItemDraft _i(String name, [int cents = 100]) =>
    ExpenseItemDraft(name: name, totalCents: cents);

void main() {
  group('CategoryClassifier', () {
    const c = CategoryClassifier();

    test('leere Items -> null', () {
      expect(c.suggestSlug(<ExpenseItemDraft>[]), isNull);
    });

    test('keine Pattern-Treffer -> null', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('VOELLIG UNBEKANNT'),
          _i('NOCH WAS UNBEKANNTES'),
        ]),
        isNull,
      );
    });

    test('Mehrheit Lebensmittel gewinnt', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('BROT VOLLKORN'),
          _i('BUTTER MILD'),
          _i('GOUDA JUNG'),
          _i('UNBEKANNT'),
        ]),
        'lebensmittel',
      );
    });

    test('Mehrheit Drogerie gewinnt', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('ELMEX 75ML TUBE'),
          _i('DUSCHGEL'),
          _i('TOILETTENPAPIER'),
        ]),
        'drogerie',
      );
    });

    test('Pfand zaehlt zu Lebensmittel (typisch fuer Lebensmittel-Bons)', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('PFAND 0,25 EURO'),
        ]),
        'lebensmittel',
      );
    });

    test('Tanken-Bon: Diesel + Wasch wird Tanken', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('DIESEL E10'),
          _i('AUTOWAESCHE'),
        ]),
        'tanken',
      );
    });

    test('Real-Bon-Mix: REWE-Lebensmittel mit ein paar Drogerie-Items', () {
      // Reproduziert Bon 1 (Rispentomate-Bon, 95,92 EUR): viele Lebens-
      // mittel-Items, ein paar Drogerie-Items dazwischen. Lebensmittel
      // sollte gewinnen.
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('RISPENTOMATE'),
          _i('ROTKOHL'),
          _i('JA! GOUDA JUNG'),
          _i('BIO GOUDA GER.'),
          _i('GRANA PADANO'),
          _i('PLANTED STEAK'),
          _i('AVOCADO ANGER.'),
          _i('GURKE BIO'),
          _i('10ER BIO EIER'),
          _i('BIO TK HEIDELBEE'),
          // Drogerie:
          _i('ELMEX 75ML TUBE'),
          _i('MUELLBTL. OEKO'),
          // Pfand:
          _i('PFAND 0,25 EURO'),
        ]),
        'lebensmittel',
      );
    });

    test('Pro Item nur ein Slug zaehlen (verhindert Mehrfach-Kollision)', () {
      // 'KAFFEE' matcht 'lebensmittel' (Tee/Kaffee). 'TO GO' matcht
      // 'restaurant'. Lebensmittel zaehlt zuerst (Map-Reihenfolge),
      // restaurant nicht zusaetzlich beim selben Item.
      final r = c.suggestSlug(<ExpenseItemDraft>[
        _i('KAFFEE TO GO'),
        _i('CROISSANT'),
      ]);
      // Beide treffen lebensmittel zuerst -> 2 Stimmen lebensmittel.
      expect(r, 'lebensmittel');
    });

    test('Case-insensitive', () {
      expect(
        c.suggestSlug(<ExpenseItemDraft>[
          _i('Brot Vollkorn'),
          _i('butter mild'),
        ]),
        'lebensmittel',
      );
    });
  });
}
