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
  // Brute-Force-Schutz (persistente Fehlversuche + Cooldown)
  // ────────────────────────────────────────────────────────────────
  Future<int> readFailedAttempts() async {
    final raw =
        await _storage.read(key: AppConstants.secureKeyFailedAttempts);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> writeFailedAttempts(int count) => _storage.write(
        key: AppConstants.secureKeyFailedAttempts,
        value: count.toString(),
      );

  Future<DateTime?> readCooldownUntil() async {
    final raw =
        await _storage.read(key: AppConstants.secureKeyCooldownUntil);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeCooldownUntil(DateTime? until) async {
    if (until == null) {
      await _storage.delete(key: AppConstants.secureKeyCooldownUntil);
    } else {
      await _storage.write(
        key: AppConstants.secureKeyCooldownUntil,
        value: until.toIso8601String(),
      );
    }
  }

  Future<void> clearLoginAttempts() async {
    await _storage.delete(key: AppConstants.secureKeyFailedAttempts);
    await _storage.delete(key: AppConstants.secureKeyCooldownUntil);
  }

  // ────────────────────────────────────────────────────────────────
  // Letzter Passwort-Login (fuer Biometrie-Erzwingung nach 72h)
  // ────────────────────────────────────────────────────────────────
  Future<DateTime?> readLastPasswordLogin() async {
    final raw =
        await _storage.read(key: AppConstants.secureKeyLastPasswordLogin);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastPasswordLogin(DateTime time) => _storage.write(
        key: AppConstants.secureKeyLastPasswordLogin,
        value: time.toIso8601String(),
      );

  // ────────────────────────────────────────────────────────────────
  // Komplettes Wipe (z. B. beim "Account zurücksetzen")
  // ────────────────────────────────────────────────────────────────
  Future<void> wipeAll() => _storage.deleteAll();
}
