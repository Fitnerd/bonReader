import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Ergebnis einer OCR-Erkennung.
///
/// Wir liefern Roh-Zeilen, weil der Parser zeilenbasiert arbeitet
/// (Position + Preis stehen typischerweise auf der gleichen Zeile).
class OcrResult {
  const OcrResult({required this.lines, required this.fullText});

  final List<String> lines;
  final String fullText;
}

/// Abstraktion ueber ML Kit, damit wir den Parser unabhaengig
/// vom Plattform-Plugin testen koennen.
abstract class ReceiptOcrService {
  Future<OcrResult> recognize(File image);
  Future<void> dispose();
}

/// On-device OCR via Google ML Kit Text Recognition.
/// Nichts geht ueber das Netzwerk.
class MlKitReceiptOcrService implements ReceiptOcrService {
  MlKitReceiptOcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrResult> recognize(File image) async {
    final input = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(input);
    final lines = <String>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }
    return OcrResult(lines: lines, fullText: recognized.text);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
