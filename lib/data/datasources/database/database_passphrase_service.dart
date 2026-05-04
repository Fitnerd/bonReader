import 'dart:convert';
import 'dart:math';

import '../secure_storage_service.dart';

/// Erzeugt und verwaltet die DB-Passphrase fuer SQLCipher.
///
/// Beim ersten App-Start wird eine 32-Byte-Zufallspassphrase mit
/// `Random.secure()` erzeugt und im Secure Storage abgelegt
/// (Android Keystore / iOS Keychain). Bei jedem weiteren Start
/// wird sie nur noch ausgelesen.
///
/// Bewusste Designentscheidung: Die Passphrase ist nicht aus dem
/// Nutzerpasswort abgeleitet. Vorteil: Der Nutzer kann das Passwort
/// aendern, ohne die DB neu zu verschluesseln. Schutz vor physischem
/// Zugriff auf die DB-Datei kommt aus dem Secure Storage selbst,
/// der vom Betriebssystem hardwaregestuetzt verschluesselt ist.
///
/// TODO(security): Key-Rotation implementieren. Langfristig sollte die
/// DB-Passphrase bei Passwortwechsel rotiert werden koennen.
/// SQLCipher unterstuetzt `PRAGMA rekey` – die alte Passphrase oeffnet
/// die DB, dann wird mit `rekey` auf die neue umgestellt. Aktuell ist
/// das kein direktes Risiko, da die Passphrase im Secure Storage liegt.
class DatabasePassphraseService {
  DatabasePassphraseService(this._storage);

  final SecureStorageService _storage;

  /// Lese die Passphrase oder erzeuge sie beim ersten Start.
  Future<String> getOrCreate() async {
    final existing = await _storage.readDbPassphrase();
    if (existing != null && existing.isNotEmpty) return existing;

    final passphrase = _generatePassphrase();
    await _storage.writeDbPassphrase(passphrase);
    return passphrase;
  }

  /// 32 Byte (256 Bit) kryptografisch sicherer Zufall, base64-kodiert.
  String _generatePassphrase() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }
}
