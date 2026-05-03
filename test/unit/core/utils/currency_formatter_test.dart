import 'package:bonbudget/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Diese Tests sind bewusst klein und sinnvoll: sie sichern die
/// Geld-Logik ab. Beträge werden intern in Cent (int) gehalten,
/// damit kein Floating-Point-Rundungsfehler entsteht. Wenn diese
/// Konvention je gebrochen wird, schlagen die Tests an.
void main() {
  group('CurrencyFormatter.formatCents', () {
    test('formatiert 1234 Cent als "12,34 €" für de_DE', () {
      final result = CurrencyFormatter.formatCents(1234);
      // intl rendert das Symbol je nach Locale unterschiedlich.
      // Wir prüfen die Kernbestandteile, ohne uns auf exaktes
      // Spacing festzulegen.
      expect(result, contains('12,34'));
      expect(result, contains('€'));
    });

    test('formatiert 0 Cent korrekt', () {
      final result = CurrencyFormatter.formatCents(0);
      expect(result, contains('0,00'));
    });

    test('formatiert große Beträge mit Tausendertrennzeichen', () {
      final result = CurrencyFormatter.formatCents(12345678);
      // 123.456,78 € im de_DE Format
      expect(result, contains('123.456,78'));
    });
  });

  group('CurrencyFormatter.parseToCents', () {
    test('parst "12,34" zu 1234 Cent', () {
      expect(CurrencyFormatter.parseToCents('12,34'), 1234);
    });

    test('parst "12.34" zu 1234 Cent (Punkt als Trenner)', () {
      expect(CurrencyFormatter.parseToCents('12.34'), 1234);
    });

    test('parst "0" zu 0 Cent', () {
      expect(CurrencyFormatter.parseToCents('0'), 0);
    });

    test('rundet "0,005" korrekt auf 1 Cent (Banker-Rundung wäre 0)', () {
      // .round() rundet kaufmännisch: 0.5 → 1.
      expect(CurrencyFormatter.parseToCents('0,005'), 1);
    });

    test('gibt null bei leerem String', () {
      expect(CurrencyFormatter.parseToCents(''), isNull);
      expect(CurrencyFormatter.parseToCents('   '), isNull);
    });

    test('gibt null bei nicht-numerischer Eingabe', () {
      expect(CurrencyFormatter.parseToCents('abc'), isNull);
    });

    test('gibt null bei negativem Betrag', () {
      expect(CurrencyFormatter.parseToCents('-1,00'), isNull);
    });
  });

  group('Round-Trip', () {
    test('parse → format ergibt konsistente Werte', () {
      const inputs = <String>['1,00', '12,34', '999,99'];
      for (final input in inputs) {
        final cents = CurrencyFormatter.parseToCents(input);
        expect(cents, isNotNull, reason: 'Parse von "$input" sollte gelingen');
        final formatted = CurrencyFormatter.formatCents(cents!);
        expect(formatted, contains(input));
      }
    });
  });
}
