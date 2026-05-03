import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:bonbudget/data/datasources/secure_storage_service.dart';

/// In-Memory-Doppelgaenger fuer [SecureStorageService] in Tests.
/// Verwendet die gleichen Keys wie die Produktion.
class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String?> _store = <String, String?>{};

  @override
  Future<String?> readDbPassphrase() async =>
      _store[AppConstants.secureKeyDbPassphrase];

  @override
  Future<void> writeDbPassphrase(String value) async {
    _store[AppConstants.secureKeyDbPassphrase] = value;
  }

  @override
  Future<String?> readAuthHash() async =>
      _store[AppConstants.secureKeyAuthHash];

  @override
  Future<void> writeAuthHash(String value) async {
    _store[AppConstants.secureKeyAuthHash] = value;
  }

  @override
  Future<String?> readAuthSalt() async =>
      _store[AppConstants.secureKeyAuthSalt];

  @override
  Future<void> writeAuthSalt(String value) async {
    _store[AppConstants.secureKeyAuthSalt] = value;
  }

  @override
  Future<bool> readBiometricEnabled() async =>
      _store[AppConstants.secureKeyBiometricEnabled] == '1';

  @override
  Future<void> writeBiometricEnabled({required bool enabled}) async {
    _store[AppConstants.secureKeyBiometricEnabled] = enabled ? '1' : '0';
  }

  @override
  Future<int> readAutoLogoutMinutes() async {
    final raw