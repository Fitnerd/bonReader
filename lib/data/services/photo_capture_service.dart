import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Quelle, aus der das Bon-Foto geholt wird.
enum PhotoSource { camera, gallery }

/// Kapselt das Aufnehmen / Auswaehlen eines Bon-Fotos.
///
/// Wichtig: Wir speichern das Foto in einer App-eigenen Temp-Datei und
/// loeschen es nach der OCR-Auswertung. Es gibt absichtlich keine
/// API zum „Foto behalten", weil Privacy-by-Default zugesichert wurde.
abstract class PhotoCaptureService {
  Future<File?> capture(PhotoSource source);
  Future<void> deleteSafe(File file);
}

class ImagePickerPhotoCaptureService implements PhotoCaptureService {
  ImagePickerPhotoCaptureService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> capture(PhotoSource source) async {
    final src =
        source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: src,
      // OCR braucht keine 4K-Aufloesung; reduziert RAM-Druck deutlich.
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // Wir kopieren in unser eigenes Tmp-Verzeichnis und behandeln
    // _diese_ Kopie als die einzige Datei – das Original aus dem
    // Picker-Cache loeschen wir ebenfalls.
    final tempDir = await getTemporaryDirectory();
    final ourDir = Directory(p.join(tempDir.path, 'bonbudget_scan'));
    if (!ourDir.existsSync()) {
      ourDir.createSync(recursive: true);
    }
    final ourFile = File(p.join(
      ourDir.path,
      'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ));
    await File(picked.path).copy(ourFile.path);
    // Original aus picker-cache loeschen (best effort)
    try {
      await File(picked.path).delete();
    } catch (_) {}
    return ourFile;
  }

  @override
  Future<void> deleteSafe(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Datei konnte nicht geloescht werden – das ist nicht kritisch,
      // beim naechsten App-Start raeumt das System die Temp auf.
    }
  }
}
