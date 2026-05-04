import 'dart:io';

import 'image_preprocessor.dart';
import 'photo_capture_service.dart';

/// Decorator, der nach dem Capture die Bildvorverarbeitung anwendet.
///
/// So bleibt die Trennung sauber: `ImagePickerPhotoCaptureService`
/// kuemmert sich um Picker/Kamera, `ImagePreprocessor` kuemmert sich
/// um Pixel-Arbeit. Der Caller (ReceiptScanScreen) sieht nur eine
/// `PhotoCaptureService`-Schnittstelle.
class PreprocessingPhotoCaptureService implements PhotoCaptureService {
  const PreprocessingPhotoCaptureService({
    required this.delegate,
    required this.preprocessor,
  });

  final PhotoCaptureService delegate;
  final ImagePreprocessor preprocessor;

  @override
  Future<File?> capture(PhotoSource source) async {
    final file = await delegate.capture(source);
    if (file == null) return null;
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
