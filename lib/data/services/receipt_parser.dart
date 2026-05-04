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
    r'\b(0?[1-9]|[12][0-9]|3[01])\s*\.\s*(0?[1-9]|1[0-2])\s*\.\s*(\d{2,4})\b',
  );

  /// Preis am Ende einer Zeile, optional mit fuehrendem `EUR` / `€`.
  /// Erlaubt: `1,23`, `12,34`, `123,45`, `1.234,56` (deutsche Notation).
  /// Erlaubt z. B. `1,23`, `12,34`, `123,45`, `1.234,56` und (durch
  /// `\s?` um den Dezimal-Trenner) auch OCR-Schmutz wie `11, 99` oder
  /// `0 ,99` mit Leerzeichen direkt nach dem Komma/Punkt.
  static final RegExp _priceAtEnd = RegExp(
    r'(?:EUR\s*|€\s*)?(\d{1,4}(?:[.\s]\d{3})*\s*[,.]\s*\d{2})\s*(?:EUR|€)?\s*[A-Z]?\s*$',
  );

  /// Stueckzahl + Einzelpreis am Anfang einer Zeile, z. B.
  /// `2 X 1,99 = 3,98` oder `2x 1,99`.
  /// Mengenzeile: `2 X 1,99`, `2 Stk x 1,59`, `2 stk * 0,99`. Erlaubt
  /// optionale Einheits-Buchstaben (Stk/St/k g/g) zwischen Zahl und x.
  static final RegExp _quantityLine = RegExp(
    r'^(\d+)\s*(?:[A-Za-z]+\s*)?[xX*]\s*(\d{1,3}[,.]\d{2})',
  );

  /// Zeilen, die wir nicht als Position zaehlen.
  /// Wichtig: Reihenfolge zaehlt nicht, Gross-/Kleinschreibung egal.
  static const List<String> _ignoreSubstrings = <String>[
    'summe', 'gesamt', 'total', 'zwischensumme', 'mwst', 'ust',
    'rueckgeld', 'rückgeld', 'gegeben', 'geg.', 'bar',
    // Bezahlmethoden / EC-Cash-Spuren
    'ec-karte', 'ec-cash', 'eccash', 'visa', 'mastercard',
    'kartenzahlung', 'contactless', 'girocard', 'paypal',
    // Bon-Metadaten
    'kunden-nr', 'kundennr', 'beleg-nr', 'belegnr', 'bon-nr', 'bonnr',
    'trace-nr', 'tracenr', 'terminal-id', 'terminalid', 'pos-info',
    'as-zeit', 'kundenbeleg', 'haendlerbeleg', 'haendler-beleg',
    'datum', 'uhrzeit', 'kasse', 'kassierer', 'filiale', 'ihre',
    'tse', 'qr-code', 'serien-nr', 'transaktion', 'pfand zurueck',
    'steuer', 'netto', 'brutto', 'eur', 'betrag',
    'zahlung erfolgt', 'zahlung erfolgreich',
  ];

  static const List<String> _totalKeywords = <String>[
    'summe', 'gesamt', 'total', 'zu zahlen', 'zahlbetrag',
  ];
  /// Bekannte Lebensmittel-/Drogerie-Ketten in DE. Hilft, den Haendler
  /// auch dann zu erkennen, wenn die erste Zeile keine plausible Form
  /// hat - und liefert einen kleinen Confidence-Bonus.
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

    // Confidence-Gewichtung: Items sind das Wichtigste fuer den Nutzer,
    // Datum am wenigsten kritisch (faellt sauber auf 'heute' zurueck).
    //   items   = 0.40
    //   total   = 0.30
    //   date    = 0.15
    //   merchant= 0.10
    //   bekannter Haendler   = +0.05 Bonus
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

  // ─────────────────────────────────────────── Haendler
  static String _detectMerchant(List<String> lines) {
    // Vorrang: Zeile mit bekanntem Ketten-Namen finden, irgendwo in den
    // ersten 8 Zeilen. Wir geben die GANZE TRIMMED ZEILE zurueck (nicht
    // nur den Ketten-Namen), damit Varianten wie 'ALDI SUED', 'REWE
    // City' oder 'EDEKA neukauf' erhalten bleiben.
    for (final raw in lines.take(8)) {
      final trimmed = raw.trim();
      final upper = trimmed.toUpperCase();
      for (final store in _knownStores) {
        if (upper.contains(store)) return trimmed;
      }
    }
    // Fallback: erste plausible Zeile in den ersten 5.
    for (final raw in lines.take(5)) {
      final l = raw.trim();
      if (l.length < 3) continue;
      if (_datePattern.hasMatch(l)) continue;
      if (RegExp(r'^\d').hasMatch(l)) continue;
      if (l.toLowerCase().contains('strasse') ||
          l.toLowerCase().contains('straße') ||
          l.toLowerCase().contains('gmbh')) {
        continue;
      }
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
    // Wir gehen von unten, weil das Total ueblicherweise am Ende des Bons steht.
    // Wenn die Keyword-Zeile selbst keinen Preis hat (z. B. SUMME ist auf
    // einer eigenen Zeile, der Wert daneben), schauen wir auch eine bzw.
    // zwei Zeilen weiter.
    for (var i = lines.length - 1; i >= 0; i--) {
      final lower = lines[i].toLowerCase();
      final hasTotalKeyword =
          _totalKeywords.any((k) => lower.contains(k));
      if (!hasTotalKeyword) continue;

      final sameLine = _priceFromLine(lines[i]);
      if (sameLine != null) return sameLine;

      // Multi-line: Wert kann eine oder zwei Zeilen darueber/darunter stehen.
      for (final offset in const <int>[1, -1, 2, -2]) {
        final j = i + offset;
        if (j < 0 || j >= lines.length) continue;
        final neighbour = _priceFromLine(lines[j]);
        if (neighbour != null) return neighbour;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────── Positionen
  static List<ExpenseItemDraft> _detectItems(List<String> lines) {
    final items = <ExpenseItemDraft>[];
    // Multi-Line-Assembly: ML Kit splittet bei grossen Whitespace-Bloecken
    // 'RISPENTOMATE         3,88 B' oft in zwei OCR-Zeilen
    //   'RISPENTOMATE'
    //   '3,88 B'
    // Wir merken uns daher den letzten Namen-ohne-Preis und nutzen ihn,
    // wenn die naechste Zeile nur einen Preis enthaelt.
    String? pendingName;

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final lower = raw.toLowerCase();

      // Mengenzeile: `2 X 1,99` / `2 Stk x 1,59`. Bei deutschen Bons
      // (Rewe, Edeka, Aldi, ...) steht diese Zeile typischerweise NACH
      // dem totalisierten Item, z. B.:
      //   WAGNER PICCOLINI            6,98 B
      //     2 Stk x    3,49
      // Die 6,98 ist der Gesamtbetrag, 2 × 3,49 die Aufschluesselung.
      // Wir aktualisieren daher das zuletzt erfasste Item retroaktiv.
      final qMatch = _quantityLine.firstMatch(raw);
      if (qMatch != null) {
        if (items.isNotEmpty) {
          final last = items.last;
          final qty = int.tryParse(qMatch.group(1)!) ?? 1;
          final unit = _priceToCents(qMatch.group(2)!) ?? last.totalCents;
          items[items.length - 1] = ExpenseItemDraft(
            name: last.name,
            quantity: qty.toDouble(),
            unitPriceCents: unit,
            totalCents: last.totalCents,
          );
        }
        pendingName = null;
        continue;
      }

      // Ignorieren?
      if (_ignoreSubstrings.any(lower.contains)) {
        pendingName = null;
        continue;
      }

      // Datum allein → ueberspringen
      if (_datePattern.hasMatch(lower) &&
          !_priceAtEnd.hasMatch(raw.trim())) {
        pendingName = null;
        continue;
      }

      // Preis am Ende?
      final cents = _priceFromLine(raw);
      if (cents == null) {
        // Diese Zeile ist KEIN Preis - sie koennte aber der Name fuer
        // die naechste Preiszeile sein. Merken.
        // Filter: zu kurz oder rein numerisch -> ignorieren.
        final trimmed = raw.trim();
        if (trimmed.length >= 2 &&
            RegExp(r'[A-Za-zÄÖÜäöüß]').hasMatch(trimmed)) {
          pendingName = trimmed;
        }
        continue;
      }

      // Plausibilitaet: hohe Preise (> 1000 €) sind selten echt
      if (cents > 100000) {
        pendingName = null;
        continue;
      }

      // Name aus dieser Zeile extrahieren (alles ohne Preis am Ende)
      var name = raw.replaceFirst(_priceAtEnd, '').trim();
      // Trailing Steuerklassen-Marker (A/B/*) entfernen
      name = name.replaceAll(RegExp(r'[\*\s]+[ABab]\s*$'), '').trim();

      // Wenn nach dem Strippen nichts mehr uebrig ist, war es eine
      // 'nur-Preis'-Zeile - dann nimm den gemerkten Namen aus der
      // vorigen Zeile.
      if (name.isEmpty) {
        name = pendingName ?? '';
      }
      if (name.isEmpty) {
        pendingName = null;
        continue;
      }

      items.add(ExpenseItemDraft(
        name: name,
        quantity: 1,
        unitPriceCents: cents,
        totalCents: cents,
      ));
      pendingName = null;
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
