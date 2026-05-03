import 'dart:convert';

import 'package:dargon2_flutter/dargon2_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Ergebnis eines Hash-Vorgangs.
class HashedPassword {
  const HashedPassword({required this.hashBase64, required this.saltBase64});
  final String hashBase64;
  final String saltBase64;
}

/// Vertrag fuer Passwort-Hashing.
///
/// Wird abstrahiert, damit Tests einen Fake nutzen koennen, ohne
/// das native dargon2-Plugin laden zu muessen.
abstract class PasswordHasher {
  Future<HashedPassword> hashNew(String password);
  Future<bool> verify({
    required String password,
    required String storedHashBase64,
    required String storedSaltBase64,
  });
}

/// Echte Implementierung mit Argon2id (RFC 9106).
///
/// Parameter aus [AppConstants]:
///   - t = 3 iterations
///   - m = 64 MB memory
///   - p = 4 parallelism
///   - hashLen = 32 bytes
///   - saltLen = 16 bytes
///
/// Vergleich erfolgt in **konstanter Zeit**, um Timing-Angriffe
/// auszuschliessen.
class Argon2PasswordHasher implements PasswordHasher {
  const Argon2PasswordHasher();

  @override
  Future<HashedPassword> hashNew(String password) async {
    final salt = Salt.newSalt();
    final result = await argon2.hashPasswordString(
      password,
      salt: salt,
      iterations: AppConstants.argon2Iterations,
      memory: AppConstants.argon2MemoryKb,
      parallelism: AppConstants.argon2Parallelism,
      length: AppConstants.argon2HashLength,
      type: Argon2Type.id,
      version: Argon2Version.V13,
    );
    return HashedPassword(
      hashBase64: base64Encode(result.hashBytes),
      saltBase64: base64Encode(salt.bytes),
    );
  }

  @override
  Future<bool> verify({
    required String password,
    required String storedHashBase64,
    required String storedSaltBase64,
  }) async {
    final saltBytes = base64Decode(storedSaltBase64);
    final salt = Salt(saltBytes);
    final result = await argon2.hashPasswordString(
      password,
      salt: salt,
      iterations: AppConstants.argon2Iterations,
      memory: AppConstants.argon2MemoryKb,
      parallelism: AppConstants.argon2Parallelism,
      length: AppConstants.argon2HashLength,
      type: Argon2Type.id,
      version: Argon2Version.V13,
    );
    final computed = base64Encode(result.hashBytes);
    return _constantTimeEquals(computed, storedHashBase64);
  }

  /// Vergleich in konstanter Zeit. Bricht *nicht* beim ersten
  /// Unterschied ab, damit ein Angreifer aus der Zeit nichts ableiten kann.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
