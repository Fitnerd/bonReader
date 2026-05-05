import 'dart:io';

import 'package:bonbudget/data/services/receipt_ocr_service.dart';

/// Test-Doppelgaenger fuer [ReceiptOcrService].
///
/// Statt ML Kit aufzurufen, gibt einfach die im Konstruktor uebergebenen
/// Zeilen zurueck. So kann der OCR-Pfad ohne Geraet getestet werden.
///
/// Beispiel:
/// ```dart
/// final ocr = FakeReceiptOcrService(lines: <String>[
///   'REWE',
///   'BROT 1,99 B',
///   'SUMME 1,99 EUR',
/// ]);
/// final result = await ocr.recognize(File('dummy.jpg'));
/// ```
class FakeReceiptOcrService implements ReceiptOcrService {
  FakeReceiptOcrService({this.lines = const <String>[], this.shouldThrow});

  final List<String> lines;
  Exception? shouldThrow;
  int recognizeCallCount = 0;
  File? lastImage;

  @override
  Future<OcrResult> recognize(File image) async {
    recognizeCallCount++;
    lastImage = image;
    final err = shouldThrow;
    if (err != null) {
      throw err;
    }
    return OcrResult(lines: lines, fullText: lines.join('\n'));
  }

  @override
  Future<void> dispose() async {}
}
