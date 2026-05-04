import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:bonbudget/data/datasources/secure_storage_service.dart';

/// In-Memory-Doppelgaenger fuer [SecureStorageService] in Tests.
/// Verwendet die gleichen Keys wie die Produktion.
class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String?> _store = <String, String?>{};

  /// Ermoeglicht Tests, Legacy-Werte (Argon2-Hash + Salt) zu seeden,
  /// um den Migrations-Pfad zu pruefen.
  void seedLegacyAuth({required String hashBase64, required String saltBase64}) {
    _store[AppConstants.secureKeyAuthHash] = hashBase64;
    _store[AppConstants.secureKeyAuthSalt] = saltBase64;
  }

  @override
  Future<String?> readDbPassphrase() async =>
      _store[AppConstants.secureKeyDbPassphrase];

  @override
  Future<void> writeDbPassphrase(String value) async {
    _store[AppConstants.secureKeyDbPassphrase] = value;
  }

  @override
  Future<bool> readSetupComplete() async =>
      _store[AppConstants.secureKeySetupComplete] == '1';

  @override
  Future<void> writeSetupComplete({required bool complete}) async {
    _store[AppConstants.secureKeySetupComplete] = complete ? '1' : '0';
  }

  @override
  Future<int> readAutoLogoutMinutes() async {
    final raw = _store[AppConstants.secureKeyAutoLogoutMin];
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

  @override
  Future<void> writeAutoLogoutMinutes(int minutes) async {
    final clamped = minutes.clamp(
      AppConstants.minAutoLogoutMinutes,
      AppConstants.maxAutoLogoutMinutes,
    );
    _store[AppConstants.secureKeyAutoLogoutMin] = clamped.toString();
  }

  // ── Legacy-Migration ──────────────────────────────────────────

  @override
  Future<String?> readAuthHash() async =>
      _store[AppConstants.secureKeyAuthHash];

  @override
  Future<String?> readAuthSalt() async =>
      _store[AppConstants.secureKeyAuthSalt];

  @override
  Future<void> deleteLegacyAuth() async {
    _store.remove(AppConstants.secureKeyAuthHash);
    _store.remove(AppConstants.secureKeyAuthSalt);
    _store.remove(AppConstants.secureKeyBiometricEnabled);
    _store.remove(AppConstants.secureKeyFailedAttempts);
    _store.remove(AppConstants.secureKeyCooldownUntil);
    _store.remove(AppConstants.secureKeyLastPasswordLogin);
  }

  // ── Wipe ──────────────────────────────────────────────────────

  @override
  Future<void> wipeAll() async {
    _store.clear();
  }
}
