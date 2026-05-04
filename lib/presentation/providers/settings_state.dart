import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/data_providers.dart';

/// Auto-Logout-Timeout in Minuten. Persistiert im Secure Storage,
/// damit beim naechsten App-Start derselbe Wert gilt.
class AutoLogoutMinutesNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final storage = ref.watch(secureStorageProvider);
    return storage.readAutoLogoutMinutes();
  }

  Future<void> set(int minutes) async {
    final clamped = minutes.clamp(
      AppConstants.minAutoLogoutMinutes,
      AppConstants.maxAutoLogoutMinutes,
    );
    final storage = ref.read(secureStorageProvider);
    await storage.writeAutoLogoutMinutes(clamped);
    state = AsyncValue<int>.data(clamped);
  }
}

final autoLogoutMinutesProvider =
    AsyncNotifierProvider<AutoLogoutMinutesNotifier, int>(
  AutoLogoutMinutesNotifier.new,
);


/// Counter, der das Auto-Logout temporaer unterdrueckt.
///
/// Wenn die App in den Hintergrund geht (z. B. weil der Foto-Picker oder
/// die Biometrie-Pruefung in einer separaten Activity laeuft), wuerde
/// AutoLogoutListener sonst sofort ausloggen. Solche legitimen
/// Hintergrund-Wechsel hoehen den Counter, der Listener prueft den Wert
/// und ueberspringt den Logout, solange er > 0 ist.
class AutoLogoutSuppressionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Unterdrueckung anfordern - z. B. vor Aufruf von ImagePicker.
  void acquire() => state = state + 1;

  /// Unterdrueckung freigeben. Bei mehrfachen Acquires zaehlt nur der
  /// letzte Release wirklich runter.
  void release() => state = state > 0 ? state - 1 : 0;
}

final autoLogoutSuppressionProvider =
    NotifierProvider<AutoLogoutSuppressionNotifier, int>(
  AutoLogoutSuppressionNotifier.new,
);

/// OCR-Engine-Auswahl. 'mlkit' (Default) oder 'tesseract'.
/// Persistiert im Secure Storage.
class OcrEngineNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    return storage.readOcrEngine();
  }

  Future<void> set(String engine) async {
    final v = (engine == 'tesseract') ? 'tesseract' : 'mlkit';
    final storage = ref.read(secureStorageProvider);
    await storage.writeOcrEngine(v);
    state = AsyncValue<String>.data(v);
  }
}

final ocrEngineProvider =
    AsyncNotifierProvider<OcrEngineNotifier, String>(
  OcrEngineNotifier.new,
);
