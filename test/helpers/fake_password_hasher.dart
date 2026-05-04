import 'dart:convert';

import 'package:bonbudget/data/services/password_hasher.dart';

/// Test-Hasher: triviale, deterministische Verkettung von Salt+Passwort.
/// Ist NICHT sicher fuer Produktion – nur damit AuthRepository-Tests
/// schnell laufen und das echte dargon2-Plugin nicht laden muessen.
///
/// Wir wollen pruefen, dass:
///  - Hash und Salt deterministisch zueinander passen,
///  - Verify mit gleichem Passwort+Salt true liefert,
///  - Verify mit anderem Passwort false liefert.
class FakePasswordHasher implements PasswordHasher {
  int _saltCounter = 0;

  @override
  Future<HashedPassword> hashNew(String password) async {
    _saltCounter++;
    final salt = base64Encode(utf8.encode('salt-$_saltCounter'));
    return HashedPassword(hashBase64: _hash(password, salt), saltBase64: salt);
  }

  @override
  Future<bool> verify({
    required String password,
    required String storedHashBase64,
    required String storedSaltBase64,
  }) async {
    return _hash(password, storedSaltBase64) == storedHashBase64;
  }

  String _hash(String password, String saltBase64) {
    // Reicht fuer Tests: deterministisch, unterschiedliche Eingaben →
    // unterschiedliche Ausgaben.
    return base64Encode(utf8.encode('$saltBase64::$password'));
  }
}
