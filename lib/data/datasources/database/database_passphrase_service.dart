import 'dart:async';
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
/// **Nebenlaeufigkeit:** [getOrCreate] ist mit einem internen Mutex
/// serialisiert. Ohne den koennten zwei parallele Aufrufer beim
/// allerersten Start jeweils eine eigene Passphrase erzeugen, was zu
/// einer nicht mehr lesbaren DB fuehrt. Im Normalbetrieb ist nur ein
/// Aufruf gleichzeitig zu erwarten, der Mutex ist Defence-in-Depth.
class DatabasePassphraseService {
  DatabasePassphraseService(this._storage);

  final SecureStorageService _storage;

  /// Laufender Aufruf von [getOrCreate], falls einer aktiv ist.
  /// Wird benutzt, um parallele Aufrufer auf das gleiche Future
  /// warten zu lassen statt jeweils eigenen Storage-Zugriff zu starten.
  Future<String>? _inFlight;

  /// Lese die Passphrase oder erzeuge sie beim ersten Start.
  ///
  /// Garantiert, dass auch bei parallelen Aufrufen nur eine Passphrase
  /// generiert und persistiert wird.
  Future<String> getOrCreate() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _readOrCreate();
    _inFlight = future;
    // Egal ob Erfolg oder Fehler: Slot wieder freigeben, damit ein
    // spaeterer Aufruf einen frischen Versuch macht.
    future.whenComplete(() => _inFlight = null);
    return future;
  }

  Future<String> _readOrCreate() async {
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
