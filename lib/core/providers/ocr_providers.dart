import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/image_preprocessor.dart';
import '../../data/services/photo_capture_service.dart';
import '../../data/services/preprocessing_photo_capture_service.dart';
import '../../data/services/receipt_ocr_service.dart';

/// Provider fuer OCR-Service. Wird beim Test ueberschrieben mit einem Fake.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
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
