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
  // Komplettes Wipe (z. B. beim "Account zurücksetzen")
  // ────────────────────────────────────────────────────────────────
  Future<void> wipeAll() => _storage.deleteAll();
}
