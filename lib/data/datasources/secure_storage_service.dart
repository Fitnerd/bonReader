import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';

/// Wrapper um [FlutterSecureStorage], der nur die Keys exponiert,
/// die wir wirklich nutzen. Das verhindert, dass irgendwo im Code
/// versehentlich freie Strings als Keys benutzt werden.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  // ────────────────────────────────────────────────────────────────
  // Datenbank-Passphrase
  // ────────────────────────────────────────────────────────────────
  Future<String?> readDbPassphrase() =>
      _storage.read(key: AppConstants.secureKeyDbPassphrase);

  Future<void> writeDbPassphrase(String value) =>
      _storage.write(key: AppConstants.secureKeyDbPassphrase, value: value);

  // ────────────────────────────────────────────────────────────────
  // Auth (Hash + Salt)
  // ────────────────────────────────────────────────────────────────
  Future<String?> readAuthHash() =>
      _storage.read(key: AppConstants.secureKeyAuthHash);

  Future<void> writeAuthHash(String value) =>
      _storage.write(key: AppConstants.secureKeyAuthHash, value: value);

  Future<String?> readAuthSalt() =>
      _storage.read(key: AppConstants.secureKeyAuthSalt);

  Future<void> writeAuthSalt(String value) =>
      _storage.write(key: AppConstants.secureKeyAuthSalt, value: value);

  // ────────────────────────────────────────────────────────────────
  // Biometrie-Flag
  // ────────────────────────────────────────────────────────────────
  Future<bool> readBiometricEnabled() async {
    final raw = await _storage.read(key: AppConstants.secureKeyBiometricEnabled);
    return raw == '1';
  }

  Future<void> writeBiometricEnabled({required bool enabled}) =>
      _storage.write(
        key: AppConstants.secureKeyBiometricEnabled,
        value: enabled ? '1' : '0',
      );

  // ────────────────────────────────────────────────────────────────
  // Auto-Logout-Timeout
  //
  // Streng genommen kein „Geheimnis". Wir benutzen Secure Storage
  // trotzdem, um keinen zweiten Persistenz-Mechanismus einzufuehren.
  // ────────────────────────────────────────────────────────────────
  Future<int> readAutoLogoutMinutes() async {
    final raw = await _storage.read(key: AppConstants.secureKeyAutoLogoutMin);
    final v = int.tryParse(raw ?? '');
    if (v == null) return AppConstants.defaultAutoLogoutMinutes;
    if (v < AppConstants.minAutoLogoutMinutes) {
      return AppConstants.minAutoLogoutMinutes;
    }
    if (v > AppConstants.maxAutoLogoutMinutes) {
      return AppConstants.maxAutoLogoutMinutes;
    }
    return v;
  }

  Future<void> writeAutoLogoutMinutes(int minutes) {
    final clamped = minutes.clamp(
      AppConstants.minAutoLogoutMinutes,
      AppConstants.maxAutoLogoutMinutes,
    );
    return _storage.write(
      key: AppConstants.secureKeyAutoLogoutMin,
      value: clamped.toString(),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // OCR-Engine-Auswahl
  //
  // Erlaubte Werte: 'mlkit' (Default) oder 'tesseract'. Default
  // greift, wenn der Key nicht existiert oder einen unbekannten
  // Wert hat - so bleibt das Verhalten stabil, falls wir spaeter
  // Engines umbenennen oder entfernen.
  // ────────────────────────────────────────────────────────────────
  Future<String> readOcrEngine() async {
    final raw = await _storage.read(key: AppConstants.secureKeyOcrEngine);
    if (raw == 'tesseract' || raw == 'mlkit') return raw!;
    return 'mlkit';
  }

  Future<void> writeOcrEngine(String engine) {
    final v = (engine == 'tesseract') ? 'tesseract' : 'mlkit';
    return _storage.write(
      key: AppConstants.secureKeyOcrEngine,
      value: v,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Komplettes Wipe (z. B. beim "Account zurücksetzen")
  // ────────────────────────────────────────────────────────────────
  Future<void> wipeAll() => _storage.deleteAll();
}
