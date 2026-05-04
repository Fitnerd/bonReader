import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formatiert Geldbeträge konsistent in der gesamten App.
///
/// Intern werden Beträge immer in **Cent als int** gehalten,
/// damit es keine Rundungsfehler durch Floating-Point gibt.
/// Diese Klasse konvertiert für die Anzeige.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formatiert Cent-Betrag in lesbare Währungs-Darstellung.
  /// `1234` (Cent) → `"12,34 €"` für Locale `de_DE`.
  static String formatCents(
    int cents, {
    String locale = AppConstants.defaultLocale,
    String currencyCode = AppConstants.defaultCurrencyCode,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: _symbolFor(currencyCode),
      decimalDigits: 2,
    );
    return formatter.format(cents / 100);
  }

  /// Parst eine vom Nutzer eingegebene Zahl ("12,34" oder "12.34")
  /// zu Cent. Gibt `null` zurück, wenn ungültig.
  static int? parseToCents(String input) {
    if (input.trim().isEmpty) return null;
    final normalized = input.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    // Auf 2 Nachkommastellen runden, dann in Cent.
    return (value * 100).round();
  }

  static String _symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return r'$';
      case 'GBP':
        return '£';
      case 'CHF':
        return 'CHF';
      default:
        return code;
    }
  }
}
