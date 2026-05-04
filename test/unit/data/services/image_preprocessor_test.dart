import 'dart:io';
import 'dart:typed_data';

import 'package:bonbudget/data/services/image_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Tests fuer DefaultImagePreprocessor.
///
/// Wir erzeugen synthetische Bilder mit bekannten Eigenschaften
/// (z.B. niedriger Kontrast, bunte Pixel) und pruefen, dass die
/// Pipeline die erwarteten Aenderungen vornimmt.
void main() {
  group('DefaultImagePreprocessor', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('imgproc_test_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    Future<File> writeJpg(img.Image image, String name) async {
      final f = File(p.join(tempDir.path, name));
      await f.writeAsBytes(img.encodeJpg(image, quality: 90));
      return f;
    }

    test('processInPlace ueberschreibt die Datei mit JPG-Output', () async {
      // Buntes 50x50 Bild
      final src = img.Image(width: 50, height: 50);
      img.fill(src, color: img.ColorRgb8(255, 100, 50));
      final file = await writeJpg(src, 'in.jpg');
      final origLen = await file.length();

      const processor = DefaultImagePreprocessor();
      final out = await processor.processInPlace(file);

      expect(out.path, file.path, reason: 'gleiches File-Objekt zurueck');
      final processed = img.decodeImage(await out.readAsBytes());
      expect(processed, isNotNull);
      // Nach grayscale sollte R=G=B fuer jedes Pixel sein.
      final px = processed!.getPixel(25, 25);
      expect(px.r.toInt(), px.g.toInt());
      expect(px.g.toInt(), px.b.toInt());
      // Datei wurde wirklich neu geschrieben (nicht zwingend kleiner,
      // aber zumindest valide JPG).
      expect(await file.length(), greaterThan(0));
      // origLen unused - just dass es laeuft.
      expect(origLen, greaterThan(0));
    });

    test('Auto-Kontrast spannt das Histogramm auf', () async {
      // Bild mit niedrigem Kontrast: alle Pixel zwischen 100..150 (grau)
      final src = img.Image(width: 100, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          final v = 100 + (x % 50);
          src.setPixelRgb(x, y, v, v, v);
        }
      }
      final file = await writeJpg(src, 'lowcontrast.jpg');

      const processor = DefaultImagePreprocessor();
      await processor.processInPlace(file);

      final processed = img.decodeImage(await file.readAsBytes())!;
      // Min/Max-Helligkeit sollte deutlich weiter auseinander sein
      // als 100..150 (50 Stufen Range vorher).
      var minL = 255;
      var maxL = 0;
      for (var y = 0; y < processed.height; y++) {
        for (var x = 0; x < processed.width; x++) {
          final px = processed.getPixel(x, y);
          final l = px.r.toInt();
          if (l < minL) minL = l;
          if (l > maxL) maxL = l;
        }
      }
      expect(maxL - minL, greaterThan(100),
          reason: 'normalize sollte Range >> 50 ergeben');
    });

    test('kaputte Datei -> unveraendert zurueck (kein Crash)', () async {
      final f = File(p.join(tempDir.path, 'broken.jpg'));
      await f.writeAsBytes(Uint8List.fromList(<int>[1, 2, 3, 4, 5]));
      const processor = DefaultImagePreprocessor();
      final out = await processor.processInPlace(f);
      expect(out.path, f.path);
      // Der Inhalt bleibt unveraendert (decodeImage gab null zurueck).
      expect(await f.readAsBytes(), <int>[1, 2, 3, 4, 5]);
    });
  });
}
