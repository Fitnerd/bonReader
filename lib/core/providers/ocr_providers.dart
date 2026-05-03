import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/photo_capture_service.dart';
import '../../data/services/receipt_ocr_service.dart';

/// Provider fuer OCR-Service. Wird beim Test ueberschrieben mit einem Fake.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final svc = MlKitReceiptOcrService();
  ref.onDispose(svc.dispose);
  return svc;
});

final photoCaptureServiceProvider = Provider<PhotoCaptureService>((ref) {
  return ImagePickerPhotoCaptureService();
});
