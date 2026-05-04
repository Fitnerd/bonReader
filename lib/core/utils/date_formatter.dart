/// Zentrale Datums-Formatierung. Entfernt das ueberall duplizierte
/// `n.toString().padLeft(2, '0')`-Pattern aus der Code-Basis.
class DateFormatter {
  const DateFormatter._();

  /// "TT.MM.JJJJ" - der in DACH gewohnte Stil.
  static String dmy(DateTime d) =>
      '${_pad2(d.day)}.${_pad2(d.month)}.${d.year}';

  /// "TT.MM." (ohne Jahr) - z. B. fuer Bereiche im selben Jahr.
  static String dm(DateTime d) => '${_pad2(d.day)}.${_pad2(d.month)}.';

  /// "JJJJ-MM-TT" - sortier-/maschinen-freundlich.
  static String iso(DateTime d) =>
      '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
