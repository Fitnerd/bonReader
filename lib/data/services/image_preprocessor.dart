import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Bereitet ein Bon-Foto fuer die OCR vor.
///
/// Hintergrund: ML Kit liefert auf zerknitterten Thermo-Bons mit
/// ungleichmaessiger Beleuchtung haeufig schlechte Ergebnisse - manche
/// Spalten/Werte werden gar nicht erkannt. Eine simple
/// Graustufen+Kontrast-Pipeline holt da empirisch viel raus, ohne dass
/// wir die OCR-Lib wechseln muessten.
///
/// Pipeline:
///   1. Graustufen (neutralisiert Farbstich vom Bon-Papier)
///   2. Auto-Kontrast (`normalize`): pusht Helligkeit auf den vollen
///      0-255-Bereich. Hellgrauer Thermo-Bon wird zu echtem Weiss.
///   3. Leichte Schaerfung (3x3-Convolution-Kernel): Buchstaben werden
///      knackiger, ohne dass Rauschen explodiert.
///
/// Bewusste Nicht-Schritte:
///   - Adaptive Binarisierung (Sauvola/Otsu): kann ML Kit verwirren,
///     die Engine hat ihre eigene Vorverarbeitung. Erst zuschalten,
///     wenn wir sehen dass die Pipeline allein nicht reicht.
///   - Deskew: braeuchte Hough-Transformation o.ae., zu viel Code
///     fuer den marginalen Nutzen.
abstract class ImagePreprocessor {
  /// Verarbeitet [source] in-place: liest die Datei, optimiert sie und
  /// schreibt das Ergebnis zurueck in dieselbe Datei. Gibt dieselbe
  /// File-Referenz zurueck (Convenience).
  Future<File> processInPlace(File source);
}

class DefaultImagePreprocessor implements ImagePreprocessor {
  const DefaultImagePreprocessor();

  @override
  Future<File> processInPlace(File source) async {
    final bytes = await source.readAsBytes();
    // decodeImage kann bei sehr kleinen oder kaputten Inputs eine
    // Exception werfen (z.B. RangeError im PSD-Detektor) statt null
    // zurueckzugeben. Wir fangen das ab und behandeln es wie 'kein
    // Bild' - die Originaldatei wird unveraendert weitergereicht.
    img.Image? image;
    try {
      image = img.decodeImage(bytes);
    } catch (e, st) {
      // Fehler nicht verschlucken, aber kein User-Stop - ML Kit soll
      // gleich selber probieren.
      if (kDebugMode) {
        debugPrint('ImagePreprocessor.decode failed: $e');
        debugPrintStack(stackTrace: st, label: 'ImagePreprocessor');
      }
      image = null;
    }
    if (image == null) {
      // Konnte nicht decodiert werden -> unveraendert lassen, ML Kit
      // soll selber sein Glueck versuchen.
      return source;
    }

    // 1. Graustufen
    image = img.grayscale(image);

    // 2. Auto-Kontrast: spannt das Histogramm auf 0..255 auf.
    //    `normalize` mit min=0, max=255 macht genau das.
    image = img.normalize(image, min: 0, max: 255);

    // 3. Leichtes Schaerfen via 3x3-Kernel (sharp filter).
    //    Zentralwert 5, Randwerte -1 -> Standard-Schaerfungsfilter.
    image = img.convolution(image, filter: <num>[
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ]);

    // JPG mit moderater Qualitaet zurueckschreiben - reicht fuer OCR
    // und haelt die Datei klein.
    final out = img.encodeJpg(image, quality: 90);
    await source.writeAsBytes(out, flush: true);
    return source;
  }
}
