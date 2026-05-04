import 'dart:io';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Ergebnis einer OCR-Erkennung.
///
/// `lines` ist bereits nach visueller Lese-Reihenfolge sortiert
/// (oben-links nach unten-rechts), inkl. Spalten-Merge: Zeilen aus
/// verschiedenen Spalten, die auf ungefaehr derselben Y-Hoehe liegen,
/// werden zu einer Zeile kombiniert. Das ist wichtig fuer Bons, weil
/// ML Kit Zeilen sonst block-/spaltenweise in beliebiger Reihenfolge
/// liefert (Position + Preis landen in unterschiedlichen Bloecken).
class OcrResult {
  const OcrResult({required this.lines, required this.fullText});

  final List<String> lines;
  final String fullText;
}

abstract class ReceiptOcrService {
  Future<OcrResult> recognize(File image);
  Future<void> dispose();
}

/// On-device OCR via Google ML Kit. Nichts geht ueber das Netzwerk.
class MlKitReceiptOcrService implements ReceiptOcrService {
  MlKitReceiptOcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrResult> recognize(File image) async {
    final input = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(input);

    // Schritt 1: Alle Zeilen mit ihrer Bounding-Box einsammeln.
    final all = <_BboxLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        all.add(_BboxLine(text: text, bbox: line.boundingBox));
      }
    }

    // Schritt 2: Y-Toleranz aus Median-Zeilenhoehe ableiten. Lines, die
    // auf ungefaehr derselben Hoehe stehen, werden als eine Bon-Zeile
    // behandelt.
    if (all.isEmpty) return OcrResult(lines: const <String>[], fullText: recognized.text);
    final heights = <double>[for (final l in all) l.bbox.height];
    heights.sort();
    final medianHeight = heights[heights.length ~/ 2];
    // Y-Toleranz: zwei OCR-Lines gehoeren in dieselbe Bon-Zeile, wenn
    // ihre Top-Y-Differenz unter `medianHeight * 0.6` liegt.
    //
    // Empirisch ermittelt:
    //  - 0.6 funktioniert fuer alle bisher getesteten Bons (Bon 3-6).
    //  - 1.0 verschiebt Preise bei dichten Bons systematisch eine Zeile
    //    nach oben (Item N+1's Preis wird Item N zugeordnet).
    //  - Niedriger als 0.4 verursacht Spalten-Splits.
    final yTol = (medianHeight * 0.6).clamp(8.0, 30.0);

    // Schritt 3: nach Y (top) sortieren.
    all.sort((a, b) => a.bbox.top.compareTo(b.bbox.top));

    // Schritt 4: in Reihen gruppieren (Lines mit aehnlicher Y-Position).
    final rows = <List<_BboxLine>>[];
    for (final line in all) {
      if (rows.isEmpty) {
        rows.add(<_BboxLine>[line]);
        continue;
      }
      // Vergleiche mit der MITTLEREN Y-Pos der letzten Reihe (robuster
      // als 'first', wenn Reihe schon mehrere Eintraege hat).
      final lastRow = rows.last;
      final lastTopAvg = lastRow.fold<double>(0, (s, l) => s + l.bbox.top) /
          lastRow.length;
      if ((line.bbox.top - lastTopAvg).abs() > yTol) {
        rows.add(<_BboxLine>[line]);
      } else {
        lastRow.add(line);
      }
    }

    // Schritt 5: Innerhalb jeder Reihe nach X (left) sortieren und mit
    // doppeltem Leerzeichen joinen.
    final assembled = <String>[
      for (final row in rows)
        (row..sort((a, b) => a.bbox.left.compareTo(b.bbox.left)))
            .map((l) => l.text)
            .join('  '),
    ];

    return OcrResult(lines: assembled, fullText: recognized.text);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}

class _BboxLine {
  _BboxLine({required this.text, required this.bbox});
  final String text;
  final Rect bbox;
}
