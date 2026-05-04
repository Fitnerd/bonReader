import '../constants/app_constants.dart';

/// Formatierung und Parsing von Stueckzahlen.
///
/// Speicherform: Integer mit Faktor 1000 (1500 = 1,5).
/// Anzeigeform: deutsches Komma als Dezimaltrenner, ohne Trailing-Nullen.
class QuantityFormatter {
  const QuantityFormatter._();

  /// Formatiert eine Milli-Stueckzahl als deutschen Anzeigestring.
  /// 1000 → "1", 1500 → "1,5", 1250 → "1,25", 250 → "0,25".
  static String format(int quantityMilli) {
    final whole = quantityMilli ~/ AppConstants.quantityMilliPerUnit;
    final remainder =
        quantityMilli.remainder(AppConstants.quantityMilliPerUnit).abs();
    if (remainder == 0) return whole.toString();
    final decimals = remainder
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return '$whole,$decimals';
  }

  /// Parst eine deutsche/internationale Eingabe zu Milli-Stueckzahl.
  /// Akzeptiert "1", "1,5", "1.5", "1,500", "0,25", " 1.250 ".
  /// Gibt null zurueck wenn ungueltig oder negativ.
  static int? parseToMilli(String raw) {
    final s = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    if (v == null) return null;
    if (v < 0) return null;
    return (v * AppConstants.quantityMilliPerUnit).round();
  }
}
