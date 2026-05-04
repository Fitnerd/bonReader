import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../core/constants/app_constants.dart';

/// Verifiziert ein altes App-Passwort gegen den im Secure Storage
/// abgelegten Argon2id-Hash.
///
/// **Nur fuer Migration!** Neue Setups verwenden Biometrie-Only ohne
/// Passwort. Diese Klasse existiert ausschliesslich, um bestehende
/// Installationen einmalig auf das neue Modell umzustellen. Sobald die
/// Migration durchgelaufen ist und der alte Hash geloescht wurde,
/// kann sie zusammen mit dem `pointycastle`-Dependency entfernt werden.
class LegacyPasswordVerifier {
  const LegacyPasswordVerifier();

  /// True wenn `password` zum gespeicherten Hash passt.
  /// Konstantzeitiger Vergleich.
  Future<bool> verify({
    required String password,
    required String storedHashBase64,
    required String storedSaltBase64,
  }) async {
    final salt = base64Decode(storedSaltBase64);
    final computed = _argon2id(password: password, salt: salt);
    return _constantTimeEquals(
      base64Encode(computed),
      storedHashBase64,
    );
  }

  Uint8List _argon2id({
    required String password,
    required Uint8List salt,
  }) {
    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: AppConstants.argon2HashLength,
      iterations: AppConstants.argon2Iterations,
      memory: AppConstants.argon2MemoryKb,
      lanes: AppConstants.argon2Parallelism,
      version: Argon2Parameters.ARGON2_VERSION_13,
    );
    final argon2 = Argon2BytesGenerator()..init(params);
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final out = Uint8List(AppConstants.argon2HashLength);
    argon2.deriveKey(passwordBytes, 0, out, 0);
    return out;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
