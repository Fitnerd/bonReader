import '../../core/constants/app_constants.dart';
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

  /// Bevorzugt der erkannte ,,Summe / Gesamt"-Betrag. Faellt sonst auf
  /// die Summe der Positionen zurueck. 0 wenn nichts erkannt wurde.
  final int totalCents;

  final List<ExpenseItemDraft> items;

  /// Heuristische Sicherheit (0..1). Niedrige Werte -> Hinweis im UI,
  /// dass der Nutzer pruefen soll.
  final double confidence;
}

/// Heuristischer Parser fuer Kassenbons.
class ReceiptParser {
  ReceiptParser._();

  static final RegExp _datePattern = RegExp(
    r'\b(0?[1-9]|[12][0-9]|3[01])\s*\.\s*(0?[1-9]|1[0-2])\s*\.\s*(\d{2,4})\b',
  );

  /// Preis am Ende einer Zeile, optional mit fuehrendem `EUR` / Euro-Zeichen
  /// und optionalen Steuerklassen-Markern danach (`A`, `B`, `*` oder
  /// Kombinationen wie `B *`). Bis zu 3 Marker-Gruppen werden toleriert.
  static final RegExp _priceAtEnd = RegExp(
    r'(?:EUR\s*|€\s*)?(\d{1,4}(?:[.\s]\d{3})*\s*[,.]\s*\d{2})\s*(?:EUR|€)?(?:\s*[A-Z\*]){0,3}\s*$',
  );

  /// Mengenzeile: `2 X 1,99`, `2 Stk x 1,59`, `1 x 4,15 EUR`. Erlaubt
  /// optionale Einheits-Buchstaben zwischen Zahl und x. Tolerant gegen
  /// fuehrenden OCR-Schmutz wie `.2 Stk x 1,59`.
  /// Mengenzeile: `2 X 1,99`, `2 Stk x 1,59`, `1 x 4,15 EUR`, oder
  /// Dezimal-Menge fuer kg-Ware: `1,558 kg x 2,49 EUR/kg`.
  /// Erlaubt optionale Einheits-Buchstaben zwischen Zahl und x.
  /// Tolerant gegen fuehrenden OCR-Schmutz wie `.2 Stk x 1,59`.
  static final RegExp _quantityLine = RegExp(
    r'^[\s.,;:_\-]*(\d+(?:\s*[,.]\s*\d+)?)\s*(?:[A-Za-z]+\s*)?[xX*]\s*(\d{1,3}\s*[,.]\s*\d{2})',
  );

  /// Pfand-/Leergut-Zeile.
  static final RegExp _pfandKeyword = RegExp(
    r'\b(pfand|leergut|einwegpfand|mehrwegpfand)\b',
    caseSensitive: false,
  );

  /// Preis am Ende mit optionalem Vorzeichen davor oder nachgestelltem Minus.
  static final RegExp _signedPriceAtEnd = RegExp(
    r'(?:EUR\s*|€\s*)?(-?\s*\d{1,4}(?:[.\s]\d{3})*\s*[,.]\s*\d{2}\s*-?)\s*(?:EUR|€)?(?:\s*[A-Z\*]){0,3}\s*$',
  );

  /// Zeilen, die wir nicht als Position zaehlen.
  /// HINWEIS: 'pfand' / 'leergut' sind hier bewusst NICHT enthalten -
  /// die werden als eigene (ggf. negative) Position behandelt.
  static const List<String> _ignoreSubstrings = <String>[
    'summe', 'gesamt', 'total', 'zwischensumme', 'mwst', 'ust',
    'rueckgeld', 'gegeben', 'geg.', 'bar',
    'ec-karte', 'ec-cash', 'eccash', 'visa', 'mastercard',
    'kartenzahlung', 'contactless', 'girocard', 'paypal',
    'kunden-nr', 'kundennr', 'beleg-nr', 'belegnr', 'bon-nr', 'bonnr',
    'trace-nr', 'tracenr', 'terminal-id', 'terminalid', 'pos-info',
    'as-zeit', 'kundenbeleg', 'haendlerbeleg', 'haendler-beleg',
    'datum', 'uhrzeit', 'kasse', 'kassierer', 'filiale', 'ihre',
    'tse', 'qr-code', 'serien-nr', 'transaktion', 'rechnung',
    'steuer', 'netto', 'brutto', 'eur', 'betrag', 'nettoumsatz',
    'zahlung erfolgt', 'zahlung erfolgreich',
    'beginn/ende', 'zertifikat', 'signaturzaehler',
  ];

  static const List<String> _totalKeywords = <String>[
    'summe', 'gesamt', 'total', 'zu zahlen', 'zahlbetrag',
  ];

  static const List<String> _knownStores = <String>[
    'REWE', 'EDEKA', 'ALDI', 'LIDL', 'KAUFLAND', 'NETTO', 'PENNY',
    'BUDNI', 'DM', 'ROSSMANN', 'MUELLER', 'NORMA', 'REAL', 'COMBI',
    'TEGUT', 'METRO', 'GLOBUS',
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
    final detectedDate = _detectDate(cleanedLines);
    final date = detectedDate ?? fallbackDate ?? DateTime.now();
    final totalCents = _detectTotalCents(cleanedLines);
    final items = _detectItems(cleanedLines);

    final fallbackTotal =
        items.fold<int>(0, (sum, i) => sum + i.totalCents);
    final effectiveTotal = totalCents ?? fallbackTotal;

    var confidence = 0.0;
    if (items.isNotEmpty) confidence += 0.40;
    if (totalCents != null) confidence += 0.30;
    if (detectedDate != null) confidence += 0.15;
    if (merchant.isNotEmpty) confidence += 0.10;
    final upper = cleanedLines.take(8).map((l) => l.toUpperCase()).join(' ');
    if (_knownStores.any(upper.contains)) confidence += 0.05;

    return ParsedReceipt(
      merchant: merchant,
      occurredAt: date,
      totalCents: effectiveTotal,
      items: items,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  // --------------------------------------------- Haendler
  static String _detectMerchant(List<String> lines) {
    for (final raw in lines.take(8)) {
      final trimmed = raw.trim();
      final upper = trimmed.toUpperCase();
      for (final store in _knownStores) {
        if (upper.contains(store)) return trimmed;
      }
    }
    for (final raw in lines.take(5)) {
      final l = raw.trim();
      if (l.length < 3) continue;
      if (_datePattern.hasMatch(l)) continue;
      if (RegExp(r'^\d').hasMatch(l)) continue;
      if (l.toLowerCase().contains('strasse') ||
          l.toLowerCase().contains('gmbh')) {
        continue;
      }
      final letters =
          RegExp(r'[A-Za-zÄÖÜäöüß]').allMatches(l).length;
      if (letters >= 3) return l;
    }
    return lines.isNotEmpty ? lines.first : '';
  }

  // --------------------------------------------- Datum
  static DateTime? _detectDate(List<String> lines) {
    for (final l in lines) {
      final m = _datePattern.firstMatch(l);
      if (m == null) continue;
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final yearRaw = int.parse(m.group(3)!);
      final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      // `DateTime(year, month, day)` wirft fuer ungueltige Tage NICHT
      // sondern rollt still um (z. B. 31.02.2026 -> 03.03.2026). Wir
      // muessen nach dem Konstruieren pruefen, ob die Felder erhalten
      // geblieben sind, sonst die naechste Zeile probieren.
      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
    }
    return null;
  }

  // --------------------------------------------- Total
  static int? _detectTotalCents(List<String> lines) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final lower = lines[i].toLowerCase();
      final hasTotalKeyword =
          _totalKeywords.any((k) => lower.contains(k));
      if (!hasTotalKeyword) continue;

      final sameLine = _priceFromLine(lines[i]);
      if (sameLine != null) return sameLine;

      for (final offset in const <int>[1, -1, 2, -2]) {
        final j = i + offset;
        if (j < 0 || j >= lines.length) continue;
        final neighbour = _priceFromLine(lines[j]);
        if (neighbour != null) return neighbour;
      }
    }
    return null;
  }

  // --------------------------------------------- Positionen
  static List<ExpenseItemDraft> _detectItems(List<String> lines) {
    final items = <ExpenseItemDraft>[];
    String? pendingName;

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final lower = raw.toLowerCase();

      // Mengenzeile: `2 X 1,99` (Rewe-Layout, retroaktiv) oder
      // `1 x 4,15 EUR    4,15 EUR` (Baecker-Layout, neues Item +
      // Name folgt auf naechster Zeile).
      final qMatch = _quantityLine.firstMatch(raw);
      if (qMatch != null) {
        final qtyMilli = _parseQuantityMilli(qMatch.group(1)!);
        final unit = _priceToCents(qMatch.group(2)!);

        // Hat die Zeile nach dem Mengen-Match noch einen separaten
        // Total-Preis? -> Baecker-Layout.
        final tail = raw.substring(qMatch.end);
        final tailPrice = _priceFromLine(tail);

        if (tailPrice != null && unit != null) {
          // Baecker-Layout: lege Item ohne Namen an. Der Name wird
          // aus der naechsten textuellen Zeile gefuellt (siehe unten).
          items.add(ExpenseItemDraft(
            name: '',
            quantityMilli: qtyMilli,
            unitPriceCents: unit,
            totalCents: tailPrice,
          ));
          pendingName = null;
          continue;
        }

        // Rewe-Layout: retroaktiv das letzte Item updaten.
        if (items.isNotEmpty && unit != null) {
          final last = items.last;
          items[items.length - 1] = ExpenseItemDraft(
            name: last.name,
            quantityMilli: qtyMilli,
            unitPriceCents: unit,
            totalCents: last.totalCents,
          );
        }
        pendingName = null;
        continue;
      }

      // Pfand / Leergut: eigene Behandlung mit Vorzeichen.
      if (_pfandKeyword.hasMatch(lower)) {
        final signed = _signedPriceFromLine(raw);
        if (signed != null && signed.abs() <= AppConstants.receiptParserMaxCents) {
          var name = raw.replaceFirst(_signedPriceAtEnd, '').trim();
          name = name.replaceAll(RegExp(r'[\*\s]+[ABab]\s*$'), '').trim();
          if (name.isEmpty) name = signed < 0 ? 'Leergut' : 'Pfand';
          items.add(ExpenseItemDraft(
            name: name,
            quantityMilli: AppConstants.quantityMilliPerUnit,
            unitPriceCents: signed,
            totalCents: signed,
          ));
        }
        pendingName = null;
        continue;
      }

      if (_ignoreSubstrings.any(lower.contains)) {
        pendingName = null;
        continue;
      }

      if (_datePattern.hasMatch(lower) &&
          !_priceAtEnd.hasMatch(raw.trim())) {
        pendingName = null;
        continue;
      }

      final cents = _priceFromLine(raw);
      if (cents == null) {
        // Kein Preis. Zwei Faelle:
        //  (a) Letztes Item hat leeren Namen (Baecker-Layout, Name
        //      kommt nach der Mengenzeile) -> fuelle ihn jetzt.
        //  (b) Sonst als pendingName fuer kommende Preiszeile merken.
        final trimmed = raw.trim();
        if (trimmed.length >= 2 &&
            RegExp(r'[A-Za-zÄÖÜäöüß]').hasMatch(trimmed)) {
          if (items.isNotEmpty && items.last.name.isEmpty) {
            final last = items.last;
            items[items.length - 1] = ExpenseItemDraft(
              name: trimmed,
              quantityMilli: last.quantityMilli,
              unitPriceCents: last.unitPriceCents,
              totalCents: last.totalCents,
            );
          } else {
            pendingName = trimmed;
          }
        }
        continue;
      }

      if (cents > AppConstants.receiptParserMaxCents) {
        pendingName = null;
        continue;
      }

      var name = raw.replaceFirst(_priceAtEnd, '').trim();
      name = name.replaceAll(RegExp(r'[\*\s]+[ABab]\s*$'), '').trim();

      if (name.isEmpty) {
        name = pendingName ?? '';
      }
      if (name.isEmpty) {
        pendingName = null;
        continue;
      }

      items.add(ExpenseItemDraft(
        name: name,
        quantityMilli: AppConstants.quantityMilliPerUnit,
        unitPriceCents: cents,
        totalCents: cents,
      ));
      pendingName = null;
    }

    // Items mit leerem Namen am Ende sind unfertig (Baecker-Layout, aber
    // kein Name kam) -> entferne sie. (Selten; wenn der Bon abrupt endet.)
    items.removeWhere((it) => it.name.isEmpty);
    return items;
  }

  // --------------------------------------------- Helpers
  static int? _priceFromLine(String line) {
    final m = _priceAtEnd.firstMatch(line.trim());
    if (m == null) return null;
    return _priceToCents(m.group(1)!);
  }

  static int? _signedPriceFromLine(String line) {
    final m = _signedPriceAtEnd.firstMatch(line.trim());
    if (m == null) return null;
    return _signedPriceToCents(m.group(1)!);
  }

  static int? _priceToCents(String raw) {
    var s = raw.replaceAll(' ', '');
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

  static int? _signedPriceToCents(String raw) {
    var s = raw.replaceAll(' ', '');
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    } else if (s.endsWith('-')) {
      negative = true;
      s = s.substring(0, s.length - 1);
    }
    final cents = _priceToCents(s);
    if (cents == null) return null;
    return negative ? -cents : cents;
  }

  /// Parst die Mengen-Angabe einer Mengenzeile. Akzeptiert ganze Zahlen
  /// (`2`) und Dezimal-Mengen (`1,558` oder `1.558` fuer kg-Ware).
  /// Liefert Milli-Stueckzahl (1500 = 1,5).
  static int _parseQuantityMilli(String raw) {
    final s = raw.replaceAll(' ', '').replaceAll(',', '.');
    final v = double.tryParse(s) ?? 1.0;
    return (v * AppConstants.quantityMilliPerUnit).round();
  }
}
