import 'dart:io';

import 'image_preprocessor.dart';
import 'photo_capture_service.dart';

/// Decorator, der nach dem Capture die Bildvorverarbeitung anwendet.
///
/// So bleibt die Trennung sauber: `ImagePickerPhotoCaptureService`
/// kuemmert sich um Picker/Kamera, `ImagePreprocessor` kuemmert sich
/// um Pixel-Arbeit. Der Caller (ReceiptScanScreen) sieht nur eine
/// `PhotoCaptureService`-Schnittstelle.
///
/// `enabled`: Wenn false, wird der Preprocessor uebersprungen und
/// das Roh-Bild durchgereicht. Sinnvoll z.B. fuer Tesseract, das
/// mit JPG-Kompressions-Artefakten + Schaerfung schlechter umgeht
/// als ML Kit.
class PreprocessingPhotoCaptureService implements PhotoCaptureService {
  const PreprocessingPhotoCaptureService({
    required this.delegate,
    required this.preprocessor,
    this.enabled = true,
  });

  final PhotoCaptureService delegate;
  final ImagePreprocessor preprocessor;
  final bool enabled;

  @override
  Future<File?> capture(PhotoSource source) async {
    final file = await delegate.capture(source);
    if (file == null) return null;
    if (!enabled) return file;
    try {
      return await preprocessor.processInPlace(file);
    } catch (_) {
      // Wenn die Vorverarbeitung scheitert (z.B. unbekanntes Format),
      // geben wir die Originaldatei weiter - lieber ein "rohes" Bild
      // als gar keins.
      return file;
    }
  }

  @override
  Future<void> deleteSafe(File file) => delegate.deleteSafe(file);
}
