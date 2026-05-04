import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/image_preprocessor.dart';
import '../../data/services/photo_capture_service.dart';
import '../../data/services/preprocessing_photo_capture_service.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../data/services/tesseract_receipt_ocr_service.dart';
import '../../presentation/providers/settings_state.dart';

/// OCR-Service. Schaltet zur Laufzeit zwischen ML Kit und Tesseract
/// um, basierend auf der Settings-Auswahl. Wenn der Settings-Provider
/// noch laedt oder einen Fehler hat, faellt er auf ML Kit zurueck.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final asyncEngine = ref.watch(ocrEngineProvider);
  final engine = asyncEngine.maybeWhen(
    data: (e) => e,
    orElse: () => 'mlkit',
  );
  if (engine == 'tesseract') {
    final svc = TesseractReceiptOcrService();
    ref.onDispose(svc.dispose);
    return svc;
  }
  final svc = MlKitReceiptOcrService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Bildvorverarbeitung (Graustufen, Auto-Kontrast, Schaerfen).
final imagePreprocessorProvider = Provider<ImagePreprocessor>((ref) {
  return const DefaultImagePreprocessor();
});

/// Foto-Aufnahme inkl. Vorverarbeitung. Reihenfolge: zuerst Picker,
/// dann Preprocessor (Decorator).
final photoCaptureServiceProvider = Provider<PhotoCaptureService>((ref) {
  return PreprocessingPhotoCaptureService(
    delegate: ImagePickerPhotoCaptureService(),
    preprocessor: ref.read(imagePreprocessorProvider),
  );
});
