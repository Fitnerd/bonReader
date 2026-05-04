import 'dart:io';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import 'receipt_ocr_service.dart';

/// Tesseract-basierte OCR-Engine als Alternative zu ML Kit.
///
/// Hintergrund: ML Kit unterperformt manchmal bei zerknitterten
/// Thermo-Bons (verlorene Kommas, Spalten-Versatz). Tesseract hat
/// dort gelegentlich bessere Ergebnisse, ist aber:
///   - langsamer (CPU-only, kein GPU-Pfad)
///   - groesser im Build (~7 MB Sprachdaten als Asset)
///   - sprachabhaengig (deu.traineddata muss vorhanden sein)
///
/// Sprachdaten:
///   Die Datei `assets/tessdata/deu.traineddata` muss vorhanden sein
///   (siehe `assets/tessdata/README.md`). Wenn nicht, wirft
///   FlutterTesseractOcr.extractText eine Exception, die wir hier
///   fangen und mit klarer Fehlermeldung weitergeben.
class TesseractReceiptOcrService implements ReceiptOcrService {
  const TesseractReceiptOcrService({
    this.language = 'deu',
    this.psm = 4,
  });

  /// Sprachcode entsprechend `<lang>.traineddata` im Asset-Ordner.
  final String language;

  /// Page Segmentation Mode. 4 = "Assume a single column of text of
  /// variable sizes" - passt zu Bon-Layouts mit Name-links/Preis-rechts.
  /// 6 = "single uniform block" merged Spalten zu schlecht.
  final int psm;

  @override
  Future<OcrResult> recognize(File image) async {
    try {
      final text = await FlutterTesseractOcr.extractText(
        image.path,
        language: language,
        args: <String, String>{
          'preserve_interword_spaces': '1',
          'psm': psm.toString(),
        },
      );
      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      return OcrResult(lines: lines, fullText: text);
    } catch (e) {
      throw Exception(
        'Tesseract OCR fehlgeschlagen. Liegt assets/tessdata/$language'
        '.traineddata vor und ist die App nach "flutter clean" + '
        '"flutter pub get" neu gebaut? Original-Fehler: $e',
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Tesseract braucht keinen expliziten dispose-Call.
  }
}
