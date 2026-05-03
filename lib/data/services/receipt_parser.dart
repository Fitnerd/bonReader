import '../../domain/repositories/expense_repository.dart';

/// Resultat der heuristischen Bon-Auswertung.
///
/// Alle Felder sind optional / mit Defaults, weil OCR-Output sehr
/// variabel ist. Der Nutzer bekommt das Formular vorbefuellt und kann
/// Falscherkennungen korrigieren.
class ParsedReceipt {
  const ParsedReceipt({
    required this.merchant,
    required this.occurredAt,
    required this.totalCents,
    required this.items,
    required this.confidence,
  });

  final String merchant;
  final DateTime occurredAt;

  /// Bevorzugt der erkannte „Summe / Gesamt"-Betrag. Faellt sonst auf
  /// die Summe der Positionen zurueck. 0 wenn nichts erkannt wurde.
  final int totalCents;

  final List<ExpenseItemDraft> items;

  /// Heuristische Sicherheit (0..1). Niedrige Werte → Hinweis im UI,
  /// dass der Nutzer pruefen soll.
  final double confidence;
}

/// Heuristischer Parser fuer Kassenbons.
///
/// Wir halten das bewusst simpel und regel-basiert:
/// * Haendler: erste sichtbare „dicke" Zeile, die wie ein Name aussieht.
/// * Datum: erstes Vorkommen `DD.MM.YYYY` oder `DD.MM.YY`.
/// * Total: Zeile mit „Summe", „Gesamt", „Total", „EUR" oder „Bar".
/// * Positionen: Zeilen mit einem Preis am Ende (`d+,dd`), die NICHT
///   als Total / Steuer / Rueckgeld erkannt sind.
class ReceiptParser {
  ReceiptParser._();

  static final RegExp _datePattern = RegExp(
    r'\b(0?[1-9]|[12][0-9]|3[01])\.(0?[1-9]|1[0-2])\.(\d{2,4})\b',
  );

  /// Preis am Ende einer Zeile, optional mit fuehrendem `EUR` / `€`.
  /// Erlaubt: `1,23`, `12,34`, `123,45`, `1.234,56` (deutsche Notation).
  static final RegExp _priceAtEnd = RegExp(
    r'(?:EUR\s*|€\s*)?(\d{1,4}(?:[.\s]\d{3})*[,.]\d{2})\s*(?:EUR|€)?\s*[A-Z]?\s*$',
  );

  /// Stueckzahl + Einzelpreis am Anfang einer Zeile, z. B.
  /// `2 X 1,99 = 3,98` oder `2x 1,99`.
  static final RegExp _quantityLine = RegExp(
    r'^(\d+)\s*[xX*]\s*(\d{1,3}[,.]\d{2})',
  );

  /// Zeilen, die wir nicht als Position zaehlen.
  /// Wichtig: Reihenfolge zaehlt nicht, Gross-/Kleinschreibung egal.
  static const List<String> _ignoreSubstrings = <String>[
    'summe', 'gesamt', 'total', 'zwischensumme', 'mwst', 'ust',
    'rueckgeld', 'rückgeld', 'gegeben', 'bar', 'ec-karte', 'visa', 'mastercard',
    'kunden-nr', 'kundennr', 'beleg-nr', 'belegnr', 'bon-nr', 'bonnr',
    'datum', 'uhrzeit', 'kasse', 'kassierer', 'filiale', 'ihre',
    'tse', 'qr-code', 'serien-nr', 'transaktion', 'pfand zurueck',
    'steuer', 'netto', 'brutto', 'eur',
  ];

  static const List<String> _totalKeywords = <String>[
    'summe', 'gesamt', 'total', 'zu zahlen', 'zahlbetrag',
  ];

  /// Parser-Einstieg.
  static ParsedReceipt parse(
    List<String> lines, {
    DateTime? fallbackDate,
  }) {
    final cleanedLines = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final merchant = _detectMerchant(cleanedLines);
    final date = _detectDate(cleanedLines) ?? fallbackDate ?? DateTime.now();
    final totalCents = _detectTotalCents(cleanedLines);
    final items = _detectItems(cleanedLines);

    final fallbackTotal =
        items.fold<int>(0, (sum, i) => sum + i.totalCents);
    final effectiveTotal = totalCents ?? fallbackTotal;

    var confidence = 0.0;
    if (date != null) confidence += 0.25;
    if (totalCents != null) confidence += 0.4;
    if (items.isNotEmpty) confidence += 0.25;
    if (merchant.isNotEmpty) confidence += 0.1;

    return ParsedReceipt(
      merchant: merchant,
      occurredAt: date,
      totalCents: effectiveTotal,
      items: items,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  // ─────────────────────────────────────────── Haendler
  static String _detectMerchant(List<String> lines) {
    for (final raw in lines.take(5)) {
      final l = raw.trim();
      if (l.length < 3) continue;
      // Vermeiden: Zeilen, die wie Adressen / Telefon / Datum aussehen.
      if (_datePattern.hasMatch(l)) continue;
      if (RegExp(r'^\d').hasMatch(l)) continue;
      if (l.toLowerCase().contains('strasse') ||
          l.toLowerCase().contains('straße') ||
          l.toLowerCase().contains('gmbh')) {
        // Erst- oder Zweitwahl Haendler, aber bevorzugt davor.
        continue;
      }
      // Plausible Haendler-Zeile: viele Buchstaben, wenige Sonderzeichen.
      final letters = RegExp(r'[A-Za-zÄÖÜäöüß]').allMatches(l).length;
      if (letters >= 3) return l;
    }
    return lines.isNotEmpty ? lines.first : '';
  }

  // ─────────────────────────────────────────── Datum
  static DateTime? _detectDate(List<String> lines) {
    for (final l in lines) {
      final m = _datePattern.firstMatch(l);
      if (m == null) continue;
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final yearRaw = int.parse(m.group(3)!);
      final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      try {
        return DateTime(year, month, day);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────── Total
  static int? _detectTotalCents(List<String> lines) {
    int? candidate;
    // Wir gehen von unten, weil das Total ueblicherweise am Ende des Bons steht.
    for (final l in lines.reversed) {
      final lower = l.toLowerCase();
      final hasTotalKeyword =
          _totalKeywords.any((k) => lower.contains(k));
      if (!hasTotalKeyword) continue;
      final cents = _priceFromLine(l);
      if (cents != null) {
        candidate = cents;
        break;
      }
    }
    return candidate;
  }

  // ─────────────────────────────────────────── Positionen
  static List<ExpenseItemDraft> _detectItems(List<String> lines) {
    final items = <ExpenseItemDraft>[];
    String? pendingQuantityName;
    int? pendingQuantity;
    int? pendingUnitPrice;

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final lower = raw.toLowerCase();

      // Mengenzeile: `2 X 1,99` → merken, Position folgt evtl. in naechster Zeile
      final qMatch = _quantityLine.firstMatch(raw);
      if (qMatch != null) {
        pendingQuantity = int.tryParse(qMatch.group(1)!);
        pendingUnitPrice =
            _priceToCents(qMatch.group(2)!);
        pendingQuantityName = null;
        continue;
      }

      // Ignorieren?
      if (_ignoreSubstrings.any(lower.contains)) {
        pendingQuantity = null;
        pendingUnitPrice = null;
        continue;
      }

      // Datum allein → ueberspringen
      if (_datePattern.hasMatch(lower) &&
          !_priceAtEnd.hasMatch(raw.trim())) {
        continue;
      }

      // Preis am Ende?
      final cents = _priceFromLine(raw);
      if (cents == null) {
        // koennte ein Positionsname VOR der Mengen-/Preiszeile sein
        pendingQuantityName = raw;
        continue;
      }

      // Plausibilitaet: hohe Preise (> 1000 €) sind selten echt
      if (cents > 100000) continue;

      // Name extrahieren: alles ohne Preis am Ende
      var name = raw.replaceFirst(_priceAtEnd, '').trim();
      // Trailing Steuerklassen-Marker (A/B/*) entfernen
      name = name.replaceAll(RegExp(r'[\*\s]+[ABab]\s*$'), '').trim();
      if (name.isEmpty) name = pendingQuantityName ?? '';
      if (name.isEmpty) continue;

      final qty = pendingQuantity ?? 1;
      final unit = pendingUnitPrice ?? cents;

      items.add(ExpenseItemDraft(
        name: name,
        quantity: qty.toDouble(),
        unitPriceCents: unit,
        totalCents: cents,
      ));

      pendingQuantity = null;
      pendingUnitPrice = null;
      pendingQuantityName = null;
    }
    return items;
  }

  // ─────────────────────────────────────────── Helpers
  static int? _priceFromLine(String line) {
    final m = _priceAtEnd.firstMatch(line.trim());
    if (m == null) return null;
    return _priceToCents(m.group(1)!);
  }

  /// `1.234,56` → 123456, `12,34` → 1234, `1234.56` (en) → 123456.
  static int? _priceToCents(String raw) {
    var s = raw.replaceAll(' ', '');
    // Wenn sowohl `.` als auch `,` vorkommen, ist `.` Tausender-Trenner.
    if (s.contains('.') && s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',') && !s.contains('.')) {
      s = s.replaceAll(',', '.');
    }
    final v = double.tryParse(s);
    if (v == null) return null;
    if (v < 0) return null;
    return (v * 100).round();
  }
}
