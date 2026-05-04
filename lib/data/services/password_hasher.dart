import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../core/constants/app_constants.dart';

/// Ergebnis eines Hash-Vorgangs.
class HashedPassword {
  const HashedPassword({required this.hashBase64, required this.saltBase64});
  final String hashBase64;
  final String saltBase64;
}

/// Vertrag fuer Passwort-Hashing.
///
/// Trennt die konkrete Crypto-Bibliothek von der Anwendungslogik, damit
/// Tests einen FakePasswordHasher nutzen koennen, ohne echtes Argon2
/// laufen zu lassen.
abstract class PasswordHasher {
  Future<HashedPassword> hashNew(String password);

  Future<bool> verify({
    required String password,
    required String storedHashBase64,
    required String storedSaltBase64,
  });
}

/// Argon2id via pointycastle. Pure Dart, keine native Library.
///
/// Parameter kommen aus [AppConstants] und entsprechen den RFC-9106
/// Empfehlungen fuer interaktives Login (t=3, m=64MB, p=4).
///
/// Verglichen mit C-Implementierungen ist Dart-Argon2 langsamer (Faktor
/// 2-3), aber Login ist Einmal-Aktion und 1-3 Sekunden auf einem
/// modernen Geraet sind akzeptabel.
class Argon2PasswordHasher implements PasswordHasher {
  const Argon2PasswordHasher();

  @override
  Future<HashedPassword> hashNew(String password) async {
    final salt = _randomSalt(AppConstants.argon2SaltLength);
    final hashBytes = _argon2id(
      password: password,
      salt: salt,
    );
    return HashedPassword(
      hashBase64: base64Encode(hashBytes),
      saltBase64: base64Encode(salt),
    );
  }

  @override
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

  // ──────────────────────────────────────────────────────────────────
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

  Uint8List _randomSalt(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  /// Vergleich in konstanter Zeit. Bricht *nicht* beim ersten Unterschied
  /// ab, damit ein Angreifer aus der Zeit nichts ableiten kann.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
